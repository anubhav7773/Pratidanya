#!/usr/bin/env python3
"""
PRATIDNYA LEGAL TECH (ASIVERTICALS)
PRODUCTION PRECEDENT INGESTION ENGINE
Ingests curated Indian criminal judgments, generates 768-dim dense vectors
via Google text-embedding-004 / gemini-embedding-001, and upserts into Supabase pgvector.
"""

import os
import sys
import json
import time
import httpx
from pathlib import Path
from typing import List, Dict, Any

# Resolve backend root path
BACKEND_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(BACKEND_ROOT))

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from app.core.config import settings
from app.core.database import get_supabase_admin_client

CORPUS_PATH = BACKEND_ROOT / "data" / "corpus" / "real_criminal_precedents.json"
BASE_EMBED_URL = "https://generativelanguage.googleapis.com/v1beta/models"

async def fetch_dense_embedding(client: httpx.AsyncClient, text_content: str, title: str) -> List[float]:
    """Generates 768-dimension dense vector via Google Gemini Embedding API."""
    # Attempt primary model text-embedding-004, with fallback to gemini-embedding-001 (768-dim)
    candidate_models = [
        ("text-embedding-004", {"model": "models/text-embedding-004", "content": {"parts": [{"text": text_content.strip()}]}, "taskType": "RETRIEVAL_DOCUMENT", "title": title[:100]}),
        ("gemini-embedding-001", {"model": "models/gemini-embedding-001", "content": {"parts": [{"text": text_content.strip()}]}, "taskType": "RETRIEVAL_DOCUMENT", "title": title[:100], "outputDimensionality": 768})
    ]

    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": settings.GEMINI_API_KEY
    }

    for attempt in range(1, 4):
        for model_name, payload in candidate_models:
            url = f"{BASE_EMBED_URL}/{model_name}:embedContent"
            try:
                response = await client.post(url, headers=headers, json=payload, timeout=25.0)
                if response.status_code == 200:
                    data = response.json()
                    embedding = data.get("embedding", {}).get("values", [])
                    if len(embedding) == 768:
                        return embedding
                    raise ValueError(f"अमान्य आयाम: अपेक्षित 768, प्राप्त {len(embedding)}")
                elif response.status_code == 404:
                    # Model not enabled on this version, try next candidate
                    continue
                elif response.status_code == 429:
                    wait_sec = attempt * 3
                    print(f"[RateLimit] 429 प्राप्त ({model_name}), {wait_sec} सेकंड प्रतीक्षा कर रहे हैं...")
                    time.sleep(wait_sec)
                    break
                else:
                    print(f"[चेतावनी] {model_name} HTTP {response.status_code}: {response.text[:150]}")
            except httpx.RequestError as exc:
                if attempt == 3:
                    raise exc
                time.sleep(2)

    raise RuntimeError(f"वेक्टर निर्माण विफल: {title}")

async def run_ingestion():
    print("==================================================================")
    print("PRATIDNYA LEGAL TECH — REAL PRECEDENTS INGESTION PIPELINE")
    print("==================================================================")

    if not CORPUS_PATH.exists():
        print(f"[त्रुटि] कॉर्पस फ़ाइल नहीं मिली: {CORPUS_PATH}")
        sys.exit(1)

    with open(CORPUS_PATH, "r", encoding="utf-8") as f:
        precedents: List[Dict[str, Any]] = json.load(f)

    print(f"कुल संकलित मिसालें: {len(precedents)}")
    supabase = get_supabase_admin_client()

    success_count = 0
    async with httpx.AsyncClient() as client:
        for idx, prec in enumerate(precedents, start=1):
            citation_id = prec["citation_id"]
            case_title = prec["case_title"]
            print(f"\n[{idx}/{len(precedents)}] प्रसंस्करण: {case_title} ({citation_id})")

            # Combine legal ratio and verbatim text for deep semantic vector representation
            text_to_embed = (
                f"शीर्षक: {case_title}\n"
                f"न्यायालय: {prec['court_name']}\n"
                f"धाराएं: {', '.join(prec['section_numbers'])}\n"
                f"विधिक सारांश (Headnote): {prec['headnote_hindi']}\n"
                f"उद्धृत अंश (Verbatim): {prec['verbatim_text']}"
            )

            try:
                # 1. Generate 768-dim embedding
                vector = await fetch_dense_embedding(client, text_to_embed, title=citation_id)
                
                # 2. Prepare payload for Supabase pgvector
                record = {
                    "citation_id": citation_id,
                    "case_title": case_title,
                    "court_name": prec["court_name"],
                    "bench_type": prec.get("bench_type", "DIVISION_BENCH"),
                    "judgment_date": prec["judgment_date"],
                    "act_name": prec["act_name"],
                    "section_numbers": prec["section_numbers"],
                    "headnote_hindi": prec["headnote_hindi"],
                    "verbatim_text": prec["verbatim_text"],
                    "paragraph_number": prec.get("paragraph_number"),
                    "verified_source_url": prec["verified_source_url"],
                    "embedding": vector,
                    "is_active": True
                }

                # 3. Upsert into Supabase pgvector table
                res = supabase.table("verified_precedents") \
                    .upsert(record, on_conflict="citation_id") \
                    .execute()

                print(f"  ✓ डेटाबेस में सुरक्षित (Vector Dimension: {len(vector)})")
                success_count += 1
                
                # Respect rate limits for embedding API
                time.sleep(1.0)
            except Exception as e:
                print(f"  ✗ विफलता [{citation_id}]: {e}")

    print("\n==================================================================")
    print(f"इनजेशन पूर्ण: {success_count}/{len(precedents)} मिसालें सफलतापूर्वक संग्रहीत।")
    print("==================================================================")

if __name__ == "__main__":
    import asyncio
    asyncio.run(run_ingestion())
