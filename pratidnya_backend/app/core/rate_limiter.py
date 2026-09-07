from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request, Response
from fastapi.responses import JSONResponse

# Rate limiter keyed by IP or verified advocate UID
def get_rate_limit_key(request: Request) -> str:
    # Use authenticated user UID if present, otherwise fallback to remote IP
    auth_header = request.headers.get("authorization", "")
    if auth_header.startswith("Bearer "):
        token_hash = hash(auth_header)
        return f"auth_{token_hash}"
    return get_remote_address(request)

limiter = Limiter(key_func=get_rate_limit_key, default_limits=["120/minute"])

def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> Response:
    """Returns an authenticated error response upon rate-limit violation."""
    return JSONResponse(
        status_code=429,
        content={
            "detail": "अनुरोध सीमा समाप्त (429 Rate Limit Exceeded): अत्यधिक अनुरोध अस्वीकृत। कृपया थोड़ी देर बाद पुनः प्रयास करें।",
            "statutory_guard": "Anti-Bot & DoS Protection Gate"
        }
    )
