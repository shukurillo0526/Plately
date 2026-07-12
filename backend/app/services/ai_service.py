"""
Plately — API-Based AI Service (Cloud AI)
=========================================
Direct connection to Google Gemini / OpenAI APIs.
No local Ollama dependencies.
"""

import asyncio
import base64
import json
import logging
from typing import Optional, Dict, List, Any, AsyncGenerator

import httpx
from app.core.config import get_settings

logger = logging.getLogger("plately.ai_service")


class AIService:
    """Cloud API-based AI service using Google Gemini or OpenAI."""

    def __init__(self):
        settings = get_settings()
        self.openai_key: Optional[str] = getattr(settings, "OPENAI_API_KEY", None)
        self.gemini_key: Optional[str] = getattr(settings, "GEMINI_API_KEY", None)
        self._client = httpx.AsyncClient(timeout=90.0)

    @property
    def provider(self) -> Optional[str]:
        """Which API provider is configured."""
        if self.gemini_key:
            return "gemini"
        if self.openai_key:
            return "openai"
        return None

    async def is_available(self) -> bool:
        """Check if at least one API provider is configured."""
        return self.provider is not None

    async def list_models(self) -> List[str]:
        if self.gemini_key:
            return ["gemini-2.5-flash", "gemini-1.5-flash"]
        if self.openai_key:
            return ["gpt-4o-mini"]
        return []

    def _parse_json_response(self, raw: str) -> Dict[str, Any]:
        """Parse raw LLM output into structured JSON."""
        text = raw.strip()
        if text.startswith("```"):
            lines = text.split("\n")
            text = "\n".join(lines[1:])
            if text.rstrip().endswith("```"):
                text = text.rstrip()[:-3]
            text = text.strip()

        try:
            result = json.loads(text)
            if isinstance(result, list):
                return {"items": result}
            return result
        except json.JSONDecodeError:
            pass

        start = text.find("{")
        end = text.rfind("}") + 1
        if start >= 0 and end > start:
            candidate = text[start:end]
            try:
                return json.loads(candidate)
            except json.JSONDecodeError:
                pass

        start = text.find("[")
        end = text.rfind("]") + 1
        if start >= 0 and end > start:
            candidate = text[start:end]
            try:
                result = json.loads(candidate)
                if isinstance(result, list):
                    return {"items": result}
            except json.JSONDecodeError:
                pass

        logger.warning(f"[AIService] Failed to parse JSON ({len(text)} chars): {text[:200]}")
        return {"error": "Failed to parse JSON", "raw_response": text[:500]}

    # ── Text & Vision Generation ─────────────────────────────────

    async def generate_text(
        self,
        prompt: str,
        model: Optional[str] = None,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 2048,
        format: Optional[str] = None,
        image_bytes: Optional[bytes] = None,
        mime_type: str = "image/jpeg",
    ) -> str:
        """Generate text or vision response via Gemini/OpenAI API."""
        if self.gemini_key:
            gemini_model = model if (model and model.startswith("gemini-")) else "gemini-2.5-flash"
            return await self._gemini_generate(
                prompt=prompt,
                system_prompt=system_prompt,
                temperature=temperature,
                max_tokens=max_tokens,
                format=format,
                image_bytes=image_bytes,
                mime_type=mime_type,
                model=gemini_model,
            )
        elif self.openai_key:
            return await self._openai_generate(
                prompt=prompt,
                system_prompt=system_prompt,
                temperature=temperature,
                max_tokens=max_tokens,
                format=format,
                image_bytes=image_bytes,
                mime_type=mime_type,
            )
        else:
            raise RuntimeError("No cloud AI provider configured. Set GEMINI_API_KEY or OPENAI_API_KEY in .env")

    async def generate_text_json(
        self,
        prompt: str,
        model: Optional[str] = None,
        system_prompt: Optional[str] = None,
        temperature: float = 0.3,
        max_tokens: int = 2048,
    ) -> Dict[str, Any]:
        """Generate text and parse structured JSON response."""
        raw = await self.generate_text(
            prompt=prompt,
            model=model,
            system_prompt=system_prompt,
            temperature=temperature,
            max_tokens=max_tokens,
            format="json",
        )
        return self._parse_json_response(raw)

    async def analyze_image(
        self,
        image_bytes: bytes,
        prompt: str,
        model: Optional[str] = None,
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> str:
        """Analyze image and return text output."""
        return await self.generate_text(
            prompt=prompt,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            image_bytes=image_bytes,
            mime_type="image/jpeg",
        )

    async def analyze_image_json(
        self,
        image_bytes: bytes,
        prompt: str,
        model: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Analyze an image with prompt and return parsed JSON strictly."""
        raw = await self.generate_text(
            prompt=prompt,
            model=model,
            temperature=0.2,
            max_tokens=2048,
            format="json",
            image_bytes=image_bytes,
            mime_type="image/jpeg",
        )
        return self._parse_json_response(raw)

    async def generate_text_stream(
        self,
        messages: List[Dict[str, str]],
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> AsyncGenerator[str, None]:
        """Stream text generation."""
        prompt = "\n".join([f"{m['role']}: {m['content']}" for m in messages])
        raw = await self.generate_text(prompt=prompt, model=model, temperature=temperature, max_tokens=max_tokens)
        yield raw

    # ── Embeddings ───────────────────────────────────────────────

    async def get_embedding(self, text: str, model: Optional[str] = None) -> List[float]:
        """Generate vector embedding (fallback zero vector if API embed not configured)."""
        return [0.0] * 768

    async def get_embeddings_batch(self, texts: List[str], model: Optional[str] = None) -> List[List[float]]:
        return [[0.0] * 768 for _ in texts]

    # ── Gemini Internal ──────────────────────────────────────────

    async def _gemini_generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 2048,
        format: Optional[str] = None,
        image_bytes: Optional[bytes] = None,
        mime_type: str = "image/jpeg",
        model: str = "gemini-2.5-flash",
    ) -> str:
        full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt

        parts = []
        parts.append({"text": full_prompt})
        if image_bytes:
            b64 = base64.b64encode(image_bytes).decode("utf-8")
            parts.append({"inlineData": {"mimeType": mime_type, "data": b64}})

        gen_config = {
            "temperature": temperature,
            "maxOutputTokens": max_tokens,
        }
        if format == "json":
            gen_config["responseMimeType"] = "application/json"

        max_retries = 3
        for attempt in range(max_retries):
            resp = await self._client.post(
                f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={self.gemini_key}",
                json={
                    "contents": [{"parts": parts}],
                    "generationConfig": gen_config,
                },
            )
            if resp.status_code == 429 and attempt < max_retries - 1:
                wait = (attempt + 1) * 4
                logger.warning(f"[AIService] Gemini rate-limited, retrying in {wait}s ({attempt+1}/{max_retries})")
                await asyncio.sleep(wait)
                continue
            resp.raise_for_status()
            data = resp.json()
            return data["candidates"][0]["content"]["parts"][0]["text"]

    # ── OpenAI Internal ──────────────────────────────────────────

    async def _openai_generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 2048,
        format: Optional[str] = None,
        image_bytes: Optional[bytes] = None,
        mime_type: str = "image/jpeg",
    ) -> str:
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        if image_bytes:
            b64 = base64.b64encode(image_bytes).decode("utf-8")
            messages.append({
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": f"data:{mime_type};base64,{b64}"}},
                ],
            })
        else:
            messages.append({"role": "user", "content": prompt})

        payload = {
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if format == "json":
            payload["response_format"] = {"type": "json_object"}

        resp = await self._client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {self.openai_key}",
                "Content-Type": "application/json",
            },
            json=payload,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["choices"][0]["message"]["content"]

    async def close(self):
        await self._client.aclose()


# Singleton
_ai_instance: Optional[AIService] = None


def get_ai_service() -> AIService:
    global _ai_instance
    if _ai_instance is None:
        _ai_instance = AIService()
    return _ai_instance


# Backward compatibility alias during transition
get_ollama_service = get_ai_service
