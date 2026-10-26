"""
Plately — Social Router Unit Tests
===================================
Tests Cooking Squad creation, joining, invite code generation, and leaderboards.
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routers import social
from app.routers.social import generate_invite_code
from app.core.auth import CurrentUser

app = FastAPI()
app.include_router(social.router)

async def mock_current_user():
    return "test-user-id"

app.dependency_overrides[CurrentUser] = mock_current_user


def test_generate_invite_code():
    """Verify squad invite code format."""
    code = generate_invite_code()
    assert len(code) == 6
    assert code.isalnum()
    assert code == code.upper()


@patch("app.routers.social.get_supabase")
def test_create_squad(mock_get_supabase):
    """Test creating a new cooking squad."""
    mock_db = MagicMock()
    mock_squad = {
        "id": "sq-100",
        "name": "Tashkent Home Chefs",
        "invite_code": "CHEF99",
        "created_by": "test-user-id",
    }

    # squads insert
    insert_chain = mock_db.table.return_value.insert.return_value
    insert_chain.execute = AsyncMock(return_value=MagicMock(data=[mock_squad]))
    mock_get_supabase.return_value = mock_db

    client = TestClient(app)
    response = client.post("/social/squads/create", json={"name": "Tashkent Home Chefs"})
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["status"] == "success"
    assert res_data["squad"]["name"] == "Tashkent Home Chefs"


@patch("app.routers.social.get_supabase")
def test_join_squad_invalid_code(mock_get_supabase):
    """Test joining a squad with an invalid invite code returns 404."""
    mock_db = MagicMock()
    select_chain = mock_db.table.return_value.select.return_value.eq.return_value
    select_chain.execute = AsyncMock(return_value=MagicMock(data=[]))
    mock_get_supabase.return_value = mock_db

    client = TestClient(app)
    response = client.post("/social/squads/join", json={"invite_code": "INVALID"})
    assert response.status_code == 404
