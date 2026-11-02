"""
Plately — Fair-Use Daily Quota Engine
=====================================
Enforces daily fair-use AI allowances per user to prevent unbounded cloud AI costs
and ensure consistent quality of service for all users.

Limits:
- Vision / Receipt / Nutrition scans: 3 scans / day
- Bespoke AI recipe generation: 2 generations / day
- Quotas reset daily at 00:00:00 UTC.
"""

from __future__ import annotations

import logging
import threading
from datetime import datetime, timezone, timedelta
from typing import Dict, Tuple
from fastapi import HTTPException, status

logger = logging.getLogger("plately.quota")

class QuotaAction:
    SCAN = "scan"
    RECIPE_GEN = "recipe_gen"

DAILY_LIMITS = {
    QuotaAction.SCAN: 3,
    QuotaAction.RECIPE_GEN: 2,
}

class DailyQuotaManager:
    """Thread-safe in-memory daily quota tracker."""
    def __init__(self):
        self._lock = threading.Lock()
        # Key: (date_str_utc, user_id, action) -> count
        self._counts: Dict[Tuple[str, str, str], int] = {}
        self._last_cleanup_date: str = ""

    def _today_utc(self) -> str:
        return datetime.now(timezone.utc).strftime("%Y-%m-%d")

    def _next_reset_utc(self) -> str:
        now = datetime.now(timezone.utc)
        tomorrow = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
        return tomorrow.isoformat()

    def _cleanup_old_dates_locked(self, today: str):
        if self._last_cleanup_date == today:
            return
        keys_to_remove = [k for k in self._counts.keys() if k[0] != today]
        for k in keys_to_remove:
            del self._counts[k]
        self._last_cleanup_date = today

    def get_status(self, user_id: str) -> dict:
        today = self._today_utc()
        reset_time = self._next_reset_utc()

        with self._lock:
            self._cleanup_old_dates_locked(today)
            result = {}
            for action, limit in DAILY_LIMITS.items():
                used = self._counts.get((today, user_id, action), 0)
                remaining = max(0, limit - used)
                result[action] = {
                    "limit": limit,
                    "used": used,
                    "remaining": remaining,
                    "resets_at_utc": reset_time,
                }
            return result

    def consume(self, user_id: str, action: str) -> dict:
        today = self._today_utc()
        limit = DAILY_LIMITS.get(action)
        if limit is None:
            raise ValueError(f"Unknown quota action: {action}")

        with self._lock:
            self._cleanup_old_dates_locked(today)
            key = (today, user_id, action)
            used = self._counts.get(key, 0)

            if used >= limit:
                logger.warning(f"[QuotaExceeded] User {user_id} exceeded daily allowance for {action} ({used}/{limit})")
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail={
                        "error": "DAILY_QUOTA_EXCEEDED",
                        "message": f"Daily limit reached for {action}. You have used {used} of {limit} free daily operations. Resets at midnight UTC.",
                        "action": action,
                        "limit": limit,
                        "used": used,
                        "remaining": 0,
                        "resets_at_utc": self._next_reset_utc(),
                    },
                )

            new_count = used + 1
            self._counts[key] = new_count
            logger.info(f"[QuotaConsumed] User {user_id} used {action} ({new_count}/{limit})")

            return {
                "action": action,
                "limit": limit,
                "used": new_count,
                "remaining": max(0, limit - new_count),
                "resets_at_utc": self._next_reset_utc(),
            }

    def reset_for_testing(self):
        with self._lock:
            self._counts.clear()
            self._last_cleanup_date = ""

# Global singleton
quota_manager = DailyQuotaManager()
