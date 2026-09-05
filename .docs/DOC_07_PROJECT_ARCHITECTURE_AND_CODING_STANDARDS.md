================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-07
MODULE         : PROJECT ARCHITECTURE, CONSTITUTION & CODING STANDARDS
TARGET RUNTIME : Flutter 3.19+ / FastAPI (Python 3.10+) / PostgreSQL 15+
ROLE & PURPOSE : ANTIGRAVITY PERMANENT CODING CONSTITUTION (NON-NEGOTIABLE)
================================================================================
1. MISSION STATEMENT & PHASE-1 BOUNDARY SPECIFICATIONPratidnya ek specialized, Hindi-first, AI-powered criminal legal research aur drafting workspace hai jo exclusive roop se State Bar Councils ke enrolled licensed advocates ke liye banaya gaya hai. Parent company Asiverticals ke statutory guidelines ke tehat, yeh platform subordinate aur district courts ke criminal docket backlog ko tackle karne ke liye tayyar kiya gaya hai.  Phase-1 Functional Scope (Criminal Domain Only)Subordinate courts ke kul pending mukadmo ka 78.2% hissa criminal cases (4.05+ Crore cases) ka hai. Isliye Phase 1 ka scope strictly niche diye gaye linear workflow tak seemit rahega:  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   MODULE 01:    │ ──> │   MODULE 02:    │ ──> │   MODULE 03:    │
│  ONBOARDING &   │     │  CRIMINAL CASE  │     │ PRECEDENT RAG & │
│  BAR ENROLLMENT │     │   INPUT MATRIX  │     │ VERIFIED SEARCH │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                         │
                                                         ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   MODULE 05:    │ <── │   MODULE 04:    │ <── │   GROUNDING &   │
│ VERIFY-BEFORE-  │     │ 360° DRAFTING & │     │ EXTRACTIVE      │
│   EXPORT GATE   │     │ ANALYSIS STUDIO │     │ VERIFICATION    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
Strictly Out-of-Scope (Phase-1 Prohibitions):Civil Law Prohibitions: Property disputes, partition suits, family/matrimonial matters, aur commercial recovery Phase 1 mein implement nahi honge.Predictive Analytics Ban: Case ka outcome predict karne wale feature (jaise "Bail milne ki 85% sambhavna") strictly prohibited hain. Judicial outcomes predict karna speculative hai aur court ethics ke khilaf hai.  Public / Citizen Facing Portals: Kisi bhi aam nagrik (litigant) ke liye direct consultation ya self-drafting tool nahi banega. Violations Advocates Act 1961 ke Section 45 ke tehat unauthorized practice of law (6 mahine tak ki imprisonment) maane jayenge.  Judge / Bench Portals: Judicial officers ke liye koi dashboard ya scoring mechanism develop nahi kiya jaayega.2. UNIFIED REPOSITORY TOPOLOGY (MONOREPO SPECIFICATION)Antigravity ko files kisi flat structure mein accumulate nahi karni hain. Project repo ka exact file-tree specification niche diya gaya hai:Plaintextpratidnya/
├── .github/
│   └── workflows/
│       ├── test_and_lint.yml                  # CI pipeline: Lints & privacy assertions
│       └── license_compliance.yml             # Audits MIT & package dependencies
│
├── docs/                                      # Reference specifications (Doc 1 to 12)
│   ├── DOC_01_FLUTTER_SETUP_REFERENCE.md
│   ├── DOC_02_SUPABASE_INTEGRATION_REFERENCE.md
│   ├── ...
│   └── DOC_07_PROJECT_ARCHITECTURE_AND_CODING_STANDARDS.md
│
├── pratidnya_mobile/                          # Flutter 3.19+ Mobile Client
│   ├── android/
│   ├── ios/
│   ├── assets/
│   │   ├── fonts/
│   │   │   └── NotoSansDevanagari-Regular.ttf
│   │   └── icons/
│   ├── lib/
│   │   ├── main.dart                          # App Bootstrap (Env validation)
│   │   ├── src/
│   │   │   ├── app.dart                       # MaterialApp & Riverpod Scope
│   │   │   ├── core/
│   │   │   │   ├── config/                    # Environment assertions & Constants
│   │   │   │   ├── network/                   # Http client with Firebase Auth interceptor
│   │   │   │   ├── router/                    # go_router with 3 mandatory gates
│   │   │   │   ├── theme/                     # Devanagari typography & court palette
│   │   │   │   └── utils/                     # Postgrest error mappers & date parsers
│   │   │   ├── features/
│   │   │   │   ├── 01_onboarding/             # Bar Council Verification & DPDP Screen
│   │   │   │   ├── 02_case_input/             # Criminal Case Diary & Chargesheet Input
│   │   │   │   ├── 03_precedent_search/       # Vector Retrieval & kanoon.dev UI
│   │   │   │   ├── 04_draft_generator/        # 360° Bail & Defense Drafting Studio
│   │   │   │   └── 05_verify_and_export/      # Non-Bypassable Verification Checklist
│   │   │   └── shared/                        # Shared UI components & disclaimer banners
│   │   └── pubspec.yaml
│   └── test/
│
├── pratidnya_backend/                         # FastAPI (Python 3.10+) Microservice
│   ├── app/
│   │   ├── main.py                            # FastAPI entry point & Lifespan handler
│   │   ├── core/
│   │   │   ├── config.py                      # Pydantic BaseSettings & Env guards
│   │   │   ├── security.py                    # Firebase JWT Token Decoders
│   │   │   └── database.py                    # Supabase Client connection pool
│   │   ├── services/
│   │   │   ├── opennyai_engine.py             # Singleton Legal NLP (NER + Rhetorical)
│   │   │   ├── gemini_service.py              # Paid-Tier LLM & Embedding service
│   │   │   ├── kanoon_service.py              # kanoon.dev API client with caching
│   │   │   └── grounding_validator.py         # Extractive text-matching verification
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── router.py                  # Consolidated API router
│   │   │       └── endpoints/
│   │   │           ├── nlp.py                 # Chargesheet deconstruction
│   │   │           ├── precedents.py          # Vector search endpoints
│   │   │           ├── drafts.py              # 360° Bail drafting
│   │   │           └── export.py              # Verification status verification
│   │   └── schemas/                           # Pydantic schemas for request/response
│   ├── tests/
│   │   ├── fixtures/                          # Synthetic dummy JSON files
│   │   └── test_grounding_validator.py        # Zero-hallucination unit tests
│   ├── Dockerfile                             # Containerized for Render Deployment
│   └── requirements.txt                       # CPU-only PyTorch & pinned versions
│
└── supabase/                                  # Supabase Cloud Database Migrations
    ├── migrations/
    │   ├── 20260101000001_advocate_profiles.sql
    │   ├── 20260101000002_cases_and_proceedings.sql
    │   ├── 20260101000003_pgvector_hnsw.sql
    │   └── 20260101000004_dpdp_audit_logs.sql
    └── config.toml
3. THE 10 NON-NEGOTIABLE CONSTITUTIONAL COMMANDMENTSYeh 10 niyam Antigravity ke code-generation engine ke liye permanent "constitution" hain. Inka koi exception ya bypass allowed nahi hai:COMMANDMENT 1: NO HALLUCINATED CITATIONSThe Rule: AI model kabhi bhi apni parametric training-memory se kisi case-law, citation number, ya high court judge ka naam assume nahi karega.  Technical Enforcement: Har precedent citation database pool (verified_precedents) ya live API (kanoon.dev) se fetch honi chahiye aur uske sath ek active, verified source link (verified_source_url ya pdf_download_url) hona anivarya hai.  Failure Behavior: Agar kisi precedent ka source-link 404 hai ya null hai, backend use response array se drop kar dega. Wo citation UI par kabhi render nahi hogi.COMMANDMENT 2: EXTRACTIVE-ONLY GROUNDINGThe Rule: AI draft mein create ki gayi har factual statement ko advocate ke raw input ya retrieved court copy ke kisi exact paragraph se trace kiya ja sakna chahiye.  Technical Enforcement: Draft export hone se pehle backend grounding_validator.py extractive substring/Levenshtein matching algorithm chalayega. Agar quoted paragraph source text mein 90% similarity se match nahi hota, toh verification fail ho jayegi.COMMANDMENT 3: "NOT FOUND = ABSTAIN"The Rule: Agar advocate ke facts ke mutabik hamare curated vector database mein 65% (similarity_threshold >= 0.65) se upar ka koi precedent match nahi milta, toh system guess nahi karega.Technical Enforcement: System clean empty state return karega aur UI par PrecedentAbstainWidget render karega:"आपके द्वारा दर्ज तथ्यों के लिए कोई पुष्ट कानूनी मिसाल नहीं मिली। कृपया मैन्युअल शोध करें।"COMMANDMENT 4: MANDATORY VERIFY-BEFORE-EXPORT GATEThe Rule: AI dwara tayyar kiya gaya bail application ya case analysis PDF tab tak download ya export nahi ho sakta jab tak advocate har ek cited judgment aur factual ground ko manually check/tick na kare.  Technical Enforcement: Flutter client mein ExportButton tab tak disable rahega jab tak isAllCitationsCheckedProvider == true na ho jaye. Koi hidden debug toggle ya automatic verification code mein nahi likha jaayega.  COMMANDMENT 5: ABSOLUTE BAN ON UNLAWFUL WEB SCRAPINGThe Rule: Indian Kanoon website (indiankanoon.org) ya governmental NJDG portals par automated bots, headless browsers (Selenium/Playwright), ya request spamming scripts chalana strictly prohibited hai.  Technical Enforcement: Sabhi court case lookups strictly official kanoon.dev REST API aur hamare self-hosted open-source datasets (OpenNyAI) ke through honge.  COMMANDMENT 6: DATA PRIVACY & THE FREE-TIER AIR-GAPThe Rule: Development aur local testing phase ke dauran Gemini Free-Tier par real client case facts ya FIR bhejkar attorney-client privilege break nahi ki ja sakti.  Technical Enforcement:Development mein strictly synthetic/dummy case data use hoga (is_dummy_testing = true).  Codebase mein hard assertions honge:Dartif (AppEnvironment.appEnv == 'PRODUCTION' && !AppEnvironment.isGeminiPaidTier) {
  throw SecurityException("Production requires GEMINI_PAID_TIER=true. Violates DPDP Act 2023.");
}
Pilot launch par billing link karke Gemini Paid-Tier par switch hona compulsory hai taaki model training zero ho sake.  COMMANDMENT 7: STATUTORY CRIMINAL JURISDICTION RESTRICTIONThe Rule: UI aur Backend validation forms civil statutes allow nahi karenge.Technical Enforcement: Supported sections array strictly criminal statutes tak seemit rahega:Bharatiya Nyaya Sanhita (BNS) / Indian Penal Code (IPC)Bharatiya Nagarik Suraksha Sanhita (BNSS) / Code of Criminal Procedure (CrPC)Special Criminal Acts: NDPS Act, POCSO Act, NI Act (Section 138), Arms Act, SC/ST Act.COMMANDMENT 8: ADVOCATE-ONLY REPRESENTATION GATE (BCI COMPLIANCE)The Rule: Platform kabhi kisi aam citizen ya accused ko direct representation ya legal advice deliver nahi karega.  Technical Enforcement: Onboarding par State Bar Council Enrollment Number verify kiya jaayega. App ke terminology mein kahin bhi "कानूनी सलाह" (Legal Advice) shabd nahi aayega; terminology strictly "अधिवक्ता अनुसंधान एवं विधिक मसौदा सहायक" (Advocate Research & Drafting Assistant) hogi.  COMMANDMENT 9: ETHICAL, NON-INTRUSIVE MONETIZATIONThe Rule: Monetization Bar Council of India ke Rule 36 (advocate advertisement restrictions) aur ethical court decorum ke sath strictly aligned honi chahiye.  Technical Enforcement:Drafting aur court reading screen par full-screen interstitial popups ya loud sound video ads strictly prohibited hain.Sirf subtle native inline banners aur deliberate rewarded video ads ("1 Extra AI Draft") allow honge.Ads par koi misleading claims nahi honge (jaise "100% जमानत की गारंटी").  COMMANDMENT 10: ZERO-SPECULATIVE DEPENDENCY INTEGRATIONThe Rule: Agar kisi external third-party library ka function signature official reference docs mein explicitly verified nahi hai, toh use assume karke generate nahi kiya jaayega.Technical Enforcement: Antigravity aise scenarios mein compile-failing speculative code generate karne ke bajaye TODO: PENDING_SPECIFICATION chhodkar fail-safe fallback return karega.4. EXTRACTIVE GROUNDING & VERIFICATION ALGORITHMBackend par draft generate hone ke baad aur advocate ko return karne se pehle grounding_validator.py execute hoga. Niche diya gaya code grounding standard define karta hai:Python# app/services/grounding_validator.py
import re
from typing import List, Dict, Any, Tuple
from difflib import SequenceMatcher

class GroundingValidator:
    @staticmethod
    def calculate_similarity(a: str, b: str) -> float:
        """Calculates character-level SequenceMatcher ratio."""
        return SequenceMatcher(None, a.lower().strip(), b.lower().strip()).ratio()

    @classmethod
    def verify_precedent_citations(
        cls,
        generated_citations: List[Dict[str, Any]],
        retrieved_precedents: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Rule 1 & Rule 2 Enforcement:
        Filters out any cited case that does not exist in the retrieved pool
        or does not have a verifiable live source link.
        """
        verified_list = []
        retrieved_ids = {p.get("citation_id"): p for p in retrieved_precedents}

        for citation in generated_citations:
            cit_id = citation.get("citation_id")
            
            # Check 1: Citation must exist in verified database pool
            if cit_id not in retrieved_ids:
                continue

            matched_source = retrieved_ids[cit_id]
            source_url = matched_source.get("verified_source_url") or matched_source.get("pdf_download_url")

            # Check 2: Verifiable URL must be valid HTTP/HTTPS
            if not source_url or not (source_url.startswith("http://") or source_url.startswith("https://")):
                continue

            # Check 3: Verbatim Grounding (Sentence exists in source text)
            quoted_text = citation.get("quoted_passage", "").strip()
            source_full_text = matched_source.get("verbatim_text", "")

            # If quoted passage is provided, verify it exists in source (similarity > 0.85)
            is_grounded = True
            if quoted_text and source_full_text:
                if quoted_text.lower() not in source_full_text.lower():
                    # Check substring match ratio
                    best_ratio = 0.0
                    words = source_full_text.split()
                    quote_len = len(quoted_text.split())
                    for i in range(0, len(words) - quote_len + 1):
                        window = " ".join(words[i:i + quote_len])
                        sim = cls.calculate_similarity(quoted_text, window)
                        if sim > best_ratio:
                            best_ratio = sim
                    if best_ratio < 0.85:
                        is_grounded = False

            if is_grounded:
                citation["verified_source_url"] = source_url
                citation["court_name"] = matched_source.get("court_name")
                citation["is_grounded_in_record"] = True
                verified_list.append(citation)

        return verified_list
5. MANDATORY VERIFY-BEFORE-EXPORT GATE WORKFLOWModule 5 ka presentation layer state-machine ke adhar par operate karega:┌────────────────────────────────────────────────────────────────────────┐
│                   VERIFICATION GATE STATE MACHINE                      │
├────────────────────────────────────────────────────────────────────────┤
│ Total Citations in Draft: N                                            │
│ User Checked Citations  : C                                            │
│ Statutory Checkbox      : [ ] "मैंने सभी तथ्यों का परीक्षण कर लिया है"   │
│                                                                        │
│ IF (C == N AND Statutory Checkbox == TRUE):                            │
│     ➔ Export Button: ENABLED (Generates Court Formatted PDF)          │
│ ELSE:                                                                  │
│     ➔ Export Button: DISABLED (Shows pending items remaining)         │
└────────────────────────────────────────────────────────────────────────┘
Flutter Gate State ControllerDart// lib/src/features/05_verify_and_export/presentation/controllers/verification_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerificationGateState {
  final Map<String, bool> verifiedCitations;
  final bool statutoryDeclarationAccepted;

  VerificationGateState({
    required this.verifiedCitations,
    required this.statutoryDeclarationAccepted,
  });

  bool get isReadyForExport {
    if (!statutoryDeclarationAccepted) return false;
    if (verifiedCitations.isEmpty) return true; // No citations present
    return verifiedCitations.values.every((isVerified) => isVerified == true);
  }

  int get pendingCount {
    return verifiedCitations.values.where((v) => v == false).length;
  }
}

class VerificationNotifier extends StateNotifier<VerificationGateState> {
  VerificationNotifier(List<String> citationIds)
      : super(VerificationGateState(
          verifiedCitations: {for (var id in citationIds) id: false},
          statutoryDeclarationAccepted: false,
        ));

  void toggleCitation(String citationId, bool value) {
    final updated = Map<String, bool>.from(state.verifiedCitations);
    updated[citationId] = value;
    state = VerificationGateState(
      verifiedCitations: updated,
      statutoryDeclarationAccepted: state.statutoryDeclarationAccepted,
    );
  }

  void setStatutoryDeclaration(bool accepted) {
    state = VerificationGateState(
      verifiedCitations: state.verifiedCitations,
      statutoryDeclarationAccepted: accepted,
    );
  }
}
6. STATUTORY COMPLIANCE CITATION AUDIT MAPPINGAntigravity ko code structure karte waqt statutory legal boundaries ko code comments mein include karna hoga:Legal ProvisionStatutory BodyCodebase Impact & ImplementationAdvocates Act 1961, Section 30  Bar Council of IndiaSirf enrolled advocates ko access; login par Bar Enrollment number mandatory.  Advocates Act 1961, Section 35  Bar Council of IndiaFalse pleadings se bachne ke liye Mandatory Human-Verification-Gate (Rule 4).  Advocates Act 1961, Section 45  Indian Penal CourtsUPL (Unauthorized Practice of Law) prohibition; direct client advice strictly disabled.  BCI Rules, Chapter II, Rule 5  Bar Council of IndiaAdvocate ka independent professional judgment sarvopari; AI prompts strictly assistive honge.  BCI Rules, Rule 36  Bar Council of IndiaAdvertising restrictions; ads mein zero sensational claims, zero guarantee promises.  DPDP Act 2023, Section 5 & 6  Data Protection BoardOnboarding consent notice and withdrawal mechanisms.  DPDP Act 2023, Section 8(5)  Data Protection BoardTLS 1.3 in-transit aur AES-256 at-rest encryption enforcement (₹250 Crore penalty avoidance).  DPDP Act 2023, Section 8(7)  Data Protection BoardStatutory Right to Erasure; case delete karne par cascade hard deletion.  DPDP Act 2023, Section 16  Central GovernmentData sovereignty; database strictly AWS Mumbai (ap-south-1) par hosted.  7. CONTINUOUS INTEGRATION (CI) SAFETY ASSERTIONSHar pull request par niche diye gaye automated checks execute honge:Air-Gap Privacy Check: Koi bhi test file bina is_dummy_testing=True flag ke commit nahi ho sakti.Anti-Scraping Scanner: Codebase mein selenium, playwright, ya puppeteer import hone par CI build fail ho jaayegi.No Direct Gemini Keys: Dart code analysis scan karega ki koi Google API Key client repo mein leak na ho.