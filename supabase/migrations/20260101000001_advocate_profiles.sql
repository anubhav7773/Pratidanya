-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 001 - ADVOCATE PROFILES & IDENTITY MANAGEMENT
-- STATUTORY COMPLIANCE: Advocates Act 1961 (Sec 30) & DPDP Act 2023 (Sec 5/6)
-- ============================================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- Table: Licensed criminal advocates enrolled with State Bar Councils
create table public.advocate_profiles (
    id text primary key, -- Firebase Auth UID string mapping
    email text unique not null,
    full_name text not null,
    bar_council_number text unique not null, -- e.g., 'UP/1234/2018'
    enrolled_state text not null default 'Uttar Pradesh',
    primary_court_name text not null default 'District & Sessions Court',
    court_type text not null default 'DISTRICT_SUBORDINATE',
    chamber_address text,
    dpdp_consent_accepted boolean default false not null,
    dpdp_consent_timestamp timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

comment on table public.advocate_profiles is 'Verified advocates enrolled with Bar Councils under Section 30 of Advocates Act 1961.';

-- Enable Row Level Security
alter table public.advocate_profiles enable row level security;

-- RLS: Advocate can view only their own profile
create policy "Advocates can view own profile"
    on public.advocate_profiles
    for select
    using (
        id = auth.uid()::text or 
        id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    );

-- RLS: Advocate can update only their own profile
create policy "Advocates can update own profile"
    on public.advocate_profiles
    for update
    using (
        id = auth.uid()::text or 
        id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )
    with check (
        id = auth.uid()::text or 
        id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    );

-- RLS: Advocate can insert their own profile upon initial onboarding
create policy "Advocates can insert own profile"
    on public.advocate_profiles
    for insert
    with check (
        id = auth.uid()::text or 
        id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    );
