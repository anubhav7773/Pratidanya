from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class BasePredicateCaseRecord(BaseModel):
    crime_number: str = Field(..., description="e.g. 'मु.अ.सं. 112/2021'")
    sections: str = Field(..., description="e.g. '379/411 भा.दं.वि.'")
    status: str = Field(
        ...,
        description="'ACQUITTED_ON_MERITS', 'DISCHARGED', 'QUASHED_BY_HIGH_COURT', 'PENDING_TRIAL', 'CONVICTED'"
    )
    disposal_date: Optional[str] = Field(default=None, description="Date of judgment/discharge/quashing")

class RegionalActsAuditRequest(StrictInputSchema):
    case_id: str
    statute_applied: str = Field(
        default="UP_GANGSTERS_ACT_1986",
        description="'UP_GANGSTERS_ACT_1986', 'UP_GOONDAS_ACT_1970', 'ARMS_ACT_1959'"
    )
    district: str = Field(default="लखनऊ")
    police_station: str = Field(default="कोतवाली नगर")
    accused_name: str = Field(default="अभियुक्त")

    # UP Gangsters Act 1986 Parameters
    gang_chart_number: Optional[str] = Field(default="गैंग चार्ट सं. 01/2026")
    joint_meeting_rule_5_documented: bool = Field(
        default=False,
        description="Whether minutes and formal resolution of joint meeting between DM & SSP are documented (Rule 5(3)(a))"
    )
    dm_independent_mind_applied: bool = Field(
        default=False,
        description="Whether DM recorded independent reasons instead of rubber-stamped signature (Rule 16)"
    )
    dm_endorsement_raw_text: Optional[str] = Field(
        default="Approved as recommended (सहमति प्रदान की गई - मोहर हस्ताक्षर)",
        description="Verbatim text of DM's approval on the Gang Chart"
    )
    base_cases: List[BasePredicateCaseRecord] = Field(
        default=[],
        description="List of predicate FIRs mentioned in the Gang Chart"
    )

    # UP Control of Goondas Act 1970 Parameters
    notice_has_material_allegations: bool = Field(
        default=False,
        description="Whether Section 3 notice discloses general nature of material allegations (Ramji Pandey test)"
    )
    notice_only_lists_firs: bool = Field(
        default=True,
        description="Whether notice merely enumerates crime numbers without factual narrative of terror/panic"
    )

class GroundOfChallengeItem(BaseModel):
    doctrine: str
    rule_or_statute: str
    severity: str  # 'JURISDICTIONAL_FATALITY', 'SUBSTANTIVE_FATALITY', 'MATERIAL_IRREGULARITY'
    argument_hindi: str
    statutory_remedy: str

class RegionalActsAuditResponse(StrictOutputSchema):
    case_id: str
    statute_applied: str
    procedural_viability: str  # 'FATALLY_DEFECTIVE_CHALLENGEABLE', 'IRREGULARITY_OBSERVED', 'PRIMA_FACIE_REGULAR'
    is_farhana_collapse_triggered: bool
    is_ramji_pandey_defect_triggered: bool
    grounds_of_challenge: List[GroundOfChallengeItem]
    recommended_forum: str
    draft_petition_type: str
    draft_petition_hindi: str
    cited_precedents: List[Dict[str, str]]
