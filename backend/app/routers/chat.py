"""
Plately — Kitchen Chat Assistant Router
==========================================
Persistent conversational AI for cooking help.
Supports both streaming (SSE) and non-streaming responses.

Features:
  - Multi-turn conversation with context retention
  - Kitchen-aware system prompt (knows user's inventory & recipes)
  - Server-Sent Events (SSE) for real-time streaming
  - Conversation history managed client-side (stateless backend)
"""

import logging
import json
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from app.services.ollama_service import get_ollama_service
from slowapi import Limiter
from slowapi.util import get_remote_address

logger = logging.getLogger("plately.chat")

limiter = Limiter(key_func=get_remote_address)

router = APIRouter(tags=["AI"])

KITCHEN_SYSTEM_PROMPT = """You are Plately AI — a friendly, expert kitchen assistant built into a smart fridge app.

Your personality:
- Warm and encouraging, especially to beginners
- Concise — keep answers under 150 words unless the user asks for detail
- Practical — give actionable advice, not theory
- Safety-conscious — always mention food safety when relevant

You can help with:
- Cooking techniques and tips
- Ingredient substitutions
- Recipe suggestions based on what the user has
- Food storage and shelf life
- Meal planning ideas
- Nutritional questions
- Kitchen tool recommendations

Rules:
- If you don't know something, say so honestly
- Never make up nutritional facts — suggest checking a reliable source
- If a question is clearly not food-related, politely redirect to cooking topics
- Use emoji sparingly to keep things friendly 🍳"""


class ChatMessage(BaseModel):
    role: str  # "user", "assistant", or "system"
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    stream: bool = True
    context: Optional[str] = None  # Optional: user's inventory/recipe context


@router.post("/api/v1/ai/chat")
@limiter.limit("30/minute")
async def chat(request: Request, req: ChatRequest):
    """
    Multi-turn kitchen assistant chat.
    
    If stream=True (default), returns Server-Sent Events (SSE).
    If stream=False, returns the complete response as JSON.
    
    The client manages conversation history and sends the full
    message list each time for context.
    """
    ollama = get_ollama_service()

    # Build messages with system prompt
    system_content = KITCHEN_SYSTEM_PROMPT
    if req.context:
        system_content += f"\n\nUser's current context:\n{req.context}"

    messages = [{"role": "system", "content": system_content}]
    for msg in req.messages:
        messages.append({"role": msg.role, "content": msg.content})

    if req.stream:
        # Streaming SSE response
        async def event_generator():
            try:
                full_response = ""
                async for chunk in ollama.generate_text_stream(
                    messages=messages,
                    temperature=0.7,
                    max_tokens=800,
                ):
                    full_response += chunk
                    # SSE format: data: <json>\n\n
                    yield f"data: {json.dumps({'content': chunk})}\n\n"
                yield f"data: {json.dumps({'done': True})}\n\n"
            except Exception as e:
                logger.error(f"[Chat] Streaming error: {e}")
                error_msg = "I'm sorry, I'm having trouble connecting right now. Please try again in a moment."
                yield f"data: {json.dumps({'content': error_msg})}\n\n"
                yield f"data: {json.dumps({'done': True})}\n\n"

        return StreamingResponse(
            event_generator(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",  # Disable nginx buffering
            },
        )
    else:
        # Non-streaming response
        try:
            # Use regular generate_text with the message history
            user_msg = req.messages[-1].content if req.messages else ""
            response = await ollama.generate_text(
                prompt=user_msg,
                system_prompt=system_content,
                temperature=0.7,
                max_tokens=800,
            )
            return {
                "status": "success",
                "data": {
                    "role": "assistant",
                    "content": response.strip(),
                },
            }
        except Exception as e:
            logger.error(f"[Chat] Generation error: {e}")
            raise HTTPException(status_code=500, detail=str(e))
