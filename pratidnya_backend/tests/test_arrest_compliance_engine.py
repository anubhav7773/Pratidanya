import pytest
from datetime import datetime, timezone, timedelta
from app.schemas.arrest_compliance_schema import (
    ArrestComplianceAuditRequest,
    OffenseChargeDetail
)
from app.services.arrest_compliance_engine import ArrestComplianceEngine

def test_satender_antil_category_a_void_arrest():
    """Verifies that an offense <= 7 yrs without Sec 35 notice triggers fatal violation & Category A."""
    now = datetime.now(timezone.utc)
    arrest_time = now - timedelta(hours=10)

    req = ArrestComplianceAuditRequest(
        case_id="ARREST-CASE-41A",
        accused_name="दिनेश कुमार",
        police_station="गोमती नगर",
        district="लखनऊ",
        charges=[
            OffenseChargeDetail(act="BNS", section="115(2)", max_punishment_years=1),
            OffenseChargeDetail(act="BNS", section="352", max_punishment_years=2),
            OffenseChargeDetail(act="BNS", section="351(2)", max_punishment_years=3)
        ],
        arrest_timestamp=arrest_time,
        remand_production_timestamp=now,
        notice_issued_sec_35_bnss=False,
        flight_or_tampering_risk_recorded=False,
        arrest_memo_witness_count=0,
        family_intimation_recorded=False,
        medical_examination_conducted=True,
        magistrate_independent_reasons_recorded=False
    )

    result = ArrestComplianceEngine.audit_arrest(req)

    assert result.antil_category == "CATEGORY_A"
    assert result.compliance_verdict == "NON_COMPLIANT_VOID_ARREST"
    assert len(result.violations) >= 2
    assert any("धारा 35(3) बी.एन.एस.एस." in v.statutory_provision for v in result.violations)
    assert any("धारा 36 बी.एन.एस.एस." in v.statutory_provision for v in result.violations)
    assert "अर्नेश कुमार" in result.instant_objection_petition_draft
    assert "सतेन्द्र कुमार अंतिल" in result.instant_objection_petition_draft

def test_article_22_2_over_24_hour_production_violation():
    """Verifies that production after 28 hours triggers constitutional detention bar."""
    now = datetime.now(timezone.utc)
    arrest_time = now - timedelta(hours=28)

    req = ArrestComplianceAuditRequest(
        case_id="TIME-BARRED-ARREST",
        charges=[
            OffenseChargeDetail(act="BNS", section="303(2)", max_punishment_years=3)
        ],
        arrest_timestamp=arrest_time,
        remand_production_timestamp=now,
        notice_issued_sec_35_bnss=True,
        flight_or_tampering_risk_recorded=True,
        arrest_memo_witness_count=1,
        family_intimation_recorded=True,
        medical_examination_conducted=True,
        magistrate_independent_reasons_recorded=True
    )

    result = ArrestComplianceEngine.audit_arrest(req)

    assert result.is_constitutionally_time_barred is True
    assert result.hours_to_production >= 28.0
    assert any("अनुच्छेद 22(2)" in v.statutory_provision for v in result.violations)

def test_category_c_special_act_classification():
    """Verifies that special acts like NDPS are mapped to Satender Antil Category C."""
    now = datetime.now(timezone.utc)

    req = ArrestComplianceAuditRequest(
        case_id="NDPS-CATEGORY-C",
        charges=[
            OffenseChargeDetail(act="NDPS", section="20", max_punishment_years=10, is_special_act=True)
        ],
        arrest_timestamp=now - timedelta(hours=5),
        remand_production_timestamp=now,
        notice_issued_sec_35_bnss=False,
        flight_or_tampering_risk_recorded=True,
        arrest_memo_witness_count=2,
        family_intimation_recorded=True,
        medical_examination_conducted=True,
        magistrate_independent_reasons_recorded=True
    )

    result = ArrestComplianceEngine.audit_arrest(req)

    assert result.antil_category == "CATEGORY_C"

@pytest.mark.asyncio
async def test_audit_arrest_compliance_api():
    """Verifies that POST /api/v1/remand/audit-arrest-compliance works over HTTP."""
    import httpx
    from app.main import app
    from app.core.security import verify_advocate_token

    app.dependency_overrides[verify_advocate_token] = lambda: {"uid": "adv_arrest_test"}
    try:
        now = datetime.now(timezone.utc)
        payload = {
            "case_id": "API-ARREST-CASE",
            "accused_name": "रामसेवक",
            "police_station": "गोमती नगर",
            "district": "लखनऊ",
            "charges": [
                {"act": "BNS", "section": "115(2)", "max_punishment_years": 1, "is_special_act": False, "is_economic_offense": False}
            ],
            "arrest_timestamp": (now - timedelta(hours=6)).isoformat(),
            "remand_production_timestamp": now.isoformat(),
            "notice_issued_sec_35_bnss": False,
            "flight_or_tampering_risk_recorded": False,
            "arrest_memo_witness_count": 0,
            "family_intimation_recorded": False,
            "medical_examination_conducted": True,
            "magistrate_independent_reasons_recorded": False
        }

        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            res = await client.post(
                "/api/v1/remand/audit-arrest-compliance",
                json=payload,
                headers={"Authorization": "Bearer dummy_token"}
            )
            assert res.status_code == 200
            data = res.json()
            assert data["antil_category"] == "CATEGORY_A"
            assert data["compliance_verdict"] == "NON_COMPLIANT_VOID_ARREST"
            assert len(data["violations"]) >= 2
    finally:
        app.dependency_overrides.pop(verify_advocate_token, None)
