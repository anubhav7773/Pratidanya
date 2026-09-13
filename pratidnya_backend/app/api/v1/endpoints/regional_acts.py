import logging
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Security, status
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.regional_acts_schema import (
    RegionalActsAuditRequest,
    RegionalActsAuditResponse
)
from app.services.regional_acts_engine import RegionalActsEngine

logger = logging.getLogger("pratidnya.regional_acts")

router = APIRouter(prefix="/regional", tags=["Regional High-Stakes Defense Suite (Pillar D)"])

@router.post("/audit-up-special-acts", response_model=RegionalActsAuditResponse)
async def audit_up_special_acts_endpoint(
    payload: RegionalActsAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Pillar D, Module 9: Audits UP Gangsters Act 1986 & Rules 2021 (Rules 5, 16, Farhana doctrine)
    and UP Control of Goondas Act 1970 Section 3 notices (Ramji Pandey Full Bench doctrine).
    Generates ready-to-file High Court Article 226 Criminal Misc. Writ Petitions.
    """
    advocate_id = current_user["uid"]

    # 1. Deterministic Legal & Statutory Rules Audit
    evaluation = RegionalActsEngine.audit_regional_act(payload)

    # 2. Persist in Supabase regional_special_acts_audits
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "statute_applied": payload.statute_applied,
        "district": payload.district,
        "police_station": payload.police_station,
        "gang_chart_number": payload.gang_chart_number,
        "joint_meeting_rule_5_documented": payload.joint_meeting_rule_5_documented,
        "dm_independent_mind_applied": payload.dm_independent_mind_applied,
        "dm_endorsement_raw_text": payload.dm_endorsement_raw_text,
        "predicate_base_cases": [c.model_dump() for c in payload.base_cases],
        "is_farhana_doctrine_applicable": evaluation.is_farhana_collapse_triggered,
        "goondas_notice_has_material_allegations": payload.notice_has_material_allegations,
        "goondas_notice_only_lists_firs": payload.notice_only_lists_firs,
        "procedural_viability": evaluation.procedural_viability,
        "grounds_of_challenge": [g.model_dump() for g in evaluation.grounds_of_challenge],
        "recommended_forum": evaluation.recommended_forum,
        "draft_petition_type": evaluation.draft_petition_type,
        "draft_petition_hindi": evaluation.draft_petition_hindi,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("regional_special_acts_audits").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist regional special acts audit: {e}")

    return evaluation
