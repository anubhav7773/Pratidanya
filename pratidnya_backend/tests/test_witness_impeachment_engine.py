import pytest
import httpx
from app.main import app
from app.core.security import verify_advocate_token
from app.schemas.witness_impeachment_schema import WitnessImpeachmentAuditRequest
from app.services.witness_impeachment_engine import WitnessImpeachmentEngine

def test_tahsildar_singh_material_improvement_omission():
    """Verifies that an eyewitness introducing a direct shooting claim in court absent in 161 is flagged under Tahsildar Singh."""
    req = WitnessImpeachmentAuditRequest(
        case_id="MURDER-TRIAL-PW2",
        witness_code="PW-2",
        witness_name="चंदन सिंह",
        witness_role="EYEWITNESS",
        fir_narrative="दो अज्ञात व्यक्ति मोटरसाइकिल से भागते दिखे।",
        sec_161_crpc_statement="चीख सुनकर मैं मौके पर पहुंचा। पीड़ित बेहोश पड़ा था। गोली किसने चलाई यह मैं नहीं देख सका था।", # Denied seeing shooter
        sec_164_crpc_statement="रमेश और सुरेश मोटरसाइकिल पर थे।",
        court_deposition_chief="मैंने अभियुक्त रमेश को हाथ में पिस्तौल तानकर मृतक की छाती पर दो फायर करते प्रत्यक्ष देखा था।", # Direct shooting claim
        defense_theory="FALSE_IMPLICATION_AND_SUBSTANTIAL_IMPROVEMENT"
    )

    result = WitnessImpeachmentEngine.audit_witness_testimony(req)

    assert result.has_fatal_contradictions is True
    assert len(result.grid_analysis) >= 1
    improvement = result.grid_analysis[0]

    assert improvement.classification in [
        "MATERIAL_IMPROVEMENT_AMOUNTING_TO_CONTRADICTION",
        "DIRECT_SUBSTANTIVE_CONTRADICTION"
    ]
    assert improvement.severity == "FATAL"
    assert "Ex. D-1" in improvement.marked_exhibit_identifier
    assert "तहसीलदार सिंह" in result.confrontation_master_script_hindi
    assert len(result.io_cross_examination_reminders) >= 1
    assert "अन्वेषण अधिकारी" in result.io_cross_examination_reminders[0]

def test_witness_corroborating_consistency():
    """Verifies that consistent statements without material deviations do not trigger fatal contradictions."""
    req = WitnessImpeachmentAuditRequest(
        case_id="THEFT-CONSISTENT",
        witness_code="PW-1",
        witness_name="रामू",
        witness_role="COMPLAINANT",
        sec_161_crpc_statement="दुकान का ताला टूटा था और गल्ले से पचास हजार रुपये गायब थे।",
        court_deposition_chief="दुकान का ताला टूटा था और गल्ले से पचास हजार रुपये गायब थे।"
    )

    result = WitnessImpeachmentEngine.audit_witness_testimony(req)

    assert result.has_fatal_contradictions is False
    assert result.grid_analysis[0].classification == "CORROBORATING_PASSAGE"

@pytest.mark.asyncio
async def test_generate_contradiction_grid_api():
    """Verifies that POST /api/v1/trial/generate-contradiction-grid responds successfully."""
    async def mock_verify_advocate():
        return {"uid": "advocate_test_uid", "role": "advocate"}

    app.dependency_overrides[verify_advocate_token] = mock_verify_advocate

    try:
        payload = {
            "case_id": "TEST-TRIAL-PW1",
            "witness_code": "PW-1",
            "witness_name": "राम किशोर",
            "witness_role": "EYEWITNESS",
            "sec_161_crpc_statement": "मैं घर पर था और बाहर शोर सुनकर निकला था।",
            "court_deposition_chief": "मैंने अभियुक्त को पिस्तौल से गोली चलाते हुए देखा था।",
            "accused_name": "विकास",
            "police_station": "हजरतगंज",
            "district": "लखनऊ"
        }

        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/v1/trial/generate-contradiction-grid",
                json=payload,
                headers={"Authorization": "Bearer mock_token"}
            )
            assert resp.status_code == 200, resp.text
            data = resp.json()
            assert data["case_id"] == "TEST-TRIAL-PW1"
            assert data["has_fatal_contradictions"] is True
            assert "confrontation_master_script_hindi" in data
            assert len(data["grid_analysis"]) >= 1
    finally:
        app.dependency_overrides.clear()
