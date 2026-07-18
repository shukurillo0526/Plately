import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from unittest.mock import AsyncMock, patch, MagicMock
from app.routers import analytics
from app.core.auth import CurrentUser

app = FastAPI()
app.include_router(analytics.router)

# Mock CurrentUser
async def mock_current_user():
    return "test-user-id"

app.dependency_overrides[CurrentUser] = mock_current_user

@pytest.fixture
def mock_db():
    with patch("app.routers.analytics.get_supabase", new_callable=AsyncMock) as mock_get_db, \
         patch("app.routers.analytics.GamificationEngine") as mock_engine_cls:
        db_instance = MagicMock()
        
        # Make chained calls return awaitable results
        insert_chain = db_instance.table.return_value.insert.return_value
        insert_chain.execute = AsyncMock(return_value=MagicMock(data=[]))
        
        mock_get_db.return_value = db_instance
        
        # Mock gamification engine
        mock_engine = MagicMock()
        mock_engine.process_event = AsyncMock(return_value={"xp_gained": 10, "badges": []})
        mock_engine_cls.return_value = mock_engine
        
        yield db_instance

def test_log_event(mock_db):
    client = TestClient(app)
    payload = {
        "event_name": "cook_session_completed",
        "properties": {"recipe_id": "123", "mode": "normal"}
    }
    
    response = client.post("/analytics/event", json=payload)
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "gamification" in data

def test_log_events_batch(mock_db):
    client = TestClient(app)
    payload = {
        "events": [
            {"event_name": "shelf_item_added", "properties": {"source": "scan"}},
            {"event_name": "shelf_item_consumed", "properties": {"is_expired": True, "thrown_out": False}},
            {"event_name": "meal_logged_auto", "properties": {}}
        ]
    }

    response = client.post("/analytics/events/batch", json=payload)
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["processed"] == 3
