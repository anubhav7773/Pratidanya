-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- CONSOLIDATED MIGRATIONS: 013 TO 022
-- STATUTORY RELEVANCE:
--   013: Sec 167(2) CrPC & Sec 187 BNSS 2023 (Default Bail & Remand Ledger)
--   014: Sec 35/36/38 BNSS & Sec 41A CrPC (Arrest & Remand Procedural Compliance)
--   015: Sec 479 BNSS & Sec 436A CrPC (Undertrial 1/3rd & 1/2 Detention Relief)
--   016: Sec 63 BSA 2023 & Sec 65B IEA 1872 (Electronic Evidence Certificates)
--   017: Sec 39 BSA 2023 / Sec 45 IEA 1872 (Medico-Legal vs Ocular Discrepancy Matrix)
--   018: Register No. 19 & NCB S.O. 1/88 (Malkhana Chain of Custody & FSL Dispatch)
--   019: Sec 148/149 BSA 2023 & Tahsildar Singh (Witness Contradiction Grids)
--   020: Sec 142/146/147/157 BSA 2023 & Sat Paul (Hostile Witness Question Trees)
--   021: UP Gangsters Rules 2021 & UP Control of Goondas Act 1970
--   022: Sec 483-485 BNSS & Moti Ram v. State of M.P. (Courtroom Sureties & Analytics)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 013: REMAND CUSTODY LEDGER & DEFAULT BAIL ENGINE
-- ----------------------------------------------------------------------------
create table if not exists public.remand_custody_ledger (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    first_remand_date timestamp with time zone not null,
    statutory_regime text not null default 'BNSS' check (statutory_regime in ('BNSS', 'CRPC')),
    statutory_threshold_days integer not null check (statutory_threshold_days in (60, 90, 180)),
    days_elapsed_in_custody integer not null default 0,
    is_default_bail_crystallized boolean not null default false,
    default_bail_accrual_timestamp timestamp with time zone not null,
    police_custody_days_used integer not null default 0,
    police_custody_days_remaining integer not null default 15,
    police_custody_window_expired boolean not null default false,
    chargesheet_filed boolean not null default false,
    chargesheet_filing_date timestamp with time zone,
    is_chargesheet_incomplete boolean not null default false,
    defect_classification text,
    missing_mandatory_reports text[] default array[]::text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_remand_ledger_case on public.remand_custody_ledger(case_id);
create index if not exists idx_remand_ledger_advocate on public.remand_custody_ledger(advocate_id);

alter table public.remand_custody_ledger enable row level security;

do $$ begin
    drop policy if exists "Advocates own remand ledger records" on public.remand_custody_ledger;
    create policy "Advocates own remand ledger records"
        on public.remand_custody_ledger for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 014: ARREST & REMAND PROCEDURAL COMPLIANCE AUDITS
-- ----------------------------------------------------------------------------
create table if not exists public.arrest_remand_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    offense_sections text[] not null default array[]::text[],
    max_punishment_years integer not null default 3,
    antil_category text not null check (antil_category in ('CATEGORY_A', 'CATEGORY_B', 'CATEGORY_C', 'CATEGORY_D')),
    notice_issued_sec_35_bnss boolean not null default false,
    flight_or_tampering_risk_recorded boolean not null default false,
    arrest_memo_witness_count integer not null default 0,
    family_intimation_recorded boolean not null default false,
    medical_examination_conducted boolean not null default false,
    produced_within_24_hours boolean not null default true,
    magistrate_independent_reasons_recorded boolean not null default false,
    compliance_verdict text not null check (compliance_verdict in ('NON_COMPLIANT_VOID_ARREST', 'SUBSTANTIAL_IRREGULARITY', 'COMPLIANT_PROCEDURE')),
    fatal_violations text[] default array[]::text[],
    magistrate_directive_recommendation text not null,
    instant_objection_petition_draft text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_arrest_audit_case on public.arrest_remand_audits(case_id);
create index if not exists idx_arrest_audit_advocate on public.arrest_remand_audits(advocate_id);

alter table public.arrest_remand_audits enable row level security;

do $$ begin
    drop policy if exists "Advocates own arrest remand audit records" on public.arrest_remand_audits;
    create policy "Advocates own arrest remand audit records"
        on public.arrest_remand_audits for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 015: UNDERTRIAL DETENTION AUDIT & SECTION 479 BNSS RELIEF
-- ----------------------------------------------------------------------------
create table if not exists public.undertrial_relief_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    jail_name text not null,
    custody_start_date date not null,
    calculation_date date not null default current_date,
    is_first_time_offender boolean not null default true,
    multiple_cases_pending boolean not null default false,
    max_punishment_months integer not null,
    statutory_threshold_fraction text not null check (statutory_threshold_fraction in ('ONE_THIRD', 'ONE_HALF')),
    threshold_duration_months numeric(6, 2) not null,
    actual_detention_served_months numeric(6, 2) not null,
    statutory_overstay_months numeric(6, 2) not null default 0.0,
    is_relief_applicable boolean not null default false,
    is_disqualified boolean not null default false,
    disqualification_reason text,
    is_retrospective_bnss_applied boolean not null default true,
    court_application_draft text not null,
    jail_superintendent_notice_draft text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_undertrial_audit_case on public.undertrial_relief_audits(case_id);
create index if not exists idx_undertrial_audit_advocate on public.undertrial_relief_audits(advocate_id);

alter table public.undertrial_relief_audits enable row level security;

do $$ begin
    drop policy if exists "Advocates own undertrial relief audits" on public.undertrial_relief_audits;
    create policy "Advocates own undertrial relief audits"
        on public.undertrial_relief_audits for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 016: BSA SECTION 63 ELECTRONIC EVIDENCE CERTIFICATE AUDIT
-- ----------------------------------------------------------------------------
create table if not exists public.bsa_electronic_certificates (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    exhibit_mark text not null,
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
    is_schedule_format_matched boolean not null default false,
    part_a_executed boolean not null default false,
    part_a_signatory_type text,
    part_b_executed boolean not null default false,
    part_b_expert_designation text,
    declared_hash_algorithm text not null check (declared_hash_algorithm in ('SHA256', 'SHA1', 'MD5', 'NONE')),
    declared_hash_value text,
    is_hash_valid_alphanumeric boolean not null default false,
    contemporaneous_acquisition boolean not null default true,
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

alter table public.bsa_electronic_certificates enable row level security;

do $$ begin
    drop policy if exists "Advocates own BSA electronic certificates" on public.bsa_electronic_certificates;
    create policy "Advocates own BSA electronic certificates"
        on public.bsa_electronic_certificates for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 017: MEDICO-LEGAL AUTOPSY/MLC VS. OCULAR DISCREPANCY MATRIX
-- ----------------------------------------------------------------------------
create table if not exists public.medico_legal_matrices (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    post_mortem_report_number text not null,
    autopsy_doctor_name text,
    hospital_name text,
    autopsy_timestamp timestamp with time zone not null,
    injuries_extracted jsonb not null default '[]'::jsonb,
    stomach_contents_analysis text,
    rigor_mortis_state text,
    estimated_pmi_hours_range numeric[] not null default array[24.0, 36.0]::numeric[],
    witness_ocular_allegations jsonb not null default '[]'::jsonb,
    has_fatal_conflict boolean not null default false,
    irreconcilable_conflicts jsonb not null default '[]'::jsonb,
    cross_examination_questions text[] default array[]::text[],
    written_medical_argument_draft text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_medico_matrix_case on public.medico_legal_matrices(case_id);
create index if not exists idx_medico_matrix_advocate on public.medico_legal_matrices(advocate_id);

alter table public.medico_legal_matrices enable row level security;

do $$ begin
    drop policy if exists "Advocates have exclusive access to own medico-legal matrices" on public.medico_legal_matrices;
    create policy "Advocates have exclusive access to own medico-legal matrices"
        on public.medico_legal_matrices for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 018: MALKHANA CHAIN OF CUSTODY & FSL DISPATCH INTEGRITY AUDITOR
-- ----------------------------------------------------------------------------
create table if not exists public.malkhana_custody_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    act_type text not null default 'NDPS' check (act_type in ('NDPS', 'ARMS_ACT', 'BNS_IPC_FORENSICS', 'EXCISE_ACT')),
    seizure_date timestamp with time zone not null,
    seizure_seal_impression text not null,
    malkhana_deposit_date timestamp with time zone not null,
    malkhana_register_number text not null,
    specimen_seal_deposited boolean not null default false,
    gd_deposit_entry_number text,
    fsl_dispatch_date timestamp with time zone not null,
    fsl_received_date timestamp with time zone not null,
    fsl_receipt_seal_impression text not null,
    road_certificate_annexed boolean not null default false,
    road_certificate_number text,
    carrier_constable_name text,
    fsl_dispatch_delay_days integer not null default 0,
    is_chain_of_custody_intact boolean not null default false,
    has_fatal_tampering_risk boolean not null default false,
    fatal_vulnerabilities jsonb not null default '[]'::jsonb,
    application_sec_254_bnss_draft text not null,
    cross_examination_carrier_questions text[] default array[]::text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_malkhana_audit_case on public.malkhana_custody_audits(case_id);
create index if not exists idx_malkhana_audit_advocate on public.malkhana_custody_audits(advocate_id);

alter table public.malkhana_custody_audits enable row level security;

do $$ begin
    drop policy if exists "Advocates own malkhana chain custody records" on public.malkhana_custody_audits;
    create policy "Advocates own malkhana chain custody records"
        on public.malkhana_custody_audits for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 019: WITNESS CONTRADICTION & OMISSION GRID
-- ----------------------------------------------------------------------------
create table if not exists public.witness_contradiction_grids (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    witness_code text not null,
    witness_name text not null,
    witness_role text not null default 'EYEWITNESS',
    fir_narrative text,
    sec_161_crpc_statement text not null,
    sec_164_crpc_statement text,
    court_deposition_chief text not null,
    has_fatal_contradictions boolean not null default false,
    contradictions_grid jsonb not null default '[]'::jsonb,
    marked_exhibits jsonb not null default '[]'::jsonb,
    io_cross_examination_reminders text[] default array[]::text[],
    confrontation_script_hindi text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_witness_grid_case on public.witness_contradiction_grids(case_id);
create index if not exists idx_witness_grid_advocate on public.witness_contradiction_grids(advocate_id);

alter table public.witness_contradiction_grids enable row level security;

do $$ begin
    drop policy if exists "Advocates own witness contradiction grids" on public.witness_contradiction_grids;
    create policy "Advocates own witness contradiction grids"
        on public.witness_contradiction_grids for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 020: HOSTILE WITNESS & LEADING QUESTION TREES
-- ----------------------------------------------------------------------------
create table if not exists public.hostile_witness_question_trees (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    witness_name text not null,
    witness_role text not null default 'PANCH_WITNESS_SEIZURE',
    defense_theory text not null check (defense_theory in (
        'PLANTED_RECOVERY_STOCK_WITNESS',
        'ALIBI_AND_ABSENCE',
        'CONSENSUAL_RELATION_SEC_69_BNS',
        'MISTAKEN_IDENTITY_TIP_FAILURE'
    )),
    case_facts jsonb not null default '{}'::jsonb,
    questionnaire_strategy_hindi text not null,
    question_trees jsonb not null default '[]'::jsonb,
    trial_tactics_summary_hindi text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_witness_questions_case on public.hostile_witness_question_trees(case_id);
create index if not exists idx_witness_questions_advocate on public.hostile_witness_question_trees(advocate_id);

alter table public.hostile_witness_question_trees enable row level security;

do $$ begin
    drop policy if exists "Advocates own hostile witness question trees" on public.hostile_witness_question_trees;
    create policy "Advocates own hostile witness question trees"
        on public.hostile_witness_question_trees for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 021: UP GANGSTERS RULES 2021 & GOONDAS ACT DEFENSE SUITE
-- ----------------------------------------------------------------------------
create table if not exists public.regional_special_acts_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    statute_applied text not null check (statute_applied in (
        'UP_GANGSTERS_ACT_1986',
        'UP_GOONDAS_ACT_1970',
        'ARMS_ACT_1959'
    )),
    district text not null,
    police_station text not null,
    gang_chart_number text,
    joint_meeting_rule_5_documented boolean not null default false,
    dm_independent_mind_applied boolean not null default false,
    dm_endorsement_raw_text text,
    predicate_base_cases jsonb not null default '[]'::jsonb,
    is_farhana_doctrine_applicable boolean not null default false,
    goondas_notice_has_material_allegations boolean not null default true,
    goondas_notice_only_lists_firs boolean not null default false,
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

alter table public.regional_special_acts_audits enable row level security;

do $$ begin
    drop policy if exists "Advocates own regional special acts audits" on public.regional_special_acts_audits;
    create policy "Advocates own regional special acts audits"
        on public.regional_special_acts_audits for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));
end $$;

-- ----------------------------------------------------------------------------
-- 022: TACTICAL COURTROOM SUITE, SURETY SCRUTINY & JUDICIAL ANALYTICS
-- ----------------------------------------------------------------------------
create table if not exists public.courtroom_surety_audits (
    id uuid primary key default gen_random_uuid(),
    case_id uuid not null unique references public.cases(id) on delete cascade,
    advocate_id text not null references public.advocate_profiles(id) on delete cascade,
    imposed_bond_amount_inr numeric(12, 2) not null,
    is_local_surety_demanded boolean not null default false,
    is_revenue_record_khatauni_demanded boolean not null default false,
    out_of_district_surety_rejected boolean not null default false,
    accused_financial_indigence boolean not null default false,
    is_condition_onerous boolean not null default false,
    moti_ram_violation_reasons text[] default array[]::text[],
    modification_petition_draft text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists public.judicial_bench_analytics (
    id uuid primary key default gen_random_uuid(),
    judge_identifier text not null unique,
    court_establishment text not null,
    district text not null,
    designation text not null,
    disposal_metrics jsonb not null default '{
        "ndps_commercial_grant_rate_percent": 18.4,
        "pocso_grant_rate_percent": 22.1,
        "murder_302_103_grant_rate_percent": 14.5,
        "average_bail_hearing_turnaround_days": 12.4
    }'::jsonb,
    favorable_procedural_levers text[] default array[
        'Section 52A BNSS Magistrate inventory non-compliance',
        'Absence of independent local search witnesses (Sec 103 BNSS)',
        'Arnesh Kumar Sec 35 BNSS notice violations'
    ]::text[],
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_surety_audits_case on public.courtroom_surety_audits(case_id);
create index if not exists idx_surety_audits_advocate on public.courtroom_surety_audits(advocate_id);
create index if not exists idx_judge_analytics_code on public.judicial_bench_analytics(judge_identifier);

alter table public.courtroom_surety_audits enable row level security;
alter table public.judicial_bench_analytics enable row level security;

do $$ begin
    drop policy if exists "Advocates own surety audits" on public.courtroom_surety_audits;
    create policy "Advocates own surety audits"
        on public.courtroom_surety_audits for all
        using (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'))
        with check (advocate_id = auth.uid()::text or advocate_id = (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'));

    drop policy if exists "Verified advocates can view judicial analytics" on public.judicial_bench_analytics;
    create policy "Verified advocates can view judicial analytics"
        on public.judicial_bench_analytics for select
        using (true);
end $$;
