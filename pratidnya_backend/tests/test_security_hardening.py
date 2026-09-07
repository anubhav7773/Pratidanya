import pytest
import jwt
import httpx
from app.main import app
from app.core.config import settings
from app.core.security import verify_advocate_token

@pytest.fixture(autouse=True)
def clean_security_overrides():
    old = app.dependency_overrides.pop(verify_advocate_token, None)
    yield
    if old:
        app.dependency_overrides[verify_advocate_token] = old

def get_async_client():
    if hasattr(httpx, "ASGITransport"):
        return httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test")
    return httpx.AsyncClient(app=app, base_url="http://test")

@pytest.mark.asyncio
async def test_unsigned_jwt_bypass_rejected():
    """SEC-01: Ensures tokens with verify_signature=False are completely rejected (401)."""
    # Forge an unsigned token with a fake advocate sub
    fake_token = jwt.encode(
        {"sub": "attacker_fake_uid", "iss": "https://securetoken.google.com/fake"},
        key="",
        algorithm="none"
    )

    async with get_async_client() as client:
        res = await client.get(
            "/api/v1/billing/status",
            headers={"Authorization": f"Bearer {fake_token}"}
        )
        assert res.status_code == 401, "Security Breach: Unsigned JWT was accepted!"
        assert "प्रमाणीकरण विफल" in res.json()["detail"]

@pytest.mark.asyncio
async def test_ecourts_webhook_secret_enforcement():
    """CIS-01: Ensures webhook rejects requests without valid HMAC secret."""
    payload = {
        "cpi_cnr": "UPHC010012342026",
        "court_code": "01",
        "case_number": "BAIL/124/2026",
        "stage_of_case": "HEARING"
    }

    async with get_async_client() as client:
        # Case 1: Missing Header -> 401
        res_missing = await client.post("/api/v1/ecourts/webhook", json=payload)
        assert res_missing.status_code == 401

        # Case 2: Invalid Secret -> 401
        res_invalid = await client.post(
            "/api/v1/ecourts/webhook",
            json=payload,
            headers={"X-Webhook-Secret": "wrong_attacker_secret"}
        )
        assert res_invalid.status_code == 401

        # Case 3: Valid Secret -> 200
        res_valid = await client.post(
            "/api/v1/ecourts/webhook",
            json=payload,
            headers={"X-Webhook-Secret": settings.ECOURTS_WEBHOOK_SECRET}
        )
        assert res_valid.status_code == 200
        assert res_valid.json()["status"] == "PROCESSED"

@pytest.mark.asyncio
async def test_cors_headers_disallow_arbitrary_origins():
    """COR-01: Verifies CORS does not reflect wildcard with credentials."""
    async with get_async_client() as client:
        res = await client.options(
            "/api/v1/billing/status",
            headers={
                "Origin": "https://evil-untrusted-site.com",
                "Access-Control-Request-Method": "GET"
            }
        )
        # Untrusted origin should not receive Access-Control-Allow-Origin for that domain
        allow_origin = res.headers.get("access-control-allow-origin")
        assert allow_origin != "https://evil-untrusted-site.com"
        assert allow_origin != "*"
