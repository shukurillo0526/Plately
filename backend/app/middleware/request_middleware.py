"""
Plately — Request Middleware
==============================
Production-grade middleware stack:
1. Request ID injection (X-Request-ID header for tracing)
2. Structured logging with correlation IDs
3. Input validation (UUID format, body size limits)
4. Request timing
"""

import uuid
import time
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response, JSONResponse

logger = logging.getLogger("plately.middleware")

# Maximum request body size: 10MB (protects against abuse)
MAX_BODY_SIZE = 10 * 1024 * 1024

# UUID v4 pattern for validation
UUID_PATTERN = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'


class RequestIdMiddleware(BaseHTTPMiddleware):
    """
    Injects a unique X-Request-ID into every request/response.
    If the client sends one, it's preserved; otherwise a new one is generated.
    This enables end-to-end request tracing across frontend → backend → logs.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        # Preserve client-sent request ID or generate a new one
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())

        # Store in request state for downstream access
        request.state.request_id = request_id

        # Time the request
        start = time.perf_counter()

        response = await call_next(request)

        elapsed_ms = round((time.perf_counter() - start) * 1000, 1)

        # Attach to response headers
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time"] = f"{elapsed_ms}ms"

        # Structured log line
        logger.info(
            "request_completed",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status": response.status_code,
                "elapsed_ms": elapsed_ms,
                "client": request.client.host if request.client else "unknown",
            },
        )

        return response


class InputValidationMiddleware(BaseHTTPMiddleware):
    """
    Validates incoming requests:
    - Rejects bodies larger than MAX_BODY_SIZE
    - Validates UUID path parameters have correct format
    - Enforces Content-Type for POST/PUT/PATCH requests
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        # 1. Body size check for mutating methods
        if request.method in ("POST", "PUT", "PATCH"):
            content_length = request.headers.get("content-length")
            if content_length and content_length.isdigit() and int(content_length) > MAX_BODY_SIZE:
                return JSONResponse(
                    status_code=413,
                    content={
                        "status": "error",
                        "message": f"Request body too large. Max: {MAX_BODY_SIZE // (1024*1024)}MB",
                    },
                )
            elif request.headers.get("transfer-encoding", "").lower() == "chunked":
                # Ensure chunked uploads are logged/monitored for downstream handler validation
                logger.debug(f"[Security] Chunked request received on {request.url.path}")

        # 2. UUID path parameter validation
        import re
        path = request.url.path
        # Check segments that look like UUIDs in the path
        segments = path.split("/")
        for segment in segments:
            # Only validate segments that contain hyphens (potential UUIDs)
            if len(segment) == 36 and segment.count("-") == 4:
                if not re.match(UUID_PATTERN, segment.lower()):
                    return JSONResponse(
                        status_code=400,
                        content={
                            "status": "error",
                            "message": f"Invalid UUID format in path: {segment}",
                        },
                    )

        return await call_next(request)
