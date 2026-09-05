from fastapi import APIRouter, HTTPException, Security
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from app.core.security import verify_advocate_token
from app.services.gemini_service import GeminiService
from app.services.grounding_validator import GroundingValidator
from app.core.database import get_supabase_admin_client

router = APIRouter(prefix="/drafts", tags=["360 Degree Legal Drafting Engine"])

class GenerateDraftRequest(BaseModel):
    case_id: str
    fir_number: str
    sections: List[str]
    police_station: str
    district: str
    factual_summary: str
    custody_status: str
    extracted_facts: Optional[List[str]] = Field(default=[])
    is_dummy_testing: bool = Field(default=True)

class CitedPrecedentItem(BaseModel):
    citation_id: str
    case_title: str
    court_name: str
    judgment_date: str
    quoted_passage: str
    verified_source_url: str
    is_grounded_in_record: bool

class GenerateDraftResponse(BaseModel):
    court_header: str
    case_title: str
    statutory_grounds: List[str]
    prosecution_weaknesses: List[str]
    procedural_objections: List[str]
    cited_precedents: List[CitedPrecedentItem]

@router.post("/generate-360", response_model=GenerateDraftResponse)
async def generate_draft_endpoint(
    payload: GenerateDraftRequest,
    current_user: dict = Security(verify_advocate_token)
):
    advocate_id = current_user["uid"]
    gemini_service = GeminiService()

    # Combine facts for prompt
    facts_narrative = payload.factual_summary
    if payload.extracted_facts:
        facts_narrative += "\nनिष्कर्षित तथ्य:\n" + "\n".join(f"- {f}" for f in payload.extracted_facts)

    facts_payload = {
        "fir_number": payload.fir_number,
        "sections": payload.sections,
        "police_station": payload.police_station,
        "district": payload.district,
        "custody_status": payload.custody_status,
        "factual_summary": facts_narrative
    }

    # Generate JSON structure via Gemini 1.5 Flash (Paid Tier / Dummy Track)
    raw_draft = await gemini_service.generate_structured_case_analysis(
        advocate_id=advocate_id,
        facts_payload=facts_payload,
        is_dummy_data=payload.is_dummy_testing
    )

    # Fetch verified precedents from pgvector for these sections
    supabase = get_supabase_admin_client()
    query_vector = await gemini_service.generate_dense_embedding(
        text=facts_narrative,
        task_type="RETRIEVAL_QUERY",
        is_dummy_data=payload.is_dummy_testing
    )

    rpc_res = supabase.rpc("match_verified_precedents", {
        "query_embedding": query_vector,
        "target_sections": payload.sections,
        "similarity_threshold": 0.65,
        "match_count": 3
    }).execute()

    retrieved_precedents = rpc_res.data or []

    # Map precedents into candidate format
    candidate_citations = []
    for row in retrieved_precedents:
        candidate_citations.append({
            "citation_id": row["citation_id"],
            "case_title": row["case_title"],
            "quoted_passage": row["verbatim_text"],
            "verified_source_url": row.get("verified_source_url"),
            "court_name": row["court_name"],
            "judgment_date": str(row["judgment_date"]),
        })

    # Execute Grounding Validator (Rule 1 & Rule 2 Enforcement)
    verified_citations = GroundingValidator.verify_precedent_citations(
        generated_citations=candidate_citations,
        retrieved_precedents=retrieved_precedents
    )

    return GenerateDraftResponse(
        court_header=raw_draft.get("court_header", "न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ"),
        case_title=raw_draft.get("case_title", f"राज्य बनाम {payload.fir_number}"),
        statutory_grounds=raw_draft.get("statutory_grounds", []),
        prosecution_weaknesses=raw_draft.get("prosecution_weaknesses", []),
        procedural_objections=raw_draft.get("procedural_objections", []),
        cited_precedents=[
            CitedPrecedentItem(
                citation_id=c["citation_id"],
                case_title=c["case_title"],
                court_name=c.get("court_name", "उच्च न्यायालय"),
                judgment_date=c.get("judgment_date", "2026"),
                quoted_passage=c.get("quoted_passage", ""),
                verified_source_url=c["verified_source_url"],
                is_grounded_in_record=c.get("is_grounded_in_record", True)
            ) for c in verified_citations
        ]
    )
