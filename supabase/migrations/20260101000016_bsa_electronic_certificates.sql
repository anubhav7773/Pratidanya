-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 016 - BSA SECTION 63 ELECTRONIC EVIDENCE CERTIFICATE AUDIT
-- STATUTORY RELEVANCE: Section 63 BSA 2023, Section 65B IEA 1872,
--                      Arjun Panditrao Khotkar v. Kailash Kushanrao Gorantyal (2020)
-- ============================================================================

create table if not exists public.bsa_electronic_certificates (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Exhibit & Digital Device Metadata
    exhibit_mark text not null, -- e.g., 'Ex. P-14' or 'Mark X-1'
    evidence_type text not null check (evidence_type in (
        'CALL_DETAIL_RECORD_CDR',
        'TOWER_DUMP',
        'WHATSAPP_CHAT_EXPORT',
        'CCTV_DVR_FOOTAGE',
        'MOBILE_FORENSIC_IMAGE',
        'AUDIO_VOICE_RECORDING',
        'SERVER_SYSTEM_LOGS'
    )),
    device_type text not null,
    device_make_model text,
    device_serial_number text,
    device_imei_mac text,

    -- Statutory Schedule Two-Part Execution Audit (Section 63(4)(c) BSA)
    is_schedule_format_matched boolean not null default false,
    part_a_executed boolean not null default false,
    part_a_signatory_type text, -- 'INVESTIGATING_OFFICER', 'NODAL_OFFICER', 'COMPLAINANT', 'NONE'
    part_b_executed boolean not null default false,
    part_b_expert_designation text,

    -- Cryptographic Hash Value & Integrity Verification
    declared_hash_algorithm text not null check (declared_hash_algorithm in ('SHA256', 'SHA1', 'MD5', 'NONE')),
    declared_hash_value text,
    is_hash_valid_alphanumeric boolean not null default false,
    contemporaneous_acquisition boolean not null default true,

    -- Legal Admissibility Verdict & Objections
    admissibility_status text not null check (admissibility_status in (
        'FATAL_DEFECT_INADMISSIBLE',
        'SUBSTANTIAL_REGULARITY_CHALLENGEABLE',
        'PRIMA_FACIE_ADMISSIBLE'
    )),
    statutory_defects text[] default array[]::text[],
    written_objection_draft text not null,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_bsa_cert_case on public.bsa_electronic_certificates(case_id);
create index if not exists idx_bsa_cert_advocate on public.bsa_electronic_certificates(advocate_id);

-- Enforce Strict Advocate Chamber Isolation via Row Level Security
alter table public.bsa_electronic_certificates enable row level security;

create policy "Advocates have exclusive access to own BSA electronic certificates"
    on public.bsa_electronic_certificates for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
