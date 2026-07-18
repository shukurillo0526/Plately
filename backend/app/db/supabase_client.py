"""
Plately Backend — Supabase Client
===================================
Provides an async-compatible Supabase client singleton.
"""

from supabase import acreate_client, AsyncClient
from app.core.config import get_settings

_client: AsyncClient | None = None

async def get_supabase() -> AsyncClient:
    """Returns the async Supabase client singleton (lazy initialized)."""
    global _client
    if _client is None:
        settings = get_settings()
        _client = await acreate_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY,
        )
    return _client
