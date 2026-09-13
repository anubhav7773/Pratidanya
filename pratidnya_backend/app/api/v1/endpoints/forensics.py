from datetime import datetime, timezone
import logging
from fastapi import APIRouter, HTTPException, Security, status
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.forensic_medical_schema import (
    MedicalMatrixAuditRequest,
    MedicalMatrixAuditResponse
)
from app.services.medico_legal_engine import MedicoLegalEngine
from app.schemas.malkhana_schema import (
    MalkhanaAuditRequest,
    MalkhanaAuditResponse
)
from app.services.malkhana_engine import MalkhanaEngine

logger = logging.getLogger("pratidnya.forensics")

router = APIRouter(prefix="/forensics", tags=["Forensic & Medico-Legal Auditing (Pillar B)"])

@router.post("/generate-medical-matrix", response_model=MedicalMatrixAuditResponse)
async def generate_medical_matrix_endpoint(
    payload: MedicalMatrixAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Pillar B, Module 5: Cross-references Post-Mortem / MLC clinical findings
    against ocular eyewitness claims. Detects wound morphology inconsistencies,
    post-mortem interval (PMI) discrepancies, and generates cross-examination questions.
    """
    advocate_id = current_user["uid"]

    # 1. Deterministic Medico-Legal Biomechanical Audit
    evaluation = MedicoLegalEngine.audit_medico_legal(payload)

    # 2. Persist in Supabase medico_legal_matrices
    supabase = get_supabase_admin_client()
    pm = payload.post_mortem_data

    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "post_mortem_report_number": pm.pmr_number,
        "autopsy_doctor_name": pm.autopsy_doctor_name,
        "hospital_name": pm.hospital_name,
        "autopsy_timestamp": pm.autopsy_timestamp.isoformat(),
        "injuries_extracted": [inj.model_dump() for inj in pm.external_injuries],
        "stomach_contents_analysis": pm.stomach_contents,
        "rigor_mortis_state": pm.rigor_mortis_state,
        "estimated_pmi_hours_range": [pm.estimated_time_since_death_hours_min, pm.estimated_time_since_death_hours_max],
        "witness_ocular_allegations": [w.model_dump(mode="json") for w in payload.ocular_allegations],
        "has_fatal_conflict": evaluation.has_fatal_conflict,
        "irreconcilable_conflicts": [c.model_dump() for c in evaluation.irreconcilable_conflicts],
        "cross_examination_questions": evaluation.cross_examination_crossfire_questions,
        "written_medical_argument_draft": evaluation.written_medical_argument_draft_hindi,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("medico_legal_matrices").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist medico-legal matrix: {e}")

    return evaluation


@router.post("/audit-malkhana-chain", response_model=MalkhanaAuditResponse)
async def audit_malkhana_chain_endpoint(
    payload: MalkhanaAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Pillar B, Module 6: Audits Malkhana Register No. 19 entries, 72-hour FSL dispatch timelines,
    Namuna Mohar specimen seal preservation, and Road Certificate tracking.
    Persists findings to malkhana_custody_audits and generates Section 254 BNSS record summoning applications.
    """
    advocate_id = current_user["uid"]

    # 1. Deterministic Custody Chain Evaluation
    evaluation = MalkhanaEngine.audit_malkhana_chain(payload)

    # 2. Persist in Supabase malkhana_custody_audits
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "act_type": payload.act_type,
        "seizure_date": payload.seizure_date.isoformat(),
        "seizure_seal_impression": payload.seizure_seal_impression,
        "malkhana_deposit_date": payload.malkhana_deposit_date.isoformat(),
        "malkhana_register_number": payload.malkhana_register_number,
        "specimen_seal_deposited": payload.specimen_seal_deposited,
        "gd_deposit_entry_number": payload.gd_deposit_entry_number,
        "fsl_dispatch_date": payload.fsl_dispatch_date.isoformat(),
        "fsl_received_date": payload.fsl_received_date.isoformat(),
        "fsl_receipt_seal_impression": payload.fsl_receipt_seal_impression,
        "road_certificate_annexed": payload.road_certificate_annexed,
        "road_certificate_number": payload.road_certificate_number,
        "carrier_constable_name": payload.carrier_constable_name,
        "fsl_dispatch_delay_days": evaluation.fsl_dispatch_delay_days,
        "is_chain_of_custody_intact": evaluation.is_chain_of_custody_intact,
        "has_fatal_tampering_risk": evaluation.has_fatal_tampering_risk,
        "fatal_vulnerabilities": [v.model_dump() for v in evaluation.fatal_vulnerabilities],
        "application_sec_254_bnss_draft": evaluation.application_sec_254_bnss_draft_hindi,
        "cross_examination_carrier_questions": evaluation.cross_examination_carrier_questions,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("malkhana_custody_audits").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist malkhana custody audit: {e}")

    return evaluation

