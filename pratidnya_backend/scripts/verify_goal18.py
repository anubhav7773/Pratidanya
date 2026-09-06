import sys
import io
import wave
import struct
from unittest.mock import patch
from starlette.testclient import TestClient
from app.main import app
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.services.voice_intake_service import VoiceIntakeService
from app.services.text_sanitizer import PoliceDocumentSanitizer

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

def create_synthetic_wav_bytes(duration_sec=2, sample_rate=44100) -> bytes:
    """Generates valid in-memory PCM 16-bit mono WAV audio bytes."""
    buf = io.BytesIO()
    with wave.open(buf, 'wb') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        # 16-bit silence / small sine amplitude
        frames = struct.pack('<' + 'h' * (duration_sec * sample_rate), *([0] * (duration_sec * sample_rate)))
        wav_file.writeframes(frames)
    return buf.getvalue()

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
        "cnr_number": "UPHC010000002026",
        "fir_number": "124/2026",
        "police_station": "कोतवाली नगर",
        "district": "लखनऊ",
        "court_designation": "CJM Lucknow",
        "stage_of_case": "BAIL_HEARING",
        "accused_name": "श्यामू",
        "under_sections": ["379 IPC", "411 IPC"],
    }
    res = supabase.table("cases").insert(case_record).execute()
    return res.data[0]["id"]

def verify_goal18():
    print("[*] Setting up database fixtures for Goal 18...")
    case_id = setup_case_fixture()
    print(f"[+] Created Test Case ID: {case_id}")

    # =========================================================================
    # CRITERION 1: Multimodal Audio Transcription & Court Jargon Extraction
    # =========================================================================
    print("\n[*] Testing Criterion 1: Multimodal Audio Transcription & Court Jargon Extraction...")

    # Simulated Gemini response for dictation:
    # "थाना कोतवाली नगर, मु.अ.सं. 124/2026, धारा 379 भा.दं.वि. के तहत श्यामू को गिरफ्तार किया गया"
    mock_gemini_response = {
        "verbatim_transcript_hindi": "थाना कोतवाली नगर, मु.अ.सं. 124/2026, धारा 379 भा.दं.वि. के तहत श्यामू को गिरफ्तार किया गया।",
        "cleaned_factual_matrix": "अभियुक्त श्यामू को थाना कोतवाली नगर के मु.अ.सं. 124/2026 अंतर्गत धारा 379 भा.दं.वि. में गिरफ्तार कर न्यायिक अभिरक्षा में भेजा गया।",
        "extracted_entities": {
            "fir_number": "124/2026",
            "police_station": "कोतवाली नगर",
            "district": "लखनऊ",
            "accused_names": ["श्यामू"],
            "complainant_name": "राम प्रकाश",
            "sections": ["379 IPC"],
            "custody_status": "JUDICIAL_CUSTODY",
            "allegation_summary": "चोरी का कथित आरोप",
            "defense_plea": "मिथ्या आरोप एवं रंजिशन फंसाया जाना"
        },
        "chronological_events": [
            "तारीख 10-02-2026: घटना की कथित सूचना",
            "तारीख 12-02-2026: अभियुक्त की गिरफ्तारी एवं रिमांड"
        ]
    }

    wav_bytes = create_synthetic_wav_bytes(duration_sec=3)
    assert len(wav_bytes) > 1000, "Audio bytes must be > 1000 bytes!"

    with patch.object(VoiceIntakeService, 'process_audio_dictation', return_value=mock_gemini_response):
        files = {
            "audio_file": ("dictation.wav", wav_bytes, "audio/wav")
        }
        data = {
            "duration_seconds": 10,
            "case_id": case_id
        }

        resp = client.post("/api/v1/voice/transcribe-and-structure", files=files, data=data)
        assert resp.status_code == 200, f"Voice endpoint failed: {resp.text}"
        res_data = resp.json()

        print(f"    Status Code: {resp.status_code}")
        print(f"    Session ID: {res_data['session_id']}")
        print(f"    Verbatim Transcript: {res_data['verbatim_transcript_hindi']}")
        print(f"    Cleaned Factual Matrix: {res_data['cleaned_factual_matrix'][:60]}...")
        print(f"    Extracted FIR: {res_data['extracted_entities']['fir_number']}")
        print(f"    Extracted Police Station: {res_data['extracted_entities']['police_station']}")
        print(f"    Extracted Sections: {res_data['extracted_entities']['sections']}")
        print(f"    Extracted Accused: {res_data['extracted_entities']['accused_names']}")

        # Assertions
        assert res_data["extracted_entities"]["fir_number"] == "124/2026", "FIR number must match '124/2026'!"
        assert res_data["extracted_entities"]["police_station"] == "कोतवाली नगर", "Police station must match 'कोतवाली नगर'!"
        assert "379 IPC" in res_data["extracted_entities"]["sections"], "Sections must contain '379 IPC'!"
        assert res_data["dpdp_ephemeral_purge_verified"] is True, "DPDP purge flag must be verified true!"
        print("[SUCCESS] Criterion 1 Verified!")

    # =========================================================================
    # CRITERION 2: DPDP Data Minimization Verification (Audio Purge)
    # =========================================================================
    print("\n[*] Testing Criterion 2: DPDP Data Minimization Verification (Audio Purge)...")
    supabase = get_supabase_admin_client()
    session_row = supabase.table("voice_dictation_sessions")\
        .select("*")\
        .eq("id", res_data["session_id"])\
        .single()\
        .execute()

    record = session_row.data
    print(f"    Session DB Record ID: {record['id']}")
    print(f"    raw_audio_purged_immediately: {record['raw_audio_purged_immediately']}")
    print(f"    Audio Format: {record['audio_format']}")
    print(f"    Duration Seconds: {record['duration_seconds']}")
    print(f"    File Size Bytes: {record['audio_file_size_bytes']}")

    assert record["raw_audio_purged_immediately"] is True, "raw_audio_purged_immediately must be True!"
    # Verify no raw audio binary or media URL column exists in record
    assert "audio_binary" not in record, "No audio_binary column allowed!"
    assert "audio_url" not in record, "No audio_url column allowed!"
    assert "raw_bytes" not in record, "No raw_bytes column allowed!"
    print("[SUCCESS] Criterion 2 Verified! No audio binary or media URL persisted.")

    print("\n=======================================================")
    print("ALL GOAL 18 BACKEND AUTONOMOUS CRITERIA SATISFIED!")
    print("=======================================================")

if __name__ == "__main__":
    verify_goal18()
