import pytest
from datetime import date, timedelta
from app.schemas.undertrial_schema import (
    UndertrialReliefAuditRequest,
    OffenseSentenceInput
)
from app.services.undertrial_relief_engine import UndertrialReliefEngine

def test_first_time_offender_one_third_relief_qualification():
    """Verifies that a first-time offender charged under 420 IPC (7 yrs = 84 mos) qualifies after 28 mos."""
    calc_date = date(2024, 9, 1)
    # 29.6 months earlier (~900 days)
    start_date = calc_date - timedelta(days=900)

    req = UndertrialReliefAuditRequest(
        case_id="UT-RELIEF-1",
        accused_name="श्यामू",
        jail_name="जिला कारागार वाराणसी",
        custody_start_date=start_date,
        calculation_date=calc_date,
        is_first_time_offender=True,
        multiple_cases_pending=False,
        charges=[
            OffenseSentenceInput(act="IPC", section="420", max_term_months=84, is_capital_or_life=False),
            OffenseSentenceInput(act="IPC", section="468", max_term_months=84, is_capital_or_life=False)
        ],
        fir_number="मु.अ.सं. 112/2022",
        police_station="कैंट",
        district="वाराणसी"
    )

    result = UndertrialReliefEngine.audit_undertrial_relief(req)

    assert result.statutory_threshold_fraction == "1/3"
    assert result.threshold_months == 28.0
    assert result.actual_detention_served_months >= 29.0
    assert result.is_relief_applicable is True
    assert result.is_disqualified is False
    assert result.overstay_months > 1.0
    assert "धारा 479(1) प्रथम परंतुक" in result.court_application_draft_hindi
    assert "धारा 479(3)" in result.jail_superintendent_notice_draft_hindi
    assert "23 अगस्त 2024" in result.court_application_draft_hindi

def test_multiple_cases_pending_disqualification_bar():
    """Verifies that Section 479(2) explicitly bars relief when multiple cases are pending."""
    calc_date = date(2024, 9, 1)
    start_date = calc_date - timedelta(days=900)

    req = UndertrialReliefAuditRequest(
        case_id="UT-BARRED-MULTICASE",
        custody_start_date=start_date,
        calculation_date=calc_date,
        is_first_time_offender=True,
        multiple_cases_pending=True,  # Disqualifying condition under Sec 479(2)
        charges=[
            OffenseSentenceInput(act="IPC", section="379", max_term_months=36, is_capital_or_life=False)
        ]
    )

    result = UndertrialReliefEngine.audit_undertrial_relief(req)

    assert result.is_relief_applicable is False
    assert result.is_disqualified is True
    assert "धारा 479(2)" in result.disqualification_reason

def test_capital_offense_life_imprisonment_exclusion():
    """Verifies that offenses carrying death or life imprisonment are excluded under Section 479(1)."""
    calc_date = date(2024, 9, 1)
    start_date = calc_date - timedelta(days=2000)

    req = UndertrialReliefAuditRequest(
        case_id="UT-MURDER-EXCLUSION",
        custody_start_date=start_date,
        calculation_date=calc_date,
        is_first_time_offender=True,
        multiple_cases_pending=False,
        charges=[
            OffenseSentenceInput(act="BNS", section="103(1)", max_term_months=1200, is_capital_or_life=True)
        ]
    )

    result = UndertrialReliefEngine.audit_undertrial_relief(req)

    assert result.is_relief_applicable is False
    assert result.is_disqualified is True
    assert "मृत्युदंड अथवा आजीवन कारावास" in result.disqualification_reason

def test_repeat_offender_one_half_threshold():
    """Verifies that repeat offenders require 1/2 detention (not 1/3)."""
    calc_date = date(2024, 9, 1)
    # 700 days = ~23 months. Max sentence 84 months. 1/3 = 28 mos, 1/2 = 42 mos.
    start_date = calc_date - timedelta(days=700)

    req = UndertrialReliefAuditRequest(
        case_id="UT-REPEAT-OFFENDER",
        custody_start_date=start_date,
        calculation_date=calc_date,
        is_first_time_offender=False,  # Repeat offender -> 1/2 rule
        multiple_cases_pending=False,
        charges=[
            OffenseSentenceInput(act="IPC", section="325", max_term_months=84, is_capital_or_life=False)
        ]
    )

    result = UndertrialReliefEngine.audit_undertrial_relief(req)

    assert result.statutory_threshold_fraction == "1/2"
    assert result.threshold_months == 42.0
    assert result.actual_detention_served_months < 42.0
    assert result.is_relief_applicable is False

@pytest.mark.asyncio
async def test_audit_undertrial_relief_api():
    """Verifies that POST /api/v1/remand/audit-undertrial-relief works over HTTP."""
    import httpx
    from app.main import app
    from app.core.security import verify_advocate_token

    app.dependency_overrides[verify_advocate_token] = lambda: {"uid": "adv_ut_test"}
    try:
        calc_date = date(2024, 9, 1)
        start_date = calc_date - timedelta(days=900)
        payload = {
            "case_id": "API-UT-CASE",
            "accused_name": "रामबहादुर",
            "jail_name": "जिला जेल कानपुर",
            "custody_start_date": start_date.isoformat(),
            "calculation_date": calc_date.isoformat(),
            "is_first_time_offender": True,
            "multiple_cases_pending": False,
            "charges": [
                {"act": "BNS", "section": "318(4)", "max_term_months": 84, "is_capital_or_life": False}
            ],
            "fir_number": "मु.अ.सं. 78/2022",
            "police_station": "कोतवाली",
            "district": "कानपुर नगर"
        }

        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/v1/remand/audit-undertrial-relief",
                json=payload,
                headers={"Authorization": "Bearer mock_token"}
            )
            assert resp.status_code == 200, resp.text
            data = resp.json()
            assert data["is_relief_applicable"] is True
            assert data["statutory_threshold_fraction"] == "1/3"
            assert data["threshold_months"] == 28.0
            assert "court_application_draft_hindi" in data
            assert "jail_superintendent_notice_draft_hindi" in data
    finally:
        app.dependency_overrides.clear()
