import json
import logging
import httpx
from typing import List, Dict, Any
from fastapi import HTTPException
from app.core.config import settings
from app.core.database import get_supabase_admin_client
from app.services.llm_gateway import LLMGateway

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

        dist = facts_payload.get("district", "लखनऊ")
        fir_no = facts_payload.get("fir_number", "124/2026")
        accused = facts_payload.get("accused_name") or "अभियुक्त"

        sections_str = ', '.join(facts_payload.get('sections', []))
        is_ndps = any(term in sections_str.lower() or term in (facts_payload.get('factual_summary') or '').lower() for term in ["ndps", "एनडीपीएस", "गांजा", "चरस", "स्मैक", "8/20", "8/21"])
        is_murder = any(term in sections_str.lower() for term in ["302", "103", "हत्या"])
        is_theft = any(term in sections_str.lower() for term in ["379", "411", "303", "317", "चोरी"])

        special_instructions = ""
        court_title = "न्यायालय मुख्य न्यायिक मजिस्ट्रेट"
        if is_ndps:
            court_title = "न्यायालय विशेष न्यायाधीश (एन.डी.पी.एस. अधिनियम)"
            special_instructions = (
                "विशेष निर्देश (NDPS अधिनियम): यह मामला स्वापक औषधि और मनःप्रभावी पदार्थ (NDPS) अधिनियम से संबंधित है। "
                "अनिवार्य रूप से धारा 50 (व्यक्तिगत तलाशी में राजपत्रित अधिकारी/मजिस्ट्रेट का विकल्प), धारा 42 (तलाशी प्रक्रिया), "
                "धारा 37 (मात्रा वर्गीकरण), धारा 52A (मजिस्ट्रेट के समक्ष इन्वेंटरी) के उल्लंघन के विधिक आधार तैयार करें। "
                "किसी भी स्थिति में चोरी (379 IPC / 303 BNS) या हत्या के प्रावधान न जोड़ें।"
            )
        elif is_murder:
            court_title = "न्यायालय अपर सत्र न्यायाधीश / सत्र न्यायालय"
            special_instructions = (
                "विशेष निर्देश (धारा 302 IPC / 103 BNS): यह मामला हत्या के गंभीर आरोप से संबंधित है। "
                "यदि मामला परिस्थितिजन्य साक्ष्य (Circumstantial Evidence) पर है, तो साक्ष्यों की कड़ी टूटने, "
                "मृत्यु का प्रत्यक्षदर्शी न होने, पोस्ट-मॉर्टम रिपोर्ट में विरोधाभास, और अकारण प्राथमिकी में विलंब के विधिक आधार तैयार करें।"
            )
        elif is_theft:
            court_title = "न्यायालय मुख्य न्यायिक मजिस्ट्रेट"
            special_instructions = (
                "विशेष निर्देश (धारा 379/411 IPC / 303 BNS): यह मामला चोरी/सम्पत्ति बरामदगी से संबंधित है। "
                "बरामदगी के समय स्वतंत्र पंच साक्षियों का अभाव, शिनाख्तगी (TIP) न होना, और 41A CrPC नोटिस का उल्लंघन के आधार तैयार करें।"
            )

        user_prompt = f"""
        निम्नलिखित आपराधिक मामले का गहन 360-डिग्री विधिक विश्लेषण करें:
        - एफ.आई.आर. संख्या: {fir_no}
        - संबंधित धाराएं: {sections_str}
        - थाना एवं जिला: {facts_payload.get('police_station')}, {dist}
        - अभियुक्त की स्थिति: {facts_payload.get('custody_status')}
        - घटना एवं अभियोजन कथानक: {facts_payload.get('factual_summary')}
        
        {special_instructions}
        
        महत्वपूर्ण: प्रत्येक विधिक आधार को सीधे न्यायालयीन भाषा में 'यह कि...' से प्रारंभ करें। कभी भी 'विधिक आधार 1' या कोष्ठक '(' जैसे लेबल न लगाएं।
        प्रतिक्रिया केवल निम्नलिखित शुद्ध JSON संरचना में दें:
        {{
          "court_header": "{court_title}, {dist}",
          "case_title": "राज्य बनाम {accused} (मु.अ.सं. {fir_no})",
          "statutory_grounds": [
            "यह कि अभियुक्त पूर्णतः निर्दोष है एवं उसे दुर्भावनापूर्वक फंसाया गया है...",
            "यह कि कथित घटना स्थल या बरामदगी के समय कोई निष्पक्ष स्वतंत्र साक्षी उपस्थित नहीं था...",
            "यह कि अभियुक्त का कोई पूर्व आपराधिक इतिहास नहीं है..."
          ],
          "prosecution_weaknesses": [
            "घटना स्थल पर निष्पक्ष स्वतंत्र साक्षियों का पूर्ण अभाव।",
            "अभियोजन कथानक में विधिक विरोधाभास एवं प्राथमिकी दर्ज करने में अकारण विलंब।"
          ],
          "procedural_objections": [
            "सांविधिक प्रक्रियात्मक नियमों का उल्लंघन किया जाना।",
            "गिरफ्तारी एवं तलाशी मेमो तैयार करने में प्रक्रियात्मक विधिक दोष।"
          ]
        }}
        """

        raw_draft = await LLMGateway.generate_structured_json(
            system_prompt=system_instruction,
            user_prompt=user_prompt,
            temperature=0.2
        )

        if not raw_draft.get("case_title"):
            raw_draft["case_title"] = f"राज्य बनाम {accused} (मु.अ.सं. {fir_no})"

        if not raw_draft.get("court_header"):
            raw_draft["court_header"] = f"{court_title}, {dist}"

        import re

        def _clean_placeholder(text: str) -> str:
            t = text.strip()
            t = re.sub(
                r'^(?:विधिक\s*आधार\s*\d+\s*[\(\:\-–\.]?\s*|अभियोजन(?:\s*कथानक)?\s*की\s*कमजोरी\s*\d+\s*[\(\:\-–\.]?\s*|प्रक्रियात्मक(?:\s*विधिक)?\s*आपत्ति\s*\d+\s*[\(\:\-–\.]?\s*|\d+[\.\)]\s*)',
                '',
                t,
                flags=re.IGNORECASE
            ).strip()
            if t.startswith('(') and t.endswith(')'):
                t = t[1:-1].strip()
            return t

        # Defensive Normalization: Guarantee that list fields are always List[str]
        def _normalize_to_list(val, default_items: List[str]) -> List[str]:
            if isinstance(val, list):
                cleaned = [_clean_placeholder(str(item)) for item in val if str(item).strip()]
                return cleaned if cleaned else default_items
            if isinstance(val, str) and val.strip():
                # Check for numbered points (1., 2., etc.) or newlines
                numbered = re.split(r'\s*\d+\.\s*', val)
                numbered = [_clean_placeholder(n.strip("- *• \t\n")) for n in numbered if n.strip("- *• \t\n")]
                if len(numbered) > 1:
                    return numbered
                lines = [_clean_placeholder(line.strip("- *• \t")) for line in val.split("\n") if line.strip("- *• \t")]
                return lines if lines else [_clean_placeholder(val.strip())]
            return default_items

        raw_draft["statutory_grounds"] = _normalize_to_list(
            raw_draft.get("statutory_grounds"),
            [
                "यह कि अभियुक्त निर्दोष है और उसे दुर्भावनापूर्वक झूठे मामले में फंसाया गया है।",
                "यह कि कथित बरामदगी के समय दंड प्रक्रिया संहिता की धारा 100(4) के आज्ञापक प्रावधानों का पालन नहीं किया गया और कोई निष्पक्ष स्वतंत्र साक्षी उपस्थित नहीं था।",
                "यह कि अभियुक्त का कोई पूर्व आपराधिक इतिहास नहीं है और वह न्यायालय के सभी आदेशों का पालन करने हेतु तैयार है।"
            ]
        )

        raw_draft["prosecution_weaknesses"] = _normalize_to_list(
            raw_draft.get("prosecution_weaknesses"),
            [
                "कथित घटना एवं बरामदगी के समय किसी भी स्वतंत्र व निष्पक्ष लोक साक्षी का उपस्थित न होना।",
                "अभियोजन कथानक में गंभीर विरोधाभास एवं एफ.आई.आर. दर्ज करने में अकारण विलंब होना।"
            ]
        )

        raw_draft["procedural_objections"] = _normalize_to_list(
            raw_draft.get("procedural_objections"),
            [
                "दंड प्रक्रिया संहिता की धारा 100(4) (समतुल्य BNSS 103) के अनिवार्य प्रावधानों का अनुपालन न किया जाना।",
                "गिरफ्तारी एवं तलाशी मेमो तैयार करने में प्रक्रियात्मक विधिक त्रुटि विद्यमान होना।"
            ]
        )

        self._deduct_user_quota(supabase, advocate_id, quota, 1200)
        return raw_draft


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
