import logging
from typing import Dict, Any, Optional
from fastapi import APIRouter, Security, status
from pydantic import BaseModel
from app.core.security import verify_advocate_token_optional

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/activity", tags=["Chamber Activity & Telemetry"])

class ActivityLogRequest(BaseModel):
    activity_type: str
    advocate_id: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    timestamp: Optional[str] = None

@router.post("/log", status_code=status.HTTP_200_OK)
async def log_activity(
    payload: ActivityLogRequest,
    current_user: Optional[dict] = Security(verify_advocate_token_optional)
):
    advocate_uid = (current_user.get("uid") if current_user else None) or payload.advocate_id or "ANONYMOUS"
    advocate_email = (current_user.get("email") if current_user else None) or "N/A"
    
    # Prominently log to Render stdout so every single user action is detected in the dashboard
    logger.info(
        f"⚡ [PRATIDANYA USER ACTIVITY] Type='{payload.activity_type.upper()}' | "
        f"Advocate UID='{advocate_uid}' | Email='{advocate_email}' | "
        f"Details={payload.details or {}}"
    )
    
    return {
        "status": "SUCCESS",
        "activity_type": payload.activity_type,
        "logged_for": advocate_uid
    }
