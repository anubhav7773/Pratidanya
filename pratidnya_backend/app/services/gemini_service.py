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
        summary_text = (facts_payload.get('factual_summary') or '').lower()
        combined_text = f"{sections_str.lower()} {summary_text}"

        # 1. Dynamic Court Determination across ALL Indian Central & State Statutes
        if any(term in combined_text for term in ["ndps", "एनडीपीएस", "गांजा", "चरस", "स्मैक", "8/20", "8/21"]):
            court_title = f"न्यायालय विशेष न्यायाधीश (एन.डी.पी.एस. अधिनियम), {dist}"
            domain_specific = (
                "विशेष निर्देश (NDPS अधिनियम): व्यक्तिगत तलाशी में धारा 50 एन.डी.पी.एस. का आज्ञापक अनुपालन, "
                "तलाशी व जब्ती में धारा 42 व 52A का उल्लंघन, धारा 37 के प्रतिबंध की गैर-प्रयोज्यता (मात्रा वर्गीकरण), "
                "और नमूना सील करने की प्रक्रियात्मक त्रुटि के विधिक आधार तैयार करें।"
            )
        elif any(term in combined_text for term in ["pocso", "पोक्सो", "नाबालिग", "छेड़छाड़", "दुष्कर्म"]):
            court_title = f"न्यायालय विशेष न्यायाधीश (पॉक्सो अधिनियम) / अपर सत्र न्यायालय, {dist}"
            domain_specific = (
                "विशेष निर्देश (पॉक्सो अधिनियम): पीड़िता की आयु निर्धारण में धारा 94 जे.जे. एक्ट के सांविधिक अनुक्रम का उल्लंघन, "
                "चिकित्सीय परीक्षण (MLC) में बाह्य/आंतरिक चोट का अभाव, धारा 164 बयानों में विरोधाभास, और "
                "पारिवारिक रंजिश अथवा प्रेम-प्रसंग के चलते दुर्भावनापूर्ण आरोप के आधार तैयार करें।"
            )
        elif any(term in combined_text for term in ["sc/st", "scst", "अत्याचार", "हरिजन", "जातिसूचक"]):
            court_title = f"न्यायालय विशेष न्यायाधीश (एस.सी./एस.टी. अत्याचार निवारण अधिनियम), {dist}"
            domain_specific = (
                "विशेष निर्देश (SC/ST अधिनियम): कथित घटना का किसी 'सार्वजनिक दृष्टिगोचर स्थान' (Public View) में घटित न होना (हितेश वर्मा सिद्धांत), "
                "नियम 7 SC/ST नियमावली के तहत Dy.SP स्तर के अधिकारी द्वारा जांच का अभाव, और पूर्व दीवानी/भूमि विवाद के चलते झूठी नामजदगी के आधार तैयार करें।"
            )
        elif any(term in combined_text for term in ["gangster", "गैंगस्टर", "गिरोहबंद"]):
            court_title = f"न्यायालय विशेष न्यायाधीश (गैंगस्टर अधिनियम) / अपर सत्र न्यायालय, {dist}"
            domain_specific = (
                "विशेष निर्देश (गैंगस्टर अधिनियम): संगठित गिरोह का सदस्य न होना, बेस केसों में पहले से नियमित जमानत पर होना, "
                "सक्षम जिला मजिस्ट्रेट द्वारा विवेक का सकारण प्रयोग न किया जाना, तथा गिरोहबंद नियमावली के नियम 5, 16, 17 का उल्लंघन।"
            )
        elif any(term in combined_text for term in ["pmla", "uapa", "ईडी", "धन शोधन", "यूएपीए"]):
            court_title = f"न्यायालय विशेष न्यायाधीश (PMLA / UAPA) / सत्र न्यायालय, {dist}"
            domain_specific = (
                "विशेष निर्देश (PMLA / UAPA): विजय मदनलाल चौधरी सिद्धांत (अनुसूचित अपराध के बिना PMLA नहीं), "
                "संविधान के अनुच्छेद 21 के तहत त्वरित विचारण का मौलिक अधिकार (मनीष सिसोदिया 2024 व के.ए. नजीब सिद्धांत), "
                "हजारों दस्तावेजों के चलते निकट भविष्य में विचारण संपन्न न होना, और अपराध की आय से सीधा जुड़ाव न होना।"
            )
        elif any(term in combined_text for term in ["corruption", "भ्रष्टाचार", "रिश्वत", "pc act", "pc_act"]):
            court_title = f"न्यायालय विशेष न्यायाधीश (भ्रष्टाचार निवारण अधिनियम / CBI), {dist}"
            domain_specific = (
                "विशेष निर्देश (PC Act): अवैध पारितोषिक की 'डिमांड एवं एक्सेप्टेंस' का प्राथमिक ठोस साक्ष्य न होना (नीरज दत्ता सिद्धांत), "
                "कथित ट्रैप कार्रवाई में स्वतंत्र पंच साक्षियों का अभाव, और विभागीय कार्य लंबित न होने का आधार।"
            )
        elif any(term in combined_text for term in ["302", "103", "307", "109", "304b", "80", "376", "64", "हत्या", "कत्ल", "बलात्कार", "डकैती"]):
            court_title = f"न्यायालय सत्र न्यायाधीश / अपर सत्र न्यायाधीश, {dist}"
            domain_specific = (
                "विशेष निर्देश (गंभीर सत्र विचारणीय अपराध): परिस्थितिजन्य साक्ष्य की कड़ी टूटना (शरद बिरधीचंद सिद्धांत), "
                "प्रत्यक्षदर्शी साक्षी का अभाव, चिकित्सकीय रिपोर्ट (Post-Mortem/MLC) में विरोधाभास, घटना स्थल से कोई अनन्य बरामदगी न होना, "
                "और अकारण प्राथमिकी दर्ज कराने में गंभीर संदेहास्पद विलंब।"
            )
        else:
            court_title = f"न्यायालय मुख्य न्यायिक मजिस्ट्रेट / अपर मुख्य न्यायिक मजिस्ट्रेट, {dist}"
            domain_specific = (
                "विशेष निर्देश (सांविधिक विश्लेषण): आरोपित धाराओं के प्रत्येक आवश्यक तत्व (Essential Ingredients) के अभाव का विश्लेषण करें। "
                "यदि 7 वर्ष तक की सजा है तो धारा 35 BNSS (41A CrPC) नोटिस का उल्लंघन और अर्नेश कुमार दिशानिर्देशों की अवहेलना को प्रमुख आधार बनाएं। "
                "यदि जब्ती या बरामदगी है तो धारा 103 BNSS (100(4) CrPC) के तहत स्वतंत्र लोक साक्षियों की अनुपस्थिति और सचेत आधिपत्य का अभाव स्पष्ट करें। "
                "यदि मामला संविदा, लेनदेन या संपत्ति का है तो दीवानी विवाद को आपराधिक रंग देने (मोहम्मद इब्राहिम सिद्धांत) का आधार तैयार करें।"
            )

        user_prompt = f"""
        निम्नलिखित आपराधिक मामले का गहन 360-डिग्री सूक्ष्म विधिक विश्लेषण करें:
        - एफ.आई.आर. संख्या: {fir_no}
        - संबंधित धाराएं: {sections_str}
        - थाना एवं जिला: {facts_payload.get('police_station')}, {dist}
        - अभियुक्त की स्थिति: {facts_payload.get('custody_status')}
        - घटना एवं अभियोजन कथानक: {facts_payload.get('factual_summary')}
        
        {domain_specific}
        
        निर्देश:
        1. आरोपित धाराओं ({sections_str}) के तहत अपराध के आवश्यक विधिक तत्वों की पूर्ति न होने का सूक्ष्म विश्लेषण करें।
        2. भारतीय नागरिक सुरक्षा संहिता 2023 (BNSS) एवं दंड प्रक्रिया संहिता 1973 के आज्ञापक प्रक्रियात्मक नियमों के उल्लंघन को प्रमुखता दें।
        3. घटना स्थल, समय, एफ.आई.आर. विलंब, और स्वतंत्र साक्षियों की अनुपस्थिति को रक्षा के तथ्यों से जोड़ें।
        4. संविधान के अनुच्छेद 21 एवं स्थापित सिद्धांत कि 'जमानत नियम है और जेल अपवाद' (बाबू सिंह / संजय चंद्रा सिद्धांत) को समाहित करें।
        5. प्रत्येक विधिक आधार को सीधे न्यायालयीन भाषा में 'यह कि...' से प्रारंभ करें। कभी भी 'विधिक आधार 1' या कोष्ठक '(' जैसे लेबल न लगाएं।
        
        प्रतिक्रिया केवल निम्नलिखित शुद्ध JSON संरचना में दें:
        {{
          "court_header": "{court_title}",
          "case_title": "राज्य बनाम {accused} (मु.अ.सं. {fir_no})",
          "statutory_grounds": [
            "यह कि अभियुक्त पूर्णतः निर्दोष है एवं उसे केवल संदेह व स्थानीय रंजिश के कारण दुर्भावनापूर्वक झूठा नामित किया गया है...",
            "यह कि अभियोजन कथानक में आरोपित धाराओं के प्राथमिक सांविधिक तत्वों का पूर्ण अभाव है...",
            "यह कि कथित घटना अथवा बरामदगी के समय किसी भी स्वतंत्र व निष्पक्ष लोक साक्षी को सम्मिलित नहीं किया गया...",
            "यह कि पुलिस द्वारा धारा 35 BNSS (समतुल्य धारा 41A CrPC) के अनिवार्य नोटिस प्रक्रिया का अनुपालन नहीं किया गया...",
            "यह कि अभियुक्त समाज का कानून-सम्मत नागरिक है, उसका कोई पूर्व आपराधिक इतिहास नहीं है तथा वह न्यायालय द्वारा नियत सभी शर्तों का पालन करने को तत्पर है।"
          ],
          "prosecution_weaknesses": [
            "आरोपित धाराओं के आवश्यक तत्वों का प्राथमिक स्तर पर स्थापित न होना एवं घटना का कोई स्वतंत्र निष्पक्ष साक्षी न होना।",
            "अभियोजन कथानक में गंभीर विधिक विरोधाभास एवं एफ.आई.आर. दर्ज कराने में अकारण संदेहास्पद विलंब होना।"
          ],
          "procedural_objections": [
            "दंड प्रक्रिया संहिता / भारतीय नागरिक सुरक्षा संहिता के आज्ञापक प्रावधानों एवं गिरफ्तारी नियमों की घोर अवहेलना।",
            "जब्ती एवं तलाशी के समय स्वतंत्र लोक साक्षियों को न बुलाकर प्रक्रियात्मक विधिक दोष उत्पन्न करना।"
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
