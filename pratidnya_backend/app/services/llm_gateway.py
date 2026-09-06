import json
import logging
from typing import Dict, Any, Optional
import httpx
from fastapi import HTTPException
from app.core.config import settings

logger = logging.getLogger("pratidnya.llm_gateway")

try:
    from groq import AsyncGroq
except ImportError:
    AsyncGroq = None


class LLMGateway:
    """
    Unified LLM Gateway for Pratidnya Legal Tech:
    - Primary Text/JSON: Groq (Llama-3.3-70B-versatile) for sub-second Devanagari legal generation.
    - Primary Voice ASR: Groq (Whisper-large-v3) for real-time court dictation.
    - Fallback: Google Gemini (gemini-3.6-flash, gemini-3.1-flash-lite, gemini-flash-latest).
    - Embeddings: Google Gemini text-embedding-004 (768-dim dense vectors).
    """

    _groq_client: Optional[Any] = None

    CANDIDATE_GEMINI_MODELS = [
        "gemini-3.6-flash",
        "gemini-3.1-flash-lite",
        "gemini-flash-latest",
        "gemini-3.5-flash",
        "gemini-3.7-flash",
        "gemini-3.8-flash",
    ]

    @classmethod
    def get_groq_client(cls) -> Optional[Any]:
        if cls._groq_client is not None:
            return cls._groq_client
        if AsyncGroq is not None and settings.GROQ_API_KEY:
            try:
                cls._groq_client = AsyncGroq(api_key=settings.GROQ_API_KEY)
                return cls._groq_client
            except Exception as e:
                logger.warning(f"[LLMGateway] Failed to initialize AsyncGroq client: {e}")
                return None
        return None

    CANDIDATE_GROQ_MODELS = [
        "llama-3.3-70b-versatile",
        "openai/gpt-oss-120b",
        "llama-3.1-70b-versatile",
        "qwen/qwen3.8-27b",
        "openai/gpt-oss-20b",
    ]

    @classmethod
    async def generate_structured_json(
        cls,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.1,
        max_tokens: int = 4096
    ) -> Dict[str, Any]:
        """
        Routes structured JSON generation through Groq primary (trying candidate models),
        falling back to Google Gemini REST API if Groq fails or is not configured.
        """
        groq_client = cls.get_groq_client()
        if groq_client and settings.GROQ_API_KEY:
            models_to_try = [settings.GROQ_MODEL] + [
                m for m in cls.CANDIDATE_GROQ_MODELS if m != settings.GROQ_MODEL
            ]
            for model_name in models_to_try:
                try:
                    logger.info(f"[LLMGateway] Invoking Groq Primary ({model_name})...")
                    chat_completion = await groq_client.chat.completions.create(
                        messages=[
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": user_prompt}
                        ],
                        model=model_name,
                        temperature=temperature,
                        max_completion_tokens=max_tokens,
                        response_format={"type": "json_object"}
                    )
                    raw_content = chat_completion.choices[0].message.content or "{}"
                    clean_content = cls._clean_json_str(raw_content)
                    parsed = json.loads(clean_content)
                    logger.info(f"[LLMGateway] Groq JSON generation successful with {model_name}.")
                    return parsed
                except Exception as e:
                    err_str = str(e)
                    if "model_not_found" in err_str or "does not exist" in err_str:
                        logger.warning(f"[LLMGateway] Groq model '{model_name}' unavailable, trying next candidate...")
                        continue
                    logger.warning(f"[LLMGateway] Groq JSON generation error ({model_name}): {e}. Failing over...")
                    break

        # Fallback to Gemini REST API
        logger.info("[LLMGateway] Executing fallback to Google Gemini...")
        return await cls._generate_json_via_gemini(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            temperature=temperature,
            max_tokens=max_tokens
        )

    @classmethod
    async def generate_text(
        cls,
        system_prompt: str,
        user_prompt: str,
        temperature: float = 0.2,
        max_tokens: int = 4096
    ) -> str:
        """
        Routes text generation through Groq primary with Gemini fallback.
        """
        groq_client = cls.get_groq_client()
        if groq_client and settings.GROQ_API_KEY:
            models_to_try = [settings.GROQ_MODEL] + [
                m for m in cls.CANDIDATE_GROQ_MODELS if m != settings.GROQ_MODEL
            ]
            for model_name in models_to_try:
                try:
                    logger.info(f"[LLMGateway] Invoking Groq text generation ({model_name})...")
                    chat_completion = await groq_client.chat.completions.create(
                        messages=[
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": user_prompt}
                        ],
                        model=model_name,
                        temperature=temperature,
                        max_completion_tokens=max_tokens
                    )
                    return (chat_completion.choices[0].message.content or "").strip()
                except Exception as e:
                    err_str = str(e)
                    if "model_not_found" in err_str or "does not exist" in err_str:
                        logger.warning(f"[LLMGateway] Groq model '{model_name}' unavailable, trying next candidate...")
                        continue
                    logger.warning(f"[LLMGateway] Groq text generation error ({model_name}): {e}. Failing over...")
                    break

        return await cls._generate_text_via_gemini(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            temperature=temperature,
            max_tokens=max_tokens
        )

    @classmethod
    def _clean_json_str(cls, raw: str) -> str:
        clean = raw.strip()
        if clean.startswith("```json"):
            clean = clean[7:]
        elif clean.startswith("```"):
            clean = clean[3:]
        if clean.endswith("```"):
            clean = clean[:-3]
        return clean.strip()

    @classmethod
    async def _generate_json_via_gemini(
        cls,
        system_prompt: str,
        user_prompt: str,
        temperature: float,
        max_tokens: int
    ) -> Dict[str, Any]:
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": settings.GEMINI_API_KEY
        }
        body = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": max_tokens,
                "responseMimeType": "application/json"
            }
        }
        base_url = "https://generativelanguage.googleapis.com/v1beta/models"

        async with httpx.AsyncClient(timeout=45.0) as client:
            last_err = None
            for model_name in cls.CANDIDATE_GEMINI_MODELS:
                url = f"{base_url}/{model_name}:generateContent"
                try:
                    res = await client.post(url, headers=headers, json=body)
                except (httpx.TimeoutException, httpx.RequestError) as net_err:
                    last_err = f"{model_name}: Network/Timeout - {str(net_err)}"
                    logger.warning(f"[LLMGateway] Gemini network error on {model_name}: {net_err}")
                    continue

                if res.status_code == 200:
                    data = res.json()
                    candidates = data.get("candidates", [])
                    if not candidates:
                        last_err = f"{model_name}: Empty candidates list"
                        continue
                    text_parts = candidates[0].get("content", {}).get("parts", [])
                    if not text_parts:
                        last_err = f"{model_name}: No text parts in candidate"
                        continue
                    raw_text = text_parts[0].get("text", "{}")
                    clean_text = cls._clean_json_str(raw_text)
                    try:
                        return json.loads(clean_text)
                    except json.JSONDecodeError as jde:
                        logger.error(f"[LLMGateway] JSON decode failed from Gemini {model_name}: {jde}")
                        raise HTTPException(status_code=500, detail="AI प्रतिक्रिया को JSON में पार्स नहीं किया जा सका।")
                elif res.status_code in (404, 429, 500, 503):
                    last_err = f"{model_name}: HTTP {res.status_code} - {res.text}"
                    logger.warning(f"[LLMGateway] Gemini fallback from {model_name}: {res.status_code}")
                    continue
                else:
                    raise HTTPException(status_code=res.status_code, detail=f"Gemini API त्रुटि: {res.text}")

            raise HTTPException(status_code=502, detail=f"सभी LLM बैकएंड (Groq एवं Gemini) अनुपलब्ध: {last_err}")

    @classmethod
    async def _generate_text_via_gemini(
        cls,
        system_prompt: str,
        user_prompt: str,
        temperature: float,
        max_tokens: int
    ) -> str:
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": settings.GEMINI_API_KEY
        }
        body = {
            "systemInstruction": {"parts": [{"text": system_prompt}]},
            "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": max_tokens
            }
        }
        base_url = "https://generativelanguage.googleapis.com/v1beta/models"

        async with httpx.AsyncClient(timeout=45.0) as client:
            last_err = None
            for model_name in cls.CANDIDATE_GEMINI_MODELS:
                url = f"{base_url}/{model_name}:generateContent"
                try:
                    res = await client.post(url, headers=headers, json=body)
                except (httpx.TimeoutException, httpx.RequestError) as net_err:
                    last_err = f"{model_name}: Network/Timeout - {str(net_err)}"
                    continue

                if res.status_code == 200:
                    data = res.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts:
                            return parts[0].get("text", "").strip()
                elif res.status_code in (404, 429, 500, 503):
                    last_err = f"{model_name}: HTTP {res.status_code}"
                    continue
                else:
                    raise HTTPException(status_code=res.status_code, detail=f"Gemini API त्रुटि: {res.text}")

            raise HTTPException(status_code=502, detail=f"सभी LLM बैकएंड अनुपलब्ध: {last_err}")
