import pytest
from starlette.testclient import TestClient
from app.main import app
from app.services.ecourts_service import EcourtsService

client = TestClient(app)

def test_validate_cnr_valid():
    raw = "UPHC010123452026"
    res = EcourtsService.validate_and_parse_cnr(raw)
    assert res["is_valid"] is True
    assert res["state_code"] == "UP"
    assert res["state_name"] == "Uttar Pradesh"
    assert res["district_code"] == "HC"
    assert res["court_complex_code"] == "01"
    assert res["case_sequence"] == "012345"
    assert res["filing_year"] == 2026
    assert res["formatted_cnr"] == "UP-HC01-012345-2026"

def test_validate_cnr_with_formatting_characters():
    # User might paste with spaces or dashes
    raw = "UP-HC 01-012345-2026"
    res = EcourtsService.validate_and_parse_cnr(raw)
    assert res["cnr_number"] == "UPHC010123452026"
    assert res["is_valid"] is True

def test_validate_cnr_invalid_length_and_format():
    with pytest.raises(Exception):
        EcourtsService.validate_and_parse_cnr("SHORT123")
    
    with pytest.raises(Exception):
        EcourtsService.validate_and_parse_cnr("1234567890123456")  # No state letters

def test_sync_case_with_cis():
    cnr = "UPLK010045212026"
    sync_result = EcourtsService.sync_case_with_cis(
        cnr_number=cnr,
        fir_number="189/2026",
        district="लखनऊ",
    )
    assert sync_result["status"] == "SUCCESS"
    assert sync_result["cnr_number"] == cnr
    assert sync_result["is_verified_ecourts"] is True
    assert "श्री राकेश कुमार सिंह" in sync_result["court_coram"]
    assert sync_result["stage_of_case"] == "जमानत प्रार्थना पत्र सुनवाई (Bail Arguments)"
    assert sync_result["order_pdf_url"].startswith("https://judgments.ecourts.gov.in/pdfcache/")
    assert len(sync_result["proceedings_history"]) >= 2

def test_daily_cause_list():
    cause_list = EcourtsService.get_daily_cause_list(
        district="Lucknow",
        advocate_bar_number="UP/1234/2018",
    )
    assert cause_list["total_listed"] >= 5
    assert "श्री राकेश कुमार सिंह" in cause_list["presiding_judge"]
    assert any(e["is_my_case"] is True for e in cause_list["entries"])
    first_entry = cause_list["entries"][0]
    assert "item_number" in first_entry
    assert "court_room" in first_entry
    assert "stage_of_hearing" in first_entry
    assert "listing_status" in first_entry

def test_api_validate_cnr_endpoint():
    response = client.post(
        "/api/v1/ecourts/validate-cnr",
        json={"cnr_number": "UPKN020054322025"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["state_code"] == "UP"
    assert data["district_code"] == "KN"
    assert data["filing_year"] == 2025

def test_api_sync_endpoint():
    response = client.post(
        "/api/v1/ecourts/sync",
        json={
            "cnr_number": "UPLK010003422026",
            "fir_number": "89/2026",
            "district": "Lucknow"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["is_verified_ecourts"] is True
    assert "next_hearing_date" in data
    assert "order_pdf_url" in data

def test_api_cause_list_endpoint():
    response = client.get(
        "/api/v1/ecourts/cause-list?district=Lucknow&advocate_bar_number=UP/1234/2018"
    )
    assert response.status_code == 200
    data = response.json()
    assert data["total_listed"] >= 5
    assert len(data["entries"]) >= 5

def test_api_webhook_endpoint():
    response = client.post(
        "/api/v1/ecourts/webhook",
        json={
            "event_type": "ORDER_UPLOADED",
            "cnr_number": "UPLK010003422026",
            "case_number": "Bail App 342/2026",
            "next_date": "2026-09-12",
            "order_summary": "केस डायरी तलब"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "PROCESSED"
    assert data["notification_dispatched"] is True
