-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 017 - MEDICO-LEGAL AUTOPSY/MLC VS. OCULAR DISCREPANCY MATRIX
-- STATUTORY RELEVANCE: Section 39 BSA 2023 / Section 45 IEA 1872,
--                      Ram Narain Singh v. State of Punjab (1975) 4 SCC 34,
--                      Darshan Singh v. State of Punjab (2010) 2 SCC 333
-- ============================================================================

create table if not exists public.medico_legal_matrices (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Forensic Report Metadata
    post_mortem_report_number text not null,
    autopsy_doctor_name text,
    hospital_name text,
    autopsy_timestamp timestamp with time zone not null,

    -- Extracted Clinical & Anatomical Parameters
    injuries_extracted jsonb not null default '[]'::jsonb,
    stomach_contents_analysis text,
    rigor_mortis_state text,
    estimated_pmi_hours_range numeric[] not null default array[24.0, 36.0]::numeric[],

    -- Eyewitness Deposition Assertions
    witness_ocular_allegations jsonb not null default '[]'::jsonb,

    -- Evaluated Irreconcilable Conflicts
    has_fatal_conflict boolean not null default false,
    irreconcilable_conflicts jsonb not null default '[]'::jsonb,
    cross_examination_questions text[] default array[]::text[],
    written_medical_argument_draft text not null,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_medico_matrix_case on public.medico_legal_matrices(case_id);
create index if not exists idx_medico_matrix_advocate on public.medico_legal_matrices(advocate_id);

-- Enforce Strict Advocate Chamber Isolation via Row Level Security
alter table public.medico_legal_matrices enable row level security;

create policy "Advocates have exclusive access to own medico-legal matrices"
    on public.medico_legal_matrices for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
