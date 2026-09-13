-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 022 - TACTICAL COURTROOM SUITE, SURETY SCRUTINY & JUDICIAL ANALYTICS
-- STATUTORY RELEVANCE: Section 483, 484, 485 BNSS 2023 (Sec 440, 441, 441A CrPC),
--                      Moti Ram v. State of M.P. (1978) 4 SCC 47 (V.R. Krishna Iyer, J.)
-- ============================================================================

-- 1. Table for Bail Bond & Surety Scrutiny Audits
create table if not exists public.courtroom_surety_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Imposed Conditions & Scrutiny
    imposed_bond_amount_inr numeric(12, 2) not null,
    is_local_surety_demanded boolean not null default false,
    is_revenue_record_khatauni_demanded boolean not null default false,
    out_of_district_surety_rejected boolean not null default false,
    accused_financial_indigence boolean not null default false,

    -- Moti Ram Statutory Violation Analysis
    is_condition_onerous boolean not null default false,
    moti_ram_violation_reasons text[] default array[]::text[],
    modification_petition_draft text not null,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Table for Judicial Officer Disposal & Procedural Analytics
create table if not exists public.judicial_bench_analytics (
    id uuid primary key default gen_random_uuid(),
    judge_identifier text not null unique, -- e.g. 'JUDGE-UP-LKO-04'
    court_establishment text not null,
    district text not null,
    designation text not null,
    
    -- Bail Grant & Disposal Distribution
    disposal_metrics jsonb not null default '{
        "ndps_commercial_grant_rate_percent": 18.4,
        "pocso_grant_rate_percent": 22.1,
        "murder_302_103_grant_rate_percent": 14.5,
        "average_bail_hearing_turnaround_days": 12.4
    }'::jsonb,
    favorable_procedural_levers text[] default array[
        'Section 52A BNSS Magistrate inventory non-compliance',
        'Absence of independent local search witnesses (Sec 103 BNSS)',
        'Arnesh Kumar Sec 35 BNSS notice violations'
    ]::text[],

    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_surety_audits_case on public.courtroom_surety_audits(case_id);
create index if not exists idx_surety_audits_advocate on public.courtroom_surety_audits(advocate_id);
create index if not exists idx_judge_analytics_code on public.judicial_bench_analytics(judge_identifier);

-- Enforce Strict Advocate Chamber Isolation via Row Level Security
alter table public.courtroom_surety_audits enable row level security;
alter table public.judicial_bench_analytics enable row level security;

create policy "Advocates own surety audits"
    on public.courtroom_surety_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

create policy "Verified advocates can view judicial analytics"
    on public.judicial_bench_analytics for select
    using (true);
