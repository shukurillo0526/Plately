"""
Plately — User Quota Router
===========================
Exposes current daily fair-use AI quota status to the frontend and monitoring tools.
"""

from fastapi import APIRouter
from app.core.auth import CurrentUser
from app.core.quota import quota_manager

router = APIRouter(prefix="/api/v1", tags=["Quota"])

@router.get("/user/quota")
async def get_user_quota(current: CurrentUser):
    """
    Returns the caller's daily quota status for scans and recipe generations.
    """
    return quota_manager.get_status(current.id)
