import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

CHAMBER_HEADERS = {
    "Authorization": "Bearer chamber_advocate_up_1234_anubhav",
    "X-Advocate-ID": "adv_up_1234_anubhav",
    "X-Action-Name": "LIVE_RENDER_INTEGRATION_TEST",
    "X-Session-ID": "SESSION_GOAL_50_VERIFY",
    "X-Client-Language": "hi",
}

def test_01_default_bail_statutory_crystallization():
    """Module 1: Section 187 BNSS 90-day custody calculation and incomplete chargesheet audit."""
    payload = {
        "case_id": "LKO-CR-2026-101",
        "first_remand_date": "2026-06-01",
        "statutory_regime": "BNSS",
        "offense_sections": [{"act": "BNS", "section": "103(1)", "max_punishment_years": 99}],
        "chargesheet_filed": True,
        "chargesheet_filing_date": "2026-09-02",
        "chargesheet_annexures": ["SITE_PLAN"],  # Missing mandatory FSL report
        "accused_name": "रामू उर्फ राम प्रकाश",
        "police_station": "कोतवाली नगर",
        "district": "लखनऊ",
        "court_name": "न्यायालय मुख्य न्यायिक मजिस्ट्रेट"
    }
    res = client.post("/api/v1/remand/audit-default-bail", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["is_default_bail_crystallized"] is True
    assert data["is_chargesheet_incomplete"] is True
    assert "धारा 187" in data["statutory_petition_draft_hindi"]

def test_02_remand_arnesh_kumar_compliance():
    """Module 2: Section 35(3) BNSS / 41A CrPC notice and objective reasons audit."""
    payload = {
        "case_id": "LKO-CR-2026-101",
        "accused_name": "रामू",
        "police_station": "कोतवाली नगर",
        "district": "लखनऊ",
        "court_name": "न्यायालय मुख्य न्यायिक मजिस्ट्रेट",
        "charges": [{"act": "BNS", "section": "115(2)", "max_punishment_years": 1, "is_special_act": False}],
        "arrest_timestamp": "2026-09-14T10:00:00",
        "remand_production_timestamp": "2026-09-14T18:00:00",
        "notice_issued_sec_35_bnss": False,
        "flight_or_tampering_risk_recorded": False,
        "arrest_memo_witness_count": 0,
        "family_intimation_recorded": False,
        "medical_examination_conducted": True,
        "magistrate_independent_reasons_recorded": False
    }
    res = client.post("/api/v1/remand/audit-compliance", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["compliance_verdict"] == "NON_COMPLIANT_VOID_ARREST"
    assert "अर्नेश कुमार" in data["instant_objection_petition_draft"]

def test_03_undertrial_relief_one_third_rule():
    """Module 3: Section 479 BNSS 1/3rd detention threshold for first-time offenders."""
    payload = {
        "case_id": "LKO-CR-2024-302",
        "accused_name": "मोहम्मद असलम",
        "jail_name": "जिला कारागार लखनऊ",
        "custody_start_date": "2024-01-01",
        "is_first_time_offender": True,
        "multiple_cases_pending": False,
        "charges": [{"act": "IPC", "section": "379", "max_term_months": 36, "is_capital_or_life": False}],
        "fir_number": "302/2024",
        "police_station": "चौक",
        "district": "लखनऊ"
    }
    res = client.post("/api/v1/remand/audit-undertrial-relief", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["is_relief_applicable"] is True
    assert data["statutory_threshold_fraction"] == "1/3"
    assert "धारा 479" in data["court_application_draft_hindi"]

def test_04_bsa_section_63_certificate_audit():
    """Module 4: Section 63 BSA electronic certificate schedule and hash digest audit."""
    payload = {
        "case_id": "LKO-CR-2026-102",
        "exhibit_mark": "Ex. P-14",
        "evidence_type": "CALL_DETAIL_RECORD_CDR",
        "schedule_format_matched": False,
        "part_a_executed": True,
        "part_b_executed": False,
        "hash_algorithm": "NONE",
        "contemporaneous_acquisition": False,
        "accused_name": "दिनेश कुमार",
        "police_station": "हजरतगंज",
        "district": "लखनऊ"
    }
    res = client.post("/api/v1/evidence/audit-bsa-certificate", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["admissibility_status"] == "FATAL_DEFECT_INADMISSIBLE"
    assert len(data["statutory_defects"]) >= 2

def test_05_medico_legal_conflict_matrix():
    """Module 5: Autopsy PMR vs Ocular biomechanical conflict (Ram Narain Singh doctrine)."""
    payload = {
        "case_id": "LKO-CR-2026-101",
        "ocular_allegations": [{
            "witness_id": "PW-1",
            "witness_name": "वादी",
            "weapon_alleged": "तलवार (Sword - sharp cutting)",
            "incident_timestamp": "2026-09-14T20:00:00",
            "alleged_distance_meters": 1.0,
            "strike_location": "सिर"
        }],
        "post_mortem_data": {
            "pmr_number": "PMR-892/2026",
            "autopsy_doctor_name": "डॉ. वर्मा",
            "hospital_name": "जिला मोर्चरी",
            "autopsy_timestamp": "2026-09-15T08:00:00",
            "external_injuries": [{
                "injury_number": 1,
                "injury_type": "Lacerated wound (कुंद चोट)",
                "dimensions": "5cm x 2cm",
                "margins": "Irregular and contused",
                "anatomical_location": "Occipital region"
            }],
            "stomach_contents": "Semi-digested food",
            "rigor_mortis_state": "Present",
            "estimated_time_since_death_hours_min": 10.0,
            "estimated_time_since_death_hours_max": 14.0
        },
        "accused_name": "रामू",
        "police_station": "कोतवाली",
        "district": "लखनऊ"
    }
    res = client.post("/api/v1/forensics/generate-medical-matrix", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["has_fatal_conflict"] is True
    assert len(data["cross_examination_crossfire_questions"]) >= 1

def test_06_malkhana_chain_and_fsl_delay():
    """Module 6: Malkhana Register 19 and NCB 1/88 72-hour FSL dispatch delay."""
    payload = {
        "case_id": "LKO-CR-2026-102",
        "act_type": "NDPS",
        "seizure_date": "2026-08-01T10:00:00",
        "seizure_seal_impression": "THANA_SEAL",
        "malkhana_deposit_date": "2026-08-02T10:00:00",
        "malkhana_register_number": "Reg-19/402",
        "specimen_seal_deposited": False,
        "fsl_dispatch_date": "2026-09-05T10:00:00",  # 35-day dispatch delay
        "fsl_received_date": "2026-09-06T10:00:00",
        "fsl_receipt_seal_impression": "ILLEGIBLE",
        "road_certificate_annexed": False,
        "accused_name": "दिनेश कुमार",
        "police_station": "हजरतगंज",
        "district": "लखनऊ"
    }
    res = client.post("/api/v1/forensics/audit-malkhana-chain", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["has_fatal_tampering_risk"] is True
    assert "धारा 254" in data["application_sec_254_bnss_draft_hindi"]

def test_07_witness_impeachment_grid():
    """Module 7: Section 148 BSA / Tahsildar Singh material omissions in deposition."""
    payload = {
        "case_id": "LKO-CR-2026-101",
        "witness_code": "PW-2",
        "witness_name": "चंदन सिंह",
        "witness_role": "EYEWITNESS",
        "sec_161_crpc_statement": "गोली किसने चलाई यह मैं नहीं देख सका था।",
        "court_deposition_chief": "मैंने अभियुक्त रमेश को हाथ में पिस्तौल तानकर सीधे सीने पर दो फायर करते देखा था।",
        "defense_theory": "FALSE_IMPLICATION_AND_SUBSTANTIAL_IMPROVEMENT",
        "accused_name": "रमेश",
        "police_station": "कोतवाली",
        "district": "लखनऊ"
    }
    res = client.post("/api/v1/trial/generate-contradiction-grid", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["has_fatal_contradictions"] is True
    assert "Ex. D-1" in data["grid_analysis"][0]["marked_exhibit_identifier"]
    assert "तहसीलदार सिंह" in data["confrontation_master_script_hindi"]

def test_08_leading_question_cross_examination_deck():
    """Module 8: Section 147 BSA leading closed binary question trees."""
    payload = {
        "case_id": "LKO-CR-2026-101",
        "witness_name": "राम लखन (पंच साक्षी)",
        "witness_role": "PANCH_WITNESS_SEIZURE",
        "defense_theory": "PLANTED_RECOVERY_STOCK_WITNESS",
        "case_facts": {
            "recovery_place": "खुला अरहर का खेत",
            "witness_residence_distance_km": 14,
            "prior_appearances_count": 4,
            "weapon_type": "315 बोर तमंचा"
        },
        "accused_name": "रामू",
        "police_station": "कोतवाली नगर",
        "district": "लखनऊ"
    }
    res = client.post("/api/v1/trial/generate-cross-questions", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert len(data["question_trees"]) >= 3
    assert data["question_trees"][0]["expected_answer"] == "YES"

def test_09_up_gangsters_and_goondas_act_suite():
    """Module 9: UP Gangsters Rules 5/16 and Farhana predicate acquittal collapse."""
    payload = {
        "case_id": "LKO-CR-2026-001",
        "statute_applied": "UP_GANGSTERS_ACT_1986",
        "district": "लखनऊ",
        "police_station": "अलीगंज",
        "accused_name": "रवि प्रकाश",
        "joint_meeting_rule_5_documented": False,
        "dm_independent_mind_applied": False,
        "dm_endorsement_raw_text": "Approved as recommended (संस्तुति स्वीकृत)",
        "base_cases": [{
            "crime_number": "मु.अ.सं. 112/2021",
            "sections": "379/411 IPC",
            "status": "ACQUITTED_ON_MERITS",
            "disposal_date": "2023-11-20"
        }]
    }
    res = client.post("/api/v1/regional/audit-up-special-acts", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert data["is_farhana_collapse_triggered"] is True
    assert "अनुच्छेद 226" in data["draft_petition_hindi"]

def test_10_live_courtroom_edge_oral_prompt():
    """Module 10: Sub-500ms Edge Oral Prompting with commercial NDPS counter-ratio."""
    payload = {
        "case_id": "LKO-CR-2026-102",
        "adversary_argument_raw_text": "श्रीमान, अभियुक्त से कमर्शियल मात्रा (Commercial Quantity) बरामद हुई है, इसलिए धारा 37 में बेल नहीं दी जा सकती।",
        "active_judge_id": "JUDGE-UP-LKO-04",
        "active_offense_category": "NDPS"
    }
    res = client.post("/api/v1/courtroom/edge-oral-prompt", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    data = res.json()
    assert "धारा 37" in data["detected_adversarial_ratio"]
    assert len(data["immediate_counter_ratios"]) >= 1
    assert "धारा 52A" in data["immediate_counter_ratios"][0]["statutory_lever"]

def test_11_telemetry_event_logging():
    """Telemetry: Verifies client activity logs register with status LOGGED."""
    payload = {
        "event_type": "MODULE_EVALUATION",
        "module_name": "TRIAL_DEFENSE_SUITE",
        "action_details": {"target": "ALL_10_MODULES_VERIFIED"},
        "case_id": "INTEGRATION-TEST-SUITE"
    }
    res = client.post("/api/v1/telemetry/log-activity", json=payload, headers=CHAMBER_HEADERS)
    assert res.status_code == 200
    assert res.json()["status"] == "LOGGED"
