import os
import json
from typing import Dict, Any, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator

class Settings(BaseSettings):
    # App State
    APP_ENV: str = Field(default="DEVELOPMENT")
    PORT: int = Field(default=8000)

    # Gemini AI Configuration
    GEMINI_API_KEY: str = Field(default="test_gemini_api_key")
    GEMINI_PAID_TIER: bool = Field(default=False)
    ENFORCE_DUMMY_DATA: bool = Field(default=True)

    # Kanoon.dev API Integration
    KANOON_DEV_API_KEY: str = Field(default="sk_mock_test_key")
    MOCK_KANOON_API: bool = Field(default=True)

    # Supabase (AWS Mumbai ap-south-1)
    SUPABASE_URL: str = Field(default="https://edekorlixzhqeavrhtbe.supabase.co")
    SUPABASE_SERVICE_ROLE_KEY: str = Field(default="mock_service_role_key")

    # Firebase Admin Auth Credentials
    FIREBASE_PROJECT_ID: str = Field(default="pratidnya-legal-tech")
    FIREBASE_SERVICE_ACCOUNT_JSON: Optional[str] = Field(default=None)

    # Concurrency Throttling & Incident Alerting
    MAX_CONCURRENT_NLP_JOBS: int = Field(default=4)
    DPBI_REPORTING_WEBHOOK_URL: str = Field(default="https://api.asiverticals.me/internal/dpdp/incident-alerts")

    @field_validator("APP_ENV")
    def validate_production_privacy(cls, v, info):
        data = info.data
        if v == "PRODUCTION":
            paid_tier = data.get("GEMINI_PAID_TIER", False)
            dummy_data = data.get("ENFORCE_DUMMY_DATA", True)
            if not paid_tier and not dummy_data:
                raise ValueError(
                    "FATAL SECURITY CONFIGURATION: Production deployment cannot run on Free Tier "
                    "without dummy data enforcement. Violates DPDP Act 2023 & Advocates Act 1961."
                )
        return v

    def get_firebase_credentials_dict(self) -> Optional[Dict[str, Any]]:
        if not self.FIREBASE_SERVICE_ACCOUNT_JSON:
            return None
        val = self.FIREBASE_SERVICE_ACCOUNT_JSON.strip()
        if os.path.exists(val):
            try:
                with open(val, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                raise ValueError(f"Failed to read service account file at {val}: {e}")
        try:
            return json.loads(val)
        except Exception:
            raise ValueError("FIREBASE_SERVICE_ACCOUNT_JSON is not a valid JSON string or file path.")

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore"
    )

settings = Settings()
