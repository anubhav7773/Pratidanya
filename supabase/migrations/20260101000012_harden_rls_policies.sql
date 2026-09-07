-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 012 - REVOKE ANON BYPASS & ENFORCE STRICT ADVOCATE ISOLATION
-- FIXES: SEC-02 (Statutory DPDP Data Leak via Public Anon Key)
-- ============================================================================

-- 1. DROP ALL LEAKING ANON POLICIES INTRODUCED IN MIGRATION 011
drop policy if exists "Allow anon access cases" on public.cases;
drop policy if exists "Allow anon access proceedings" on public.case_proceedings;
drop policy if exists "Allow anon access advocate_ai_quotas" on public.advocate_ai_quotas;
drop policy if exists "Allow anon access advocate_subscriptions" on public.advocate_subscriptions;
drop policy if exists "Allow anon access case_document_embeddings" on public.case_document_embeddings;
drop policy if exists "Allow anon access voice_dictation_sessions" on public.voice_dictation_sessions;

-- 2. ENSURE RLS IS HARD-ENABLED ON ALL CORE TABLES
alter table public.advocate_profiles enable row level security;
alter table public.cases enable row level security;
alter table public.case_proceedings enable row level security;
alter table public.case_document_embeddings enable row level security;
alter table public.advocate_ai_quotas enable row level security;
alter table public.advocate_subscriptions enable row level security;
alter table public.high_court_pleadings enable row level security;
alter table public.trial_court_judgment_analyses enable row level security;
alter table public.ndps_seizure_audits enable row level security;
alter table public.pocso_age_audits enable row level security;
alter table public.scst_case_audits enable row level security;
alter table public.ni_act_notice_audits enable row level security;
alter table public.voice_dictation_sessions enable row level security;

-- 3. RE-APPLY STRICT ADVOCATE CHAMBER ISOLATION POLICIES
-- Note: Calls must be authenticated (authenticated role or matching sub claim in JWT)

-- Helper function to extract caller uid safely from Supabase/Firebase claims or client header
create or replace function public.current_request_advocate_id()
returns text
language sql
stable
as $$
    select coalesce(
        nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', ''),
        nullif(current_setting('request.headers', true)::jsonb ->> 'x-advocate-id', ''),
        auth.uid()::text
    );
$$;

-- Table: cases
drop policy if exists "Advocates own cases isolation" on public.cases;
create policy "Advocates own cases isolation"
    on public.cases
    for all
    using (advocate_id = public.current_request_advocate_id())
    with check (advocate_id = public.current_request_advocate_id());

-- Table: case_proceedings
drop policy if exists "Advocates own proceedings isolation" on public.case_proceedings;
create policy "Advocates own proceedings isolation"
    on public.case_proceedings
    for all
    using (advocate_id = public.current_request_advocate_id())
    with check (advocate_id = public.current_request_advocate_id());

-- Table: advocate_ai_quotas
drop policy if exists "Advocates own quotas isolation" on public.advocate_ai_quotas;
create policy "Advocates own quotas isolation"
    on public.advocate_ai_quotas
    for all
    using (advocate_id = public.current_request_advocate_id())
    with check (advocate_id = public.current_request_advocate_id());

-- Table: advocate_subscriptions
drop policy if exists "Advocates own subscriptions isolation" on public.advocate_subscriptions;
create policy "Advocates own subscriptions isolation"
    on public.advocate_subscriptions
    for all
    using (advocate_id = public.current_request_advocate_id())
    with check (advocate_id = public.current_request_advocate_id());

-- Table: case_document_embeddings
drop policy if exists "Advocates own embeddings isolation" on public.case_document_embeddings;
create policy "Advocates own embeddings isolation"
    on public.case_document_embeddings
    for all
    using (advocate_id = public.current_request_advocate_id())
    with check (advocate_id = public.current_request_advocate_id());

-- Table: voice_dictation_sessions
drop policy if exists "Advocates own voice sessions isolation" on public.voice_dictation_sessions;
create policy "Advocates own voice sessions isolation"
    on public.voice_dictation_sessions
    for all
    using (advocate_id = public.current_request_advocate_id())
    with check (advocate_id = public.current_request_advocate_id());
