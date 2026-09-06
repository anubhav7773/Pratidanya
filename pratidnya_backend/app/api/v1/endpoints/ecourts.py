import logging
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Query, Header, Security
from pydantic import BaseModel, Field
from app.core.security import verify_advocate_token_optional
from app.services.ecourts_service import EcourtsService

logger = logging.getLogger("pratidnya.api.ecourts")
router = APIRouter(prefix="/ecourts", tags=["e-Courts CIS 3.2 Integration"])

class ValidateCnrRequest(BaseModel):
    cnr_number: str = Field(..., description="16-character alphanumeric e-Courts CNR number")

class SyncCaseRequest(BaseModel):
    cnr_number: str = Field(..., description="16-character alphanumeric e-Courts CNR number")
    fir_number: Optional[str] = Field(None, description="Optional police FIR number")
    district: Optional[str] = Field(None, description="Judicial district name")
    state: Optional[str] = Field(None, description="State jurisdiction")

class CourtWebhookPayload(BaseModel):
    event_type: str = Field("ORDER_UPLOADED", description="Event type: ORDER_UPLOADED, NEXT_DATE_FIXED, CAUSE_LIST_PUBLISHED")
    cnr_number: str = Field(..., description="Target 16-character CNR number")
    case_number: Optional[str] = None
    next_date: Optional[str] = None
    order_summary: Optional[str] = None
    order_pdf_url: Optional[str] = None

@router.post("/validate-cnr")
async def validate_cnr_endpoint(payload: ValidateCnrRequest):
    """
    Validates a 16-character Indian e-Courts CNR number and decodes jurisdictional elements.
    """
    logger.info(f"⚡ [VALIDATE_CNR_REQUEST] CNR={payload.cnr_number}")
    return EcourtsService.validate_and_parse_cnr(payload.cnr_number)

@router.post("/sync")
async def sync_case_endpoint(payload: SyncCaseRequest):
    """
    Performs real-time synchronization of a case against e-Courts CIS 3.2.
    Returns authoritative coram, next hearing date, court room, and certified orders.
    """
    logger.info(f"⚡ [ECOURTS_SYNC_REQUEST] CNR={payload.cnr_number} | FIR={payload.fir_number}")
    result = EcourtsService.sync_case_with_cis(
        cnr_number=payload.cnr_number,
        fir_number=payload.fir_number,
        district=payload.district,
        state=payload.state,
    )
    logger.info(f"✅ [ECOURTS_SYNC_SUCCESS] CNR={payload.cnr_number} | NextDate={result['next_hearing_date']}")
    return result

@router.get("/cause-list")
async def get_cause_list_endpoint(
    district: str = Query("Lucknow", description="Judicial district name"),
    court_designation: Optional[str] = Query(None, description="Specific Court Coram/Designation"),
    target_date: Optional[str] = Query(None, description="Target listing date (YYYY-MM-DD)"),
    advocate_bar_number: Optional[str] = Query(None, description="Advocate Bar Enrollment Number for highlighting"),
    current_user: Optional[dict] = Security(verify_advocate_token_optional),
):
    """
    Retrieves the Daily Cause List (दैनिक वाद सूची) for District & Sessions Courts,
    automatically personalizing for the authenticated advocate chamber.
    """
    advocate_id = current_user.get("uid") if current_user else None
    logger.info(f"⚡ [CAUSE_LIST_REQUEST] District={district} | Date={target_date} | Advocate={advocate_bar_number} | UID={advocate_id}")
    return EcourtsService.get_daily_cause_list(
        district=district,
        court_designation=court_designation,
        target_date=target_date,
        advocate_bar_number=advocate_bar_number,
        advocate_id=advocate_id,
    )

@router.post("/webhook")
async def ecourts_webhook_endpoint(
    payload: CourtWebhookPayload,
    x_webhook_secret: Optional[str] = Header(None, alias="X-Webhook-Secret"),
):
    """
    Webhook receiver for e-Courts CIS 3.2 and National Judicial Data Grid (NJDG) push updates.
    """
    return EcourtsService.process_court_webhook(payload.model_dump())
