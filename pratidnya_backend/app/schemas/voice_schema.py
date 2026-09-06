from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class ExtractedCaseEntities(BaseModel):
    fir_number: Optional[str] = Field(default=None, description="उदा. '124/2026'")
    police_station: Optional[str] = Field(default=None, description="उदा. 'कोतवाली नगर'")
    district: Optional[str] = Field(default=None, description="उदा. 'लखनऊ'")
    accused_names: List[str] = Field(default=[], description="अभियुक्तों के नाम")
    complainant_name: Optional[str] = Field(default=None, description="वादी का नाम")
    sections: List[str] = Field(default=[], description="उदा. ['379 IPC', '411 IPC']")
    custody_status: str = Field(default="JUDICIAL_CUSTODY", description="JUDICIAL_CUSTODY, POLICE_CUSTODY, ON_BAIL")
    allegation_summary: str = Field(default="", description="अभियोजन कथानक का सार")
    defense_plea: str = Field(default="", description="अधिवक्ता द्वारा इंगित मुख्य बचाव बिंदु")

class VoiceDictationResponse(BaseModel):
    session_id: str
    verbatim_transcript_hindi: str
    cleaned_factual_matrix: str
    duration_seconds: int
    extracted_entities: ExtractedCaseEntities
    chronological_events: List[str]
    dpdp_ephemeral_purge_verified: bool = True
