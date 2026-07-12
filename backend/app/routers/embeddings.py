"""
Plately — Embedding & Vector Search Router
=============================================
Uses local nomic-embed-text via Ollama to generate embeddings
for recipes and user preferences, enabling semantic similarity search.
"""

import logging
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from typing import List

from app.core.auth import CurrentUser
from app.core.security import raise_internal_error
from app.services.ai_service import get_ai_service as get_ollama_service
from slowapi import Limiter
from slowapi.util import get_remote_address

logger = logging.getLogger("plately.embeddings")

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


class EmbedTextRequest(BaseModel):
    text: str

class EmbedBatchRequest(BaseModel):
    texts: List[str]

class SemanticSearchRequest(BaseModel):
    query: str
    candidates: List[dict]  # Each dict has 'id', 'title', 'description'
    top_k: int = 5


def _cosine_similarity(a: List[float], b: List[float]) -> float:
    """Compute cosine similarity between two vectors."""
    if not a or not b or len(a) != len(b):
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = sum(x * x for x in a) ** 0.5
    norm_b = sum(x * x for x in b) ** 0.5
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


@router.post("/api/v1/ai/embed")
@limiter.limit("30/minute")
async def embed_text(request: Request, req: EmbedTextRequest, current: CurrentUser):
    """Generate an embedding vector for a single text."""
    ollama = get_ollama_service()
    if not await ollama.is_available():
        raise HTTPException(status_code=503, detail="Ollama unavailable")

    try:
        vector = await ollama.get_embedding(req.text)
        return {
            "status": "success",
            "dimensions": len(vector),
            "embedding": vector,
        }
    except Exception as e:
        raise_internal_error(logger, "Embed failed", e)


@router.post("/api/v1/ai/embed-batch")
@limiter.limit("20/minute")
async def embed_batch(request: Request, req: EmbedBatchRequest, current: CurrentUser):
    """Generate embeddings for multiple texts at once."""
    ollama = get_ollama_service()
    if not await ollama.is_available():
        raise HTTPException(status_code=503, detail="Ollama unavailable")

    try:
        vectors = await ollama.get_embeddings_batch(req.texts)
        return {
            "status": "success",
            "count": len(vectors),
            "dimensions": len(vectors[0]) if vectors else 0,
            "embeddings": vectors,
        }
    except Exception as e:
        raise_internal_error(logger, "Embed batch failed", e)


@router.post("/api/v1/ai/semantic-search")
@limiter.limit("20/minute")
async def semantic_search(request: Request, req: SemanticSearchRequest, current: CurrentUser):
    """
    Perform semantic search: embed the query, compute similarity
    against pre-computed candidate embeddings, return top-K results.

    Each candidate dict should have: id, title, description.
    The title + description are embedded and compared against the query.
    """
    ollama = get_ollama_service()
    if not await ollama.is_available():
        raise HTTPException(status_code=503, detail="Ollama unavailable")

    try:
        query_vec = await ollama.get_embedding(req.query)

        candidate_texts = [
            f"{c.get('title', '')}. {c.get('description', '')}"
            for c in req.candidates
        ]
        candidate_vecs = await ollama.get_embeddings_batch(candidate_texts)

        scored = []
        for i, candidate in enumerate(req.candidates):
            if i < len(candidate_vecs):
                sim = _cosine_similarity(query_vec, candidate_vecs[i])
                scored.append({
                    "id": candidate.get("id"),
                    "title": candidate.get("title"),
                    "score": round(sim, 4),
                })

        scored.sort(key=lambda x: x["score"], reverse=True)

        return {
            "status": "success",
            "query": req.query,
            "results": scored[:req.top_k],
        }
    except Exception as e:
        raise_internal_error(logger, "Semantic search failed", e)


@router.post("/api/v1/ai/personalize")
@limiter.limit("20/minute")
async def personalize_recipes(
    request: Request,
    current: CurrentUser,
    user_history: List[str],
    candidate_titles: List[str],
    top_k: int = 10,
):
    """
    Personalize recipe recommendations based on user cooking history.

    Workflow:
    1. Embed the user's cooking history as a single preference vector
    2. Embed all candidate recipe titles
    3. Rank by cosine similarity to the user's preference
    """
    ollama = get_ollama_service()
    if not await ollama.is_available():
        raise HTTPException(status_code=503, detail="Ollama unavailable")

    try:
        history_text = f"I enjoy cooking: {', '.join(user_history)}. Recommend similar recipes."
        user_vec = await ollama.get_embedding(history_text)

        candidate_vecs = await ollama.get_embeddings_batch(candidate_titles)

        scored = []
        for i, title in enumerate(candidate_titles):
            if i < len(candidate_vecs):
                sim = _cosine_similarity(user_vec, candidate_vecs[i])
                scored.append({"title": title, "score": round(sim, 4)})

        scored.sort(key=lambda x: x["score"], reverse=True)

        return {
            "status": "success",
            "user_profile_summary": history_text,
            "results": scored[:top_k],
        }
    except Exception as e:
        raise_internal_error(logger, "Personalize failed", e)
