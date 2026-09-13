import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import verify_advocate_token
from app.schemas.courtroom_tactics_schema import (
    SuretyAuditRequest,
    EdgeOralPromptRequest
)
from app.services.courtroom_tactics_engine import CourtroomTacticsEngine

client = TestClient(app)

def test_moti_ram_local_surety_and_khatauni_violation():
    """Verifies that demanding local sureties and revenue records triggers Moti Ram violation."""
    req = SuretyAuditRequest(
        case_id="BAIL-SURETY-CASE-01",
        imposed_bond_amount_inr=50000.0,
        is_local_surety_demanded=True,              # Violates Moti Ram local surety ban
        is_revenue_record_khatauni_demanded=True,   # Violates onerous property condition
        out_of_district_surety_rejected=True,
        accused_financial_indigence=True,
        accused_name="राम प्रकाश",
        police_station="कोतवाली नगर",
        district="लखनऊ"
    )

    result = CourtroomTacticsEngine.audit_surety_conditions(req)

    assert result.is_condition_onerous is True
    assert len(result.moti_ram_violation_reasons) >= 2
    assert any("स्थानीय प्रतिभू" in r for r in result.moti_ram_violation_reasons)
    assert any("खतौनी" in r for r in result.moti_ram_violation_reasons)
    assert "मोती राम बनाम मध्य प्रदेश राज्य" in result.modification_petition_draft_hindi
    assert "धारा 483(2)" in result.modification_petition_draft_hindi

def test_edge_oral_prompt_commercial_ndps_counter():
    """Verifies that adversary argument on Section 37 commercial NDPS triggers Section 52A Mohanlal rejoinder."""
    req = EdgeOralPromptRequest(
        case_id="NDPS-COMMERCIAL-ARG",
        adversary_argument_raw_text="श्रीमान, अभियुक्त से कमर्शियल मात्रा (Commercial Quantity) बरामद हुई है, इसलिए धारा 37 एनडीपीएस के तहत बेल खारिज की जाए।"
    )

    result = CourtroomTacticsEngine.generate_edge_oral_prompt(req)

    assert "धारा 37" in result.detected_adversarial_ratio
    assert len(result.immediate_counter_ratios) >= 1
    top_counter = result.immediate_counter_ratios[0]
    assert "धारा 52A" in top_counter.counter_legal_ground
    assert "मोहनलाल" in top_counter.prompt_text_hindi
    assert result.latency_ms["total_latency_ms"] < 500.0

def test_edge_oral_prompt_gangster_collapse_counter():
    """Verifies that gangster act adversary argument triggers Farhana collapse rejoinder."""
    req = EdgeOralPromptRequest(
        case_id="GANGSTER-ARG",
        adversary_argument_raw_text="अभियुक्त पर गंभीर गैंगस्टर एक्ट (UP Gangsters Act) लगा है।"
    )

    result = CourtroomTacticsEngine.generate_edge_oral_prompt(req)

    assert "गैंगस्टर" in result.detected_adversarial_ratio
    assert any("फरहाना" in c.prompt_text_hindi for c in result.immediate_counter_ratios)

def test_courtroom_api_endpoints():
    """Verifies courtroom edge oral prompter and judicial analytics endpoints."""
    # Test oral prompter endpoint
    app.dependency_overrides[verify_advocate_token] = lambda: {"uid": "adv_test_999", "role": "advocate"}
    
    prompt_res = client.post(
        "/api/v1/courtroom/edge-oral-prompt",
        json={
            "case_id": "TEST-PROMPT-01",
            "adversary_argument_raw_text": "अभियुक्त से कमर्शियल मात्रा बरामद हुई है",
            "active_judge_id": "JUDGE-UP-LKO-04",
            "active_offense_category": "NDPS"
        }
    )
    assert prompt_res.status_code == 200
    prompt_data = prompt_res.json()
    assert "detected_adversarial_ratio" in prompt_data
    assert len(prompt_data["immediate_counter_ratios"]) > 0

    # Test judge analytics endpoint
    judge_res = client.get("/api/v1/courtroom/judge-analytics/JUDGE-UP-LKO-04")
    assert judge_res.status_code == 200
    judge_data = judge_res.json()
    assert judge_data["judge_identifier"] == "JUDGE-UP-LKO-04"
    assert "disposal_metrics" in judge_data

    app.dependency_overrides.clear()
