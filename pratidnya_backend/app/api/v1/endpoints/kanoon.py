from fastapi import APIRouter, HTTPException, Query, Security
from typing import List, Dict, Any, Optional
from app.core.security import verify_advocate_token
from app.services.kanoon_service import KanoonService

router = APIRouter(prefix="/kanoon", tags=["Kanoon.dev Court Data Proxy"])

@router.get("/courts", response_model=List[Dict[str, Any]])
async def get_courts(current_user: dict = Security(verify_advocate_token)):
    service = KanoonService()
    return await service.list_courts()

@router.get("/search-cases", response_model=List[Dict[str, Any]])
async def search_court_cases(
    court_id: str = Query(..., description="Court ID e.g., APHC01"),
    query: str = Query(..., min_length=2, description="Search term (FIR, Accused, or Sections)"),
    year: Optional[int] = Query(None, description="Filing year"),
    current_user: dict = Security(verify_advocate_token)
):
    service = KanoonService()
    return await service.search_cases(court_id=court_id, query=query, year=year)

@router.get("/cases/{case_id}/orders", response_model=List[Dict[str, Any]])
async def get_case_orders(
    case_id: str,
    court_id: str = Query(..., description="Court ID e.g., APHC01"),
    current_user: dict = Security(verify_advocate_token)
):
    service = KanoonService()
    return await service.get_case_orders(court_id=court_id, case_id=case_id)
