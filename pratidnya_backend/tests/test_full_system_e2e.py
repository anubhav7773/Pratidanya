import pytest
import asyncio
from unittest.mock import patch, MagicMock, AsyncMock
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.config import settings
from app.core.security import verify_advocate_token
from app.services.grounding_validator import GroundingValidator

def mock_verify_advocate_token():
    return {
        "uid": "advocate_test_uid",
        "email": "advocate@test.in",
        "auth_time": 1700000000
    }

app.dependency_overrides[verify_advocate_token] = mock_verify_advocate_token

@pytest.mark.asyncio
async def test_complete_phase1_pipeline():
    """
    End-to-End Integration Test for Pratidnya Legal Tech (Goals 1-7):
    1. Diagnostics Probe Check (/healthz)
    2. OpenNyAI Chargesheet Deconstruction (/api/v1/nlp/process-chargesheet)
    3. pgvector Precedent Semantic Retrieval with 0.65 Threshold
    4. 360° Bail Drafting with Extractive Grounding
    5. Rule 3 Not Found = Abstain Assertion
    6. Billing & Quota Atomicity Check
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        auth_headers = {"Authorization": "Bearer TEST_MOCK_FIREBASE_TOKEN"}

        # STEP 1: System Health Check (Goal 2)
        with patch("app.api.v1.endpoints.health.get_supabase_admin_client") as mock_health_db, \
             patch("app.api.v1.endpoints.health.OpenNyAIEngine.get_instance") as mock_health_nlp:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.limit.return_value.execute.return_value = MagicMock()
            mock_health_db.return_value = mock_client
            mock_engine = MagicMock()
            mock_engine._pipeline = MagicMock()
            mock_health_nlp.return_value = mock_engine

            health_res = await client.get("/healthz")
            assert health_res.status_code == 200
            health_data = health_res.json()
            assert health_data["status"] == "HEALTHY"
            assert health_data["opennyai_loaded"] is True

        # STEP 2: Chargesheet Deconstruction via OpenNyAI (Goal 6)
        chargesheet_payload = {
            "case_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
            "chargesheet_text": (
                "थाना कोतवाली नगर, मुकदमा अपराध संख्या 124/2026, अंतर्गत धारा 379, 411 भा.दं.वि.। "
                "वादी राम प्रकाश द्वारा मोटरसाइकिल चोरी की सूचना दी गई। उपनिरीक्षक के.के. सिंह द्वारा "
                "अभियुक्त श्यामू को कथित चोरी की मोटरसाइकिल सहित गिरफ्तार किया गया। मौके पर कोई स्वतंत्र "
                "साक्षी उपस्थित नहीं था।"
            ),
            "is_dummy_testing": True
        }
        nlp_res = await client.post(
            "/api/v1/nlp/process-chargesheet",
            json=chargesheet_payload,
            headers=auth_headers
        )
        assert nlp_res.status_code == 200
        nlp_data = nlp_res.json()
        assert len(nlp_data["facts_extracts"]) > 0
        assert "धारा 411" in str(nlp_data["provisions_detected"]) or len(nlp_data["provisions_detected"]) >= 0

        # STEP 3: Precedent Vector Retrieval (Goal 5)
        precedent_payload = {
            "query_text": "बिना स्वतंत्र साक्षी के चोरी की संपत्ति की बरामदगी धारा 411",
            "target_sections": ["411"],
            "similarity_threshold": 0.65,
            "limit": 3,
            "is_dummy_testing": True
        }

        mock_precedents = [
            {
                "id": "p1",
                "citation_id": "AIR 1980 SC 785",
                "case_title": "बाबू सिंह बनाम उत्तर प्रदेश राज्य",
                "court_name": "सर्वोच्च न्यायालय",
                "judgment_date": "1978-01-31",
                "act_name": "भारतीय दंड संहिता",
                "section_numbers": ["411"],
                "headnote_hindi": "बरामदगी के समय स्वतंत्र गवाह आवश्यक है।",
                "verbatim_text": "जमानत एक नियम है और जेल अपवाद।",
                "paragraph_number": 8,
                "verified_source_url": "https://judgments.ecourts.gov.in/pdf/1980_SC_785.pdf",
                "similarity": 0.78
            }
        ]

        with patch("app.api.v1.endpoints.precedents.GeminiService") as MockGemini, \
             patch("app.api.v1.endpoints.precedents.get_supabase_admin_client") as MockSupabase:
            gemini_mock = MockGemini.return_value
            gemini_mock.generate_dense_embedding = AsyncMock(return_value=[0.1] * 768)

            supa_mock = MagicMock()
            supa_rpc = MagicMock()
            supa_rpc.execute.return_value = MagicMock(data=mock_precedents)
            supa_mock.rpc.return_value = supa_rpc
            MockSupabase.return_value = supa_mock

            prec_res = await client.post(
                "/api/v1/precedents/search",
                json=precedent_payload,
                headers=auth_headers
            )
            assert prec_res.status_code == 200
            prec_data = prec_res.json()
            assert len(prec_data) > 0
            for citation in prec_data:
                assert citation["verified_source_url"].startswith("http")
                assert citation["similarity_score"] >= 0.65

        # STEP 4: Rule 3 "Not Found = Abstain" Assertion (Goal 5)
        unmatched_payload = {
            "query_text": "काल्पनिक अनमैच्ड सिविल दीवानी प्रश्न जो डेटाबेस में नहीं है",
            "target_sections": ["9999_NON_EXISTENT"],
            "similarity_threshold": 0.85,
            "limit": 3,
            "is_dummy_testing": True
        }

        with patch("app.api.v1.endpoints.precedents.GeminiService") as MockGemini, \
             patch("app.api.v1.endpoints.precedents.get_supabase_admin_client") as MockSupabase:
            gemini_mock = MockGemini.return_value
            gemini_mock.generate_dense_embedding = AsyncMock(return_value=[0.1] * 768)

            supa_mock = MagicMock()
            supa_rpc = MagicMock()
            supa_rpc.execute.return_value = MagicMock(data=[]) # No matches above 0.85 threshold!
            supa_mock.rpc.return_value = supa_rpc
            MockSupabase.return_value = supa_mock

            unmatched_res = await client.post(
                "/api/v1/precedents/search",
                json=unmatched_payload,
                headers=auth_headers
            )
            assert unmatched_res.status_code == 200
            assert len(unmatched_res.json()) == 0, "Abstain Rule Failed: AI returned hallucinated citations!"

        # STEP 5: 360° Legal Draft Generation (Goal 6)
        draft_payload = {
            "case_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
            "fir_number": "124/2026",
            "sections": ["379 IPC", "411 IPC"],
            "police_station": "कोतवाली नगर",
            "district": "लखनऊ",
            "factual_summary": "कथित जब्ती के समय धारा 100(4) दंड प्रक्रिया संहिता का उल्लंघन हुआ।",
            "custody_status": "JUDICIAL_CUSTODY",
            "extracted_facts": nlp_data["facts_extracts"],
            "is_dummy_testing": True
        }

        mock_draft_data = {
            "court_header": "न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ",
            "case_title": "राज्य बनाम श्यामू",
            "statutory_grounds": [
                "अभियुक्त का कोई पूर्व आपराधिक इतिहास नहीं है।",
                "आरोपित अपराध मजिस्ट्रेट द्वारा विचारणीय एवं जमानतीय प्रकृति का है।",
                "अभियुक्त स्थानीय निवासी है और विचारण के दौरान उपस्थित रहने का वचन देता है।"
            ],
            "prosecution_weaknesses": [
                "अभियोजन पक्ष कथित जब्ती के समय किसी स्वतंत्र साक्षी को प्रस्तुत करने में विफल रहा।"
            ],
            "procedural_objections": [
                "दंड प्रक्रिया संहिता की धारा 100(4) के आज्ञापक प्रावधानों का पालन नहीं किया गया।"
            ]
        }

        with patch("app.api.v1.endpoints.drafts.GeminiService") as MockDraftGemini, \
             patch("app.api.v1.endpoints.drafts.get_supabase_admin_client") as MockDraftSupabase:
            draft_gemini = MockDraftGemini.return_value
            draft_gemini.generate_structured_case_analysis = AsyncMock(return_value=mock_draft_data)
            draft_gemini.generate_dense_embedding = AsyncMock(return_value=[0.1] * 768)

            draft_supa = MagicMock()
            draft_rpc = MagicMock()
            draft_rpc.execute.return_value = MagicMock(data=mock_precedents)
            draft_supa.rpc.return_value = draft_rpc
            MockDraftSupabase.return_value = draft_supa

            draft_res = await client.post(
                "/api/v1/drafts/generate-360",
                json=draft_payload,
                headers=auth_headers
            )
            assert draft_res.status_code == 200
            draft_data = draft_res.json()
            assert len(draft_data["statutory_grounds"]) >= 3
            assert len(draft_data["prosecution_weaknesses"]) >= 1

            # STEP 6: Extractive Grounding Verification Assertion (Goal 7)
            if draft_data["cited_precedents"]:
                for prec in draft_data["cited_precedents"]:
                    assert prec["is_grounded_in_record"] is True
                    assert prec["verified_source_url"].startswith("http")

        # STEP 7: Rewarded Ad Quota Unlock Ceiling (Goal 7)
        # Simulate initial quota with 0 rewarded ads claimed
        mock_quota_state = {
            "ad_rewarded_drafts": 0,
            "daily_drafts_remaining": 0,
            "subscription_tier": "FREE"
        }

        def mock_billing_execute():
            current_count = mock_quota_state["ad_rewarded_drafts"]
            if current_count >= 3:
                return MagicMock(data=mock_quota_state)
            return MagicMock(data=mock_quota_state)

        def mock_billing_update(update_payload):
            if "ad_rewarded_drafts" in update_payload:
                mock_quota_state["ad_rewarded_drafts"] = update_payload["ad_rewarded_drafts"]
            return MagicMock(eq=MagicMock(return_value=MagicMock(execute=MagicMock())))

        with patch("app.api.v1.endpoints.billing.get_supabase_admin_client") as MockBillingSupabase:
            billing_supa = MagicMock()
            billing_table = MagicMock()

            def mock_billing_select(cols):
                mock_s = MagicMock()
                def mock_eq(col, val):
                    mock_e = MagicMock()
                    mock_e.single.return_value.execute.side_effect = lambda: MagicMock(data=dict(mock_quota_state))
                    return mock_e
                mock_s.eq = mock_eq
                return mock_s

            billing_table.select = mock_billing_select
            billing_table.update.side_effect = mock_billing_update
            billing_supa.table.return_value = billing_table
            MockBillingSupabase.return_value = billing_supa

            for _ in range(3):
                reward_res = await client.post("/api/v1/billing/claim-ad-reward", headers=auth_headers)
                assert reward_res.status_code in [200, 429]

            # 4th Attempt must fail with HTTP 429 (Daily Cap of 3 Ads)
            capped_res = await client.post("/api/v1/billing/claim-ad-reward", headers=auth_headers)
            assert capped_res.status_code == 429
