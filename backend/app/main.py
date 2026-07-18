"""
Plately — Application Entry Point
====================================
FastAPI application with full production middleware stack:
- Request ID tracing (X-Request-ID)
- Structured JSON logging
- Input validation (body size, UUID format)
- Global error handling with standardized envelopes
- Rate limiting on AI-heavy endpoints
- CORS for Flutter frontend
- Comprehensive health checks
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.routers import (
    ocr_parser, barcode_lookup, vision_detect, recipe_ai,
    embeddings, inventory, user_data, calorie_analysis,
    recommendations, health, chat, notifications, orders,
    feedback, meal_prep, analytics, challenges, social,
)
from app.services.ai_service import get_ai_service as get_ollama_service
from app.core.auth import CurrentUser
from app.middleware.request_middleware import RequestIdMiddleware, InputValidationMiddleware
from app.middleware.error_handlers import register_error_handlers
from app.core.logging_config import setup_logging
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import uvicorn

# ── Logging ──────────────────────────────────────────────────────
# Use structured=False for local development (readable logs)
# Use structured=True for production (JSON logs)
setup_logging(level="INFO", structured=True)

# ── Sentry (optional — activate by setting SENTRY_DSN in .env) ──
try:
    from app.core.config import get_settings
    _dsn = get_settings().SENTRY_DSN
    if _dsn:
        import sentry_sdk
        from sentry_sdk.integrations.fastapi import FastApiIntegration
        from sentry_sdk.integrations.starlette import StarletteIntegration
        sentry_sdk.init(
            dsn=_dsn,
            traces_sample_rate=0.2,
            integrations=[FastApiIntegration(), StarletteIntegration()],
            environment="production",
        )
        import logging
        logging.getLogger("plately.main").info("[Sentry] Crash reporting enabled")
except ImportError:
    pass  # sentry-sdk not installed — skip silently

# ── Rate Limiter ─────────────────────────────────────────────────
limiter = Limiter(key_func=get_remote_address)

# ── FastAPI App ──────────────────────────────────────────────────
_settings = get_settings()
app = FastAPI(
    title="Plately AI Backend",
    description=(
        "Vision and Intelligence layer for the Plately consumer app. "
        "Local Ollama AI + Supabase DB + vector search.\n\n"
        "## Features\n"
        "- 🔍 **Vision**: OCR receipt scanning, barcode lookup, food image recognition\n"
        "- 🤖 **AI**: Recipe generation, ingredient substitution, cooking tips\n"
        "- 📊 **Recommendations**: 6-signal composite scoring engine\n"
        "- 🎥 **YouTube Intelligence**: Auto-extract recipes from video metadata\n"
        "- 🛒 **Shopping**: Smart shopping list generation\n"
        "- 📈 **Nutrition**: Calorie analysis and daily tracking\n"
        "- 👤 **User**: Flavor profile auto-learning, engagement tracking\n"
    ),
    version="0.1.9",
    docs_url="/docs" if _settings.DEBUG else None,
    redoc_url="/redoc" if _settings.DEBUG else None,
    openapi_tags=[
        {"name": "Health", "description": "System health checks and status"},
        {"name": "Vision", "description": "OCR, barcode, and food image recognition"},
        {"name": "AI", "description": "Recipe generation, substitution, and cooking tips"},
        {"name": "Recipes", "description": "Recipe recommendations and scoring"},
        {"name": "Inventory", "description": "Ingredient and inventory management"},
        {"name": "User Data", "description": "User profiles, shopping lists, meal plans"},
        {"name": "Nutrition", "description": "Calorie analysis and tracking"},
        {"name": "Embeddings", "description": "Vector search and similarity"},
        {"name": "Orders", "description": "Mobile ordering — pickup and delivery"},
    ],
)

# ── Rate Limiter Setup ───────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── Middleware Stack (order matters — last added runs first) ─────
# 1. CORS (outermost) — explicit origins only; never wildcard + credentials
_cors_origins = _settings.cors_origins_list()
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins or ["http://localhost"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept", "X-Request-ID"],
    expose_headers=["X-Request-ID", "X-Response-Time"],
)

# 2. Request ID + timing (runs after CORS, adds tracing headers)
app.add_middleware(RequestIdMiddleware)

# 3. Input validation (runs last, innermost)
app.add_middleware(InputValidationMiddleware)

# 4. Security hardening headers (HSTS, Anti-MIME sniffing, Frame protection)
@app.middleware("http")
async def security_headers_middleware(request: Request, call_next):
    response = await call_next(request)
    if not _settings.DEBUG:
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    return response

# ── Global Error Handlers ────────────────────────────────────────
register_error_handlers(app)

# ── Routers ──────────────────────────────────────────────────────
app.include_router(health.router)
app.include_router(ocr_parser.router)
app.include_router(barcode_lookup.router)
app.include_router(vision_detect.router)
app.include_router(recipe_ai.router)
app.include_router(embeddings.router)
app.include_router(inventory.router)
app.include_router(user_data.router)
app.include_router(calorie_analysis.router)
app.include_router(recommendations.router)
app.include_router(chat.router)
app.include_router(notifications.router)
app.include_router(orders.router)
app.include_router(feedback.router)
app.include_router(meal_prep.router)
app.include_router(analytics.router)
app.include_router(challenges.router)
app.include_router(social.router)

# ── Root ─────────────────────────────────────────────────────────
@app.get("/", tags=["Health"])
async def root():
    return {
        "name": "Plately Intelligence API",
        "version": _settings.APP_VERSION,
        "docs": "/docs" if _settings.DEBUG else None,
        "health": "/api/v1/health",
    }


@app.get("/api/v1/ai/status", tags=["AI"])
async def ai_status(current: CurrentUser):
    """Health check for the local AI pipeline."""
    ollama = get_ollama_service()
    available = await ollama.is_available()
    models = await ollama.list_models() if available else []
    return {
        "ollama_running": available,
        "models_loaded": models,
        "gpu": "RTX 5070 Ti (16GB VRAM)",
        "recommended": {
            "vision": "qwen2.5vl:7b",
            "text": "qwen3:8b",
            "embedding": "nomic-embed-text",
        }
    }


from prometheus_fastapi_instrumentator import Instrumentator
import asyncio
from app.core.worker import worker_loop

# Instrument FastAPI with Prometheus
Instrumentator().instrument(app).expose(app)

@app.on_event("startup")
async def startup_event():
    # Start the async job worker loop in the background
    asyncio.create_task(worker_loop())

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
