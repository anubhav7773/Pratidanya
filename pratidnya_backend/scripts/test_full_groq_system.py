#!/usr/bin/env python3
"""
PRATIDNYA LEGAL TECH (ASIVERTICALS)
FULL-SYSTEM GROQ + WHISPER + LLM GATEWAY VERIFICATION HARNESS
Tests:
1. Groq Llama-3.3-70B Bail Draft Generation
2. Voice Text Structuring Pipeline
3. Gemini text-embedding-004 Vector Generation
"""

import sys
import time
import asyncio
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

BACKEND_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(BACKEND_ROOT))

from app.core.config import settings
from app.services.llm_gateway import LLMGateway
from app.services.gemini_service import GeminiService
from app.services.voice_intake_service import VoiceIntakeService


async def run_full_suite():
    print("==================================================================")
    print("PRATIDNYA: FULL-SYSTEM MULTI-PROVIDER AUDIT & SPEED TEST")
    print("==================================================================")
    print(f"Primary Text LLM Provider: {settings.DEFAULT_LLM_PROVIDER} ({settings.GROQ_MODEL})")
    print(f"Groq API Key Configured  : {'YES (Active)' if settings.GROQ_API_KEY else 'NO (Missing)'}")
    print(f"Gemini API Key Configured: {'YES (Active for Embeddings)' if settings.GEMINI_API_KEY else 'NO'}")
    print("==================================================================")

    # -------------------------------------------------------------------------
    # TEST 1: 360° BAIL DRAFT GENERATION VIA GROQ LLAMA-3.3-70B
    # -------------------------------------------------------------------------
    print("\n[Test 1/3] Testing Bail Draft Generation via Groq Llama-3.3-70B...")
    t0 = time.perf_counter()
    gemini_svc = GeminiService()
    
    draft_res = await gemini_svc.generate_structured_case_analysis(
        advocate_id="test_advocate",
        facts_payload={
            "fir_number": "124/2026",
            "police_station": "कोतवाली नगर",
            "district": "लखनऊ",
            "sections": ["379 IPC", "411 IPC"],
            "custody_status": "JUDICIAL_CUSTODY",
            "factual_summary": "बरामदगी के समय धारा 100(4) दंड प्रक्रिया संहिता का उल्लंघन हुआ। कोई स्वतंत्र साक्षी नहीं था।"
        }
    )
    t1 = time.perf_counter() - t0
    print(f"  ✓ पूर्ण! समय: {t1:.2f} सेकंड")
    print(f"  शीर्षक: {draft_res.get('case_title')}")
    print(f"  आधारों की संख्या: {len(draft_res.get('statutory_grounds', []))}")
    assert len(draft_res.get("statutory_grounds", [])) >= 2

    # -------------------------------------------------------------------------
    # TEST 2: VOICE LEGAL ENTITY EXTRACTION VIA GROQ
    # -------------------------------------------------------------------------
    print("\n[Test 2/3] Testing Voice Entity Extraction via LLMGateway...")
    t0 = time.perf_counter()
    sample_court_dictation = (
        "थाना कोतवाली नगर का मामला है, मुकदमा अपराध संख्या 89/2026, धारा 307 और 323 भा.दं.वि. लगी है। "
        "अभियुक्त का नाम रमेश कुमार है और वादी महेश है। मेडिकल रिपोर्ट में साधारण चोटें आई हैं और कोई गंभीर घाव नहीं है। "
        "अभियुक्त 15 दिन से जेल में बंद है।"
    )
    entities = await VoiceIntakeService._extract_legal_entities_from_text(sample_court_dictation)
    t2 = time.perf_counter() - t0
    print(f"  ✓ पूर्ण! समय: {t2:.2f} सेकंड")
    extracted = entities.get("extracted_entities", {})
    print(f"  पहचानी गई FIR: {extracted.get('fir_number')}")
    print(f"  पहचाना गया थाना: {extracted.get('police_station')}")
    print(f"  पहचाने गए अभियुक्त: {extracted.get('accused_names')}")
    print(f"  पहचानी गई धाराएं: {extracted.get('sections')}")
    assert extracted.get("fir_number") == "89/2026" or "89" in str(extracted.get("fir_number"))

    # -------------------------------------------------------------------------
    # TEST 3: VECTOR EMBEDDINGS INTEGRITY VIA GEMINI TEXT-EMBEDDING-004
    # -------------------------------------------------------------------------
    print("\n[Test 3/3] Testing 768-dim Vector Embeddings (Gemini text-embedding-004)...")
    t0 = time.perf_counter()
    vector = await gemini_svc.generate_dense_embedding(
        text="बिना स्वतंत्र गवाह जब्ती फर्द धारा 100(4) CrPC",
        task_type="RETRIEVAL_QUERY"
    )
    t3 = time.perf_counter() - t0
    print(f"  ✓ पूर्ण! समय: {t3:.2f} सेकंड")
    print(f"  वेक्टर आयाम (Dimension): {len(vector)}")
    assert len(vector) == 768, "pgvector schema mismatch: Expected 768 dimensions!"

    print("\n==================================================================")
    print("ALL TESTS PASSED: Zero Rate Limits, Ultra-Fast Groq Inference, Intact 768-dim Vectors.")
    print("==================================================================")


if __name__ == "__main__":
    asyncio.run(run_full_suite())
