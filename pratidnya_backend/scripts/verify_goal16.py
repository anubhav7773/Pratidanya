import sys
from datetime import date
from starlette.testclient import TestClient
from app.main import app
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client

# Ensure UTF-8 output on Windows terminal
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

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

def setup_case_fixture():
    supabase = get_supabase_admin_client()

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

    case_record = {
        "advocate_id": TEST_ADVOCATE_ID,
        "cnr_number": "UPHC010000002024",
        "fir_number": "314/2024",
        "police_station": "हजरतगंज",
        "district": "लखनऊ",
        "court_designation": "Special Judge NDPS / POCSO",
        "stage_of_case": "BAIL_HEARING",
        "accused_name": "विक्रम सिंह",
        "under_sections": ["20 NDPS Act", "3/4 POCSO Act"],
    }
    res = supabase.table("cases").insert(case_record).execute()
    return res.data[0]["id"]

def verify_goal16():
    print("[*] Setting up database fixtures for Goal 16...")
    case_id = setup_case_fixture()
    print(f"[+] Created Test Case ID: {case_id}")

    # =========================================================================
    # CRITERION 1: NDPS Section 50 Fatal Defect Test (Third Option Defect)
    # =========================================================================
    print("\n[*] Testing Criterion 1: NDPS Section 50 Fatal Defect Test (Third Option Defect)...")
    resp_fatal = client.post(
        "/api/v1/specialized-acts/ndps/evaluate",
        json={
            "case_id": case_id,
            "substance_name": "Charas",
            "recovered_quantity_grams": 450.0,
            "is_personal_search": True,
            "section_50_notice_given": True,
            "section_50_notice_type": "WRITTEN_INDEPENDENT",
            "third_option_defect_present": True,
            "was_searched_before_gazetted_officer": False,
            "was_searched_before_magistrate": False,
            "sample_drawn_before_magistrate_sec_52a": False,
            "independent_public_witnesses_present": False
        }
    )
    print(f"    Status Code: {resp_fatal.status_code}")
    assert resp_fatal.status_code == 200, f"Expected 200, got {resp_fatal.status_code}"
    fatal_data = resp_fatal.json()
    print(f"    Compliance Status: {fatal_data.get('section_50_compliance_status')}")
    print(f"    Quantity Category: {fatal_data.get('quantity_category')}")
    print(f"    Defects Count: {len(fatal_data.get('detected_procedural_defects', []))}")
    print(f"    Bail Grounds Count: {len(fatal_data.get('tailored_bail_grounds', []))}")

    assert fatal_data.get("section_50_compliance_status") == "FATAL_DEFECT", "Expected FATAL_DEFECT"
    grounds_text = " ".join(fatal_data.get("tailored_bail_grounds", []))
    assert "परमानंद" in grounds_text or "विजयासिंह" in grounds_text, "Expected Parmanand / Vijaysinh Jadeja citation in grounds"
    print("[SUCCESS] Criterion 1 Verified!")

    # =========================================================================
    # CRITERION 2: NDPS Commercial Quantity Classification Test
    # =========================================================================
    print("\n[*] Testing Criterion 2: NDPS Commercial vs. Small Quantity Classification...")
    # Subtest A: Ganja 21000g (21 kg) -> Commercial Quantity, Sec 37 applicable
    resp_comm = client.post(
        "/api/v1/specialized-acts/ndps/evaluate",
        json={
            "case_id": case_id,
            "substance_name": "Ganja",
            "recovered_quantity_grams": 21000.0,
            "is_personal_search": False,
            "section_50_notice_given": False
        }
    )
    assert resp_comm.status_code == 200
    comm_data = resp_comm.json()
    print(f"    Ganja 21kg: Category = {comm_data.get('quantity_category')}, Sec 37 Bar = {comm_data.get('is_section_37_bar_applicable')}")
    assert comm_data.get("quantity_category") == "COMMERCIAL_QUANTITY"
    assert comm_data.get("is_section_37_bar_applicable") is True

    # Subtest B: Ganja 850g -> Small Quantity, Sec 37 NOT applicable
    resp_small = client.post(
        "/api/v1/specialized-acts/ndps/evaluate",
        json={
            "case_id": case_id,
            "substance_name": "Ganja",
            "recovered_quantity_grams": 850.0,
            "is_personal_search": False,
            "section_50_notice_given": False
        }
    )
    assert resp_small.status_code == 200
    small_data = resp_small.json()
    print(f"    Ganja 850g: Category = {small_data.get('quantity_category')}, Sec 37 Bar = {small_data.get('is_section_37_bar_applicable')}")
    assert small_data.get("quantity_category") == "SMALL_QUANTITY"
    assert small_data.get("is_section_37_bar_applicable") is False
    print("[SUCCESS] Criterion 2 Verified!")

    # =========================================================================
    # CRITERION 3: POCSO Section 94 JJ Act Hierarchy & Age Determination Test
    # =========================================================================
    print("\n[*] Testing Criterion 3: POCSO Section 94 JJ Act Hierarchy & Age Determination...")
    resp_pocso = client.post(
        "/api/v1/specialized-acts/pocso/evaluate-age",
        json={
            "case_id": case_id,
            "alleged_incident_date": "2024-05-15",
            "fir_stated_age_years": 15,
            "has_first_attended_school_certificate": False,
            "has_matriculation_certificate": False,
            "has_municipal_birth_certificate": False,
            "ossification_test_conducted": True,
            "radiological_age_lower": 16.0,
            "radiological_age_upper": 18.0,
            "two_year_margin_benefit_applied": True,
            "evidence_of_prior_romantic_relationship": True,
            "unexplained_delay_in_fir_days": 7,
            "no_injuries_found": True
        }
    )
    print(f"    Status Code: {resp_pocso.status_code}")
    assert resp_pocso.status_code == 200, f"Expected 200, got {resp_pocso.status_code}"
    pocso_data = resp_pocso.json()
    print(f"    Tier Applicable: {pocso_data.get('statutory_tier_applicable')}")
    print(f"    Computed Age: {pocso_data.get('computed_age_at_incident_years')} years")
    print(f"    Is Majority Probable: {pocso_data.get('is_majority_probable')}")
    print(f"    Analysis: {pocso_data.get('age_determination_analysis_hindi')[:120]}...")
    print(f"    Presumption Rebuttal Count: {len(pocso_data.get('presumption_rebuttal_strategy', []))}")
    print(f"    Bail Grounds Count: {len(pocso_data.get('bail_grounds_pocso', []))}")

    assert pocso_data.get("statutory_tier_applicable") == "TIER_3_OSSIFICATION"
    assert pocso_data.get("is_majority_probable") is True, "Expected majority probable under Rishipal Singh Solanki"
    assert pocso_data.get("computed_age_at_incident_years") >= 18.0
    pocso_grounds = " ".join(pocso_data.get("bail_grounds_pocso", []))
    assert "वयस्क" in pocso_grounds or "सहमति" in pocso_grounds
    print("[SUCCESS] Criterion 3 Verified!")

    print("\n=======================================================")
    print("ALL GOAL 16 BACKEND AUTONOMOUS CRITERIA SATISFIED!")
    print("=======================================================")

if __name__ == "__main__":
    verify_goal16()
