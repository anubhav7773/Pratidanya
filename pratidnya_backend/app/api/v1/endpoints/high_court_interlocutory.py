from fastapi import APIRouter, HTTPException, Security
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client
from app.schemas.limitation_and_stay_schema import (
    LimitationCheckRequest,
    LimitationEvaluationResponse,
    GenerateSection5DelayRequest,
    Section5DelayApplicationResponse,
    GenerateSuspensionBailRequest,
    SuspensionBailApplicationResponse
)
from app.services.limitation_calculator import LimitationCalculator
from app.services.delay_condonation_builder import DelayCondonationBuilder
from app.services.sentence_suspension_builder import SentenceSuspensionBuilder

router = APIRouter(prefix="/high-court/interlocutory", tags=["High Court Interlocutory & Limitation Engine"])

@router.post("/calculate-limitation", response_model=LimitationEvaluationResponse)
async def calculate_limitation_endpoint(
    payload: LimitationCheckRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Computes statutory limitation days under Limitation Act 1963 (Art 115(b)/131),
    deducts certified copy preparation time under Section 12, and determines if
    a Section 5 Delay Condonation Application is mandatory.
    """
    try:
        evaluation = LimitationCalculator.evaluate_limitation(payload)

        # Update limitation state in high_court_pleadings table
        supabase = get_supabase_admin_client()
        supabase.table("high_court_pleadings").update({
            "certified_copy_applied_date": payload.certified_copy_applied_date.isoformat(),
            "certified_copy_ready_date": payload.certified_copy_ready_date.isoformat(),
            "limitation_expiry_date": evaluation.limitation_expiry_date.isoformat(),
            "is_delayed": evaluation.is_delayed,
            "delay_days": evaluation.delay_days
        }).eq("id", payload.pleading_id).eq("advocate_id", current_user["uid"]).execute()

        return evaluation
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"मियाद गणना विफलता: {str(e)}")

@router.post("/generate-section-5-delay", response_model=Section5DelayApplicationResponse)
async def generate_section_5_delay_endpoint(
    payload: GenerateSection5DelayRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Generates formal Section 5 Limitation Act Application and Pairokar Supporting Affidavit
    incorporating grounded reasons for delay and leading Supreme Court precedents.
    """
    supabase = get_supabase_admin_client()
    pleading_res = supabase.table("high_court_pleadings") \
        .select("*") \
        .eq("id", payload.pleading_id) \
        .eq("advocate_id", current_user["uid"]) \
        .maybe_single() \
        .execute()

    if not pleading_res or not pleading_res.data:
        raise HTTPException(status_code=404, detail="उच्च न्यायालय वाद प्रविष्टि नहीं मिली।")

    pleading = pleading_res.data

    # Re-evaluate limitation using stored dates
    judgment_dt = pleading.get("trial_judgment_date")
    applied_dt = pleading.get("certified_copy_applied_date") or judgment_dt
    ready_dt = pleading.get("certified_copy_ready_date") or judgment_dt
    filing_dt = pleading.get("limitation_expiry_date") or judgment_dt

    from datetime import date
    if isinstance(judgment_dt, str):
        judgment_dt = date.fromisoformat(judgment_dt)
    if isinstance(applied_dt, str):
        applied_dt = date.fromisoformat(applied_dt)
    if isinstance(ready_dt, str):
        ready_dt = date.fromisoformat(ready_dt)
    if isinstance(filing_dt, str):
        filing_dt = date.fromisoformat(filing_dt)

    lim_request = LimitationCheckRequest(
        pleading_id=payload.pleading_id,
        judgment_date=judgment_dt,
        certified_copy_applied_date=applied_dt,
        certified_copy_ready_date=ready_dt,
        proposed_filing_date=filing_dt,
        pleading_type=pleading["pleading_type"]
    )
    lim_eval = LimitationCalculator.evaluate_limitation(lim_request)

    return DelayCondonationBuilder.build_section_5_suite(
        req=payload,
        limitation_eval=lim_eval,
        pleading=pleading
    )

@router.post("/generate-suspension-bail", response_model=SuspensionBailApplicationResponse)
async def generate_suspension_bail_endpoint(
    payload: GenerateSuspensionBailRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Generates Section 389(1) CrPC / Section 430(1) BNSS Sentence Suspension and Bail Application
    with accompanying Pairokar Affidavit and Bhagwan Rama Shinde / Saudan Singh precedent grounding.
    """
    supabase = get_supabase_admin_client()
    pleading_res = supabase.table("high_court_pleadings") \
        .select("*") \
        .eq("id", payload.pleading_id) \
        .eq("advocate_id", current_user["uid"]) \
        .maybe_single() \
        .execute()

    if not pleading_res or not pleading_res.data:
        raise HTTPException(status_code=404, detail="उच्च न्यायालय वाद प्रविष्टि नहीं मिली।")

    pleading = pleading_res.data

    return SentenceSuspensionBuilder.build_suspension_suite(
        req=payload,
        pleading=pleading
    )
