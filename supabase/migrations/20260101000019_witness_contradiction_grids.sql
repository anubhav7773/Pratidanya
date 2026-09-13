-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 019 - WITNESS CONTRADICTION & OMISSION GRID
-- STATUTORY RELEVANCE: Section 148 & 149 BSA 2023 (Sec 145 & 146 IEA 1872),
--                      Section 183 BNSS 2023 (Sec 161 & 162 CrPC 1973),
--                      Tahsildar Singh v. State of U.P. (1959) Supp (2) SCR 875,
--                      V.K. Mishra v. State of Uttarakhand (2015) 9 SCC 588
-- ============================================================================

create table if not exists public.witness_contradiction_grids (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Witness Identification & Testimony Sources
    witness_code text not null, -- e.g. 'PW-1', 'PW-2'
    witness_name text not null,
    witness_role text not null default 'EYEWITNESS', -- 'EYEWITNESS', 'INJURED_WITNESS', 'PANCH_SEIZURE', 'CHANCE_WITNESS'
    fir_narrative text,
    sec_161_crpc_statement text not null,
    sec_164_crpc_statement text,
    court_deposition_chief text not null,

    -- Evaluated Contradictions & Omission Alignments
    has_fatal_contradictions boolean not null default false,
    contradictions_grid jsonb not null default '[]'::jsonb,
    marked_exhibits jsonb not null default '[]'::jsonb, -- e.g. [{'exhibit': 'Ex. D-1', 'passage': '...'}]
    io_cross_examination_reminders text[] default array[]::text[],
    confrontation_script_hindi text not null,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_witness_grid_case on public.witness_contradiction_grids(case_id);
create index if not exists idx_witness_grid_advocate on public.witness_contradiction_grids(advocate_id);

-- Enforce Strict Advocate Chamber Isolation via Row Level Security
alter table public.witness_contradiction_grids enable row level security;

create policy "Advocates own witness contradiction grids"
    on public.witness_contradiction_grids for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
