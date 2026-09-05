from fastapi import APIRouter, HTTPException, Security
from pydantic import BaseModel, Field
from typing import List, Optional
from app.core.security import verify_advocate_token
from app.core.config import settings
from app.core.concurrency import acquire_nlp_slot, release_nlp_slot
from app.services.opennyai_engine import OpenNyAIEngine

router = APIRouter(prefix="/nlp", tags=["Legal NLP & Chargesheet Parsing"])

class ChargesheetDeconstructRequest(BaseModel):
    case_id: str = Field(..., description="Target Case UUID")
    chargesheet_text: str = Field(..., min_length=50, description="Raw chargesheet / FIR text in Hindi or English")
    is_dummy_testing: bool = Field(default=True, description="Strictly True during local development")

class ChargesheetDeconstructResponse(BaseModel):
    case_id: str
    facts_extracts: List[str]
    prosecution_arguments: List[str]
    statutes_detected: List[str]
    provisions_detected: List[str]
    witnesses_detected: List[str]
    persons_detected: List[str]
    total_sentences_processed: int

@router.post("/process-chargesheet", response_model=ChargesheetDeconstructResponse)
async def process_chargesheet_endpoint(
    payload: ChargesheetDeconstructRequest,
    current_user: dict = Security(verify_advocate_token)
):
    # Statutory Privacy Gate Check (Rule 6)
    if not settings.GEMINI_PAID_TIER and not payload.is_dummy_testing:
        raise HTTPException(
            status_code=403,
            detail="गोपनीयता सुरक्षा निषेध: जब तक पेड-टियर सक्रिय न हो, वास्तविक अभियोग पत्र का प्रसंस्करण प्रतिबंधित है।"
        )

    # Throttling to prevent OOM crash on container
    await acquire_nlp_slot()
    try:
        engine = OpenNyAIEngine.get_instance()
        analysis = engine.process_chargesheet(payload.chargesheet_text)

        return ChargesheetDeconstructResponse(
            case_id=payload.case_id,
            facts_extracts=analysis["facts_extracts"],
            prosecution_arguments=analysis["prosecution_arguments"],
            statutes_detected=analysis["statutes_detected"],
            provisions_detected=analysis["provisions_detected"],
            witnesses_detected=analysis["witnesses_detected"],
            persons_detected=analysis["persons_detected"],
            total_sentences_processed=analysis["total_sentences_processed"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"अभियोग पत्र विश्लेषण विफलता: {str(e)}")
    finally:
        release_nlp_slot()
