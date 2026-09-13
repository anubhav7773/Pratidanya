from datetime import date
from typing import List, Optional
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class OffenseSentenceInput(BaseModel):
    act: str = Field(..., description="e.g. 'BNS', 'IPC', 'IT_ACT'")
    section: str = Field(..., description="e.g. '420', '318(4)', '303(2)'")
    max_term_months: int = Field(..., ge=1, description="Maximum sentence in months (e.g. 84 for 7 years)")
    is_capital_or_life: bool = Field(default=False, description="True if offense carries death or life imprisonment")

class UndertrialReliefAuditRequest(StrictInputSchema):
    case_id: str
    accused_name: str = Field(default="विचाराधीन बंदी")
    jail_name: str = Field(default="केंद्रीय / जिला कारागार")
    custody_start_date: date = Field(..., description="Date of first judicial custody / remand")
    calculation_date: Optional[date] = Field(default=None, description="Defaults to current date")
    is_first_time_offender: bool = Field(
        default=True,
        description="True if individual has never been convicted in any offense previously (Section 479(1) First Proviso)"
    )
    multiple_cases_pending: bool = Field(
        default=False,
        description="True if another investigation, inquiry, or trial is pending against the accused (Section 479(2) Bar)"
    )
    charges: List[OffenseSentenceInput] = Field(..., min_length=1)
    fir_number: str = Field(default="मु.अ.सं. 124/2023")
    police_station: str = Field(default="कोतवाली")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय मुख्य न्यायिक मजिस्ट्रेट")

class UndertrialReliefAuditResponse(StrictOutputSchema):
    case_id: str
    is_relief_applicable: bool
    governing_statute: str
    statutory_threshold_fraction: str  # '1/3' or '1/2'
    max_prescribed_term_months: int
    threshold_months: float
    actual_detention_served_months: float
    overstay_months: float
    is_disqualified: bool
    disqualification_reason: Optional[str] = None
    retrospective_mandate_text_hindi: str
    jail_superintendent_mandate_sec_479_3: str
    court_application_draft_hindi: str
    jail_superintendent_notice_draft_hindi: str
    cited_precedents: List[dict]
