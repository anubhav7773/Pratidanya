from datetime import datetime, date
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class CustodyPeriodInput(BaseModel):
    custody_type: str = Field(..., description="'POLICE_CUSTODY' or 'JUDICIAL_CUSTODY'")
    start_date: date
    end_date: date

class OffenseSectionItem(BaseModel):
    act: str = Field(..., description="e.g. 'BNS', 'IPC', 'NDPS'")
    section: str = Field(..., description="e.g. '103(1)', '302', '379'")
    max_punishment_years: int = Field(default=3, description="Maximum imprisonment term in years; 99 for life/death")

class DefaultBailAuditRequest(StrictInputSchema):
    case_id: str
    first_remand_date: datetime
    statutory_regime: str = Field(default="BNSS", description="'BNSS' or 'CRPC'")
    offense_sections: List[OffenseSectionItem]
    custody_history: List[CustodyPeriodInput] = Field(default=[])
    chargesheet_filed: bool = Field(default=False)
    chargesheet_filing_date: Optional[datetime] = None
    chargesheet_annexures: List[str] = Field(
        default=[],
        description="Names of documents annexed with chargesheet, e.g. ['SITE_PLAN', 'WITNESS_STATEMENTS']"
    )
    accused_name: str = Field(default="अभियुक्त")
    police_station: str = Field(default="कोतवाली नगर")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय मुख्य न्यायिक मजिस्ट्रेट")

class PrecedentCitationItem(BaseModel):
    case_title: str
    citation: str
    legal_ratio_hindi: str
    verified_url: str

class DefaultBailAuditResponse(StrictOutputSchema):
    case_id: str
    statutory_threshold_days: int
    days_elapsed_in_custody: int
    is_default_bail_crystallized: bool
    default_bail_accrual_timestamp: datetime
    hours_until_default_bail: float
    
    # Section 187 BNSS Split Police Custody Analysis
    police_custody_days_used: int
    police_custody_days_remaining: int
    police_custody_window_expired: bool
    police_custody_alert_hindi: str
    
    # Incomplete Chargesheet Defect Analysis
    is_chargesheet_incomplete: bool
    defect_type: Optional[str] = None
    missing_mandatory_reports: List[str] = []
    chargesheet_defect_summary_hindi: str
    
    # Ready-to-file Devanagari Petition Draft
    statutory_petition_draft_hindi: str
    cited_precedents: List[PrecedentCitationItem]
