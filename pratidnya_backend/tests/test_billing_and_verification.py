import pytest
from unittest.mock import patch, MagicMock, AsyncMock
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

def test_anti_replay_token_protection():
    """Anti-replay protection: Replaying purchase token from another account raises 403."""
    with patch("app.services.subscription_verifier.get_supabase_admin_client") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()
        mock_single = MagicMock()

        # Token exists and belongs to a different advocate!
        mock_single.execute.return_value = MagicMock(
            data={"advocate_id": "other_hacker_uid", "subscription_status": "ACTIVE"}
        )
        mock_eq.maybe_single.return_value = mock_single
        mock_select.eq.return_value = mock_eq
        mock_table.select.return_value = mock_select
        mock_supabase.table.return_value = mock_table
        mock_get_supabase.return_value = mock_supabase

        client = TestClient(app)
        response = client.post(
            "/api/v1/billing/verify-subscription",
            json={
                "product_id": "pratidnya_chamber_pro_monthly",
                "purchase_token": "replayed_token_123"
            }
        )
        assert response.status_code == 403
        assert "सुरक्षा उल्लंघन" in response.json()["detail"]

def test_rewarded_ad_daily_limit_exceeded_returns_429():
    """Claiming > 3 rewarded ads per day triggers HTTP 429."""
    with patch("app.api.v1.endpoints.billing.get_supabase_admin_client") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()
        mock_single = MagicMock()

        # Already claimed 3 rewarded ads today
        mock_single.execute.return_value = MagicMock(
            data={
                "ad_rewarded_drafts": 3,
                "daily_drafts_remaining": 0,
                "subscription_tier": "FREE"
            }
        )
        mock_eq.single.return_value = mock_single
        mock_select.eq.return_value = mock_eq
        mock_table.select.return_value = mock_select
        mock_supabase.table.return_value = mock_table
        mock_get_supabase.return_value = mock_supabase

        client = TestClient(app)
        response = client.post("/api/v1/billing/claim-ad-reward")
        assert response.status_code == 429
        assert "दैनिक विज्ञापन सीमा समाप्त" in response.json()["detail"]

def test_rewarded_ad_claim_success_under_limit():
    """Claiming rewarded ad under limit succeeds and increments count."""
    with patch("app.api.v1.endpoints.billing.get_supabase_admin_client") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_table = MagicMock()
        
        # Mock select
        mock_select = MagicMock()
        mock_eq_select = MagicMock()
        mock_single = MagicMock()
        mock_single.execute.return_value = MagicMock(
            data={
                "ad_rewarded_drafts": 1,
                "daily_drafts_remaining": 0,
                "subscription_tier": "FREE"
            }
        )
        mock_eq_select.single.return_value = mock_single
        mock_select.eq.return_value = mock_eq_select
        
        # Mock update
        mock_update = MagicMock()
        mock_eq_update = MagicMock()
        mock_eq_update.execute.return_value = MagicMock(data=[])
        mock_update.eq.return_value = mock_eq_update
        
        mock_table.select.return_value = mock_select
        mock_table.update.return_value = mock_update
        mock_supabase.table.return_value = mock_table
        mock_get_supabase.return_value = mock_supabase

        client = TestClient(app)
        response = client.post("/api/v1/billing/claim-ad-reward")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "SUCCESS"
        assert data["ad_rewarded_drafts_available"] == 2

def test_subscription_tier_elevation_to_pro_chamber():
    """Successful subscription verification activates PRO_CHAMBER tier."""
    with patch("app.services.subscription_verifier.get_supabase_admin_client") as mock_get_supabase, \
         patch("app.services.subscription_verifier.GooglePlaySubscriptionVerifier._get_publisher_service") as mock_service_call:

        # Mock Supabase
        mock_supabase = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()
        mock_single = MagicMock()
        mock_single.execute.return_value = MagicMock(data=None) # No existing token replay
        mock_eq.maybe_single.return_value = mock_single
        mock_select.eq.return_value = mock_eq
        mock_table.select.return_value = mock_select

        # Mock upsert & update
        mock_table.upsert.return_value = MagicMock(execute=MagicMock())
        mock_table.update.return_value = MagicMock(eq=MagicMock(return_value=MagicMock(execute=MagicMock())))
        mock_supabase.table.return_value = mock_table
        mock_get_supabase.return_value = mock_supabase

        # Mock Google Play Android Publisher response
        mock_service = MagicMock()
        mock_purchases = MagicMock()
        mock_subs = MagicMock()
        mock_get = MagicMock()
        mock_get.execute.return_value = {
            "subscriptionState": "SUBSCRIPTION_STATE_ACTIVE",
            "lineItems": [
                {
                    "productId": "pratidnya_chamber_pro_monthly",
                    "expiryTime": "2026-10-05T00:00:00Z",
                    "autoRenewingPlan": {"autoRenewEnabled": True}
                }
            ],
            "latestOrderId": "GPA.1234-5678",
            "startTime": "2026-09-05T00:00:00Z",
            "regionCode": "IN"
        }
        mock_subs.get.return_value = mock_get
        mock_purchases.subscriptionsv2.return_value = mock_subs
        mock_service.purchases.return_value = mock_purchases
        mock_service_call.return_value = mock_service

        client = TestClient(app)
        response = client.post(
            "/api/v1/billing/verify-subscription",
            json={
                "product_id": "pratidnya_chamber_pro_monthly",
                "purchase_token": "valid_token_xyz"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "SUCCESS"
        assert data["subscription_status"] == "ACTIVE"
        assert data["tier"] == "PRO_CHAMBER"
