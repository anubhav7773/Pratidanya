import re
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, field_validator
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema

class DeviceIdentifierDetails(BaseModel):
    make_model: Optional[str] = Field(default=None, description="Make and model of the electronic device")
    serial_number: Optional[str] = Field(default=None, description="Hardware serial number")
    imei_number: Optional[str] = Field(default=None, description="IMEI number for mobile/cellular devices")
    mac_address: Optional[str] = Field(default=None, description="Network MAC address for network/DVR devices")

class ElectronicEvidenceAuditRequest(StrictInputSchema):
    case_id: str
    exhibit_mark: str = Field(..., description="Exhibit or Mark identifier, e.g., 'Ex. P-14'")
    evidence_type: str = Field(
        ...,
        description="'CALL_DETAIL_RECORD_CDR', 'TOWER_DUMP', 'WHATSAPP_CHAT_EXPORT', 'CCTV_DVR_FOOTAGE', 'MOBILE_FORENSIC_IMAGE', 'AUDIO_VOICE_RECORDING', 'SERVER_SYSTEM_LOGS'"
    )
    certificate_statute: str = Field(default="BSA_SECTION_63", description="'BSA_SECTION_63' or 'IEA_SECTION_65B'")
    schedule_format_matched: bool = Field(
        default=False,
        description="Whether certificate aligns with the Schedule format under Section 63(4)(c) BSA 2023"
    )
    part_a_executed: bool = Field(default=False, description="Executed by person producing record (Part A)")
    part_a_signatory_type: Optional[str] = Field(default="INVESTIGATING_OFFICER", description="'INVESTIGATING_OFFICER', 'NODAL_OFFICER', 'COMPLAINANT', 'NONE'")
    part_b_executed: bool = Field(default=False, description="Executed by Forensic/Cyber Expert (Part B)")
    part_b_expert_designation: Optional[str] = Field(default=None, description="Designation of certifying expert")
    hash_algorithm: str = Field(default="NONE", description="'SHA256', 'SHA1', 'MD5', 'NONE'")
    declared_hash_value: Optional[str] = Field(default=None, description="Alphanumeric cryptographic hash digest")
    device_identifiers: DeviceIdentifierDetails = Field(default_factory=DeviceIdentifierDetails)
    contemporaneous_acquisition: bool = Field(
        default=True,
        description="Whether certificate was executed contemporaneously at the time of data acquisition"
    )
    accused_name: str = Field(default="अभियुक्त")
    police_station: str = Field(default="कोतवाली नगर")
    district: str = Field(default="लखनऊ")
    court_name: str = Field(default="न्यायालय अपर सत्र न्यायाधीश / मुख्य न्यायिक मजिस्ट्रेट")

class StatutoryDefectItem(BaseModel):
    statutory_clause: str
    governing_doctrine: str
    severity: str  # 'FATAL', 'MATERIAL', 'PROCEDURAL'
    defect_description_hindi: str
    trial_countermeasure: str

class ElectronicEvidenceAuditResponse(StrictOutputSchema):
    case_id: str
    exhibit_mark: str
    admissibility_status: str  # 'FATAL_DEFECT_INADMISSIBLE', 'SUBSTANTIAL_REGULARITY_CHALLENGEABLE', 'PRIMA_FACIE_ADMISSIBLE'
    is_schedule_compliant: bool
    is_hash_valid: bool
    statutory_defects: List[StatutoryDefectItem]
    actionable_courtroom_objection: str
    written_objection_petition_draft: str
    cited_precedents: List[Dict[str, str]]
