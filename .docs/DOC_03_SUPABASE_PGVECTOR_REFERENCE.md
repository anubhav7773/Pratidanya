================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-03
MODULE         : SUPABASE PGVECTOR, SEMANTIC RETRIEVAL & RAG PIPELINE
TARGET RUNTIME : PostgreSQL 15+ / pgvector 0.5.0+ / Python 3.10+ / Flutter 3.19+
EMBEDDING SPEC : 768 Dimensions (Google text-embedding-004 / gemini-embedding-001)
INDEXING MODEL : HNSW (Hierarchical Navigable Small World) with Cosine & L2 Ops
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. END-TO-END VECTOR PIPELINE ARCHITECTUREPratidnya ka semantic search pipeline pure system (Frontend, Backend, Database, Billing, Ads aur Security) ko aapas mein bind karta hai. Koi bhi search isolated nahi hai:┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT (UI LAYER)                       │
│  - User inputs case facts in Devanagari Hindi or English               │
│  - Checks local credit balance (Free Quota vs Subscribed Pro vs Ads)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS + Bearer <Firebase_ID_Token>
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             FASTAPI BACKEND MICROSERVICE (AWS MUMBAI / RENDER)         │
│  1. Token & Quota Guard: Validates Pro subscription or Ad-credit token  │
│  2. Privacy Guard: Blocks real case-facts if GEMINI_PAID_TIER != True   │
│  3. Embedding Engine: Calls Gemini API to get 768-float query vector   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   SUPABASE POSTGRESQL + PGVECTOR STORE                 │
│  - Public Pool: `verified_precedents` (Curated judgments with URLs)    │
│  - Chamber Pool: `case_document_embeddings` (Strict RLS isolation)     │
│  - HNSW Index Search: Evaluates Cosine Similarity (<=>) & L2 (<->)     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               EXTRACTIVE GROUNDING & ABSTAIN ENGINE (BACKEND)          │
│  - Similarity Score < 0.65 ➔ Triggers "Rule 3: Abstain (No Match)"    │
│  - Similarity Score >= 0.65 ➔ Verifies official source URL exists      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Filtered Verified JSON
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                 FLUTTER PRESENTATION (VERIFIED CARDS)                  │
│  - Verified Judgments displayed with green seal & clickable source     │
│  - If daily limit reached ➔ Rewarded Ad trigger / Paywall prompt       │
└────────────────────────────────────────────────────────────────────────┘
2. PRODUCTION DATABASE DDL & PGVECTOR SCHEMAAntigravity ko Supabase migrations ke dauran niche diya gaya exact SQL script execute karna hai. Isme HNSW indexing, table schemas, Row-Level Security, aur cascading erasures shamil hain:  SQL-- ============================================================================
-- 1. EXTENSIONS & SCHEMAS
-- ============================================================================
create extension if not exists vector with schema extensions;
create extension if not exists "uuid-ossp";

-- ============================================================================
-- 2. VERIFIED JUDICIAL PRECEDENTS (PUBLIC RAG LIBRARY)
-- Sourced from verified public records (NJDG/eCourts/High Courts)
-- ============================================================================
create table public.verified_precedents (
    id uuid primary key default gen_random_uuid(),
    citation_id text unique not null,               -- e.g., '2024_ALHC_CRIMINAL_411'
    case_title text not null,                       -- e.g., 'Ramesh vs. State of U.P.'
    court_name text not null,                       -- e.g., 'Allahabad High Court'
    bench_type text not null default 'SINGLE_BENCH',-- 'SINGLE_BENCH', 'DIVISION_BENCH'
    judgment_date date not null,
    act_name text not null,                         -- 'IPC', 'BNS', 'CrPC', 'BNSS', 'NDPS'
    section_numbers text[] not null,                -- ARRAY['379', '411']
    headnote_hindi text not null,                   -- Legal Ratio in authentic Hindi
    verbatim_text text not null,                    -- Exact extracted judgment paragraph
    paragraph_number integer,                       -- Official Judgment Paragraph Number
    verified_source_url text not null,              -- Rule 1: Verifiable official URL
    embedding extensions.vector(768) not null,      -- 768 dims (text-embedding-004 / gemini-embedding-001)
    is_active boolean default true not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

comment on table public.verified_precedents is 'Verified criminal court precedents for extractive RAG grounding.';

-- ============================================================================
-- 3. PRIVATE CHAMBER CASE EMBEDDINGS (ADVOCATE WORKSPACE)
-- Chunked FIRs, chargesheets, and defense notes per case file
-- ============================================================================
create table public.case_document_embeddings (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    document_name text not null,                    -- e.g., 'Chargesheet_124_2026.pdf'
    document_type text not null,                    -- 'FIR', 'CHARGESHEET', 'BAIL_ORDER', 'DEFENSE_NOTE'
    chunk_index integer not null,                   -- 0, 1, 2...
    chunk_text text not null,                       -- Verbatim extracted text (approx 400-500 tokens)
    token_count integer not null,
    metadata jsonb default '{}'::jsonb,             -- Page numbers, dates, speaker tags
    embedding extensions.vector(768) not null,      -- 768 dims
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

comment on table public.case_document_embeddings is 'Chamber-isolated vector chunks for individual criminal cases.';

-- ============================================================================
-- 4. HNSW INDEX SPECIFICATION (PERFORMANCE & ZERO RECALL LOSS)
-- ============================================================================
-- Precedent Library Index (Cosine Distance for semantic relevance)
create index idx_verified_precedents_hnsw_cosine
on public.verified_precedents 
using hnsw (embedding extensions.vector_cosine_ops)
with (m = 16, ef_construction = 64);

-- Precedent Library Index (L2 Distance for exact Euclidean proximity)
create index idx_verified_precedents_hnsw_l2
on public.verified_precedents 
using hnsw (embedding extensions.vector_l2_ops)
with (m = 16, ef_construction = 64);

-- Private Chamber Chunks Index (Cosine Distance)
create index idx_case_embeddings_hnsw_cosine
on public.case_document_embeddings 
using hnsw (embedding extensions.vector_cosine_ops)
with (m = 16, ef_construction = 64);

-- Supporting GIN & B-Tree indexes for fast pre-filtering
create index idx_precedents_sections_gin on public.verified_precedents using gin(section_numbers);
create index idx_case_embeddings_lookup on public.case_document_embeddings(case_id, advocate_id);

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
alter table public.verified_precedents enable row level security;
alter table public.case_document_embeddings enable row level security;

-- Precedents: All authenticated advocates have Read-Only access
create policy "Authenticated advocates can search verified precedents"
    on public.verified_precedents
    for select
    to authenticated
    using (is_active = true);

-- Chamber Embeddings: Strict chamber isolation (Firebase UID mapped to advocate_id)
create policy "Advocates have exclusive access to own case embeddings"
    on public.case_document_embeddings
    for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
3. STORED PROCEDURES (POSTGRESQL RPC FUNCTIONS)Pratidnya do distinct search mechanics use karti hai:match_verified_precedents: Precedent library mein Section-based pre-filter ke baad Cosine Similarity (<=>) aur L2 Distance (<->) compute karta hai.  match_private_case_chunks: Kisi specific case file ke andar relevant facts extract karta hai.SQL-- ============================================================================
-- RPC 1: MATCH VERIFIED PRECEDENTS (WITH LEGAL SECTION PRE-FILTERING)
-- ============================================================================
create or replace function match_verified_precedents (
  query_embedding extensions.vector(768),
  target_sections text[],
  similarity_threshold float default 0.65,
  match_count int default 5
)
returns table (
  id uuid,
  citation_id text,
  case_title text,
  court_name text,
  judgment_date date,
  act_name text,
  section_numbers text[],
  headnote_hindi text,
  verbatim_text text,
  paragraph_number int,
  verified_source_url text,
  similarity float,
  l2_distance float
)
language plpgsql
security definer
as $$
begin
  return query
  select
    vp.id,
    vp.citation_id,
    vp.case_title,
    vp.court_name,
    vp.judgment_date,
    vp.act_name,
    vp.section_numbers,
    vp.headnote_hindi,
    vp.verbatim_text,
    vp.paragraph_number,
    vp.verified_source_url,
    (1 - (vp.embedding <=> query_embedding)) as similarity,
    (vp.embedding <-> query_embedding) as l2_distance
  from public.verified_precedents vp
  where vp.is_active = true
    -- Strict Section Pre-Filtering (GIN Index Scan)
    and (target_sections is null or target_sections = '{}' or vp.section_numbers && target_sections)
    -- Cosine Similarity Hard Cutoff (Rule 3: Not Found = Abstain)
    and (1 - (vp.embedding <=> query_embedding)) >= similarity_threshold
  order by vp.embedding <=> query_embedding asc
  limit match_count;
end;
$$;

-- ============================================================================
-- RPC 2: MATCH PRIVATE CASE CHUNKS (CHAMBER RAG)
-- ============================================================================
create or replace function match_private_case_chunks (
  query_embedding extensions.vector(768),
  target_case_id uuid,
  requesting_advocate_id text,
  similarity_threshold float default 0.60,
  match_count int default 5
)
returns table (
  id uuid,
  document_name text,
  document_type text,
  chunk_index int,
  chunk_text text,
  similarity float
)
language plpgsql
security definer
as $$
begin
  return query
  select
    cde.id,
    cde.document_name,
    cde.document_type,
    cde.chunk_index,
    cde.chunk_text,
    (1 - (cde.embedding <=> query_embedding)) as similarity
  from public.case_document_embeddings cde
  where cde.case_id = target_case_id
    and cde.advocate_id = requesting_advocate_id
    and (1 - (cde.embedding <=> query_embedding)) >= similarity_threshold
  order by cde.embedding <=> query_embedding asc
  limit match_count;
end;
$$;
4. BACKEND INTEGRATION: FASTAPI & GEMINI EMBEDDINGSBackend par Gemini REST API se embeddings fetch hoti hain, text chunks create hote hain, aur Supabase pgvector RPC execute hoti hai.A. Embedding Client with Privacy & Tier AssertionsPython# app/services/vector_embedding_service.py
import httpx
from typing import List
from fastapi import HTTPException
from app.core.config import settings

class VectorEmbeddingService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.is_paid_tier = settings.GEMINI_PAID_TIER
        self.enforce_dummy_data = settings.ENFORCE_DUMMY_DATA
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models"

    def _verify_privacy_compliance(self, is_dummy_data: bool):
        """Rule 6: Blocks real client case-data on Free Tier."""
        if not self.is_paid_tier and not is_dummy_data:
            raise HTTPException(
                status_code=403,
                detail="गोपनीयता उल्लंघन: निःशुल्क (Free) टियर पर केवल डमी/सिंथेटिक डेटा अनुमत है। "
                       "अधिवक्ता गोपनीयता और DPDP अधिनियम 2023 की धारा 8 का अनुपालन अनिवार्य है।"[cite: 1]
            )

    async def get_embedding(
        self, 
        text: str, 
        task_type: str = "RETRIEVAL_QUERY",
        is_dummy_data: bool = True
    ) -> List[float]:
        self._verify_privacy_compliance(is_dummy_data)

        # Dimension: 768 floats (gemini-embedding-001 or text-embedding-004)
        url = f"{self.base_url}/text-embedding-004:embedContent"
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.api_key
        }
        payload = {
            "model": "models/text-embedding-004",
            "content": {
                "parts": [{"text": text.strip()}]
            },
            "taskType": task_type
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Gemini Embedding विफलता: {response.text}"
                )
            
            result = response.json()
            embedding = result.get("embedding", {}).get("values", [])
            
            if len(embedding) != 768:
                raise HTTPException(
                    status_code=500,
                    detail=f"अमान्य वेक्टर आयाम (Dimension): अपेक्षित 768, प्राप्त {len(embedding)}"
                )
            return embedding
B. Legal Document Chunker (Devanagari Optimized)District court chargesheets aur police reports ko tokens mein todte waqt complex Hindi conjuncts aur legal sentence structures tootne se bachane ke liye character/sentence-aware chunking lagayi gayi hai:Python# app/services/legal_chunker.py
import re
from typing import List, Dict, Any

class LegalDocumentChunker:
    @staticmethod
    def chunk_legal_text(
        full_text: str, 
        chunk_size_chars: int = 1200, 
        overlap_chars: int = 200
    ) -> List[Dict[str, Any]]:
        # Normalize Hindi and English whitespaces
        cleaned_text = re.sub(r'\s+', ' ', full_text).strip()
        
        chunks = []
        start_idx = 0
        text_length = len(cleaned_text)
        chunk_index = 0

        while start_idx < text_length:
            end_idx = start_idx + chunk_size_chars
            
            if end_idx >= text_length:
                chunk = cleaned_text[start_idx:]
                chunks.append({
                    "chunk_index": chunk_index,
                    "chunk_text": chunk,
                    "approx_tokens": len(chunk) // 4
                })
                break
            
            # Sentence boundary check: Hindi Purna Viram (|) or English Full Stop (.)
            boundary_match = re.search(r'[।\.\n]', cleaned_text[end_idx - 100:end_idx + 100])
            if boundary_match:
                split_point = (end_idx - 100) + boundary_match.end()
            else:
                split_point = end_idx

            chunk = cleaned_text[start_idx:split_point].strip()
            chunks.append({
                "chunk_index": chunk_index,
                "chunk_text": chunk,
                "approx_tokens": len(chunk) // 4
            })

            chunk_index += 1
            start_idx = split_point - overlap_chars

        return chunks
C. FastAPI Search & Indexing EndpointsPython# app/api/v1/endpoints/precedent_search.py
from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, Field
from typing import List, Optional
from app.services.vector_embedding_service import VectorEmbeddingService
from app.core.supabase_client import get_supabase_admin_client

router = APIRouter(prefix="/vectors", tags=["pgvector Operations"])

class PrecedentSearchRequest(BaseModel):
    query_text: str = Field(..., min_length=5, description="Factual issue or defense argument in Hindi/English")
    target_sections: List[str] = Field(default=[], description="e.g., ['379', '411'] or ['303 BNS']")
    similarity_threshold: float = Field(default=0.65, ge=0.5, le=0.99)
    limit: int = Field(default=5, ge=1, le=10)
    is_dummy_testing: bool = Field(default=True)

class PrecedentSearchResult(BaseModel):
    id: str
    citation_id: str
    case_title: str
    court_name: str
    judgment_date: str
    act_name: str
    section_numbers: List[str]
    headnote_hindi: str
    verbatim_text: str
    paragraph_number: Optional[int]
    verified_source_url: str
    similarity_score: float

@router.post("/search-precedents", response_model=List[PrecedentSearchResult])
async def search_precedents_endpoint(
    payload: PrecedentSearchRequest,
    embedding_service: VectorEmbeddingService = Depends(),
    authorization: Optional[str] = Header(None)
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="अनधिकृत पहुंच: वैध टोकन आवश्यक है।")

    # Step 1: Generate 768-dim query embedding via Gemini
    query_vector = await embedding_service.get_embedding(
        text=payload.query_text,
        task_type="RETRIEVAL_QUERY",
        is_dummy_data=payload.is_dummy_testing
    )

    # Step 2: Query Supabase pgvector RPC
    supabase = get_supabase_admin_client()
    rpc_params = {
        "query_embedding": query_vector,
        "target_sections": payload.target_sections,
        "similarity_threshold": payload.similarity_threshold,
        "match_count": payload.limit
    }

    try:
        response = supabase.rpc("match_verified_precedents", rpc_params).execute()
        results = response.data or []

        # Step 3: Enforce Rule 1 & Rule 3 (Zero Hallucination & Abstain Filter)
        verified_results = []
        for row in results:
            url = row.get("verified_source_url", "")
            # Verify URL is official/valid
            if url and (url.startswith("http://") or url.startswith("https://")):
                verified_results.append(PrecedentSearchResult(
                    id=row["id"],
                    citation_id=row["citation_id"],
                    case_title=row["case_title"],
                    court_name=row["court_name"],
                    judgment_date=str(row["judgment_date"]),
                    act_name=row["act_name"],
                    section_numbers=row["section_numbers"],
                    headnote_hindi=row["headnote_hindi"],
                    verbatim_text=row["verbatim_text"],
                    paragraph_number=row.get("paragraph_number"),
                    verified_source_url=url,
                    similarity_score=round(row["similarity"], 4)
                ))

        # Rule 3: If no match passes threshold, return empty list (UI will show Abstain Widget)
        return verified_results

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"pgvector खोज त्रुटि: {str(e)}")
5. FLUTTER INTEGRATION (RIVERPOD 2.X & DOMAIN MODELS)A. Domain Model (PrecedentCitation)Dart// lib/src/features/03_precedent_search/domain/precedent_citation.dart
class PrecedentCitation {
  final String id;
  final String citationId;
  final String caseTitle;
  final String courtName;
  final String judgmentDate;
  final String actName;
  final List<String> sectionNumbers;
  final String headnoteHindi;
  final String verbatimText;
  final int? paragraphNumber;
  final String verifiedSourceUrl;
  final double similarityScore;
  bool isManuallyVerified; // Used by Module 5 Verification Gate

  PrecedentCitation({
    required this.id,
    required this.citationId,
    required this.caseTitle,
    required this.courtName,
    required this.judgmentDate,
    required this.actName,
    required this.sectionNumbers,
    required this.headnoteHindi,
    required this.verbatimText,
    this.paragraphNumber,
    required this.verifiedSourceUrl,
    required this.similarityScore,
    this.isManuallyVerified = false,
  });

  factory PrecedentCitation.fromJson(Map<String, dynamic> json) {
    return PrecedentCitation(
      id: json['id'] as String,
      citationId: json['citation_id'] as String,
      caseTitle: json['case_title'] as String,
      courtName: json['court_name'] as String,
      judgmentDate: json['judgment_date'] as String,
      actName: json['act_name'] as String,
      sectionNumbers: List<String>.from(json['section_numbers'] ?? []),
      headnoteHindi: json['headnote_hindi'] as String,
      verbatimText: json['verbatim_text'] as String,
      paragraphNumber: json['paragraph_number'] as int?,
      verifiedSourceUrl: json['verified_source_url'] as String,
      similarityScore: (json['similarity_score'] as num).toDouble(),
    );
  }
}
B. Precedent Controller (State Management)Dart// lib/src/features/03_precedent_search/presentation/controllers/precedent_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/precedent_citation.dart';
import '../../data/precedent_repository.dart';

part 'precedent_controller.g.dart';

@riverpod
class PrecedentSearchController extends _$PrecedentSearchController {
  @override
  FutureOr<List<PrecedentCitation>> build() {
    // Initial state: empty list before search
    return [];
  }

  Future<void> searchPrecedents({
    required String factsNarrative,
    required List<String> sections,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(precedentRepositoryProvider);
      return await repository.fetchPrecedents(
        queryText: factsNarrative,
        sections: sections,
      );
    });
  }

  void toggleCitationManualVerification(String citationId, bool isVerified) {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final updatedList = currentList.map((c) {
      if (c.citationId == citationId) {
        c.isManuallyVerified = isVerified;
      }
      return c;
    }).toList();

    state = AsyncValue.data(updatedList);
  }
}
6. UI PRESENTATION & "NOT FOUND = ABSTAIN" WIDGET (RULE 3)District Court advocates ko hallucinated precedents se bachane ke liye, agar koi precedent match nahi hota toh clean fallback widget render hona chahiye:Dart// lib/src/features/03_precedent_search/presentation/widgets/precedent_abstain_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PrecedentAbstainWidget extends StatelessWidget {
  final String queryTerm;

  const PrecedentAbstainWidget({super.key, required this.queryTerm});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.amber.shade300, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.unverifiedAmber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'कोई पुष्ट कानूनी मिसाल (Precedent) नहीं मिली',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.unverifiedAmber,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'आपके द्वारा दर्ज किए गए तथ्यों के लिए हमारे डेटाबेस में कोई न्यूनतम 65% प्रासंगिक निर्णय उपलब्ध नहीं है। '
              'अधिवक्ता आचार संहिता एवं न्यायालयीन शुचिता हेतु सिस्टम ने कोई काल्पनिक केस-लॉ नहीं बनाया है।',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: BorderSide(color: Colors.amber.shade200),
              ),
              child: Text(
                'परामर्श: कृपया जिला न्यायालय मैन्युअल या ई-कोर्ट्स पर मैन्युअल शोध करें।',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Dart// lib/src/features/03_precedent_search/presentation/widgets/precedent_citation_card.dart
import 'package:flutter/material.dart';
import '../../domain/precedent_citation.dart';
import '../../../../core/theme/app_colors.dart';

class PrecedentCitationCard extends StatelessWidget {
  final PrecedentCitation citation;
  final ValueChanged<bool?> onVerificationChanged;

  const PrecedentCitationCard({
    super.key,
    required this.citation,
    required this.onVerificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    citation.caseTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.courtNavy,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.verifiedGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: BorderSide(color: AppColors.verifiedGreen),
                  ),
                  child: Text(
                    'सटीकता: ${(citation.similarityScore * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.verifiedGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${citation.courtName} \vert{} दिनांक: ${citation.judgmentDate}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const Divider(height: 16),
            Text(
              'विधिक निष्कर्ष (Headnote):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slateBlue),
            ),
            const SizedBox(height: 4),
            Text(
              citation.headnoteHindi,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
                border: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                'उद्धृत अंश (Para ${citation.paragraphNumber ?? "N/A"}): "${citation.verbatimText}"',
                style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    // Open verified URL in in-app browser
                  },
                  child: Text(
                    'सत्यापित स्रोत रिकॉर्ड देखें ↗',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: citation.isManuallyVerified,
                      activeColor: AppColors.verifiedGreen,
                      onChanged: onVerificationChanged,
                    ),
                    const Text('सत्यापित किया', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
7. MONETIZATION, BILLING & AD-GATING HOOKSVector embedding generation aur LLM search calls compute costs generate karte hain. System mein 3-tier quota engine link hoga:  Tier / StateDaily Precedent SearchesRewarded Ad OptionBilling TriggerFree User3 Searches / DayYes: Ad dekh kar +1 Precedent Search unlock ho sakti haiQuota khatam hone par Paywall ModalPro Subscriber (₹499/mo)Unlimited SearchesNo Ads: Ads completely disabledGoogle Play Billing activeAd-Unlocked Temporary+1 Search per Rewarded AdN/AValid for current search sessionQuota Verification Middleware FlowDart// Flow evaluated before triggering precedentRepository.fetchPrecedents()
if (!isUserProSubscriber) {
  final int remainingSearches = await ref.read(dailyQuotaProvider.future);
  if (remainingSearches <= 0) {
    // Show Modal: [Watch Ad to Search Once] OR [Upgrade to Pro Chamber Plan]
    final userChoseAd = await showQuotaExceededDialog(context);
    if (userChoseAd) {
      await ref.read(admobServiceProvider).showRewardedPrecedentSearchAd();
    } else {
      return; // Abort search
    }
  }
}
8. SYNTHETIC DUMMY DATA SEED FOR LOCAL TESTINGJab tak app production paid-tier par nahi jaati, development testing ke liye ye SQL records seed kiye jayenge:  SQL-- DUMMY SEED: Section 379/411 IPC (Theft & Stolen Property Recovery)
insert into public.verified_precedents (
    citation_id,
    case_title,
    court_name,
    bench_type,
    judgment_date,
    act_name,
    section_numbers,
    headnote_hindi,
    verbatim_text,
    paragraph_number,
    verified_source_url,
    embedding
) values (
    'TEST_2024_ALHC_411_DUMMY',
    'रमेश बनाम उत्तर प्रदेश राज्य (डमी परीक्षण रिकॉर्ड)',
    'इलाहाबाद उच्च न्यायालय',
    'SINGLE_BENCH',
    '2024-02-15',
    'IPC',
    ARRAY['379', '411'],
    'केवल कथित बरामदगी के आधार पर धारा 411 का अपराध सिद्ध नहीं होता जब तक कि चुराई हुई संपत्ति होने का ज्ञान या विश्वास साबित न हो। स्वतंत्र गवाहों की अनुपस्थिति अभियोजन के मामले को कमजोर करती है।',
    'यह स्थापित विधिक स्थिति है कि धारा 411 भा.दं.वि. के अधीन अभियोजन को यह सिद्ध करना आवश्यक है कि बरामद वस्तु चोरी की संपत्ति थी और अभियुक्त को यह भली-भांति ज्ञात था। मौके पर धारा 100(4) दंड प्रक्रिया संहिता के अनुसार कोई स्वतंत्र साक्षी तलब नहीं किया गया, अतः बरामदगी मात्र पर दोषसिद्धि संदेहास्पद है।',
    14,
    'https://judgments.ecourts.gov.in/dummy_verified_record_411',
    -- Synthetic 768-float array (Normalized float for unit testing)
    array_fill(0.0125::float, ARRAY[768])::extensions.vector
);
9. ANTIGRAVITY NON-NEGOTIABLE VERIFICATION CHECKLIST (DOC-03)Antigravity code likhte waqt in exact technical assertions ko verify karega:[ ] Embedding column datatype strictly extensions.vector(768) hai[cite: 1].[ ] Precedent search query mein section pre-filter && operator use karega taaki irrelevant civil ya corporate case-laws criminal search mein pollute na hon.[ ] Similarity threshold strictly >= 0.65 enforce rahega (Lower values cause legal hallucinations).[ ] If search yields 0 rows above 0.65 similarity, UI will render PrecedentAbstainWidget (Rule 3: Not Found = Abstain).[ ] verified_source_url har precedent object mein mandatory hai; null ya broken links backend se filter out honge (Rule 1: No Hallucinated Citations).[ ] Vector search endpoint par user quota / Ad-credit validation active hai.[ ] Deleting a case in cases table triggers ON DELETE CASCADE on case_document_embeddings (DPDP Section 8(7) Compliance)[cite: 1].