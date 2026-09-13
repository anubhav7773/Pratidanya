-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 021 - UP GANGSTERS RULES 2021 & GOONDAS ACT DEFENSE SUITE
-- STATUTORY RELEVANCE: UP Gangsters Act 1986 & Rules 2021 (Rules 5, 16),
--                      Farhana v. State of U.P. (SC 2024),
--                      UP Control of Goondas Act 1970 Section 3,
--                      Ramji Pandey v. State of U.P. (Full Bench 1981)
-- ============================================================================

create table if not exists public.regional_special_acts_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Statutory Enactment & Jurisdiction
    statute_applied text not null check (statute_applied in (
        'UP_GANGSTERS_ACT_1986',
        'UP_GOONDAS_ACT_1970',
        'ARMS_ACT_1959'
    )),
    district text not null,
    police_station text not null,

    -- UP Gangsters Act & Rules 2021 Audit Fields
    gang_chart_number text,
    joint_meeting_rule_5_documented boolean not null default false,
    dm_independent_mind_applied boolean not null default false,
    dm_endorsement_raw_text text,
    predicate_base_cases jsonb not null default '[]'::jsonb,
    is_farhana_doctrine_applicable boolean not null default false,

    -- UP Control of Goondas Act 1970 Audit Fields
    goondas_notice_has_material_allegations boolean not null default true,
    goondas_notice_only_lists_firs boolean not null default false,

    -- Audit Findings & Courtroom Relief Drafts
    procedural_viability text not null check (procedural_viability in (
        'FATALLY_DEFECTIVE_CHALLENGEABLE',
        'IRREGULARITY_OBSERVED',
        'PRIMA_FACIE_REGULAR'
    )),
    grounds_of_challenge jsonb not null default '[]'::jsonb,
    recommended_forum text not null default 'ALLAHABAD_HIGH_COURT_ARTICLE_226',
    draft_petition_type text not null,
    draft_petition_hindi text not null,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_regional_audits_case on public.regional_special_acts_audits(case_id);
create index if not exists idx_regional_audits_advocate on public.regional_special_acts_audits(advocate_id);

-- Enforce Strict Advocate Chamber Isolation via Row Level Security
alter table public.regional_special_acts_audits enable row level security;

create policy "Advocates own regional special acts audits"
    on public.regional_special_acts_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
