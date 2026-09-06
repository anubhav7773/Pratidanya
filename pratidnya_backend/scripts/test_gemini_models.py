import httpx
import asyncio
from app.core.config import settings

async def test_candidate(m):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent"
    body = {
        "contents": [{"role": "user", "parts": [{"text": "Hello, return JSON: {\"message\": \"success\"}"}]}],
        "generationConfig": {"responseMimeType": "application/json"}
    }
    async with httpx.AsyncClient(timeout=20.0) as client:
        try:
            res = await client.post(
                url,
                headers={"Content-Type": "application/json", "x-goog-api-key": settings.GEMINI_API_KEY},
                json=body
            )
            print(f"{m:25} status={res.status_code} text={res.text[:120].strip()}")
        except Exception as e:
            print(f"{m:25} exception: {e}")

async def run_all():
    candidates = [
        "gemini-2.5-flash",
        "gemini-3.5-flash",
        "gemini-3.7-flash",
        "gemini-3.8-flash",
        "gemini-flash-latest",
        "gemini-2.5-flash-lite",
        "gemini-3.1-flash-lite",
        "gemini-pro-latest"
    ]
    for c in candidates:
        await test_candidate(c)

if __name__ == "__main__":
    asyncio.run(run_all())
