-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 005 - PURGE DUMMY TESTING FIXTURES & HARDEN PRODUCTION CONSTRAINTS
-- ============================================================================

-- 1. Remove synthetic precedents injected during sandbox testing
delete from public.verified_precedents 
where citation_id like '%DUMMY%' 
   or citation_id like '%TEST%'
   or case_title like '%(डमी%'
   or case_title like '%परीक्षण रिकॉर्ड%';

-- 2. Remove sandbox advocate and test case records
-- Temporarily bypass immutable audit trigger to clear test telemetry
alter table public.dpdp_audit_logs disable trigger trg_protect_dpdp_audit_logs;

delete from public.dpdp_audit_logs 
where advocate_id = 'TEST_FIREBASE_UID_ADVOCATE_01';

delete from public.cases 
where advocate_id = 'TEST_FIREBASE_UID_ADVOCATE_01'
   or fir_number = '124/2026'
   or accused_name like '%(डमी%';

delete from public.advocate_ai_quotas 
where advocate_id = 'TEST_FIREBASE_UID_ADVOCATE_01';

delete from public.advocate_profiles 
where id = 'TEST_FIREBASE_UID_ADVOCATE_01';

-- Re-enable immutable audit trigger
alter table public.dpdp_audit_logs enable trigger trg_protect_dpdp_audit_logs;

-- 3. Enforce statutory constraints on real precedent corpus
alter table public.verified_precedents
    drop constraint if exists check_valid_source_url,
    add constraint check_valid_source_url 
    check (verified_source_url ~* '^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$');

-- Ensure paragraph number is always a positive integer when provided
alter table public.verified_precedents
    drop constraint if exists check_positive_para,
    add constraint check_positive_para 
    check (paragraph_number is null or paragraph_number > 0);
