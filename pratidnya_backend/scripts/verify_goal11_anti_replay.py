import sys
from pathlib import Path
from unittest.mock import patch, MagicMock
from starlette.testclient import TestClient

BACKEND_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(BACKEND_ROOT))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from app.main import app
from app.core.security import verify_advocate_token

def test_anti_replay():
    # Advocate 2 attempting to claim a token already owned by Advocate 1
    app.dependency_overrides[verify_advocate_token] = lambda: {
        "uid": "advocate_2_uid",
        "email": "advocate2@test.in",
        "auth_time": 1700000000
    }

    with patch("app.services.subscription_verifier.get_supabase_admin_client") as mock_get_supabase:
        mock_supabase = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()
        mock_single = MagicMock()

        # Token exists and belongs to advocate_1_uid
        mock_single.execute.return_value = MagicMock(
            data={"advocate_id": "advocate_1_uid", "subscription_status": "ACTIVE"}
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
                "purchase_token": "ALREADY_CLAIMED_TOKEN"
            }
        )

        print(f"Status Code: {response.status_code}")
        print(f"Response Body: {response.json()}")

        assert response.status_code == 403
        assert "सुरक्षा उल्लंघन: यह खरीद रसीद पहले से किसी अन्य खाते में सक्रिय है।" in response.json()["detail"]
        print("Server-Side Token Anti-Replay Assertion: PASSED!")

if __name__ == "__main__":
    test_anti_replay()
