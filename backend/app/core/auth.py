"""
Plately — Authentication Dependencies
======================================
Validates Supabase JWT tokens on protected API routes.
User-scoped endpoints must derive user_id from the token, not the request body.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from supabase import Client, create_client

from app.core.config import get_settings

logger = logging.getLogger("plately.auth")

_bearer = HTTPBearer(auto_error=False)

_auth_client: Client | None = None


@dataclass(frozen=True)
class AuthenticatedUser:
    id: str
    email: str | None = None


def _get_auth_client() -> Client:
    global _auth_client
    if _auth_client is None:
        settings = get_settings()
        if not settings.SUPABASE_URL or not settings.SUPABASE_ANON_KEY:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Authentication is not configured",
            )
        _auth_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)
    return _auth_client


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> AuthenticatedUser:
    """Require a valid Supabase access token."""
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        response = _get_auth_client().auth.get_user(credentials.credentials)
        user = response.user
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
            )
        return AuthenticatedUser(id=str(user.id), email=user.email)
    except HTTPException:
        raise
    except Exception as exc:
        logger.warning("JWT validation failed: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from exc


async def get_optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> AuthenticatedUser | None:
    """Return AuthenticatedUser if valid token is provided, else None."""
    if credentials is None or not credentials.credentials:
        return None
    try:
        response = _get_auth_client().auth.get_user(credentials.credentials)
        user = response.user
        if user is None:
            return None
        return AuthenticatedUser(id=str(user.id), email=user.email)
    except Exception:
        return None


CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_user)]
OptionalUser = Annotated[AuthenticatedUser | None, Depends(get_optional_user)]


def require_user_id(current: AuthenticatedUser, claimed_user_id: str) -> None:
    """Ensure the caller can only act on their own user_id."""
    if current.id != claimed_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )


def verify_inventory_ownership(db, item_id: str, user_id: str) -> None:
    """Ensure an inventory item belongs to the authenticated user."""
    result = (
        db.table("inventory_items")
        .select("user_id")
        .eq("id", item_id)
        .limit(1)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
    if str(result.data[0]["user_id"]) != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


def verify_shopping_item_ownership(db, item_id: str, user_id: str) -> None:
    result = (
        db.table("shopping_list")
        .select("user_id")
        .eq("id", item_id)
        .limit(1)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
    if str(result.data[0]["user_id"]) != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


def verify_meal_plan_ownership(db, meal_id: str, user_id: str) -> None:
    result = (
        db.table("meal_plan")
        .select("user_id")
        .eq("id", meal_id)
        .limit(1)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Meal not found")
    if str(result.data[0]["user_id"]) != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


def get_order_or_404(db, order_id: str) -> dict:
    result = db.table("orders").select("*").eq("id", order_id).limit(1).execute()
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    return result.data[0]


def verify_order_customer(current: AuthenticatedUser, order: dict) -> None:
    if str(order.get("user_id")) != current.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


def verify_restaurant_owner(db, current: AuthenticatedUser, restaurant_id: str) -> None:
    result = (
        db.table("restaurants")
        .select("owner_id")
        .eq("id", restaurant_id)
        .limit(1)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Restaurant not found")
    owner_id = result.data[0].get("owner_id")
    if owner_id is None or str(owner_id) != current.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
