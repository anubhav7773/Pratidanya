import pytest
from fastapi import HTTPException
from app.services.gemini_service import GeminiService
from app.services.grounding_validator import GroundingValidator

def test_free_tier_blocks_real_case_data():
    """Rule 6 & DPDP Act 2023: Free tier MUST block real client/case data."""
    service = GeminiService()
    service.is_paid_tier = False
    with pytest.raises(HTTPException) as excinfo:
        service._verify_privacy_firewall(is_dummy_data=False)
    assert excinfo.value.status_code == 403
    assert "गोपनीयता सुरक्षा निषेध" in excinfo.value.detail

def test_free_tier_allows_dummy_data():
    """Free tier is permitted to process sanitized/dummy test data."""
    service = GeminiService()
    service.is_paid_tier = False
    # Should not raise exception
    service._verify_privacy_firewall(is_dummy_data=True)

def test_paid_tier_allows_real_case_data():
    """Paid tier (with zero data retention agreement) permits real case analysis."""
    service = GeminiService()
    service.is_paid_tier = True
    # Should not raise exception
    service._verify_privacy_firewall(is_dummy_data=False)

def test_grounding_validator_strips_hallucinated_citations():
    """Rule 1 & Rule 2: Unverified or ungrounded citations must be stripped."""
    retrieved_precedents = [
        {
            "citation_id": "AIR 1980 SC 785",
            "court_name": "Supreme Court of India",
            "verified_source_url": "https://judgments.ecourts.gov.in/dummy_785.pdf",
            "verbatim_text": "Bail is the rule and committal to jail an exception in ordinary criminal matters."
        }
    ]
    
    generated_citations = [
        {
            "citation_id": "AIR 1980 SC 785",
            "quoted_passage": "Bail is the rule and committal to jail an exception"
        },
        {
            "citation_id": "AIR 2024 SC 9999", # Hallucinated citation
            "quoted_passage": "Completely fabricated precedent passage"
        }
    ]

    verified = GroundingValidator.verify_precedent_citations(
        generated_citations=generated_citations,
        retrieved_precedents=retrieved_precedents
    )

    assert len(verified) == 1
    assert verified[0]["citation_id"] == "AIR 1980 SC 785"
    assert verified[0]["is_grounded_in_record"] is True
    assert verified[0]["verified_source_url"] == "https://judgments.ecourts.gov.in/dummy_785.pdf"
