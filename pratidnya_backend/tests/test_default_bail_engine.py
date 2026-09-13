import pytest
from datetime import datetime, timezone, timedelta
from app.schemas.remand_schema import DefaultBailAuditRequest, OffenseSectionItem
from app.services.default_bail_engine import DefaultBailEngine

def test_90_day_default_bail_crystallization():
    """Verifies that an offense punishable >= 10 yrs (e.g. 302/103 BNS) triggers 90-day threshold and accrues."""
    now = datetime.now(timezone.utc)
    # 91 days ago
    first_remand = now - timedelta(days=91)

    req = DefaultBailAuditRequest(
        case_id="TEST-CASE-90",
        first_remand_date=first_remand,
        statutory_regime="BNSS",
        offense_sections=[
            OffenseSectionItem(act="BNS", section="103(1)", max_punishment_years=99)
        ],
        chargesheet_filed=False,
        accused_name="रामू",
        police_station="कोतवाली",
        district="लखनऊ"
    )

    result = DefaultBailEngine.audit_default_bail(req)

    assert result.statutory_threshold_days == 90
    assert result.days_elapsed_in_custody >= 91
    assert result.is_default_bail_crystallized is True
    assert "धारा 187(3) भारतीय नागरिक सुरक्षा संहिता" in result.statutory_petition_draft_hindi
    assert "बिक्रमजीत सिंह" in result.cited_precedents[0].case_title

def test_incomplete_chargesheet_defect_detection():
    """Verifies that filing an NDPS chargesheet without FSL Chemical Report is flagged as incomplete under Kapil Wadhawan."""
    now = datetime.now(timezone.utc)
    first_remand = now - timedelta(days=185)

    req = DefaultBailAuditRequest(
        case_id="NDPS-COMM-CASE",
        first_remand_date=first_remand,
        statutory_regime="BNSS",
        offense_sections=[
            OffenseSectionItem(act="NDPS", section="20(b)(ii)(C)", max_punishment_years=20)
        ],
        chargesheet_filed=True,
        chargesheet_filing_date=now - timedelta(days=5),
        # Lacks FSL_CHEMICAL_EXAMINER_REPORT
        chargesheet_annexures=["SITE_PLAN", "WITNESS_STATEMENTS"],
        accused_name="विकास",
        police_station="हजरतगंज",
        district="लखनऊ"
    )

    result = DefaultBailEngine.audit_default_bail(req)

    assert result.statutory_threshold_days == 180
    assert result.is_chargesheet_incomplete is True
    assert "FSL_CHEMICAL_EXAMINER_REPORT" in result.missing_mandatory_reports
    assert result.defect_type == "SUBTERFUGE_INCOMPLETE_CHARGESHEET"
    # Even though chargesheet was filed, it is legally incomplete, so default bail crystallizes
    assert result.is_default_bail_crystallized is True
    assert "कपिल वाधवान" in result.statutory_petition_draft_hindi

def test_section_187_bnss_split_police_custody_expiry():
    """Verifies that after 40 days (for 60-day threshold), police custody window is permanently closed."""
    now = datetime.now(timezone.utc)
    first_remand = now - timedelta(days=42)

    req = DefaultBailAuditRequest(
        case_id="THEFT-379",
        first_remand_date=first_remand,
        statutory_regime="BNSS",
        offense_sections=[
            OffenseSectionItem(act="BNS", section="303(2)", max_punishment_years=3)
        ],
        chargesheet_filed=False,
        accused_name="सोनू",
        police_station="कैसरबाग",
        district="लखनऊ"
    )

    result = DefaultBailEngine.audit_default_bail(req)

    assert result.statutory_threshold_days == 60
    assert result.police_custody_window_expired is True
    assert "प्रथम 40 दिन बीत चुके हैं" in result.police_custody_alert_hindi

@pytest.mark.asyncio
async def test_remand_api_endpoint_audit():
    """Verifies that FastAPI /api/v1/remand/audit-default-bail returns 200 and valid schema."""
    import httpx
    from app.main import app
    from app.core.security import verify_advocate_token

    app.dependency_overrides[verify_advocate_token] = lambda: {"uid": "adv_test_456"}
    try:
        now = datetime.now(timezone.utc)
        payload = {
            "case_id": "API-TEST-CASE",
            "first_remand_date": (now - timedelta(days=95)).isoformat(),
            "statutory_regime": "BNSS",
            "offense_sections": [
                {"act": "BNS", "section": "103(1)", "max_punishment_years": 99}
            ],
            "chargesheet_filed": False,
            "accused_name": "रोहित",
            "police_station": "हजरतगंज",
            "district": "लखनऊ"
        }

        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            res = await client.post(
                "/api/v1/remand/audit-default-bail",
                json=payload,
                headers={"Authorization": "Bearer dummy_test_token"}
            )
            assert res.status_code == 200
            data = res.json()
            assert data["case_id"] == "API-TEST-CASE"
            assert data["is_default_bail_crystallized"] is True
            assert data["statutory_threshold_days"] == 90
            assert len(data["cited_precedents"]) == 3
    finally:
        app.dependency_overrides.pop(verify_advocate_token, None)

