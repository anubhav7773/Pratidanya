-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 014 - ARREST & REMAND PROCEDURAL COMPLIANCE AUDITS
-- STATUTORY RELEVANCE: Section 41A/41B CrPC, Section 35/36/38 BNSS 2023,
--                      Arnesh Kumar (2014), Satender Kumar Antil (2022)
-- ============================================================================

create table if not exists public.arrest_remand_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Statutory Classification & Offense Metrics
    offense_sections text[] not null default array[]::text[],
    max_punishment_years integer not null default 3,
    antil_category text not null check (antil_category in ('CATEGORY_A', 'CATEGORY_B', 'CATEGORY_C', 'CATEGORY_D')),
    
    -- Mandatory Procedural Checkpoints
    notice_issued_sec_35_bnss boolean not null default false,
    flight_or_tampering_risk_recorded boolean not null default false,
    arrest_memo_witness_count integer not null default 0,
    family_intimation_recorded boolean not null default false,
    medical_examination_conducted boolean not null default false,
    produced_within_24_hours boolean not null default true,
    magistrate_independent_reasons_recorded boolean not null default false,

    -- Audit Findings & Defense Strategy
    compliance_verdict text not null check (compliance_verdict in ('NON_COMPLIANT_VOID_ARREST', 'SUBSTANTIAL_IRREGULARITY', 'COMPLIANT_PROCEDURE')),
    fatal_violations text[] default array[]::text[],
    magistrate_directive_recommendation text not null,
    instant_objection_petition_draft text not null,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_arrest_audit_case on public.arrest_remand_audits(case_id);
create index if not exists idx_arrest_audit_advocate on public.arrest_remand_audits(advocate_id);

-- Enforce Strict Tenant Isolation via Row Level Security
alter table public.arrest_remand_audits enable row level security;

create policy "Advocates own arrest remand audit records"
    on public.arrest_remand_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
