import json
import logging
import httpx
from typing import List, Dict, Any
from fastapi import HTTPException
from app.core.config import settings
from app.core.database import get_supabase_admin_client

logger = logging.getLogger("pratidnya.gemini")

class GeminiService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.is_paid_tier = settings.GEMINI_PAID_TIER
        self.enforce_dummy_data = settings.ENFORCE_DUMMY_DATA
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models"

    def _verify_privacy_firewall(self, is_dummy_data: bool):
        """Rule 6: Blocks non-dummy facts on Free Tier."""
        if not self.is_paid_tier and not is_dummy_data:
            raise HTTPException(
                status_code=403,
                detail="गोपनीयता सुरक्षा निषेध: फ्री-टियर पर वास्तविक वाद तथ्यों का प्रसंस्करण प्रतिबंधित है। "
                       "अधिवक्ता गोपनीयता और DPDP अधिनियम 2023 की धारा 8 का अनुपालन अनिवार्य है।"
            )

    async def generate_dense_embedding(
        self,
        text: str,
        task_type: str = "RETRIEVAL_DOCUMENT",
        is_dummy_data: bool = True
    ) -> List[float]:
        self._verify_privacy_firewall(is_dummy_data)

        candidate_models = [
            ("gemini-embedding-001", {"model": "models/gemini-embedding-001", "content": {"parts": [{"text": text.strip()}]}, "taskType": task_type, "outputDimensionality": 768}),
            ("gemini-embedding-2", {"model": "models/gemini-embedding-2", "content": {"parts": [{"text": text.strip()}]}, "taskType": task_type, "outputDimensionality": 768}),
            ("text-embedding-004", {"model": "models/text-embedding-004", "content": {"parts": [{"text": text.strip()}]}, "taskType": task_type})
        ]

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.api_key
        }

        async with httpx.AsyncClient(timeout=15.0) as client:
            last_err = None
            for model_name, payload in candidate_models:
                url = f"{self.base_url}/{model_name}:embedContent"
                response = await client.post(url, headers=headers, json=payload)
                if response.status_code == 200:
                    data = response.json()
                    values = data.get("embedding", {}).get("values", [])
                    if len(values) == 768:
                        return values
                    raise HTTPException(
                        status_code=500,
                        detail=f"अमान्य वेक्टर आयाम (Dimension): 768 अपेक्षित, {len(values)} प्राप्त।"
                    )
                elif response.status_code == 404:
                    last_err = response.text
                    continue
                else:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Gemini Embedding API विफलता: {response.text}"
                    )
            raise HTTPException(
                status_code=502,
                detail=f"कोई भी संगत एम्बेडिंग मॉडल उपलब्ध नहीं: {last_err}"
            )

    async def generate_structured_case_analysis(
        self,
        advocate_id: str,
        facts_payload: Dict[str, Any],
        is_dummy_data: bool = True
    ) -> Dict[str, Any]:
        self._verify_privacy_firewall(is_dummy_data)

        supabase = get_supabase_admin_client()
        try:
            quota_record = supabase.table("advocate_ai_quotas") \
                .select("daily_drafts_remaining, subscription_tier, ad_rewarded_drafts") \
                .eq("advocate_id", advocate_id) \
                .maybe_single() \
                .execute()
            quota = quota_record.data if quota_record else None
        except Exception:
            quota = None

        if not quota:
            quota = {"subscription_tier": "FREE", "daily_drafts_remaining": 3, "ad_rewarded_drafts": 0}
            try:
                supabase.table("advocate_ai_quotas").upsert({
                    "advocate_id": advocate_id,
                    "subscription_tier": "FREE",
                    "daily_drafts_remaining": 3,
                    "ad_rewarded_drafts": 0
                }).execute()
            except Exception:
                pass

        if quota.get("subscription_tier") != "PRO_CHAMBER":
            if quota.get("daily_drafts_remaining", 0) <= 0 and quota.get("ad_rewarded_drafts", 0) <= 0:
                raise HTTPException(
                    status_code=402,
                    detail="दैनिक ड्राफ्टिंग कोटा समाप्त। अतिरिक्त ड्राफ्ट के लिए विज्ञापन देखें या प्रो चैंबर में अपग्रेड करें।"
                )

        system_instruction = (
            "आप 'प्रतिज्ञा' लीगल असिस्टेंट हैं। आप केवल भारतीय जिला एवं अधीनस्थ न्यायालयों के "
            "आपराधिक अधिवक्ताओं के लिए विधिक ड्राफ्ट तैयार करते हैं। भाषा प्रामाणिक न्यायालयीन हिंदी "
            "(Devanagari) होनी चाहिए। कभी भी काल्पनिक केस-लॉ या अप्रमाणित निर्णय उद्धृत न करें।"
        )

        user_prompt = f"""
        निम्नलिखित आपराधिक मामले का गहन 360-डिग्री विधिक विश्लेषण करें:
        - एफ.आई.आर. संख्या: {facts_payload.get('fir_number')}
        - संबंधित धाराएं: {', '.join(facts_payload.get('sections', []))}
        - थाना एवं जिला: {facts_payload.get('police_station')}, {facts_payload.get('district')}
        - अभियुक्त की स्थिति: {facts_payload.get('custody_status')}
        - घटना एवं अभियोजन कथानक: {facts_payload.get('factual_summary')}
        
        प्रतिक्रिया केवल मान्य JSON में दें जिसमें 'court_header', 'statutory_grounds', 
        'prosecution_weaknesses', aur 'procedural_objections' शामिल हों।
        """

        candidate_gen_models = [
            "gemini-3.1-flash-lite",
            "gemini-3.5-flash",
            "gemini-3.7-flash",
            "gemini-3.8-flash"
        ]

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.api_key
        }
        body = {
            "systemInstruction": {"parts": [{"text": system_instruction}]},
            "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
            "generationConfig": {
                "temperature": 0.2,
                "topP": 0.9,
                "maxOutputTokens": 8192,
                "responseMimeType": "application/json"
            }
        }

        async with httpx.AsyncClient(timeout=20.0) as client:
            last_err = None
            for model_name in candidate_gen_models:
                url = f"{self.base_url}/{model_name}:generateContent"
                try:
                    response = await client.post(url, headers=headers, json=body)
                except (httpx.TimeoutException, httpx.RequestError) as net_err:
                    last_err = f"{model_name}: Network/Timeout - {str(net_err)}"
                    logger.warning(f"Gemini timeout/error on {model_name}, failing over to next model: {net_err}")
                    continue

                if response.status_code == 200:
                    result = response.json()
                    raw_text = result["candidates"][0]["content"]["parts"][0]["text"]
                    usage = result.get("usageMetadata", {})
                    total_tokens = usage.get("totalTokenCount", 0)

                    self._deduct_user_quota(supabase, advocate_id, quota, total_tokens)

                    clean_json = raw_text.strip()
                    if clean_json.startswith("```json"):
                        clean_json = clean_json[7:]
                    if clean_json.startswith("```"):
                        clean_json = clean_json[3:]
                    if clean_json.endswith("```"):
                        clean_json = clean_json[:-3]
                    clean_json = clean_json.strip()

                    try:
                        return json.loads(clean_json)
                    except json.JSONDecodeError as jde:
                        logger.error(f"JSON decode failed on response from {model_name}: {jde}")
                        raise HTTPException(status_code=500, detail="AI प्रतिक्रिया को JSON में पार्स नहीं किया जा सका।")
                elif response.status_code in (404, 429, 500, 503):
                    last_err = f"{model_name}: HTTP {response.status_code} - {response.text}"
                    logger.warning(f"Gemini generation fallback from {model_name}: {response.status_code}")
                    continue
                else:
                    raise HTTPException(status_code=response.status_code, detail=f"Gemini API त्रुटि: {response.text}")

            raise HTTPException(status_code=502, detail=f"कोई भी संगत जनरेटिव मॉडल उपलब्ध नहीं: {last_err}")


    def _deduct_user_quota(self, supabase, advocate_id: str, quota: Dict[str, Any], tokens: int):
        if quota["subscription_tier"] != "PRO_CHAMBER":
            if quota["daily_drafts_remaining"] > 0:
                supabase.table("advocate_ai_quotas") \
                    .update({
                        "daily_drafts_remaining": quota["daily_drafts_remaining"] - 1,
                        "total_tokens_consumed": quota.get("total_tokens_consumed", 0) + tokens,
                        "updated_at": "now()"
                    }) \
                    .eq("advocate_id", advocate_id) \
                    .execute()
            elif quota["ad_rewarded_drafts"] > 0:
                supabase.table("advocate_ai_quotas") \
                    .update({
                        "ad_rewarded_drafts": quota["ad_rewarded_drafts"] - 1,
                        "total_tokens_consumed": quota.get("total_tokens_consumed", 0) + tokens,
                        "updated_at": "now()"
                    }) \
                    .eq("advocate_id", advocate_id) \
                    .execute()
