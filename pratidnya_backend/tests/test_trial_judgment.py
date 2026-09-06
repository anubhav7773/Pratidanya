import pytest
from starlette.testclient import TestClient
from pathlib import Path
from app.main import app
from app.core.security import verify_advocate_token
from app.services.high_court_judgment_parser import HighCourtJudgmentParser

TEST_ADVOCATE_ID = "00000000-0000-0000-0000-000000000001"

async def mock_verify_advocate_token():
    return {
        "uid": TEST_ADVOCATE_ID,
        "advocate_id": TEST_ADVOCATE_ID,
        "email": "advocate_trial_test@pratidnya.com",
        "role": "advocate"
    }

@pytest.fixture
def client():
    app.dependency_overrides[verify_advocate_token] = mock_verify_advocate_token
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()

def test_operative_order_regex_unit():
    sample_judgment = (
        "अतः पत्रावली पर उपलब्ध साक्ष्यों के आधार पर अभियुक्त राजू को धारा 307 भा.दं.वि. "
        "के अंतर्गत दोषसिद्ध किया जाता है।\n"
        "दंडादेश: अभियुक्त को 7 वर्ष के कठोर कारावास एवं ₹5,000 अर्थदंड से दंडित किया जाता है। "
        "अर्थदंड न अदा करने पर 3 माह का अतिरिक्त साधारण कारावास भुगतना होगा।"
    )
    operative = HighCourtJudgmentParser._extract_operative_order(sample_judgment)
    assert "7 वर्ष के कठोर कारावास" in operative
    assert "₹5,000 अर्थदंड" in operative

def test_parse_trial_judgment_invalid_file_type(client):
    response = client.post(
        "/api/v1/high-court/parse-trial-judgment",
        data={"pleading_type": "CRIMINAL_APPEAL"},
        files={"file": ("test.txt", b"plain text data", "text/plain")}
    )
    assert response.status_code == 400
    assert "केवल PDF प्रारूप मान्य है" in response.json()["detail"]
