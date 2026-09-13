from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class LeadingQuestionRequest(StrictInputSchema):
    case_id: str
    witness_name: str = Field(default="राम लखन (पंच साक्षी)")
    witness_role: str = Field(
        default="PANCH_WITNESS_SEIZURE",
        description="'PANCH_WITNESS_SEIZURE', 'EYEWITNESS', 'VICTIM_PROSECUTRIX', 'POLICE_OFFICIAL'"
    )
    defense_theory: str = Field(
        default="PLANTED_RECOVERY_STOCK_WITNESS",
        description="'PLANTED_RECOVERY_STOCK_WITNESS', 'ALIBI_AND_ABSENCE', 'CONSENSUAL_RELATION_SEC_69_BNS', 'MISTAKEN_IDENTITY_TIP_FAILURE'"
    )
    case_facts: Dict[str, Any] = Field(
        default_factory=dict,
        description="Structured facts: recovery_place, witness_residence_distance_km, prior_appearances_count, weapon_type, delay_days"
    )
    accused_name: str = Field(default="अभियुक्त")
    police_station: str = Field(default="कोतवाली नगर")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय अपर सत्र न्यायाधीश / सत्र न्यायाधीश")

class QuestionStepItem(BaseModel):
    step_number: int
    objective_hindi: str
    leading_question_hindi: str
    expected_answer: str  # 'YES' or 'NO'
    trap_mitigation_hindi: str
    pivot_tactic_hindi: str
    statutory_basis: str

class LeadingQuestionResponse(StrictOutputSchema):
    case_id: str
    witness_name: str
    defense_theory: str
    questionnaire_strategy_hindi: str
    question_trees: List[QuestionStepItem]
    trial_tactics_summary_hindi: str
    cited_precedents: List[Dict[str, str]]
