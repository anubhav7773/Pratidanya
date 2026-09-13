-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 015 - UNDERTRIAL DETENTION AUDIT & SECTION 479 BNSS RELIEF
-- STATUTORY RELEVANCE: Section 479 BNSS 2023, Section 436A CrPC 1973,
--                      Re: Inhuman Conditions in 1382 Prisons (SC Order 23.08.2024)
-- ============================================================================

create table if not exists public.undertrial_relief_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Custody Duration & Offender Metrics
    jail_name text not null,
    custody_start_date date not null,
    calculation_date date not null default current_date,
    is_first_time_offender boolean not null default true,
    multiple_cases_pending boolean not null default false,

    -- Statutory Sentence Distribution & Thresholds
    max_punishment_months integer not null,
    statutory_threshold_fraction text not null check (statutory_threshold_fraction in ('ONE_THIRD', 'ONE_HALF')),
    threshold_duration_months numeric(6, 2) not null,
    actual_detention_served_months numeric(6, 2) not null,
    statutory_overstay_months numeric(6, 2) not null default 0.0,

    -- Eligibility & Disqualification Checks
    is_relief_applicable boolean not null default false,
    is_disqualified boolean not null default false,
    disqualification_reason text,
    is_retrospective_bnss_applied boolean not null default true,

    -- Generated Statutory Artifacts
    court_application_draft text not null,
    jail_superintendent_notice_draft text not null,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_undertrial_audit_case on public.undertrial_relief_audits(case_id);
create index if not exists idx_undertrial_audit_advocate on public.undertrial_relief_audits(advocate_id);

-- Enforce Strict Tenant Isolation via Row Level Security
alter table public.undertrial_relief_audits enable row level security;

create policy "Advocates own undertrial relief audits"
    on public.undertrial_relief_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
