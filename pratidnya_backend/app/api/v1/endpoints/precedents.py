from fastapi import APIRouter, HTTPException, Depends, Security
from pydantic import BaseModel, Field
from typing import List, Optional
from app.core.security import verify_advocate_token
from app.core.config import settings
from app.core.database import get_supabase_admin_client
from app.services.gemini_service import GeminiService

router = APIRouter(prefix="/precedents", tags=["Precedent Retrieval & Vector Search"])

class PrecedentSearchRequest(BaseModel):
    query_text: str = Field(..., min_length=5, description="Factual issue or defense proposition in Hindi/English")
    target_sections: List[str] = Field(default=[], description="Filter by sections e.g., ['379', '411'] or ['303 BNS']")
    similarity_threshold: float = Field(default=0.65, ge=0.50, le=0.99)
    limit: int = Field(default=5, ge=1, le=10)
    is_dummy_testing: bool = Field(default=True)

class PrecedentSearchResult(BaseModel):
    id: str
    citation_id: str
    case_title: str
    court_name: str
    judgment_date: str
    act_name: str
    section_numbers: List[str]
    headnote_hindi: str
    verbatim_text: str
    paragraph_number: Optional[int]
    verified_source_url: str
    similarity_score: float

@router.post("/search", response_model=List[PrecedentSearchResult])
async def search_precedents_endpoint(
    payload: PrecedentSearchRequest,
    current_user: dict = Security(verify_advocate_token)
):
    # Rule 6 Privacy Assertion
    if not settings.GEMINI_PAID_TIER and not payload.is_dummy_testing:
        raise HTTPException(
            status_code=403,
            detail="गोपनीयता सुरक्षा निषेध: जब तक पेड-टियर सक्रिय न हो, केवल डमी/सिंथेटिक डेटा अनुमत है।"
        )

    # 1. Generate 768-dim query embedding via Gemini
    gemini_service = GeminiService()
    query_vector = await gemini_service.generate_dense_embedding(
        text=payload.query_text,
        task_type="RETRIEVAL_QUERY",
        is_dummy_data=payload.is_dummy_testing
    )

    from app.services.kanoon_service import KanoonService

    # 2. Query Supabase pgvector HNSW RPC
    supabase = get_supabase_admin_client()

    # Auto-detect intent keywords if target_sections is empty
    inferred_sections = list(payload.target_sections)
    lower_q = payload.query_text.lower()
    if not inferred_sections:
        if any(w in lower_q for w in ["muder", "murder", "हत्या", "कत्ल"]):
            inferred_sections = ["302", "103_BNS"]
        elif any(w in lower_q for w in ["theft", "chori", "चोरी"]):
            inferred_sections = ["379", "411", "303_BNS"]
        elif any(w in lower_q for w in ["bail", "जमानत"]):
            inferred_sections = ["437", "439", "480_BNSS", "483_BNSS"]
        elif any(w in lower_q for w in ["ndps", "ganja", "गांजा", "चरस"]):
            inferred_sections = ["50", "20", "21"]
        elif any(w in lower_q for w in ["dowry", "dahej", "दहेज", "498a"]):
            inferred_sections = ["498A", "85_BNS"]
        elif any(w in lower_q for w in ["cheating", "fraud", "420"]):
            inferred_sections = ["420", "318_BNS"]

    rpc_params = {
        "query_embedding": query_vector,
        "target_sections": inferred_sections,
        "similarity_threshold": payload.similarity_threshold,
        "match_count": payload.limit
    }

    try:
        response = supabase.rpc("match_verified_precedents", rpc_params).execute()
        raw_results = response.data or []

        # Adaptive threshold: if strict threshold returned zero and user didn't specify explicit section filter
        if not raw_results and not payload.target_sections and payload.similarity_threshold > 0.50:
            relaxed_params = {
                "query_embedding": query_vector,
                "target_sections": [],
                "similarity_threshold": max(0.48, payload.similarity_threshold - 0.15),
                "match_count": payload.limit
            }
            relaxed_res = supabase.rpc("match_verified_precedents", relaxed_params).execute()
            raw_results = relaxed_res.data or []

        # 3. Rule 1 & Rule 3 Enforcement: Filter verifiable URLs only
        verified_results = []
        for row in raw_results:
            source_url = row.get("verified_source_url", "").strip()
            if source_url and (source_url.startswith("http://") or source_url.startswith("https://")):
                verified_results.append(PrecedentSearchResult(
                    id=str(row["id"]),
                    citation_id=row["citation_id"],
                    case_title=row["case_title"],
                    court_name=row["court_name"],
                    judgment_date=str(row["judgment_date"]),
                    act_name=row["act_name"],
                    section_numbers=row.get("section_numbers", []),
                    headnote_hindi=row["headnote_hindi"],
                    verbatim_text=row["verbatim_text"],
                    paragraph_number=row.get("paragraph_number"),
                    verified_source_url=source_url,
                    similarity_score=round(row["similarity"], 4)
                ))

        # Rule 3: Returns empty list if no certified database matches exist (triggers Abstain widget)
        return verified_results

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"pgvector खोज विफलता: {str(e)}")
