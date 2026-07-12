"""
Plately — Health Check Router
================================
Comprehensive health check that reports the status of all
backend dependencies. Used by monitoring systems and the
frontend's connectivity check.

Response codes:
  200 = All systems healthy
  503 = One or more critical dependencies down
"""

import logging
import time
from datetime import datetime, timezone
from fastapi import APIRouter

from app.services.ai_service import get_ai_service as get_ollama_service
from app.db.supabase_client import get_supabase

logger = logging.getLogger("plately.health")

router = APIRouter(tags=["Health"])


@router.get("/api/v1/health")
async def health_check():
    """
    Deep health check — tests connectivity to all dependencies.
    
    Returns:
        - overall: "healthy" | "degraded" | "unhealthy"
        - services: dict of each dependency's status
        - timestamp: ISO 8601
        - version: backend version
    """
    checks = {}
    overall = "healthy"

    # 1. Supabase DB connectivity
    db_start = time.perf_counter()
    try:
        db = get_supabase()
        # Simple read to verify connection
        result = db.table("ingredients").select("id").limit(1).execute()
        db_ms = round((time.perf_counter() - db_start) * 1000, 1)
        checks["supabase"] = {
            "status": "up",
            "latency_ms": db_ms,
            "detail": f"Connected, {len(result.data)} row(s) returned",
        }
    except Exception as e:
        db_ms = round((time.perf_counter() - db_start) * 1000, 1)
        checks["supabase"] = {
            "status": "down",
            "latency_ms": db_ms,
            "detail": "Connection failed",
        }
        overall = "unhealthy"

    # 2. Ollama AI service
    ai_start = time.perf_counter()
    try:
        ollama = get_ollama_service()
        available = await ollama.is_available()
        ai_ms = round((time.perf_counter() - ai_start) * 1000, 1)

        if available:
            models = await ollama.list_models()
            checks["ollama"] = {
                "status": "up",
                "latency_ms": ai_ms,
                "models_loaded": models,
                "detail": f"{len(models)} model(s) available",
            }
        else:
            checks["ollama"] = {
                "status": "down",
                "latency_ms": ai_ms,
                "detail": "Ollama not reachable",
            }
            if overall == "healthy":
                overall = "degraded"  # AI is optional, not critical
    except Exception as e:
        ai_ms = round((time.perf_counter() - ai_start) * 1000, 1)
        checks["ollama"] = {
            "status": "down",
            "latency_ms": ai_ms,
            "detail": str(e),
        }
        if overall == "healthy":
            overall = "degraded"

    # 3. Rate limiter (always up if app is running)
    checks["rate_limiter"] = {"status": "up", "detail": "slowapi active"}

    # Build response
    status_code = 200 if overall != "unhealthy" else 503

    from starlette.responses import JSONResponse
    from app.core.config import get_settings
    return JSONResponse(
        status_code=status_code,
        content={
            "status": overall,
            "version": get_settings().APP_VERSION,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "services": checks,
        },
    )


@router.get("/api/v1/health/ping")
async def ping():
    """
    Lightweight liveness probe.
    Returns immediately with no dependency checks.
    """
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}
