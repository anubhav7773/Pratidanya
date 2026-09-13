-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 018 - MALKHANA CHAIN OF CUSTODY & FSL DISPATCH INTEGRITY AUDITOR
-- STATUTORY RELEVANCE: Section 103/105 BNSS (Sec 100/102 CrPC),
--                      UP Police Regulations Chapter XVIII (Register No. 19),
--                      NCB Standing Order 1/88 (Mandatory 72-Hour Dispatch),
--                      State of Rajasthan v. Gurmail Singh (2005) 3 SCC 59
-- ============================================================================

create table if not exists public.malkhana_custody_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Act & Seizure Protocol
    act_type text not null default 'NDPS' check (act_type in ('NDPS', 'ARMS_ACT', 'BNS_IPC_FORENSICS', 'EXCISE_ACT')),
    seizure_date timestamp with time zone not null,
    seizure_seal_impression text not null,

    -- Malkhana Register No. 19 Ingestion
    malkhana_deposit_date timestamp with time zone not null,
    malkhana_register_number text not null, -- e.g., 'Reg-19/Item-402'
    specimen_seal_deposited boolean not null default false, -- नमूना मुहर
    gd_deposit_entry_number text,

    -- Dispatch to Forensic Science Laboratory (FSL)
    fsl_dispatch_date timestamp with time zone not null,
    fsl_received_date timestamp with time zone not null,
    fsl_receipt_seal_impression text not null,
    road_certificate_annexed boolean not null default false,
    road_certificate_number text,
    carrier_constable_name text,

    -- Integrity & Tampering Analysis
    fsl_dispatch_delay_days integer not null default 0,
    is_chain_of_custody_intact boolean not null default false,
    has_fatal_tampering_risk boolean not null default false,
    fatal_vulnerabilities jsonb not null default '[]'::jsonb,
    
    -- Actionable Courtroom Pleadings & Cross-Exam Questions
    application_sec_254_bnss_draft text not null,
    cross_examination_carrier_questions text[] default array[]::text[],

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_malkhana_audit_case on public.malkhana_custody_audits(case_id);
create index if not exists idx_malkhana_audit_advocate on public.malkhana_custody_audits(advocate_id);

-- Enforce Strict Tenant Isolation via Row Level Security
alter table public.malkhana_custody_audits enable row level security;

create policy "Advocates own malkhana chain custody records"
    on public.malkhana_custody_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
