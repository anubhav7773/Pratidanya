import re
import unicodedata
from typing import Dict

class PoliceDocumentSanitizer:
    """
    Production pre-processor for Indian subordinate court police chargesheets,
    case diaries, and FIRs. Normalizes Devanagari Unicode, repairs broken OCR
    conjuncts, and expands standardized police/court abbreviations.
    """

    # Subordinate Court & State Police Standard Abbreviations
    ABBREVIATION_MAP: Dict[str, str] = {
        r"मु\.अ\.सं\.": "मुकदमा अपराध संख्या",
        r"मु\.अ\.स\.": "मुकदमा अपराध संख्या",
        r"अ\.सं\.": "अपराध संख्या",
        r"था\.": "थाना",
        r"अ\.पु\.अ\.": "अपर पुलिस अधीक्षक",
        r"पु\.उ\.नि\.": "पुलिस उपनिरीक्षक",
        r"उ\.नि\.": "उपनिरीक्षक",
        r"प्र\.नि\.": "प्रभारी निरीक्षक",
        r"कां\.": "कांस्टेबल",
        r"हे\.का\.": "हेड कांस्टेबल",
        r"ज\.फ\.": "जब्ती फर्द",
        r"फ\.ब\.": "फर्द बरामदगी",
        r"ग्रा\.": "ग्राम",
        r"नि\.": "निवासी",
        r"जि\.": "जिला",
        r"भा\.दं\.वि\.": "भारतीय दंड विधान",
        r"भा\.द\.वि\.": "भारतीय दंड विधान",
        r"दं\.प्र\.सं\.": "दंड प्रक्रिया संहिता",
        r"द\.प्र\.सं\.": "दंड प्रक्रिया संहिता",
        r"बी\.एन\.एस\.": "भारतीय न्याय संहिता",
        r"बी\.एन\.एस\.एस\.": "भारतीय नागरिक सुरक्षा संहिता",
        r"एन\.आई\.एक्ट": "परक्राम्य लिखत अधिनियम",
        r"एन\.डी\.पी\.एस\.": "स्वापक औषधि और मनःप्रभावी पदार्थ अधिनियम",
        r"सी\.जे\.एम\.": "मुख्य न्यायिक मजिस्ट्रेट",
        r"ए\.सी\.जे\.एम\.": "अपर मुख्य न्यायिक मजिस्ट्रेट",
    }

    @classmethod
    def clean_and_normalize(cls, raw_text: str) -> str:
        if not raw_text:
            return ""

        # 1. Unicode Normalization (NFKC standard for Devanagari)
        text = unicodedata.normalize("NFKC", raw_text)

        # 2. Strip Zero-Width Joiners / Non-Joiners that break NLP tokenizers
        text = text.replace("\u200c", "").replace("\u200d", "").replace("\ufeff", "")

        # 3. Clean scanner/photocopy OCR noise (excessive underscores, tildes, pipes)
        text = re.sub(r"_{2,}", " ", text)
        text = re.sub(r"-{3,}", " ", text)
        text = re.sub(r"\.{4,}", "...", text)
        text = re.sub(r"[~^`\t]", " ", text)

        # 4. Expand standardized police abbreviations for accurate OpenNyAI NER
        for abbr_pattern, full_term in cls.ABBREVIATION_MAP.items():
            text = re.sub(abbr_pattern, full_term, text)

        # 5. Normalize spacing around punctuation and Purna Viram (|)
        text = re.sub(r"\s+", " ", text)
        text = re.sub(r"\s*।\s*", "। ", text)
        text = re.sub(r"\s*\.\s*", ". ", text)

        return text.strip()
