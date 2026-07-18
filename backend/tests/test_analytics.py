import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from unittest.mock import MagicMock, patch
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
    with patch("app.routers.analytics.get_supabase") as mock:
        db_instance = MagicMock()
        mock.return_value = db_instance
        yield db_instance

def test_log_event(mock_db):
    client = TestClient(app)
    payload = {
        "event_name": "cook_session_completed",
        "properties": {"recipe_id": "123", "mode": "normal"}
    }
    
    mock_db.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []
    
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
    
    mock_db.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

    response = client.post("/analytics/events/batch", json=payload)
    
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["processed"] == 3
