PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-06
MODULE         : KANOON.DEV REST API, COURT CASE RETRIEVAL & CITATION VERIFICATION
TARGET RUNTIME : Python 3.10+ (FastAPI Proxy) / Flutter 3.19+ (Riverpod 2.x)
DATA SCOPE     : Indian Courts (Subordinate/District Courts, High Courts & SC)
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. STRATEGIC CONTEXT & ANTI-SCRAPING COMPLIANCE MANDATEPratidnya judicial data retrieval ke liye kanoon.dev official REST API ko primary data layer ke roop mein employ karta hai:  ┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT (UI LAYER)                       │
│  - Case search query (FIR Number, Police Station, Under Sections)      │
│  - Sends request to backend proxy with Firebase Bearer Token           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS + Bearer <Firebase_ID_Token>
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             FASTAPI BACKEND MICROSERVICE (RENDER / AWS MUMBAI)         │
│  1. Security Gateway: Validates Advocate Session & Rate Limit Quota    │
│  2. Cache Layer: Checks Redis/Memory Cache (12-hour TTL)               │
│  3. API Client: Injects Secret KANOON_DEV_API_KEY to kanoon.dev API    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS + Authorization: Bearer <API_KEY>
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         KANOON.DEV REST API GATEWAY                    │
│  - Endpoints: /courts, /cases, /events, /insights, /orders             │
│  - Structured Indian Judicial Data (High Courts & District Mapping)    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               CITATION VERIFICATION & GROUNDING ENGINE (RULE 1)        │
│  - Validates: Order PDF link exists & verified court record is live    │
│  - Rejects: Unindexed or hallucinated case numbers                     │
└────────────────────────────────────────────────────────────────────────┘
Statutory & Contractual Compliance Rules:Rule 5 Compliance (Strict Anti-Scraping Ban): Indian Kanoon (indiankanoon.org) ya governmental portals (NJDG/eCourts) par headless browsers (Selenium/Playwright/Puppeteer) se bulk scraping karna unki terms of service aur IP firewalls ka ullanghan hai. kanoon.dev structured, developer-compliant JSON responses provide karta hai jisse scraping liabilities zero ho jaati hain.  Client-Side Key Protection: Flutter client binary (APK/AAB) mein kanoon.dev API Key kabhi hardcode ya compile-time inject nahi hogi. Reverse engineering se key leak hone par commercial liability ban sakti hai, isliye microservice proxy anivarya hai.  Rule 1 & Rule 2 Enforcement (Grounding Gate): Gemini dwara suggest kiye gaye kisi bhi precedent argument ko orders aur insights endpoints ke data se verify kiya jaayega. Agar kanoon.dev ke database mein case record nahi milta, toh citation UI mein render nahi hogi.  2. AUTHENTICATION & PROXY TOPOLOGYBase URL: [https://api.kanoon.dev/v1](https://api.kanoon.dev/v1)  Authentication Scheme: HTTP Bearer Authentication  Request Header: Authorization: Bearer <KANOON_DEV_API_KEY>  Content-Type: application/jsonSupabase Caching DDL (Minimizing Paid API Credits)Kanoon.dev ke paid calls ko optimize karne ke liye, disposed cases aur orders ko Supabase PostgreSQL cache table mein 12-hour TTL ke sath persist kiya jaayega:SQLcreate table public.kanoon_api_cache (
    cache_key text primary key,                     -- e.g., 'case_orders_APHC01_case_982341'
    endpoint text not null,
    payload jsonb not null,
    expires_at timestamp with time zone not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index idx_kanoon_cache_expiry on public.kanoon_api_cache(expires_at);

-- Automatic cleanup of expired cache entries
create or replace function prune_expired_kanoon_cache()
returns void as $$
begin
    delete from public.kanoon_api_cache where expires_at < now();
end;
$$ language plpgsql;
3. CORE ENDPOINTS DIRECTORY & COMPLETE JSON SCHEMASA. List Supported Courts (GET /v1/courts)Indian Judicial system ke high courts (jaise Allahabad, Bombay, Jammu & Kashmir) aur subordinate district courts ke identifiers retrieve karne ke liye.  Request Headers:  HTTPGET /v1/courts?limit=10&order=asc HTTP/1.1
Host: api.kanoon.dev
Authorization: Bearer sk_live_pratidnya_kanoon_dev_key
Accept: application/json
Query Parameters:limit (optional, integer): Defaults to 20, maximum 100.after (optional, string): Cursor pagination identifier.before (optional, string): Cursor for backward navigation.order (optional, string): asc or desc.Response JSON Specification:  JSON{
  "object": "list",
  "data": [
    {
      "id": "APHC01",
      "object": "court",
      "name": "High Court of Judicature at Allahabad",
      "jurisdiction": "State of Uttar Pradesh",
      "court_level": "HIGH_COURT",
      "district_coverage": ["Lucknow", "Prayagraj", "Varanasi", "Kanpur Nagar"],
      "bench_locations": ["Allahabad (Principal)", "Lucknow (Bench)"]
    },
    {
      "id": "HCBM01",
      "object": "court",
      "name": "High Court of Judicature at Bombay",
      "jurisdiction": "State of Maharashtra & Goa",
      "court_level": "HIGH_COURT",
      "district_coverage": ["Mumbai", "Nagpur", "Aurangabad", "Panaji"],
      "bench_locations": ["Mumbai (Principal)", "Nagpur", "Aurangabad", "Goa"]
    },
    {
      "id": "JKHC01",
      "object": "court",
      "name": "High Court of Jammu & Kashmir and Ladakh",
      "jurisdiction": "UT of Jammu & Kashmir and Ladakh",
      "court_level": "HIGH_COURT",
      "district_coverage": ["Srinagar", "Jammu"],
      "bench_locations": ["Srinagar", "Jammu"]
    },
    {
      "id": "UPDC01_LKO",
      "object": "court",
      "name": "District & Sessions Court, Lucknow",
      "jurisdiction": "District Level Subordinate",
      "court_level": "DISTRICT_COURT",
      "district_coverage": ["Lucknow"],
      "bench_locations": ["Lucknow District Court Complex"]
    }
  ],
  "has_more": false,
  "next_cursor": null
}
B. List Court Cases (GET /v1/courts/{court_id}/cases)District/High court level par specific criminal cases filter karne ke liye.  Path Parameter:court_id: e.g., APHC01 or UPDC01_LKO.  Query Parameters:year (optional, integer): Case filing year (e.g., 2026).case_type (optional, string): e.g., BAIL_APPLICATION, CRIMINAL_MISC, REVISION.q (optional, string): Search query by FIR, Police Station, or Accused name.limit (optional, integer): Max records per page.Response JSON Specification:  JSON{
  "object": "list",
  "data": [
    {
      "id": "case_982341",
      "object": "case",
      "court_id": "APHC01",
      "case_number": "Criminal Misc. Bail Application No. 10244 of 2026",
      "cnr_number": "UPHC010102442026",
      "filing_date": "2026-02-10",
      "registration_date": "2026-02-12",
      "status": "DISPOSED",
      "petitioner": "श्यामू उर्फ़ श्याम",
      "respondent": "उत्तर प्रदेश राज्य",
      "petitioner_counsel": "श्री आर.के. त्रिपाठी, अधिवक्ता",
      "respondent_counsel": "अपर शासकीय अधिवक्ता (A.G.A.)",
      "police_station": "कोतवाली नगर, लखनऊ",
      "fir_number": "124/2026",
      "under_sections": [
        "धारा 379 भा.दं.वि. (समतुल्य 303 बी.एन.एस.)",
        "धारा 411 भा.दं.वि. (समतुल्य 317(2) बी.एन.एस.)"
      ],
      "presiding_judge": "मा० न्यायमूर्ति वी.के. शर्मा"
    }
  ],
  "has_more": false,
  "next_cursor": null
}
C. Case Events & Hearing History (GET /v1/courts/{court_id}/cases/{case_id}/events)Cause-list history, listing dates, aur judicial orders pass hone ka sequence track karne ke liye.  Path Parameters:court_id: APHC01  case_id: case_982341  Response JSON Specification:  JSON{
  "object": "list",
  "case_id": "case_982341",
  "data": [
    {
      "id": "evt_001",
      "object": "case_event",
      "event_date": "2026-02-15",
      "purpose_of_hearing": "प्रथम सुनवाई एवं राज्य से आख्या तलब",
      "court_room_number": "कोर्ट संख्या 14",
      "bench_description": "एकल पीठ (Single Bench)",
      "coram": "मा० न्यायमूर्ति वी.के. शर्मा",
      "business_recorded": "विद्वान अधिवक्ता आवेदक एवं विद्वान ए.जी.ए. को सुना गया। राज्य को केस डायरी प्रस्तुत करने हेतु समय प्रदान किया जाता है।",
      "order_passed": false,
      "next_hearing_date": "2026-02-28"
    },
    {
      "id": "evt_002",
      "object": "case_event",
      "event_date": "2026-02-28",
      "purpose_of_hearing": "जमानत प्रार्थना पत्र पर अंतिम बहस",
      "court_room_number": "कोर्ट संख्या 14",
      "bench_description": "एकल पीठ (Single Bench)",
      "coram": "मा० न्यायमूर्ति वी.के. शर्मा",
      "business_recorded": "उभय पक्षों की बहस सुनी गई। केस डायरी का अवलोकन किया गया। निर्णय सुरक्षित/आदेश पारित।",
      "order_passed": true,
      "next_hearing_date": null
    }
  ]
}
D. Case Insights Engine (GET /v1/courts/{court_id}/cases/{case_id}/insights)Case ka AI structured summary, judicial outcome, aur statistical metrics:  Path Parameters:court_id: APHC01  case_id: case_982341  Response JSON Specification:  JSON{
  "object": "case_insights",
  "case_id": "case_982341",
  "outcome_category": "ALLOWED",
  "bail_granted": true,
  "disposal_duration_days": 18,
  "key_findings": [
    "कथित बरामदगी के समय दंड प्रक्रिया संहिता की धारा 100(4) के अंतर्गत कोई स्वतंत्र साक्षी उपस्थित नहीं था।",
    "अभियुक्त का कोई पूर्व आपराधिक इतिहास नहीं है।",
    "विचारण शीघ्र समाप्त होने की संभावना नहीं है।"
  ],
  "favorable_precedents_cited": [
    "अर्नेश कुमार बनाम बिहार राज्य (2014)",
    "संजय चंद्रा बनाम सी.बी.आई. (2012)"
  ],
  "statutory_provisions_analyzed": [
    "धारा 411 भा.दं.वि.",
    "धारा 439 दंड प्रक्रिया संहिता"
  ]
}
E. Case Orders & Downloadable Judgments (GET /v1/courts/{court_id}/cases/{case_id}/orders)Rule 1 compliance ke liye verified original court judgment PDF URL aur text snippet nikalna:  Path Parameters:court_id: APHC01  case_id: case_982341  Response JSON Specification:  JSON{
  "object": "list",
  "case_id": "case_982341",
  "data": [
    {
      "id": "ord_774910",
      "object": "case_order",
      "order_date": "2026-02-28",
      "order_type": "FINAL_DISPOSAL_ORDER",
      "judge_names": ["मा० न्यायमूर्ति वी.के. शर्मा"],
      "pdf_download_url": "https://api.kanoon.dev/v1/download/orders/APHC01_ord_774910.pdf",
      "pdf_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "order_text_snippet": "आवेदक श्यामू की ओर से प्रस्तुत यह प्रथम जमानत प्रार्थना पत्र स्वीकार किया जाता है। आवेदक को संबंधित न्यायालय की संतुष्टि पर व्यक्तिगत बंधपत्र एवं समान धनराशि के दो प्रतिभू प्रस्तुत करने पर रिहा किया जाए।"
    }
  ]
}
4. RATE LIMITS, PRICING & LOCAL MOCK SPECIFICATIONCommercial Status: ⚠️ VERIFY BEFORE USE (kanoon.dev active developer beta mein operate kar raha hai; custom quotas enterprise contract ke adhar par assign hote hain).  Rate Limits: Beta endpoints dynamic rate-limiting (approx 60 requests/minute) follow karte hain.  Zero-Credit Testing Policy: Development phase ke dauran API credits preserve karne ke liye jab tak MOCK_KANOON_API=True ho, Antigravity ko niche diya gaya mock fixture use karna hai:Python# app/tests/fixtures/kanoon_mock_fixtures.py

MOCK_COURTS_DATA = {
    "object": "list",
    "data": [
        {
            "id": "APHC01",
            "object": "court",
            "name": "High Court of Judicature at Allahabad",
            "jurisdiction": "State of Uttar Pradesh",
            "court_level": "HIGH_COURT",
            "district_coverage": ["Lucknow", "Prayagraj"],
            "bench_locations": ["Allahabad", "Lucknow"]
        }
    ],
    "has_more": False
}

MOCK_CASE_SEARCH_DATA = {
    "object": "list",
    "data": [
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
    ],
    "has_more": False
}

MOCK_CASE_ORDERS_DATA = {
    "object": "list",
    "case_id": "mock_case_411",
    "data": [
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
}
5. BACKEND PYTHON IMPLEMENTATION (kanoon_service.py)FastAPI backend service jo caching, API authorization, retry logic aur mock fixtures execute karti hai:  Python# app/services/kanoon_service.py
import json
import httpx
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException
from app.core.config import settings
from app.core.supabase_client import get_supabase_admin_client
from app.tests.fixtures.kanoon_mock_fixtures import (
    MOCK_COURTS_DATA,
    MOCK_CASE_SEARCH_DATA,
    MOCK_CASE_ORDERS_DATA
)

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
            return MOCK_COURTS_DATA["data"]

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

    async def search_cases(
        self,
        court_id: str,
        query: str,
        year: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        if self.use_mock:
            return MOCK_CASE_SEARCH_DATA["data"]

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

    async def get_case_orders(
        self,
        court_id: str,
        case_id: str
    ) -> List[Dict[str, Any]]:
        if self.use_mock:
            return MOCK_CASE_ORDERS_DATA["data"]

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
6. FLUTTER INTEGRATION & DOMAIN SPECIFICATIONA. Domain Models (KanoonCaseRecord & VerifiedCaseOrder)Dart// lib/src/features/03_precedent_search/domain/kanoon_case_record.dart
class KanoonCaseRecord {
  final String id;
  final String courtId;
  final String caseNumber;
  final String cnrNumber;
  final String filingDate;
  final String status;
  final String petitioner;
  final String respondent;
  final String policeStation;
  final String firNumber;
  final List<String> underSections;
  final String? presidingJudge;

  KanoonCaseRecord({
    required this.id,
    required this.courtId,
    required this.caseNumber,
    required this.cnrNumber,
    required this.filingDate,
    required this.status,
    required this.petitioner,
    required this.respondent,
    required this.policeStation,
    required this.firNumber,
    required this.underSections,
    this.presidingJudge,
  });

  factory KanoonCaseRecord.fromJson(Map<String, dynamic> json) {
    return KanoonCaseRecord(
      id: json['id'] as String,
      courtId: json['court_id'] as String,
      caseNumber: json['case_number'] as String,
      cnrNumber: json['cnr_number'] as String? ?? '',
      filingDate: json['filing_date'] as String,
      status: json['status'] as String,
      petitioner: json['petitioner'] as String,
      respondent: json['respondent'] as String,
      policeStation: json['police_station'] as String? ?? '',
      firNumber: json['fir_number'] as String? ?? '',
      underSections: List<String>.from(json['under_sections'] ?? []),
      presidingJudge: json['presiding_judge'] as String?,
    );
  }
}
Dart// lib/src/features/03_precedent_search/domain/verified_case_order.dart
class VerifiedCaseOrder {
  final String id;
  final String orderDate;
  final String orderType;
  final String pdfDownloadUrl;
  final String? pdfSha256;
  final String orderTextSnippet;

  VerifiedCaseOrder({
    required this.id,
    required this.orderDate,
    required this.orderType,
    required this.pdfDownloadUrl,
    this.pdfSha256,
    required this.orderTextSnippet,
  });

  factory VerifiedCaseOrder.fromJson(Map<String, dynamic> json) {
    return VerifiedCaseOrder(
      id: json['id'] as String,
      orderDate: json['order_date'] as String,
      orderType: json['order_type'] as String,
      pdfDownloadUrl: json['pdf_download_url'] as String,
      pdfSha256: json['pdf_sha256'] as String?,
      orderTextSnippet: json['order_text_snippet'] as String? ?? '',
    );
  }
}
B. Flutter Data Repository (KanoonRepository)Dart// lib/src/features/03_precedent_search/data/kanoon_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/kanoon_case_record.dart';
import '../domain/verified_case_order.dart';

final kanoonRepositoryProvider = Provider<KanoonRepository>((ref) {
  return KanoonRepository();
});

class KanoonRepository {
  Future<List<KanoonCaseRecord>> searchCourtCases({
    required String courtId,
    required String searchQuery,
    int? year,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final uri = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/kanoon/search-cases').replace(
      queryParameters: {
        'court_id': courtId,
        'query': searchQuery,
        if (year != null) 'year': year.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((item) => KanoonCaseRecord.fromJson(item)).toList();
    } else {
      throw Exception('केस रिकॉर्ड खोज विफल (${response.statusCode}):${response.body}');
    }
  }

  Future<List<VerifiedCaseOrder>> fetchCaseOrders({
    required String courtId,
    required String caseId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final uri = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/kanoon/cases/$caseId/orders').replace(
      queryParameters: {'court_id': courtId},
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((item) => VerifiedCaseOrder.fromJson(item)).toList();
    } else {
      throw Exception('न्यायालयीन आदेश लोड विफल (${response.statusCode}):${response.body}');
    }
  }
}
7. MONETIZATION, QUOTA & AD-GATING HOOKSKanoon.dev API queries server bandwidth aur subscription credits consume karti hain. Isliye monetization lifecycle ko enforce karna zaroori hai:  Free Advocates: Din mein 5 Kanoon Queries allowed. Quota khatam hone par advocate Rewarded Ad dekh kar +2 additional verified case lookups unlock kar sakta hai.Pro Chamber Subscribers: Unlimited searches with direct High Court and District Court order PDF streaming without ads.Dart// lib/src/features/03_precedent_search/presentation/controllers/kanoon_quota_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> checkAndEnforceKanoonQuota(BuildContext context, WidgetRef ref) async {
  final isProUser = ref.read(isProSubscriberProvider);
  if (isProUser) return true;

  final remainingQuota = await ref.read(dailyKanoonQuotaProvider.future);
  if (remainingQuota > 0) return true;

  // Show Monetization Gate Dialog
  final bool? watchAd = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('दैनिक खोज कोटा समाप्त'),
      content: const Text(
        'आज के लिए आपके 5 निःशुल्क kanoon.dev केस खोज समाप्त हो चुके हैं। '
        'एक छोटा विज्ञापन देखकर 2 अतिरिक्त खोज अनलॉक करें या प्रो चैंबर में अपग्रेड करें।',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('रद्द करें'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_circle_fill),
          label: const Text('विज्ञापन देखें (+2 खोज)'),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );

  if (watchAd == true) {
    final adSuccess = await ref.read(adMobServiceProvider).showRewardedKanoonSearchAd();
    return adSuccess;
  }
  return false;
}
8. ANTIGRAVITY NON-NEGOTIABLE VERIFICATION CHECKLIST (DOC-06)Antigravity code likhte waqt in exact technical assertions ko verify karega:[ ] Direct kanoon.dev API key Flutter codebase ya .env assets mein commit nahi hogi.  [ ] All kanoon.dev endpoints must route through the FastAPI microservice proxy with verified Firebase JWT tokens.  [ ] In-memory/Supabase cache layer (kanoon_api_cache) must be checked before making outbound network calls to kanoon.dev to avoid credit depletion.[ ] If MOCK_KANOON_API == True, the microservice must return deterministic mock fixtures without failing network requests.[ ] Every retrieved precedent displayed in the UI must feature a valid pdf_download_url or verified court order identifier (Rule 1: No Hallucinated Citations).  [ ] Precedent lookup failure must trigger the PrecedentAbstainWidget (Rule 3: Not Found = Abstain) instead of making generative guesses.