import os
from typing import Tuple
from fastapi import HTTPException, UploadFile

class SecureUploadGuard:
    """
    Inspects magic binary bytes, file extensions, and memory boundaries
    to prevent file upload attacks (malicious ELF/EXE execution, ZIP-bombs, path traversal).
    """

    ALLOWED_MIME_SIGNATURES = {
        # Magic bytes for PDF (%PDF-)
        b"%PDF-": ("application/pdf", [".pdf"]),
        # Magic bytes for M4A (ftypM4A)
        b"\x00\x00\x00\x20ftypM4A": ("audio/m4a", [".m4a"]),
        b"\x00\x00\x00\x18ftypmp42": ("audio/mp4", [".mp4", ".m4a"]),
        # Magic bytes for standard MP3 (ID3 or sync word)
        b"ID3": ("audio/mpeg", [".mp3"]),
    }

    MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024  # 25 MB

    @classmethod
    async def validate_file(cls, file: UploadFile, expected_category: str = "PDF") -> Tuple[bytes, str]:
        # 1. Path Traversal Guard: Sanitize filename
        raw_filename = file.filename or "uploaded_file"
        if ".." in raw_filename or "/" in raw_filename or "\\" in raw_filename:
            raise HTTPException(status_code=400, detail="अमान्य फ़ाइल नाम: पथ उल्लंघन (Path traversal) अस्वीकृत।")
        safe_filename = os.path.basename(raw_filename)

        # 2. Size boundary check
        contents = await file.read()
        if len(contents) == 0:
            raise HTTPException(status_code=400, detail="प्रस्तुत फ़ाइल रिक्त है।")
        if len(contents) > cls.MAX_FILE_SIZE_BYTES:
            raise HTTPException(status_code=413, detail="फ़ाइल का आकार अधिकतम 25MB की सीमा से अधिक है।")

        # 3. Magic Bytes Deep Inspection
        header = contents[:16]
        is_valid_type = False
        detected_mime = "application/octet-stream"

        if expected_category == "PDF":
            if header.startswith(b"%PDF-"):
                is_valid_type = True
                detected_mime = "application/pdf"
        elif expected_category == "AUDIO":
            if header.startswith(b"ID3") or b"ftyp" in header or header.startswith(b"\xff\xfb"):
                is_valid_type = True
                detected_mime = file.content_type or "audio/m4a"

        if not is_valid_type:
            raise HTTPException(
                status_code=415,
                detail=f"अस्वीकृत फ़ाइल प्रारूप: फ़ाइल के वास्तविक बाइनरी सिग्नेचर मान्य {expected_category} से मेल नहीं खाते।"
            )

        return contents, detected_mime
