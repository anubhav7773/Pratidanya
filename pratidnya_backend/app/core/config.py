import os
import json
from typing import Dict, Any, Optional
from pydantic_settings import BaseSettings
from pydantic import Field, field_validator

class Settings(BaseSettings):
    # Gemini AI Configuration (Live Production Engine)
    GEMINI_API_KEY: str = Field(..., description="Google AI Studio / Cloud Gemini API Key")
    GEMINI_PAID_TIER: bool = Field(default=True, description="Enables zero data retention on Google Cloud")
    ENFORCE_DUMMY_DATA: bool = Field(default=False, description="Disabled for live real-case processing")

    # App State
    APP_ENV: str = Field(default="PRODUCTION")
    PORT: int = Field(default=8000)

    # Kanoon.dev API Integration (Live REST Gateway)
    MOCK_KANOON_API: bool = Field(default=False, description="Strictly False: connects to live api.kanoon.dev/v1")
    KANOON_DEV_API_KEY: str = Field(..., description="Active kanoon.dev bearer token")
    KANOON_DEV_BASE_URL: str = Field(default="https://api.kanoon.dev/v1")
    KANOON_CACHE_TTL_HOURS: int = Field(default=12)

    # Supabase Connection (AWS Mumbai ap-south-1)
    SUPABASE_URL: str = Field(...)
    SUPABASE_SERVICE_ROLE_KEY: str = Field(...)

    # Firebase Admin Auth
    FIREBASE_PROJECT_ID: str = Field(default="pratidnya-legal-tech")
    FIREBASE_SERVICE_ACCOUNT_JSON: Optional[str] = Field(default=None)

    # Concurrency & Incident Monitoring
    MAX_CONCURRENT_NLP_JOBS: int = Field(default=4)
    DPBI_REPORTING_WEBHOOK_URL: str = Field(default="https://api.asiverticals.me/internal/dpdp/incident-alerts")

    @field_validator("GEMINI_API_KEY")
    def validate_gemini_key(cls, v: str) -> str:
        if not v or v.startswith("mock_") or len(v) < 15:
            raise ValueError("FATAL: Live production pipeline requires a valid Google Gemini API Key.")
        return v

    @field_validator("KANOON_DEV_API_KEY")
    def validate_kanoon_key(cls, v: str, info) -> str:
        data = info.data
        if not data.get("MOCK_KANOON_API", False):
            if not v or v.startswith("sk_mock") or len(v) < 10:
                raise ValueError("FATAL: Live Kanoon integration requires a valid kanoon.dev production API Key.")
        return v

    @field_validator("APP_ENV")
    def validate_production_privacy(cls, v: str, info) -> str:
        data = info.data
        if v == "PRODUCTION":
            paid_tier = data.get("GEMINI_PAID_TIER", False)
            dummy_data = data.get("ENFORCE_DUMMY_DATA", False)
            if not paid_tier and not dummy_data:
                raise ValueError(
                    "STATUTORY PRIVACY VIOLATION: Production processing of real case facts on Google Free Tier "
                    "violates DPDP Act 2023 Sec 8 and Advocates Act 1961 Sec 126. GEMINI_PAID_TIER must be True."
                )
        return v

    def get_firebase_credentials_dict(self) -> Optional[Dict[str, Any]]:
        if not self.FIREBASE_SERVICE_ACCOUNT_JSON:
            return None
        val = self.FIREBASE_SERVICE_ACCOUNT_JSON.strip()
        backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        candidate_paths = [val, os.path.join(backend_dir, val)]
        for cp in candidate_paths:
            if os.path.exists(cp):
                try:
                    with open(cp, "r", encoding="utf-8") as f:
                        return json.load(f)
                except Exception as e:
                    raise ValueError(f"Failed to read service account file at {cp}: {e}")
        try:
            return json.loads(val)
        except Exception:
            raise ValueError("FIREBASE_SERVICE_ACCOUNT_JSON is not a valid JSON string or file path.")


    class Config:
        env_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), ".env")
        case_sensitive = True
        extra = "ignore"


settings = Settings()
