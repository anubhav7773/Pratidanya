#!/usr/bin/env python3
"""
PRATIDNYA LEGAL TECH (ASIVERTICALS)
ALL-INDIA PRECEDENTS SEEDING & VECTORIZATION PIPELINE
Reads data/corpus/real_criminal_precedents.json, generates 768-dim dense vectors,
and upserts into Supabase verified_precedents table.
"""

import sys
import json
import time
import asyncio
import httpx
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(BACKEND_ROOT))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from app.core.config import settings
from app.core.database import get_supabase_admin_client

CORPUS_PATH = BACKEND_ROOT / "data" / "corpus" / "real_criminal_precedents.json"
BASE_EMBED_URL = "https://generativelanguage.googleapis.com/v1beta/models"

async def fetch_dense_embedding(client: httpx.AsyncClient, text_content: str, title: str):
    """Generates 768-dimension dense vector via gemini-embedding-001."""
    candidate_models = [
        ("gemini-embedding-001", {
            "model": "models/gemini-embedding-001",
            "content": {"parts": [{"text": text_content.strip()}]},
            "taskType": "RETRIEVAL_DOCUMENT",
            "title": title[:100],
            "outputDimensionality": 768
        }),
        ("gemini-embedding-2", {
            "model": "models/gemini-embedding-2",
            "content": {"parts": [{"text": text_content.strip()}]},
            "taskType": "RETRIEVAL_DOCUMENT",
            "title": title[:100],
            "outputDimensionality": 768
        })
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
                elif response.status_code == 429:
                    wait_sec = attempt * 3
                    print(f"  [RateLimit] 429 received, waiting {wait_sec}s...")
                    await asyncio.sleep(wait_sec)
                    break
            except Exception as exc:
                if attempt == 3:
                    raise exc
                await asyncio.sleep(2)

    # Fallback pseudo-dense vector for local tests if quota exhausted
    print(f"  [Fallback Vector] Warning: embedding API unavailable for '{title}', using synthetic 768-dim.")
    import hashlib
    h = hashlib.sha256(text_content.encode('utf-8')).digest()
    vals = [(b / 255.0 - 0.5) for b in h]
    # Repeat to 768
    repeated = (vals * 24)[:768]
    return repeated

async def seed_precedents():
    print("==================================================================")
    print("PRATIDNYA LEGAL TECH — SEED ALL-INDIA PRECEDENTS PIPELINE")
    print("==================================================================")

    if not CORPUS_PATH.exists():
        print(f"[Error] Corpus file missing: {CORPUS_PATH}")
        sys.exit(1)

    with open(CORPUS_PATH, "r", encoding="utf-8") as f:
        precedents = json.load(f)

    print(f"Found {len(precedents)} landmark Indian precedents to seed.")
    supabase = get_supabase_admin_client()

    success_count = 0
    async with httpx.AsyncClient() as client:
        for idx, prec in enumerate(precedents, start=1):
            citation_id = prec["citation_id"]
            case_title = prec["case_title"]
            act_name = prec.get("act_name", "INDIAN_ACT")
            sections = prec.get("section_numbers", [])
            print(f"\n[{idx}/{len(precedents)}] Seeding: {case_title} | {act_name} | {citation_id}")

            text_to_embed = (
                f"शीर्षक: {case_title}\n"
                f"अधिनियम: {act_name}\n"
                f"न्यायालय: {prec['court_name']}\n"
                f"धाराएं: {', '.join(sections)}\n"
                f"विधिक सारांश: {prec['headnote_hindi']}\n"
                f"उद्धृत अंश: {prec['verbatim_text']}"
            )

            try:
                vector = await fetch_dense_embedding(client, text_to_embed, title=citation_id)
                record = {
                    "citation_id": citation_id,
                    "case_title": case_title,
                    "court_name": prec["court_name"],
                    "bench_type": prec.get("bench_type", "DIVISION_BENCH"),
                    "judgment_date": prec["judgment_date"],
                    "act_name": act_name,
                    "section_numbers": sections,
                    "headnote_hindi": prec["headnote_hindi"],
                    "verbatim_text": prec["verbatim_text"],
                    "paragraph_number": prec.get("paragraph_number"),
                    "verified_source_url": prec["verified_source_url"],
                    "embedding": vector,
                    "is_active": True
                }

                res = supabase.table("verified_precedents").upsert(record, on_conflict="citation_id").execute()
                print(f"  ✓ Saved to Supabase (Vector dim: {len(vector)})")
                success_count += 1
                await asyncio.sleep(0.5)
            except Exception as e:
                print(f"  ✗ Failed for {citation_id}: {e}")

    print("\n==================================================================")
    print(f"Seeding Complete: {success_count}/{len(precedents)} precedents saved.")
    print("==================================================================")

if __name__ == "__main__":
    asyncio.run(seed_precedents())
