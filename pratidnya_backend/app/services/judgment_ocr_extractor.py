import io
import pymupdf as fitz  # PyMuPDF with modern import
import base64
import httpx
from typing import List, Tuple
from fastapi import HTTPException
from app.core.config import settings

class JudgmentOcrExtractor:
    """
    Dual-Engine PDF Extractor:
    1. Digital PDFs: Uses PyMuPDF for fast, zero-cost native Devanagari text extraction.
    2. Photostat/Scanned PDFs: Renders PDF pages to 200/300-DPI images and applies Gemini Flash
       multimodal vision OCR specialized for degraded Hindi court orders.
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
    async def extract_text_from_pdf(cls, pdf_bytes: bytes) -> Tuple[str, int]:
        try:
            doc = fitz.open(stream=pdf_bytes, filetype="pdf")
            total_pages = len(doc)
            if total_pages == 0:
                raise HTTPException(status_code=400, detail="प्रस्तुत PDF फ़ाइल खाली है।")

            extracted_pages: List[str] = []
            scanned_pages_to_ocr: List[Tuple[int, bytes]] = []

            for page_idx in range(total_pages):
                page = doc[page_idx]
                page_text = page.get_text("text").strip()

                # Low character density threshold (< 80 chars per page indicates photostat scan)
                if len(page_text) < 80:
                    pix = page.get_pixmap(dpi=200)
                    img_bytes = pix.tobytes("png")
                    scanned_pages_to_ocr.append((page_idx + 1, img_bytes))
                else:
                    extracted_pages.append(f"[पृष्ठ {page_idx + 1}]\n{page_text}")

            # If document has scanned photocopies, execute Multimodal Vision OCR
            if scanned_pages_to_ocr:
                ocr_results = await cls._ocr_scanned_pages(scanned_pages_to_ocr)
                extracted_pages.extend(ocr_results)

            full_extracted_text = "\n\n".join(extracted_pages)
            if len(full_extracted_text.strip()) < 100:
                raise HTTPException(
                    status_code=422,
                    detail="निर्णय की प्रति से सुस्पष्ट पाठ नहीं निकाला जा सका। कृपया उच्च गुणवत्ता की PDF अपलोड करें।"
                )

            return full_extracted_text, total_pages

        except Exception as e:
            if isinstance(e, HTTPException):
                raise e
            raise HTTPException(status_code=500, detail=f"PDF निष्कर्षण विफलता: {str(e)}")

    @classmethod
    async def _ocr_scanned_pages(cls, pages: List[Tuple[int, bytes]]) -> List[str]:
        results = []
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": settings.GEMINI_API_KEY
        }

        # Process max 15 pages in one request batch to prevent timeout
        target_pages = pages[:15]

        async with httpx.AsyncClient(timeout=60.0) as client:
            for page_num, img_bytes in target_pages:
                base64_image = base64.b64encode(img_bytes).decode("utf-8")
                
                payload = {
                    "contents": [{
                        "parts": [
                            {
                                "text": (
                                    "आप भारतीय न्यायालयीन अभिलेखों के लिए विशेष OCR सहायक हैं। "
                                    "इस न्यायालयीन निर्णय/आदेश के पृष्ठ से समस्त हिंदी (देवनागरी) पाठ को "
                                    "अक्षरशः (verbatim) निकालें। कानूनी शब्दों, तारीखों, धाराओं (IPC/CrPC/BNS) "
                                    "और साक्षियों के बयानों को बिना किसी फेरबदल के शुद्ध रूप में प्रस्तुत करें।"
                                )
                            },
                            {
                                "inlineData": {
                                    "mimeType": "image/png",
                                    "data": base64_image
                                }
                            }
                        ]
                    }],
                    "generationConfig": {
                        "temperature": 0.0,
                        "maxOutputTokens": 2048
                    }
                }

                page_extracted = False
                for model_name in cls.CANDIDATE_MODELS:
                    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
                    try:
                        response = await client.post(url, headers=headers, json=payload)
                        if response.status_code == 200:
                            resp_json = response.json()
                            page_ocr = resp_json["candidates"][0]["content"]["parts"][0]["text"]
                            results.append(f"[पृष्ठ {page_num} (OCR)]\n{page_ocr}")
                            page_extracted = True
                            break
                        elif response.status_code in (404, 503, 429):
                            continue
                    except Exception:
                        continue

                if not page_extracted:
                    results.append(f"[पृष्ठ {page_num} (OCR विफल)]")

        return results
