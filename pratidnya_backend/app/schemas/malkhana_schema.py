from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class MalkhanaAuditRequest(StrictInputSchema):
    case_id: str
    act_type: str = Field(default="NDPS", description="'NDPS', 'ARMS_ACT', 'BNS_IPC_FORENSICS', 'EXCISE_ACT'")
    seizure_date: datetime = Field(..., description="Timestamp of recovery / seizure memo (Fard Baramadgi)")
    seizure_seal_impression: str = Field(..., description="Seal text on seizure memo (e.g., 'POLICE THANA HAZRATGANJ_A1')")
    malkhana_deposit_date: datetime = Field(..., description="Date & time deposited in Thana Malkhana")
    malkhana_register_number: str = Field(..., description="Register No. 19 Entry, e.g., 'Reg-19/Item-402'")
    specimen_seal_deposited: bool = Field(
        default=False,
        description="Whether 'Namuna Mohar' (Specimen Seal Impression) was deposited with Malkhana Moharrir"
    )
    gd_deposit_entry_number: Optional[str] = Field(default=None, description="General Diary entry of deposit")
    fsl_dispatch_date: datetime = Field(..., description="Date when carrier constable was dispatched to FSL")
    fsl_received_date: datetime = Field(..., description="Date acknowledgment receipt was stamped at FSL")
    fsl_receipt_seal_impression: str = Field(
        ...,
        description="Seal impression noted on FSL acknowledgment report (e.g. 'POLICE_SEAL_ILLEGIBLE')"
    )
    road_certificate_annexed: bool = Field(
        default=False,
        description="Whether Road Certificate (RC / रवानगी रसीद) is annexed to chargesheet"
    )
    road_certificate_number: Optional[str] = Field(default=None, description="Road Certificate reference number")
    carrier_constable_name: Optional[str] = Field(default="कांस्टेबल वाहक", description="Name of constable carrier")
    accused_name: str = Field(default="अभियुक्त")
    police_station: str = Field(default="कोतवाली नगर")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय विशेष न्यायाधीश (एन.डी.पी.एस. एक्ट)")

class CustodyVulnerabilityItem(BaseModel):
    issue_code: str  # 'DELAYED_FSL_DISPATCH', 'SPECIMEN_SEAL_ABSENT', 'ROAD_CERTIFICATE_MISSING', 'SEAL_TAMPERING_MISMATCH'
    severity: str    # 'FATAL_CHAIN_BREAK', 'MATERIAL_TAMPERING_RISK'
    statutory_violation_hindi: str
    impact_analysis_hindi: str
    precedent_authority: str

class MalkhanaAuditResponse(StrictOutputSchema):
    case_id: str
    is_chain_of_custody_intact: bool
    has_fatal_tampering_risk: bool
    fsl_dispatch_delay_days: int
    fatal_vulnerabilities: List[CustodyVulnerabilityItem]
    actionable_defense_strategy_hindi: str
    application_sec_254_bnss_draft_hindi: str
    cross_examination_carrier_questions: List[str]
    cited_precedents: List[Dict[str, str]]
