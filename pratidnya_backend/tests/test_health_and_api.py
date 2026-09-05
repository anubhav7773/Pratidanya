import pytest
from unittest.mock import MagicMock, patch
from starlette.testclient import TestClient
from app.main import app

def test_healthz_endpoint_healthy():
    """Verify GET /healthz returns status 200 when dependencies check passes."""
    with patch("app.api.v1.endpoints.health.get_supabase_admin_client") as mock_supabase, \
         patch("app.api.v1.endpoints.health.OpenNyAIEngine.get_instance") as mock_nlp:
        
        # Mock Supabase
        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.limit.return_value.execute.return_value = MagicMock()
        mock_supabase.return_value = mock_client

        # Mock OpenNyAI engine
        mock_engine = MagicMock()
        mock_engine._pipeline = MagicMock()
        mock_nlp.return_value = mock_engine

        client = TestClient(app)
        response = client.get("/healthz")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "HEALTHY"
        assert data["dummy_data_enforced"] is True
        assert data["opennyai_loaded"] is True
        assert data["supabase_connected"] is True

def test_healthz_endpoint_unhealthy_when_supabase_fails():
    """Verify GET /healthz returns status 503 when Supabase query fails."""
    with patch("app.api.v1.endpoints.health.get_supabase_admin_client") as mock_supabase:
        mock_client = MagicMock()
        mock_client.table.return_value.select.return_value.limit.return_value.execute.side_effect = Exception("DB Connection Timeout")
        mock_supabase.return_value = mock_client

        client = TestClient(app)
        response = client.get("/healthz")

        assert response.status_code == 503
        data = response.json()
        assert data["status"] == "UNHEALTHY"
        assert data["supabase_connected"] is False
        assert "DB Connection Timeout" in data["supabase_error"]
