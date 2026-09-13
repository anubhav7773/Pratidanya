from datetime import datetime, timezone
import logging
from fastapi import APIRouter, HTTPException, Security, status
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.remand_schema import DefaultBailAuditRequest, DefaultBailAuditResponse
from app.services.default_bail_engine import DefaultBailEngine

logger = logging.getLogger("pratidnya.remand")

router = APIRouter(prefix="/remand", tags=["Pre-Trial Remand & Default Bail Defense (Pillar A)"])

@router.post("/audit-default-bail", response_model=DefaultBailAuditResponse)
async def audit_default_bail_endpoint(
    payload: DefaultBailAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Evaluates Section 167(2) CrPC / Section 187 BNSS default bail thresholds,
    tracks Section 187 split police custody quotas, inspects chargesheets for
    missing forensic annexures under Kapil Wadhawan, and returns a verified Devanagari petition.
    """
    advocate_id = current_user["uid"]
    
    # 1. Compute Deterministic Statutory Audit
    evaluation = DefaultBailEngine.audit_default_bail(payload)

    # 2. Persist in Supabase remand_custody_ledger
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "first_remand_date": payload.first_remand_date.isoformat(),
        "statutory_regime": payload.statutory_regime,
        "statutory_threshold_days": evaluation.statutory_threshold_days,
        "days_elapsed_in_custody": evaluation.days_elapsed_in_custody,
        "is_default_bail_crystallized": evaluation.is_default_bail_crystallized,
        "default_bail_accrual_timestamp": evaluation.default_bail_accrual_timestamp.isoformat(),
        "police_custody_days_used": evaluation.police_custody_days_used,
        "police_custody_days_remaining": evaluation.police_custody_days_remaining,
        "police_custody_window_expired": evaluation.police_custody_window_expired,
        "chargesheet_filed": payload.chargesheet_filed,
        "chargesheet_filing_date": payload.chargesheet_filing_date.isoformat() if payload.chargesheet_filing_date else None,
        "is_chargesheet_incomplete": evaluation.is_chargesheet_incomplete,
        "defect_classification": evaluation.defect_type,
        "missing_mandatory_reports": evaluation.missing_mandatory_reports,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("remand_custody_ledger").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist remand custody ledger: {e}")

    return evaluation

@router.get("/case/{case_id}/custody-status")
async def get_case_custody_status(
    case_id: str,
    current_user: dict = Security(verify_advocate_token)
):
    """Fetches real-time remand and default bail countdown status for an active docket."""
    advocate_id = current_user["uid"]
    supabase = get_supabase_admin_client()

    res = supabase.table("remand_custody_ledger") \
        .select("*") \
        .eq("case_id", case_id) \
        .eq("advocate_id", advocate_id) \
        .maybe_single() \
        .execute()

    if not res or not res.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="इस वाद हेतु कोई रिमांड रिकॉर्ड उपलब्ध नहीं है।"
        )

    return res.data

from app.schemas.arrest_compliance_schema import (
    ArrestComplianceAuditRequest,
    ArrestComplianceAuditResponse
)
from app.services.arrest_compliance_engine import ArrestComplianceEngine

@router.post("/audit-arrest-compliance", response_model=ArrestComplianceAuditResponse)
async def audit_arrest_compliance_endpoint(
    payload: ArrestComplianceAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Audits arrest and police remand records against Section 35 BNSS, Section 41A CrPC,
    Arnesh Kumar, and Satender Kumar Antil (Category A-D) guidelines.
    Persists findings to arrest_remand_audits and outputs an instant Devanagari objection draft.
    """
    advocate_id = current_user["uid"]

    # 1. Evaluate Deterministic Legal Compliance
    evaluation = ArrestComplianceEngine.audit_arrest(payload)

    # 2. Persist in Supabase arrest_remand_audits
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "offense_sections": [f"{c.act}:{c.section}" for c in payload.charges],
        "max_punishment_years": max((c.max_punishment_years for c in payload.charges), default=3),
        "antil_category": evaluation.antil_category,
        "notice_issued_sec_35_bnss": payload.notice_issued_sec_35_bnss,
        "flight_or_tampering_risk_recorded": payload.flight_or_tampering_risk_recorded,
        "arrest_memo_witness_count": payload.arrest_memo_witness_count,
        "family_intimation_recorded": payload.family_intimation_recorded,
        "medical_examination_conducted": payload.medical_examination_conducted,
        "produced_within_24_hours": not evaluation.is_constitutionally_time_barred,
        "magistrate_independent_reasons_recorded": payload.magistrate_independent_reasons_recorded,
        "compliance_verdict": evaluation.compliance_verdict,
        "fatal_violations": [v.finding_hindi for v in evaluation.violations if v.severity == "FATAL"],
        "magistrate_directive_recommendation": evaluation.magistrate_directive_recommendation,
        "instant_objection_petition_draft": evaluation.instant_objection_petition_draft,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("arrest_remand_audits").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist arrest remand audit: {e}")

    return evaluation

from datetime import date
from app.schemas.undertrial_schema import (
    UndertrialReliefAuditRequest,
    UndertrialReliefAuditResponse
)
from app.services.undertrial_relief_engine import UndertrialReliefEngine

@router.post("/audit-undertrial-relief", response_model=UndertrialReliefAuditResponse)
async def audit_undertrial_relief_endpoint(
    payload: UndertrialReliefAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Pillar A, Module 3: Evaluates Section 479 BNSS / Section 436A CrPC undertrial relief.
    Applies the 1/3rd rule for first-time offenders under Supreme Court Order dt. 23.08.2024
    (Re: Inhuman Conditions in 1382 Prisons), enforces multi-case bars, and outputs dual petitions.
    """
    advocate_id = current_user["uid"]

    # 1. Deterministic Statutory Computation
    evaluation = UndertrialReliefEngine.audit_undertrial_relief(payload)

    # 2. Persist in Supabase undertrial_relief_audits
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "jail_name": payload.jail_name,
        "custody_start_date": payload.custody_start_date.isoformat(),
        "calculation_date": (payload.calculation_date or date.today()).isoformat(),
        "is_first_time_offender": payload.is_first_time_offender,
        "multiple_cases_pending": payload.multiple_cases_pending,
        "max_punishment_months": evaluation.max_prescribed_term_months,
        "statutory_threshold_fraction": "ONE_THIRD" if evaluation.statutory_threshold_fraction == "1/3" else "ONE_HALF",
        "threshold_duration_months": evaluation.threshold_months,
        "actual_detention_served_months": evaluation.actual_detention_served_months,
        "statutory_overstay_months": evaluation.overstay_months,
        "is_relief_applicable": evaluation.is_relief_applicable,
        "is_disqualified": evaluation.is_disqualified,
        "disqualification_reason": evaluation.disqualification_reason,
        "is_retrospective_bnss_applied": True,
        "court_application_draft": evaluation.court_application_draft_hindi,
        "jail_superintendent_notice_draft": evaluation.jail_superintendent_notice_draft_hindi,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("undertrial_relief_audits").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist undertrial relief audit: {e}")

    return evaluation

