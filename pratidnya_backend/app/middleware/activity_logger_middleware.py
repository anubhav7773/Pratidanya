import time
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.logging_config import render_logger

class ActivityLoggerMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.perf_counter()

        # Extract tracing headers passed from Flutter ChamberHttpClient
        advocate_id = request.headers.get("X-Advocate-ID", "GUEST_OR_ANONYMOUS")
        action_name = request.headers.get("X-Action-Name", "DIRECT_HTTP_CALL")
        session_id = request.headers.get("X-Session-ID", "NO_SESSION")
        client_lang = request.headers.get("X-Client-Language", "hi")
        path = request.url.path
        method = request.method

        response = await call_next(request)

        duration_ms = round((time.perf_counter() - start_time) * 1000.0, 2)
        status_code = response.status_code

        # High-visibility log line for Render Console
        status_icon = "🟢 200 OK" if status_code < 400 else f"🔴 {status_code} ERROR"
        render_logger.info(
            f"| {status_icon} | LATENCY: {duration_ms}ms | ADVOCATE: {advocate_id} "
            f"| ACTION: {action_name} | {method} {path} | SESSION: {session_id} | LANG: {client_lang}"
        )

        response.headers["X-Server-Processing-Time-Ms"] = str(duration_ms)
        return response
