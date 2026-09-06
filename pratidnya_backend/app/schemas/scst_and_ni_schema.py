from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import date

# ============================================================================
# SC/ST (PoA) ACT 1989 SCHEMAS
# ============================================================================

class ScstAuditRequest(BaseModel):
    case_id: str
    atrocity_sections: List[str] = Field(default=["3(1)(r)", "3(1)(s)"])
    incident_place_type: str = Field(..., description="'PRIVATE_HOUSE_ROOM', 'ENCLOSED_CHAMBER', 'PUBLIC_ROAD', 'PUBLIC_GROUND'")
    independent_public_witnesses_present: bool = Field(default=False)
    allegation_of_caste_name_used: bool = Field(default=True)
    prior_land_or_civil_dispute_existing: bool = Field(default=False)
    special_court_order_date: Optional[date] = Field(default=None, description="Date of bail rejection order by Special Judge")
    proposed_appeal_filing_date: date = Field(default_factory=date.today)
    victim_notice_served: bool = Field(default=False)

class ScstComplianceEvaluation(BaseModel):
    case_id: str
    is_public_view_test_satisfied: bool
    is_anticipatory_bail_maintainable: bool
    section_18_bar_bypass_ratio: str
    section_14a_appeal_limitation_status: str # 'WITHIN_90_DAYS', 'EXTENDED_90_TO_180_DAYS_REQUIRES_CONDONATION', 'BARRED_BEYOND_180_DAYS'
    delay_days: int
    mandatory_victim_notice_warning: str
    tailored_grounds: List[str]
    cited_precedents: List[Dict[str, str]]

# ============================================================================
# NI ACT SECTION 138 SCHEMAS
# ============================================================================

class NiActAuditRequest(BaseModel):
    case_id: str
    cheque_number: str
    cheque_amount: float = Field(..., ge=1.0)
    cheque_date: date
    bank_return_memo_date: date
    dishonour_reason: str = Field(default="FUNDS_INSUFFICIENT")
    demand_notice_dispatch_date: date
    demand_notice_delivery_date: date
    is_omnibus_demand_defective: bool = Field(default=False, description="Demand note combines interest/damages without separating cheque amount")
    complaint_filing_date: date
    defense_category: str = Field(default="SECURITY_CHEQUE", description="'SECURITY_CHEQUE', 'NO_EXISTING_DEBT', 'FINANCIAL_INCAPACITY'")
    seeks_compounding: bool = Field(default=False)

class NiActComplianceEvaluation(BaseModel):
    case_id: str
    dispatch_within_30_days: bool
    cure_period_15_days_expiry_date: date
    is_premature_complaint: bool
    is_time_barred: bool
    fatal_defects_detected: List[str]
    defense_rebuttal_strategy: List[str]
    statutory_discharge_or_quashing_grounds: List[str]
    compounding_guidelines_under_147: Optional[str] = None
    cited_precedents: List[Dict[str, str]]
