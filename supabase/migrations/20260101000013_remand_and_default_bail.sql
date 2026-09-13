-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 013 - REMAND CUSTODY LEDGER & DEFAULT BAIL ENGINE
-- STATUTORY RELEVANCE: Section 167(2) CrPC & Section 187 BNSS 2023
-- ============================================================================

create table if not exists public.remand_custody_ledger (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    
    -- Custody Timeline Tracking
    first_remand_date timestamp with time zone not null,
    statutory_regime text not null default 'BNSS' check (statutory_regime in ('BNSS', 'CRPC')),
    statutory_threshold_days integer not null check (statutory_threshold_days in (60, 90, 180)),
    days_elapsed_in_custody integer not null default 0,
    is_default_bail_crystallized boolean not null default false,
    default_bail_accrual_timestamp timestamp with time zone not null,
    
    -- Section 187 BNSS Split Police Custody Accounting
    police_custody_days_used integer not null default 0,
    police_custody_days_remaining integer not null default 15,
    police_custody_window_expired boolean not null default false,
    
    -- Incomplete Chargesheet Defect Ledger (Kapil Wadhawan / Bikramjit Singh)
    chargesheet_filed boolean not null default false,
    chargesheet_filing_date timestamp with time zone,
    is_chargesheet_incomplete boolean not null default false,
    defect_classification text,
    missing_mandatory_reports text[] default array[]::text[],
    
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_remand_ledger_case on public.remand_custody_ledger(case_id);
create index if not exists idx_remand_ledger_advocate on public.remand_custody_ledger(advocate_id);

-- Enforce Strict Tenant Isolation via Row Level Security
alter table public.remand_custody_ledger enable row level security;

create policy "Advocates own remand ledger records"
    on public.remand_custody_ledger for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
