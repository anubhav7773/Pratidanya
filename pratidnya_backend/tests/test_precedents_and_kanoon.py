import pytest
from unittest.mock import patch, MagicMock
from starlette.testclient import TestClient
from app.main import app
from app.core.security import verify_advocate_token

def mock_verify_advocate_token():
    return {
        "uid": "advocate_test_uid",
        "email": "advocate@test.in",
        "auth_time": 1700000000
    }

app.dependency_overrides[verify_advocate_token] = mock_verify_advocate_token

def test_kanoon_list_courts():
    client = TestClient(app)
    response = client.get("/api/v1/kanoon/courts")
    assert response.status_code == 200
    data = response.json()
    assert len(data) > 0
    assert data[0]["court_level"] == "HIGH_COURT"

def test_kanoon_search_cases():
    client = TestClient(app)
    response = client.get("/api/v1/kanoon/search-cases", params={"court_id": "APHC01", "query": "379"})
    assert response.status_code == 200
    data = response.json()
    assert len(data) > 0
    assert "cnr_number" in data[0]

def test_precedents_search_blocks_real_data_on_free_tier():
    with patch("app.api.v1.endpoints.precedents.settings") as mock_settings:
        mock_settings.GEMINI_PAID_TIER = False
        client = TestClient(app)
        response = client.post(
            "/api/v1/precedents/search",
            json={
                "query_text": "बिना स्वतंत्र गवाह जब्ती अमान्य",
                "target_sections": ["379", "411"],
                "similarity_threshold": 0.65,
                "is_dummy_testing": False
            }
        )
        assert response.status_code == 403
        assert "गोपनीयता सुरक्षा निषेध" in response.json()["detail"]

def test_precedents_search_filters_unverified_urls():
    client = TestClient(app)

    mock_db_results = [
        {
            "id": "1",
            "citation_id": "AIR 1980 SC 785",
            "case_title": "Babu Singh v. State of U.P.",
            "court_name": "Supreme Court of India",
            "judgment_date": "1978-01-31",
            "act_name": "Code of Criminal Procedure 1973",
            "section_numbers": ["437", "439"],
            "headnote_hindi": "जमानत एक नियम है और जेल अपवाद।",
            "verbatim_text": "Bail is the rule and committal to jail an exception.",
            "paragraph_number": 12,
            "verified_source_url": "https://judgments.ecourts.gov.in/dummy_785.pdf",
            "similarity": 0.88
        },
        {
            "id": "2",
            "citation_id": "AIR 2020 SC 999",
            "case_title": "Unverified Precedent",
            "court_name": "High Court",
            "judgment_date": "2020-01-01",
            "act_name": "IPC",
            "section_numbers": ["411"],
            "headnote_hindi": "अपुष्ट मिसाल",
            "verbatim_text": "Unverified text",
            "paragraph_number": 1,
            "verified_source_url": "", # Missing URL
            "similarity": 0.75
        }
    ]

    with patch("app.api.v1.endpoints.precedents.GeminiService.generate_dense_embedding") as mock_embed, \
         patch("app.api.v1.endpoints.precedents.get_supabase_admin_client") as mock_db:

        mock_embed.return_value = [0.1] * 768
        mock_rpc = MagicMock()
        mock_rpc.execute.return_value = MagicMock(data=mock_db_results)
        mock_client = MagicMock()
        mock_client.rpc.return_value = mock_rpc
        mock_db.return_value = mock_client

        response = client.post(
            "/api/v1/precedents/search",
            json={
                "query_text": "जमानत का सामान्य नियम",
                "target_sections": ["437"],
                "similarity_threshold": 0.65,
                "is_dummy_testing": True
            }
        )

        assert response.status_code == 200
        results = response.json()
        assert len(results) == 1
        assert results[0]["citation_id"] == "AIR 1980 SC 785"
        assert results[0]["similarity_score"] == 0.88
        assert results[0]["verified_source_url"].startswith("https://")


def test_precedents_search_adaptive_relaxation_on_typo():
    client = TestClient(app)

    relaxed_mock_results = [
        {
            "id": "2",
            "citation_id": "1984_4_SCC_116_SHARAD_BIRDHICHAND",
            "case_title": "शरद बिरधीचंद सारडा बनाम महाराष्ट्र राज्य",
            "court_name": "सर्वोच्च न्यायालय",
            "judgment_date": "1984-07-17",
            "act_name": "IPC",
            "section_numbers": ["302", "103_BNS"],
            "headnote_hindi": "परिस्थितिजन्य साक्ष्य के आधार पर दोषसिद्धि के 5 स्वर्णिम सिद्धांत।",
            "verbatim_text": "सन्देह चाहे कितना भी गम्भीर क्यों न हो, वह साक्ष्य का स्थान नहीं ले सकता।",
            "paragraph_number": 153,
            "verified_source_url": "https://judgments.ecourts.gov.in/pdfcache/1984_4_scc_116.pdf",
            "similarity": 0.6155
        }
    ]

    with patch("app.api.v1.endpoints.precedents.GeminiService.generate_dense_embedding") as mock_embed, \
         patch("app.api.v1.endpoints.precedents.get_supabase_admin_client") as mock_db:

        mock_embed.return_value = [0.1] * 768
        mock_rpc = MagicMock()
        # First call (at 0.65) returns empty, second call (at 0.50) returns match
        mock_rpc.execute.side_effect = [MagicMock(data=[]), MagicMock(data=relaxed_mock_results)]
        mock_client = MagicMock()
        mock_client.rpc.return_value = mock_rpc
        mock_db.return_value = mock_client

        response = client.post(
            "/api/v1/precedents/search",
            json={
                "query_text": "muder case",
                "similarity_threshold": 0.65,
                "is_dummy_testing": True
            }
        )

        assert response.status_code == 200
        results = response.json()
        assert len(results) == 1
        assert "शरद बिरधीचंद सारडा" in results[0]["case_title"]
        assert results[0]["similarity_score"] == 0.6155

