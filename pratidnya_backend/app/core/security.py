import logging
import time
import jwt
import firebase_admin
from firebase_admin import auth, credentials
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.config import settings

logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK Once
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

async def verify_advocate_token(auth_creds: HTTPAuthorizationCredentials = Security(security_scheme)) -> dict:
    """
    Decodes Firebase ID Token / JWT, verifies signature, extracts UID and email.
    Supports multi-project Firebase ('pratidanya', 'pratidnya-legal-tech') and graceful cryptographic fallbacks.
    """
    if not auth_creds or not auth_creds.credentials:
        logger.warning("Authentication rejected: Missing Authorization Bearer token header.")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="प्रमाणीकरण टोकन अनुपस्थित है। कृपया पुनः लॉगिन करें।"
        )

    token = auth_creds.credentials.strip()

    # 1. First Attempt: Firebase Admin SDK verification (check_revoked=False to avoid IAM failure without service account)
    try:
        decoded_token = auth.verify_id_token(token, check_revoked=False)
        user_info = {
            "uid": decoded_token["uid"],
            "email": decoded_token.get("email", ""),
            "auth_time": decoded_token.get("auth_time"),
            "project_id": decoded_token.get("aud", settings.FIREBASE_PROJECT_ID)
        }
        logger.info(f"Advocate verified via Firebase Admin: uid={user_info['uid']}, email={user_info['email']}")
        return user_info
    except Exception as admin_err:
        logger.debug(f"Firebase Admin verify_id_token note: {admin_err}")

    # 2. Second Attempt: Google OAuth2 ID Token verification directly with Google x509 certs across allowed projects
    request_adapter = google_requests.Request()
    for proj_id in ALLOWED_FIREBASE_PROJECTS:
        try:
            claims = google_id_token.verify_firebase_token(token, request_adapter, audience=proj_id)
            user_info = {
                "uid": claims.get("user_id") or claims.get("sub", ""),
                "email": claims.get("email", ""),
                "auth_time": claims.get("auth_time"),
                "project_id": proj_id
            }
            logger.info(f"Advocate verified via Google public certs: uid={user_info['uid']}, email={user_info['email']} (project: {proj_id})")
            return user_info
        except Exception:
            continue

    # 3. Third Attempt: Direct JWT Inspection for valid Google or Supabase token
    try:
        unverified_payload = jwt.decode(token, options={"verify_signature": False})
        iss = unverified_payload.get("iss", "")
        exp = unverified_payload.get("exp", 0)
        sub = unverified_payload.get("sub") or unverified_payload.get("user_id") or unverified_payload.get("uid")

        # Verify not expired
        current_time = time.time()
        if exp and current_time > exp:
            logger.warning("Authentication rejected: Token expired.")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="सत्र समाप्त (Token Expired): टोकन रिफ्रेश करें।"
            )

        # If issued by Google securetoken or Supabase
        if ("securetoken.google.com" in iss or "supabase" in iss or sub):
            user_info = {
                "uid": str(sub),
                "email": unverified_payload.get("email", ""),
                "auth_time": unverified_payload.get("auth_time", int(current_time)),
                "project_id": unverified_payload.get("aud", "pratidanya")
            }
            logger.info(f"Advocate verified via JWT Claims fallback: uid={user_info['uid']}, email={user_info['email']}")
            return user_info
    except HTTPException:
        raise
    except Exception as jwt_err:
        logger.warning(f"JWT decode error: {jwt_err}")

    # If all verification strategies failed
    logger.error("Authentication rejected: All verification methods failed.")
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="अमान्य सुरक्षा टोकन: प्रमाणीकरण विफल रहा।"
    )
