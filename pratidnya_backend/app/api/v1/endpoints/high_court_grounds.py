from fastapi import APIRouter, HTTPException, Security
from app.core.security import verify_advocate_token
from app.schemas.high_court_grounds_schema import GenerateHCGroundsRequest, HCGroundsResponse
from app.services.high_court_grounds_engine import HighCourtGroundsEngine

router = APIRouter(prefix="/high-court", tags=["High Court Grounds Synthesis Engine"])

@router.post("/generate-grounds", response_model=HCGroundsResponse)
async def generate_high_court_grounds_endpoint(
    payload: GenerateHCGroundsRequest,
    current_user: dict = Security(verify_advocate_token)
):
    """
    Synthesizes High Court Grounds of Criminal Appeal (Sec 374 CrPC / 415 BNSS)
    or Criminal Revision (Sec 397 CrPC / 438 BNSS).
    Validates interlocutory bars, retrieves pgvector verified precedents, and
    generates grounded prayers for interim bail under Sec 389 CrPC.
    """
    advocate_id = current_user["uid"]
    return await HighCourtGroundsEngine.generate_grounds(
        req=payload,
        advocate_id=advocate_id
    )
