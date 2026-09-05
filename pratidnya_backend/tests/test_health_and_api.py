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

def test_uptimerobot_health_endpoint():
    """Verify lightweight /health endpoint returns 200 without DB requirement."""
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "HEALTHY"
    assert data["alive"] is True
    assert data["service"] == "pratidnya-backend"

def test_uptimerobot_health_head_method():
    """Verify HEAD /health returns 200 with custom headers for bandwidth-saving uptime monitors."""
    client = TestClient(app)
    response = client.head("/health")
    assert response.status_code == 200
    assert response.headers["X-Service"] == "pratidnya-backend"
    assert response.headers["X-Status"] == "healthy"
    assert response.headers["X-Uptime-Monitor"] == "active"
    assert len(response.content) == 0

def test_uptimerobot_root_head_method():
    """Verify HEAD / returns 200 with zero body."""
    client = TestClient(app)
    response = client.head("/")
    assert response.status_code == 200
    assert response.headers["X-Service"] == "pratidnya-backend"
    assert len(response.content) == 0

def test_ping_endpoint():
    """Verify /ping returns pong immediately (GET & HEAD)."""
    client = TestClient(app)
    response = client.get("/ping")
    assert response.status_code == 200
    assert response.json() == {"ping": "pong", "status": "ok"}

    head_resp = client.head("/ping")
    assert head_resp.status_code == 200
    assert len(head_resp.content) == 0

