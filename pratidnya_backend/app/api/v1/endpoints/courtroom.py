from fastapi import APIRouter, HTTPException, Security, status
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.courtroom_tactics_schema import (
    SuretyAuditRequest,
    SuretyAuditResponse,
    EdgeOralPromptRequest,
    EdgeOralPromptResponse,
    JudicialBenchAnalyticsResponse
)
from app.services.courtroom_tactics_engine import CourtroomTacticsEngine

router = APIRouter(prefix="/courtroom", tags=["Tactical Courtroom Suite & Edge Prompter (Pillar E)"])

@router.post("/audit-surety-conditions", response_model=SuretyAuditResponse)
async def audit_surety_conditions_endpoint(
    payload: SuretyAuditRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Audits onerous bail conditions, local surety mandates, and revenue record demands.
    Synthesizes Section 483(2) BNSS / 440(2) CrPC modification petitions under Moti Ram (1978).
    """
    advocate_id = current_user["uid"]
    evaluation = CourtroomTacticsEngine.audit_surety_conditions(payload)

    supabase = get_supabase_admin_client()
    record = {
        "case_id": payload.case_id,
        "advocate_id": advocate_id,
        "imposed_bond_amount_inr": payload.imposed_bond_amount_inr,
        "is_local_surety_demanded": payload.is_local_surety_demanded,
        "is_revenue_record_khatauni_demanded": payload.is_revenue_record_khatauni_demanded,
        "out_of_district_surety_rejected": payload.out_of_district_surety_rejected,
        "accused_financial_indigence": payload.accused_financial_indigence,
        "is_condition_onerous": evaluation.is_condition_onerous,
        "moti_ram_violation_reasons": evaluation.moti_ram_violation_reasons,
        "modification_petition_draft": evaluation.modification_petition_draft_hindi,
        "updated_at": "now()"
    }

    supabase.table("courtroom_surety_audits").upsert(record, on_conflict="case_id").execute()
    return evaluation

@router.post("/edge-oral-prompt", response_model=EdgeOralPromptResponse)
async def edge_oral_prompt_endpoint(
    payload: EdgeOralPromptRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Sub-500ms Edge Oral Prompting Engine for live courtroom defense.
    Matches adversary prosecution submissions against statutory counter-ratios in real-time.
    """
    return CourtroomTacticsEngine.generate_edge_oral_prompt(payload)

@router.get("/judge-analytics/{judge_id}", response_model=JudicialBenchAnalyticsResponse)
async def get_judge_analytics_endpoint(
    judge_id: str,
    current_user: dict = Security(verify_advocate_token)
):
    """Fetches objective judicial disposal trends and favorable procedural levers for a specific bench."""
    bench_data = CourtroomTacticsEngine.BENCH_DATABASE.get(judge_id)
    if not bench_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"न्यायिक अधिकारी कोड '{judge_id}' का डेटा उपलब्ध नहीं है।"
        )

    return JudicialBenchAnalyticsResponse(
        judge_identifier=judge_id,
        court_establishment=bench_data["court_establishment"],
        district=bench_data["district"],
        designation=bench_data["designation"],
        disposal_metrics=bench_data["disposal_metrics"],
        favorable_procedural_levers=bench_data["favorable_procedural_levers"]
    )
