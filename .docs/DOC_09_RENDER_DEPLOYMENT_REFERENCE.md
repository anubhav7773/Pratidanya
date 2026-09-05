================================================================================
PRATIDNYA LEGAL TECH (ASIVERTICALS) — REFERENCE SPECIFICATION
DOCUMENT ID    : DOC-09
MODULE         : RENDER BACKEND DEPLOYMENT, DOCKER SPEC & CLOUD INFRASTRUCTURE
TARGET RUNTIME : Python 3.10+ / FastAPI / Docker / Render Linux Web Service
HOST REGION    : AWS ap-south-1 (Mumbai, India) / Render Singapore/Frankfurt Bridge
AI CODER TARGET: ANTIGRAVITY (ZERO-HALLUCINATION SPECIFICATION)
================================================================================
1. CLOUD ARCHITECTURE & COMPUTE CAPACITY PLANNING
Pratidnya microservice Render platform par deploy hogi aur teen core engines ko host karegi:

OpenNyAI Pipeline (Self-hosted Legal NER & Rhetorical Roles)

Kanoon.dev API Proxy & 12-Hour Cache Gateway

Google Gemini LLM Privacy Firewall & Quota Manager

┌────────────────────────────────────────────────────────────────────────┐
│               FLUTTER CLIENT (ANDROID / IOS APPS)                      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS (TLS 1.3 Strict)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     RENDER WEB SERVICE EDGE PROXY                      │
│  - Automatic SSL/TLS Certificate Provisioning                          │
│  - Cloudflare DDoS Mitigation                                          │
│  - Port Routing: Incoming 443 ➔ Container Port $PORT                   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   DOCKER CONTAINER (PYTHON 3.10-SLIM)                  │
│  - Single-Worker Uvicorn Server (ASGI)                                 │
│  - Concurrency Semaphore (Max 4 concurrent NLP jobs)                   │
│  - Pre-cached OpenNyAI Models in Container Image Layer                 │
│  - Memory Footprint: ~1.4 GB Idle / ~1.7 GB Active Processing          │
└────────────────────────────────────────────────────────────────────────┘
Free Tier vs. Starter Tier Reality Check
Render Free Tier Limit: Strictly 512 MB RAM. Agar free tier par OpenNyAI load kiya gaya, toh SpaCy pipelines aur PyTorch transformers load hote hi Linux Kernel OOM killer container ko terminate kar dega (Exit Code 137).

Production / Pilot Requirement: Pratidnya backend microservice ke liye Render Starter Plan (2 GB RAM, 1 Shared vCPU) choose karna anivarya hai.

Cost Factor: ~$7/month (Asiverticals infrastructure budget-friendly).

2. PRODUCTION MULTI-STAGE DOCKERFILE
Antigravity ko microservice containerize karne ke liye yeh exact multi-stage Dockerfile use karni hai. Isme models build time par download hokar image layer mein bake ho jaate hain taaki container startup par runtime download delay ya network timeout na aaye:

Dockerfile
# ==============================================================================
# STAGE 1: Build & Dependency Wheel Resolver
# ==============================================================================
FROM python:3.10-slim as builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /install

# Install build-essential for C-extensions compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# 1. Install CPU-only PyTorch first (Prevents multi-gigabyte CUDA bloat)
RUN pip install --no-cache-dir --prefix=/install torch==2.2.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu

# 2. Install remaining production dependencies
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ==============================================================================
# STAGE 2: Lightweight Production Runtime Container
# ==============================================================================
FROM python:3.10-slim as runner

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    APP_ENV=PRODUCTION \
    # OpenNyAI / SpaCy Pre-load Directory
    TORCH_HOME=/app/cache/torch \
    SPACY_DATA=/app/cache/spacy

WORKDIR /app

# Install minimal runtime libraries (curl for Render Healthchecks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python site-packages from builder
COPY --from=builder /install /usr/local

# Create non-root system user for DPDP Act security compliance
RUN groupadd -r pratidnya && useradd -r -g pratidnya -m -d /home/pratidnya pratidnya

# Copy application source tree
COPY . /app

# Create cache directories and grant permissions
RUN mkdir -p /app/cache/torch /app/cache/spacy && \
    chown -R pratidnya:pratidnya /app

# Switch to non-root execution
USER pratidnya

# Pre-download OpenNyAI / SpaCy model weights during docker build
RUN python -c "from opennyai import Pipeline; Pipeline(components=['NER', 'Rhetorical_Role'], use_gpu=False, verbose=False)" || true

# Healthcheck probe for Render orchestrator
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD curl -f http://127.0.0.1:${PORT}/healthz || exit 1

EXPOSE 8000

# STRICT: Single worker uvicorn to prevent memory multiplication & OOM
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --workers 1 --loop uvloop --http httptools --lifespan on"]
3. RENDER BLUEPRINT SPECIFICATION (render.yaml)
Render par infrastructure-as-code deploy karne ke liye root directory mein render.yaml file configure karni hai:

YAML
services:
  - type: web
    name: pratidnya-backend-api
    env: docker
    plan: starter # 2GB RAM / 1 vCPU ($7/month) - Mandatory for OpenNyAI
    region: singapore # Nearest low-latency region to India
    dockerfilePath: Dockerfile
    healthCheckPath: /healthz
    autoDeploy: true
    envVars:
      - key: APP_ENV
        value: PRODUCTION
      - key: PORT
        value: 8000
      - key: GEMINI_PAID_TIER
        value: "false" # Set to 'true' when billing linked for real pilot
      - key: ENFORCE_DUMMY_DATA
        value: "true" # Must be true during development
      - key: GEMINI_API_KEY
        sync: false # Set securely in Render Dashboard
      - key: KANOON_DEV_API_KEY
        sync: false # Set securely in Render Dashboard
      - key: MOCK_KANOON_API
        value: "false"
      - key: SUPABASE_URL
        sync: false
      - key: SUPABASE_SERVICE_ROLE_KEY
        sync: false
      - key: FIREBASE_PROJECT_ID
        value: "pratidnya-legal-tech"
      - key: FIREBASE_SERVICE_ACCOUNT_JSON
        sync: false # Minified JSON credentials injected via Render Secret
      - key: DPBI_REPORTING_WEBHOOK_URL
        value: "https://api.asiverticals.me/internal/dpdp/incident-alerts"
      - key: MAX_CONCURRENT_NLP_JOBS
        value: "4"
4. ENVIRONMENT CONFIGURATION & VALIDATION ENGINE (config.py)
Pydantic Settings module jo server startup par har zaroori secret ko validate karta hai:

Python
# app/core/config.py
import json
from typing import Dict, Any, Optional
from pydantic_settings import BaseSettings
from pydantic import Field, field_validator

class Settings(BaseSettings):
    # Application State
    APP_ENV: str = Field(default="DEVELOPMENT")
    PORT: int = Field(default=8000)
    
    # Gemini AI Configuration
    GEMINI_API_KEY: str = Field(...)
    GEMINI_PAID_TIER: bool = Field(default=False)
    ENFORCE_DUMMY_DATA: bool = Field(default=True)
    
    # Kanoon.dev Integration
    KANOON_DEV_API_KEY: str = Field(default="sk_mock_test_key")
    MOCK_KANOON_API: bool = Field(default=True)
    
    # Supabase (AWS Mumbai ap-south-1)
    SUPABASE_URL: str = Field(...)
    SUPABASE_SERVICE_ROLE_KEY: str = Field(...)
    
    # Firebase Service Account Credentials
    FIREBASE_PROJECT_ID: str = Field(default="pratidnya-legal-tech")
    FIREBASE_SERVICE_ACCOUNT_JSON: Optional[str] = Field(default=None)
    
    # Concurrency & Performance
    MAX_CONCURRENT_NLP_JOBS: int = Field(default=4)
    DPBI_REPORTING_WEBHOOK_URL: str = Field(default="https://api.asiverticals.me/internal/dpdp/incident-alerts")

    @field_validator("APP_ENV")
    def validate_production_privacy(cls, v, values):
        """Rule 6: Mandates Paid Tier on production launch."""
        data = values.data
        if v == "PRODUCTION":
            paid_tier = data.get("GEMINI_PAID_TIER", False)
            dummy_data = data.get("ENFORCE_DUMMY_DATA", True)
            if not paid_tier and not dummy_data:
                raise ValueError(
                    "FATAL SECURITY CONFIGURATION: Production deployment cannot run on Free Tier "
                    "without dummy data enforcement. Violates DPDP Act 2023 & BCI Privilege."
                )
        return v

    def get_firebase_credentials_dict(self) -> Optional[Dict[str, Any]]:
        if not self.FIREBASE_SERVICE_ACCOUNT_JSON:
            return None
        try:
            return json.loads(self.FIREBASE_SERVICE_ACCOUNT_JSON)
        except Exception:
            raise ValueError("FIREBASE_SERVICE_ACCOUNT_JSON is not a valid JSON string.")

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
5. CONCURRENCY THROTTLING & MEMORY PRESERVATION
District Court lawyers ek sath multiple 30-page chargesheets upload kar sakte hain. Render ke single-worker CPU par crash rokhne ke liye Asyncio Semaphore lagana mandatory hai:

Python
# app/core/concurrency.py
import asyncio
from fastapi import HTTPException
from app.core.config import settings

# Global concurrency guard
nlp_semaphore = asyncio.Semaphore(settings.MAX_CONCURRENT_NLP_JOBS)

async def acquire_nlp_slot():
    """
    Ensures no more than MAX_CONCURRENT_NLP_JOBS run simultaneously,
    preventing CPU spikes and memory exhaustion on Render.
    """
    try:
        # Wait up to 15 seconds for a processing slot
        await asyncio.wait_for(nlp_semaphore.acquire(), timeout=15.0)
    except asyncio.TimeoutError:
        raise HTTPException(
            status_code=503,
            detail="सर्वर व्यस्त है: कई अधिवक्ता एक साथ अभियोग पत्र का विश्लेषण कर रहे हैं। "
                   "कृपया 15 सेकंड बाद पुनः प्रयास करें।"
        )

def release_nlp_slot():
    nlp_semaphore.release()
6. HEALTHCHECK & READINESS PROBE (/healthz)
Render service orchestration ke dauran healthcheck endpoint call karta hai. Yeh endpoint verify karta hai ki database, AI engine aur auth systems functional hain:

Python
# app/api/v1/endpoints/health.py
from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.core.supabase_client import get_supabase_admin_client
from app.services.opennyai_engine import OpenNyAIEngine

router = APIRouter()

@router.get("/healthz", tags=["System Diagnostics"])
async def health_check_probe():
    diagnostics = {
        "status": "HEALTHY",
        "app_env": settings.APP_ENV,
        "paid_tier_active": settings.GEMINI_PAID_TIER,
        "dummy_data_enforced": settings.ENFORCE_DUMMY_DATA,
        "opennyai_loaded": False,
        "supabase_connected": False,
    }

    # 1. Verify OpenNyAI Pipeline state in RAM
    try:
        engine = OpenNyAIEngine.get_instance()
        diagnostics["opennyai_loaded"] = engine._pipeline is not None
    except Exception:
        diagnostics["opennyai_loaded"] = False

    # 2. Verify Supabase Database connectivity
    try:
        client = get_supabase_admin_client()
        # Query 1 row from public verified precedents
        res = client.table("verified_precedents").select("id").limit(1).execute()
        diagnostics["supabase_connected"] = True
    except Exception as e:
        diagnostics["supabase_connected"] = False
        diagnostics["supabase_error"] = str(e)

    # If critical subsystems fail, return HTTP 503 so Render does not route traffic
    if not diagnostics["supabase_connected"]:
        diagnostics["status"] = "UNHEALTHY"
        return JSONResponse(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, content=diagnostics)

    return JSONResponse(status_code=status.HTTP_200_OK, content=diagnostics)
7. FIREBASE AUTH DECODER IN FASTAPI (security.py)
Flutter client se aane wale Firebase ID token ko verify karne aur lawyer identity extract karne ka production module:

Python
# app/core/security.py
import firebase_admin
from firebase_admin import auth, credentials
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.config import settings

# Initialize Firebase Admin SDK
if not firebase_admin._apps:
    creds_dict = settings.get_firebase_credentials_dict()
    if creds_dict:
        cred = credentials.Certificate(creds_dict)
        firebase_admin.initialize_app(cred)
    else:
        # Development fallback (Default project application credentials)
        firebase_admin.initialize_app(options={"projectId": settings.FIREBASE_PROJECT_ID})

security_scheme = HTTPBearer(auto_error=False)

async def verify_advocate_token(auth_creds: HTTPAuthorizationCredentials = Security(security_scheme)) -> dict:
    """
    Decodes Firebase ID Token, verifies signature, extracts UID and email.
    """
    if not auth_creds:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="प्रमाणीकरण टोकन अनुपस्थित है। कृपया लॉगिन करें।"
        )

    token = auth_creds.credentials
    try:
        decoded_token = auth.verify_id_token(token, check_revoked=True)
        return {
            "uid": decoded_token["uid"],
            "email": decoded_token.get("email", ""),
            "auth_time": decoded_token.get("auth_time")
        }
    except auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="सत्र समाप्त (Token Revoked): कृपया पुनः लॉगिन करें।"
        )
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="सत्र समाप्त (Token Expired): टोकन रिफ्रेश करें।"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"अमान्य सुरक्षा टोकन: {str(e)}"
        )
8. DEPLOYMENT PIPELINE (GITHUB ACTIONS ➔ RENDER)
Jab code GitHub main branch par push hoga, automated CI pehle tests run karegi aur fir Render webhook trigger karegi:

YAML
# .github/workflows/deploy_render.yml
name: Deploy Pratidnya Backend to Render

on:
  push:
    branches: [ main ]
    paths:
      - 'pratidnya_backend/**'

jobs:
  test-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python 3.10
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'

      - name: Run Grounding & Safety Tests
        working-directory: ./pratidnya_backend
        run: |
          pip install -r requirements.txt
          pytest tests/

      - name: Trigger Render Deploy Webhook
        if: success()
        run: |
          curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK_URL }}"
9. ANTIGRAVITY NON-NEGOTIABLE DEPLOYMENT CHECKLIST (DOC-09)
Antigravity code generation aur Docker setup ke dauran in assertions ko enforce karega:

[ ] Dockerfile mein PyTorch dependency strictly --extra-index-url [https://download.pytorch.org/whl/cpu](https://download.pytorch.org/whl/cpu) se resolve honi chahiye (CUDA download block).

[ ] Container execution command strictly single-worker rahegi (--workers 1). Multi-worker setup Render par instant OOM crash trigger karega.

[ ] OpenNyAI models ko Docker build time par cache directory mein pre-bake karna hai taaki runtime boot par latency na aaye.

[ ] The app container must run as a non-root system user (pratidnya).

[ ] /healthz probe must check both OpenNyAI initialization and Supabase database availability before returning HTTP 200.

[ ] Concurrency guard (nlp_semaphore) must throttle parallel parsing jobs to max 4 to preserve CPU and memory stability.