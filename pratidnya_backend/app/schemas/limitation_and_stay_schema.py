from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import date

class LimitationCheckRequest(BaseModel):
    pleading_id: str = Field(..., description="UUID of high_court_pleadings record")
    judgment_date: date = Field(..., description="दिनांक जिस दिन आक्षेपित निर्णय सुनाया गया")
    certified_copy_applied_date: date = Field(..., description="नकल प्रमाणित प्रति हेतु आवेदन दिनांक")
    certified_copy_ready_date: date = Field(..., description="नकल तैयार/वितरित होने का दिनांक")
    proposed_filing_date: date = Field(default_factory=date.today, description="उच्च न्यायालय में याचिका दाखिल करने का दिनांक")
    pleading_type: str = Field(default="CRIMINAL_APPEAL", description="'CRIMINAL_APPEAL' or 'CRIMINAL_REVISION'")

class LimitationEvaluationResponse(BaseModel):
    pleading_id: str
    pleading_type: str
    statutory_limitation_days: int = Field(..., description="Appeal: 60 Days (Art 115(b)), Revision: 90 Days (Art 131)")
    certified_copy_excluded_days: int = Field(..., description="धारा 12 मियाद अधिनियम के तहत घटाई गई नकल अवधि")
    effective_days_taken: int = Field(..., description="नकल अवधि घटाने के उपरांत कुल प्रयुक्त कार्यदिवस")
    is_delayed: bool = Field(..., description="क्या याचिका मियाद समाप्त होने के उपरांत दाखिल की जा रही है")
    delay_days: int = Field(..., description="मियाद से अतिरिक्त दिनों की संख्या")
    limitation_expiry_date: date = Field(..., description="याचिका दाखिल करने की अंतिम वैधानिक तिथि")
    must_file_section_5_application: bool

class GenerateSection5DelayRequest(BaseModel):
    pleading_id: str
    pairokar_name: str = Field(..., description="शपथकर्ता/पैरोकार का नाम")
    pairokar_relation: str = Field(..., description="उदा. 'अभियुक्त का सगा भाई' या 'अधिवक्ता का क्लर्क'")
    pairokar_age: int = Field(..., description="शपथकर्ता की आयु")
    pairokar_address: str = Field(..., description="शपथकर्ता का पूर्ण आवासीय पता")
    primary_delay_reason: str = Field(
        default="POVERTY_AND_JAIL_COMMUNICATION",
        description="'POVERTY_AND_JAIL_COMMUNICATION', 'APPELLANT_ILLNESS', 'COUNSEL_ADVICE_DELAY', 'FINANCIAL_DISTRESS'"
    )
    custom_narrative: Optional[str] = Field(default=None, description="विलंब के विशिष्ट तथ्यात्मक कारण")

class Section5DelayApplicationResponse(BaseModel):
    pleading_id: str
    court_header: str
    cause_title: str
    application_title_hindi: str
    delay_grounds: List[str]
    prayer_text_hindi: str
    affidavit_header: str
    affidavit_deponent_block: str
    affidavit_paragraphs: List[str]
    affidavit_verification_clause: str

class GenerateSuspensionBailRequest(BaseModel):
    pleading_id: str
    statute_system: str = Field(default="IPC_CRPC", description="'IPC_CRPC' (Sec 389) or 'BNS_BNSS' (Sec 430)")
    trial_bail_status: str = Field(default="ON_BAIL_NEVER_MISUSED", description="'ON_BAIL_NEVER_MISUSED' or 'IN_JAIL_THROUGHOUT'")
    fine_deposit_status: str = Field(default="READY_TO_DEPOSIT", description="'ALREADY_DEPOSITED' or 'READY_TO_DEPOSIT' or 'SEEKING_STAY'")
    pairokar_name: str
    pairokar_relation: str
    pairokar_age: int
    pairokar_address: str

class SuspensionBailApplicationResponse(BaseModel):
    pleading_id: str
    statutory_provision: str
    application_title_hindi: str
    grounds_for_suspension: List[str]
    interim_bail_prayer: str
    affidavit_text_hindi: str
    cited_precedents: List[Dict[str, str]]
