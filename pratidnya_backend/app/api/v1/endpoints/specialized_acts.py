from fastapi import APIRouter, HTTPException, Security
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.specialized_acts_schema import (
    NdpsAuditRequest,
    NdpsComplianceEvaluation,
    PocsoAgeAuditRequest,
    PocsoAgeEvaluation
)
from app.services.ndps_compliance_engine import NdpsComplianceEngine
from app.services.pocso_age_engine import PocsoAgeEngine

router = APIRouter(prefix="/specialized-acts", tags=["Specialized Criminal Acts (NDPS & POCSO)"])

@router.post("/ndps/evaluate", response_model=NdpsComplianceEvaluation)
async def evaluate_ndps_compliance_endpoint(
    payload: NdpsAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Evaluates NDPS search and seizure for Section 50 mandatory personal search defects,
    commercial vs. intermediate quantity classification, Section 37 bypassability,
    and Section 52A magistrate sampling compliance.
    """
    advocate_id = current_user["uid"]
    evaluation = NdpsComplianceEngine.evaluate(payload)

    # Persist in Supabase ndps_seizure_audits table
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "substance_name": payload.substance_name,
        "recovered_quantity_grams": payload.recovered_quantity_grams,
        "quantity_category": evaluation.quantity_category,
        "is_section_37_bar_applicable": evaluation.is_section_37_bar_applicable,
        "is_personal_search": payload.is_personal_search,
        "section_50_notice_given": payload.section_50_notice_given,
        "section_50_notice_type": payload.section_50_notice_type,
        "was_searched_before_gazetted_officer": payload.was_searched_before_gazetted_officer,
        "was_searched_before_magistrate": payload.was_searched_before_magistrate,
        "third_option_defect_present": payload.third_option_defect_present,
        "information_recorded_in_writing": payload.information_recorded_in_writing,
        "information_sent_to_superior_within_72h": payload.information_sent_to_superior_within_72h,
        "independent_public_witnesses_present": payload.independent_public_witnesses_present,
        "sample_drawn_before_magistrate_sec_52a": payload.sample_drawn_before_magistrate_sec_52a,
        "malkhana_entry_delay_days": payload.malkhana_entry_delay_days,
        "fsl_dispatch_delay_days": payload.fsl_dispatch_delay_days
    }
    supabase.table("ndps_seizure_audits").upsert(record, on_conflict="case_id").execute()

    return evaluation

@router.post("/pocso/evaluate-age", response_model=PocsoAgeEvaluation)
async def evaluate_pocso_age_endpoint(
    payload: PocsoAgeAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Evaluates victim age determination under Section 94 Juvenile Justice Act hierarchy
    (Matriculation > Municipal Certificate > Ossification Test with 2-year margin of error),
    and generates rebuttal points for POCSO Sections 29/30 statutory presumptions.
    """
    advocate_id = current_user["uid"]
    evaluation = PocsoAgeEngine.evaluate(payload)

    # Persist in Supabase pocso_age_audits table
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "alleged_incident_date": payload.alleged_incident_date.isoformat(),
        "fir_stated_age_years": payload.fir_stated_age_years,
        "has_first_attended_school_certificate": payload.has_first_attended_school_certificate,
        "school_dob": payload.school_dob.isoformat() if payload.school_dob else None,
        "has_matriculation_certificate": payload.has_matriculation_certificate,
        "matriculation_dob": payload.matriculation_dob.isoformat() if payload.matriculation_dob else None,
        "has_municipal_birth_certificate": payload.has_municipal_birth_certificate,
        "municipal_dob": payload.municipal_dob.isoformat() if payload.municipal_dob else None,
        "ossification_test_conducted": payload.ossification_test_conducted,
        "radiological_age_lower": payload.radiological_age_lower,
        "radiological_age_upper": payload.radiological_age_upper,
        "two_year_margin_benefit_applied": payload.two_year_margin_benefit_applied,
        "computed_majority_probable": evaluation.is_majority_probable,
        "evidence_of_prior_romantic_relationship": payload.evidence_of_prior_romantic_relationship,
        "unexplained_delay_in_fir_days": payload.unexplained_delay_in_fir_days,
        "no_external_or_internal_injuries": payload.no_injuries_found
    }
    supabase.table("pocso_age_audits").upsert(record, on_conflict="case_id").execute()

    return evaluation
