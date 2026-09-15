from fastapi import APIRouter, Security
from app.core.security import verify_advocate_token
from app.core.logging_config import render_logger
from app.schemas.telemetry_schema import ClientActivityLogRequest, ClientActivityLogResponse

router = APIRouter(prefix="/telemetry", tags=["Client Telemetry & Audit Logs"])

@router.post("/log-activity", response_model=ClientActivityLogResponse)
async def log_activity_endpoint(
    payload: ClientActivityLogRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Receives explicit telemetry events from the Flutter client (login, logout,
    tab transitions, audit button clicks, and petition copy events) and logs
    them directly to the Render console.
    """
    adv_id = current_user["uid"]
    adv_name = current_user.get("name", "Advocate")

    render_logger.info(
        f"📱 [CLIENT EVENT] >>> ADVOCATE: {adv_id} ({adv_name}) "
        f"| EVENT: {payload.event_type} | MODULE: {payload.module_name} "
        f"| CASE: {payload.case_id or 'N/A'} | DETAILS: {payload.action_details}"
    )

    return ClientActivityLogResponse(
        status="LOGGED",
        event_type=payload.event_type,
        advocate_id=adv_id,
    )
