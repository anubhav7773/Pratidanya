from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class OcularWitnessClaim(BaseModel):
    witness_id: str = Field(..., description="e.g. 'PW-1' or 'वादी / चश्मदीद'")
    witness_name: str = Field(default="चश्मदीद साक्षी")
    weapon_alleged: str = Field(..., description="e.g. 'Talwar / Sword', 'Knife / Chhura', 'Lathi / Danda', 'Firearm / Pistol'")
    incident_timestamp: datetime = Field(..., description="Alleged exact date and time of the assault")
    alleged_distance_meters: float = Field(default=1.0, ge=0.0, description="Alleged distance of assailant in meters")
    strike_location: str = Field(..., description="e.g. 'Occipital region', 'Chest', 'Abdomen'")
    ocular_narrative: str = Field(default="", description="Verbatim statement from FIR or examination-in-chief")

class ExternalInjuryDetail(BaseModel):
    injury_number: int = Field(default=1)
    injury_type: str = Field(
        ...,
        description="'Lacerated wound', 'Incised wound', 'Stab/Punctured wound', 'Contusion', 'Abrasion', 'Firearm entry wound', 'Firearm exit wound'"
    )
    dimensions: str = Field(..., description="e.g. '5cm x 2cm x bone deep'")
    margins: str = Field(
        ...,
        description="e.g. 'Irregular, contused, abraded' OR 'Clean-cut, linear, sharp' OR 'Inverted, charred, tattooed'"
    )
    anatomical_location: str = Field(..., description="e.g. 'Occipital region of skull', 'Left 5th intercostal space'")
    underlying_damage: Optional[str] = Field(default=None, description="e.g. 'Fracture of parietal bone', 'Perforation of left ventricle'")

class PostMortemDataInput(BaseModel):
    pmr_number: str = Field(..., description="PMR or MLC reference number")
    autopsy_doctor_name: Optional[str] = Field(default="डॉक्टर / चिकित्साधिकारी")
    hospital_name: Optional[str] = Field(default="जिला चिकित्सालय / मोर्चरी")
    autopsy_timestamp: datetime = Field(..., description="Date and time when post-mortem was conducted")
    external_injuries: List[ExternalInjuryDetail] = Field(..., min_length=1)
    internal_injuries_summary: Optional[str] = Field(default=None)
    stomach_contents: str = Field(
        ...,
        description="e.g. 'Empty', 'Semi-digested food containing rice and dal', 'Fully digested fluid'"
    )
    rigor_mortis_state: str = Field(
        ...,
        description="e.g. 'Present all over body', 'Passing off from face and neck, present in lower limbs', 'Fully absent'"
    )
    post_mortem_lividity: Optional[str] = Field(default="Fixed on back and dependent parts")
    estimated_time_since_death_hours_min: float = Field(default=24.0, ge=0.0)
    estimated_time_since_death_hours_max: float = Field(default=36.0, ge=0.0)

class MedicalMatrixAuditRequest(StrictInputSchema):
    case_id: str
    ocular_allegations: List[OcularWitnessClaim] = Field(..., min_length=1)
    post_mortem_data: PostMortemDataInput
    accused_name: str = Field(default="अभियुक्त")
    police_station: str = Field(default="कोतवाली नगर")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय सत्र न्यायाधीश / अपर सत्र न्यायाधीश")

class ConflictFindingItem(BaseModel):
    parameter: str  # 'WEAPON_MECHANISM', 'TIME_OF_OCCURRENCE_PMI', 'STOMACH_DIGESTION_CHRONOLOGY', 'RANGE_OF_FIRING'
    ocular_claim: str
    autopsy_finding: str
    scientific_verdict_hindi: str
    biomechanical_authority: str
    impact_on_prosecution: str
    severity: str  # 'FATAL_CONTRADICTION', 'MATERIAL_DISCREPANCY'

class MedicalMatrixAuditResponse(StrictOutputSchema):
    case_id: str
    pmr_number: str
    has_fatal_conflict: bool
    irreconcilable_conflicts: List[ConflictFindingItem]
    cross_examination_crossfire_questions: List[str]
    written_medical_argument_draft_hindi: str
    cited_precedents: List[Dict[str, str]]
