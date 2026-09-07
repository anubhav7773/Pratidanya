import io
import fitz  # PyMuPDF
import base64
import httpx
from typing import List, Tuple
from fastapi import HTTPException
from app.core.config import settings

class JudgmentOcrExtractor:
    """
    Dual-Engine PDF Extractor:
    1. Digital PDFs: Uses PyMuPDF with strict context management (Fixes OCR-02 memory leak).
    2. Photostat/Scanned PDFs: Head + Tail Smart Sampling prioritizing FIR charges (first 5 pages)
       and Operative Conviction/Sentencing (last 10 pages) (Fixes OCR-01 truncation).
    """

    CANDIDATE_MODELS = [
        "gemini-2.5-flash",
        "gemini-2.0-flash",
        "gemini-1.5-flash",
        "gemini-flash-latest"
    ]

    @classmethod
    async def extract_text_from_pdf(cls, pdf_bytes: bytes) -> Tuple[str, int]:
        if not pdf_bytes or len(pdf_bytes) == 0:
            raise HTTPException(status_code=400, detail="प्रस्तुत PDF फ़ाइल खाली है।")

        try:
            # Fixes OCR-02: Strict context manager prevents unclosed C++ document handle leaks
            with fitz.open(stream=pdf_bytes, filetype="pdf") as doc:
                total_pages = len(doc)
                if total_pages == 0:
                    raise HTTPException(status_code=400, detail="PDF में कोई पृष्ठ नहीं मिला।")

                extracted_pages: List[str] = []
                scanned_pages_to_ocr: List[Tuple[int, bytes]] = []

                for page_idx in range(total_pages):
                    page = doc[page_idx]
                    page_text = page.get_text("text").strip()

                    # Low character density (< 80 chars per page indicates photostat scan)
                    if len(page_text) < 80:
                        pix = page.get_pixmap(dpi=200)
                        img_bytes = pix.tobytes("png")
                        scanned_pages_to_ocr.append((page_idx + 1, img_bytes))
                    else:
                        extracted_pages.append(f"[पृष्ठ {page_idx + 1}]\n{page_text}")

                # If document contains scanned photocopies, execute Smart-Sampled Vision OCR
                if scanned_pages_to_ocr:
                    # Fixes OCR-01: Head + Tail Smart Sampling (First 5 pages + Last 10 pages)
                    sampled_pages = cls._smart_sample_pages(scanned_pages_to_ocr, max_budget=15)
                    ocr_results = await cls._ocr_scanned_pages(sampled_pages)
                    extracted_pages.extend(ocr_results)

                full_extracted_text = "\n\n".join(extracted_pages)
                if len(full_extracted_text.strip()) < 80:
                    raise HTTPException(
                        status_code=422,
                        detail="निर्णय की प्रति से सुस्पष्ट पाठ नहीं निकाला जा सका। कृपया स्पष्ट PDF अपलोड करें।"
                    )

                return full_extracted_text, total_pages

        except Exception as e:
            if isinstance(e, HTTPException):
                raise e
            raise HTTPException(status_code=500, detail=f"PDF निष्कर्षण विफलता: {str(e)}")

    @classmethod
    def _smart_sample_pages(cls, pages: List[Tuple[int, bytes]], max_budget: int = 15) -> List[Tuple[int, bytes]]:
        """
        Fixes OCR-01: Eliminates blind head-truncation (pages[:15]).
        In Indian trial court judgments, charges are in first 5 pages and conviction/sentence
        orders are in the final pages.
        """
        total = len(pages)
        if total <= max_budget:
            return pages

        # Head 5 pages (FIR, Charges, Prosecution Case)
        head = pages[:5]
        # Tail 10 pages (313 examination, analysis, operative sentence & conviction)
        tail = pages[-10:]

        # Combine uniquely preserving order
        seen_numbers = set()
        sampled = []
        for p in (head + tail):
            if p[0] not in seen_numbers:
                seen_numbers.add(p[0])
                sampled.append(p)

        sampled.sort(key=lambda x: x[0])
        return sampled

    @classmethod
    async def _ocr_scanned_pages(cls, pages: List[Tuple[int, bytes]]) -> List[str]:
        results = []
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": settings.GEMINI_API_KEY
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            for page_num, img_bytes in pages:
                base64_image = base64.b64encode(img_bytes).decode("utf-8")
                payload = {
                    "contents": [{
                        "parts": [
                            {
                                "text": (
                                    "भारतीय न्यायालयीन निर्णय के इस पृष्ठ से समस्त हिंदी (देवनागरी) पाठ को "
                                    "अक्षरशः निकालें। विशेषकर धाराओं, गवाहों के बयानों और दंडादेश को शुद्ध रूप में प्रस्तुत करें।"
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
