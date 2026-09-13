from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class WitnessImpeachmentAuditRequest(StrictInputSchema):
    case_id: str
    witness_code: str = Field(..., description="e.g. 'PW-1', 'PW-2'")
    witness_name: str = Field(default="चश्मदीद गवाह")
    witness_role: str = Field(default="EYEWITNESS", description="'EYEWITNESS', 'INJURED_WITNESS', 'PANCH_SEIZURE', 'CHANCE_WITNESS'")
    fir_narrative: Optional[str] = Field(default=None, description="Initial FIR version regarding this witness")
    sec_161_crpc_statement: str = Field(..., description="Statement recorded by police under Section 161 CrPC / Section 183 BNSS")
    sec_164_crpc_statement: Optional[str] = Field(default=None, description="Statement recorded before Magistrate under Section 164 CrPC / Section 186 BNSS")
    court_deposition_chief: str = Field(..., description="Examination-in-chief recorded in court")
    defense_theory: Optional[str] = Field(default="FALSE_IMPLICATION_AND_SUBSTANTIAL_IMPROVEMENT")
    accused_name: str = Field(default="अभियुक्त")
    police_station: str = Field(default="कोतवाली नगर")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय अपर सत्र न्यायाधीश / सत्र न्यायाधीश")

class ContradictionGridItem(BaseModel):
    statement_segment: str
    statement_161: str
    statement_164: Optional[str] = None
    chief_deposition: str
    classification: str  # 'MATERIAL_IMPROVEMENT_AMOUNTING_TO_CONTRADICTION', 'DIRECT_SUBSTANTIVE_CONTRADICTION', 'VITAL_OMISSION', 'CORROBORATING_PASSAGE'
    severity: str        # 'FATAL', 'MATERIAL', 'TRIVIAL'
    tahsildar_singh_applicability_hindi: str
    statutory_confrontation_script_hindi: str
    marked_exhibit_identifier: str  # e.g. 'Ex. D-1', 'Mark X-1'

class WitnessImpeachmentAuditResponse(StrictOutputSchema):
    case_id: str
    witness_code: str
    witness_name: str
    has_fatal_contradictions: bool
    grid_analysis: List[ContradictionGridItem]
    marked_exhibits_summary: List[Dict[str, str]]
    io_cross_examination_reminders: List[str]
    confrontation_master_script_hindi: str
    cited_precedents: List[Dict[str, str]]
