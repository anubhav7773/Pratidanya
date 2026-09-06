-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 007 - SPECIALIZED CRIMINAL ACTS (NDPS ACT 1985 & POCSO ACT 2012)
-- ============================================================================

-- Table 1: NDPS Search, Seizure & Section 50 Compliance Audits
create table if not exists public.ndps_seizure_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    
    -- Contraband Substance & Quantity Classification
    substance_name text not null,                 -- 'Ganja', 'Charas', 'Heroin/Smack', 'Opium', 'Tramadol'
    recovered_quantity_grams numeric(12, 3) not null,
    quantity_category text not null check (quantity_category in ('SMALL_QUANTITY', 'INTERMEDIATE_QUANTITY', 'COMMERCIAL_QUANTITY')),
    is_section_37_bar_applicable boolean not null default false,
    
    -- Section 50 Mandatory Compliance Matrix (Personal Search)
    is_personal_search boolean not null default true, -- false if recovery from bag, vehicle or house
    section_50_notice_given boolean not null default false,
    section_50_notice_type text check (section_50_notice_type in ('WRITTEN_INDEPENDENT', 'ORAL_ONLY', 'JOINT_NOTICE_DEFECTIVE', 'NO_NOTICE')),
    was_searched_before_gazetted_officer boolean not null default false,
    was_searched_before_magistrate boolean not null default false,
    third_option_defect_present boolean not null default false, -- e.g. "या आप हमारी तलाशी ले सकते हैं"
    
    -- Section 42 / 43 Search Authorization & Link Evidence
    information_recorded_in_writing boolean not null default false,
    information_sent_to_superior_within_72h boolean not null default false,
    independent_public_witnesses_present boolean not null default false,
    sample_drawn_before_magistrate_sec_52a boolean not null default false,
    malkhana_entry_delay_days integer default 0,
    fsl_dispatch_delay_days integer default 0,
    
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint unique_case_ndps_audit unique (case_id)
);

-- Table 2: POCSO Act Section 94 JJ Act Age Determination Audits
create table if not exists public.pocso_age_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    
    -- Victim Documented Age Claims
    alleged_incident_date date not null,
    fir_stated_age_years integer not null,
    
    -- Section 94 JJ Act Statutory Hierarchy
    has_first_attended_school_certificate boolean not null default false,
    school_dob date,
    has_matriculation_certificate boolean not null default false,
    matriculation_dob date,
    has_municipal_birth_certificate boolean not null default false,
    municipal_dob date,
    
    -- Medical Board & Ossification Examination
    ossification_test_conducted boolean not null default false,
    radiological_age_lower numeric(4, 1),        -- e.g. 16.0
    radiological_age_upper numeric(4, 1),        -- e.g. 18.0
    two_year_margin_benefit_applied boolean not null default true,
    computed_majority_probable boolean not null default false,
    
    -- Section 29/30 Presumption Rebuttal Indicators
    evidence_of_prior_romantic_relationship boolean not null default false,
    cdr_call_records_exchanged boolean not null default false,
    unexplained_delay_in_fir_days integer default 0,
    no_external_or_internal_injuries boolean not null default false,
    
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    constraint unique_case_pocso_audit unique (case_id)
);

-- Row Level Security
alter table public.ndps_seizure_audits enable row level security;
alter table public.pocso_age_audits enable row level security;

create policy "Advocates have exclusive access to own NDPS audits"
    on public.ndps_seizure_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

create policy "Advocates have exclusive access to own POCSO audits"
    on public.pocso_age_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
