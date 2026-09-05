import firebase_admin
from firebase_admin import auth, credentials
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.config import settings

# Initialize Firebase Admin SDK Once
if not firebase_admin._apps:
    creds_dict = settings.get_firebase_credentials_dict()
    if creds_dict:
        cred = credentials.Certificate(creds_dict)
        firebase_admin.initialize_app(cred)
    else:
        try:
            firebase_admin.initialize_app(options={"projectId": settings.FIREBASE_PROJECT_ID})
        except Exception:
            pass

security_scheme = HTTPBearer(auto_error=False)

async def verify_advocate_token(auth_creds: HTTPAuthorizationCredentials = Security(security_scheme)) -> dict:
    """
    Decodes Firebase ID Token, verifies signature, extracts UID and email.
    """
    if not auth_creds:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="प्रमाणीकरण टोकन अनुपस्थित है। कृपया पुनः लॉगिन करें।"
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
