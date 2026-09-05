-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 002 - CRIMINAL CASES DOCKET & COURT PROCEEDINGS LOG
-- DOMAIN: Subordinate / District Courts Criminal Jurisdiction (78.2% Backlog)
-- ============================================================================

-- Table: Master Criminal Cases Docket
create table public.cases (
    id uuid primary key default gen_random_uuid(),
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    
    -- Police Administration & FIR Record
    fir_number text not null,                       -- e.g., '124/2026'
    police_station text not null,                   -- e.g., 'Kotwali Nagar'
    district text not null,                         -- e.g., 'Lucknow'
    state text not null default 'Uttar Pradesh',
    
    -- Litigant Details
    accused_name text not null,
    accused_custody_status text not null default 'JUDICIAL_CUSTODY', -- 'JUDICIAL_CUSTODY', 'POLICE_CUSTODY', 'ON_BAIL', 'ANTICIPATORY'
    complainant_name text,
    
    -- Substantive & Procedural Law Mapping
    statute_system text not null default 'HYBRID',  -- 'BNS_BNSS', 'IPC_CRPC', 'HYBRID'
    under_sections text[] not null,                 -- e.g., ARRAY['379 IPC', '411 IPC'] or ARRAY['303 BNS']
    
    -- Judicial Hierarchy
    court_designation text not null,                -- 'CJM', 'ACJM-I', 'JMFC', 'Special Judge POCSO', 'Sessions Judge'
    case_number text,                               -- e.g., 'Bail App No. 450/2026'
    cnr_number text,                                -- 16-character eCourts CNR Number
    
    -- Docket State
    stage_of_case text not null,                    -- 'REMAND', 'BAIL_HEARING', 'CHARGESHEET_FILED', 'FRAMING_OF_CHARGES', 'EVIDENCE'
    next_hearing_date date,
    last_court_order text,
    
    -- Soft-Delete / Archival Flag
    is_archived boolean default false not null,
    
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table: Case Diary & Daily Hearing Proceedings
create table public.case_proceedings (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    proceeding_date date not null,
    court_coram text,                               -- Presiding Judicial Officer
    business_recorded text not null,                -- Summary of what transpired in court
    next_date date,
    purpose_of_next_date text,                      -- Next step: 'Arguments on Bail'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Performance Indexes
create index idx_cases_advocate_active on public.cases(advocate_id) where is_archived = false;
create index idx_cases_next_hearing on public.cases(advocate_id, next_hearing_date asc);
create index idx_cases_sections_gin on public.cases using gin(under_sections);
create index idx_proceedings_case_lookup on public.case_proceedings(case_id, proceeding_date desc);

-- Enable Row Level Security
alter table public.cases enable row level security;
alter table public.case_proceedings enable row level security;

-- RLS: Strict Chamber Isolation for Cases
create policy "Advocates have exclusive access to own cases"
    on public.cases
    for all
    using (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )
    with check (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    );

-- RLS: Strict Chamber Isolation for Proceedings
create policy "Advocates have exclusive access to own proceedings"
    on public.case_proceedings
    for all
    using (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )
    with check (
        advocate_id = auth.uid()::text or 
        advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    );
