import sys
from datetime import date, timedelta
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
        "cnr_number": "UPHC010000002025",
        "fir_number": "412/2025",
        "police_station": "कैसरबाग",
        "district": "लखनऊ",
        "court_designation": "Special Judge SC/ST & NI Act",
        "stage_of_case": "BAIL_HEARING",
        "accused_name": "रोहित त्रिपाठी",
        "under_sections": ["3(1)(r) SC/ST Act", "138 NI Act"],
    }
    res = supabase.table("cases").insert(case_record).execute()
    return res.data[0]["id"]

def verify_goal17():
    print("[*] Setting up database fixtures for Goal 17...")
    case_id = setup_case_fixture()
    print(f"[+] Created Test Case ID: {case_id}")

    # =========================================================================
    # CRITERION 1: SC/ST Act Section 18 Bar Bypass Assertion (Hitesh Verma Test)
    # =========================================================================
    print("\n[*] Testing Criterion 1: SC/ST Act Section 18 Bar Bypass Assertion (Hitesh Verma Test)...")
    payload_scst_bypass = {
        "case_id": case_id,
        "atrocity_sections": ["3(1)(r)", "3(1)(s)"],
        "incident_place_type": "PRIVATE_HOUSE_ROOM",
        "independent_public_witnesses_present": False,
        "allegation_of_caste_name_used": True,
        "prior_land_or_civil_dispute_existing": True,
        "proposed_appeal_filing_date": date.today().isoformat(),
        "victim_notice_served": False
    }

    resp_scst = client.post("/api/v1/specialized-acts/scst/evaluate", json=payload_scst_bypass)
    assert resp_scst.status_code == 200, f"SC/ST evaluate failed: {resp_scst.text}"
    scst_data = resp_scst.json()

    print(f"    Status Code: {resp_scst.status_code}")
    print(f"    Public View Satisfied: {scst_data['is_public_view_test_satisfied']}")
    print(f"    Anticipatory Bail Maintainable: {scst_data['is_anticipatory_bail_maintainable']}")
    print(f"    Bypass Ratio: {scst_data['section_18_bar_bypass_ratio'][:60]}...")
    print(f"    Tailored Grounds Count: {len(scst_data['tailored_grounds'])}")

    assert scst_data["is_anticipatory_bail_maintainable"] is True, "Anticipatory bail should be maintainable!"
    assert scst_data["is_public_view_test_satisfied"] is False, "Public view test should not be satisfied inside private room!"
    assert any("हितेश वर्मा" in g for g in scst_data["tailored_grounds"]), "Tailored grounds must cite Hitesh Verma!"
    assert any("पृथ्वी राज चौहान" in scst_data["section_18_bar_bypass_ratio"] or "पृथ्वी राज चौहान" in p["case_title"] for p in scst_data["cited_precedents"]), "Must cite Prathvi Raj Chauhan!"
    print("[SUCCESS] Criterion 1 Verified!")

    # =========================================================================
    # CRITERION 2: SC/ST Section 14A Appeal 180-Day Absolute Bar Test
    # =========================================================================
    print("\n[*] Testing Criterion 2: SC/ST Section 14A Appeal 180-Day Absolute Bar Test...")
    order_date_195_days_ago = date.today() - timedelta(days=195)
    payload_scst_barred = {
        "case_id": case_id,
        "atrocity_sections": ["3(1)(r)", "3(1)(s)"],
        "incident_place_type": "PUBLIC_ROAD",
        "independent_public_witnesses_present": True,
        "allegation_of_caste_name_used": True,
        "prior_land_or_civil_dispute_existing": False,
        "special_court_order_date": order_date_195_days_ago.isoformat(),
        "proposed_appeal_filing_date": date.today().isoformat(),
        "victim_notice_served": False
    }

    resp_scst_barred = client.post("/api/v1/specialized-acts/scst/evaluate", json=payload_scst_barred)
    assert resp_scst_barred.status_code == 200, f"SC/ST 180-day bar test failed: {resp_scst_barred.text}"
    barred_data = resp_scst_barred.json()

    print(f"    Special Court Order Date: {order_date_195_days_ago}")
    print(f"    Limitation Status: {barred_data['section_14a_appeal_limitation_status']}")
    print(f"    Delay Days beyond 180: {barred_data['delay_days']}")
    print(f"    Victim Notice Warning: {barred_data['mandatory_victim_notice_warning'][:60]}...")

    assert barred_data["section_14a_appeal_limitation_status"] == "BARRED_BEYOND_180_DAYS", "Must be BARRED_BEYOND_180_DAYS!"
    assert barred_data["delay_days"] == 15, "Delay should be 195 - 180 = 15 days!"
    print("[SUCCESS] Criterion 2 Verified!")

    # =========================================================================
    # CRITERION 3: NI Act 138 Premature Complaint Fatal Defect (Yogendra Pratap Singh)
    # =========================================================================
    print("\n[*] Testing Criterion 3: NI Act 138 Premature Complaint Fatal Defect Assertion...")
    delivery_date = date(2026, 8, 1)
    cure_expiry = delivery_date + timedelta(days=15) # 2026-08-16
    complaint_date = date(2026, 8, 10) # 6 days before cure expiry

    payload_ni_premature = {
        "case_id": case_id,
        "cheque_number": "602914",
        "cheque_amount": 150000.0,
        "cheque_date": "2026-06-15",
        "bank_return_memo_date": "2026-07-15",
        "dishonour_reason": "FUNDS_INSUFFICIENT",
        "demand_notice_dispatch_date": "2026-07-25",
        "demand_notice_delivery_date": delivery_date.isoformat(),
        "is_omnibus_demand_defective": False,
        "complaint_filing_date": complaint_date.isoformat(),
        "defense_category": "SECURITY_CHEQUE",
        "seeks_compounding": False
    }

    resp_ni_premature = client.post("/api/v1/specialized-acts/ni-act/evaluate", json=payload_ni_premature)
    assert resp_ni_premature.status_code == 200, f"NI Act premature test failed: {resp_ni_premature.text}"
    ni_premature_data = resp_ni_premature.json()

    print(f"    Status Code: {resp_ni_premature.status_code}")
    print(f"    Notice Delivery: {delivery_date}")
    print(f"    Cure Expiry: {ni_premature_data['cure_period_15_days_expiry_date']}")
    print(f"    Complaint Filed: {complaint_date}")
    print(f"    Is Premature Complaint: {ni_premature_data['is_premature_complaint']}")
    print(f"    Fatal Defects Count: {len(ni_premature_data['fatal_defects_detected'])}")

    assert ni_premature_data["is_premature_complaint"] is True, "Complaint must be flagged premature!"
    assert any("योगेंद्र प्रताप सिंह" in defect for defect in ni_premature_data["fatal_defects_detected"]), "Must cite Yogendra Pratap Singh in fatal defects!"
    print("[SUCCESS] Criterion 3 Verified!")

    # =========================================================================
    # CRITERION 4: NI Act 138 Omnibus Demand Defect (K.R. Indira)
    # =========================================================================
    print("\n[*] Testing Criterion 4: NI Act 138 Omnibus Demand Defect Assertion (K.R. Indira)...")
    payload_ni_omnibus = {
        "case_id": case_id,
        "cheque_number": "602915",
        "cheque_amount": 250000.0,
        "cheque_date": "2026-06-01",
        "bank_return_memo_date": "2026-06-10",
        "dishonour_reason": "FUNDS_INSUFFICIENT",
        "demand_notice_dispatch_date": "2026-06-20",
        "demand_notice_delivery_date": "2026-06-25",
        "is_omnibus_demand_defective": True,
        "complaint_filing_date": "2026-07-20",
        "defense_category": "FINANCIAL_INCAPACITY",
        "seeks_compounding": True
    }

    resp_ni_omnibus = client.post("/api/v1/specialized-acts/ni-act/evaluate", json=payload_ni_omnibus)
    assert resp_ni_omnibus.status_code == 200, f"NI Act omnibus test failed: {resp_ni_omnibus.text}"
    ni_omnibus_data = resp_ni_omnibus.json()

    print(f"    Fatal Defects Count: {len(ni_omnibus_data['fatal_defects_detected'])}")
    print(f"    Fatal Defect: {ni_omnibus_data['fatal_defects_detected'][0][:60]}...")
    print(f"    Compounding Info: {ni_omnibus_data['compounding_guidelines_under_147'][:60]}...")

    assert any("Omnibus" in d or "के.आर. इंदिरा" in d for d in ni_omnibus_data["fatal_defects_detected"]), "Must flag omnibus defect under K.R. Indira!"
    assert any("के.आर. इंदिरा" in p["case_title"] for p in ni_omnibus_data["cited_precedents"]), "Must cite K.R. Indira!"
    assert ni_omnibus_data["compounding_guidelines_under_147"] is not None, "Must provide compounding guidelines under Sec 147!"
    assert any("दामोदर एस. प्रभु" in ni_omnibus_data["compounding_guidelines_under_147"] or "दामोदर एस. प्रभु" in p["case_title"] for p in ni_omnibus_data["cited_precedents"]), "Must cite Damodar S. Prabhu!"
    print("[SUCCESS] Criterion 4 Verified!")

    print("\n=======================================================")
    print("ALL GOAL 17 BACKEND AUTONOMOUS CRITERIA SATISFIED!")
    print("=======================================================")

if __name__ == "__main__":
    verify_goal17()
