"""
Plately — Order Router
========================
REST API for the mobile ordering system.
Handles order creation, status updates, history, and cancellation.

Endpoints:
    POST   /api/v1/orders              — Place a new order
    GET    /api/v1/orders/{order_id}    — Get order by ID
    GET    /api/v1/orders/user/{user_id} — Get user's order history
    PATCH  /api/v1/orders/{order_id}/status — Update order status
    POST   /api/v1/orders/{order_id}/cancel — Cancel an order
    GET    /api/v1/orders/active/{user_id}  — Get active (non-completed) orders
"""

import logging
import random
import secrets
import string
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.core.auth import (
    CurrentUser,
    get_order_or_404,
    require_user_id,
    verify_order_customer,
    verify_restaurant_owner,
)
from app.core.security import raise_internal_error
from app.db.supabase_client import get_supabase
from app.models.api_response import api_success, api_error

logger = logging.getLogger("plately.orders")

router = APIRouter(prefix="/api/v1/orders", tags=["Orders"])


# ── Request / Response Models ─────────────────────────────────────

class OrderItemCreate(BaseModel):
    """A single item in an order."""
    menu_item_id: str
    name: str
    price: float
    quantity: int = 1
    special_instructions: Optional[str] = None

    @property
    def subtotal(self) -> float:
        return self.price * self.quantity


class CreateOrderRequest(BaseModel):
    """Request body for placing a new order."""
    user_id: str
    restaurant_id: str
    type: str = Field(default="pickup", pattern="^(pickup|delivery)$")
    items: list[OrderItemCreate]
    delivery_address: Optional[str] = None
    delivery_latitude: Optional[float] = None
    delivery_longitude: Optional[float] = None
    customer_note: Optional[str] = None


class UpdateStatusRequest(BaseModel):
    """Request body for updating order status."""
    status: str = Field(
        ...,
        pattern="^(confirmed|preparing|ready|picked_up|delivering|completed|cancelled)$"
    )


class CancelOrderRequest(BaseModel):
    """Request body for cancelling an order."""
    reason: Optional[str] = None


# ── Helpers ───────────────────────────────────────────────────────

def _generate_pickup_code() -> str:
    """Generate a secure 6-character alphanumeric pickup code like 'AB742X'."""
    alphabet = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(6))


# ── Endpoints ─────────────────────────────────────────────────────

@router.post("")
async def create_order(req: CreateOrderRequest, current: CurrentUser):
    """Place a new order.
    
    Creates the order in Supabase with a generated pickup code.
    Returns the full order object with ID and pickup code.
    """
    require_user_id(current, req.user_id)
    try:
        db = await get_supabase()

        # Calculate totals with server-side price verification
        items_data = []
        subtotal = 0.0
        for item in req.items:
            verified_price = item.price
            verified_name = item.name
            try:
                db_item = await (
                    db.table("menu_items")
                    .select("price, name")
                    .eq("id", item.menu_item_id)
                    .single()
                    .execute()
                )
                if db_item.data and "price" in db_item.data:
                    verified_price = float(db_item.data["price"])
                    verified_name = db_item.data.get("name", item.name)
            except Exception:
                pass

            item_subtotal = verified_price * item.quantity
            item_dict = {
                "menu_item_id": item.menu_item_id,
                "name": verified_name,
                "price": verified_price,
                "quantity": item.quantity,
                "special_instructions": item.special_instructions,
                "subtotal": item_subtotal,
            }
            items_data.append(item_dict)
            subtotal += item_subtotal

        # Get delivery fee from restaurant if delivery order
        delivery_fee = 0.0
        estimated_minutes = 20
        try:
            restaurant = await db.table("restaurants").select(
                "delivery_fee, avg_prep_minutes"
            ).eq("id", req.restaurant_id).single().execute()
            if restaurant.data:
                if req.type == "delivery":
                    delivery_fee = restaurant.data.get("delivery_fee", 0) or 0
                estimated_minutes = restaurant.data.get("avg_prep_minutes", 20) or 20
                if req.type == "delivery":
                    estimated_minutes += 15  # Add delivery time estimate
        except Exception:
            pass  # Use defaults if restaurant lookup fails

        total = subtotal + delivery_fee
        pickup_code = _generate_pickup_code()

        order_data = {
            "user_id": req.user_id,
            "restaurant_id": req.restaurant_id,
            "type": req.type,
            "status": "confirmed",
            "pickup_code": pickup_code,
            "items": items_data,
            "subtotal": subtotal,
            "delivery_fee": delivery_fee,
            "total": total,
            "estimated_minutes": estimated_minutes,
            "confirmed_at": datetime.now(timezone.utc).isoformat(),
            "delivery_address": req.delivery_address,
            "delivery_latitude": req.delivery_latitude,
            "delivery_longitude": req.delivery_longitude,
            "customer_note": req.customer_note,
        }

        result = await db.table("orders").insert(order_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create order")

        order = result.data[0]
        logger.info(
            f"Order created: {order['id']} | "
            f"Restaurant: {req.restaurant_id} | "
            f"Type: {req.type} | "
            f"Items: {len(req.items)} | "
            f"Total: {total} | "
            f"Pickup: {pickup_code}"
        )

        return api_success(
            data=order,
            message=f"Order placed! Pickup code: {pickup_code}",
        )

    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(logger, "Order creation failed", e)


@router.get("/{order_id}")
async def get_order(order_id: str, current: CurrentUser):
    """Get a specific order by ID."""
    try:
        db = await get_supabase()
        order = get_order_or_404(db, order_id)
        if str(order.get("user_id")) != current.id:
            verify_restaurant_owner(db, current, str(order["restaurant_id"]))
        return api_success(data=order)

    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(logger, "Get order failed", e)


@router.get("/user/{user_id}")
async def get_user_orders(
    user_id: str,
    current: CurrentUser,
    limit: int = 20,
    offset: int = 0,
):
    """Get a user's order history, newest first.
    
    Includes restaurant name via the get_user_orders RPC function.
    Falls back to direct query if RPC is not available.
    """
    require_user_id(current, user_id)
    try:
        db = await get_supabase()

        # Try RPC first (includes restaurant name via JOIN)
        try:
            result = await db.rpc("get_user_orders", {
                "p_user_id": user_id,
                "p_limit": limit,
                "p_offset": offset,
            }).execute()
            return api_success(data=result.data or [])
        except Exception:
            pass

        # Fallback: direct query
        result = await (
            db.table("orders")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )

        return api_success(data=result.data or [])

    except Exception as e:
        raise_internal_error(logger, "Get user orders failed", e)


@router.get("/active/{user_id}")
async def get_active_orders(user_id: str, current: CurrentUser):
    """Get user's active (non-completed, non-cancelled) orders."""
    require_user_id(current, user_id)
    try:
        db = await get_supabase()
        result = await (
            db.table("orders")
            .select("*")
            .eq("user_id", user_id)
            .not_.in_("status", ["completed", "cancelled"])
            .order("created_at", desc=True)
            .execute()
        )

        return api_success(data=result.data or [])

    except Exception as e:
        raise_internal_error(logger, "Get active orders failed", e)


@router.patch("/{order_id}/status")
async def update_order_status(order_id: str, req: UpdateStatusRequest, current: CurrentUser):
    """Update the status of an order.
    
    Used by restaurants (via Business dashboard) to advance order state:
    confirmed → preparing → ready → completed
    
    For delivery: ready → picked_up → delivering → completed
    """
    try:
        db = await get_supabase()
        order = get_order_or_404(db, order_id)
        verify_restaurant_owner(db, current, str(order["restaurant_id"]))

        # Build update data with timestamps
        update_data = {"status": req.status}
        now = datetime.now(timezone.utc).isoformat()

        if req.status == "ready":
            update_data["ready_at"] = now
        elif req.status == "completed":
            update_data["completed_at"] = now
        elif req.status == "cancelled":
            update_data["cancelled_at"] = now

        result = await (
            db.table("orders")
            .update(update_data)
            .eq("id", order_id)
            .execute()
        )

        if not result.data:
            raise HTTPException(status_code=404, detail="Order not found")

        logger.info(f"Order {order_id} status → {req.status}")
        return api_success(
            data=result.data[0],
            message=f"Order status updated to: {req.status}",
        )

    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(logger, "Update order status failed", e)


@router.post("/{order_id}/cancel")
async def cancel_order(order_id: str, req: CancelOrderRequest, current: CurrentUser):
    """Cancel an order.
    
    Only allows cancellation if the order is in 'confirmed' or 'preparing' status.
    """
    try:
        db = await get_supabase()
        order = get_order_or_404(db, order_id)
        verify_order_customer(current, order)
        current_status = order["status"]
        if current_status not in ("confirmed", "preparing"):
            raise HTTPException(
                status_code=400,
                detail=f"Cannot cancel order in '{current_status}' status. "
                       f"Only 'confirmed' or 'preparing' orders can be cancelled.",
            )

        result = await (
            db.table("orders")
            .update({
                "status": "cancelled",
                "cancelled_at": datetime.now(timezone.utc).isoformat(),
                "cancel_reason": req.reason,
            })
            .eq("id", order_id)
            .execute()
        )

        logger.info(f"Order {order_id} cancelled. Reason: {req.reason}")
        return api_success(
            data=result.data[0] if result.data else None,
            message="Order cancelled",
        )

    except HTTPException:
        raise
    except Exception as e:
        raise_internal_error(logger, "Cancel order failed", e)
