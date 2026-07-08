"""
Plately — Security Utilities
==============================
Shared helpers for input sanitization, upload validation, and safe errors.
"""

from __future__ import annotations

import logging
import re

from fastapi import HTTPException, UploadFile

MAX_UPLOAD_BYTES = 10 * 1024 * 1024


def sanitize_search_query(query: str, max_len: int = 100) -> str:
    """Strip PostgREST filter syntax characters from user search input."""
    cleaned = query.strip()[:max_len]
    return re.sub(r"[,\(\)\.%\\]", "", cleaned)


def raise_internal_error(logger: logging.Logger, message: str, exc: Exception) -> None:
    """Log the real error but return a generic message to clients."""
    logger.error("%s: %s", message, exc)
    raise HTTPException(status_code=500, detail="Internal server error")


def _is_valid_image(data: bytes) -> bool:
    if len(data) < 12:
        return False
    if data[:3] == b"\xff\xd8\xff":
        return True
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return True
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return True
    if data[:6] in (b"GIF87a", b"GIF89a"):
        return True
    return False


async def validate_image_upload(
    file: UploadFile,
    max_bytes: int = MAX_UPLOAD_BYTES,
) -> bytes:
    """Validate content type, size, and magic bytes for uploaded images."""
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    data = await file.read()
    if len(data) == 0:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(data) > max_bytes:
        raise HTTPException(status_code=413, detail="File too large")
    if not _is_valid_image(data):
        raise HTTPException(status_code=400, detail="Invalid image file")
    return data
