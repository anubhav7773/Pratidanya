import sys
import os
from pathlib import Path

# Ensure UTF-8 output on Windows terminal
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

from starlette.testclient import TestClient
from app.main import app
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client

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

def setup_test_fixtures():
    supabase = get_supabase_admin_client()

    # 1. Advocate profile
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

    # 2. Appeal Pleading Record
    appeal_record = {
        "advocate_id": TEST_ADVOCATE_ID,
        "pleading_type": "CRIMINAL_APPEAL",
        "high_court_bench": "LUCKNOW_BENCH",
        "trial_court_name": "न्यायालय अपर सत्र न्यायाधीश, न्यायालय संख्या 4, लखनऊ",
        "trial_case_number": "सत्र परीक्षण संख्या 342/2021",
        "trial_judgment_date": "2024-03-15",
        "trial_presiding_judge": "श्री अजय कुमार श्रीवास्तव, एच.जे.एस.",
        "convicted_sections": ["307 IPC", "323 IPC"],
        "quantum_of_sentence": "7 वर्ष का कठोर कारावास एवं ₹5,000 अर्थदंड",
        "case_title": "राजू उर्फ राजेश बनाम उत्तर प्रदेश राज्य",
        "accused_names": ["राजू उर्फ राजेश"],
        "police_station": "हजरतगंज",
        "district": "लखनऊ",
        "fir_number": "112/2021",
        "limitation_expiry_date": "2024-05-15",
        "appellant_custody_status": "IN_JAIL",
        "days_in_custody": 140
    }
    res_app = supabase.table("high_court_pleadings").insert(appeal_record).execute()
    appeal_id = res_app.data[0]["id"]

    # Analysis for Appeal
    analysis_app = {
        "pleading_id": appeal_id,
        "advocate_id": TEST_ADVOCATE_ID,
        "operative_sentence_hindi": "अभियुक्त को 7 वर्ष के कठोर कारावास की सजा सुनाई जाती है।",
        "prosecution_witness_flaws": [
            {
                "witness_name": "PW-1",
                "statement_extract": "PW-1 ने घटना दोपहर में बताई जबकि PW-2 ने रात में",
                "contradiction_nature": "घटना के समय में प्रत्यक्ष अंतर्विरोध",
                "impact_on_prosecution": "अभियोजन कथानक पूर्णतः संदिग्ध"
            }
        ],
        "procedural_omissions": [],
        "section_313_examination_defects": "अभियुक्त के समक्ष FSL रिपोर्ट व बरामदगी का साक्ष्य धारा 313 के बयान में नहीं रखा गया।",
        "ocular_vs_medical_conflict": "चश्मदीद साक्षी ने धारदार हथियार से वार बताया जबकि मेडिकल रिपोर्ट में केवल कुंद चोट (Blunt Injury) दर्ज है।",
        "raw_judgment_word_count": 850
    }
    supabase.table("trial_court_judgment_analyses").insert(analysis_app).execute()

    # 3. Revision Pleading Record
    rev_record = {
        "advocate_id": TEST_ADVOCATE_ID,
        "pleading_type": "CRIMINAL_REVISION",
        "high_court_bench": "LUCKNOW_BENCH",
        "trial_court_name": "न्यायालय अपर मुख्य न्यायिक मजिस्ट्रेट, लखनऊ",
        "trial_case_number": "आपराधिक वाद संख्या 512/2023",
        "trial_judgment_date": "2024-04-10",
        "trial_presiding_judge": "न्यायिक अधिकारी",
        "convicted_sections": ["138 NI Act"],
        "quantum_of_sentence": "1 वर्ष का कारावास",
        "case_title": "सुनील बनाम अमित",
        "accused_names": ["सुनील"],
        "police_station": "गोमती नगर",
        "district": "लखनऊ",
        "fir_number": "परिवाद 512/2023",
        "limitation_expiry_date": "2024-07-10",
        "appellant_custody_status": "ON_PROVISIONAL_BAIL_389",
        "days_in_custody": 0
    }
    res_rev = supabase.table("high_court_pleadings").insert(rev_record).execute()
    revision_id = res_rev.data[0]["id"]

    analysis_rev = {
        "pleading_id": revision_id,
        "advocate_id": TEST_ADVOCATE_ID,
        "operative_sentence_hindi": "आदेश: परिवादी द्वारा प्रस्तुत परिवाद पर अभियुक्त को तलब किया जाता है।",
        "prosecution_witness_flaws": [],
        "procedural_omissions": [],
        "raw_judgment_word_count": 300
    }
    supabase.table("trial_court_judgment_analyses").insert(analysis_rev).execute()

    return appeal_id, revision_id

def verify_goal13():
    print("[*] Setting up database fixtures for Goal 13...")
    appeal_id, revision_id = setup_test_fixtures()
    print(f"[+] Created Appeal Pleading ID: {appeal_id}")
    print(f"[+] Created Revision Pleading ID: {revision_id}")

    # =========================================================================
    # CRITERION 1: Statutory Revision Gate (Sec 397(2) Interlocutory Order Bar)
    # =========================================================================
    print("\n[*] Testing Criterion 1: Sec 397(2) Interlocutory Bar...")
    resp_interlocutory = client.post(
        "/api/v1/high-court/generate-grounds",
        json={
            "pleading_id": revision_id,
            "is_interlocutory_order": True,
            "seeks_acquittal_conversion": False
        }
    )
    print(f"    Status Code: {resp_interlocutory.status_code}")
    assert resp_interlocutory.status_code == 400, f"Expected 400, got {resp_interlocutory.status_code}"
    detail = resp_interlocutory.json().get("detail", "")
    assert "धारा 397(2)" in detail or "अंतर्वर्ती आदेश" in detail, f"Expected Sec 397(2) bar error, got: {detail}"
    print(f"    Detail: {detail[:120]}...")
    print("[SUCCESS] Criterion 1 Verified!")

    # =========================================================================
    # CRITERION 2: Statutory Revision Gate (Sec 401(3) Acquittal Conversion Bar)
    # =========================================================================
    print("\n[*] Testing Criterion 2: Sec 401(3) Acquittal Conversion Bar...")
    resp_acquittal = client.post(
        "/api/v1/high-court/generate-grounds",
        json={
            "pleading_id": revision_id,
            "is_interlocutory_order": False,
            "seeks_acquittal_conversion": True
        }
    )
    print(f"    Status Code: {resp_acquittal.status_code}")
    assert resp_acquittal.status_code == 400, f"Expected 400, got {resp_acquittal.status_code}"
    detail_acq = resp_acquittal.json().get("detail", "")
    assert "धारा 401(3)" in detail_acq or "दोषमुक्ति" in detail_acq, f"Expected Sec 401(3) bar error, got: {detail_acq}"
    print(f"    Detail: {detail_acq[:120]}...")
    print("[SUCCESS] Criterion 2 Verified!")

    # =========================================================================
    # CRITERION 3: Criminal Appeal (Sec 374) Generation & Precedent Grounding
    # =========================================================================
    print("\n[*] Testing Criterion 3: Criminal Appeal Generation with Real pgvector Precedents...")
    resp_appeal = client.post(
        "/api/v1/high-court/generate-grounds",
        json={
            "pleading_id": appeal_id,
            "statute_system": "IPC_CRPC",
            "include_section_389_bail_grounds": True
        }
    )
    print(f"    Status Code: {resp_appeal.status_code}")
    if resp_appeal.status_code != 200:
        print(f"[!] Appeal Generation failed: {resp_appeal.text}")
        sys.exit(1)

    appeal_data = resp_appeal.json()
    print("[+] Appeal Grounds generated successfully:")
    print(f"    Memo Title: {appeal_data.get('memo_title_hindi')}")
    print(f"    Court Block: {appeal_data.get('court_title_block')}")
    print(f"    Grounds Count: {len(appeal_data.get('grounds', []))}")
    print(f"    Interim Suspension Prayer: {appeal_data.get('interim_suspension_prayer')}")
    print(f"    Cited Precedents Count: {len(appeal_data.get('cited_precedents', []))}")

    # Assertions per Goal 13 criteria
    assert "दांडिक अपील अंतर्गत धारा 374(2) दंड प्रक्रिया संहिता" in appeal_data.get("memo_title_hindi", "")
    assert len(appeal_data.get("grounds", [])) > 0, "Must contain generated grounds"
    assert appeal_data.get("interim_suspension_prayer") is not None, "Must contain Sec 389 interim suspension prayer"
    assert "389" in appeal_data.get("interim_suspension_prayer", "")

    # Grounding check
    assert len(appeal_data.get("cited_precedents", [])) > 0, "Must cite real pgvector precedents"
    for prec in appeal_data.get("cited_precedents", []):
        assert prec.get("is_grounded_in_record") is True
        print(f"    Cited: {prec.get('citation_id')} - {prec.get('case_title')} ({prec.get('verified_source_url')})")

    print("\n[SUCCESS] Criterion 3 Verified!")
    print("\n=======================================================")
    print("ALL GOAL 13 AUTONOMOUS VERIFICATION CRITERIA SATISFIED!")
    print("=======================================================")

if __name__ == "__main__":
    verify_goal13()
