import asyncio
from fastapi import HTTPException
from app.core.config import settings

# Global concurrency semaphore for OpenNyAI processing
nlp_semaphore = asyncio.Semaphore(settings.MAX_CONCURRENT_NLP_JOBS)

async def acquire_nlp_slot():
    """
    Throttles parallel NLP parsing jobs to MAX_CONCURRENT_NLP_JOBS,
    preventing Out-Of-Memory (OOM) crashes on the Render container.
    """
    try:
        await asyncio.wait_for(nlp_semaphore.acquire(), timeout=15.0)
    except asyncio.TimeoutError:
        raise HTTPException(
            status_code=503,
            detail="सर्वर व्यस्त है: कई अधिवक्ता एक साथ अभियोग पत्र का विश्लेषण कर रहे हैं। "
                   "कृपया 15 सेकंड बाद पुनः प्रयास करें।"
        )

def release_nlp_slot():
    nlp_semaphore.release()
