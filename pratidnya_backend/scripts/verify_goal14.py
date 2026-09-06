import sys
from datetime import date
from pathlib import Path

# Ensure UTF-8 output on Windows terminal
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

from starlette.testclient import TestClient
from app.main import app
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.services.limitation_calculator import LimitationCalculator
from app.schemas.limitation_and_stay_schema import LimitationCheckRequest

TEST_ADVOCATE_ID = "00000000-0000-0000-0000-000000000001"

async def mock_verify_advocate_token():
    return {
        "uid": TEST_ADVOCATE_ID,
        "advocate_id": TEST_ADVOCATE_ID,
        "email": "advocate_trial_test@pratidnya.com",
        "role": "advocate"
    }

app.dependency_overrides[verify_advocate_token] = mock_verify_advocate_token

client = TestClient(app)

def setup_test_pleading():
    supabase = get_supabase_admin_client()

    # Ensure profile
    profile = {
        "id": TEST_ADVOCATE_ID,
        "email": "advocate_trial_test@pratidnya.com",
        "full_name": "एडवोकेट राम कुमार वर्मा",
        "bar_council_number": "UP/12345/2015",
        "enrolled_state": "UTTAR_PRADESH",
        "primary_court_name": "उच्च न्यायालय इलाहाबाद, लखनऊ खंडपीठ",
        "court_type": "HIGH_COURT",
        "chamber_address": "चैंबर संख्या 42, लखनऊ",
        "dpdp_consent_accepted": True
    }
    supabase.table("advocate_profiles").upsert(profile).execute()

    # Create pleading for limitation testing
    pleading = {
        "advocate_id": TEST_ADVOCATE_ID,
        "pleading_type": "CRIMINAL_APPEAL",
        "high_court_bench": "LUCKNOW_BENCH",
        "trial_court_name": "न्यायालय अपर सत्र न्यायाधीश, न्यायालय संख्या 4, लखनऊ",
        "trial_case_number": "सत्र परीक्षण संख्या 342/2021",
        "trial_judgment_date": "2024-01-01",
        "trial_presiding_judge": "श्री अजय कुमार श्रीवास्तव, एच.जे.एस.",
        "convicted_sections": ["307 IPC", "323 IPC"],
        "quantum_of_sentence": "7 वर्ष का कठोर कारावास एवं ₹5,000 अर्थदंड",
        "case_title": "राजू उर्फ राजेश बनाम उत्तर प्रदेश राज्य",
        "accused_names": ["राजू उर्फ राजेश"],
        "police_station": "हजरतगंज",
        "district": "लखनऊ",
        "fir_number": "112/2021",
        "limitation_expiry_date": "2024-03-01",
        "appellant_custody_status": "IN_JAIL",
        "days_in_custody": 140
    }
    res = supabase.table("high_court_pleadings").insert(pleading).execute()
    return res.data[0]["id"]

def verify_goal14():
    print("[*] Setting up database fixtures for Goal 14...")
    pleading_id = setup_test_pleading()
    print(f"[+] Created Pleading ID for Goal 14: {pleading_id}")

    # =========================================================================
    # CRITERION 1: Limitation & Certified Copy Exclusion Calculation Test
    # =========================================================================
    print("\n[*] Testing Criterion 1: Limitation & Certified Copy Exclusion Calculation...")
    # Judgment Date: 2024-01-01
    # Copy Applied Date: 2024-01-10
    # Copy Ready Date: 2024-01-25 (Excluded days = (25-10) + 1 = 16 days)
    # Proposed Filing Date: 2024-03-25 (84 calendar days elapsed)
    # Effective days = 84 - 16 = 68 days
    # Statutory Appeal limit = 60 days
    # Expected: is_delayed == True, delay_days == 8, must_file_section_5_application == True
    req = LimitationCheckRequest(
        pleading_id=pleading_id,
        judgment_date=date(2024, 1, 1),
        certified_copy_applied_date=date(2024, 1, 10),
        certified_copy_ready_date=date(2024, 1, 25),
        proposed_filing_date=date(2024, 3, 25),
        pleading_type="CRIMINAL_APPEAL"
    )
    lim_eval = LimitationCalculator.evaluate_limitation(req)
    print(f"    Statutory Days: {lim_eval.statutory_limitation_days}")
    print(f"    Certified Copy Excluded Days: {lim_eval.certified_copy_excluded_days}")
    print(f"    Effective Days Taken: {lim_eval.effective_days_taken}")
    print(f"    Is Delayed: {lim_eval.is_delayed}")
    print(f"    Delay Days: {lim_eval.delay_days}")
    print(f"    Limitation Expiry Date: {lim_eval.limitation_expiry_date}")
    print(f"    Must File Section 5: {lim_eval.must_file_section_5_application}")

    assert lim_eval.certified_copy_excluded_days == 16, f"Expected 16 excluded days, got {lim_eval.certified_copy_excluded_days}"
    assert lim_eval.effective_days_taken == 68, f"Expected 68 effective days, got {lim_eval.effective_days_taken}"
    assert lim_eval.is_delayed is True, "Expected is_delayed to be True"
    assert lim_eval.delay_days == 8, f"Expected 8 delay days, got {lim_eval.delay_days}"
    assert lim_eval.must_file_section_5_application is True, "Expected must_file_section_5_application to be True"

    # API Endpoint check for calculate-limitation
    api_resp = client.post(
        "/api/v1/high-court/interlocutory/calculate-limitation",
        json={
            "pleading_id": pleading_id,
            "judgment_date": "2024-01-01",
            "certified_copy_applied_date": "2024-01-10",
            "certified_copy_ready_date": "2024-01-25",
            "proposed_filing_date": "2024-03-25",
            "pleading_type": "CRIMINAL_APPEAL"
        }
    )
    assert api_resp.status_code == 200, f"Expected 200, got {api_resp.status_code}"
    api_data = api_resp.json()
    assert api_data["delay_days"] == 8
    assert api_data["is_delayed"] is True
    print("[SUCCESS] Criterion 1 Verified!")

    # =========================================================================
    # CRITERION 2: Section 5 Condonation Suite Generation Test
    # =========================================================================
    print("\n[*] Testing Criterion 2: Section 5 Condonation Suite Generation...")
    resp_sec5 = client.post(
        "/api/v1/high-court/interlocutory/generate-section-5-delay",
        json={
            "pleading_id": pleading_id,
            "pairokar_name": "सुरेश कुमार",
            "pairokar_relation": "सगा भाई",
            "pairokar_age": 38,
            "pairokar_address": "ग्राम व पोस्ट बख्शी का तालाब, लखनऊ",
            "primary_delay_reason": "POVERTY_AND_JAIL_COMMUNICATION"
        }
    )
    print(f"    Status Code: {resp_sec5.status_code}")
    assert resp_sec5.status_code == 200, f"Expected 200, got {resp_sec5.status_code}"
    sec5_data = resp_sec5.json()

    print(f"    App Title: {sec5_data.get('application_title_hindi')}")
    print(f"    Deponent Block: {sec5_data.get('affidavit_deponent_block')}")
    print(f"    Verification: {sec5_data.get('affidavit_verification_clause')}")
    print(f"    Grounds Count: {len(sec5_data.get('delay_grounds', []))}")

    assert sec5_data.get("application_title_hindi") == "प्रार्थना पत्र अंतर्गत धारा 5 मियाद अधिनियम (Limitation Act, 1963)"
    
    grounds_joined = " ".join(sec5_data.get("delay_grounds", []))
    assert "कातीजी" in grounds_joined or "Substantial Justice" in grounds_joined or "सारवान न्याय" in grounds_joined
    assert "सत्यापन:" in sec5_data.get("affidavit_verification_clause", "")
    assert "ईश्वर मेरी सहायता करे" in sec5_data.get("affidavit_verification_clause", "")
    print("[SUCCESS] Criterion 2 Verified!")

    # =========================================================================
    # CRITERION 3: Section 389(1) Sentence Suspension & Bail Suite Generation
    # =========================================================================
    print("\n[*] Testing Criterion 3: Section 389(1) Sentence Suspension & Bail Suite Generation...")
    resp_stay = client.post(
        "/api/v1/high-court/interlocutory/generate-suspension-bail",
        json={
            "pleading_id": pleading_id,
            "statute_system": "IPC_CRPC",
            "trial_bail_status": "ON_BAIL_NEVER_MISUSED",
            "fine_deposit_status": "READY_TO_DEPOSIT",
            "pairokar_name": "सुरेश कुमार",
            "pairokar_relation": "सगा भाई",
            "pairokar_age": 38,
            "pairokar_address": "लखनऊ"
        }
    )
    print(f"    Status Code: {resp_stay.status_code}")
    assert resp_stay.status_code == 200, f"Expected 200, got {resp_stay.status_code}"
    stay_data = resp_stay.json()

    print(f"    Statutory Provision: {stay_data.get('statutory_provision')}")
    print(f"    App Title: {stay_data.get('application_title_hindi')}")
    print(f"    Grounds Count: {len(stay_data.get('grounds_for_suspension', []))}")
    print(f"    Interim Prayer: {stay_data.get('interim_bail_prayer')[:100]}...")
    print(f"    Cited Precedents Count: {len(stay_data.get('cited_precedents', []))}")

    assert stay_data.get("statutory_provision") == "धारा 389(1) दंड प्रक्रिया संहिता"
    stay_grounds = " ".join(stay_data.get("grounds_for_suspension", []))
    assert "भगवान राम शिंदे गोसाई" in stay_grounds or "सीमित अवधि" in stay_grounds
    assert "अपीलार्थी संपूर्ण विचारण के दौरान जमानत पर था" in stay_grounds

    # Check verified cited precedents
    precedents = stay_data.get("cited_precedents", [])
    assert len(precedents) >= 2
    titles = [p.get("case_title", "") for p in precedents]
    assert any("भगवान राम शिंदे" in t for t in titles)
    assert any("सौदान सिंह" in t for t in titles)

    for p in precedents:
        assert len(p.get("verbatim_quote", "")) > 20
        print(f"    Precedent: {p.get('case_title')} -> {p.get('verbatim_quote')[:80]}...")

    print("[SUCCESS] Criterion 3 Verified!")
    print("\n=======================================================")
    print("ALL GOAL 14 AUTONOMOUS VERIFICATION CRITERIA SATISFIED!")
    print("=======================================================")

if __name__ == "__main__":
    verify_goal14()
