import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from starlette.testclient import TestClient
from fastapi import HTTPException
from app.main import app
from app.core.security import verify_advocate_token

def mock_verify_advocate_token():
    return {
        "uid": "advocate_test_uid",
        "email": "advocate@test.in",
        "auth_time": 1700000000
    }

app.dependency_overrides[verify_advocate_token] = mock_verify_advocate_token

def test_nlp_process_chargesheet_privacy_guard():
    """Privacy Gate: free tier blocks real chargesheet data."""
    with patch("app.api.v1.endpoints.nlp.settings") as mock_settings:
        mock_settings.GEMINI_PAID_TIER = False
        client = TestClient(app)
        response = client.post(
            "/api/v1/nlp/process-chargesheet",
            json={
                "case_id": "case-uuid-1",
                "chargesheet_text": "यह एक वास्तविक पुलिस आरोप पत्र का पाठ है जिसकी लंबाई पचास अक्षरों से अधिक होनी आवश्यक है।",
                "is_dummy_testing": False
            }
        )
        assert response.status_code == 403
        assert "गोपनीयता सुरक्षा निषेध" in response.json()["detail"]

def test_nlp_process_chargesheet_fact_extraction():
    """Extracts discrete facts and detected sections from chargesheet text."""
    client = TestClient(app)
    sample_text = (
        "अभियुक्त राहुल को पुलिस उपनिरीक्षक द्वारा दिनांक 12.01.2026 को चोरी की मोटरसाइकिल सहित गिरफ्तार किया गया। "
        "मौके पर कोई स्वतंत्र गवाह उपस्थित नहीं था। जब्ती मेमो तैयार कर धारा 379, 411 भा.दं.सं. के अंतर्गत चालान प्रस्तुत किया गया।"
    )
    response = client.post(
        "/api/v1/nlp/process-chargesheet",
        json={
            "case_id": "case-uuid-1",
            "chargesheet_text": sample_text,
            "is_dummy_testing": True
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["case_id"] == "case-uuid-1"
    assert isinstance(data["facts_extracts"], list)
    assert len(data["facts_extracts"]) > 0
    assert data["total_sentences_processed"] >= 1

@pytest.mark.asyncio
async def test_generate_draft_quota_exhaustion_throws_402():
    """Atomic quota check: When quota is 0, throws HTTP 402."""
    with patch("app.api.v1.endpoints.drafts.GeminiService") as MockGeminiService:
        instance = MockGeminiService.return_value
        instance.generate_structured_case_analysis = AsyncMock(
            side_effect=HTTPException(
                status_code=402,
                detail="दैनिक ड्राफ्टिंग कोटा समाप्त। अतिरिक्त ड्राफ्ट के लिए विज्ञापन देखें या प्रो चैंबर में अपग्रेड करें।"
            )
        )
        client = TestClient(app)
        response = client.post(
            "/api/v1/drafts/generate-360",
            json={
                "case_id": "case-uuid-1",
                "fir_number": "123/2026",
                "sections": ["379", "411"],
                "police_station": "हजरतगंज",
                "district": "लखनऊ",
                "factual_summary": "बरामदगी के समय कोई स्वतंत्र गवाह नहीं था।",
                "custody_status": "JUDICIAL_CUSTODY",
                "is_dummy_testing": True
            }
        )
        assert response.status_code == 402
        assert "दैनिक ड्राफ्टिंग कोटा समाप्त" in response.json()["detail"]

@pytest.mark.asyncio
async def test_generate_draft_grounding_enforcement():
    """Grounding Validator filters out hallucinated or unverified citations."""
    mock_raw_draft = {
        "court_header": "न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ",
        "case_title": "राज्य बनाम अभियुक्त",
        "statutory_grounds": ["अभियुक्त निर्दोष है और उसे रंजिशन फंसाया गया है।"],
        "prosecution_weaknesses": ["बरामदगी के समय कोई निष्पक्ष स्वतंत्र साक्षी उपस्थित नहीं था।"],
        "procedural_objections": ["सीआरपीसी की धारा 100(4) का उल्लंघन किया गया है।"]
    }

    mock_rpc_data = [
        {
            "id": "c1",
            "citation_id": "AIR 1980 SC 785",
            "case_title": "बाबू सिंह बनाम उत्तर प्रदेश राज्य",
            "court_name": "सर्वोच्च न्यायालय",
            "judgment_date": "1978-01-31",
            "verbatim_text": "जमानत एक नियम है और जेल अपवाद। अभियुक्त को बिना ठोस आधार के कारागार में नहीं रखा जा सकता।",
            "verified_source_url": "https://judgments.ecourts.gov.in/pdf/1980_SC_785.pdf"
        },
        {
            "id": "c2",
            "citation_id": "HALLUCINATED_999",
            "case_title": "काल्पनिक केस लॉ",
            "court_name": "अज्ञात न्यायालय",
            "judgment_date": "2026",
            "verbatim_text": "काल्पनिक उद्धरण",
            "verified_source_url": ""  # Missing verified URL
        }
    ]

    with patch("app.api.v1.endpoints.drafts.GeminiService") as MockGeminiService, \
         patch("app.api.v1.endpoints.drafts.get_supabase_admin_client") as mock_get_supabase:

        gemini_inst = MockGeminiService.return_value
        gemini_inst.generate_structured_case_analysis = AsyncMock(return_value=mock_raw_draft)
        gemini_inst.generate_dense_embedding = AsyncMock(return_value=[0.1] * 768)

        mock_supabase = MagicMock()
        mock_rpc = MagicMock()
        mock_rpc.execute.return_value = MagicMock(data=mock_rpc_data)
        mock_supabase.rpc.return_value = mock_rpc
        mock_get_supabase.return_value = mock_supabase

        client = TestClient(app)
        response = client.post(
            "/api/v1/drafts/generate-360",
            json={
                "case_id": "case-uuid-1",
                "fir_number": "123/2026",
                "sections": ["379", "411"],
                "police_station": "हजरतगंज",
                "district": "लखनऊ",
                "factual_summary": "बरामदगी के समय कोई स्वतंत्र गवाह नहीं था।",
                "custody_status": "JUDICIAL_CUSTODY",
                "is_dummy_testing": True
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["court_header"] == "न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ"
        assert len(data["statutory_grounds"]) == 1
        assert len(data["prosecution_weaknesses"]) == 1
        assert len(data["procedural_objections"]) == 1

        # Check citations: unverified URL (HALLUCINATED_999) must be stripped!
        citations = data["cited_precedents"]
        assert len(citations) == 1
        assert citations[0]["citation_id"] == "AIR 1980 SC 785"
        assert citations[0]["verified_source_url"].startswith("https://")
        assert citations[0]["is_grounded_in_record"] is True


@patch("app.api.v1.endpoints.drafts.get_supabase_admin_client")
@patch("app.api.v1.endpoints.drafts.GeminiService")
def test_generate_draft_endpoint_resilient_to_string_weaknesses_and_objections(mock_gemini_cls, mock_get_supabase):
    """Verifies that if LLM returns strings instead of lists for weaknesses/objections,
    the endpoint coerces them to List[str] and succeeds with HTTP 200 without ValidationError."""
    gemini_inst = mock_gemini_cls.return_value
    gemini_inst.generate_structured_case_analysis = AsyncMock(return_value={
        "court_header": "न्यायालय अपर सत्र न्यायाधीश, लखनऊ",
        "case_title": "राज्य बनाम रमेश कुमार",
        "statutory_grounds": "1. अभियुक्त निर्दोष है। 2. झूठा फंसाया गया है।",
        "prosecution_weaknesses": "प्रोसेक्यूशन द्वारा कोई स्वतंत्र साक्षी प्रस्तुत नहीं किया गया है।",
        "procedural_objections": "एफ.आई.आर. दर्ज करने में 48 घंटे का अकारण विलंब हुआ है।"
    })
    gemini_inst.generate_dense_embedding = AsyncMock(return_value=[0.1] * 768)

    mock_supabase = MagicMock()
    mock_rpc = MagicMock()
    mock_rpc.execute.return_value = MagicMock(data=[])
    mock_supabase.rpc.return_value = mock_rpc
    mock_get_supabase.return_value = mock_supabase

    client = TestClient(app)
    response = client.post(
        "/api/v1/drafts/generate-360",
        json={
            "case_id": "case-uuid-99",
            "fir_number": "124/2026",
            "sections": ["302"],
            "police_station": "कोतवाली नगर",
            "district": "लखनऊ",
            "factual_summary": "अभियुक्त पर धारा 302 का आरोप है।",
            "custody_status": "JUDICIAL_CUSTODY",
            "is_dummy_testing": True
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert isinstance(data["statutory_grounds"], list)
    assert len(data["statutory_grounds"]) >= 2
    assert isinstance(data["prosecution_weaknesses"], list)
    assert len(data["prosecution_weaknesses"]) >= 1
    assert "प्रोसेक्यूशन द्वारा कोई स्वतंत्र साक्षी प्रस्तुत नहीं किया गया है।" in data["prosecution_weaknesses"][0]
    assert isinstance(data["procedural_objections"], list)
    assert len(data["procedural_objections"]) >= 1
    assert "एफ.आई.आर. दर्ज करने में 48 घंटे का अकारण विलंब हुआ है।" in data["procedural_objections"][0]

