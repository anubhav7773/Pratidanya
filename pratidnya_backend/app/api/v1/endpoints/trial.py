import logging
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Security, status
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.witness_impeachment_schema import (
    WitnessImpeachmentAuditRequest,
    WitnessImpeachmentAuditResponse
)
from app.services.witness_impeachment_engine import WitnessImpeachmentEngine
from app.schemas.leading_question_schema import (
    LeadingQuestionRequest,
    LeadingQuestionResponse
)
from app.services.leading_question_engine import LeadingQuestionEngine

logger = logging.getLogger("pratidnya.trial")


router = APIRouter(prefix="/trial", tags=["Trial Strategy & Witness Impeachment Engine (Pillar C)"])

@router.post("/generate-contradiction-grid", response_model=WitnessImpeachmentAuditResponse)
async def generate_contradiction_grid_endpoint(
    payload: WitnessImpeachmentAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Pillar C, Module 7: Evaluates contradictions and material omissions between
    Section 161 CrPC (Police), Section 164 CrPC (Magistrate), and in-court chief depositions.
    Applies Tahsildar Singh v. State of U.P. (1959) and V.K. Mishra (2015) mechanics.
    """
    advocate_id = current_user["uid"]

    # 1. Deterministic Witness Impeachment Evaluation
    evaluation = WitnessImpeachmentEngine.audit_witness_testimony(payload)

    # 2. Persist in Supabase witness_contradiction_grids
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "witness_code": payload.witness_code,
        "witness_name": payload.witness_name,
        "witness_role": payload.witness_role,
        "fir_narrative": payload.fir_narrative,
        "sec_161_crpc_statement": payload.sec_161_crpc_statement,
        "sec_164_crpc_statement": payload.sec_164_crpc_statement,
        "court_deposition_chief": payload.court_deposition_chief,
        "has_fatal_contradictions": evaluation.has_fatal_contradictions,
        "contradictions_grid": [item.model_dump() for item in evaluation.grid_analysis],
        "marked_exhibits": evaluation.marked_exhibits_summary,
        "io_cross_examination_reminders": evaluation.io_cross_examination_reminders,
        "confrontation_script_hindi": evaluation.confrontation_master_script_hindi,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("witness_contradiction_grids").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist witness contradiction grid: {e}")

    return evaluation


@router.post("/generate-cross-questions", response_model=LeadingQuestionResponse)
async def generate_cross_questions_endpoint(
    payload: LeadingQuestionRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Pillar C, Module 8: Hostile Witness & Leading Question Tree Generator under Section 147 BSA / Section 143 IEA.
    Builds sequenced binary (Yes/No) decision trees with trap mitigations and documentary pivots
    across specific defense theories (Planted recovery/stock witness, Alibi, Consensual relation under Sec 69 BNS, and TIP failure).
    """
    advocate_id = current_user["uid"]

    # 1. Deterministic Leading Question Tree Generation
    evaluation = LeadingQuestionEngine.generate_question_trees(payload)

    # 2. Persist in Supabase hostile_witness_question_trees
    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "witness_name": payload.witness_name,
        "witness_role": payload.witness_role,
        "defense_theory": payload.defense_theory,
        "case_facts": payload.case_facts,
        "questionnaire_strategy_hindi": evaluation.questionnaire_strategy_hindi,
        "question_trees": [q.model_dump() for q in evaluation.question_trees],
        "trial_tactics_summary_hindi": evaluation.trial_tactics_summary_hindi,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }

    try:
        supabase.table("hostile_witness_question_trees").upsert(record, on_conflict="case_id").execute()
    except Exception as e:
        logger.warning(f"Could not persist hostile witness question trees: {e}")

    return evaluation

