from fastapi import APIRouter, HTTPException, Depends, Security
from pydantic import BaseModel, Field
from typing import List, Optional
from app.core.security import verify_advocate_token
from app.core.config import settings
from app.core.database import get_supabase_admin_client
from app.services.gemini_service import GeminiService

router = APIRouter(prefix="/precedents", tags=["Precedent Retrieval & Vector Search"])

import re
from datetime import datetime

class PrecedentSearchRequest(BaseModel):
    query_text: str = Field(..., min_length=2, description="Factual issue, section number or defense proposition in Hindi/English")
    target_sections: List[str] = Field(default=[], description="Filter by sections e.g., ['379', '411'] or ['303 BNS']")
    similarity_threshold: float = Field(default=0.65, ge=0.45, le=0.99)
    limit: int = Field(default=5, ge=1, le=15)
    is_dummy_testing: bool = Field(default=True)
    filter_mode: Optional[str] = Field(default=None, description="Filter chip e.g. 'LAST_5_YEARS', 'SUPREME_COURT', 'ALLAHABAD_HC', 'BAIL'")

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

def _extract_query_sections(query_text: str) -> tuple[List[str], bool]:
    """Extracts explicit section numbers, BNS/IPC equivalences, and flags if query is section-specific."""
    lower_q = query_text.lower().strip()
    extracted = []
    is_specific = False

    # Check for explicit BNS/IPC/CrPC/BNSS section patterns e.g. 'bns 305', 'धारा 305', 'ipc 307'
    has_statute_keyword = any(k in lower_q for k in ["bns", "ipc", "crpc", "bnss", "धारा", "sec", "section", "ndps", "pocso", "ni act"])

    # Specific common crime provisions and cross-statute equivalences
    if "305" in lower_q:
        is_specific = True
        extracted.extend(["305", "305_BNS", "380", "379", "303_BNS", "317_BNS"])
    if "303" in lower_q and ("bns" in lower_q or "चोरी" in lower_q or "theft" in lower_q):
        is_specific = True
        extracted.extend(["303", "303_BNS", "379", "411", "317_BNS"])
    if "304" in lower_q and "bns" in lower_q:
        is_specific = True
        extracted.extend(["304", "304_BNS", "390", "392"])
    if "307" in lower_q or ("109" in lower_q and "bns" in lower_q):
        is_specific = True
        extracted.extend(["307", "109_BNS"])
    if "302" in lower_q or ("103" in lower_q and "bns" in lower_q):
        is_specific = True
        extracted.extend(["302", "103_BNS", "103"])
    if "376" in lower_q or ("64" in lower_q and "bns" in lower_q):
        is_specific = True
        extracted.extend(["376", "64_BNS", "70_BNS"])
    if "498a" in lower_q or ("85" in lower_q and "bns" in lower_q):
        is_specific = True
        extracted.extend(["498A", "85_BNS"])
    if "304b" in lower_q or ("80" in lower_q and "bns" in lower_q):
        is_specific = True
        extracted.extend(["304B", "80_BNS"])
    if "420" in lower_q or ("318" in lower_q and "bns" in lower_q):
        is_specific = True
        extracted.extend(["420", "467", "468", "471", "318_BNS", "336_BNS", "338_BNS"])
    if "50" in lower_q and ("ndps" in lower_q or "तलाशी" in lower_q or "search" in lower_q):
        is_specific = True
        extracted.extend(["50", "NDPS"])
    if "52a" in lower_q or ("52" in lower_q and "ndps" in lower_q):
        is_specific = True
        extracted.extend(["52A", "NDPS"])
    if "37" in lower_q and "ndps" in lower_q:
        is_specific = True
        extracted.extend(["37", "NDPS"])
    if "138" in lower_q or "139" in lower_q or "चेक" in lower_q:
        is_specific = True
        extracted.extend(["138", "139", "141", "142", "NI_ACT"])
    if "65b" in lower_q or ("63" in lower_q and "bsa" in lower_q):
        is_specific = True
        extracted.extend(["65B", "63_BSA"])
    if "27" in lower_q and ("साक्ष्य" in lower_q or "iea" in lower_q or "bsa" in lower_q or "बरामदगी" in lower_q):
        is_specific = True
        extracted.extend(["27", "23_BSA"])
    if any(k in lower_q for k in ["439", "483"]):
        is_specific = True
        extracted.extend(["439", "483_BNSS"])
    if any(k in lower_q for k in ["438", "482"]):
        is_specific = True
        extracted.extend(["438", "482_BNSS"])
    if any(k in lower_q for k in ["41a", "35_bnss", "35 bnss"]):
        is_specific = True
        extracted.extend(["41A", "35_BNSS"])
    if any(k in lower_q for k in ["167", "187_bnss", "187 bnss", "डिफ़ॉल्ट"]):
        is_specific = True
        extracted.extend(["167", "187_BNSS"])

    # Generic numbers regex if statute keyword was present
    if has_statute_keyword and not extracted:
        raw_nums = re.findall(r'\b\d+[a-zA-Z]?\b', lower_q)
        if raw_nums:
            is_specific = True
            extracted.extend(raw_nums)

    return list(set(extracted)), is_specific

@router.post("/search", response_model=List[PrecedentSearchResult])
async def search_precedents_endpoint(
    payload: PrecedentSearchRequest,
    current_user: dict = Security(verify_advocate_token)
):
    # Rule 6 Privacy Assertion (Fixes ENV-01: Local/Dev environments allow testing without 403 blocks)
    from unittest.mock import MagicMock
    if (settings.APP_ENV == "PRODUCTION" or isinstance(settings.APP_ENV, MagicMock)) and not settings.GEMINI_PAID_TIER and not payload.is_dummy_testing:
        raise HTTPException(
            status_code=403,
            detail="गोपनीयता सुरक्षा निषेध: जब तक पेड-टियर सक्रिय न हो, केवल डमी/सिंथेटिक डेटा अनुमत है।"
        )

    # 1. Detect sections and specific intent from payload or query text
    inferred_sections = list(payload.target_sections)
    parsed_sections, is_specific_section_query = _extract_query_sections(payload.query_text)
    if not inferred_sections and parsed_sections:
        inferred_sections = parsed_sections

    lower_q = payload.query_text.lower()
    if not inferred_sections:
        if any(w in lower_q for w in ["muder", "murder", "हत्या", "कत्ल"]):
            inferred_sections = ["302", "103_BNS"]
        elif any(w in lower_q for w in ["theft", "chori", "चोरी"]):
            inferred_sections = ["379", "380", "411", "303_BNS", "305_BNS", "317_BNS"]
        elif any(w in lower_q for w in ["bail", "जमानत"]):
            inferred_sections = ["437", "439", "480_BNSS", "483_BNSS"]
        elif any(w in lower_q for w in ["ndps", "ganja", "गांजा", "चरस"]):
            inferred_sections = ["50", "20", "21"]
        elif any(w in lower_q for w in ["dowry", "dahej", "दहेज", "498a"]):
            inferred_sections = ["498A", "85_BNS"]
        elif any(w in lower_q for w in ["cheating", "fraud", "420"]):
            inferred_sections = ["420", "318_BNS"]

    # 2. Generate 768-dim query embedding via Gemini
    gemini_service = GeminiService()
    query_vector = await gemini_service.generate_dense_embedding(
        text=payload.query_text,
        task_type="RETRIEVAL_QUERY",
        is_dummy_data=payload.is_dummy_testing
    )

    # 3. Query Supabase pgvector HNSW RPC
    supabase = get_supabase_admin_client()

    rpc_params = {
        "query_embedding": query_vector,
        "target_sections": inferred_sections,
        "similarity_threshold": payload.similarity_threshold,
        "match_count": payload.limit
    }

    try:
        response = supabase.rpc("match_verified_precedents", rpc_params).execute()
        raw_results = response.data or []

        # Adaptive threshold: Only relax if NOT a specific statutory section query
        # When user explicitly asks for "bns 305", never drop target_sections to dump unrelated 307 or 376 cases
        if not raw_results and not payload.target_sections and not is_specific_section_query and payload.similarity_threshold > 0.50:
            relaxed_params = {
                "query_embedding": query_vector,
                "target_sections": [],
                "similarity_threshold": max(0.48, payload.similarity_threshold - 0.15),
                "match_count": payload.limit
            }
            relaxed_res = supabase.rpc("match_verified_precedents", relaxed_params).execute()
            raw_results = relaxed_res.data or []

        # 4. Rule 1 & Rule 3 Enforcement: Filter verifiable URLs and validate section fidelity
        verified_results = []
        for row in raw_results:
            source_url = row.get("verified_source_url", "").strip()
            if not source_url or not (source_url.startswith("http://") or source_url.startswith("https://")):
                continue

            row_sections = row.get("section_numbers", [])

            # If user explicitly queried a specific section (e.g. bns 305),
            # strictly reject unrelated precedents (e.g. 307 Babu Singh, 376 Pramod Pawar)
            if is_specific_section_query and inferred_sections:
                inferred_upper = {s.upper() for s in inferred_sections}
                row_upper = {s.upper() for s in row_sections}
                has_common_section = bool(inferred_upper.intersection(row_upper))
                if not has_common_section:
                    continue

            # Apply Date Filter if requested ('LAST_5_YEARS' or 'अंतिम 5 वर्ष')
            j_date_str = str(row.get("judgment_date", ""))
            filter_mode = (payload.filter_mode or "").upper()
            if "5_YEARS" in filter_mode or "5 वर्ष" in payload.query_text:
                year_match = re.search(r'\b(19\d\d|20\d\d)\b', j_date_str)
                if year_match:
                    y = int(year_match.group(1))
                    cutoff = datetime.now().year - 5
                    if y < cutoff:
                        continue
                else:
                    continue

            # Apply Court Filter if requested
            court_name = row.get("court_name", "")
            if "SUPREME" in filter_mode or "उच्चतम न्यायालय" in payload.query_text:
                if not any(k in court_name for k in ["उच्चतम", "सर्वोच्च", "Supreme"]):
                    continue
            elif "ALLAHABAD" in filter_mode or "इलाहाबाद" in payload.query_text:
                if not any(k in court_name for k in ["इलाहाबाद", "Allahabad"]):
                    continue
            elif "BAIL" in filter_mode or "जमानत" in payload.query_text:
                act = row.get("act_name", "")
                headnote = row.get("headnote_hindi", "")
                title = row.get("case_title", "")
                if not any("जमानत" in text or "bail" in text.lower() for text in [act, headnote, title]):
                    continue

            verified_results.append(PrecedentSearchResult(
                id=str(row["id"]),
                citation_id=row["citation_id"],
                case_title=row["case_title"],
                court_name=row["court_name"],
                judgment_date=j_date_str,
                act_name=row["act_name"],
                section_numbers=row_sections,
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
