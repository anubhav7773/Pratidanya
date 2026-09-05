================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-08
MODULE         : STATUTORY COMPLIANCE CHECKLIST & REGULATORY GUARDRAILS
STATUTES COVERED: DPDP Act 2023 | Advocates Act 1961 | Bar Council of India Rules
TARGET RUNTIME : Flutter 3.19+ / FastAPI (Python 3.10+) / Supabase PostgreSQL 15+
ROLE & PURPOSE : ANTIGRAVITY SILENT COMPLIANCE DIRECTIVE (ZERO COMPROMISE)
================================================================================
1. STATUTORY ROLES & REGULATORY DEFINITIONSJab bhi Antigravity codebase mein data models, UI dialogs, ya API endpoints generate karega, use statutory terms aur liabilities ko in exact legal definitions ke mutabik execute karna hai:Legal TermStatutory ProvisionPratidnya Architecture AssignmentLegal Obligation / PenaltyData FiduciaryDPDP Act 2023, Sec 2(i)  Asiverticals / Pratidnya Platform  Personal case data ke processing, retention aur security safeguards ke liye strictly accountable.  Data PrincipalDPDP Act 2023, Sec 2(j)  Advocate & Litigant (Client/Accused)  Data processing ke purpose ko janne, consent withdraw karne, aur data erase karwane ka right.  Data ProcessorDPDP Act 2023, Sec 8(2)  Google Cloud / Gemini Paid Tier, Supabase, RenderInke aur platform ke beech valid legal contract hona anivarya hai.  Unauthorized Practice of Law (UPL)Advocates Act 1961, Sec 29, 30 & 45  Platform Operational Barrier  Non-advocates ko direct legal advice ya self-drafting dena illegal practice hai; up to 6 months jail.  Independent Professional JudgmentBCI Rules, Chapter II, Rule 5  Human-Verification Gate  Advocate AI output ko blindly follow nahi kar sakta; court mein file karne se pehle review mandatory.  Professional MisconductAdvocates Act 1961, Sec 35  Hallucination Protection  Court mein fake citations ya jhoothe facts file karna advocate ka license suspend/revoke karwa sakta hai.  2. THE DEVELOPER'S MASTER COMPLIANCE CHECKLISTAntigravity ko har module build karte waqt is tabular checklist ke technical conditions silently verify karne hain:┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 PRATIDNYA ENGINEERING COMPLIANCE MATRIX                               │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ STATUS: [MANDATORY] = Production Blocked if Violated | [AIR-GAP] = Dev/Testing Sandboxing Rule         │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
Domain / LayerStatutory ClauseCompliance RequirementEngineering Implementation DirectiveSeverityOnboardingDPDP Act Sec 5(1) & 6(1)  Explicit Bilingual Notice & Consent  English aur Hindi mein clear notice modal; consent log IP aur timestamp ke sath immutable table mein store hoga.  MANDATORYOnboardingAdvocates Act Sec 29 & 30  Advocate-Only Access Gate  State Bar Council enrollment number compulsory input; civilian/accused accounts blocked.  MANDATORYSettings / ProfileDPDP Act Sec 6(4)  Right to Withdraw Consent  Settings screen mein "सहमति वापस लें (Withdraw Consent)" button jisse platform access revoke aur data queued for deletion ho.  MANDATORYSettings / Case ActionsDPDP Act Sec 8(7)  Right to Erasure / Data Deletion  Case delete karne par PostgreSQL database mein cascade delete trigger hoga; raw files and vectors permanently erased.  MANDATORYCloud HostingDPDP Act Sec 16(1)  Data Localization / Indian Cloud  Supabase database aur FastAPI microservice strictly AWS Mumbai (ap-south-1) region mein host honge.  MANDATORYData StorageDPDP Act Sec 8(5)  Encryption At-Rest & In-Transit  Database level par AES-256 encryption at-rest; network communication strictly TLS 1.3 in-transit (Penalty up to ₹250 Cr).  MANDATORYIncidents / InfosecDPDP Act Sec 8(6)  Mandatory Data Breach Reporting  Breach hone par Data Protection Board of India (DPBI) aur affected advocates ko structured notification dispatch engine.  MANDATORYAI LLM PipelineAttorney-Client Privilege / DPDP Sec 8  Gemini Free-Tier Data Air-Gap  Development phase mein sirf synthetic dummy data allow hoga; production pilot launch par Paid Tier (Tier 1) mandatory.  AIR-GAPDrafting StudioAdvocates Act Sec 35 / BCI Rule 5  Mandatory Human Verification Gate  PDF Export tab tak disable rahega jab tak lawyer har precedent aur fact ko manually check/tick na kare.  MANDATORYUI TerminologyAdvocates Act Sec 45  Zero Direct Legal Advice Framing  App UI par "कानूनी सलाह" (Legal Advice) shabd strictly prohibited hai; "अधिवक्ता ड्राफ्टिंग सहायक" use hoga.  MANDATORYMonetizationBCI Rules, Chapter II, Rule 36  Ethical Advertising & No Guarantees  Drafting screen par interstitial popups ban; ads mein "100% जमानत की गारंटी" jaise sensational claims ban.  MANDATORYLegal ResearchJudicial Terms & IP Law  Anti-Bulk Scraping Ban  Indian Kanoon portal ki direct scraping ban; sirf kanoon.dev REST API aur self-hosted OpenNyAI use honge.  MANDATORY3. DPDP ACT 2023 STATUTORY IMPLEMENTATIONA. Bilingual Consent & Notice Specification (Section 5 & 6)Lawyer onboarding complete karne se pehle use ek unambiguous notice display karna anivarya hai:  Dart// lib/src/features/01_onboarding/presentation/screens/dpdp_consent_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/profile_repository.dart';

class DpdpConsentScreen extends ConsumerStatefulWidget {
  const DpdpConsentScreen({super.key});

  @override
  ConsumerState<DpdpConsentScreen> createState() => _DpdpConsentScreenState();
}

class _DpdpConsentScreenState extends ConsumerState<DpdpConsentScreen> {
  bool _isUnderstood = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('विधिक सूचना एवं सहमति (DPDP Act 2023)'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.Border.all(color: AppColors.borderSubtle),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'डिजिटल व्यक्तिगत डेटा संरक्षण अधिनियम, 2023 (धारा 5 एवं 6 के अंतर्गत सूचना)',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.courtNavy,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Divider(height: 24),
                        _buildSectionHeader('1. डेटा संग्रहण का विशिष्ट उद्देश्य (Purpose of Collection):'),
                        _buildBodyText(
                          'प्रतिज्ञा (Asiverticals) केवल जिला न्यायालय के आपराधिक मामलों में विधि अनुसंधान, '
                          'आरोप-पत्र विश्लेषण और जमानत प्रार्थना पत्र के तकनीकी प्रारूपण में सहायता हेतु '
                          'अधिवक्ता द्वारा उपलब्ध कराए गए वाद तथ्यों को संसाधित करती है।',
                        ),
                        const SizedBox(height: 12),
                        _buildSectionHeader('2. डेटा का प्रक्रमण एवं गोपनीयता (Processing & Confidentiality):'),
                        _buildBodyText(
                          'हम आपके वाद तथ्यों को किसी भी AI मॉडल के सामान्य सार्वजनिक प्रशिक्षण (Model Training) '
                          'हेतु उपयोग नहीं करते हैं। डेटा केवल भारतीय संप्रभु क्लाउड (AWS मुंबई) पर सुरक्षित संग्रहीत रहता है।',
                        ),
                        const SizedBox(height: 12),
                        _buildSectionHeader('3. सहमति वापसी एवं विलोपन का अधिकार (Right to Erasure - Sec 8(7)):'),
                        _buildBodyText(
                          'अधिवक्ता किसी भी समय सेटिंग्स मेनू से अपनी सहमति वापस ले सकते हैं अथवा केस फाइल को स्थायी रूप '
                          'से मिटा (Hard Delete) सकते हैं। ऐसा करने पर समस्त संबंधित वेक्टर एम्बेडिंग्स स्वतः नष्ट हो जाएंगी।',
                        ),
                        const SizedBox(height: 12),
                        _buildSectionHeader('4. शिकायत निवारण (Data Protection Board of India):'),
                        _buildBodyText(
                          'किसी भी डेटा उल्लंघन या शिकायत हेतु आप हमारे डेटा संरक्षण अधिकारी (DPO) से dpo@asiverticals.me पर '
                          'संपर्क कर सकते हैं अथवा DPBI के समक्ष विधिक शिकायत दर्ज कर सकते हैं।',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isUnderstood,
                    activeColor: AppColors.verifiedGreen,
                    onChanged: (val) => setState(() => _isUnderstood = val ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'मैंने उपरोक्त विधिक सूचना को पढ़ लिया है और मैं अपने आपराधिक वाद अनुसंधान हेतु '
                      'डेटा प्रक्रमण के लिए स्पष्ट एवं सूचित सहमति (Informed Consent) प्रदान करता हूँ।',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.courtNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                  ),
                  onPressed: _isUnderstood
                      ? () async {
                          // Record immutable consent and proceed
                          await ref.read(profileRepositoryProvider).recordStatutoryConsent();
                        }
                      : null,
                  child: const Text('सहमति स्वीकार करें एवं आगे बढ़ें', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.slateBlue),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.0, height: 1.45, color: AppColors.textSecondary),
      ),
    );
  }
}
B. Statutory Right to Erasure Cascade (Section 8(7))Jab advocate kisi case record ko delete kare ya apni consent revoke kare, toh data complete erase (hard delete) hona chahiye:  SQL-- PostgreSQL Cascade Erasure Trigger
create or replace function execute_statutory_data_erasure()
returns trigger as $$
begin
    -- 1. Log hard erasure statutory event for regulatory audit
    insert into public.dpdp_audit_logs (
        advocate_id,
        action_type,
        metadata
    ) values (
        old.advocate_id,
        'STATUTORY_RIGHT_TO_ERASURE_EXECUTED',
        jsonb_build_object(
            'deleted_case_id', old.id,
            'fir_number', old.fir_number,
            'erasure_timestamp', timezone('utc'::text, now())
        )
    );

    -- Note: Foreign keys on case_document_embeddings and case_proceedings
    -- have 'ON DELETE CASCADE' configured, ensuring all vector floats and
    -- proceedings are instantly wiped from physical storage.

    return old;
end;
$$ language plpgsql;

create trigger trg_statutory_case_erasure
after delete on public.cases
for each row execute function execute_statutory_data_erasure();
C. Data Breach Notification Payload (Section 8(6))Data breach hone par Data Protection Board of India (DPBI) aur affected users ko intimation bhejne ka backend engine:  Python# app/services/breach_notification_service.py
import httpx
from datetime import datetime, timezone
from typing import List, Dict, Any
from app.core.config import settings

class BreachNotificationService:
    @staticmethod
    async def report_breach_to_dpbi(
        incident_id: str,
        nature_of_breach: str,
        affected_user_ids: List[str],
        mitigation_steps_taken: List[str]
    ) -> bool:
        """
        DPDP Act 2023 Section 8(6) Compliance:
        Mandatory reporting to Data Protection Board of India.
        Non-compliance penalty up to Rs. 200 Crores under Schedule.
        """
        dpbi_endpoint = settings.DPBI_REPORTING_WEBHOOK_URL
        payload = {
            "data_fiduciary": "Asiverticals (Pratidnya Legal Tech)",
            "incident_id": incident_id,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "nature_of_breach": nature_of_breach,
            "number_of_data_principals_affected": len(affected_user_ids),
            "data_categories_involved": ["Criminal FIR Records", "Case Diary Notes", "Advocate Profile"],
            "containment_actions_taken": mitigation_steps_taken,
            "dpo_contact": {
                "name": "Data Protection Officer",
                "email": "dpo@asiverticals.me",
                "phone": "+91-522-XXXXXXX"
            }
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(dpbi_endpoint, json=payload)
            return response.status_code == 200
4. ADVOCATES ACT 1961 & BCI RULES COMPLIANCEA. Prevention of Unauthorized Practice of Law (Section 29, 30 & 45)Antigravity ko ensure karna hai ki platform kisi non-advocate ko direct legal consultation na deliver kare:                       ┌───────────────────────────────┐
                     │     APP USER ACCESS GATE      │
                     └───────────────┬───────────────┘
                                     │
                    Is User an Enrolled Advocate?
                   (Has Valid State Bar Council No.)
                                     │
                     ┌───────────────┴───────────────┐
                    YES                              NO
                     │                               │
        Access Allowed: Case Input,          ACCESS TERMINATED
        RAG Precedent Search, Drafting       Redirect: "केवल पंजीकृत अधिवक्ताओं के लिए"
        (Advocate is Human Gatekeeper) (Violators attract Sec 45 imprisonment)
B. BCI Rule 5: Independent Professional Judgment EngineAI model kisi lawyer ko mandatory legal step lene ke liye force nahi karega. Sabhi draft sections assistive suggestions ke roop mein frame honge:  Dart// lib/src/shared/components/bci_disclaimer_banner.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BciDisclaimerBanner extends StatelessWidget {
  const BciDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: AppColors.chamberSlate,
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'विधिक अस्वीकरण (BCI नियम 5): यह प्रणाली केवल अनुसंधान एवं मसौदा सहायक है। '
              'न्यायालय में उपयोग से पूर्व अधिवक्ता द्वारा स्वतंत्र पेशेवर विवेक का प्रयोग अनिवार्य है।',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
5. BCI RULE 36 ADVERTISING & MONETIZATION RULESDistrict court criminal practice mein Bar Council of India ke Rule 36 ke tehat advocates ya legal platforms par advertising restrictions applicable hain:  4 Non-Negotiable AdMob Integration Rules:No Interstitials During Active Drafting: Jab advocate bail application ya argument grounds prepare kar raha ho, tab koi full-screen intrusive interstitial popup render nahi hoga.Strict Ad Category Whitelist: Google AdMob console mein legal-sensitive aur misleading categories block rahengi:BLOCKED CATEGORIES: Gambling, Adult/Dating, Sensational Loans, Astrological Remedies, Fake Bail Guarantee services.  ALLOWED CATEGORIES: Legal Publications, Legal Seminars, Office Tech, Educational Subscriptions.No Promotional Claims: UI par kisi bhi banner mein "सर्वश्रेष्ठ जमानत वकील" ya "100% जमानत की गारंटी" jaise daave promote nahi honge.  Rewarded Ad Discretion: Rewarded video ads keval explicit advocate choice par trigger honge jab daily quota exceed ho:Clear Prompt: [ 1 अतिरिक्त AI ड्राफ्ट हेतु विज्ञापन देखें ]6. AUTOMATED COMPLIANCE TEST SUITE (CI PIPELINE)CI pipeline mein automated unit test execute hoga jo statutory boundaries verify karega:Python# tests/test_statutory_compliance.py
import pytest
from app.services.grounding_validator import GroundingValidator
from app.core.config import settings

def test_air_gap_privacy_enforcement():
    """Rule 6: Asserts real data cannot process on free-tier."""
    if not settings.GEMINI_PAID_TIER:
        assert settings.ENFORCE_DUMMY_DATA is True, (
            "STATUTORY VIOLATION: Free tier cannot operate without ENFORCE_DUMMY_DATA=True."
        )

def test_zero_unlinked_precedents_allowed():
    """Rule 1: Citations without valid source URL must be dropped."""
    fake_precedent = [{
        "citation_id": "FAKE_CASE_2026",
        "quoted_passage": "आवेदक को जमानत दी जाती है।"
    }]
    retrieved_db_pool = [{
        "citation_id": "FAKE_CASE_2026",
        "verified_source_url": None, # Missing verified URL!
        "verbatim_text": "आवेदक को जमानत दी जाती है।"
    }]

    verified = GroundingValidator.verify_precedent_citations(fake_precedent, retrieved_db_pool)
    assert len(verified) == 0, "Failed: Citation without source link passed verification gate!"

def test_bci_legal_advice_wording_prohibition():
    """Rule 8: Word 'कानूनी सलाह' (Legal Advice) must not exist in user templates."""
    banned_phrase = "कानूनी सलाह"
    system_prompt_sample = settings.SYSTEM_INSTRUCTION_HINDI
    assert banned_phrase not in system_prompt_sample, (
        f"Statutory UPL violation: Banned phrase '{banned_phrase}' found in AI system prompt."
    )
7. ANTIGRAVITY SILENT ENFORCEMENT DIRECTIVES (DOC-08)Antigravity code generate karte waqt in directives ko unconditionally apply karega:[ ] Direct client registration disabled rahegi; onboarding form par Bar Council Enrollment Number mandatory field hoga.  [ ] The app UI will never use the word "कानूनी सलाह" (Legal Advice); it must always be "विधिक अनुसंधान एवं प्रारूपण सहायक" (Legal Research & Drafting Assistant).  [ ] Export/Download PDF flow must check isAllCitationsCheckedProvider == true and the statutory declaration checkbox. Bypass shortcuts are considered fatal bugs.  [ ] Database deletion requests must execute statutory erasure triggers with audit logs under DPDP Section 8(7)[cite: 1].[ ] All outbound database connections must enforce TLS 1.3 and connect strictly to the AWS Mumbai data center[cite: 1].[ ] Ad placements must adhere to BCI Rule 36: Zero interstitials in drafting rooms, zero sensational guarantee claims[cite: 1].