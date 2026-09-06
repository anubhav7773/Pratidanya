import base64
import json
import logging
import httpx
from typing import Dict, Any
from fastapi import HTTPException
from app.core.config import settings
from app.services.text_sanitizer import PoliceDocumentSanitizer

logger = logging.getLogger("pratidnya.voice")

class VoiceIntakeService:
    """
    Multimodal Hindi Audio Processing Service using Gemini 1.5 Flash.
    Transcribes colloquial, noisy court corridor speech into formal Devanagari legal Hindi,
    expands judicial abbreviations, and extracts structured case docket entities.
    Enforces DPDP Act 2023 Sec 8(7): raw audio bytes exist solely in-memory during execution.
    """

    CANDIDATE_VOICE_MODELS = [
        "gemini-3.6-flash",
        "gemini-3.1-flash-lite",
        "gemini-flash-latest"
    ]

    @classmethod
    async def process_audio_dictation(
        cls,
        audio_bytes: bytes,
        mime_type: str = "audio/m4a"
    ) -> Dict[str, Any]:
        if len(audio_bytes) < 1000:
            raise HTTPException(status_code=400, detail="ऑडियो फ़ाइल बहुत छोटी अथवा रिक्त है।")

        if len(audio_bytes) > 20 * 1024 * 1024:
            raise HTTPException(status_code=413, detail="ऑडियो फ़ाइल 20MB से अधिक नहीं होनी चाहिए।")

        base64_audio = base64.b64encode(audio_bytes).decode("utf-8")

        system_instruction = (
            "आप भारतीय जिला एवं उच्च न्यायालयों के आपराधिक अधिवक्ताओं के लिए विधिक डिक्टेशन एवं ऑडियो ट्रांसक्रिप्शन सहायक हैं। "
            "अधिवक्ता अक्सर कचेहरी, बार रूम या न्यायालय परिसर के शोर में बोलकर केस तथ्य, एफ.आई.आर. संख्या, गवाहों के बयान और "
            "कानूनी धाराएं रिकॉर्ड करते हैं। आपकी जिम्मेदारी है:\n"
            "1. ऑडियो को शुद्ध, प्रामाणिक न्यायालयीन देवनागरी हिंदी (Devanagari) में अक्षरशः लिखना।\n"
            "2. मु.अ.सं., धाराएं, थाना, तारीखें और अभियुक्तों के नामों को सही ढंग से पहचानना।\n"
            "3. ऑडियो से वाद-तथ्यों का संरचित JSON डेटा निकालना।"
        )

        user_prompt = """
        इस ऑडियो रिकॉर्डिंग को सुनें और निम्नलिखित कार्य करें:
        1. 'verbatim_transcript_hindi': ऑडियो का शुद्ध देवनागरी में पूर्ण प्रतिलेख (Transcript), पूर्ण विराम (।) और उपयुक्त विराम चिह्नों सहित।
        2. 'cleaned_factual_matrix': तथ्यों का सुव्यवस्थित, कालक्रमानुसार विवरण।
        3. 'extracted_entities': वाद से संबंधित विधिक इकाइयां (FIR, थाना, धाराएं, अभियुक्त, अभिरक्षा स्थिति)।
        4. 'chronological_events': घटनाक्रम के प्रमुख चरणों की सूची।

        प्रतिक्रिया केवल मान्य JSON प्रारूप में दें:
        {
          "verbatim_transcript_hindi": "...",
          "cleaned_factual_matrix": "...",
          "extracted_entities": {
            "fir_number": "124/2026",
            "police_station": "कोतवाली नगर",
            "district": "लखनऊ",
            "accused_names": ["श्यामू"],
            "complainant_name": "राम प्रकाश",
            "sections": ["379 IPC", "411 IPC"],
            "custody_status": "JUDICIAL_CUSTODY",
            "allegation_summary": "...",
            "defense_plea": "..."
          },
          "chronological_events": [
            "तारीख 10-02-2026 को कथित घटना...",
            "तारीख 12-02-2026 को पुलिस द्वारा गिरफ्तारी..."
          ]
        }
        """

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": settings.GEMINI_API_KEY
        }

        body = {
            "systemInstruction": {"parts": [{"text": system_instruction}]},
            "contents": [{
                "parts": [
                    {"text": user_prompt},
                    {
                        "inlineData": {
                            "mimeType": mime_type,
                            "data": base64_audio
                        }
                    }
                ]
            }],
            "generationConfig": {
                "temperature": 0.1,
                "responseMimeType": "application/json"
            }
        }

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                last_err = None
                for model_name in cls.CANDIDATE_VOICE_MODELS:
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
                    try:
                        response = await client.post(url, headers=headers, json=body)
                    except (httpx.TimeoutException, httpx.RequestError) as net_err:
                        last_err = f"{model_name}: Network/Timeout - {str(net_err)}"
                        logger.warning(f"Gemini voice timeout/error on {model_name}: {net_err}")
                        continue

                    if response.status_code == 200:
                        result_json = response.json()
                        raw_text = result_json["candidates"][0]["content"]["parts"][0]["text"]
                        clean_json = raw_text.strip()
                        if clean_json.startswith("```json"):
                            clean_json = clean_json[7:]
                        if clean_json.startswith("```"):
                            clean_json = clean_json[3:]
                        if clean_json.endswith("```"):
                            clean_json = clean_json[:-3]
                        parsed_data = json.loads(clean_json.strip())

                        # Post-process through PoliceDocumentSanitizer
                        parsed_data["verbatim_transcript_hindi"] = PoliceDocumentSanitizer.clean_and_normalize(
                            parsed_data.get("verbatim_transcript_hindi", "")
                        )
                        parsed_data["cleaned_factual_matrix"] = PoliceDocumentSanitizer.clean_and_normalize(
                            parsed_data.get("cleaned_factual_matrix", "")
                        )

                        return parsed_data
                    elif response.status_code in (404, 429, 500, 503):
                        last_err = f"{model_name}: HTTP {response.status_code} - {response.text}"
                        logger.warning(f"Gemini voice fallback from {model_name}: {response.status_code}")
                        continue
                    else:
                        raise HTTPException(
                            status_code=response.status_code,
                            detail=f"Gemini Voice Engine त्रुटि ({response.status_code}): {response.text}"
                        )

                raise HTTPException(status_code=502, detail=f"वॉयस ट्रांसक्रिप्शन मॉडल अनुपलब्ध: {last_err}")

        except json.JSONDecodeError:
            raise HTTPException(status_code=500, detail="AI ऑडियो प्रतिलेख को संरचित JSON में पार्स नहीं किया जा सका।")
        except Exception as e:
            if isinstance(e, HTTPException):
                raise e
            raise HTTPException(status_code=500, detail=f"वॉयस इनटेक विफलता: {str(e)}")
        finally:
            # Enforce immediate memory wipe of base64 buffer
            del base64_audio
