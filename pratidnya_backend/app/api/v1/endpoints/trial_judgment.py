import re
from datetime import datetime, timezone
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Security
from app.core.security import verify_advocate_token
from app.core.concurrency import acquire_nlp_slot, release_nlp_slot
from app.core.database import get_supabase_admin_client
from app.services.judgment_ocr_extractor import JudgmentOcrExtractor
from app.services.high_court_judgment_parser import HighCourtJudgmentParser
from app.schemas.trial_judgment_schema import TrialJudgmentAnalysisResponse

router = APIRouter(prefix="/high-court", tags=["High Court Trial Judgment NLP Engine"])

@router.post("/parse-trial-judgment", response_model=TrialJudgmentAnalysisResponse)
async def parse_trial_judgment_endpoint(
    file: UploadFile = File(..., description="Scanned or Digital PDF of Trial Court Conviction Judgment"),
    pleading_type: str = Form("CRIMINAL_APPEAL", description="'CRIMINAL_APPEAL' or 'CRIMINAL_REVISION'"),
    current_user: dict = Security(verify_advocate_token)
):
    """
    Ingests Trial Court Judgment PDF, executes dual-mode OCR (PyMuPDF / Gemini Vision),
    extracts sentencing metadata, witness conflicts, Section 313 omissions, and persists
    the structural docket in Supabase.
    """
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="केवल PDF प्रारूप मान्य है।")

    advocate_id = current_user["uid"]

    await acquire_nlp_slot()
    try:
        pdf_bytes = await file.read()
        if len(pdf_bytes) > 25 * 1024 * 1024:
            raise HTTPException(status_code=413, detail="फ़ाइल का आकार 25MB से कम होना अनिवार्य है।")

        # 1. Dual-Mode OCR Extraction
        extracted_text, total_pages = await JudgmentOcrExtractor.extract_text_from_pdf(pdf_bytes)

        # 2. Deconstruct Judgment via Gemini Legal Parser
        analysis = await HighCourtJudgmentParser.analyze_trial_judgment(
            raw_text=extracted_text,
            total_pages=total_pages,
            pleading_type=pleading_type
        )

        # 3. Persist Pleading & Analysis in Supabase
        supabase = get_supabase_admin_client()

        # Sanitize ISO date format for PostgreSQL date columns
        date_pattern = r'^\d{4}-\d{2}-\d{2}$'
        valid_date = analysis.metadata.judgment_date if re.match(date_pattern, str(analysis.metadata.judgment_date)) else datetime.now(timezone.utc).date().isoformat()

        # Insert Master Pleading Row
        pleading_record = {
            "advocate_id": advocate_id,
            "pleading_type": pleading_type,
            "high_court_bench": "LUCKNOW_BENCH",
            "trial_court_name": analysis.metadata.court_name,
            "trial_case_number": analysis.metadata.case_number,
            "trial_judgment_date": valid_date,
            "trial_presiding_judge": analysis.metadata.presiding_judge,
            "convicted_sections": analysis.metadata.convicted_sections,
            "quantum_of_sentence": analysis.metadata.quantum_of_sentence,
            "case_title": f"{', '.join(analysis.metadata.accused_names)} बनाम उत्तर प्रदेश राज्य",
            "accused_names": analysis.metadata.accused_names,
            "police_station": analysis.metadata.police_station,
            "district": analysis.metadata.district,
            "fir_number": analysis.metadata.fir_number,
            "limitation_expiry_date": valid_date, # Updated in Goal 14
        }
        pleading_res = supabase.table("high_court_pleadings").insert(pleading_record).execute()
        new_pleading_id = pleading_res.data[0]["id"]
        analysis.pleading_id = new_pleading_id

        # Insert Trial Analysis Details
        witness_flaws_data = [w.model_dump() if hasattr(w, "model_dump") else w.dict() for w in analysis.witness_flaws]
        procedural_omissions_data = [p.model_dump() if hasattr(p, "model_dump") else p.dict() for p in analysis.procedural_omissions]

        analysis_record = {
            "pleading_id": new_pleading_id,
            "advocate_id": advocate_id,
            "operative_sentence_hindi": analysis.operative_sentence_hindi,
            "prosecution_witness_flaws": witness_flaws_data,
            "procedural_omissions": procedural_omissions_data,
            "section_313_examination_defects": analysis.section_313_examination_defects,
            "ocular_vs_medical_conflict": analysis.ocular_vs_medical_conflict,
            "malkhana_link_evidence_defects": analysis.malkhana_link_evidence_defects,
            "raw_judgment_word_count": analysis.raw_word_count
        }
        supabase.table("trial_court_judgment_analyses").insert(analysis_record).execute()

        return analysis

    finally:
        release_nlp_slot()
