from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import date

# ============================================================================
# NDPS ACT 1985 SCHEMAS
# ============================================================================

class NdpsAuditRequest(BaseModel):
    case_id: str
    substance_name: str = Field(..., description="e.g. 'Ganja', 'Charas', 'Heroin', 'Smack', 'Opium'")
    recovered_quantity_grams: float = Field(..., ge=0.0)
    is_personal_search: bool = Field(default=True)
    section_50_notice_given: bool = Field(default=True)
    section_50_notice_type: str = Field(default="WRITTEN_INDEPENDENT", description="'WRITTEN_INDEPENDENT', 'ORAL_ONLY', 'JOINT_NOTICE_DEFECTIVE', 'NO_NOTICE'")
    was_searched_before_gazetted_officer: bool = Field(default=False)
    was_searched_before_magistrate: bool = Field(default=False)
    third_option_defect_present: bool = Field(default=False, description="Option like 'या आप हमारी तलाशी ले सकते हैं'")
    information_recorded_in_writing: bool = Field(default=True)
    information_sent_to_superior_within_72h: bool = Field(default=True)
    independent_public_witnesses_present: bool = Field(default=False)
    sample_drawn_before_magistrate_sec_52a: bool = Field(default=False)
    malkhana_entry_delay_days: int = Field(default=0)
    fsl_dispatch_delay_days: int = Field(default=0)

class NdpsComplianceEvaluation(BaseModel):
    case_id: str
    substance_name: str
    quantity_category: str # 'SMALL_QUANTITY', 'INTERMEDIATE_QUANTITY', 'COMMERCIAL_QUANTITY'
    is_section_37_bar_applicable: bool
    section_50_compliance_status: str # 'FATAL_DEFECT', 'SUSPICIOUS', 'COMPLIANT', 'NOT_APPLICABLE'
    detected_procedural_defects: List[str]
    tailored_bail_grounds: List[str]
    cited_supreme_court_precedents: List[Dict[str, str]]

# ============================================================================
# POCSO ACT 2012 & JJ ACT 2015 SCHEMAS
# ============================================================================

class PocsoAgeAuditRequest(BaseModel):
    case_id: str
    alleged_incident_date: date
    fir_stated_age_years: int
    has_first_attended_school_certificate: bool = Field(default=False)
    school_dob: Optional[date] = None
    has_matriculation_certificate: bool = Field(default=False)
    matriculation_dob: Optional[date] = None
    has_municipal_birth_certificate: bool = Field(default=False)
    municipal_dob: Optional[date] = None
    ossification_test_conducted: bool = Field(default=False)
    radiological_age_lower: Optional[float] = Field(default=None)
    radiological_age_upper: Optional[float] = Field(default=None)
    two_year_margin_benefit_applied: bool = Field(default=True)
    evidence_of_prior_romantic_relationship: bool = Field(default=False)
    unexplained_delay_in_fir_days: int = Field(default=0)
    no_injuries_found: bool = Field(default=False)

class PocsoAgeEvaluation(BaseModel):
    case_id: str
    statutory_tier_applicable: str # 'TIER_1_MATRICULATION', 'TIER_1_FIRST_SCHOOL', 'TIER_2_MUNICIPAL', 'TIER_3_OSSIFICATION', 'NO_VALID_DOCUMENT'
    computed_age_at_incident_years: Optional[float]
    is_majority_probable: bool
    age_determination_analysis_hindi: str
    presumption_rebuttal_strategy: List[str]
    bail_grounds_pocso: List[str]
    cited_precedents: List[Dict[str, str]]
