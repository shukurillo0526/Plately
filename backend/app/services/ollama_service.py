"""
Plately — Local AI Service Layer (Ollama)
==========================================
Manages all interactions with the local Ollama server.
Supports vision (qwen2.5vl:7b), text generation (qwen3:8b),
and embeddings (nomic-embed-text).

Architecture:
  - 16GB VRAM budget (RTX 5070 Ti) — local dev only
  - On production (Railway), Ollama is unavailable → auto-fallback to cloud Gemini
  - Cloud Gemini is the PRIMARY AI for production deployments
  - Ollama is SECONDARY, used only when running locally with GPU
  - Cached availability check prevents repeated health probes
"""

import httpx
import base64
import json
import logging
import time
from typing import Optional, Dict, List, Any

logger = logging.getLogger("plately.ollama")

OLLAMA_BASE_URL = "http://localhost:11434"

# Model registry — maps task types to preferred models
# Dynamically resolved at runtime based on what's available
# RTX 5070 Ti (16GB VRAM) — qwen2.5vl is purpose-built for vision+JSON
MODEL_REGISTRY = {
    "vision": ["qwen2.5vl:7b", "gemma3:12b", "gemma3:4b", "moondream"],
    "text": ["qwen3:14b", "qwen3:8b", "gemma3:12b", "qwen2.5:3b"],
    "translation": ["qwen3:14b", "qwen3:8b", "gemma3:12b"],  # prefer larger model for translation quality
    "embedding": ["nomic-embed-text"],           # embedding models (CPU-safe)
}


class OllamaService:
    """Unified interface to the local Ollama server with automatic cloud fallback."""

    def __init__(self, base_url: str = OLLAMA_BASE_URL, timeout: float = 120.0):
        self.base_url = base_url
        self.timeout = timeout
        self._client = httpx.AsyncClient(timeout=timeout)
        self._available_models: Optional[List[str]] = None
        # Cached availability — avoid repeated health checks
        self._available_cache: Optional[bool] = None
        self._available_cache_time: float = 0
        self._CACHE_TTL = 60.0  # Re-check every 60 seconds

    async def is_available(self) -> bool:
        """Check if the Ollama server is running (cached for 60s)."""
        now = time.monotonic()
        if self._available_cache is not None and (now - self._available_cache_time) < self._CACHE_TTL:
            return self._available_cache
        try:
            resp = await self._client.get(f"{self.base_url}/api/tags", timeout=5.0)
            self._available_cache = resp.status_code == 200
        except (httpx.ConnectError, httpx.TimeoutException):
            self._available_cache = False
        self._available_cache_time = now
        return self._available_cache

    async def list_models(self) -> List[str]:
        """Return names of locally available models."""
        try:
            resp = await self._client.get(f"{self.base_url}/api/tags")
            data = resp.json()
            self._available_models = [m["name"] for m in data.get("models", [])]
            return self._available_models
        except Exception:
            return []

    async def _resolve_model(self, task: str) -> Optional[str]:
        """Find the best available model for a given task."""
        if self._available_models is None:
            await self.list_models()
        candidates = MODEL_REGISTRY.get(task, [])
        for model in candidates:
            if self._available_models and any(
                m == model or m.startswith(model.split(":")[0])
                for m in self._available_models
            ):
                return model
        # Return first candidate and let Ollama handle the error
        return candidates[0] if candidates else None

    # ── Vision ───────────────────────────────────────────────────

    async def analyze_image(
        self,
        image_bytes: bytes,
        prompt: str,
        model: Optional[str] = None,
        temperature: float = 0.2,
        max_tokens: int = 2048,
    ) -> str:
        """
        Send an image + prompt to a vision model via /api/chat.
        Returns the raw text response.
        Falls back to cloud AI if Ollama is unavailable.
        """
        # Check availability first — skip Ollama entirely if down
        if not await self.is_available():
            logger.info("[Ollama] Unavailable, using cloud for vision")
            return await self._cloud_vision_fallback(image_bytes, prompt, temperature, max_tokens)

        try:
            model = model or await self._resolve_model("vision")
            b64_image = base64.b64encode(image_bytes).decode("utf-8")

            messages = []
            messages.append({
                "role": "user",
                "content": prompt,
                "images": [b64_image],
            })

            payload = {
                "model": model,
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens,
                },
            }

            logger.info(f"[Ollama] Vision request → {model} (temp={temperature}, max_tok={max_tokens})")
            resp = await self._client.post(
                f"{self.base_url}/api/chat",
                json=payload,
            )
            resp.raise_for_status()
            result = resp.json()
            msg = result.get("message", {})
            return self._strip_thinking_tags(msg.get("content", ""))
        except (httpx.ConnectError, httpx.TimeoutException) as e:
            logger.warning(f"[Ollama] Vision failed, trying cloud fallback: {e}")
            self._available_cache = False  # Invalidate cache
            return await self._cloud_vision_fallback(image_bytes, prompt, temperature, max_tokens)

    async def _cloud_vision_fallback(
        self, image_bytes: bytes, prompt: str,
        temperature: float = 0.2, max_tokens: int = 2048,
    ) -> str:
        """Fall back to cloud AI for vision tasks."""
        try:
            from app.services.cloud_ai_service import get_cloud_ai_service
            cloud = get_cloud_ai_service()
            if cloud.is_configured:
                logger.info(f"[Ollama] Cloud vision fallback → {cloud.provider}")
                return await cloud.generate_text(
                    prompt=prompt,
                    temperature=temperature,
                    max_tokens=max_tokens,
                    image_bytes=image_bytes,
                    mime_type="image/jpeg",
                )
        except Exception as fallback_err:
            logger.error(f"[Ollama] Cloud vision fallback also failed: {fallback_err}")
        raise httpx.ConnectError("Both Ollama and cloud AI are unavailable for vision")

    async def analyze_image_json(
        self,
        image_bytes: bytes,
        prompt: str,
        model: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Send an image + prompt, parse the response as JSON."""
        raw = await self.analyze_image(image_bytes, prompt, model)
        return self._parse_json_response(raw)

    # ── Text Generation ──────────────────────────────────────────

    async def generate_text(
        self,
        prompt: str,
        model: Optional[str] = None,
        system_prompt: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
        format: Optional[str] = None,
    ) -> str:
        """
        Generate text from a prompt using a local LLM via /api/chat.
        Returns the raw text response.
        Falls back to cloud AI if Ollama is unavailable.
        """
        # If explicitly asking for a Gemini model, skip local Ollama completely
        if model and model.startswith("gemini-"):
            return await self._cloud_fallback(prompt, system_prompt, temperature, max_tokens, format, model)

        # Check availability first — skip Ollama entirely if down
        if not await self.is_available():
            logger.info("[Ollama] Unavailable, using cloud for text generation")
            return await self._cloud_fallback(prompt, system_prompt, temperature, max_tokens, format, model)

        model = model or await self._resolve_model("text")

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens,
            },
        }
        
        if format:
            payload["format"] = format

        logger.info(f"[Ollama] Text generation → {model}")
        try:
            resp = await self._client.post(
                f"{self.base_url}/api/chat",
                json=payload,
            )
            resp.raise_for_status()
            result = resp.json()
            msg = result.get("message", {})
            return self._strip_thinking_tags(msg.get("content", ""))
        except (httpx.ConnectError, httpx.TimeoutException) as e:
            logger.warning(f"[Ollama] Unavailable, trying cloud fallback: {e}")
            self._available_cache = False  # Invalidate cache
            return await self._cloud_fallback(prompt, system_prompt, temperature, max_tokens, format, model)

    async def _cloud_fallback(
        self, prompt: str, system_prompt: Optional[str] = None,
        temperature: float = 0.7, max_tokens: int = 1024,
        format: Optional[str] = None, model: Optional[str] = None,
    ) -> str:
        """Fall back to cloud AI (OpenAI/Gemini) when Ollama is down."""
        try:
            from app.services.cloud_ai_service import get_cloud_ai_service
            cloud = get_cloud_ai_service()
            if cloud.is_configured:
                # If they requested a specific model string that isn't Ollama-specific, map it.
                # E.g. "gemini-2.5-pro"
                cloud_model = model if model and model.startswith("gemini-") else None
                logger.info(f"[Ollama] Cloud fallback → {cloud.provider} (model={cloud_model or 'default'}, format={format})")
                return await cloud.generate_text(prompt, system_prompt, temperature, max_tokens, format=format, model=cloud_model)
        except Exception as fallback_err:
            logger.error(f"[Ollama] Cloud fallback also failed: {fallback_err}")
        raise httpx.ConnectError("Both Ollama and cloud AI are unavailable")

    async def generate_text_json(
        self,
        prompt: str,
        model: Optional[str] = None,
        system_prompt: Optional[str] = None,
        max_tokens: int = 4096,
    ) -> Dict[str, Any]:
        """Generate text and parse as JSON."""
        raw = await self.generate_text(
            prompt, model, system_prompt, temperature=0.1, max_tokens=max_tokens, format="json"
        )
        return self._parse_json_response(raw)

    # ── Embeddings ───────────────────────────────────────────────

    async def get_embedding(
        self,
        text: str,
        model: Optional[str] = None,
    ) -> List[float]:
        """Generate an embedding vector for the given text."""
        model = model or (await self._resolve_model("embedding")) or "nomic-embed-text"

        payload = {"model": model, "input": text}
        resp = await self._client.post(
            f"{self.base_url}/api/embed", json=payload
        )
        resp.raise_for_status()
        data = resp.json()
        embeddings = data.get("embeddings", [[]])
        return embeddings[0] if embeddings else []

    async def get_embeddings_batch(
        self,
        texts: List[str],
        model: Optional[str] = None,
    ) -> List[List[float]]:
        """Generate embeddings for multiple texts."""
        model = model or (await self._resolve_model("embedding")) or "nomic-embed-text"

        payload = {"model": model, "input": texts}
        resp = await self._client.post(
            f"{self.base_url}/api/embed", json=payload
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("embeddings", [])

    # ── Streaming Text Generation ─────────────────────────────────

    async def generate_text_stream(
        self,
        messages: List[Dict[str, str]],
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ):
        """
        Stream text generation token-by-token.
        Yields individual text chunks as they arrive from Ollama.
        Falls back to cloud AI (non-streaming, yielded as single chunk) if Ollama is unavailable.
        
        Args:
            messages: Full chat history [{"role": "user", "content": "..."}]
            model: Model name (auto-resolved if None)
            temperature: Sampling temperature
            max_tokens: Max tokens to generate
            
        Yields:
            str: Individual text chunks
        """
        # Check availability first — if Ollama is down, use cloud fallback
        if not await self.is_available():
            logger.info("[Ollama] Unavailable for streaming, falling back to cloud")
            async for chunk in self._cloud_stream_fallback(messages, temperature, max_tokens):
                yield chunk
            return

        model = model or await self._resolve_model("text")

        payload = {
            "model": model,
            "messages": messages,
            "stream": True,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens,
            },
        }

        logger.info(f"[Ollama] Streaming text → {model} ({len(messages)} messages)")

        try:
            async with self._client.stream(
                "POST", f"{self.base_url}/api/chat", json=payload
            ) as resp:
                resp.raise_for_status()
                async for line in resp.aiter_lines():
                    if not line.strip():
                        continue
                    try:
                        chunk = json.loads(line)
                        content = chunk.get("message", {}).get("content", "")
                        if content:
                            # Strip thinking tags inline
                            import re
                            if "<think>" not in content:
                                yield content
                        if chunk.get("done", False):
                            break
                    except json.JSONDecodeError:
                        continue
        except (httpx.ConnectError, httpx.TimeoutException) as e:
            logger.warning(f"[Ollama] Streaming failed, falling back to cloud: {e}")
            self._available_cache = False  # Invalidate cache
            async for chunk in self._cloud_stream_fallback(messages, temperature, max_tokens):
                yield chunk

    async def _cloud_stream_fallback(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ):
        """
        Cloud fallback for streaming: calls cloud AI non-streaming,
        then yields the response in word-sized chunks to simulate streaming.
        """
        try:
            from app.services.cloud_ai_service import get_cloud_ai_service
            cloud = get_cloud_ai_service()
            if cloud.is_configured:
                # Extract user message and system prompt from message list
                system_prompt = None
                user_prompt = ""
                for msg in messages:
                    if msg.get("role") == "system":
                        system_prompt = msg.get("content", "")
                    elif msg.get("role") == "user":
                        user_prompt = msg.get("content", "")

                logger.info(f"[Ollama] Cloud stream fallback → {cloud.provider}")
                full_response = await cloud.generate_text(
                    prompt=user_prompt,
                    system_prompt=system_prompt,
                    temperature=temperature,
                    max_tokens=max_tokens,
                )
                # Yield in word-sized chunks to simulate streaming
                words = full_response.split(" ")
                for i, word in enumerate(words):
                    yield word if i == 0 else f" {word}"
                return
        except Exception as e:
            logger.error(f"[Ollama] Cloud stream fallback failed: {e}")
            yield "I'm sorry, AI is temporarily unavailable. Please try again later."

    # ── Response Processing Helpers ────────────────────────────────

    @staticmethod
    def _strip_thinking_tags(text: str) -> str:
        """Strip <think>...</think> reasoning blocks from models like qwen3."""
        import re
        # Remove <think>...</think> blocks (possibly multiline)
        cleaned = re.sub(r'<think>.*?</think>', '', text, flags=re.DOTALL)
        return cleaned.strip()

    def _parse_json_response(self, raw: str) -> Dict[str, Any]:
        """Parse a raw LLM response into JSON, handling code fences and edge cases."""
        text = raw.strip()

        # Strip markdown code fences (```json ... ``` or ``` ... ```)
        if text.startswith("```"):
            lines = text.split("\n")
            text = "\n".join(lines[1:])
            if text.rstrip().endswith("```"):
                text = text.rstrip()[:-3]
            text = text.strip()

        # Try direct parse
        try:
            result = json.loads(text)
            if isinstance(result, list):
                return {"items": result}
            return result
        except json.JSONDecodeError:
            pass

        # Try to find JSON object within text (handles preamble/postamble text)
        start = text.find("{")
        end = text.rfind("}") + 1
        if start >= 0 and end > start:
            candidate = text[start:end]
            try:
                result = json.loads(candidate)
                return result
            except json.JSONDecodeError:
                pass

        # Try to find JSON array within text
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

        logger.warning(f"[Ollama] Failed to parse JSON from response ({len(text)} chars): {text[:300]}")
        return {"error": "Failed to parse JSON", "raw_response": text[:500]}

    # ── Cleanup ──────────────────────────────────────────────────

    async def close(self):
        """Close the HTTP client."""
        await self._client.aclose()


# ── Module-level singleton ───────────────────────────────────────
_instance: Optional[OllamaService] = None

def get_ollama_service() -> OllamaService:
    """Get or create the singleton OllamaService instance."""
    global _instance
    if _instance is None:
        _instance = OllamaService()
    return _instance
