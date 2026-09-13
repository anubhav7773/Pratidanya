from datetime import datetime, timezone
import logging
from fastapi import APIRouter, HTTPException, Security, status
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.electronic_evidence_schema import (
    ElectronicEvidenceAuditRequest,
    ElectronicEvidenceAuditResponse
)
from app.services.electronic_evidence_engine import ElectronicEvidenceEngine

logger = logging.getLogger("pratidnya.evidence")

router = APIRouter(prefix="/evidence", tags=["Evidence & Forensic Auditing (Pillar B)"])

@router.post("/audit-bsa-certificate", response_model=ElectronicEvidenceAuditResponse)
async def audit_bsa_certificate_endpoint(
    payload: ElectronicEvidenceAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Pillar B, Module 4: Audits Electronic Evidence Certificates under Section 63 BSA 2023 / Section 65B IEA.
    Validates Schedule Part A & B, cryptographic hash algorithms, and hardware identifiers.
    Persists audit records in Supabase and outputs ready-to-file Devanagari written objections.
    """
    advocate_id = current_user["uid"]

    # 1. Deterministic Legal & Cryptographic Audit
    evaluation = ElectronicEvidenceEngine.audit_certificate(payload)

    # 2. Persist in Supabase bsa_electronic_certificates
    supabase = get_supabase_admin_client()
    dev = payload.device_identifiers

    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "exhibit_mark": payload.exhibit_mark,
        "evidence_type": payload.evidence_type,
        "device_type": payload.device_identifiers.make_model or "ELECTRONIC_DEVICE",
        "device_make_model": dev.make_model,
        "device_serial_number": dev.serial_number,
        "device_imei_mac": dev.imei_number or dev.mac_address,
        "is_schedule_format_matched": payload.schedule_format_matched,
        "part_a_executed": payload.part_a_executed,
        "part_a_signatory_type": payload.part_a_signatory_type,
        "part_b_executed": payload.part_b_executed,
        "part_b_expert_designation": payload.part_b_expert_designation,
        "declared_hash_algorithm": payload.hash_algorithm,
        "declared_hash_value": payload.declared_hash_value,
        "is_hash_valid_alphanumeric": evaluation.is_hash_valid,
        "contemporaneous_acquisition": payload.contemporaneous_acquisition,
        "admissibility_status": evaluation.admissibility_status,
        "statutory_defects": [d.defect_description_hindi for d in evaluation.statutory_defects],
        "written_objection_draft": evaluation.written_objection_petition_draft,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("bsa_electronic_certificates").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist BSA electronic certificate: {e}")

    return evaluation
