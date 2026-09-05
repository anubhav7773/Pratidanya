from fastapi import APIRouter, HTTPException, Security
from pydantic import BaseModel, Field
from typing import List, Optional
from app.core.security import verify_advocate_token
from app.core.config import settings
from app.core.database import get_supabase_admin_client
from app.services.gemini_service import GeminiService
from app.services.text_sanitizer import PoliceDocumentSanitizer
from app.services.opennyai_engine import OpenNyAIEngine
from app.services.grounding_validator import GroundingValidator

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
    raw_chargesheet_text: Optional[str] = Field(default=None, description="Optional raw police FIR/Chargesheet")
    is_dummy_testing: bool = Field(default=False)

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

    # 1. Clean & sanitize factual narrative using Devanagari normalizer
    sanitized_summary = PoliceDocumentSanitizer.clean_and_normalize(payload.factual_summary)
    
    extracted_facts: List[str] = []
    if payload.extracted_facts:
        extracted_facts.extend(payload.extracted_facts)

    # If raw chargesheet was provided, pass through OpenNyAI for sentence extraction
    if payload.raw_chargesheet_text and len(payload.raw_chargesheet_text) >= 50:
        cleaned_chargesheet = PoliceDocumentSanitizer.clean_and_normalize(payload.raw_chargesheet_text)
        nlp_engine = OpenNyAIEngine.get_instance()
        nlp_result = nlp_engine.process_chargesheet(cleaned_chargesheet)
        extracted_facts.extend(nlp_result.get("facts_extracts", []))

    # 2. Construct synthesized factual matrix for prompt grounding
    factual_matrix = sanitized_summary
    if extracted_facts:
        factual_matrix += "\nपुलिस आरोप-पत्र से निष्कर्षित प्रामाणिक तथ्य:\n" + "\n".join(f"- {f}" for f in extracted_facts)

    facts_payload = {
        "fir_number": payload.fir_number,
        "sections": payload.sections,
        "police_station": payload.police_station,
        "district": payload.district,
        "custody_status": payload.custody_status,
        "factual_summary": factual_matrix
    }

    # 3. Call Live Gemini 1.5 Flash (Paid Tier Grounding)
    raw_draft = await gemini_service.generate_structured_case_analysis(
        advocate_id=advocate_id,
        facts_payload=facts_payload,
        is_dummy_data=payload.is_dummy_testing
    )

    # 4. Semantic Precedent Retrieval from Real pgvector Corpus (Goal 8)
    supabase = get_supabase_admin_client()
    query_vector = await gemini_service.generate_dense_embedding(
        text=factual_matrix,
        task_type="RETRIEVAL_QUERY",
        is_dummy_data=payload.is_dummy_testing
    )

    # Clean target section numbers for GIN array filtering
    cleaned_sections = [
        s.replace("धारा", "").replace("भा.दं.वि.", "").replace("IPC", "").replace("BNS", "").replace("CrPC", "").strip() 
        for s in payload.sections
    ]
    # Keep only alphanumeric tokens
    import re
    cleaned_sections = [re.sub(r'[^0-9A-Za-z_]', '', cs) for cs in cleaned_sections if cs]

    rpc_res = supabase.rpc("match_verified_precedents", {
        "query_embedding": query_vector,
        "target_sections": cleaned_sections,
        "similarity_threshold": 0.65,
        "match_count": 3
    }).execute()

    retrieved_precedents = rpc_res.data or []
    if not retrieved_precedents:
        # Fallback to 0.50 threshold for concise Devanagari factual matrices
        rpc_res = supabase.rpc("match_verified_precedents", {
            "query_embedding": query_vector,
            "target_sections": cleaned_sections,
            "similarity_threshold": 0.50,
            "match_count": 3
        }).execute()
        retrieved_precedents = rpc_res.data or []

    # 5. Transform retrieved database records into candidate precedents
    candidate_citations = []
    for row in retrieved_precedents:
        candidate_citations.append({
            "citation_id": row["citation_id"],
            "case_title": row["case_title"],
            "quoted_passage": row["verbatim_text"],
            "verified_source_url": row.get("verified_source_url", ""),
            "court_name": row["court_name"],
            "judgment_date": str(row["judgment_date"]),
        })

    # 6. Enforce Non-Negotiable Grounding Verification (Rule 1 & Rule 2)
    verified_citations = GroundingValidator.verify_precedent_citations(
        generated_citations=candidate_citations,
        retrieved_precedents=retrieved_precedents
    )

    return GenerateDraftResponse(
        court_header=raw_draft.get("court_header", f"न्यायालय मुख्य न्यायिक मजिस्ट्रेट, {payload.district}"),
        case_title=raw_draft.get("case_title", f"राज्य बनाम {payload.fir_number}"),
        statutory_grounds=raw_draft.get("statutory_grounds", []),
        prosecution_weaknesses=raw_draft.get("prosecution_weaknesses", []),
        procedural_objections=raw_draft.get("procedural_objections", []),
        cited_precedents=[
            CitedPrecedentItem(
                citation_id=c["citation_id"],
                case_title=c["case_title"],
                court_name=c.get("court_name", "उच्चतम न्यायालय"),
                judgment_date=c.get("judgment_date", "2026"),
                quoted_passage=c.get("quoted_passage", ""),
                verified_source_url=c["verified_source_url"],
                is_grounded_in_record=c.get("is_grounded_in_record", True)
            ) for c in verified_citations
        ]
    )
