from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class OffenseChargeDetail(BaseModel):
    act: str = Field(..., description="e.g. 'BNS', 'IPC', 'IT_ACT', 'NDPS'")
    section: str = Field(..., description="e.g. '115(2)', '352', '302'")
    max_punishment_years: int = Field(default=3, description="Maximum sentence in years; 99 for life/death")
    is_special_act: bool = Field(default=False, description="True if NDPS, PMLA, UAPA, POCSO")
    is_economic_offense: bool = Field(default=False, description="True for non-special economic offenses")

class ArrestComplianceAuditRequest(StrictInputSchema):
    case_id: str
    accused_name: str = Field(default="अभियुक्त")
    police_station: str = Field(default="कोतवाली नगर")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय मुख्य न्यायिक मजिस्ट्रेट")
    charges: List[OffenseChargeDetail]
    arrest_timestamp: datetime
    remand_production_timestamp: datetime
    
    # Procedural Affirmations from Police Remand Diary
    notice_issued_sec_35_bnss: bool = Field(
        default=False, 
        description="Whether a written Section 35(3) BNSS / 41A CrPC notice was served prior to arrest"
    )
    flight_or_tampering_risk_recorded: bool = Field(
        default=False,
        description="Whether concrete objective reasons for arrest (flight risk, witness tampering) were recorded in case diary"
    )
    arrest_memo_witness_count: int = Field(
        default=0,
        description="Number of respectable local witnesses or family members attesting the arrest memo (D.K. Basu)"
    )
    family_intimation_recorded: bool = Field(
        default=False,
        description="Whether formal intimation of arrest and custody venue was given to a nominated family member/friend"
    )
    medical_examination_conducted: bool = Field(
        default=False,
        description="Whether medical examination was conducted under Sec 53 BNSS / Sec 54 CrPC"
    )
    magistrate_independent_reasons_recorded: bool = Field(
        default=False,
        description="Whether the Magistrate recorded independent objective satisfaction before authorizing police remand"
    )
    police_remand_reasons_raw_text: Optional[str] = Field(
        default=None,
        description="Verbatim reasons recorded by police in remand CD (e.g. 'अभियुक्त से पूछताछ व माल बरामदगी शेष है')"
    )

class ProceduralViolationItem(BaseModel):
    statutory_provision: str
    governing_doctrine: str
    severity: str  # 'FATAL', 'MATERIAL', 'PROCEDURAL'
    finding_hindi: str
    actionable_remedy: str

class ArrestComplianceAuditResponse(StrictOutputSchema):
    case_id: str
    antil_category: str  # 'CATEGORY_A', 'CATEGORY_B', 'CATEGORY_C', 'CATEGORY_D'
    compliance_verdict: str  # 'NON_COMPLIANT_VOID_ARREST', 'SUBSTANTIAL_IRREGULARITY', 'COMPLIANT_PROCEDURE'
    hours_to_production: float
    is_constitutionally_time_barred: bool  # Produced beyond 24 hours (Art. 22(2))
    violations: List[ProceduralViolationItem]
    magistrate_directive_recommendation: str
    instant_objection_petition_draft: str
    cited_precedents: List[dict]
