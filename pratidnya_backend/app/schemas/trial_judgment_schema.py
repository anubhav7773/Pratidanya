from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class WitnessContradiction(BaseModel):
    witness_name: str = Field(..., description="e.g., 'PW-1 (वादी) राम स्वरूप'")
    statement_extract: str = Field(..., description="मौखिक गवाही का मुख्य अंश")
    contradiction_nature: str = Field(..., description="e.g., 'चिकित्सीय रिपोर्ट से विरोधाभास' or 'घटनास्थल पर उपस्थिति संदिग्ध'")
    impact_on_prosecution: str = Field(..., description="अभियोजन कथानक पर प्रभाव")

class ProceduralOmission(BaseModel):
    stage_name: str = Field(..., description="e.g., 'धारा 313 दंड प्रक्रिया संहिता बयान' or 'फर्द बरामदगी'")
    statutory_mandate: str = Field(..., description="e.g., 'Sec 313 CrPC / Sec 351 BNSS' or 'Sec 100(4) CrPC'")
    defect_description: str = Field(..., description="अवर न्यायालय द्वारा की गई विशिष्ट विधिक भूल")
    relevance_to_appeal: str = Field(..., description="अपील हेतु विधिक आधार")

class TrialCourtMetadata(BaseModel):
    court_name: str
    case_number: str
    judgment_date: str
    presiding_judge: str
    convicted_sections: List[str]
    quantum_of_sentence: str
    accused_names: List[str]
    police_station: str
    district: str
    fir_number: str

class TrialJudgmentAnalysisResponse(BaseModel):
    pleading_id: Optional[str] = None
    metadata: TrialCourtMetadata
    operative_sentence_hindi: str
    ocular_vs_medical_conflict: Optional[str] = None
    section_313_examination_defects: Optional[str] = None
    malkhana_link_evidence_defects: Optional[str] = None
    witness_flaws: List[WitnessContradiction]
    procedural_omissions: List[ProceduralOmission]
    total_pages_processed: int
    raw_word_count: int
    extracted_appeal_grounds: List[str]
