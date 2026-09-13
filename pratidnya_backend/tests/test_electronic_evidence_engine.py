import pytest
from app.schemas.electronic_evidence_schema import (
    ElectronicEvidenceAuditRequest,
    DeviceIdentifierDetails
)
from app.services.electronic_evidence_engine import ElectronicEvidenceEngine

def test_missing_part_b_and_missing_hash_fatal_inadmissible():
    """Verifies that absence of Part B and absence of hash value triggers fatal defects under Arjun Khotkar."""
    req = ElectronicEvidenceAuditRequest(
        case_id="EVID-TEST-01",
        exhibit_mark="Ex. P-14",
        evidence_type="CALL_DETAIL_RECORD_CDR",
        certificate_statute="BSA_SECTION_63",
        schedule_format_matched=True,
        part_a_executed=True,
        part_b_executed=False,  # Missing Part B Expert signature
        hash_algorithm="NONE",   # Missing hash algorithm
        declared_hash_value=None,
        device_identifiers=DeviceIdentifierDetails(make_model="Nokia Server"),
        contemporaneous_acquisition=False
    )

    result = ElectronicEvidenceEngine.audit_certificate(req)

    assert result.admissibility_status == "FATAL_DEFECT_INADMISSIBLE"
    assert result.is_schedule_compliant is False
    assert result.is_hash_valid is False
    assert len(result.statutory_defects) >= 3
    assert any("भाग ख" in d.statutory_clause for d in result.statutory_defects)
    assert any("क्रिप्टोग्राफिक हैश" in d.statutory_clause for d in result.statutory_defects)
    assert "अर्जुन पंडितराव खोतकर" in result.written_objection_petition_draft

def test_valid_sha256_hash_and_schedule_matched():
    """Verifies that a valid SHA-256 hash and completed two-part schedule is considered prima facie admissible."""
    valid_sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

    req = ElectronicEvidenceAuditRequest(
        case_id="EVID-TEST-VALID",
        exhibit_mark="Ex. P-20",
        evidence_type="CCTV_DVR_FOOTAGE",
        certificate_statute="BSA_SECTION_63",
        schedule_format_matched=True,
        part_a_executed=True,
        part_b_executed=True,
        part_b_expert_designation="Senior Forensic Analyst, FSL",
        hash_algorithm="SHA256",
        declared_hash_value=valid_sha256,
        device_identifiers=DeviceIdentifierDetails(
            make_model="Hikvision DVR 16-Channel",
            serial_number="HK12345678",
            mac_address="00:1A:2B:3C:4D:5E"
        ),
        contemporaneous_acquisition=True
    )

    result = ElectronicEvidenceEngine.audit_certificate(req)

    assert result.admissibility_status == "PRIMA_FACIE_ADMISSIBLE"
    assert result.is_schedule_compliant is True
    assert result.is_hash_valid is True
    assert len(result.statutory_defects) == 0

def test_invalid_hash_digest_format_triggers_fatal_defect():
    """Verifies that a malformed hash string (e.g. truncated) triggers hash validation failure."""
    req = ElectronicEvidenceAuditRequest(
        case_id="EVID-MALFORMED-HASH",
        exhibit_mark="Ex. P-05",
        evidence_type="WHATSAPP_CHAT_EXPORT",
        certificate_statute="BSA_SECTION_63",
        schedule_format_matched=True,
        part_a_executed=True,
        part_b_executed=True,
        hash_algorithm="SHA256",
        declared_hash_value="abc123short",  # Invalid SHA-256 digest
        device_identifiers=DeviceIdentifierDetails(imei_number="861234567890123"),
        contemporaneous_acquisition=True
    )

    result = ElectronicEvidenceEngine.audit_certificate(req)

    assert result.admissibility_status == "FATAL_DEFECT_INADMISSIBLE"
    assert result.is_hash_valid is False
    assert any("हैश सत्यापन" in d.statutory_clause for d in result.statutory_defects)

@pytest.mark.asyncio
async def test_audit_bsa_certificate_api():
    """Verifies that POST /api/v1/evidence/audit-bsa-certificate works over HTTP."""
    import httpx
    from app.main import app
    from app.core.security import verify_advocate_token

    app.dependency_overrides[verify_advocate_token] = lambda: {"uid": "adv_evidence_test"}
    try:
        payload = {
            "case_id": "API-EVID-CASE",
            "exhibit_mark": "Ex. P-10",
            "evidence_type": "TOWER_DUMP",
            "certificate_statute": "BSA_SECTION_63",
            "schedule_format_matched": False,
            "part_a_executed": False,
            "part_b_executed": False,
            "hash_algorithm": "NONE",
            "device_identifiers": {
                "make_model": "Cisco Router"
            },
            "contemporaneous_acquisition": False,
            "accused_name": "संजय यादव",
            "police_station": "हजरतगंज",
            "district": "लखनऊ"
        }

        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/v1/evidence/audit-bsa-certificate",
                json=payload,
                headers={"Authorization": "Bearer mock_token"}
            )
            assert resp.status_code == 200, resp.text
            data = resp.json()
            assert data["admissibility_status"] == "FATAL_DEFECT_INADMISSIBLE"
            assert data["is_schedule_compliant"] is False
            assert "written_objection_petition_draft" in data
            assert len(data["statutory_defects"]) >= 1
    finally:
        app.dependency_overrides.clear()
