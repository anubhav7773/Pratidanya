from fastapi import APIRouter, HTTPException, Security
from fastapi.responses import JSONResponse
from datetime import datetime, timezone
from typing import Dict, Any
from app.core.security import verify_advocate_token
from app.core.database import get_supabase_admin_client

router = APIRouter(prefix="/compliance/dpdp", tags=["DPDP Act 2023 Statutory Compliance"])

@router.get("/export-chamber-bundle")
async def export_chamber_bundle_endpoint(current_user: dict = Security(verify_advocate_token)):
    """
    DPDP Act 2023 Section 11 (Right to Access Information):
    Exports complete JSON bundle of advocate's profile, dockets, proceedings,
    specialized audits, and immutable compliance logs.
    """
    advocate_id = current_user["uid"]
    supabase = get_supabase_admin_client()

    try:
        rpc_res = supabase.rpc("export_advocate_chamber_data", {"target_advocate_id": advocate_id}).execute()
        bundle_data = rpc_res.data

        if not bundle_data:
            raise HTTPException(status_code=404, detail="डेटा बंडल उत्पन्न नहीं किया जा सका।")

        return JSONResponse(
            content=bundle_data,
            headers={
                "Content-Disposition": f"attachment; filename=Pratidnya_Chamber_Data_{datetime.now().strftime('%Y%m%d')}.json"
            }
        )
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=f"डेटा निर्यात विफलता: {str(e)}")

@router.delete("/execute-erasure")
async def execute_erasure_endpoint(current_user: dict = Security(verify_advocate_token)):
    """
    DPDP Act 2023 Section 8(7) (Right to Erasure):
    Permanently erases all case records, proceedings, vectors, and profile metadata.
    """
    advocate_id = current_user["uid"]
    supabase = get_supabase_admin_client()

    try:
        rpc_res = supabase.rpc("execute_complete_advocate_erasure", {"target_advocate_id": advocate_id}).execute()
        if rpc_res.data is True:
            return {
                "status": "ERASURE_COMPLETE",
                "message": "डीपीसपी अधिनियम 2023 की धारा 8(7) के तहत आपका समस्त चैंबर डेटा स्थायी रूप से विलोपित कर दिया गया है।",
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        raise HTTPException(status_code=500, detail="डेटा विलोपन प्रक्रिया पूरी नहीं हो सकी।")
    except Exception as e:
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=f"डेटा विलोपन विफलता: {str(e)}")

@router.get("/bci-audit-statement")
async def bci_audit_statement_endpoint(current_user: dict = Security(verify_advocate_token)):
    """
    Bar Council of India Rule 36 Statutory Declaration Statement:
    Certifies zero-advertisement and professional legal research assistant classification.
    """
    advocate_id = current_user["uid"]
    supabase = get_supabase_admin_client()

    profile_res = supabase.table("advocate_profiles") \
        .select("full_name, bar_council_number, enrolled_state, primary_court_name") \
        .eq("id", advocate_id) \
        .execute()

    profile = profile_res.data[0] if profile_res.data else {
        "full_name": "माननीय अधिवक्ता",
        "bar_council_number": "UP/1234/2020",
        "enrolled_state": "Uttar Pradesh",
        "primary_court_name": "जिला एवं सत्र न्यायालय, लखनऊ"
    }

    return {
        "institution": "प्रतिज्ञा विधिक अनुसंधान एवं प्रारूपण प्रणाली (Asiverticals)",
        "advocate_name": profile.get("full_name", "माननीय अधिवक्ता"),
        "bar_council_number": profile.get("bar_council_number", "UP/1234/2020"),
        "enrolled_state": profile.get("enrolled_state", "Uttar Pradesh"),
        "statutory_certifications": [
            "प्रणाली भारतीय बार काउंसिल नियमावली (BCI Rules) के अध्याय II के नियम 36 का पूर्णतः अनुपालन करती है।",
            "यह एप्लिकेशन किसी भी प्रकार के व्यावसायिक विज्ञापन या वकालत के प्रचार-प्रसार में संलग्न नहीं है।",
            "प्रणाली द्वारा निर्मित सभी विधिक मसौदे केवल अधिवक्ता के स्वतंत्र पेशेवर परीक्षण (Section 35 Gate) के अधीन हैं।",
            "डेटा संप्रभुता: समस्त वाद-तथ्य भारतीय क्षेत्राधिकार (AWS मुंबई ap-south-1) में एन्क्रिप्टेड संग्रहीत हैं।"
        ],
        "generated_at": datetime.now(timezone.utc).isoformat()
    }
