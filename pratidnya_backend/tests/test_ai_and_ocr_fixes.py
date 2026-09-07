import pytest
from app.services.opennyai_engine import OpenNyAIEngine
from app.services.judgment_ocr_extractor import JudgmentOcrExtractor
from app.core.config import settings

def test_nlp_01_opennyai_never_returns_none():
    """NLP-01: Verifies process_chargesheet returns structured dict, not None."""
    engine = OpenNyAIEngine.get_instance()
    sample_text = "थाना कोतवाली नगर, मु.अ.सं. 102/2026, धारा 379, 411 भा.दं.वि.। अभियुक्त को चोरी के माल सहित गिरफ्तार किया गया।"
    
    result = engine.process_chargesheet(sample_text)
    assert result is not None, "NLP-01 Regression: process_chargesheet returned None!"
    assert isinstance(result, dict)
    assert "facts_extracts" in result
    assert "provisions_detected" in result
    assert len(result["facts_extracts"]) > 0

def test_ocr_01_smart_sampling_preserves_head_and_tail():
    """OCR-01: Verifies 25-page PDF is sampled across head (1-5) and tail (16-25), not truncated to [:15]."""
    mock_pages = [(i, b"mock_img_bytes") for i in range(1, 26)] # 25 pages
    sampled = JudgmentOcrExtractor._smart_sample_pages(mock_pages, max_budget=15)
    
    assert len(sampled) == 15
    page_numbers = [p[0] for p in sampled]
    
    # Head pages must be present
    assert 1 in page_numbers
    assert 5 in page_numbers
    # Tail operative pages must be present
    assert 25 in page_numbers
    assert 20 in page_numbers
    # Intermediate non-critical pages (e.g. page 10) skipped
    assert 10 not in page_numbers

def test_cfg_01_pydantic_v2_model_config():
    """CFG-01: Ensures Pydantic v2 SettingsConfigDict is properly loaded without Config deprecation."""
    assert hasattr(settings, "model_config"), "Pydantic v2 model_config missing!"
    assert settings.PORT == 8000
    assert settings.DEFAULT_LLM_PROVIDER in ["GROQ", "GEMINI"]
