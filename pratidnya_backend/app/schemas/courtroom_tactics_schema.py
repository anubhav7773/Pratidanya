from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

# =========================================================================
# 1. SURETY SCRUTINY & MOTI RAM MODIFICATION SCHEMAS
# =========================================================================
class SuretyAuditRequest(StrictInputSchema):
    case_id: str
    imposed_bond_amount_inr: float = Field(..., ge=0.0, description="Amount of bail bond ordered by Magistrate/Court")
    is_local_surety_demanded: bool = Field(default=False, description="Court insisted surety must reside in local district")
    is_revenue_record_khatauni_demanded: bool = Field(default=False, description="Court demanded original agricultural land/property revenue records")
    out_of_district_surety_rejected: bool = Field(default=False, description="Surety rejected solely because they reside in another district/state")
    accused_financial_indigence: bool = Field(default=False, description="Accused cannot afford onerous financial bonds")
    accused_name: str = Field(default="अभियुक्त")
    police_station: str = Field(default="कोतवाली नगर")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय मुख्य न्यायिक मजिस्ट्रेट")

class SuretyAuditResponse(StrictOutputSchema):
    case_id: str
    is_condition_onerous: bool
    moti_ram_violation_reasons: List[str]
    suggested_statutory_relief: str
    modification_petition_draft_hindi: str
    cited_precedents: List[Dict[str, str]]

# =========================================================================
# 2. EDGE ORAL PROMPTING & ADVERSARIAL COUNTER-RATIO SCHEMAS
# =========================================================================
class EdgeOralPromptRequest(StrictInputSchema):
    case_id: str
    adversary_argument_raw_text: str = Field(..., description="Transcript of adversary prosecution submission")
    active_judge_id: Optional[str] = Field(default="JUDGE-UP-LKO-04")
    active_offense_category: str = Field(default="NDPS", description="'NDPS', 'POCSO', 'BNS_103_MURDER', 'ARREST_41A', 'GANGSTERS'")
    language: str = Field(default="HINDI_KACHEHRI_SLANG")

class OralPromptRejoinderItem(BaseModel):
    counter_legal_ground: str
    prompt_text_hindi: str
    lead_citation: str
    statutory_lever: str

class EdgeOralPromptResponse(StrictOutputSchema):
    detected_adversarial_ratio: str
    immediate_counter_ratios: List[OralPromptRejoinderItem]
    bench_insights: Optional[Dict[str, Any]] = None
    latency_ms: Dict[str, float]

# =========================================================================
# 3. JUDICIAL BENCH ANALYTICS SCHEMAS
# =========================================================================
class JudicialBenchAnalyticsResponse(StrictOutputSchema):
    judge_identifier: str
    court_establishment: str
    district: str
    designation: str
    disposal_metrics: Dict[str, Any]
    favorable_procedural_levers: List[str]
