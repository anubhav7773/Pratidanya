import json
import httpx
from typing import Dict, Any, List
from fastapi import HTTPException
from app.core.config import settings
from app.core.database import get_supabase_admin_client
from app.services.gemini_service import GeminiService
from app.services.grounding_validator import GroundingValidator
from app.services.revision_statutory_gate import RevisionStatutoryGate
from app.schemas.high_court_grounds_schema import (
    GenerateHCGroundsRequest,
    HighCourtGroundItem,
    HighCourtCitedPrecedent,
    HCGroundsResponse
)

class HighCourtGroundsEngine:
    """
    Synthesizes High Court Criminal Appeals (Sec 374 CrPC / 415 BNSS) and
    Criminal Revisions (Sec 397/401 CrPC / 438/442 BNSS) using deep trial
    judgment analysis, statutory gate validation, and pgvector RAG precedents.
    """

    CANDIDATE_MODELS = [
        "gemini-3.6-flash",
        "gemini-3.1-flash-lite",
        "gemini-flash-latest",
        "gemini-3.5-flash",
        "gemini-3.7-flash",
        "gemini-3.8-flash",
    ]

    @classmethod
    async def generate_grounds(cls, req: GenerateHCGroundsRequest, advocate_id: str) -> HCGroundsResponse:
        supabase = get_supabase_admin_client()

        # 1. Fetch Pleading and Trial Analysis Record from Supabase
        pleading_res = supabase.table("high_court_pleadings") \
            .select("*") \
            .eq("id", req.pleading_id) \
            .eq("advocate_id", advocate_id) \
            .maybe_single() \
            .execute()

        if not pleading_res or not pleading_res.data:
            raise HTTPException(status_code=404, detail="उच्च न्यायालय वाद प्रविष्टि (Pleading) नहीं मिली।")

        pleading = pleading_res.data

        analysis_res = supabase.table("trial_court_judgment_analyses") \
            .select("*") \
            .eq("pleading_id", req.pleading_id) \
            .maybe_single() \
            .execute()

        analysis = analysis_res.data if analysis_res else {}

        # 2. Execute Statutory Revision Gate if pleading is CRIMINAL_REVISION
        statutory_warnings = []
        if pleading["pleading_type"] == "CRIMINAL_REVISION":
            is_admissible, warnings = RevisionStatutoryGate.evaluate_revision_admissibility(
                impugned_order_summary=analysis.get("operative_sentence_hindi", ""),
                is_interlocutory_flag=req.is_interlocutory_order,
                seeks_acquittal_conversion=req.seeks_acquittal_conversion
            )
            statutory_warnings.extend(warnings)
            if not is_admissible:
                raise HTTPException(
                    status_code=400,
                    detail="; ".join(warnings)
                )

        # 3. Retrieve Verified High Court / Supreme Court Precedents via pgvector
        gemini_service = GeminiService()
        query_text = (
            f"आपराधिक अपील सजा निलंबन {', '.join(pleading['convicted_sections'])} "
            f"{analysis.get('ocular_vs_medical_conflict', '')} "
            f"{analysis.get('section_313_examination_defects', '')}"
        )

        query_vector = await gemini_service.generate_dense_embedding(
            text=query_text,
            task_type="RETRIEVAL_QUERY",
            is_dummy_data=False
        )

        cleaned_sections = [
            s.replace("धारा", "").replace("IPC", "").replace("CrPC", "").replace("BNS", "").strip()
            for s in pleading["convicted_sections"]
        ]

        rpc_res = supabase.rpc("match_verified_precedents", {
            "query_embedding": query_vector,
            "target_sections": cleaned_sections,
            "similarity_threshold": 0.60,
            "match_count": 4
        }).execute()

        retrieved_precedents = rpc_res.data or []

        # If zero matches at strict threshold, fallback query without target_sections filter
        if not retrieved_precedents:
            fallback_rpc = supabase.rpc("match_verified_precedents", {
                "query_embedding": query_vector,
                "target_sections": [],
                "similarity_threshold": 0.40,
                "match_count": 3
            }).execute()
            retrieved_precedents = fallback_rpc.data or []

        # 4. Generate Structured Appellate/Revisional Grounds via Gemini
        generated_data = await cls._invoke_gemini_grounds_generation(
            pleading=pleading,
            analysis=analysis,
            req=req,
            retrieved_precedents=retrieved_precedents
        )

        # 5. Extract and Validate Citations against Real Corpus (Grounding Gate)
        candidate_citations = []
        for row in retrieved_precedents:
            candidate_citations.append({
                "citation_id": row["citation_id"],
                "case_title": row["case_title"],
                "quoted_passage": row["verbatim_text"],
                "verified_source_url": row.get("verified_source_url", ""),
                "court_name": row["court_name"],
                "judgment_date": str(row["judgment_date"]),
                "relevance_ratio": row.get("headnote_hindi", "")
            })

        verified_citations = GroundingValidator.verify_precedent_citations(
            generated_citations=candidate_citations,
            retrieved_precedents=retrieved_precedents
        )

        # Format Grounds Model
        raw_grounds = generated_data.get("grounds", [])
        if pleading["pleading_type"] == "CRIMINAL_REVISION":
            # Sanitize to prevent pure factual arguments in revision
            cleaned_ground_texts = RevisionStatutoryGate.sanitize_revision_grounds(
                [g.get("ground_text_hindi", "") for g in raw_grounds]
            )
            for idx, g in enumerate(raw_grounds):
                g["ground_text_hindi"] = cleaned_ground_texts[idx]

        structured_grounds = [
            HighCourtGroundItem(
                ground_number=idx + 1,
                ground_heading=g.get("ground_heading", f"विधिक आधार {idx + 1}"),
                ground_text_hindi=g.get("ground_text_hindi", ""),
                statutory_basis=g.get("statutory_basis", pleading["convicted_sections"][0] if pleading["convicted_sections"] else "धारा 374 दं.प्र.सं."),
                legal_doctrine=g.get("legal_doctrine", "Perversity")
            )
            for idx, g in enumerate(raw_grounds)
        ]

        # Format High Court Bench Header Block
        bench_hindi = "लखनऊ खंडपीठ" if pleading.get("high_court_bench") == "LUCKNOW_BENCH" else "इलाहाबाद (प्रधान पीठ)"
        court_title = f"माननीय उच्च न्यायालय, इलाहाबाद, {bench_hindi}"

        statute_appeal = "धारा 374(2) दंड प्रक्रिया संहिता" if req.statute_system == "IPC_CRPC" else "धारा 415(2) भारतीय नागरिक सुरक्षा संहिता"
        statute_revision = "धारा 397 सपठित धारा 401 दंड प्रक्रिया संहिता" if req.statute_system == "IPC_CRPC" else "धारा 438 सपठित धारा 442 भारतीय नागरिक सुरक्षा संहिता"

        memo_title = (
            f"दांडिक अपील अंतर्गत {statute_appeal}"
            if pleading["pleading_type"] == "CRIMINAL_APPEAL"
            else f"दांडिक पुनरीक्षण याचिका अंतर्गत {statute_revision}"
        )

        trial_ref_block = (
            f"विरुद्ध आक्षेपित निर्णय एवं दंडादेश दिनांकित {pleading['trial_judgment_date']}, "
            f"पारित द्वारा {pleading['trial_court_name']}, "
            f"सत्र वाद संख्या: {pleading['trial_case_number']}, "
            f"मु.अ.सं.: {pleading['fir_number']}, थाना: {pleading['police_station']}, जिला: {pleading['district']}"
        )

        return HCGroundsResponse(
            pleading_id=req.pleading_id,
            pleading_type=pleading["pleading_type"],
            high_court_bench=pleading["high_court_bench"],
            court_title_block=court_title,
            memo_title_hindi=memo_title,
            trial_court_reference_block=trial_ref_block,
            grounds=structured_grounds,
            interim_suspension_prayer=generated_data.get("interim_suspension_prayer"),
            final_relief_prayer=generated_data.get("final_relief_prayer", "अतः न्यायहित में अपील स्वीकार की जाए।"),
            cited_precedents=[
                HighCourtCitedPrecedent(
                    citation_id=c["citation_id"],
                    case_title=c["case_title"],
                    court_name=c["court_name"],
                    judgment_date=c["judgment_date"],
                    quoted_passage=c["quoted_passage"],
                    verified_source_url=c["verified_source_url"],
                    is_grounded_in_record=c["is_grounded_in_record"],
                    relevance_ratio=c.get("relevance_ratio", "")
                )
                for c in verified_citations
            ],
            statutory_gate_warnings=statutory_warnings
        )

    @classmethod
    async def _invoke_gemini_grounds_generation(
        cls,
        pleading: Dict[str, Any],
        analysis: Dict[str, Any],
        req: GenerateHCGroundsRequest,
        retrieved_precedents: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        is_appeal = pleading["pleading_type"] == "CRIMINAL_APPEAL"

        system_prompt = (
            "आप भारतीय उच्च न्यायालय (High Court of Judicature at Allahabad) के वरिष्ठ "
            "आपराधिक अधिवक्ता (Appellate & Revisional Counsel) के विधिक प्रारूपक हैं। "
            "भाषा अत्यंत प्रामाणिक, गरिमामयी न्यायालयीन हिंदी (Devanagari) होनी चाहिए। "
            "तथ्यों की सामान्य शिकायत के स्थान पर साक्ष्य की विधिक विकृति (Perversity), "
            "चिकित्सीय अंतर्विरोध, धारा 313 की विधिक खामियों और अधिकारिता दोष पर आधार बनाएं।"
        )

        user_prompt = f"""
        प्रकार: {pleading['pleading_type']}
        विधिक व्यवस्था: {req.statute_system}
        अवर न्यायालय: {pleading['trial_court_name']}
        सत्र वाद संख्या: {pleading['trial_case_number']}
        दोषसिद्धि धाराएं: {', '.join(pleading['convicted_sections'])}
        सुनाया गया दंडादेश: {pleading['quantum_of_sentence']}
        अभियुक्त की अभिरक्षा स्थिति: {pleading['appellant_custody_status']} (जेल में कुल दिन: {pleading['days_in_custody']})
        
        अवर न्यायालय के विश्लेषण के मुख्य बिंदु:
        - दंडादेश अंश: {analysis.get('operative_sentence_hindi', '')}
        - चश्मदीद बनाम मेडिकल अंतर्विरोध: {analysis.get('ocular_vs_medical_conflict', 'कोई नहीं')}
        - धारा 313 दोष: {analysis.get('section_313_examination_defects', 'कोई नहीं')}
        - साक्षियों की गवाही में विधिक त्रुटियां: {json.dumps(analysis.get('prosecution_witness_flaws', []), ensure_ascii=False)}
        - अतिरिक्त बिंदु: {', '.join(req.custom_defense_angles or [])}

        सत्यापित मिसालें:
        {json.dumps([{ 'title': p['case_title'], 'ratio': p['headnote_hindi'] } for p in retrieved_precedents], ensure_ascii=False)}

        कृपया केवल निम्नलिखित JSON संरचना में उत्तर दें:
        {{
          "grounds": [
            {{
              "ground_heading": "साक्ष्य का विकृत मूल्यांकन / चिकित्सीय अंतर्विरोध",
              "ground_text_hindi": "विस्तृत न्यायालयीन आधार (यह कि विद्वान अवर न्यायालय द्वारा पारित आक्षेपित निर्णय साक्ष्य के विकृत मूल्यांकन पर आधारित है...)",
              "statutory_basis": "IPC 307 / CrPC 386",
              "legal_doctrine": "Perverse Appreciation of Evidence"
            }}
          ],
          "interim_suspension_prayer": "धारा 389(1) दं.प्र.सं. / BNSS 430(1) के तहत सजा के क्रियान्वयन को स्थगित करने व अपीलार्थी को अपील के निस्तारण तक जमानत पर रिहा करने की अंतरिम प्रार्थना",
          "final_relief_prayer": "आक्षेपित निर्णय व दंडादेश को निरस्त कर अपीलार्थी को समस्त आरोपों से दोषमुक्त करने की अंतिम प्रार्थना"
        }}
        """

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": settings.GEMINI_API_KEY
        }
        body = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
            "generationConfig": {
                "temperature": 0.15,
                "responseMimeType": "application/json"
            }
        }

        async with httpx.AsyncClient(timeout=45.0) as client:
            last_err = None
            for model_name in cls.CANDIDATE_MODELS:
                url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
                try:
                    response = await client.post(url, headers=headers, json=body)
                    if response.status_code == 200:
                        result = response.json()
                        raw_text = result["candidates"][0]["content"]["parts"][0]["text"]
                        return json.loads(raw_text)
                    elif response.status_code in (404, 503, 429):
                        last_err = f"{model_name} HTTP {response.status_code}: {response.text}"
                        continue
                    else:
                        raise HTTPException(status_code=502, detail=f"Gemini Grounds Synthesis Error: {response.text}")
                except HTTPException:
                    raise
                except Exception as ex:
                    last_err = str(ex)
                    continue

            raise HTTPException(status_code=502, detail=f"Gemini Grounds Synthesis Error: {last_err}")
