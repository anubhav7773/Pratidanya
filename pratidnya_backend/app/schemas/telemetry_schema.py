from typing import Dict, Any, Optional
from datetime import datetime, timezone
from pydantic import BaseModel, Field

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

class ClientActivityLogRequest(BaseModel):
    event_type: str = Field(
        ...,
        description="'APP_LAUNCH', 'LOGIN_SUCCESS', 'LOGOUT', 'TAB_SWITCH', 'MODULE_EVALUATION', 'PETITION_EXPORT', 'ERROR_OCCURRED'"
    )
    module_name: str = Field(..., description="e.g. 'REMAND_DEFENSE', 'DEFAULT_BAIL', 'BSA_63', 'MEDICO_LEGAL'")
    action_details: Dict[str, Any] = Field(default_factory=dict)
    case_id: Optional[str] = None
    client_timestamp: datetime = Field(default_factory=utc_now)
    client_language: str = Field(default="hi")
    device_info: Optional[str] = Field(default="Flutter Mobile Client")

class ClientActivityLogResponse(BaseModel):
    status: str = "LOGGED"
    received_at: datetime = Field(default_factory=utc_now)
    event_type: str
    advocate_id: str
