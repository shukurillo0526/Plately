"""
Plately — Daily Fair-Use Quota Unit Tests
========================================
Validates that:
1. Daily quota defaults (3 scans, 2 recipe gens) are properly tracked.
2. Multiple calls increment usage and decrement remaining quota.
3. Exceeding the daily limit raises HTTP 429 Too Many Requests.
4. Quota status endpoint returns correct structure.
5. In-memory manager resets cleanly.
"""

import pytest
from fastapi import HTTPException, status
from app.core.quota import DailyQuotaManager, QuotaAction, DAILY_LIMITS

@pytest.fixture(autouse=True)
def fresh_quota_manager():
    manager = DailyQuotaManager()
    yield manager
    manager.reset_for_testing()


def test_initial_quota_status(fresh_quota_manager):
    user_id = "test-user-123"
    status_dict = fresh_quota_manager.get_status(user_id)

    assert QuotaAction.SCAN in status_dict
    assert QuotaAction.RECIPE_GEN in status_dict

    assert status_dict[QuotaAction.SCAN]["limit"] == 3
    assert status_dict[QuotaAction.SCAN]["used"] == 0
    assert status_dict[QuotaAction.SCAN]["remaining"] == 3

    assert status_dict[QuotaAction.RECIPE_GEN]["limit"] == 2
    assert status_dict[QuotaAction.RECIPE_GEN]["used"] == 0
    assert status_dict[QuotaAction.RECIPE_GEN]["remaining"] == 2


def test_consume_scan_quota_within_limit(fresh_quota_manager):
    user_id = "test-user-456"

    # Consume 1st scan
    res1 = fresh_quota_manager.consume(user_id, QuotaAction.SCAN)
    assert res1["used"] == 1
    assert res1["remaining"] == 2

    # Consume 2nd scan
    res2 = fresh_quota_manager.consume(user_id, QuotaAction.SCAN)
    assert res2["used"] == 2
    assert res2["remaining"] == 1

    # Consume 3rd scan
    res3 = fresh_quota_manager.consume(user_id, QuotaAction.SCAN)
    assert res3["used"] == 3
    assert res3["remaining"] == 0


def test_consume_scan_quota_exceeded_raises_429(fresh_quota_manager):
    user_id = "test-user-789"

    for _ in range(DAILY_LIMITS[QuotaAction.SCAN]):
        fresh_quota_manager.consume(user_id, QuotaAction.SCAN)

    # 4th attempt must fail with 429
    with pytest.raises(HTTPException) as exc_info:
        fresh_quota_manager.consume(user_id, QuotaAction.SCAN)

    assert exc_info.value.status_code == status.HTTP_429_TOO_MANY_REQUESTS
    assert exc_info.value.detail["error"] == "DAILY_QUOTA_EXCEEDED"
    assert exc_info.value.detail["action"] == QuotaAction.SCAN


def test_consume_recipe_gen_quota_exceeded_raises_429(fresh_quota_manager):
    user_id = "test-user-999"

    for _ in range(DAILY_LIMITS[QuotaAction.RECIPE_GEN]):
        fresh_quota_manager.consume(user_id, QuotaAction.RECIPE_GEN)

    # 3rd attempt must fail with 429
    with pytest.raises(HTTPException) as exc_info:
        fresh_quota_manager.consume(user_id, QuotaAction.RECIPE_GEN)

    assert exc_info.value.status_code == status.HTTP_429_TOO_MANY_REQUESTS
    assert exc_info.value.detail["error"] == "DAILY_QUOTA_EXCEEDED"
    assert exc_info.value.detail["action"] == QuotaAction.RECIPE_GEN


def test_independent_user_quotas(fresh_quota_manager):
    user_a = "user-alpha"
    user_b = "user-beta"

    fresh_quota_manager.consume(user_a, QuotaAction.SCAN)
    fresh_quota_manager.consume(user_a, QuotaAction.SCAN)

    status_a = fresh_quota_manager.get_status(user_a)
    status_b = fresh_quota_manager.get_status(user_b)

    assert status_a[QuotaAction.SCAN]["used"] == 2
    assert status_a[QuotaAction.SCAN]["remaining"] == 1

    assert status_b[QuotaAction.SCAN]["used"] == 0
    assert status_b[QuotaAction.SCAN]["remaining"] == 3
