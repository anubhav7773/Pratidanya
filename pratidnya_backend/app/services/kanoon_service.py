import json
import httpx
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException
from app.core.config import settings
from app.core.database import get_supabase_admin_client

MOCK_COURTS_DATA = [
    {
        "id": "APHC01",
        "object": "court",
        "name": "High Court of Judicature at Allahabad",
        "jurisdiction": "State of Uttar Pradesh",
        "court_level": "HIGH_COURT",
        "district_coverage": ["Lucknow", "Prayagraj"],
        "bench_locations": ["Allahabad", "Lucknow"]
    }
]

MOCK_CASE_SEARCH_DATA = [
    {
        "id": "mock_case_411",
        "object": "case",
        "court_id": "APHC01",
        "case_number": "Criminal Misc. Bail Application No. 10244 of 2026",
        "cnr_number": "UPHC010102442026",
        "filing_date": "2026-02-10",
        "status": "DISPOSED",
        "petitioner": "श्यामू उर्फ़ श्याम (परीक्षण रिकॉर्ड)",
        "respondent": "उत्तर प्रदेश राज्य",
        "police_station": "कोतवाली नगर",
        "fir_number": "124/2026",
        "under_sections": ["धारा 379 भा.दं.वि.", "धारा 411 भा.दं.वि."],
        "presiding_judge": "मा० न्यायमूर्ति वी.के. शर्मा"
    }
]

MOCK_CASE_ORDERS_DATA = [
    {
        "id": "mock_ord_411_bail",
        "object": "case_order",
        "order_date": "2026-02-28",
        "order_type": "FINAL_DISPOSAL_ORDER",
        "judge_names": ["मा० न्यायमूर्ति वी.के. शर्मा"],
        "pdf_download_url": "https://judgments.ecourts.gov.in/dummy_verified_record_411.pdf",
        "pdf_sha256": "mock_hash_verification_passed",
        "order_text_snippet": "स्वतंत्र साक्षियों के अभाव एवं धारा 100(4) दंड प्रक्रिया संहिता के उल्लंघन के आधार पर आवेदक की जमानत स्वीकार की जाती है।"
    }
]

class KanoonService:
    def __init__(self):
        self.api_key = settings.KANOON_DEV_API_KEY
        self.base_url = "https://api.kanoon.dev/v1"
        self.use_mock = settings.MOCK_KANOON_API
        self.cache_ttl_hours = 12

    def _get_headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Accept": "application/json",
            "Content-Type": "application/json"
        }

    async def _get_from_cache(self, cache_key: str) -> Optional[Dict[str, Any]]:
        supabase = get_supabase_admin_client()
        try:
            result = supabase.table("kanoon_api_cache") \
                .select("payload") \
                .eq("cache_key", cache_key) \
                .gt("expires_at", datetime.now(timezone.utc).isoformat()) \
                .maybe_single() \
                .execute()
            if result and result.data:
                return result.data["payload"]
        except Exception:
            pass
        return None

    async def _save_to_cache(self, cache_key: str, endpoint: str, payload: Dict[str, Any]):
        supabase = get_supabase_admin_client()
        expires = datetime.now(timezone.utc) + timedelta(hours=self.cache_ttl_hours)
        try:
            supabase.table("kanoon_api_cache").upsert({
                "cache_key": cache_key,
                "endpoint": endpoint,
                "payload": payload,
                "expires_at": expires.isoformat()
            }).execute()
        except Exception:
            pass

    async def list_courts(self) -> List[Dict[str, Any]]:
        if self.use_mock:
            return MOCK_COURTS_DATA

        cache_key = "kanoon_courts_list"
        cached = await self._get_from_cache(cache_key)
        if cached:
            return cached.get("data", [])

        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.get(f"{self.base_url}/courts", headers=self._get_headers())
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=f"kanoon.dev Courts त्रुटि: {response.text}")
            
            data = response.json()
            await self._save_to_cache(cache_key, "/courts", data)
            return data.get("data", [])

    async def search_cases(self, court_id: str, query: str, year: Optional[int] = None) -> List[Dict[str, Any]]:
        if self.use_mock:
            return MOCK_CASE_SEARCH_DATA

        cache_key = f"case_search_{court_id}_{query}_{year or 'all'}"
        cached = await self._get_from_cache(cache_key)
        if cached:
            return cached.get("data", [])

        params = {"q": query.strip(), "limit": 20}
        if year:
            params["year"] = year

        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                f"{self.base_url}/courts/{court_id}/cases",
                headers=self._get_headers(),
                params=params
            )
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=f"kanoon.dev Case Search त्रुटि: {response.text}")
            
            data = response.json()
            await self._save_to_cache(cache_key, f"/courts/{court_id}/cases", data)
            return data.get("data", [])

    async def get_case_orders(self, court_id: str, case_id: str) -> List[Dict[str, Any]]:
        if self.use_mock:
            return MOCK_CASE_ORDERS_DATA

        cache_key = f"case_orders_{court_id}_{case_id}"
        cached = await self._get_from_cache(cache_key)
        if cached:
            return cached.get("data", [])

        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                f"{self.base_url}/courts/{court_id}/cases/{case_id}/orders",
                headers=self._get_headers()
            )
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=f"kanoon.dev Orders त्रुटि: {response.text}")

            data = response.json()
            await self._save_to_cache(cache_key, f"/courts/{court_id}/cases/{case_id}/orders", data)
            return data.get("data", [])
