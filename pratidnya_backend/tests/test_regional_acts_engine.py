import pytest
import httpx
from app.main import app
from app.core.security import verify_advocate_token
from app.schemas.regional_acts_schema import (
    RegionalActsAuditRequest,
    BasePredicateCaseRecord
)
from app.services.regional_acts_engine import RegionalActsEngine

def test_up_gangsters_farhana_and_rule_5_collapse():
    """Verifies that lack of Rule 5 joint meeting and acquittal in all base cases triggers Farhana collapse."""
    req = RegionalActsAuditRequest(
        case_id="GANG-LKO-2024-01",
        statute_applied="UP_GANGSTERS_ACT_1986",
        district="लखनऊ",
        police_station="कोतवाली नगर",
        accused_name="रवि प्रकाश",
        joint_meeting_rule_5_documented=False,  # Rule 5 joint meeting missing
        dm_independent_mind_applied=False,      # Rubber stamped
        dm_endorsement_raw_text="Approved as recommended (संस्तुति स्वीकृत)",
        base_cases=[
            BasePredicateCaseRecord(
                crime_number="मु.अ.सं. 112/2021",
                sections="379/411 IPC",
                status="ACQUITTED_ON_MERITS",
                disposal_date="2023-11-20"
            )
        ]
    )

    result = RegionalActsEngine.audit_regional_act(req)

    assert result.procedural_viability == "FATALLY_DEFECTIVE_CHALLENGEABLE"
    assert result.is_farhana_collapse_triggered is True
    assert len(result.grounds_of_challenge) >= 3

    doctrines = [g.doctrine for g in result.grounds_of_challenge]
    assert any("नियम 5(3)(a)" in d for d in doctrines)
    assert any("नियम 16" in d for d in doctrines)
    assert any("फरहाना बनाम उत्तर प्रदेश राज्य" in d for d in doctrines)

    assert "अनुच्छेद 226" in result.draft_petition_hindi
    assert "फरहाना बनाम उत्तर प्रदेश राज्य" in result.draft_petition_hindi

def test_up_goondas_ramji_pandey_notice_defect():
    """Verifies that a Goondas Act notice only listing crime numbers without material allegations is void ab initio under Ramji Pandey."""
    req = RegionalActsAuditRequest(
        case_id="GOONDAS-PRAYAGRAJ-2026",
        statute_applied="UP_GOONDAS_ACT_1970",
        district="प्रयागराज",
        police_station="सिविल लाइन्स",
        accused_name="अजय यादव",
        notice_has_material_allegations=False,  # No narrative of terror/public panic
        notice_only_lists_firs=True             # Bare listing of crime numbers
    )

    result = RegionalActsEngine.audit_regional_act(req)

    assert result.procedural_viability == "FATALLY_DEFECTIVE_CHALLENGEABLE"
    assert result.is_ramji_pandey_defect_triggered is True
    assert len(result.grounds_of_challenge) >= 1
    assert "रामजी पांडेय बनाम उत्तर प्रदेश राज्य" in result.grounds_of_challenge[0].doctrine
    assert "रामजी पांडेय" in result.draft_petition_hindi

@pytest.mark.asyncio
async def test_audit_up_special_acts_api():
    """Verifies that POST /api/v1/regional/audit-up-special-acts responds successfully."""
    async def mock_verify_advocate():
        return {"uid": "advocate_test_uid", "role": "advocate"}

    app.dependency_overrides[verify_advocate_token] = mock_verify_advocate

    try:
        payload = {
            "case_id": "TEST-GANGSTERS-01",
            "statute_applied": "UP_GANGSTERS_ACT_1986",
            "district": "लखनऊ",
            "police_station": "कोतवाली नगर",
            "accused_name": "विकास",
            "joint_meeting_rule_5_documented": False,
            "dm_independent_mind_applied": False,
            "dm_endorsement_raw_text": "Approved as recommended",
            "base_cases": [
                {
                    "crime_number": "101/2020",
                    "sections": "379 IPC",
                    "status": "ACQUITTED_ON_MERITS"
                }
            ]
        }

        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/v1/regional/audit-up-special-acts",
                json=payload,
                headers={"Authorization": "Bearer mock_token"}
            )
            assert resp.status_code == 200, resp.text
            data = resp.json()
            assert data["case_id"] == "TEST-GANGSTERS-01"
            assert data["procedural_viability"] == "FATALLY_DEFECTIVE_CHALLENGEABLE"
            assert data["is_farhana_collapse_triggered"] is True
            assert "draft_petition_hindi" in data
    finally:
        app.dependency_overrides.clear()
