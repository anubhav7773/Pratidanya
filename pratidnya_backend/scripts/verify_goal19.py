import sys
from starlette.testclient import TestClient
from app.main import app
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client

# Ensure UTF-8 output on Windows terminal
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

TEST_ADVOCATE_ID = "00000000-0000-0000-0000-000000000019"

async def mock_verify_advocate_token():
    return {
        "uid": TEST_ADVOCATE_ID,
        "advocate_id": TEST_ADVOCATE_ID,
        "email": "dpdp_audit_test@pratidnya.com",
        "role": "advocate"
    }

app.dependency_overrides[verify_advocate_token] = mock_verify_advocate_token
client = TestClient(app)

def setup_fixtures():
    supabase = get_supabase_admin_client()

    # 1. Upsert Advocate Profile
    profile = {
        "id": TEST_ADVOCATE_ID,
        "email": "dpdp_audit_test@pratidnya.com",
        "full_name": "एडवोकेट विक्रम सिंह",
        "bar_council_number": "UP/9999/2018",
        "enrolled_state": "UTTAR_PRADESH",
        "primary_court_name": "जिला एवं सत्र न्यायालय, लखनऊ",
        "court_type": "DISTRICT_COURT",
        "chamber_address": "चैंबर 19, लखनऊ",
        "dpdp_consent_accepted": True
    }
    supabase.table("advocate_profiles").upsert(profile).execute()

    # 2. Insert Case
    case_record = {
        "advocate_id": TEST_ADVOCATE_ID,
        "fir_number": "999/2026",
        "police_station": "हजरतगंज",
        "district": "लखनऊ",
        "state": "Uttar Pradesh",
        "accused_name": "महेश कुमार",
        "accused_custody_status": "JUDICIAL_CUSTODY",
        "statute_system": "HYBRID",
        "under_sections": ["धारा 379 भा.दं.वि."],
        "court_designation": "CJM Lucknow",
        "stage_of_case": "BAIL",
        "is_archived": False
    }
    case_res = supabase.table("cases").insert(case_record).execute()
    case_id = case_res.data[0]["id"]

    # 3. Insert Proceeding
    proceeding = {
        "case_id": case_id,
        "advocate_id": TEST_ADVOCATE_ID,
        "proceeding_date": "2026-09-06",
        "court_coram": "न्यायालय मुख्य न्यायिक मजिस्ट्रेट",
        "business_recorded": "जमानत प्रार्थना पत्र पर बहस सुनी गई।",
        "next_date": "2026-09-12",
        "purpose_of_next_date": "आदेश हेतु"
    }
    supabase.table("case_proceedings").insert(proceeding).execute()

    return case_id

def test_dpdp_export_and_erasure():
    print("[*] Setting up database fixtures for Goal 19...")
    case_id = setup_fixtures()
    print(f"[+] Created test advocate {TEST_ADVOCATE_ID} with case {case_id}")

    # =========================================================================
    # CRITERION 1: DPDP Section 11 Data Bundle Export Assertion
    # =========================================================================
    print("\n[*] Testing Criterion 1: DPDP Section 11 Data Bundle Export...")
    res_export = client.get("/api/v1/compliance/dpdp/export-chamber-bundle")
    assert res_export.status_code == 200, f"Export failed with {res_export.status_code}: {res_export.text}"
    bundle = res_export.json()

    assert bundle.get("compliance_standard") == "DPDP_ACT_2023_SEC_11", "Standard mismatch"
    assert "advocate_profile" in bundle, "Missing advocate_profile"
    assert bundle["advocate_profile"]["id"] == TEST_ADVOCATE_ID
    assert "cases" in bundle, "Missing cases"
    assert len(bundle["cases"]) >= 1, "Expected at least 1 case in export"
    assert "proceedings" in bundle, "Missing proceedings"
    assert len(bundle["proceedings"]) >= 1, "Expected at least 1 proceeding in export"
    assert "high_court_pleadings" in bundle, "Missing high_court_pleadings"
    assert "statutory_audit_logs" in bundle, "Missing statutory_audit_logs"

    # Verify audit log in Supabase
    supabase = get_supabase_admin_client()
    audit_res = supabase.table("dpdp_audit_logs") \
        .select("*") \
        .eq("advocate_id", TEST_ADVOCATE_ID) \
        .eq("action_type", "STATUTORY_DATA_EXPORT_GENERATED") \
        .execute()
    assert len(audit_res.data) >= 1, "STATUTORY_DATA_EXPORT_GENERATED was not logged in dpdp_audit_logs"

    print("    HTTP Status: 200")
    print(f"    Export Standard: {bundle.get('compliance_standard')}")
    print(f"    Exported Cases: {len(bundle['cases'])}, Proceedings: {len(bundle['proceedings'])}")
    print(f"    Logged Audit Action: {audit_res.data[0]['action_type']}")
    print("[SUCCESS] Criterion 1 Verified!")

    # =========================================================================
    # BCI Rule 36 Statement Test
    # =========================================================================
    print("\n[*] Testing BCI Rule 36 Statutory Declaration Statement...")
    res_bci = client.get("/api/v1/compliance/dpdp/bci-audit-statement")
    assert res_bci.status_code == 200, f"BCI statement failed: {res_bci.text}"
    bci_data = res_bci.json()
    assert "statutory_certifications" in bci_data
    assert len(bci_data["statutory_certifications"]) == 4
    print(f"    Advocate: {bci_data.get('advocate_name')} ({bci_data.get('bar_council_number')})")
    print(f"    Certifications: {len(bci_data['statutory_certifications'])} verified statements")
    print("[SUCCESS] BCI Statement Verified!")

    # =========================================================================
    # CRITERION 2: DPDP Section 8(7) Erasure Assertion
    # =========================================================================
    print("\n[*] Testing Criterion 2: DPDP Section 8(7) Erasure (Cascading Chamber Wipe)...")
    res_erasure = client.delete("/api/v1/compliance/dpdp/execute-erasure")
    assert res_erasure.status_code == 200, f"Erasure failed with {res_erasure.status_code}: {res_erasure.text}"
    erasure_data = res_erasure.json()
    assert erasure_data.get("status") == "ERASURE_COMPLETE", f"Expected ERASURE_COMPLETE, got {erasure_data}"

    # Verify that case records are wiped from database
    case_check = supabase.table("cases").select("id").eq("advocate_id", TEST_ADVOCATE_ID).execute()
    assert len(case_check.data) == 0, f"Cases were not deleted: {case_check.data}"

    profile_check = supabase.table("advocate_profiles").select("id").eq("id", TEST_ADVOCATE_ID).execute()
    assert len(profile_check.data) == 0, f"Profile was not deleted: {profile_check.data}"

    # Verify final statutory audit log entry was preserved
    final_audit = supabase.table("dpdp_audit_logs") \
        .select("*") \
        .eq("advocate_id", TEST_ADVOCATE_ID) \
        .eq("action_type", "ACCOUNT_AND_CHAMBER_RIGHT_TO_ERASURE_EXECUTED") \
        .execute()
    assert len(final_audit.data) >= 1, "Erasure audit log was not preserved"

    print("    HTTP Status: 200")
    print(f"    Erasure Status: {erasure_data.get('status')}")
    print(f"    Remaining Cases in DB: {len(case_check.data)}")
    print(f"    Remaining Profiles in DB: {len(profile_check.data)}")
    print(f"    Preserved Immutable Audit Action: {final_audit.data[0]['action_type']}")
    print("[SUCCESS] Criterion 2 Verified! Full cascading wipe under DPDP Act Sec 8(7).")

    print("\n" + "=" * 55)
    print("ALL GOAL 19 BACKEND AUTONOMOUS CRITERIA SATISFIED!")
    print("=" * 55)

if __name__ == "__main__":
    test_dpdp_export_and_erasure()
