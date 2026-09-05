from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.core.database import get_supabase_admin_client
from app.services.opennyai_engine import OpenNyAIEngine

import time
from datetime import datetime, timezone

router = APIRouter()

@router.get("/health", tags=["System Diagnostics"])
@router.head("/health", tags=["System Diagnostics"])
async def uptime_robot_keep_alive():
    """
    Lightweight health check probe for UptimeRobot, BetterUptime, Cron, and keep-alive monitors.
    Returns HTTP 200 immediately without database queries or quota consumption.
    Prevents Render free tier from going to sleep.
    """
    return {
        "status": "HEALTHY",
        "alive": True,
        "service": "pratidnya-backend",
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "unix_time": int(time.time())
    }

@router.get("/ping", tags=["System Diagnostics"])
async def ping():
    """Ultra-low latency ping-pong endpoint for uptime pingers."""
    return {"ping": "pong", "status": "ok"}

@router.get("/healthz", tags=["System Diagnostics"])
async def health_check_probe():
    """
    Health check probe for Render orchestrator and uptime monitors.
    Validates configuration, OpenNyAI pipeline availability, and Supabase connectivity.
    """
    diagnostics = {
        "status": "HEALTHY",
        "app_env": settings.APP_ENV,
        "paid_tier_active": settings.GEMINI_PAID_TIER,
        "dummy_data_enforced": settings.ENFORCE_DUMMY_DATA,
        "opennyai_loaded": False,
        "supabase_connected": False,
    }

    try:
        engine = OpenNyAIEngine.get_instance()
        diagnostics["opennyai_loaded"] = engine._pipeline is not None
    except Exception:
        diagnostics["opennyai_loaded"] = False

    try:
        client = get_supabase_admin_client()
        client.table("verified_precedents").select("id").limit(1).execute()
        diagnostics["supabase_connected"] = True
    except Exception as e:
        diagnostics["supabase_connected"] = False
        diagnostics["supabase_error"] = str(e)

    if not diagnostics["supabase_connected"]:
        diagnostics["status"] = "UNHEALTHY"
        return JSONResponse(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, content=diagnostics)

    return JSONResponse(status_code=status.HTTP_200_OK, content=diagnostics)
