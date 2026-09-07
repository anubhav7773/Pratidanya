import re
import logging
from typing import Any

class SensitiveDataScrubbingFilter(logging.Filter):
    """
    Scrubs API keys, passwords, Firebase/Supabase bearer tokens,
    and sensitive national identity numbers from server logs.
    """

    PATTERNS = [
        (re.compile(r"Bearer\s+[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*", re.IGNORECASE), "Bearer [REDACTED_JWT]"),
        (re.compile(r"gsk_[A-Za-z0-9]{30,}", re.IGNORECASE), "[REDACTED_GROQ_KEY]"),
        (re.compile(r"AIza[0-9A-Za-z-_]{30,40}", re.IGNORECASE), "[REDACTED_GEMINI_KEY]"),
        (re.compile(r"rzp_(?:test|live)_[A-Za-z0-9]+", re.IGNORECASE), "[REDACTED_RAZORPAY_KEY]"),
        (re.compile(r"(password[\"':\s=]+)[\"'][^\"']+[\"']", re.IGNORECASE), r'\1"[REDACTED_PASSWORD]"'),
        (re.compile(r"\b\d{4}\s?\d{4}\s?\d{4}\b"), "[Aadhaar Redacted]"),
    ]

    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.msg, str):
            record.msg = self.scrub(record.msg)
        if record.args:
            record.args = tuple(
                self.scrub(arg) if isinstance(arg, str) else arg for arg in record.args
            )
        return True

    @classmethod
    def scrub(cls, text: str) -> str:
        for pattern, replacement in cls.PATTERNS:
            text = pattern.sub(replacement, text)
        return text

def configure_production_logging():
    """Applies the scrubbing filter to root logger and active log handlers."""
    root_logger = logging.getLogger()
    scrubber = SensitiveDataScrubbingFilter()
    root_logger.addFilter(scrubber)
    for handler in root_logger.handlers:
        handler.addFilter(scrubber)
