from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from app.core.config import settings
from app.core.security_headers import ProductionSecurityHeadersMiddleware
from app.core.sanitized_logger import configure_production_logging
from app.core.rate_limiter import limiter, rate_limit_exceeded_handler
from app.services.opennyai_engine import OpenNyAIEngine
from app.api.v1.endpoints import (
    health,
    precedents,
    kanoon,
    drafts,
    billing,
    trial_judgment,
    high_court_grounds,
    high_court_interlocutory,
    specialized_acts,
    scst_ni_acts,
    voice,
    dpdp_compliance,
    activity,
    ecourts,
    nlp
)

# Initialize production logging scrubber (Points 1, 11, 15)
configure_production_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Server Startup: Load OpenNyAI into RAM
    engine = OpenNyAIEngine.get_instance()
    engine.initialize()
    yield
    # Server Shutdown: Flush and cleanup memory
    engine.cleanup()

app = FastAPI(
    title="Pratidnya Legal Tech API",
    description="360° Hardened Production API for Indian Criminal Defense",
    version="2.2.0",
    lifespan=lifespan
)

# Attach SlowAPI Limiter state (Points 6, 11, 12)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

# 1. Register OWASP Production Security Headers & HTTPS Middleware (Points 9, 18, 19)
app.add_middleware(ProductionSecurityHeadersMiddleware)

# 2. Strict CORS Configuration (Points 6, 12, 18)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
    max_age=600,
)

# Register Endpoints
app.include_router(health.router)
app.include_router(health.router, prefix="/api/v1")
app.include_router(nlp.router, prefix="/api/v1")
app.include_router(precedents.router, prefix="/api/v1")
app.include_router(kanoon.router, prefix="/api/v1")
app.include_router(drafts.router, prefix="/api/v1")
app.include_router(billing.router, prefix="/api/v1")
app.include_router(trial_judgment.router, prefix="/api/v1")
app.include_router(high_court_grounds.router, prefix="/api/v1")
app.include_router(high_court_interlocutory.router, prefix="/api/v1")
app.include_router(specialized_acts.router, prefix="/api/v1")
app.include_router(scst_ni_acts.router, prefix="/api/v1")
app.include_router(voice.router, prefix="/api/v1")
app.include_router(dpdp_compliance.router, prefix="/api/v1")
app.include_router(activity.router, prefix="/api/v1")
app.include_router(ecourts.router, prefix="/api/v1")
