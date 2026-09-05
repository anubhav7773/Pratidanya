-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 003 - PGVECTOR EXTENSION, HNSW INDEXING & SEMANTIC RETRIEVAL
-- VECTOR DIMENSION: 768 (text-embedding-004 / gemini-embedding-001)
-- ============================================================================

-- Enable pgvector extension
create extension if not exists vector with schema extensions;

-- Table 1: Curated Public Precedent Library (RAG Knowledge Base)
create table public.verified_precedents (
    id uuid primary key default gen_random_uuid(),
    citation_id text unique not null,               -- e.g., '2024_ALHC_CRIMINAL_411'
    case_title text not null,                       -- e.g., 'State of U.P. vs. Ramesh & Ors.'
    court_name text not null,                       -- e.g., 'High Court of Judicature at Allahabad'
    bench_type text not null default 'SINGLE_BENCH',-- 'SINGLE_BENCH', 'DIVISION_BENCH'
    judgment_date date not null,
    act_name text not null,                         -- 'IPC', 'BNS', 'CrPC', 'BNSS', 'NDPS'
    section_numbers text[] not null,                -- ARRAY['379', '411']
    headnote_hindi text not null,                   -- Case Ratio in Devanagari Hindi
    verbatim_text text not null,                    -- Exact extracted legal paragraph
    paragraph_number integer,                       -- Judgment Official Paragraph Number
    verified_source_url text not null,              -- Rule 1 Mandate: Official verifiable source link
    embedding extensions.vector(768) not null,      -- 768 Dimensions
    is_active boolean default true not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table 2: Private Chamber Case Document Chunks (Isolated RAG per Case)
create table public.case_document_embeddings (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    document_name text not null,                    -- e.g., 'Chargesheet_124_2026.pdf'
    document_type text not null,                    -- 'FIR', 'CHARGESHEET', 'BAIL_ORDER', 'DEFENSE_NOTE'
    chunk_index integer not null,
    chunk_text text not null,
    token_count integer not null,
    metadata jsonb default '{}'::jsonb,
    embedding extensions.vector(768) not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- HNSW Indexes: Zero Recall Loss for Criminal Law Precedents
create index idx_verified_precedents_hnsw_cosine
on public.verified_precedents 
using hnsw (embedding extensions.vector_cosine_ops)
with (m = 16, ef_construction = 64);

create index idx_verified_precedents_hnsw_l2
on public.verified_precedents 
using hnsw (embedding extensions.vector_l2_ops)
with (m = 16, ef_construction = 64);

create index idx_case_embeddings_hnsw_cosine
on public.case_document_embeddings 
using hnsw (embedding extensions.vector_cosine_ops)
with (m = 16, ef_construction = 64);

-- GIN Index for rapid section-based pre-filtering
create index idx_precedents_sections_gin on public.verified_precedents using gin(section_numbers);
create index idx_case_embeddings_lookup on public.case_document_embeddings(case_id, advocate_id);

-- Enable Row Level Security
alter table public.verified_precedents enable row level security;
alter table public.case_document_embeddings enable row level security;

-- RLS: Public precedent pool is readable by all authenticated advocates
create policy "Authenticated advocates can search verified precedents"
    on public.verified_precedents
    for select
    to authenticated
    using (is_active = true);

-- RLS: Private document embeddings strictly isolated to the chamber advocate
create policy "Advocates have exclusive access to own case embeddings"
    on public.case_document_embeddings
    for all
    using (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )
    with check (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    );

-- ============================================================================
-- STORED PROCEDURE: MATCH VERIFIED PRECEDENTS (COSINE & L2 DISTANCE)
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
    -- Hard Similarity Cutoff (Rule 3: Not Found = Abstain)
    and (1 - (vp.embedding <=> query_embedding)) >= similarity_threshold
  order by vp.embedding <=> query_embedding asc
  limit match_count;
end;
$$;

-- ============================================================================
-- STORED PROCEDURE: MATCH PRIVATE CASE CHUNKS (CHAMBER RAG)
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
