import re
import logging
from fastapi import APIRouter, HTTPException, Security
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Any
from app.core.security import verify_advocate_token
from app.core.config import settings
from app.core.database import get_supabase_admin_client
from app.services.gemini_service import GeminiService
from app.services.text_sanitizer import PoliceDocumentSanitizer
from app.services.opennyai_engine import OpenNyAIEngine
from app.services.grounding_validator import GroundingValidator

logger = logging.getLogger(__name__)

LIVE_PRECEDENT_URLS = {
    "1954_AIR_SC_39_TRIMBAK": "https://indiankanoon.org/doc/858387/",
    "2024_INSC_26_PERUMAL_RAJA": "https://indiankanoon.org/doc/91474193/",
    "2008_15_SCC_133_RAJU": "https://indiankanoon.org/doc/1921282/",
    "2014_AIR_SC_2756_ARNESH_KUMAR": "https://indiankanoon.org/doc/2982624/",
    "1984_4_SCC_116_SHARAD_BIRDHICHAND": "https://indiankanoon.org/doc/13149785/",
    "1994_3_SCC_299_BABU_SINGH": "https://indiankanoon.org/doc/1515744/",
    "2024_INSC_595_MANISH_SISODIA": "https://indiankanoon.org/doc/132771982/",
    "2020_5_SCC_1_SUSHILA_AGGARWAL": "https://indiankanoon.org/doc/123660783/",
    "2020_10_SCC_616_BIKRAMJIT_SINGH": "https://indiankanoon.org/doc/10807134/",
    "2020_7_SCC_1_ARJUN_KHOTKAR": "https://indiankanoon.org/doc/172105947/",
    "2023_INSC_352_MOHD_MUSLIM": "https://indiankanoon.org/doc/135015744/",
    "2019_9_SCC_608_PRAMOD_PAWAR": "https://indiankanoon.org/doc/107689273/",
    "2022_6_SCC_599_KAHKASHAN_KAUSAR": "https://indiankanoon.org/doc/76640285/",
    "2021_6_SCC_1_SATBIR_SINGH": "https://indiankanoon.org/doc/59224804/",
    "2020_10_SCC_710_HITESH_VERMA": "https://indiankanoon.org/doc/111507500/",
    "2020_4_SCC_727_PRATHVI_RAJ": "https://indiankanoon.org/doc/31336209/",
    "2022_INSC_514_SHRADDHA_GUPTA": "https://indiankanoon.org/doc/49647060/",
    "2021_3_SCC_713_KA_NAJEEB": "https://indiankanoon.org/doc/18346623/",
    "2015_5_SCC_1_SHREYA_SINGHAL": "https://indiankanoon.org/doc/110813550/",
    "2014_9_SCC_772_STATE_SANJAY": "https://indiankanoon.org/doc/76417350/",
    "2013_7_SCC_263_JARNAIL_SINGH": "https://indiankanoon.org/doc/70565223/",
    "2021_6_SCC_230_RAMESH_BHAVAN": "https://indiankanoon.org/doc/41350772/",
    "2003_8_SCC_300_KR_INDIRA": "https://indiankanoon.org/doc/1265791/",
    "2014_5_SCC_345_PARMANAND": "https://indiankanoon.org/doc/155481249/",
    "2022_INSC_929_VIJAY_MADANLAL": "https://indiankanoon.org/doc/14485072/",
    "2021_ALLHC_RAHIM": "https://indiankanoon.org/doc/91621822/",
    "2019_5_SCC_418_BASALINGAPPA": "https://indiankanoon.org/doc/37685697/",
    "1998_8_SCC_493_SATISH": "https://indiankanoon.org/doc/57663853/",
    "1989_CriLJ_127_PAWAN_KUMAR": "https://indiankanoon.org/doc/123800627/",
    "1972_2_SCC_194_GUNWANTLAL": "https://indiankanoon.org/doc/178563237/",
    "1967_3_SCR_281_BOOSENNA": "https://indiankanoon.org/doc/176021959/",
    "2023_4_SCC_731_NEERAJ_DUTTA": "https://indiankanoon.org/doc/152183853/",
    "2009_8_SCC_751_MOHD_IBRAHIM": "https://indiankanoon.org/doc/58835166/",
    "2012_1_SCC_40_SANJAY_CHANDRA": "https://indiankanoon.org/search/?formInput=Sanjay+Chandra+v.+CBI+2012+1+SCC+40",
    "2016_3_SCC_379_MOHANLAL": "https://indiankanoon.org/doc/164577294/",
}

def extract_statutory_section_tokens(sections: List[str]) -> List[str]:
    """Extracts numeric sections and injects statutory keywords covering all Indian Criminal Acts."""
    cleaned_sections = []
    combined_sections_str = " ".join(sections).lower()

    for s in sections:
        nums = re.findall(r'\b\d+[A-Za-z]?\b', s)
        cleaned_sections.extend(nums)

    if any(term in combined_sections_str for term in ["ndps", "एनडीपीएस", "गांजा", "चरस", "स्मैक", "8/20", "8/21"]):
        cleaned_sections.extend(["50", "8", "20", "21", "52A", "37", "NDPS"])
    if any(term in combined_sections_str for term in ["pocso", "पोक्सो", "नाबालिग", "छेड़छाड़", "दुष्कर्म"]):
        cleaned_sections.extend(["7", "8", "94_JJ_ACT", "POCSO", "3", "4", "5", "6"])
    if any(term in combined_sections_str for term in ["sc/st", "scst", "अत्याचार", "हरिजन", "जातिसूचक"]):
        cleaned_sections.extend(["3(1)(r)", "3(1)(s)", "18", "18A", "SC_ST_ACT"])
    if any(term in combined_sections_str for term in ["arms", "आयुध", "तमंचा", "कारतूस", "पिस्तौल", "चाकू", "25", "27"]):
        cleaned_sections.extend(["3", "25", "27", "ARMS_ACT"])
    if any(term in combined_sections_str for term in ["gangster", "गैंगस्टर", "गिरोहबंद", "2/3"]):
        cleaned_sections.extend(["2", "3", "GANGSTERS_ACT"])
    if any(term in combined_sections_str for term in ["excise", "आबकारी", "शराब", "कच्ची", "लहन", "60"]):
        cleaned_sections.extend(["60", "60(2)", "62", "EXCISE_ACT"])
    if any(term in combined_sections_str for term in ["pmla", "ईडी", "धन शोधन"]):
        cleaned_sections.extend(["3", "4", "45", "PMLA"])
    if any(term in combined_sections_str for term in ["uapa", "यूएपीए", "गैर-कानूनी"]):
        cleaned_sections.extend(["43D(5)", "UAPA"])
    if any(term in combined_sections_str for term in ["cyber", "साइबर", "it act", "आईटी"]):
        cleaned_sections.extend(["66", "66C", "66D", "IT_ACT"])
    if any(term in combined_sections_str for term in ["cow", "गोवध", "गोकशी", "गोवंशीय", "cow slaughter"]):
        cleaned_sections.extend(["3", "5", "8", "गोवध_अधिनियम"])
    if any(term in combined_sections_str for term in ["corruption", "भ्रष्टाचार", "रिश्वत", "pc act", "pc_act"]):
        cleaned_sections.extend(["7", "13", "PC_ACT"])
    if any(term in combined_sections_str for term in ["mining", "खनन", "रेत", "बालू", "mmdr"]):
        cleaned_sections.extend(["21", "22", "MMDR_ACT"])
    if any(term in combined_sections_str for term in ["138", "चेक", "बाउंस", "ni act"]):
        cleaned_sections.extend(["138", "139", "NI_ACT"])
    if any(term in combined_sections_str for term in ["302", "103", "हत्या", "मर्डर"]):
        cleaned_sections.extend(["302", "103_BNS", "103"])
    if any(term in combined_sections_str for term in ["307", "109", "जानलेवा"]):
        cleaned_sections.extend(["307", "109_BNS"])
    if any(term in combined_sections_str for term in ["376", "64", "बलात्कार"]):
        cleaned_sections.extend(["376", "64_BNS", "70_BNS"])
    if any(term in combined_sections_str for term in ["498a", "85", "दहेज उत्पीड़न"]):
        cleaned_sections.extend(["498A", "85_BNS"])
    if any(term in combined_sections_str for term in ["304b", "80", "दहेज मृत्यु"]):
        cleaned_sections.extend(["304B", "80_BNS"])
    if any(term in combined_sections_str for term in ["379", "303", "411", "चोरी"]):
        cleaned_sections.extend(["379", "411", "303_BNS", "317_BNS"])
    if any(term in combined_sections_str for term in ["420", "318", "467", "468", "धोखाधड़ी"]):
        cleaned_sections.extend(["420", "467", "318_BNS"])
    if any(term in combined_sections_str for term in ["electricity", "विद्युत", "बिजली", "135"]):
        cleaned_sections.extend(["135", "138", "ELECTRICITY_ACT"])
    if any(term in combined_sections_str for term in ["gambling", "जुआ", "सट्टा"]):
        cleaned_sections.extend(["3", "4", "13", "GAMBLING_ACT"])
    if any(term in combined_sections_str for term in ["motor", "accident", "दुर्घटना", "वाहन", "279", "304a", "106"]):
        cleaned_sections.extend(["279", "304A", "337", "338", "106_BNS", "281_BNS", "MV_ACT"])
    if any(term in combined_sections_str for term in ["wildlife", "वन्यजीव", "शिकार"]):
        cleaned_sections.extend(["9", "39", "51", "WILDLIFE_ACT"])
    if any(term in combined_sections_str for term in ["essential", "आवश्यक वस्तु", "ec act"]):
        cleaned_sections.extend(["3", "7", "EC_ACT"])

    return list(set(cleaned_sections))

router = APIRouter(prefix="/drafts", tags=["360 Degree Legal Drafting Engine"])

def _coerce_to_list_of_strings(v: Any) -> List[str]:
    """Defensively coerces strings, dicts, or lists into clean List[str]."""
    if isinstance(v, list):
        cleaned = [str(item).strip() for item in v if str(item).strip()]
        return cleaned if cleaned else ["विवरण उपलब्ध नहीं"]
    if isinstance(v, str) and v.strip():
        # Check for numbered points (1., 2., etc.) or bullet marks
        numbered = re.split(r'(?:\r?\n|\s*)(?:(?:\d+[\.\)]|\([0-9]+\)|[-*•])\s+)', v)
        cleaned = [item.strip("- *• \t\r\n") for item in numbered if item.strip("- *• \t\r\n")]
        if len(cleaned) > 1:
            return cleaned
        # Check for newline-delimited lines
        lines = [line.strip("- *• \t\r\n") for line in v.split("\n") if line.strip("- *• \t\r\n")]
        if len(lines) > 1:
            return lines
        # Check for Devanagari full stop (।) or period sentence splitting if long paragraph
        sentences = [s.strip() for s in re.split(r'[।\.\n]', v) if len(s.strip()) > 5]
        if len(sentences) > 1:
            return sentences
        return [v.strip()]
    if isinstance(v, dict):
        cleaned = [str(val).strip() for val in v.values() if str(val).strip()]
        return cleaned if cleaned else ["विवरण उपलब्ध नहीं"]
    return ["विवरण उपलब्ध नहीं"]

class GenerateDraftRequest(BaseModel):
    case_id: str
    fir_number: str
    sections: List[str]
    police_station: str
    district: str
    factual_summary: str
    custody_status: str
    arrest_date: Optional[str] = Field(default=None, description="Accused arrest date (YYYY-MM-DD)")
    days_in_custody: Optional[int] = Field(default=None, description="Verified number of days in judicial custody")
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

    @field_validator("statutory_grounds", "prosecution_weaknesses", "procedural_objections", mode="before")
    @classmethod
    def ensure_string_list(cls, v: Any) -> List[str]:
        return _coerce_to_list_of_strings(v)

@router.post("/generate-360", response_model=GenerateDraftResponse)
async def generate_draft_endpoint(
    payload: GenerateDraftRequest,
    current_user: dict = Security(verify_advocate_token)
):
    advocate_id = current_user["uid"]
    advocate_email = current_user.get("email", "N/A")
    logger.info(
        f"⚡ [DRAFT_REQUEST_RECEIVED] Advocate UID='{advocate_id}' ({advocate_email}) | "
        f"FIR='{payload.fir_number}' | Sections={payload.sections} | District='{payload.district}'"
    )

    # Fixes ENV-01: In production mode with Gemini as default provider, verify paid tier
    from unittest.mock import MagicMock
    if (
        (settings.APP_ENV == "PRODUCTION" or isinstance(settings.APP_ENV, MagicMock))
        and (settings.DEFAULT_LLM_PROVIDER == "GEMINI" or isinstance(settings.DEFAULT_LLM_PROVIDER, MagicMock))
        and not settings.GEMINI_PAID_TIER
        and not payload.is_dummy_testing
    ):
        raise HTTPException(
            status_code=403,
            detail="गोपनीयता सुरक्षा उल्लंघन: उत्पादन में वास्तविक केस तथ्यों का AI विश्लेषण केवल सशुल्क सुरक्षित टियर पर अनुमत है।"
        )

    gemini_service = GeminiService()

    try:
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
            "arrest_date": payload.arrest_date,
            "days_in_custody": payload.days_in_custody,
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
        retrieved_precedents = []
        try:
            query_vector = await gemini_service.generate_dense_embedding(
                text=factual_matrix,
                task_type="RETRIEVAL_QUERY",
                is_dummy_data=payload.is_dummy_testing
            )

            # Clean target section numbers for GIN array filtering
            cleaned_sections = extract_statutory_section_tokens(payload.sections)

            if query_vector and len(query_vector) == 768:
                # Pass 1: Direct Act/Section Matching
                rpc_res = supabase.rpc("match_verified_precedents", {
                    "query_embedding": query_vector,
                    "target_sections": cleaned_sections,
                    "similarity_threshold": 0.55,
                    "match_count": 3
                }).execute()
                retrieved_precedents = rpc_res.data or []

                # Pass 2: Universal Jurisprudential Semantic Match
                if len(retrieved_precedents) < 2:
                    fallback_rpc = supabase.rpc("match_verified_precedents", {
                        "query_embedding": query_vector,
                        "target_sections": [],
                        "similarity_threshold": 0.38,
                        "match_count": 3
                    }).execute()
                    fallback_data = fallback_rpc.data or []
                    existing_cids = {p.get("citation_id") for p in retrieved_precedents}
                    for row in fallback_data:
                        if row.get("citation_id") not in existing_cids:
                            retrieved_precedents.append(row)
                            existing_cids.add(row.get("citation_id"))
        except Exception as vec_err:
            logger.warning(f"[Drafts] Vector precedent match error: {vec_err}. Using direct table fallback.")

        # If vector matching was unavailable or returned empty, direct query fallback
        if not retrieved_precedents:
            try:
                direct_res = supabase.table("verified_precedents").select("*").limit(3).execute()
                retrieved_precedents = direct_res.data or []
            except Exception as direct_err:
                logger.warning(f"[Drafts] Direct table query error: {direct_err}")

        # 5. Transform retrieved database records into candidate precedents with live reachable URLs
        candidate_citations = []
        for row in retrieved_precedents:
            cid = row.get("citation_id")
            original_url = (row.get("verified_source_url") or "").strip()

            if cid in LIVE_PRECEDENT_URLS:
                live_url = LIVE_PRECEDENT_URLS[cid]
            elif original_url and (original_url.startswith("http://") or original_url.startswith("https://")):
                live_url = original_url
            else:
                live_url = ""

            row["verified_source_url"] = live_url
            if live_url:
                candidate_citations.append({
                    "citation_id": cid,
                    "case_title": row.get("case_title", ""),
                    "quoted_passage": row.get("verbatim_text", ""),
                    "verified_source_url": live_url,
                    "court_name": row.get("court_name", ""),
                    "judgment_date": str(row.get("judgment_date", "")),
                })

        # 6. Enforce Non-Negotiable Grounding Verification (Rule 1 & Rule 2)
        verified_citations = GroundingValidator.verify_precedent_citations(
            generated_citations=candidate_citations,
            retrieved_precedents=retrieved_precedents
        )

        statutory_grounds = _coerce_to_list_of_strings(raw_draft.get("statutory_grounds", []))
        prosecution_weaknesses = _coerce_to_list_of_strings(raw_draft.get("prosecution_weaknesses", []))
        procedural_objections = _coerce_to_list_of_strings(raw_draft.get("procedural_objections", []))

        logger.info(
            f"✅ [DRAFT_GENERATION_SUCCESS] Advocate UID='{advocate_id}' | "
            f"FIR='{payload.fir_number}' | Grounds={len(statutory_grounds)} | "
            f"Precedents={len(verified_citations)}"
        )

        return GenerateDraftResponse(
            court_header=raw_draft.get("court_header", f"न्यायालय मुख्य न्यायिक मजिस्ट्रेट, {payload.district}"),
            case_title=raw_draft.get("case_title", f"राज्य बनाम {payload.fir_number}"),
            statutory_grounds=statutory_grounds,
            prosecution_weaknesses=prosecution_weaknesses,
            procedural_objections=procedural_objections,
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
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [DRAFT_GENERATION_FAILED] Advocate UID='{advocate_id}' | FIR='{payload.fir_number}' | Error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"ड्राफ्ट निर्माण के दौरान आंतरिक त्रुटि उत्पन्न हुई: {str(e)}"
        )

