from fastapi import APIRouter, status, Response, Request
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.core.database import get_supabase_admin_client
from app.services.opennyai_engine import OpenNyAIEngine

import time
from datetime import datetime, timezone

router = APIRouter()

@router.head("/", tags=["System Diagnostics"], status_code=status.HTTP_200_OK)
@router.get("/", tags=["System Diagnostics"], status_code=status.HTTP_200_OK)
async def root_keep_alive(request: Request):
    """Root URL keep-alive for UptimeRobot (supports HEAD & GET)."""
    headers = {
        "X-Service": "pratidnya-backend",
        "X-Status": "healthy",
        "Cache-Control": "no-cache, no-store, must-revalidate"
    }
    if request.method == "HEAD":
        return Response(status_code=status.HTTP_200_OK, headers=headers)
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"status": "HEALTHY", "service": "pratidnya-backend", "alive": True},
        headers=headers
    )

@router.head("/health", tags=["System Diagnostics"], status_code=status.HTTP_200_OK)
async def uptime_robot_head_probe():
    """
    Dedicated HTTP HEAD endpoint for UptimeRobot.
    Returns 200 OK instantly with zero payload body to preserve bandwidth and eliminate latency.
    Keeps Render backend running 24/7 without sleeping.
    """
    return Response(
        status_code=status.HTTP_200_OK,
        headers={
            "X-Service": "pratidnya-backend",
            "X-Status": "healthy",
            "X-Uptime-Monitor": "active",
            "Cache-Control": "no-cache, no-store, must-revalidate"
        }
    )

@router.get("/health", tags=["System Diagnostics"], status_code=status.HTTP_200_OK)
async def uptime_robot_get_probe():
    """Lightweight GET health check probe for uptime monitors."""
    return {
        "status": "HEALTHY",
        "alive": True,
        "service": "pratidnya-backend",
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "unix_time": int(time.time())
    }

@router.head("/ping", tags=["System Diagnostics"], status_code=status.HTTP_200_OK)
@router.get("/ping", tags=["System Diagnostics"], status_code=status.HTTP_200_OK)
async def ping(request: Request):
    """Ultra-low latency ping-pong endpoint for uptime monitors (supports HEAD & GET)."""
    if request.method == "HEAD":
        return Response(status_code=status.HTTP_200_OK)
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
