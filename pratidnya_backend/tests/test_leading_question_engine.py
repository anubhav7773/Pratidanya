import pytest
import httpx
from app.main import app
from app.core.security import verify_advocate_token
from app.schemas.leading_question_schema import LeadingQuestionRequest
from app.services.leading_question_engine import LeadingQuestionEngine

def test_planted_recovery_stock_witness_trees():
    """Verifies that planted recovery theory generates stock witness and distance questions ending in Yes/No."""
    req = LeadingQuestionRequest(
        case_id="ARMS-ACT-CASE-101",
        witness_name="राम लखन (जब्ती गवाह)",
        witness_role="PANCH_WITNESS_SEIZURE",
        defense_theory="PLANTED_RECOVERY_STOCK_WITNESS",
        case_facts={
            "recovery_place": "खुला अरहर का खेत",
            "witness_residence_distance_km": 14,
            "prior_appearances_count": 4,
            "weapon_type": "अवैध 315 बोर तमंचा"
        },
        police_station="कोतवाली नगर",
        district="लखनऊ"
    )

    result = LeadingQuestionEngine.generate_question_trees(req)

    assert result.defense_theory == "PLANTED_RECOVERY_STOCK_WITNESS"
    assert len(result.question_trees) >= 3
    
    # Step 1: Distance question
    step1 = result.question_trees[0]
    assert "14 किलोमीटर" in step1.leading_question_hindi
    assert step1.expected_answer == "YES"

    # Step 2: Stock witness question
    step2 = result.question_trees[1]
    assert "पूर्ववर्ती आपराधिक मुकदमों" in step2.leading_question_hindi
    assert "Ex. D-12" in step2.pivot_tactic_hindi

    # Step 3: Open public access conscious possession
    step3 = result.question_trees[2]
    assert "चारों तरफ से खुली जगह" in step3.leading_question_hindi
    assert "गुणवंतलाल" in step3.pivot_tactic_hindi

def test_consensual_bns_sec_69_trees():
    """Verifies Section 69 BNS / 376 IPC defense theory establishes age of majority and voluntary cohabitation."""
    req = LeadingQuestionRequest(
        case_id="BNS-69-TRIAL",
        witness_name="पीड़िता (Prosecutrix)",
        witness_role="VICTIM_PROSECUTRIX",
        defense_theory="CONSENSUAL_RELATION_SEC_69_BNS",
        case_facts={
            "prosecutrix_age": 23,
            "relationship_duration_months": 24
        }
    )

    result = LeadingQuestionEngine.generate_question_trees(req)

    assert result.defense_theory == "CONSENSUAL_RELATION_SEC_69_BNS"
    assert len(result.question_trees) >= 3

    step1 = result.question_trees[0]
    assert "23 वर्ष" in step1.leading_question_hindi
    assert step1.expected_answer == "YES"

    step2 = result.question_trees[1]
    assert "24 माह" in step2.leading_question_hindi
    assert "होटलों में स्वेच्छा" in step2.leading_question_hindi

@pytest.mark.asyncio
async def test_generate_cross_questions_api():
    """Verifies that POST /api/v1/trial/generate-cross-questions responds successfully."""
    async def mock_verify_advocate():
        return {"uid": "advocate_test_uid", "role": "advocate"}

    app.dependency_overrides[verify_advocate_token] = mock_verify_advocate

    try:
        payload = {
            "case_id": "TEST-CROSS-101",
            "witness_name": "श्याम सुंदर",
            "witness_role": "PANCH_WITNESS_SEIZURE",
            "defense_theory": "PLANTED_RECOVERY_STOCK_WITNESS",
            "case_facts": {
                "witness_residence_distance_km": 15,
                "recovery_place": "सार्वजनिक पार्क"
            },
            "accused_name": "विकास",
            "police_station": "हजरतगंज",
            "district": "लखनऊ"
        }

        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/v1/trial/generate-cross-questions",
                json=payload,
                headers={"Authorization": "Bearer mock_token"}
            )
            assert resp.status_code == 200, resp.text
            data = resp.json()
            assert data["case_id"] == "TEST-CROSS-101"
            assert len(data["question_trees"]) >= 1
            assert "15 किलोमीटर" in data["question_trees"][0]["leading_question_hindi"]
    finally:
        app.dependency_overrides.clear()
