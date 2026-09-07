import pytest
import io
import base64
import logging
from fastapi import FastAPI, UploadFile, HTTPException
from fastapi.testclient import TestClient
from starlette.requests import Request
from pydantic import ValidationError
from slowapi.errors import RateLimitExceeded

from app.core.security_headers import ProductionSecurityHeadersMiddleware
from app.core.sanitized_logger import SensitiveDataScrubbingFilter
from app.core.field_crypto import FieldCrypto
from app.core.file_upload_guard import SecureUploadGuard
from app.schemas.base_security_schema import StrictInputSchema, StrictOutputSchema
from app.core.rate_limiter import limiter, rate_limit_exceeded_handler
from app.core.config import settings


def test_production_security_headers_middleware():
    app = FastAPI()
    app.add_middleware(ProductionSecurityHeadersMiddleware)

    @app.get("/test")
    def get_test():
        return {"status": "ok"}

    client = TestClient(app)
    response = client.get("/test")
    assert response.status_code == 200

    # Verify OWASP Top 10 hardening headers
    assert response.headers["Strict-Transport-Security"] == "max-age=63072000; includeSubDomains; preload"
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["X-XSS-Protection"] == "1; mode=block"
    assert response.headers["Referrer-Policy"] == "strict-origin-when-cross-origin"
    assert "geolocation=()" in response.headers["Permissions-Policy"]
    assert "default-src 'self'" in response.headers["Content-Security-Policy"]


def test_https_redirection_in_production(monkeypatch):
    monkeypatch.setattr(settings, "APP_ENV", "PRODUCTION")

    app = FastAPI()
    app.add_middleware(ProductionSecurityHeadersMiddleware)

    @app.get("/secure-endpoint")
    def get_secure():
        return {"message": "secure"}

    client = TestClient(app)

    # Insecure request (http) on production domain without https forwarded-proto should be redirected
    res = client.get("http://pratidnya-api.onrender.com/secure-endpoint", headers={"x-forwarded-proto": "http"}, follow_redirects=False)
    assert res.status_code == 301
    assert res.headers["location"].startswith("https://")


def test_sensitive_data_scrubbing_filter():
    scrubber = SensitiveDataScrubbingFilter()

    # JWT
    raw_jwt = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.do_not_leak_signature"
    assert scrubber.scrub(raw_jwt) == "Bearer [REDACTED_JWT]"

    # Groq API key
    raw_groq = "Authorization with gsk_abcdefghijklmnopqrstuvwxyz1234567890"
    assert "[REDACTED_GROQ_KEY]" in scrubber.scrub(raw_groq)

    # Gemini API key
    raw_gemini = "Using AIzaSyAbcde1234567890fghij12345678901 for generative AI"
    assert "[REDACTED_GEMINI_KEY]" in scrubber.scrub(raw_gemini)

    # Razorpay key
    raw_rzp = "Client initialized with rzp_test_abcdef12345678 and secret"
    assert "[REDACTED_RAZORPAY_KEY]" in scrubber.scrub(raw_rzp)

    # Password
    raw_pwd = 'payload: {"password": "superSecretPassword123"}'
    assert '[REDACTED_PASSWORD]' in scrubber.scrub(raw_pwd)

    # Aadhaar number
    raw_aadhaar = "Advocate Aadhaar: 1234 5678 9012 verified"
    assert "[Aadhaar Redacted]" in scrubber.scrub(raw_aadhaar)

    # Test logging.Filter integration
    record = logging.LogRecord(
        name="test", level=logging.INFO, pathname="", lineno=0,
        msg="Error authenticating with gsk_abcdefghijklmnopqrstuvwxyz1234567890",
        args=(), exc_info=None
    )
    scrubber.filter(record)
    assert "[REDACTED_GROQ_KEY]" in record.msg


def test_aes_256_gcm_field_crypto():
    original = "अभियुक्त: राम प्रकाश, मु.अ.सं. 124/2026, थाना: कोतवाली नगर"
    
    # 1. Round-trip encryption and decryption
    ciphertext = FieldCrypto.encrypt_field(original)
    assert ciphertext != original
    assert original not in ciphertext
    
    decrypted = FieldCrypto.decrypt_field(ciphertext)
    assert decrypted == original

    # 2. Nonce unpredictability: Encrypting the same text twice yields different ciphertexts
    ciphertext_2 = FieldCrypto.encrypt_field(original)
    assert ciphertext != ciphertext_2
    assert FieldCrypto.decrypt_field(ciphertext_2) == original

    # 3. Tamper detection: Modifying ciphertext bytes must raise 500
    raw_payload = bytearray(base64.b64decode(ciphertext))
    # Flip bit in ciphertext
    raw_payload[-1] ^= 0xFF
    tampered_b64 = base64.b64encode(raw_payload).decode("utf-8")

    with pytest.raises(HTTPException) as excinfo:
        FieldCrypto.decrypt_field(tampered_b64)
    assert excinfo.value.status_code == 500

    # 4. Empty strings
    assert FieldCrypto.encrypt_field("") == ""
    assert FieldCrypto.decrypt_field("") == ""


@pytest.mark.asyncio
async def test_secure_upload_guard_pdf():
    # Valid PDF
    valid_pdf = UploadFile(filename="case_report.pdf", file=io.BytesIO(b"%PDF-1.7\nValid pdf content"))
    content, mime = await SecureUploadGuard.validate_file(valid_pdf, expected_category="PDF")
    assert mime == "application/pdf"
    assert content.startswith(b"%PDF-")

    # Disguised fake PDF (ELF / Shell script)
    fake_pdf = UploadFile(filename="case_report.pdf", file=io.BytesIO(b"#!/bin/bash\necho malicious"))
    with pytest.raises(HTTPException) as excinfo:
        await SecureUploadGuard.validate_file(fake_pdf, expected_category="PDF")
    assert excinfo.value.status_code == 415

    # Path traversal in filename
    traversal_file = UploadFile(filename="../../etc/passwd", file=io.BytesIO(b"%PDF-1.7"))
    with pytest.raises(HTTPException) as excinfo:
        await SecureUploadGuard.validate_file(traversal_file, expected_category="PDF")
    assert excinfo.value.status_code == 400

    # Empty file
    empty_file = UploadFile(filename="empty.pdf", file=io.BytesIO(b""))
    with pytest.raises(HTTPException) as excinfo:
        await SecureUploadGuard.validate_file(empty_file, expected_category="PDF")
    assert excinfo.value.status_code == 400


@pytest.mark.asyncio
async def test_secure_upload_guard_audio():
    # Valid MP3 with ID3 header
    valid_audio = UploadFile(
        filename="argument_recording.mp3",
        file=io.BytesIO(b"ID3\x03\x00\x00\x00\x00\x00\x00Dummy MP3 Audio Stream"),
        headers={"content-type": "audio/mpeg"}
    )
    content, mime = await SecureUploadGuard.validate_file(valid_audio, expected_category="AUDIO")
    assert "audio" in mime

    # Invalid audio
    invalid_audio = UploadFile(
        filename="fake_voice.mp3",
        file=io.BytesIO(b"Not an audio stream!"),
        headers={"content-type": "audio/mpeg"}
    )
    with pytest.raises(HTTPException) as excinfo:
        await SecureUploadGuard.validate_file(invalid_audio, expected_category="AUDIO")
    assert excinfo.value.status_code == 415


def test_strict_input_and_output_schema():
    class CaseInput(StrictInputSchema):
        client_name: str
        act_name: str

    # 1. Extra fields must be forbidden (Point 8 & 14)
    with pytest.raises(ValidationError):
        CaseInput(client_name="Ramesh Kumar", act_name="BNS 2023", injected_admin=True)

    # 2. XSS & HTML escaping and whitespace trimming (Point 15)
    valid_instance = CaseInput(
        client_name="  <script>alert('XSS')</script> Ramesh  ",
        act_name="NDPS Act \x001985"
    )
    assert valid_instance.client_name == "&lt;script&gt;alert(&#x27;XSS&#x27;)&lt;/script&gt; Ramesh"
    assert "\x00" not in valid_instance.act_name
    assert valid_instance.act_name == "NDPS Act 1985"

    # 3. Output trimming schema (Point 17)
    class CaseOutput(StrictOutputSchema):
        id: str
        client_name: str

    # Extra fields ignored
    data = {"id": "case_123", "client_name": "Ramesh", "internal_db_hash": "secret123"}
    output = CaseOutput(**data)
    assert output.id == "case_123"
    assert not hasattr(output, "internal_db_hash")


def test_rate_limiter_integration():
    app = FastAPI()
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

    @app.get("/rate-limited")
    @limiter.limit("2/minute")
    def limited_route(request: Request):
        return {"message": "success"}

    client = TestClient(app)
    # Request 1 & 2 should succeed
    res1 = client.get("/rate-limited")
    assert res1.status_code == 200
    res2 = client.get("/rate-limited")
    assert res2.status_code == 200

    # Request 3 should trigger 429
    res3 = client.get("/rate-limited")
    assert res3.status_code == 429
    assert "Rate Limit Exceeded" in res3.json()["detail"]
    assert res3.json()["statutory_guard"] == "Anti-Bot & DoS Protection Gate"
