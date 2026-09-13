-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 020 - HOSTILE WITNESS & LEADING QUESTION TREES
-- STATUTORY RELEVANCE: Section 142, 146, 147, 157 BSA 2023 (Sec 137, 141, 143, 154 IEA 1872),
--                      Sat Paul v. Delhi Administration (1976) 1 SCC 727,
--                      Neeraj Dutta v. State (Govt. of NCT of Delhi) (2023) 4 SCC 731
-- ============================================================================

create table if not exists public.hostile_witness_question_trees (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Witness Identification & Defense Strategy
    witness_name text not null,
    witness_role text not null default 'PANCH_WITNESS_SEIZURE',
    defense_theory text not null check (defense_theory in (
        'PLANTED_RECOVERY_STOCK_WITNESS',
        'ALIBI_AND_ABSENCE',
        'CONSENSUAL_RELATION_SEC_69_BNS',
        'MISTAKEN_IDENTITY_TIP_FAILURE'
    )),
    case_facts jsonb not null default '{}'::jsonb,

    -- Generated Question Trees & Tactical Guidance
    questionnaire_strategy_hindi text not null,
    question_trees jsonb not null default '[]'::jsonb,
    trial_tactics_summary_hindi text not null,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_witness_questions_case on public.hostile_witness_question_trees(case_id);
create index if not exists idx_witness_questions_advocate on public.hostile_witness_question_trees(advocate_id);

-- Enforce Strict Advocate Chamber Isolation via Row Level Security
alter table public.hostile_witness_question_trees enable row level security;

create policy "Advocates own hostile witness question trees"
    on public.hostile_witness_question_trees for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
