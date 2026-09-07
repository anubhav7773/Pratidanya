import logging
from typing import Dict, Any, Optional
import jwt
from fastapi import Header, HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import auth as firebase_auth, credentials
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
from app.core.config import settings

logger = logging.getLogger("pratidnya.security")

# Initialize Firebase Admin app if credentials or project ID are configured
if not firebase_admin._apps:
    creds_dict = settings.get_firebase_credentials_dict()
    if creds_dict:
        try:
            cred = credentials.Certificate(creds_dict)
            firebase_admin.initialize_app(cred)
        except Exception:
            try:
                firebase_admin.initialize_app(options={"projectId": settings.FIREBASE_PROJECT_ID})
            except Exception:
                pass
    else:
        try:
            firebase_admin.initialize_app(options={"projectId": settings.FIREBASE_PROJECT_ID})
        except Exception:
            pass

security_scheme = HTTPBearer(auto_error=False)
ALLOWED_FIREBASE_PROJECTS = ["pratidanya", "pratidnya-legal-tech", settings.FIREBASE_PROJECT_ID]

async def verify_advocate_token(
    auth_creds: Optional[HTTPAuthorizationCredentials] = Security(security_scheme),
    authorization: Optional[str] = Header(None, alias="Authorization")
) -> Dict[str, Any]:
    """
    Validates caller JWT cryptographically without bypasses.
    Fixes SEC-01: Removed unsigned JWT decoding (verify_signature=False).
    Supports:
    1. Firebase ID Tokens (signed by Google x509 certs).
    2. Supabase Auth Tokens (signed with SUPABASE_JWT_SECRET).
    """
    token = None
    if auth_creds and auth_creds.credentials:
        token = auth_creds.credentials.strip()
    elif authorization and authorization.startswith("Bearer "):
        token = authorization.split("Bearer ")[1].strip()

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="प्रमाणीकरण विफल: बियरर टोकन अनिवार्य है।",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 1. Primary Route: Verify via Firebase Admin SDK
    try:
        decoded_firebase = firebase_auth.verify_id_token(token, check_revoked=False)
        return {
            "uid": decoded_firebase["uid"],
            "email": decoded_firebase.get("email", ""),
            "provider": "firebase",
            "claims": decoded_firebase,
        }
    except Exception as fb_err:
        logger.debug(f"Firebase token verification failed: {fb_err}. Attempting Google x509 certs...")

    # 1b. Direct Google OAuth2 ID Token verification via Google public x509 certs
    request_adapter = google_requests.Request()
    for proj_id in ALLOWED_FIREBASE_PROJECTS:
        try:
            claims = google_id_token.verify_firebase_token(token, request_adapter, audience=proj_id)
            return {
                "uid": claims.get("user_id") or claims.get("sub", ""),
                "email": claims.get("email", ""),
                "provider": "firebase_google",
                "claims": claims,
            }
        except Exception:
            continue

    # 2. Secondary Route: Verify via Supabase JWT Secret (if configured)
    if hasattr(settings, "SUPABASE_JWT_SECRET") and settings.SUPABASE_JWT_SECRET:
        try:
            decoded_supabase = jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                options={"verify_signature": True, "verify_exp": True},
            )
            sub = decoded_supabase.get("sub")
            if not sub:
                raise ValueError("Supabase token lacks 'sub' claim.")

            return {
                "uid": sub,
                "email": decoded_supabase.get("email", ""),
                "provider": "supabase",
                "claims": decoded_supabase,
            }
        except Exception as sb_err:
            logger.debug(f"Supabase token verification failed: {sb_err}")

    # No unsigned fallbacks permitted (SEC-01)
    logger.error("Authentication rejected: Token failed cryptographic signature verification.")
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="प्रमाणीकरण विफल: अमान्य अथवा अनधिकृत टोकन।",
        headers={"WWW-Authenticate": "Bearer"},
    )

async def verify_advocate_token_optional(
    auth_creds: Optional[HTTPAuthorizationCredentials] = Security(security_scheme),
    authorization: Optional[str] = Header(None, alias="Authorization")
) -> Optional[Dict[str, Any]]:
    """
    Returns verified user info dictionary if a valid Authorization header is provided,
    or None if credentials are missing or unparseable, without raising 401.
    """
    token = None
    if auth_creds and auth_creds.credentials:
        token = auth_creds.credentials.strip()
    elif authorization and authorization.startswith("Bearer "):
        token = authorization.split("Bearer ")[1].strip()

    if not token:
        return None

    try:
        return await verify_advocate_token(auth_creds=auth_creds, authorization=authorization)
    except Exception:
        return None
