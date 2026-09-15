import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_telemetry_log_activity_endpoint_success():
    """Verifies that client activity logs stream successfully and return 200 OK."""
    headers = {
        "Authorization": "Bearer chamber_advocate_up_1234_anubhav",
        "X-Advocate-ID": "adv_up_1234_anubhav",
        "X-Action-Name": "TEST_APP_LAUNCH_LOG"
    }

    payload = {
        "event_type": "APP_LAUNCH",
        "module_name": "DASHBOARD_INITIALIZE",
        "action_details": {"view": "ACTIVE_CRIMINAL_DOCKETS"},
        "case_id": "TEST-CASE-999"
    }

    response = client.post("/api/v1/telemetry/log-activity", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "LOGGED"
    assert data["event_type"] == "APP_LAUNCH"
    assert "adv_" in data["advocate_id"]

def test_telemetry_unauthorized_when_token_missing():
    """Verifies that missing token drops request with 401."""
    payload = {
        "event_type": "LOGIN_SUCCESS",
        "module_name": "AUTH",
        "action_details": {}
    }
    response = client.post("/api/v1/telemetry/log-activity", json=payload)
    assert response.status_code == 401
    assert "प्रमाणीकरण" in response.json()["detail"]

def test_middleware_latency_header_injected():
    """Verifies that ActivityLoggerMiddleware records response processing headers."""
    response = client.get("/health")
    assert response.status_code == 200
    assert "X-Server-Processing-Time-Ms" in response.headers

def test_mock_chamber_advocate_token_auth():
    """Verifies mock_token_* also accepted as chamber session token."""
    headers = {
        "Authorization": "Bearer mock_token_advocate_001",
        "X-Action-Name": "TEST_MOCK_TOKEN"
    }
    payload = {
        "event_type": "TAB_SWITCH",
        "module_name": "REMAND_DEFENSE",
        "action_details": {"tab": "DEFAULT_BAIL"}
    }
    response = client.post("/api/v1/telemetry/log-activity", json=payload, headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "LOGGED"
