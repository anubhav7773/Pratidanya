-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 006 - HIGH COURT PLEADINGS & TRIAL COURT JUDGMENT ANALYSIS
-- DOMAIN: High Court Appellate & Revisional Jurisdiction (Sec 374/397 CrPC / Sec 415/438 BNSS)
-- ============================================================================

-- Table 1: Master High Court Appellate & Revisional Dockets
create table if not exists public.high_court_pleadings (
    id uuid primary key default gen_random_uuid(),
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    pleading_type text not null check (pleading_type in ('CRIMINAL_APPEAL', 'CRIMINAL_REVISION', 'SECTION_482_APPLICATION')),
    high_court_bench text not null default 'LUCKNOW_BENCH', -- 'ALLAHABAD_PRINCIPAL', 'LUCKNOW_BENCH'
    
    -- Subordinate Trial Court Record (TCR) Metadata
    trial_court_name text not null,               -- e.g., 'अपर सत्र न्यायाधीश, न्यायालय सं. 4, लखनऊ'
    trial_case_number text not null,              -- e.g., 'सत्र परीक्षण संख्या 342/2021'
    trial_judgment_date date not null,
    trial_presiding_judge text not null,          -- Judicial Officer name
    
    -- Sentencing & Custody Matrix
    convicted_sections text[] not null,           -- e.g., ARRAY['307 IPC', '323 IPC', '34 IPC']
    quantum_of_sentence text not null,            -- e.g., '7 वर्ष का कठोर कारावास एवं ₹10,000 अर्थदंड'
    fine_deposited boolean default false not null,
    appellant_custody_status text not null default 'IN_JAIL', -- 'IN_JAIL', 'ON_PROVISIONAL_BAIL_389'
    days_in_custody integer default 0 not null,
    
    -- Case Title & Parties
    case_title text not null,                     -- e.g., 'राजू उर्फ राजेश बनाम उत्तर प्रदेश राज्य'
    accused_names text[] not null,
    complainant_name text,
    police_station text not null,
    district text not null,
    fir_number text not null,
    
    -- Statutory Limitation Tracking (Limitation Act 1963)
    certified_copy_applied_date date,
    certified_copy_ready_date date,
    limitation_expiry_date date not null,
    is_delayed boolean default false not null,
    delay_days integer default 0 not null,
    
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table 2: Extracted Trial Court Evidence & Procedural Defect Matrix
create table if not exists public.trial_court_judgment_analyses (
    id uuid primary key default gen_random_uuid(),
    pleading_id uuid not null references public.high_court_pleadings(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    
    -- Structural Extracts
    operative_sentence_hindi text not null,
    prosecution_witness_flaws jsonb default '[]'::jsonb not null,
    procedural_omissions jsonb default '[]'::jsonb not null,
    section_313_examination_defects text,
    ocular_vs_medical_conflict text,
    malkhana_link_evidence_defects text,
    raw_judgment_word_count integer not null default 0,
    
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Indexes for rapid case lookups
create index if not exists idx_hc_pleadings_advocate on public.high_court_pleadings(advocate_id, pleading_type);
create index if not exists idx_trial_analysis_pleading on public.trial_court_judgment_analyses(pleading_id);

-- Enable Row Level Security
alter table public.high_court_pleadings enable row level security;
alter table public.trial_court_judgment_analyses enable row level security;

-- Strict Chamber Isolation RLS Policies
create policy "Advocates have exclusive access to own High Court pleadings"
    on public.high_court_pleadings
    for all
    using (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )
    with check (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    );

create policy "Advocates have exclusive access to own trial analyses"
    on public.trial_court_judgment_analyses
    for all
    using (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )
    with check (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    );
