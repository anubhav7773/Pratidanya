-- ============================================================================
-- PRATIDNYA LEGAL TECH (ASIVERTICALS)
-- MIGRATION: 010 - DPDP ACT 2023 STATUTORY EXPORT & SELF-SERVICE ERASURE
-- STATUTORY COMPLIANCE: DPDP Act 2023 Sections 8(7), 11, 12 & 13
-- ============================================================================

-- Ensure dpdp_audit_logs is not constrained to cascade-delete with advocate profile
alter table if exists public.dpdp_audit_logs drop constraint if exists dpdp_audit_logs_advocate_id_fkey;

-- Function: Generate complete chamber export bundle for an advocate (Right to Access - Sec 11)
create or replace function export_advocate_chamber_data(target_advocate_id text)
returns jsonb
language plpgsql
security definer
as $$
declare
    v_profile jsonb;
    v_cases jsonb;
    v_proceedings jsonb;
    v_high_court jsonb;
    v_ndps_audits jsonb;
    v_pocso_audits jsonb;
    v_audit_trail jsonb;
    v_result jsonb;
begin
    -- Verify caller matches target_advocate_id or has service_role
    if (auth.uid()::text != target_advocate_id and current_user != 'service_role') then
        raise exception 'गोपनीयता सुरक्षा उल्लंघन: अनधिकृत डेटा एक्सेस प्रतिबंधित है।';
    end if;

    -- 1. Profile Data
    select to_jsonb(p) into v_profile
    from public.advocate_profiles p
    where p.id = target_advocate_id;

    -- 2. Criminal Cases Docket
    select coalesce(jsonb_agg(to_jsonb(c)), '[]'::jsonb) into v_cases
    from public.cases c
    where c.advocate_id = target_advocate_id;

    -- 3. Court Proceedings Log
    select coalesce(jsonb_agg(to_jsonb(pr)), '[]'::jsonb) into v_proceedings
    from public.case_proceedings pr
    where pr.advocate_id = target_advocate_id;

    -- 4. High Court Appellate Pleadings
    select coalesce(jsonb_agg(to_jsonb(hc)), '[]'::jsonb) into v_high_court
    from public.high_court_pleadings hc
    where hc.advocate_id = target_advocate_id;

    -- 5. Specialized Audits (NDPS & POCSO)
    select coalesce(jsonb_agg(to_jsonb(n)), '[]'::jsonb) into v_ndps_audits
    from public.ndps_seizure_audits n
    where n.advocate_id = target_advocate_id;

    select coalesce(jsonb_agg(to_jsonb(pc)), '[]'::jsonb) into v_pocso_audits
    from public.pocso_age_audits pc
    where pc.advocate_id = target_advocate_id;

    -- 6. Immutable DPDP Audit Trail
    select coalesce(jsonb_agg(to_jsonb(a)), '[]'::jsonb) into v_audit_trail
    from public.dpdp_audit_logs a
    where a.advocate_id = target_advocate_id;

    -- Compile Unified Bundle
    v_result := jsonb_build_object(
        'export_timestamp', timezone('utc'::text, now()),
        'compliance_standard', 'DPDP_ACT_2023_SEC_11',
        'advocate_profile', v_profile,
        'cases', v_cases,
        'proceedings', v_proceedings,
        'high_court_pleadings', v_high_court,
        'ndps_audits', v_ndps_audits,
        'pocso_audits', v_pocso_audits,
        'statutory_audit_logs', v_audit_trail
    );

    -- Log the export event immutably
    insert into public.dpdp_audit_logs (advocate_id, action_type, metadata)
    values (
        target_advocate_id,
        'STATUTORY_DATA_EXPORT_GENERATED',
        jsonb_build_object('total_cases', jsonb_array_length(v_cases), 'generated_at', timezone('utc'::text, now()))
    );

    return v_result;
end;
$$;

-- Function: Execute Right to Erasure / Chamber Deletion (Sec 8(7) DPDP Act)
create or replace function execute_complete_advocate_erasure(target_advocate_id text)
returns boolean
language plpgsql
security definer
as $$
begin
    if (auth.uid()::text != target_advocate_id and current_user != 'service_role') then
        raise exception 'अनाधिकृत विलोपन अनुरोध: केवल खाता धारक डेटा विलोपन निष्पादित कर सकता है।';
    end if;

    -- Log final erasure event before cascading delete
    insert into public.dpdp_audit_logs (advocate_id, action_type, metadata)
    values (
        target_advocate_id,
        'ACCOUNT_AND_CHAMBER_RIGHT_TO_ERASURE_EXECUTED',
        jsonb_build_object(
            'erasure_statute', 'DPDP Act 2023 Section 8(7)',
            'timestamp', timezone('utc'::text, now())
        )
    );

    -- Cascading hard delete triggered from advocate_profiles
    delete from public.cases where advocate_id = target_advocate_id;
    delete from public.high_court_pleadings where advocate_id = target_advocate_id;
    delete from public.case_document_embeddings where advocate_id = target_advocate_id;
    delete from public.advocate_ai_quotas where advocate_id = target_advocate_id;
    delete from public.voice_dictation_sessions where advocate_id = target_advocate_id;
    delete from public.scst_case_audits where advocate_id = target_advocate_id;
    delete from public.ni_act_notice_audits where advocate_id = target_advocate_id;
    delete from public.ndps_seizure_audits where advocate_id = target_advocate_id;
    delete from public.pocso_age_audits where advocate_id = target_advocate_id;
    delete from public.advocate_profiles where id = target_advocate_id;

    return true;
end;
$$;
