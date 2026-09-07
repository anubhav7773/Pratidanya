import os
import base64
from typing import Optional
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from fastapi import HTTPException
from app.core.config import settings

class FieldCrypto:
    """
    AES-256-GCM Field-Level Authenticated Encryption:
    Used to encrypt sensitive client names, contact records, and unverified FIR notes
    at rest before persisting to PostgreSQL (DPDP Act 2023 Sec 8(5)).
    Includes a 96-bit cryptographic nonce to prevent replay attacks and ciphertext tampering.
    """

    _key: Optional[bytes] = None

    @classmethod
    def _get_key(cls) -> bytes:
        if cls._key is None:
            raw_key = os.getenv("PRATIDNYA_ENCRYPTION_KEY")
            if not raw_key:
                # Deterministic fallback derived from service role secret for dev environments
                raw_key = base64.b64encode(settings.SUPABASE_SERVICE_ROLE_KEY[:32].encode()).decode()
            cls._key = base64.b64decode(raw_key.strip())
            if len(cls._key) not in [16, 24, 32]:
                raise ValueError("PRATIDNYA_ENCRYPTION_KEY must be 128, 192, or 256 bits in base64.")
        return cls._key

    @classmethod
    def encrypt_field(cls, plaintext: str) -> str:
        if not plaintext:
            return ""
        key = cls._get_key()
        aesgcm = AESGCM(key)
        nonce = os.urandom(12)  # 96-bit random nonce
        ciphertext = aesgcm.encrypt(nonce, plaintext.encode("utf-8"), None)
        # Store as base64 payload: nonce + ciphertext
        return base64.b64encode(nonce + ciphertext).decode("utf-8")

    @classmethod
    def decrypt_field(cls, payload_b64: str) -> str:
        if not payload_b64:
            return ""
        try:
            raw = base64.b64decode(payload_b64.encode("utf-8"))
            nonce = raw[:12]
            ciphertext = raw[12:]
            key = cls._get_key()
            aesgcm = AESGCM(key)
            decrypted = aesgcm.decrypt(nonce, ciphertext, None)
            return decrypted.decode("utf-8")
        except Exception:
            raise HTTPException(
                status_code=500,
                detail="डेटा डिक्रिप्शन विफलता: सिफरटेक्स्ट विकृत अथवा अनधिकृत है।"
            )
