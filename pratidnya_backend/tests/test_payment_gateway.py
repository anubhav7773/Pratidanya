import pytest
from unittest.mock import patch, MagicMock
import httpx
from app.main import app
from app.core.config import settings
from app.core.security import verify_advocate_token

def mock_verify_advocate_token():
    return {
        "uid": "advocate_test_uid",
        "email": "advocate@test.in",
        "auth_time": 1700000000
    }

@pytest.fixture(autouse=True)
def setup_auth_override():
    app.dependency_overrides[verify_advocate_token] = mock_verify_advocate_token
    yield
    # Keep consistent with test environment

def get_async_client():
    if hasattr(httpx, "ASGITransport"):
        return httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test")
    return httpx.AsyncClient(app=app, base_url="http://test")

@pytest.mark.asyncio
async def test_new_advocate_quota_auto_initialization():
    """BIL-03: Ensures a brand new user doesn't crash with 406/500 PGRST116."""
    headers = {"Authorization": "Bearer TEST_MOCK_TOKEN_NEW_USER"}

    with patch("app.api.v1.endpoints.billing.get_supabase_admin_client") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()
        mock_maybe = MagicMock()

        # maybe_single returns None for a new advocate with no quota row
        mock_maybe.execute.return_value = MagicMock(data=None)
        mock_eq.maybe_single.return_value = mock_maybe
        mock_select.eq.return_value = mock_eq
        mock_table.select.return_value = mock_select
        mock_table.upsert.return_value = MagicMock(execute=MagicMock())
        mock_table.order.return_value.limit.return_value.execute.return_value = MagicMock(data=[])
        mock_supabase.table.return_value = mock_table
        mock_get_supabase.return_value = mock_supabase

        async with get_async_client() as client:
            res = await client.get("/api/v1/billing/status", headers=headers)
            # Should not crash with 500 PGRST116
            assert res.status_code == 200
            data = res.json()
            assert data["quota"]["subscription_tier"] == "FREE"
            assert data["quota"]["daily_drafts_remaining"] == 3

@pytest.mark.asyncio
async def test_sandbox_dummy_order_and_activation():
    """Verifies SANDBOX_DUMMY mode creates structured order and activates cleanly."""
    settings.PAYMENT_MODE = "SANDBOX_DUMMY"

    with patch("app.api.v1.endpoints.billing.get_supabase_admin_client") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_supabase.table.return_value.upsert.return_value.execute.return_value = MagicMock()
        mock_get_supabase.return_value = mock_supabase

        async with get_async_client() as client:
            headers = {"Authorization": "Bearer TEST_MOCK_TOKEN_ADVOCATE_1"}

            # 1. Create order
            order_res = await client.post(
                "/api/v1/billing/create-order",
                json={"plan_id": "pratidnya_chamber_pro_monthly", "amount_inr": 499},
                headers=headers
            )
            assert order_res.status_code == 200
            order_data = order_res.json()
            assert order_data["is_sandbox"] is True
            assert order_data["order_id"].startswith("order_sandbox_")

            # 2. Verify payment with valid sandbox signature
            verify_res = await client.post(
                "/api/v1/billing/verify-payment",
                json={
                    "order_id": order_data["order_id"],
                    "payment_id": "pay_test_12345",
                    "signature": "sig_sandbox_valid_hash"
                },
                headers=headers
            )
            assert verify_res.status_code == 200
            verify_data = verify_res.json()
            assert verify_data["status"] == "SUCCESS"
            assert verify_data["tier"] == "PRO_CHAMBER"

@pytest.mark.asyncio
async def test_production_mode_rejects_mock_signatures():
    """BIL-01: Ensures PRODUCTION mode strictly rejects sandbox signatures."""
    settings.PAYMENT_MODE = "PRODUCTION"
    settings.RAZORPAY_KEY_ID = "rzp_test_mock_id"
    settings.RAZORPAY_KEY_SECRET = "test_secret_for_hash_123"

    try:
        async with get_async_client() as client:
            headers = {"Authorization": "Bearer TEST_MOCK_TOKEN_ADVOCATE_1"}

            verify_res = await client.post(
                "/api/v1/billing/verify-payment",
                json={
                    "order_id": "order_real_987",
                    "payment_id": "pay_real_456",
                    "signature": "test_signature_valid" # Attempting old mock bypass
                },
                headers=headers
            )
            # Must be rejected with 400 Bad Request
            assert verify_res.status_code == 400
            assert "अमान्य डिजिटल हस्ताक्षर" in verify_res.json()["detail"]
    finally:
        # Reset to SANDBOX_DUMMY for ongoing local development
        settings.PAYMENT_MODE = "SANDBOX_DUMMY"
