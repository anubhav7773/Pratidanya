import pytest
from datetime import datetime, timezone, timedelta
from app.schemas.malkhana_schema import MalkhanaAuditRequest
from app.services.malkhana_engine import MalkhanaEngine

def test_malkhana_fatal_chain_break_34_day_delay_and_no_specimen_seal():
    """Verifies that delayed FSL dispatch (34 days) + missing Namuna Mohar triggers fatal chain break under Gurmail Singh."""
    now = datetime.now(timezone.utc)
    seizure_time = now - timedelta(days=36)
    deposit_time = now - timedelta(days=35)
    dispatch_time = now - timedelta(days=2)
    received_time = now - timedelta(days=1)

    req = MalkhanaAuditRequest(
        case_id="NDPS-LKO-2024-44",
        act_type="NDPS",
        seizure_date=seizure_time,
        seizure_seal_impression="POLICE THANA HAZRATGANJ_A1",
        malkhana_deposit_date=deposit_time,
        malkhana_register_number="Reg-19/Item-402",
        specimen_seal_deposited=False,  # Namuna Mohar absent
        fsl_dispatch_date=dispatch_time,
        fsl_received_date=received_time,
        fsl_receipt_seal_impression="POLICE_SEAL_ILLEGIBLE", # Damaged/Illegible seal
        road_certificate_annexed=False,  # Road Certificate missing
        accused_name="रामू",
        police_station="हजरतगंज",
        district="लखनऊ"
    )

    result = MalkhanaEngine.audit_malkhana_chain(req)

    assert result.is_chain_of_custody_intact is False
    assert result.has_fatal_tampering_risk is True
    assert result.fsl_dispatch_delay_days >= 34
    assert len(result.fatal_vulnerabilities) >= 3

    # Check for specific fatal issues
    issue_codes = [v.issue_code for v in result.fatal_vulnerabilities]
    assert "DELAYED_FSL_DISPATCH" in issue_codes
    assert "SPECIMEN_SEAL_ABSENT" in issue_codes
    assert "ROAD_CERTIFICATE_MISSING" in issue_codes
    assert "SEAL_TAMPERING_MISMATCH" in issue_codes

    # Verify generated Section 254 BNSS petition content
    assert "धारा 254(2) भारतीय नागरिक सुरक्षा संहिता" in result.application_sec_254_bnss_draft_hindi
    assert "गुरमैल सिंह" in result.application_sec_254_bnss_draft_hindi
    assert "नूर आगा" in result.application_sec_254_bnss_draft_hindi
    assert len(result.cross_examination_carrier_questions) >= 4

def test_malkhana_intact_timely_dispatch_and_valid_seals():
    """Verifies that timely dispatch (2 days) with specimen seal and matching seals produces an intact chain."""
    now = datetime.now(timezone.utc)
    seizure_time = now - timedelta(days=3)
    deposit_time = now - timedelta(days=3)
    dispatch_time = now - timedelta(days=1)
    received_time = now

    req = MalkhanaAuditRequest(
        case_id="NDPS-VALID-CUSTODY",
        act_type="NDPS",
        seizure_date=seizure_time,
        seizure_seal_impression="SEAL_CW_99",
        malkhana_deposit_date=deposit_time,
        malkhana_register_number="Reg-19/Item-105",
        specimen_seal_deposited=True,
        fsl_dispatch_date=dispatch_time,
        fsl_received_date=received_time,
        fsl_receipt_seal_impression="SEAL_CW_99",
        road_certificate_annexed=True,
        road_certificate_number="RC-402/2026",
        carrier_constable_name="कांस्टेबल अजय कुमार"
    )

    result = MalkhanaEngine.audit_malkhana_chain(req)

    assert result.is_chain_of_custody_intact is True
    assert result.has_fatal_tampering_risk is False
    assert result.fsl_dispatch_delay_days <= 3
    assert len(result.fatal_vulnerabilities) == 0
