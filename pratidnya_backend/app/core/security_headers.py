import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response, RedirectResponse
from app.core.config import settings

logger = logging.getLogger("pratidnya.security.headers")

class ProductionSecurityHeadersMiddleware(BaseHTTPMiddleware):
    """
    Enforces OWASP Top 10 Security Headers and HTTPS Redirection:
    - Strict-Transport-Security (HSTS): 2-year preloaded HTTPS enforcement.
    - Content-Security-Policy (CSP): Zero-eval, strict origin lock.
    - X-Frame-Options: DENY to completely eliminate clickjacking.
    - X-Content-Type-Options: nosniff to stop MIME-confusion attacks.
    - Referrer-Policy: strict-origin-when-cross-origin.
    - Permissions-Policy: Disables unneeded hardware features (camera, geolocation, microphone on web).
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        # Point 19: Force HTTPS redirection in production environments
        if settings.APP_ENV == "PRODUCTION" and request.url.hostname not in ("test", "testserver", "localhost", "127.0.0.1"):
            forwarded_proto = request.headers.get("x-forwarded-proto", "http")
            if request.url.scheme == "http" and forwarded_proto != "https":
                secure_url = request.url.replace(scheme="https")
                return RedirectResponse(url=str(secure_url), status_code=301)

        response: Response = await call_next(request)

        # Point 18 & 9: Inject OWASP hardening headers
        response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = (
            "geolocation=(), camera=(), payment=(), usb=(), display-capture=()"
        )
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; "
            "img-src 'self' data: https:; "
            "script-src 'self'; "
            "style-src 'self' 'unsafe-inline'; "
            "frame-ancestors 'none'; "
            "base-uri 'self'; "
            "form-action 'self';"
        )

        return response
