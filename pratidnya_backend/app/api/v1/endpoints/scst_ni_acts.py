from fastapi import APIRouter, HTTPException, Security
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.scst_and_ni_schema import (
    ScstAuditRequest,
    ScstComplianceEvaluation,
    NiActAuditRequest,
    NiActComplianceEvaluation
)
from app.services.scst_compliance_engine import ScstComplianceEngine
from app.services.ni_act_compliance_engine import NiActComplianceEngine

router = APIRouter(prefix="/specialized-acts", tags=["Specialized Acts: SC/ST & NI Act 138"])

@router.post("/scst/evaluate", response_model=ScstComplianceEvaluation)
async def evaluate_scst_endpoint(
    payload: ScstAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Evaluates SC/ST (PoA) Act cases for Section 18/18A anticipatory bail bar bypassability
    (Hitesh Verma public view test), Section 14A High Court Appeal limitation, and Section 15A victim notice.
    """
    advocate_id = current_user["uid"]
    evaluation = ScstComplianceEngine.evaluate(payload)

    # Persist in Supabase scst_case_audits table
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "atrocity_sections": payload.atrocity_sections,
        "incident_place_type": payload.incident_place_type,
        "independent_public_witnesses_present": payload.independent_public_witnesses_present,
        "allegation_of_caste_name_used": payload.allegation_of_caste_name_used,
        "prior_land_or_civil_dispute_existing": payload.prior_land_or_civil_dispute_existing,
        "prima_facie_case_disclosed": not evaluation.is_anticipatory_bail_maintainable,
        "anticipatory_bail_maintainable": evaluation.is_anticipatory_bail_maintainable,
        "special_court_order_date": payload.special_court_order_date.isoformat() if payload.special_court_order_date else None,
        "is_section_14a_appeal": payload.special_court_order_date is not None,
        "is_within_statutory_limitation": evaluation.section_14a_appeal_limitation_status != "BARRED_BEYOND_180_DAYS",
        "victim_notice_served_sec_15a": payload.victim_notice_served
    }
    supabase.table("scst_case_audits").upsert(record, on_conflict="case_id").execute()

    return evaluation

@router.post("/ni-act/evaluate", response_model=NiActComplianceEvaluation)
async def evaluate_ni_act_endpoint(
    payload: NiActAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Audits NI Act Section 138 statutory notices and complaints for fatal defects
    (premature complaints under Yogendra Pratap Singh, omnibus demands under K.R. Indira),
    and structures Section 139 presumption rebuttal and Section 147 compounding.
    """
    advocate_id = current_user["uid"]
    evaluation = NiActComplianceEngine.evaluate(payload)

    # Persist in Supabase ni_act_notice_audits table
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "cheque_number": payload.cheque_number,
        "cheque_amount": payload.cheque_amount,
        "cheque_date": payload.cheque_date.isoformat(),
        "bank_return_memo_date": payload.bank_return_memo_date.isoformat(),
        "dishonour_reason": payload.dishonour_reason,
        "demand_notice_dispatch_date": payload.demand_notice_dispatch_date.isoformat(),
        "notice_dispatch_within_30_days": evaluation.dispatch_within_30_days,
        "demand_notice_delivery_date": payload.demand_notice_delivery_date.isoformat(),
        "is_omnibus_demand_defective": payload.is_omnibus_demand_defective,
        "cure_period_15_days_expiry_date": evaluation.cure_period_15_days_expiry_date.isoformat(),
        "complaint_filing_date": payload.complaint_filing_date.isoformat(),
        "is_premature_complaint": evaluation.is_premature_complaint,
        "is_time_barred_complaint": evaluation.is_time_barred,
        "defense_category": payload.defense_category,
        "seeks_compounding_under_sec_147": payload.seeks_compounding
    }
    supabase.table("ni_act_notice_audits").upsert(record, on_conflict="case_id").execute()

    return evaluation
