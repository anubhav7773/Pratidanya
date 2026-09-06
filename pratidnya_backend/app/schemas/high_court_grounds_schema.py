from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

class HighCourtCitedPrecedent(BaseModel):
    citation_id: str
    case_title: str
    court_name: str
    judgment_date: str
    quoted_passage: str
    verified_source_url: str
    is_grounded_in_record: bool
    relevance_ratio: str = Field(..., description="मिसाल की इस अपील/पुनरीक्षण में प्रासंगिकता")

class GenerateHCGroundsRequest(BaseModel):
    pleading_id: str = Field(..., description="UUID of high_court_pleadings record created in Goal 12")
    custom_defense_angles: Optional[List[str]] = Field(default=[], description="अधिवक्ता द्वारा इंगित विशिष्ट कानूनी बिंदु")
    statute_system: str = Field(default="IPC_CRPC", description="'IPC_CRPC' or 'BNS_BNSS'")
    is_interlocutory_order: bool = Field(default=False, description="Whether impugned order is interlocutory (Revision Bar Check)")
    seeks_acquittal_conversion: bool = Field(default=False, description="Whether revision seeks converting acquittal to conviction")
    include_section_389_bail_grounds: bool = Field(default=True, description="Generate interim bail/suspension grounds")

class HighCourtGroundItem(BaseModel):
    ground_number: int
    ground_heading: str
    ground_text_hindi: str
    statutory_basis: str
    legal_doctrine: str # e.g. 'Perverse Appreciation', 'Patent Illegality', 'Jurisdictional Error'

class HCGroundsResponse(BaseModel):
    pleading_id: str
    pleading_type: str
    high_court_bench: str
    court_title_block: str
    memo_title_hindi: str
    trial_court_reference_block: str
    grounds: List[HighCourtGroundItem]
    interim_suspension_prayer: Optional[str] = None
    final_relief_prayer: str
    cited_precedents: List[HighCourtCitedPrecedent]
    statutory_gate_warnings: List[str] = []
