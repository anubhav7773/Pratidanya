================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-04
MODULE         : GOOGLE GEMINI REST API, LLM PIPELINE & GROUNDED DRAFTING
TARGET RUNTIME : Python 3.10+ (FastAPI) / Google AI Studio & Cloud Gemini API
MODELS USED    : gemini-1.5-flash, gemini-1.5-pro, text-embedding-004, gemini-embedding-001
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. MODEL TAXONOMY & PRICING MATRIXPratidnya microservice mein teen standard AI engines integrate honge. Kisi bhi experimental ya deprecated model ka use codebase mein prohibited hai:Model IdentifierPratidnya Operational RoleContext WindowGeneration ConfigPaid Tier Pricing (Approx.)gemini-1.5-flashPrimary Drafting Engine: Bail grounds, prosecution weak points, chargesheet deconstruction1,000,000 tokenstemp: 0.2, topP: 0.9~$0.75 / 1M input tokens, ~$3.75 / 1M output tokens  gemini-1.5-proComplex Case Synthesis: Voluminous trial sessions, multiple witness contradictions, murder/NDPS charges2,000,000 tokenstemp: 0.15, topP: 0.85Higher tiered pricing; only for Chamber Pro subscriberstext-embedding-004Primary Vector Engine: 768-dimension dense vector representations for Hindi legal text2,048 tokens / chunkRETRIEVAL_DOCUMENT / RETRIEVAL_QUERYHigh efficiency batch embeddinggemini-embedding-001Fallback Vector Engine: Text-only semantic embeddings  2,048 tokens / chunkSemantic retrieval  ~$0.075 / 1M tokens  gemini-embedding-2Multimodal Fallback: Supports cross-modal text and document image inputs  Multimodal  Image/text retrieval  ~$0.20 / 1M tokens  (⚠️ VERIFY BEFORE USE: Production launch ke waqt Google AI Studio Console mein active rate limits aur dynamic quota tiers zaroor verify karein).  2. PRIVACY ARCHITECTURE & FREE-TIER VS. PAID-TIER MANDATEThe Statutory Privacy ThreatFree-Tier Policy: Google AI Studio ke Terms of Service ke mutabik Free-Tier API par submit kiya gaya input prompt, case facts, aur generated outputs Google ke engineers dwara review kiye ja sakte hain aur model training ke liye store hote hain.  Statutory Violations:Advocates Act 1961 (Section 126 Evidence Act / Attorney-Client Privilege): Lawyer apne client ki FIR, confession ya case strategy kisi teesre paksh ko disclose nahi kar sakta.  DPDP Act 2023 (Section 8 Security Safeguards): Sensitive personal legal data ka unauthorized leak ₹250 Crore tak ki penalty attract kar sakta hai.  System Dual-Track Architecture:Track A (Development / Local QA): Free-Tier allowed hai, lekin system mein strictly synthetic (kaalpanik) dummy data inject hoga. Real case facts pass karna codebase-level assertion se block rahega.  Track B (Pilot / Production Release): App ke launch hote hi Google AI Studio billing-linked Paid Tier (Tier 1) par jump karna mandatory hai. Paid Tier par zero-data retention hoti hai aur prompt data training ke liye use nahi hota.  ┌────────────────────────────────────────────────────────┐
│        PRATIDNYA PRIVACY GATEWAY (FASTAPI BACKEND)     │
└───────────────────────────┬────────────────────────────┘
                            │
              Is `GEMINI_PAID_TIER == True`?
             /                              \
            YES                              NO
           /                                  \
  [Production Mode]                    [Testing Sandbox]
  Real Client Facts Allowed             Only Synthetic Dummy Data
  Zero Data Retention         Is `is_dummy_data == True`?
  Commercial SLA Applied                      /               \
                                            YES                NO
                                             │                  │
                                         Processed      HTTP 403 FORBIDDEN
                                         via Free Tier  (Privacy Breach Blocked)
3. AUTHENTICATION & SECURITY PROXY PATTERNRULE 1 MANDATE: Flutter Client binary ke andar Google Gemini API Key kabhi bhi store nahi hogi. Sabhi calls Pratidnya FastAPI backend se proxy hongi.Backend HTTP Header ConfigurationHTTPPOST /v1beta/models/{model}:{method} HTTP/1.1
Host: generativelanguage.googleapis.com
Content-Type: application/json
x-goog-api-key: {{GEMINI_API_KEY}}
Supabase LLM Quota Tracking Table DDLHar lawyer ke daily AI usage, token consumption, aur billing quota ko track karne ke liye Supabase table schema:SQLcreate table public.advocate_ai_quotas (
    advocate_id text primary key references public.advocate_profiles(id) on delete cascade,
    subscription_tier text not null default 'FREE', -- 'FREE', 'PRO_CHAMBER'
    daily_drafts_remaining integer not null default 3,
    ad_rewarded_drafts integer not null default 0,
    total_tokens_consumed bigint not null default 0,
    last_quota_reset_date date not null default current_date,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Daily Reset Function for Free Tiers
create or replace function reset_daily_draft_quotas()
returns void as $$
begin
    update public.advocate_ai_quotas
    set 
        daily_drafts_remaining = case 
            when subscription_tier = 'PRO_CHAMBER' then 9999
            else 3 
        end,
        ad_rewarded_drafts = 0,
        last_quota_reset_date = current_date
    where last_quota_reset_date < current_date;
end;
$$ language plpgsql;
4. embedContent API SPECIFICATIONDistrict Court judgments aur FIR chunks ko 768-dimension vector mein convert karne ka verified format:A. Endpoint & ParametersURL: POST [https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent](https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent)B. Request JSON StructureJSON{
  "model": "models/text-embedding-004",
  "content": {
    "parts": [
      {
        "text": "अभियुक्त के विरुद्ध थाना कोतवाली में अपराध संख्या 124/2026, धारा 379 भा.दं.वि. (या 303 बी.एन.एस.) के अंतर्गत प्रथम सूचना रिपोर्ट दर्ज कराई गई है। कथित चोरी गई मोटरसाइकिल की बरामदगी के समय कोई स्वतंत्र साक्षी उपस्थित नहीं था।"
      }
    ]
  },
  "taskType": "RETRIEVAL_DOCUMENT",
  "title": "FIR_124_Section_379_Chunk_0"
}
Task Type Taxonomy:RETRIEVAL_DOCUMENT: Precedents, court judgments, ya chargesheet chunks ko database mein index karte waqt.RETRIEVAL_QUERY: Jab advocate search bar ya analysis engine mein query execute kare.SEMANTIC_SIMILARITY: Case diary aur police notes ke beech similarity compare karne ke liye.C. Response JSON StructureJSON{
  "embedding": {
    "values": [
      0.01429817,
      -0.03847291,
      0.00284918,
      -0.05219482,
      0.02194012,
      "... exactly 768 floating point numbers ..."
    ]
  }
}
5. generateContent API SPECIFICATION (360° LEGAL DRAFTING)Bail grounds aur case weak points generate karte waqt system instruction Devanagari Hindi ko strictly court-standards par force karta hai aur hallucination ko prohibit karta hai.  A. Endpoint & ParametersURL: POST [https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent](https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent)B. Request JSON Structure (Structured JSON Output)JSON{
  "systemInstruction": {
    "parts": [
      {
        "text": "आप 'प्रतिज्ञा' लीगल असिस्टेंट हैं, जो भारतीय जिला एवं अधीनस्थ न्यायालयों के आपराधिक अधिवक्ताओं के लिए कार्य करते हैं। आपका कार्य केवल दिए गए सत्यापित तथ्यों एवं विधिक धाराओं के आधार पर तकनीकी मसौदा तैयार करना है।\n\nअनिवार्य नियम:\n1. भाषा पूर्णतः प्रामाणिक न्यायालयीन हिंदी (Devanagari) होनी चाहिए (जैसे: 'आवेदक', 'अभियोजन', 'साक्षी', 'जब्ती फर्द')।\n2. आप अपनी ओर से कोई काल्पनिक केस-लॉ (Hallucinated Precedents) उद्धृत नहीं करेंगे।\n3. अभियोजन की कमियों, प्रक्रियात्मक त्रुटियों (धारा 100(4) दंड प्रक्रिया संहिता / बी.एन.एस.एस.) और जमानत के आधारों को स्पष्ट उपशीर्षकों में विभाजित करें।"
      }
    ]
  },
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "केस विवरण:\n- मुकदमा अपराध संख्या: 124/2026\n- थाना: कोतवाली नगर\n- धाराएं: 379, 411 भा.दं.वि. (समतुल्य धारा 303, 317(2) बी.एन.एस.)\n- न्यायालय: मुख्य न्यायिक मजिस्ट्रेट (CJM)\n- तथ्य: अभियुक्त से 3 दिन बाद कथित चोरी की मोटरसाइकिल बरामद दिखाई गई है। जब्ती के समय कोई पब्लिक गवाह नहीं था। अभियुक्त का कोई पूर्व आपराधिक इतिहास नहीं है।\n\nनिर्देश: सक्षम न्यायालय हेतु जमानत प्रार्थना पत्र के सुदृढ़ आधार (Grounds for Bail) और अभियोजन पक्ष की कमजोरियां JSON प्रारूप में तैयार करें।"
        }
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.2,
    "topP": 0.9,
    "maxOutputTokens": 2048,
    "responseMimeType": "application/json"
  }
}
C. Response JSON StructureJSON{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "{\n  \"court_header\": \"न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ\",\n  \"case_title\": \"राज्य बनाम श्यामू\",\n  \"statutory_grounds\": [\n    \"यह कि आवेदक/अभियुक्त पूर्णतः निर्दोष है तथा उसे स्थानीय पुलिस द्वारा दुर्भावनावश एवं रंजिशन झूठा फंसाया गया है।\",\n    \"यह कि प्रथम सूचना रिपोर्ट में आवेदक नामजद नहीं था तथा कथित घटना के तीन दिन उपरांत मनगढ़ंत बरामदगी दिखाकर अभियुक्त को आरोपित किया गया है।\",\n    \"यह कि कथित जब्ती के समय दंड प्रक्रिया संहिता की धारा 100(4) के आज्ञापक प्रावधानों का घोर उल्लंघन करते हुए किसी भी स्वतंत्र स्थानीय साक्षी को सम्मिलित नहीं किया गया।\",\n    \"यह कि आवेदक का कोई पूर्व आपराधिक इतिहास (Criminal Antecedents) नहीं है और वह समाज का प्रतिष्ठित नागरिक है।\",\n    \"यह कि कथित अपराध विचारणीय न्यायालय द्वारा मजिस्ट्रेट ट्रायल है और इसमें मृत्यु अथवा आजीवन कारावास का कोई प्रावधान नहीं है।\"\n  ],\n  \"prosecution_weaknesses\": [\n    \"मौके की जब्ती फर्द पर स्वतंत्र पंच साक्षियों के हस्ताक्षर न होना अभियोजन कथानक को प्रथम दृष्टया संदेहास्पद बनाता है।\",\n    \"बरामद माल की कोई शिनाख्तगी कार्यवाही (Test Identification Parade) नियमानुसार संपन्न नहीं कराई गई है।\"\n  ],\n  \"procedural_objections\": [\n    \"गिरफ्तारी के समय अर्नेश कुमार बनाम बिहार राज्य के दिशानिर्देशों (धारा 41ए दंड प्रक्रिया संहिता) का पालन नहीं किया गया।\"\n  ]\n}"
          }
        ],
        "role": "model"
      },
      "finishReason": "STOP",
      "safetyRatings": [
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "probability": "NEGLIGIBLE"
        }
      ]
    }
  ],
  "usageMetadata": {
    "promptTokenCount": 184,
    "candidatesTokenCount": 462,
    "totalTokenCount": 646
  }
}
6. BACKEND PYTHON ENGINE (gemini_service.py)FastAPI backend service jo privacy checks, streaming generation, embeddings extraction, aur token usage tracking execute karti hai:Python# app/services/gemini_service.py
import json
import httpx
from typing import List, Dict, Any, AsyncGenerator
from fastapi import HTTPException
from app.core.config import settings
from app.core.supabase_client import get_supabase_admin_client

class GeminiService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.is_paid_tier = settings.GEMINI_PAID_TIER
        self.enforce_dummy_data = settings.ENFORCE_DUMMY_DATA
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models"

    def _verify_privacy_firewall(self, is_dummy_data: bool):
        """Rule 6: Blocks real case facts on Free-Tier."""
        if not self.is_paid_tier and not is_dummy_data:
            raise HTTPException(
                status_code=403,
                detail="गोपनीयता सुरक्षा निषेध: फ्री-टियर पर वास्तविक वाद तथ्यों का प्रसंस्करण प्रतिबंधित है। "
                       "अधिवक्ता गोपनीयता और DPDP अधिनियम 2023 की धारा 8 का अनुपालन सुनिश्चित करें।"[cite: 1]
            )

    async def generate_dense_embedding(
        self,
        text: str,
        task_type: str = "RETRIEVAL_DOCUMENT",
        is_dummy_data: bool = True
    ) -> List[float]:
        self._verify_privacy_firewall(is_dummy_data)

        url = f"{self.base_url}/text-embedding-004:embedContent"
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.api_key
        }
        payload = {
            "model": "models/text-embedding-004",
            "content": {"parts": [{"text": text.strip()}]},
            "taskType": task_type
        }

        async with httpx.AsyncClient(timeout=12.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Gemini Embedding API विफलता: {response.text}"
                )
            
            data = response.json()
            return data["embedding"]["values"]

    async def generate_structured_case_analysis(
        self,
        advocate_id: str,
        facts_payload: Dict[str, Any],
        is_dummy_data: bool = True
    ) -> Dict[str, Any]:
        self._verify_privacy_firewall(is_dummy_data)

        # Quota Deduction Verification
        supabase = get_supabase_admin_client()
        quota_record = supabase.table("advocate_ai_quotas") \
            .select("daily_drafts_remaining, subscription_tier, ad_rewarded_drafts") \
            .eq("advocate_id", advocate_id) \
            .single() \
            .execute()

        quota = quota_record.data
        if quota["subscription_tier"] != "PRO_CHAMBER":
            if quota["daily_drafts_remaining"] <= 0 and quota["ad_rewarded_drafts"] <= 0:
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

        url = f"{self.base_url}/gemini-1.5-flash:generateContent"
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
                "maxOutputTokens": 2048,
                "responseMimeType": "application/json"
            }
        }

        async with httpx.AsyncClient(timeout=40.0) as client:
            response = await client.post(url, headers=headers, json=body)
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=f"Gemini API त्रुटि: {response.text}")

            result = response.json()
            raw_text = result["candidates"][0]["content"]["parts"][0]["text"]
            usage = result.get("usageMetadata", {})
            total_tokens = usage.get("totalTokenCount", 0)

            # Deduct Quota & Track Usage
            self._deduct_user_quota(supabase, advocate_id, quota, total_tokens)

            try:
                return json.loads(raw_text)
            except json.JSONDecodeError:
                raise HTTPException(status_code=500, detail="AI प्रतिक्रिया को JSON में पार्स नहीं किया जा सका।")

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
7. FLUTTER INTEGRATION & DEVANAGARI STREAMING CONTROLLERRiverpod 2.x controller jo backend se generated 360-degree JSON draft ko consume karta hai aur Devanagari font rendering standard maintain karta hai:Dart// lib/src/features/04_draft_generator/presentation/controllers/drafting_controller.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/app_environment.dart';
import '../../domain/case_analysis_draft.dart';

part 'drafting_controller.g.dart';

@riverpod
class DraftingController extends _$DraftingController {
  @override
  FutureOr<CaseAnalysisDraft?> build() {
    return null;
  }

  Future<void> generateBailDraft({
    required String firNumber,
    required List<String> sections,
    required String policeStation,
    required String district,
    required String factualSummary,
    required String custodyStatus,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('प्रमाणीकरण आवश्यक है: कृपया पुनः लॉगिन करें।');
      }

      final idToken = await user.getIdToken();
      final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/drafts/generate-360');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'fir_number': firNumber,
          'sections': sections,
          'police_station': policeStation,
          'district': district,
          'factual_summary': factualSummary,
          'custody_status': custodyStatus,
          'is_dummy_testing': AppEnvironment.enforceDummyData,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return CaseAnalysisDraft.fromJson(decoded);
      } else if (response.statusCode == 402) {
        throw Exception('दैनिक कोटा समाप्त हो गया है। जारी रखने के लिए विज्ञापन देखें या प्रो अपग्रेड करें।');
      } else {
        throw Exception('ड्राफ्ट निर्माण विफल (${response.statusCode}):${response.body}');
      }
    });
  }
}
Dart// lib/src/features/04_draft_generator/domain/case_analysis_draft.dart
class CaseAnalysisDraft {
  final String courtHeader;
  final String caseTitle;
  final List<String> statutoryGrounds;
  final List<String> prosecutionWeaknesses;
  final List<String> proceduralObjections;

  CaseAnalysisDraft({
    required this.courtHeader,
    required this.caseTitle,
    required this.statutoryGrounds,
    required this.prosecutionWeaknesses,
    required this.proceduralObjections,
  });

  factory CaseAnalysisDraft.fromJson(Map<String, dynamic> json) {
    return CaseAnalysisDraft(
      courtHeader: json['court_header'] as String? ?? 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट',
      caseTitle: json['case_title'] as String? ?? 'राज्य बनाम अभियुक्त',
      statutoryGrounds: List<String>.from(json['statutory_grounds'] ?? []),
      prosecutionWeaknesses: List<String>.from(json['prosecution_weaknesses'] ?? []),
      proceduralObjections: List<String>.from(json['procedural_objections'] ?? []),
    );
  }
}
8. LLM COST OPTIMIZATION & MONETIZATION BRIDGEEk standard 360-degree case analysis draft generation mein lagbhag 650 se 900 total tokens kharch hote hain. Paid Tier par iski unit cost calculate karke humne quota tier design kiya hai:$$\text{Cost per Draft} \approx \frac{200 \text{ prompt tokens}}{1,000,000} \times \$0.75 + \frac{500 \text{ candidate tokens}}{1,000,000} \times \$3.75 \approx \$0.00015 + \$0.00187 = \$0.00202 \approx \text{₹}0.17$$   ┌────────────────────────────────────────────────────────┐
   │               ADVOCATE QUOTA WORKFLOW                  │
   └───────────────────────────┬────────────────────────────┘
                               │
                Free User: 3 Daily Drafts Available?
                               │
               ┌───────────────┴───────────────┐
              YES                              NO
               │                               │
        Draft Generated             Trigger Paywall Dialog
       (Token Tracked)                         │
                                ┌──────────────┴──────────────┐
                                ▼                             ▼
                        Watch Rewarded Ad             Upgrade to Pro Chamber
                       (AdMob Ad Loaded)              (Google Play Billing)
                                │                             │
                        +1 Draft Unlocked             Unlimited Drafts Unlocked
9. ANTIGRAVITY NON-NEGOTIABLE CODING RULES (DOC-04)Antigravity Gemini integration code likhte waqt in exact safety conditions ko enforce karega:[ ] Direct Google Gemini client package (google_generative_ai) Flutter frontend mein import nahi hoga. Sabhi operations FastAPI proxy se execute honge.[ ] Embedding dimension validation: Embedding vectors ki array length strictly 768 honi chahiye (text-embedding-004).[ ] Hallucination prevention: Drafting ke liye temperature parameter 0.2 se zyada nahi rakha jayega.[ ] Privacy check enforcement: Agar GEMINI_PAID_TIER == False ho aur request mein is_dummy_data == False ho, toh backend ko HTTP 403 Forbidden return karna mandatory hai[cite: 1].[ ] User quota deduction transaction atomicity: Draft generate hone ke baad hi advocate_ai_quotas table mein remaining count deduct hoga.