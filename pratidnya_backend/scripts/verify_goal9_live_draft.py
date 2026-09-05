#!/usr/bin/env python3
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(BACKEND_ROOT))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from starlette.testclient import TestClient
from app.main import app
from app.core.security import verify_advocate_token

app.dependency_overrides[verify_advocate_token] = lambda: {
    "uid": "live_test_advocate_uid",
    "email": "advocate@pratidnya.in"
}

client = TestClient(app)

payload = {
    "case_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "fir_number": "124/2026",
    "sections": ["379 IPC", "411 IPC"],
    "police_station": "कोतवाली नगर",
    "district": "लखनऊ",
    "factual_summary": "कथित जब्ती के समय धारा 100(4) दंड प्रक्रिया संहिता का उल्लंघन हुआ। कोई स्वतंत्र साक्षी नहीं था।",
    "custody_status": "JUDICIAL_CUSTODY",
    "is_dummy_testing": False
}

print("Executing POST /api/v1/drafts/generate-360...")
res = client.post("/api/v1/drafts/generate-360", json=payload)
print(f"Status Code: {res.status_code}")

if res.status_code != 200:
    print(f"Error Detail: {res.text}")
    sys.exit(1)

data = res.json()
print(f"Court Header: {data.get('court_header')}")
print(f"Case Title: {data.get('case_title')}")
print(f"Statutory Grounds ({len(data.get('statutory_grounds', []))}):")
for g in data.get("statutory_grounds", [])[:3]:
    print(f"  * {g}")

print(f"Prosecution Weaknesses ({len(data.get('prosecution_weaknesses', []))}):")
for w in data.get("prosecution_weaknesses", [])[:3]:
    print(f"  * {w}")

print(f"Cited Precedents ({len(data.get('cited_precedents', []))}):")
for cp in data.get("cited_precedents", []):
    print(f"  * [{cp['citation_id']}] {cp['case_title']}")
    print(f"    Source: {cp['verified_source_url']}")
    print(f"    Grounded: {cp['is_grounded_in_record']}")

assert res.status_code == 200
assert len(data.get("statutory_grounds", [])) > 0
assert len(data.get("cited_precedents", [])) > 0
assert any("TRIMBAK" in cp["citation_id"] for cp in data.get("cited_precedents", []))
print("\n=== End-to-End Live 360 Draft Generation PASSED! ===")
