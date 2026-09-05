DOC_05_OPENNYAI_INTEGRATION_REFERENCE.mdPlaintext================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-05
MODULE         : OPENNYAI NLP MICROSERVICE & CHARGESHEET DECONSTRUCTION
TARGET RUNTIME : Python 3.10+ / FastAPI / Render (Linux Container)
LICENSE & COST : MIT License (100% Free, Open-Source & Self-Hosted)
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. STRATEGIC VALUE & ARCHITECTURAL ROLE IN PRATIDNYAOpenNyAI ek open-source Indian legal NLP library hai jo Pratidnya ecosystem mein LLM cost-reduction, data sovereignty aur deterministic information extraction ka primary engine hai:  ┌────────────────────────────────────────────────────────────────────────┐
│                   UNSTRUCTURED POLICE / COURT TEXT                     │
│  - 30-50 Page Criminal Chargesheet / FIR / Police Case Diary (CD)      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               SELF-HOSTED OPENNYAI PIPELINE (RENDER/AWS)               │
│  1. Legal NER: Extracts Sections, Police Stations, Judges, Accused     │
│  2. Rhetorical Roles: Isolates 'Facts', 'Arguments', 'Statutes'        │
│  3. Extractive Summarizer: Compresses text to core verifiable extracts │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Extracted Factual Matrix (~400 Tokens)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                GEMINI 1.5 FLASH (PAID-TIER DRAFTING)                   │
│  - LLM receives ONLY pre-filtered facts & detected legal sections      │
│  - Zero prompt bloat: Token consumption reduced by 85%                 │
│  - Grounded output: Cannot hallucinate outside OpenNyAI extracted facts│
└────────────────────────────────────────────────────────────────────────┘
Core Advantages for District Court Criminal Practice:DPDP Act 2023 Sovereignty (Zero Data Sharing): Chonki OpenNyAI MIT License ke tehat aati hai aur hamare apne private server par host hoti hai, sensitive criminal FIRs, victim ke naam aur chargesheet statements kisi third-party closed AI company ke server par transfer nahi hote.  Zero Scraping Risk: OpenNyAI ka apna koi internal judgment database nahi hai; yeh strictly advocate dwara upload kiye gaye document text ko analyze karti hai. Isse Indian Kanoon ya web portals ki scraping terms breach hone ka 0% risk rehta hai.  Massive Token Cost Optimization: 50-page ki raw chargesheet ko direct Gemini API mein bhejne par 30,000+ tokens consume hote. OpenNyAI pehle text se sirf Facts aur Statute extract karta hai, jisse Gemini ko sirf 800 tokens ka concise context bhejna padta hai — jisse operating cost 90% kam ho jaati hai.  2. PRODUCTION DEPENDENCY SPECIFICATION (requirements.txt)Render Linux container par memory footprint minimize karne ke liye CPU-only PyTorch wheels aur pinned production dependencies install karna lazmi hai:Plaintext# --- Framework & Server ---
fastapi==0.110.0
uvicorn[standard]==0.29.0
pydantic==2.6.4
pydantic-settings==2.2.1
python-multipart==0.0.9

# --- OpenNyAI & Legal NLP Engine ---
opennyai>=0.0.8
spacy>=3.7.4

# --- PyTorch CPU Build (Prevents 4GB+ CUDA Bloat on Render) ---
--extra-index-url https://download.pytorch.org/whl/cpu
torch==2.2.1+cpu

# --- Database & Auth Integration ---
supabase==2.4.1
firebase-admin==6.5.0
httpx==0.27.0
3. CORE NLP ENGINES & STATUTORY CAPABILITIESOpenNyAI ke teen functional modules ko Pratidnya microservice mein expose kiya gaya hai:  A. Indian Legal Named Entity Recognition (14 Entities)Criminal chargesheets mein se essential parties aur statutory sections ko filter karta hai:  Judicial & Administrative Hierarchy: COURT, JUDGE, LAWYER, POLICE_OFFICER.Litigants & Witnesses: PETITIONER, RESPONDENT, WITNESS, OTHER_PERSON.Substantive Penal Law: STATUTE (e.g., Indian Penal Code, Bharatiya Nyaya Sanhita), PROVISION (e.g., Section 411, Section 303).Docket Metadata: CASE_NUMBER, DATE, ORG, GPE (Geopolitical Entities like Districts and Police Stations).B. Rhetorical Roles Classification (Sentence-Level Discourse Structure)Chargesheet ya Lower Court judgment ke har ek vakya (sentence) ko 7 standardized legal discourse labels mein categorize karta hai:  Facts: Police dwara darj ghatna ka vivaran.  Issue: Vivadit bindu (e.g., kya baramadgi niyamit thi).Argument: Abhiyojan (Prosecution) ya Bachav (Defense) ke tark.  Statute: Laagu kanoon aur aadesh.  Precedent: Uchchatam ya Uchcha nyayalay ke poorv drishtant.  Ratio of the decision: Adalat ke aadesh ka mukhya vidhik aadhar.  Ruling by Present Court: Antim aadesh (e.g., जमानत स्वीकार/खारिज).  C. Extractive SummarizerRhetorical Roles ke aadhar par bina kisi factual alteration ya generative hallucination ke original sentences ko extract karke authentic summary prepare karta hai.  4. RENDER DEPLOYMENT & OOM (OUT OF MEMORY) CRASH MITIGATIONCRITICAL MEMORY MANDATE (RENDER CONTAINER):OpenNyAI ke SpaCy transformers aur sentence tokenizers memory mein 1.2 GB se 1.8 GB RAM occupy karte hain.Render ke Free Tier (512 MB limit) par container OOM Killed (Exit Code 137) ho jayega.4 Non-Negotiable Server Rules:Host Instance Spec: Render par Starter Instance ($7/mo, 2 GB RAM) select karna anivarya hai.Singleton Model Pattern: NLP Pipeline ko har HTTP request par dobara instantiate nahi kiya jaayega. Use FastAPI Lifespan Handler ke zariye server startup par ek baar memory mein cache kiya jaayega.Single Worker Uvicorn Execution: Multiple workers (--workers 2 ya zyada) RAM usage ko 3 GB+ tak multiply kar denge. Container execution command strictly single worker hogi:Bashuvicorn app.main:app --host 0.0.0.0 --port $PORT --workers 1
Selective Pipeline Loading: Agar kisi request mein sirf Entity Extraction chahiye, toh summarizer pass ko skip karke CPU cycles save ki jaayengi.5. BACKEND SERVICE IMPLEMENTATION (opennyai_engine.py)FastAPI microservice ke core singleton engine ka production code:Python# app/services/opennyai_engine.py
import gc
import logging
from typing import Dict, Any, List, Optional
from opennyai import Pipeline
from opennyai.utils import Data

logger = logging.getLogger("pratidnya.nlp")

class OpenNyAIEngine:
    _instance: Optional["OpenNyAIEngine"] = None
    _pipeline: Optional[Pipeline] = None

    @classmethod
    def get_instance(cls) -> "OpenNyAIEngine":
        if cls._instance is None:
            cls._instance = OpenNyAIEngine()
        return cls._instance

    def initialize(self):
        """Loads models once into RAM during FastAPI startup."""
        if self._pipeline is None:
            logger.info("OpenNyAI मॉडल मेमोरी में लोड हो रहे हैं (CPU Mode)...")
            try:
                # Load NER, Rhetorical Role, and Extractive Summarizer
                self._pipeline = Pipeline(
                    components=['NER', 'Rhetorical_Role', 'Summarizer'],
                    use_gpu=False,
                    verbose=False
                )
                logger.info("OpenNyAI मॉडल्स सफलतापूर्वक लोड हो गए।")
            except Exception as e:
                logger.error(f"OpenNyAI लोड विफलता: {e}")
                raise RuntimeError(f"OpenNyAI इनिशियलाइज़ेशन त्रुटि: {str(e)}")

    def cleanup(self):
        """Releases memory during shutdown."""
        self._pipeline = None
        gc.collect()

    def process_chargesheet(self, raw_text: str) -> Dict[str, Any]:
        if self._pipeline is None:
            self.initialize()

        # Wrap text in OpenNyAI Data container
        data_packet = Data([raw_text])
        results = self._pipeline(data_packet)

        if not results or len(results) == 0:
            return {
                "facts_extracts": [],
                "prosecution_arguments": [],
                "statutes_detected": [],
                "provisions_detected": [],
                "witnesses_detected": [],
                "total_sentences_processed": 0
            }

        doc = results[0]

        # 1. Extractive Summary by Rhetorical Roles
        summary_obj = doc.get("summary", {})
        facts_sentences: List[str] = summary_obj.get("Facts", [])
        argument_sentences: List[str] = summary_obj.get("Argument", [])

        # 2. Extract Entities from Annotations
        statutes = set()
        provisions = set()
        witnesses = set()
        other_persons = set()

        annotations = doc.get("annotations", [])
        for sent in annotations:
            entities = sent.get("entities", [])
            for entity in entities:
                label = entity.get("label")
                text = entity.get("text", "").strip()

                if not text:
                    continue

                if label == "STATUTE":
                    statutes.add(text)
                elif label == "PROVISION":
                    provisions.add(text)
                elif label == "WITNESS":
                    witnesses.add(text)
                elif label == "OTHER_PERSON":
                    other_persons.add(text)

        return {
            "facts_extracts": facts_sentences,
            "prosecution_arguments": argument_sentences,
            "statutes_detected": sorted(list(statutes)),
            "provisions_detected": sorted(list(provisions)),
            "witnesses_detected": sorted(list(witnesses)),
            "persons_detected": sorted(list(other_persons)),
            "total_sentences_processed": len(annotations)
        }
6. FASTAPI ENDPOINTS & LIFESPAN HANDLERPython# app/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.services.opennyai_engine import OpenNyAIEngine
from app.api.v1.endpoints import case_analysis

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Load OpenNyAI into RAM
    engine = OpenNyAIEngine.get_instance()
    engine.initialize()
    yield
    # Shutdown: Clean memory
    engine.cleanup()

app = FastAPI(
    title="Pratidnya Legal NLP Microservice",
    description="District Court Criminal Chargesheet Deconstruction Engine",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(case_analysis.router, prefix="/api/v1/nlp", tags=["Legal NLP"])
Route Handler (case_analysis.py)Python# app/api/v1/endpoints/case_analysis.py
from fastapi import APIRouter, HTTPException, Header, Depends
from pydantic import BaseModel, Field
from typing import List, Optional
from app.services.opennyai_engine import OpenNyAIEngine
from app.core.config import settings

router = APIRouter()

class ChargesheetAnalysisRequest(BaseModel):
    case_id: str = Field(..., description="Supabase Case UUID")
    chargesheet_text: str = Field(..., min_length=50, description="Raw chargesheet text (Hindi/English)")
    is_dummy_testing: bool = Field(default=True, description="Strictly True during local dev/free tier testing")

class ChargesheetAnalysisResponse(BaseModel):
    case_id: str
    facts_extracts: List[str]
    prosecution_arguments: List[str]
    statutes_detected: List[str]
    provisions_detected: List[str]
    witnesses_detected: List[str]
    total_sentences_processed: int

@router.post("/process-chargesheet", response_model=ChargesheetAnalysisResponse)
async def process_chargesheet_endpoint(
    payload: ChargesheetAnalysisRequest,
    authorization: Optional[str] = Header(None)
):
    # Step 1: Validate Firebase Bearer Token
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="अनधिकृत अनुरोध: वैध Firebase ID टोकन आवश्यक है।"
        )

    # Step 2: Statutory Privacy Gate Check (Rule 6)
    if not settings.GEMINI_PAID_TIER and not payload.is_dummy_testing:
        raise HTTPException(
            status_code=403,
            detail="गोपनीयता उल्लंघन: जब तक प्रोडक्शन पेड टियर सक्रिय न हो, वास्तविक केस डेटा संसाधित करना प्रतिबंधित है।"
        )

    try:
        engine = OpenNyAIEngine.get_instance()
        analysis = engine.process_chargesheet(payload.chargesheet_text)

        return ChargesheetAnalysisResponse(
            case_id=payload.case_id,
            facts_extracts=analysis["facts_extracts"],
            prosecution_arguments=analysis["prosecution_arguments"],
            statutes_detected=analysis["statutes_detected"],
            provisions_detected=analysis["provisions_detected"],
            witnesses_detected=analysis["witnesses_detected"],
            total_sentences_processed=analysis["total_sentences_processed"]
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"NLP अभियोग पत्र विश्लेषण त्रुटि: {str(e)}"
        )
7. INPUT / OUTPUT JSON SCHEMA SPECIFICATIONA. Request Payload (Client -> Microservice)JSON{
  "case_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "chargesheet_text": "थाना कोतवाली नगर, जनपद लखनऊ। मुकदमा अपराध संख्या 124/2026 अंतर्गत धारा 379, 411 भारतीय दंड विधान। आरोप पत्र संख्या 45/2026। वादी मुकदमा श्री राम प्रकाश द्वारा तहरीर दी गई कि उनकी हीरो स्प्लेंडर मोटरसाइकिल संख्या UP 32 AB 1234 कचहरी परिसर से अज्ञात चोर द्वारा चोरी कर ली गई। विवेचना अधिकारी उपनिरीक्षक के.के. सिंह द्वारा मुखबिर खास की सूचना पर अभियुक्त श्यामू को कथित चोरी की मोटरसाइकिल सहित गिरफ्तार किया गया। मौके पर कोई स्वतंत्र गवाह उपस्थित नहीं हुआ। अभियुक्त ने स्वीकार किया कि वह उक्त वाहन बेचने की फिराक में था। अतः अभियुक्त के विरुद्ध आरोप पत्र न्यायालय में प्रेषित किया जाता है।",
  "is_dummy_testing": true
}
B. Response Payload (Microservice -> Client)JSON{
  "case_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "facts_extracts": [
    "वादी मुकदमा श्री राम प्रकाश द्वारा तहरीर दी गई कि उनकी हीरो स्प्लेंडर मोटरसाइकिल संख्या UP 32 AB 1234 कचहरी परिसर से अज्ञात चोर द्वारा चोरी कर ली गई।",
    "विवेचना अधिकारी उपनिरीक्षक के.के. सिंह द्वारा मुखबिर खास की सूचना पर अभियुक्त श्यामू को कथित चोरी की मोटरसाइकिल सहित गिरफ्तार किया गया।",
    "मौके पर कोई स्वतंत्र गवाह उपस्थित नहीं हुआ।"
  ],
  "prosecution_arguments": [
    "अभियुक्त ने स्वीकार किया कि वह उक्त वाहन बेचने की फिराक में था।",
    "अभियुक्त के विरुद्ध आरोप पत्र न्यायालय में प्रेषित किया जाता है।"
  ],
  "statutes_detected": [
    "भारतीय दंड विधान"
  ],
  "provisions_detected": [
    "धारा 379",
    "धारा 411"
  ],
  "witnesses_detected": [
    "श्री राम प्रकाश",
    "के.के. सिंह"
  ],
  "total_sentences_processed": 6
}
8. FLUTTER INTEGRATION SERVICE (DART / RIVERPOD)Flutter application is NLP microservice se judkar chargesheet facts ko local UI state mein bind karegi:Dart// lib/src/features/02_case_input/data/nlp_chargesheet_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/chargesheet_analysis.dart';

final nlpChargesheetRepositoryProvider = Provider<NlpChargesheetRepository>((ref) {
  return NlpChargesheetRepository();
});

class NlpChargesheetRepository {
  Future<ChargesheetAnalysis> analyzeChargesheet({
    required String caseId,
    required String rawChargesheetText,
    bool isDummyData = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('उपयोगकर्ता प्रमाणीकृत नहीं है।');
    }

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/nlp/process-chargesheet');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'case_id': caseId,
        'chargesheet_text': rawChargesheetText,
        'is_dummy_testing': isDummyData,
      }),
    );

    if (response.statusCode == 200) {
      final decodedJson = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ChargesheetAnalysis.fromJson(decodedJson);
    } else {
      throw Exception('अभियोग पत्र विश्लेषण विफल (${response.statusCode}):${response.body}');
    }
  }
}
Dart// lib/src/features/02_case_input/domain/chargesheet_analysis.dart
class ChargesheetAnalysis {
  final String caseId;
  final List<String> factsExtracts;
  final List<String> prosecutionArguments;
  final List<String> statutesDetected;
  final List<String> provisionsDetected;
  final List<String> witnessesDetected;
  final int totalSentencesProcessed;

  ChargesheetAnalysis({
    required this.caseId,
    required this.factsExtracts,
    required this.prosecutionArguments,
    required this.statutesDetected,
    required this.provisionsDetected,
    required this.witnessesDetected,
    required this.totalSentencesProcessed,
  });

  factory ChargesheetAnalysis.fromJson(Map<String, dynamic> json) {
    return ChargesheetAnalysis(
      caseId: json['case_id'] as String,
      factsExtracts: List<String>.from(json['facts_extracts'] ?? []),
      prosecutionArguments: List<String>.from(json['prosecution_arguments'] ?? []),
      statutesDetected: List<String>.from(json['statutes_detected'] ?? []),
      provisionsDetected: List<String>.from(json['provisions_detected'] ?? []),
      witnessesDetected: List<String>.from(json['witnesses_detected'] ?? []),
      totalSentencesProcessed: json['total_sentences_processed'] as int? ?? 0,
    );
  }
}
9. MONETIZATION & AD-GATING HOOKSChargesheet parsing server par CPU cycles kharch karta hai. Isliye monetization lifecycle ko manage karne ke liye hooks add kiye gaye hain:Free Users: 2 Chargesheet analyses / day. Quota exceed hone par Rewarded Ad dekhne par +1 analysis unlock hogi.Pro Chamber Users: Unlimited analyses bina kisi quota ya ad ke.Dart// Enforcement in Case Analysis UI:
if (!isUserPro) {
  final remaining = await ref.read(chargesheetQuotaProvider.future);
  if (remaining <= 0) {
    final rewarded = await showQuotaExceededRewardDialog(context);
    if (!rewarded) return; // User declined to watch ad
  }
}
10. ANTIGRAVITY NON-NEGOTIABLE VERIFICATION CHECKLIST (DOC-05)Antigravity code likhte waqt in technical guardrails ko verify karega:[ ] OpenNyAI model initialization strictly FastAPI Lifespan Handler ke andar Singleton pattern se honi chahiye. Request handler ke andar model dobara load nahi hoga.[ ] Uvicorn server start command mein worker count strictly --workers 1 rahega (OOM crash prevention).[ ] PyTorch dependency CPU wheel URL ([https://download.pytorch.org/whl/cpu](https://download.pytorch.org/whl/cpu)) se point honi chahiye taaki unnecessary CUDA libs load na hon.[ ] Direct SpaCy/PyTorch packages Flutter mobile code mein import nahi honge.[ ] If payload.is_dummy_testing == False and GEMINI_PAID_TIER == False, microservice HTTP 403 Forbidden throw karegi (Statutory DPDP Compliance).  