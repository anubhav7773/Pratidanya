import json
import re
import httpx
from typing import Dict, Any, List
from fastapi import HTTPException
from app.core.config import settings
from app.services.text_sanitizer import PoliceDocumentSanitizer
from app.schemas.trial_judgment_schema import (
    TrialCourtMetadata,
    WitnessContradiction,
    ProceduralOmission,
    TrialJudgmentAnalysisResponse
)

class HighCourtJudgmentParser:
    """
    Deconstructs Trial Court Judgments to extract Operative Sentences, Coram,
    PW Depositions, Section 313 CrPC statement flaws, and synthesis of Appeal/Revision grounds.
    """

    CANDIDATE_MODELS = [
        "gemini-3.6-flash",
        "gemini-3.1-flash-lite",
        "gemini-flash-latest",
        "gemini-3.5-flash",
        "gemini-3.7-flash",
        "gemini-3.8-flash",
    ]

    @classmethod
    async def analyze_trial_judgment(
        cls,
        raw_text: str,
        total_pages: int,
        pleading_type: str = "CRIMINAL_APPEAL"
    ) -> TrialJudgmentAnalysisResponse:
        sanitized_text = PoliceDocumentSanitizer.clean_and_normalize(raw_text)
        word_count = len(sanitized_text.split())

        # Extract Operative Part using regex anchor
        operative_part = cls._extract_operative_order(sanitized_text)

        # Call Gemini with structured legal extraction prompt
        extracted_data = await cls._execute_deep_legal_extraction(sanitized_text, pleading_type)

        meta = extracted_data.get("metadata", {})
        metadata_obj = TrialCourtMetadata(
            court_name=meta.get("court_name", "न्यायालय अपर सत्र न्यायाधीश, लखनऊ"),
            case_number=meta.get("case_number", "सत्र परीक्षण संख्या 00/2021"),
            judgment_date=meta.get("judgment_date", "2024-01-01"),
            presiding_judge=meta.get("presiding_judge", "अपर सत्र न्यायाधीश"),
            convicted_sections=meta.get("convicted_sections", ["307 IPC"]),
            quantum_of_sentence=meta.get("quantum_of_sentence", "कठोर कारावास"),
            accused_names=meta.get("accused_names", ["अभियुक्त"]),
            police_station=meta.get("police_station", "कोतवाली"),
            district=meta.get("district", "लखनऊ"),
            fir_number=meta.get("fir_number", "00/2021")
        )

        witness_flaws = [WitnessContradiction(**w) for w in extracted_data.get("witness_flaws", [])]
        procedural_omissions = [ProceduralOmission(**p) for p in extracted_data.get("procedural_omissions", [])]

        grounds = cls._synthesize_appeal_grounds(
            analysis_data=extracted_data,
            pleading_type=pleading_type,
            metadata=metadata_obj
        )

        return TrialJudgmentAnalysisResponse(
            metadata=metadata_obj,
            operative_sentence_hindi=operative_part or extracted_data.get("operative_sentence_hindi", "दंडादेश उपलब्ध नहीं"),
            ocular_vs_medical_conflict=extracted_data.get("ocular_vs_medical_conflict"),
            section_313_examination_defects=extracted_data.get("section_313_examination_defects"),
            malkhana_link_evidence_defects=extracted_data.get("malkhana_link_evidence_defects"),
            witness_flaws=witness_flaws,
            procedural_omissions=procedural_omissions,
            total_pages_processed=total_pages,
            raw_word_count=word_count,
            extracted_appeal_grounds=grounds
        )

    @classmethod
    def _extract_operative_order(cls, text: str) -> str:
        # Locates typical Indian judgment operative conclusion markers
        patterns = [
            r"(आदेश\s*[:\-].*?$)",
            r"(दंडादेश\s*[:\-].*?$)",
            r"(उपरोक्त\s*विवेचना\s*के\s*आधार\s*पर.*?दोषसिद्ध\s*किया\s*जाता\s*है.*?$)",
            r"(अतः\s*अभियुक्त.*?सजा\s*सुनाई\s*जाती\s*है.*?$)"
        ]
        for pattern in patterns:
            match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
            if match:
                return match.group(1).strip()[:1500]
        # Fallback to last 1200 characters if no explicit header matches
        return text[-1200:].strip()

    @classmethod
    async def _execute_deep_legal_extraction(cls, text: str, pleading_type: str) -> Dict[str, Any]:
        system_prompt = (
            "आप भारतीय उच्च न्यायालयों के आपराधिक अपीलीय अधिकारिता (Criminal Appellate & Revisional Jurisdiction) "
            "के विशेषज्ञ विधिक विश्लेषक हैं। अधीनस्थ न्यायालय (Trial Court) के निर्णय का विश्लेषण कर शुद्ध JSON में "
            "दोषसिद्धि, दंडादेश, साक्षियों के अंतर्विरोध, धारा 313 के दोष, और विधिक त्रुटियों को निकालें।"
        )

        # Context truncation to fit token budget (middle slice preservation if large)
        condensed_text = text if len(text) <= 30000 else (text[:18000] + "\n...[मध्य भाग छोड़ा गया]...\n" + text[-12000:])

        user_prompt = f"""
        प्रकार: {pleading_type}
        
        निम्नलिखित अधीनस्थ न्यायालय के आक्षेपित निर्णय (Impugned Judgment) का गहन विधिक परीक्षण करें:
        \"\"\"{condensed_text}\"\"\"

        केवल निम्नलिखित JSON संरचना में उत्तर दें:
        {{
          "metadata": {{
            "court_name": "न्यायालय का नाम",
            "case_number": "सत्र परीक्षण संख्या",
            "judgment_date": "YYYY-MM-DD",
            "presiding_judge": "पीठासीन अधिकारी का नाम",
            "convicted_sections": ["307 IPC", "323 IPC"],
            "quantum_of_sentence": "सजा का विवरण (अवधि व जुर्माना)",
            "accused_names": ["अभियुक्तों के नाम"],
            "police_station": "थाना",
            "district": "जिला",
            "fir_number": "मु.अ.सं."
          }},
          "operative_sentence_hindi": "अवर न्यायालय का दंडादेश",
          "ocular_vs_medical_conflict": "चश्मदीद गवाहों एवं डॉक्टर की मेडिकल/पोस्टमार्टम रिपोर्ट में अंतर्विरोध",
          "section_313_examination_defects": "धारा 313 के बयान में अभियुक्त के समक्ष महत्वपूर्ण परिस्थितियों को न रखने का दोष",
          "malkhana_link_evidence_defects": "कथित बरामदगी मालखाने में रखने व FSL भेजने में विधिक कमियां",
          "witness_flaws": [
            {{
              "witness_name": "PW-1 या PW-2",
              "statement_extract": "गवाही का अंश",
              "contradiction_nature": "विरोधाभास का प्रकार",
              "impact_on_prosecution": "अभियोजन पर प्रभाव"
            }}
          ],
          "procedural_omissions": [
            {{
              "stage_name": "प्रक्रियात्मक चरण",
              "statutory_mandate": "संबंधित विधिक धारा",
              "defect_description": "अवर न्यायालय की त्रुटि",
              "relevance_to_appeal": "अपील का आधार"
            }}
          ]
        }}
        """

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": settings.GEMINI_API_KEY
        }
        body = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
            "generationConfig": {
                "temperature": 0.1,
                "responseMimeType": "application/json"
            }
        }

        async with httpx.AsyncClient(timeout=45.0) as client:
            last_err = None
            for model_name in cls.CANDIDATE_MODELS:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
                try:
                    response = await client.post(url, headers=headers, json=body)
                    if response.status_code == 200:
                        result = response.json()
                        raw_json_str = result["candidates"][0]["content"]["parts"][0]["text"]
                        return json.loads(raw_json_str)
                    elif response.status_code in (404, 503, 429):
                        last_err = f"{model_name} HTTP {response.status_code}: {response.text}"
                        continue
                    else:
                        raise HTTPException(status_code=502, detail=f"निर्णय विश्लेषण विफलता: {response.text}")
                except HTTPException:
                    raise
                except Exception as ex:
                    last_err = str(ex)
                    continue

            raise HTTPException(status_code=502, detail=f"निर्णय विश्लेषण विफलता: {last_err}")

    @classmethod
    def _synthesize_appeal_grounds(
        cls,
        analysis_data: Dict[str, Any],
        pleading_type: str,
        metadata: TrialCourtMetadata
    ) -> List[str]:
        grounds = []

        if pleading_type == "CRIMINAL_APPEAL":
            grounds.append(
                f"यह कि विद्वान अवर न्यायालय ({metadata.court_name}) द्वारा पारित आक्षेपित निर्णय एवं दंडादेश "
                f"दिनांकित {metadata.judgment_date} पूर्णतः विधि विरुद्ध, तथ्यों के विपरीत एवं साक्ष्य के विकृत मूल्यांकन (Perverse Appreciation) पर आधारित है।"
            )

            if analysis_data.get("ocular_vs_medical_conflict"):
                grounds.append(
                    f"यह कि चश्मदीद अभियोजन साक्षियों के बयानों एवं चिकित्सकीय साक्ष्य (Medical Evidence) के मध्य "
                    f"गंभीर अंतर्विरोध विद्यमान है: {analysis_data['ocular_vs_medical_conflict']}। अवर न्यायालय ने इस विधिक त्रुटि की उपेक्षा की है।"
                )

            if analysis_data.get("section_313_examination_defects"):
                grounds.append(
                    f"यह कि दंड प्रक्रिया संहिता की धारा 313 (समतुल्य BNSS 351) के आज्ञापक प्रावधानों का घोर उल्लंघन किया गया है। "
                    f"दोषसिद्धि हेतु प्रयुक्त महत्वपूर्ण परिस्थितियों को अभियुक्त के समक्ष व्यक्तिगत रूप से स्पष्टीकरण हेतु नहीं रखा गया।"
                )

            for flaw in analysis_data.get("witness_flaws", [])[:3]:
                grounds.append(
                    f"यह कि {flaw['witness_name']} का बयान पूर्णतः अविश्वसनीय है; {flaw['contradiction_nature']}, "
                    f"जिसके आधार पर अभियुक्त को दोषी ठहराया जाना प्राकृतिक न्याय के विरुद्ध है।"
                )

            grounds.append(
                "यह कि अभियोजन पक्ष अभियुक्त के विरुद्ध संदेह से परे (Beyond Reasonable Doubt) मामला सिद्ध करने में पूर्णतः विफल रहा है, "
                "अतः अभियुक्त संदेह का लाभ (Benefit of Doubt) पाकर दोषमुक्त किए जाने योग्य है।"
            )

        elif pleading_type == "CRIMINAL_REVISION":
            grounds.append(
                f"यह कि विद्वान अवर न्यायालय ने आक्षेपित आदेश पारित करने में अपने क्षेत्राधिकार की सीमा का उल्लंघन (Jurisdictional Error) "
                f"किया है और यह आदेश अभिलेख पर प्रथम दृष्टया अवैध एवं विकृत (Patently Illegal and Perverse) है।"
            )
            grounds.append(
                "यह कि दंड प्रक्रिया संहिता की धारा 397/401 के अंतर्गत इस माननीय उच्च न्यायालय को अवर न्यायालय के आदेश की वैधता, शुद्धता "
                "एवं औचित्य (Legality, Correctness and Propriety) का पुनरीक्षण करने का पूर्ण क्षेत्राधिकार प्राप्त है।"
            )

        return grounds
