"""
Plately — Orders Router Unit & Integration Tests
=================================================
Tests order creation, validation, status updates, and code generation.
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routers import orders
from app.routers.orders import _generate_pickup_code, OrderItemCreate, CreateOrderRequest
from app.core.auth import get_current_user, AuthenticatedUser

app = FastAPI()
app.include_router(orders.router)

# Override get_current_user dependency
async def mock_get_current_user():
    return AuthenticatedUser(id="test-user-id", email="test@plately.app")

app.dependency_overrides[get_current_user] = mock_get_current_user


def test_generate_pickup_code():
    """Verify pickup code format and uniqueness."""
    code = _generate_pickup_code()
    assert len(code) == 6
    assert code.isalnum()
    assert code == code.upper()

    codes = {_generate_pickup_code() for _ in range(50)}
    assert len(codes) == 50  # High entropy test


def test_order_item_subtotal():
    """Verify OrderItem subtotal calculation."""
    item = OrderItemCreate(
        menu_item_id="item-1",
        name="Osh",
        price=45000.0,
        quantity=3,
    )
    assert item.subtotal == 135000.0


def test_create_order_request_validation():
    """Verify invalid order type is rejected by Pydantic validation."""
    with pytest.raises(Exception):
        CreateOrderRequest(
            user_id="test-user-id",
            restaurant_id="rest-1",
            type="invalid_type",
            items=[OrderItemCreate(menu_item_id="1", name="Plov", price=50000.0, quantity=1)],
        )


@patch("app.routers.orders.get_supabase")
def test_create_order_endpoint(mock_get_supabase):
    """Test successful order creation through the POST endpoint."""
    mock_db = MagicMock()
    mock_order_record = {
        "id": "ord-123456",
        "user_id": "test-user-id",
        "restaurant_id": "rest-1",
        "type": "pickup",
        "status": "confirmed",
        "total": 90000.0,
        "pickup_code": "AB12CD",
        "created_at": "2026-10-26T12:00:00Z",
    }

    # Setup Supabase chain: table("orders").insert(...).execute()
    insert_chain = mock_db.table.return_value.insert.return_value
    insert_chain.execute = AsyncMock(return_value=MagicMock(data=[mock_order_record]))
    mock_get_supabase.return_value = mock_db

    client = TestClient(app)
    payload = {
        "user_id": "test-user-id",
        "restaurant_id": "rest-1",
        "type": "pickup",
        "items": [
            {"menu_item_id": "item-1", "name": "Somsa", "price": 15000.0, "quantity": 2},
            {"menu_item_id": "item-2", "name": "Plov", "price": 60000.0, "quantity": 1},
        ],
        "customer_note": "Extra napkins",
    }

    response = client.post("/api/v1/orders", json=payload)
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["status"] == "success"
    assert res_data["data"]["id"] == "ord-123456"
    assert res_data["data"]["pickup_code"] == "AB12CD"


@patch("app.routers.orders.get_supabase")
@patch("app.routers.orders.verify_restaurant_owner")
@patch("app.routers.orders.get_order_or_404")
def test_update_order_status_endpoint(mock_get_order, mock_verify_owner, mock_get_supabase):
    """Test updating order status."""
    mock_get_order.return_value = {
        "id": "ord-123456",
        "restaurant_id": "rest-1",
        "status": "confirmed",
    }
    mock_verify_owner.return_value = None

    mock_db = MagicMock()
    updated_record = {
        "id": "ord-123456",
        "status": "preparing",
        "preparing_at": "2026-10-26T12:05:00Z",
    }
    update_chain = mock_db.table.return_value.update.return_value.eq.return_value
    update_chain.execute = AsyncMock(return_value=MagicMock(data=[updated_record]))
    mock_get_supabase.return_value = mock_db

    client = TestClient(app)
    response = client.patch(
        "/api/v1/orders/ord-123456/status",
        json={"status": "preparing"},
    )
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["status"] == "success"
    assert res_data["data"]["status"] == "preparing"
