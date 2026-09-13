import pytest
from datetime import datetime, timezone, timedelta
from app.schemas.forensic_medical_schema import (
    MedicalMatrixAuditRequest,
    OcularWitnessClaim,
    PostMortemDataInput,
    ExternalInjuryDetail
)
from app.services.medico_legal_engine import MedicoLegalEngine

def test_weapon_mechanism_fatal_conflict_sword_vs_laceration():
    """Verifies fatal conflict when witness claims sharp sword assault, but PMR reveals laceration with contused margins."""
    now = datetime.now(timezone.utc)
    assault_time = now - timedelta(hours=14)

    req = MedicalMatrixAuditRequest(
        case_id="MURDER-WEAPON-CONFLICT",
        ocular_allegations=[
            OcularWitnessClaim(
                witness_id="PW-1 (वादी)",
                witness_name="राम सिंह",
                weapon_alleged="तलवार (Sword - sharp cutting weapon)",
                incident_timestamp=assault_time,
                alleged_distance_meters=1.0,
                strike_location="सिर (Occipital region)"
            )
        ],
        post_mortem_data=PostMortemDataInput(
            pmr_number="PMR-2024-892",
            autopsy_doctor_name="डॉ. एस.के. वर्मा",
            hospital_name="जिला मोर्चरी लखनऊ",
            autopsy_timestamp=now,
            external_injuries=[
                ExternalInjuryDetail(
                    injury_number=1,
                    injury_type="Lacerated wound",
                    dimensions="5cm x 2cm x bone deep",
                    margins="Irregular, contused and abraded",
                    anatomical_location="Occipital region of skull"
                )
            ],
            stomach_contents="Semi-digested rice and dal",
            rigor_mortis_state="Present all over body",
            estimated_time_since_death_hours_min=12.0,
            estimated_time_since_death_hours_max=16.0
        ),
        accused_name="दिलीप",
        police_station="गोसाईंगंज",
        district="लखनऊ"
    )

    result = MedicoLegalEngine.audit_medico_legal(req)

    assert result.has_fatal_conflict is True
    assert len(result.irreconcilable_conflicts) >= 1
    weapon_conflict = next(c for c in result.irreconcilable_conflicts if c.parameter == "WEAPON_MECHANISM")
    assert weapon_conflict.severity == "FATAL_CONTRADICTION"
    assert "कुंद वस्तु" in weapon_conflict.scientific_verdict_hindi
    assert "राम नारायण सिंह" in result.written_medical_argument_draft_hindi
    assert len(result.cross_examination_crossfire_questions) >= 2

def test_pmi_and_rigor_mortis_timeline_discrepancy():
    """Verifies that an assault claimed 4 hours prior to autopsy conflicts with an estimated PMI of 24-36 hours."""
    now = datetime.now(timezone.utc)
    # Stated assault only 4 hours ago, but autopsy says death was 24-36 hours ago
    assault_time = now - timedelta(hours=4)

    req = MedicalMatrixAuditRequest(
        case_id="PMI-TIMELINE-CONFLICT",
        ocular_allegations=[
            OcularWitnessClaim(
                witness_id="PW-2 (चश्मदीद)",
                witness_name="मुकेश",
                weapon_alleged="लाठी",
                incident_timestamp=assault_time,
                alleged_distance_meters=2.0,
                strike_location="छाती"
            )
        ],
        post_mortem_data=PostMortemDataInput(
            pmr_number="PMR-2024-411",
            autopsy_timestamp=now,
            external_injuries=[
                ExternalInjuryDetail(
                    injury_number=1,
                    injury_type="Contusion",
                    dimensions="10cm x 4cm",
                    margins="Contused",
                    anatomical_location="Chest wall"
                )
            ],
            stomach_contents="Empty",
            rigor_mortis_state="Passing off from face and neck, present in lower limbs",
            estimated_time_since_death_hours_min=24.0,
            estimated_time_since_death_hours_max=36.0
        )
    )

    result = MedicoLegalEngine.audit_medico_legal(req)

    assert result.has_fatal_conflict is True
    pmi_conflict = next(c for c in result.irreconcilable_conflicts if c.parameter == "TIME_OF_OCCURRENCE_PMI")
    assert pmi_conflict.severity == "FATAL_CONTRADICTION"
    assert "समय का भारी विचलन" in pmi_conflict.scientific_verdict_hindi

@pytest.mark.asyncio
async def test_generate_medical_matrix_api():
    """Verifies that POST /api/v1/forensics/generate-medical-matrix works over HTTP."""
    import httpx
    from app.main import app
    from app.core.security import verify_advocate_token

    app.dependency_overrides[verify_advocate_token] = lambda: {"uid": "adv_forensics_test"}
    try:
        now = datetime.now(timezone.utc)
        payload = {
            "case_id": "API-FORENSIC-CASE",
            "ocular_allegations": [
                {
                    "witness_id": "PW-1",
                    "witness_name": "राम किशोर",
                    "weapon_alleged": "Sword (तलवार)",
                    "incident_timestamp": (now - timedelta(hours=20)).isoformat(),
                    "alleged_distance_meters": 1.5,
                    "strike_location": "Head"
                }
            ],
            "post_mortem_data": {
                "pmr_number": "PMR-990",
                "autopsy_timestamp": now.isoformat(),
                "external_injuries": [
                    {
                        "injury_number": 1,
                        "injury_type": "Lacerated wound",
                        "dimensions": "4cm x 2cm",
                        "margins": "Irregular and contused",
                        "anatomical_location": "Parietal bone"
                    }
                ],
                "stomach_contents": "Empty",
                "rigor_mortis_state": "Present all over body",
                "estimated_time_since_death_hours_min": 18.0,
                "estimated_time_since_death_hours_max": 24.0
            },
            "accused_name": "विकास",
            "police_station": "हजरतगंज",
            "district": "लखनऊ"
        }

        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            resp = await client.post(
                "/api/v1/forensics/generate-medical-matrix",
                json=payload,
                headers={"Authorization": "Bearer mock_token"}
            )
            assert resp.status_code == 200, resp.text
            data = resp.json()
            assert data["has_fatal_conflict"] is True
            assert "written_medical_argument_draft_hindi" in data
            assert len(data["cross_examination_crossfire_questions"]) >= 1
    finally:
        app.dependency_overrides.clear()
