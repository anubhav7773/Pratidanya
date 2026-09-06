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

def setup_test_advocate():
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
    print("[+] Verified/upserted test advocate profile in database.")

def run_probe():
    setup_test_advocate()

    pdf_path = Path(__file__).parent / "sample_trial_judgment.pdf"
    if not pdf_path.exists():
        print(f"Error: Sample PDF does not exist at {pdf_path}")
        sys.exit(1)

    print(f"[*] Ingesting sample judgment PDF ({pdf_path.stat().st_size} bytes) to /api/v1/high-court/parse-trial-judgment...")
    
    with open(pdf_path, "rb") as f:
        response = client.post(
            "/api/v1/high-court/parse-trial-judgment",
            data={"pleading_type": "CRIMINAL_APPEAL"},
            files={"file": ("sample_trial_judgment.pdf", f, "application/pdf")}
        )

    print(f"[*] Response Status Code: {response.status_code}")
    if response.status_code != 200:
        print(f"[!] Request failed: {response.text}")
        sys.exit(1)

    data = response.json()
    print("[+] Successfully parsed judgment!")
    print(f"    Pleading ID: {data.get('pleading_id')}")
    print(f"    Court: {data.get('metadata', {}).get('court_name')}")
    print(f"    Convicted Sections: {data.get('metadata', {}).get('convicted_sections')}")
    print(f"    Sentence: {data.get('metadata', {}).get('quantum_of_sentence')}")
    print(f"    Operative Sentence: {data.get('operative_sentence_hindi')}")
    print(f"    Witness Flaws Count: {len(data.get('witness_flaws', []))}")
    print(f"    Appeal Grounds Count: {len(data.get('extracted_appeal_grounds', []))}")

    # Assertions per Goal 12 criteria
    assert data.get("metadata", {}).get("convicted_sections") is not None, "convicted_sections must be present"
    assert len(data.get("metadata", {}).get("convicted_sections")) > 0, "convicted_sections must not be empty"
    assert "witness_flaws" in data, "witness_flaws must be present in response"
    assert len(data.get("extracted_appeal_grounds", [])) > 0, "extracted_appeal_grounds must contain grounds"

    grounds = data.get("extracted_appeal_grounds", [])
    has_perversity = any("साक्ष्य के विकृत मूल्यांकन" in g or "Perverse" in g for g in grounds)
    print(f"    Has perversity grounds: {has_perversity}")

    print("\n[SUCCESS] Criterion 3: End-to-End API Ingestion Probe verified!")

if __name__ == "__main__":
    run_probe()
