-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 008 - SPECIALIZED ACTS: SC/ST (PoA) ACT 1989 & NI ACT SECTION 138
-- ============================================================================

-- Table 1: SC/ST (Prevention of Atrocities) Act Compliance & Bail Audits
create table if not exists public.scst_case_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Specific Offense Sections Under Section 3
    atrocity_sections text[] not null default array['3(1)(r)', '3(1)(s)'],
    
    -- Public View & Caste Animus Test (Hitesh Verma / Swaran Singh Doctrine)
    incident_place_type text not null check (incident_place_type in ('PRIVATE_HOUSE_ROOM', 'ENCLOSED_CHAMBER', 'PUBLIC_ROAD', 'PUBLIC_GROUND', 'VILLAGE_CHAUPAL')),
    independent_public_witnesses_present boolean not null default false,
    allegation_of_caste_name_used boolean not null default true,
    prior_land_or_civil_dispute_existing boolean not null default false,

    -- Anticipatory Bail Gate (Section 18 & 18A Bypassability)
    prima_facie_case_disclosed boolean not null default true,
    anticipatory_bail_maintainable boolean not null default false,

    -- Section 14A High Court Statutory Appeal Tracking
    special_court_order_date date,
    is_section_14a_appeal boolean not null default false,
    appeal_limitation_days integer not null default 90, -- Sec 14A(3) provides 90 days (extendable up to 180 days)
    is_within_statutory_limitation boolean not null default true,
    victim_notice_served_sec_15a boolean not null default false,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,

    constraint unique_case_scst_audit unique (case_id)
);

-- Table 2: Negotiable Instruments Act (Section 138) Statutory Notice & Timeline Audits
create table if not exists public.ni_act_notice_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,

    -- Cheque & Transaction Matrix
    cheque_number text not null,
    cheque_amount numeric(12, 2) not null,
    cheque_date date not null,
    bank_return_memo_date date not null,
    dishonour_reason text not null default 'FUNDS_INSUFFICIENT', -- 'FUNDS_INSUFFICIENT', 'ACCOUNT_CLOSED', 'STOP_PAYMENT'

    -- Section 138(b) Statutory Notice Compliance
    demand_notice_dispatch_date date not null,
    notice_dispatch_within_30_days boolean not null default true,
    demand_notice_delivery_date date,
    is_omnibus_demand_defective boolean not null default false, -- Demanding interest/penalties mixed with cheque amount

    -- Cause of Action Window (Section 138(c) & Section 142)
    cure_period_15_days_expiry_date date not null,
    complaint_filing_date date not null,
    is_premature_complaint boolean not null default false, -- Filed before expiry of 15 days (Fatal under Yogendra Pratap Singh)
    is_time_barred_complaint boolean not null default false, -- Filed after 30 days of cure expiry without condonation

    -- Section 139 Presumption Rebuttal & Compounding
    defense_category text not null default 'SECURITY_CHEQUE', -- 'SECURITY_CHEQUE', 'NO_EXISTING_DEBT', 'FINANCIAL_INCAPACITY', 'MISUSE_OF_BLANK_CHEQUE'
    seeks_compounding_under_sec_147 boolean not null default false,
    proposed_settlement_percentage numeric(5, 2) default 100.0,

    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,

    constraint unique_case_ni_act_audit unique (case_id)
);

-- Enable Row Level Security
alter table public.scst_case_audits enable row level security;
alter table public.ni_act_notice_audits enable row level security;

-- RLS Policies
create policy "Advocates have exclusive access to own SC/ST audits"
    on public.scst_case_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

create policy "Advocates have exclusive access to own NI Act audits"
    on public.ni_act_notice_audits for all
    using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
    with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
