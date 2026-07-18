from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime
from app.db.supabase_client import get_supabase
from app.core.auth import CurrentUser
from app.services.gamification_engine import GamificationEngine

router = APIRouter(prefix="/analytics", tags=["Analytics & Gamification"])

class AnalyticsEventCreate(BaseModel):
    event_name: str
    properties: Optional[Dict[str, Any]] = {}
    timestamp: Optional[datetime] = None

class EventBatch(BaseModel):
    events: List[AnalyticsEventCreate]

@router.post("/event")
async def log_event(event: AnalyticsEventCreate, user_id: str = Depends(CurrentUser)):
    db = await get_supabase()
    
    # 1. Save event to analytics_events
    try:
        await db.table("analytics_events").insert({
            "user_id": user_id,
            "event_name": event.event_name,
            "properties": event.properties,
            "created_at": event.timestamp.isoformat() if event.timestamp else datetime.utcnow().isoformat()
        }).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save event: {e}")

    # 2. Process gamification rules
    try:
        engine = GamificationEngine(db)
        gamification_result = await engine.process_event(user_id, event.event_name, event.properties)
        return {"status": "success", "gamification": gamification_result}
    except Exception as e:
        # Don't fail the event logging if gamification errors out
        return {"status": "success", "gamification_error": str(e)}

@router.post("/events/batch")
async def log_events_batch(batch: EventBatch, user_id: str = Depends(CurrentUser)):
    db = await get_supabase()
    
    events_data = [
        {
            "user_id": user_id,
            "event_name": e.event_name,
            "properties": e.properties,
            "created_at": e.timestamp.isoformat() if e.timestamp else datetime.utcnow().isoformat()
        } for e in batch.events
    ]
    
    try:
        await db.table("analytics_events").insert(events_data).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save events batch: {e}")

    engine = GamificationEngine(db)
    results = []
    for e in batch.events:
        try:
            res = await engine.process_event(user_id, e.event_name, e.properties)
            if res and (res.get("badges_unlocked") or res.get("streaks_updated")):
                results.append({"event": e.event_name, "gamification": res})
        except:
            pass

    return {"status": "success", "processed": len(batch.events), "gamification_results": results}

@router.get("/dashboard/retention")
async def get_retention_metrics():
    # Placeholder for dashboard metrics typically queried by internal admin tools
    return {"status": "success", "message": "Retention metrics (mock)"}

@router.get("/cohorts/gamification")
async def get_gamification_cohorts():
    db = await get_supabase()
    # Simple cohort breakdown based on XP / streaks
    # Engaged users (XP > 100 or level > 1) vs Unengaged users
    engaged_resp = await db.table("gamification_stats").select("user_id").gt("total_xp", 100).execute()
    unengaged_resp = await db.table("gamification_stats").select("user_id").lte("total_xp", 100).execute()
    
    return {
        "status": "success", 
        "cohorts": {
            "engaged_users_count": len(engaged_resp.data) if engaged_resp.data else 0,
            "unengaged_users_count": len(unengaged_resp.data) if unengaged_resp.data else 0
        }
    }

@router.get("/metrics/usage")
async def get_usage_metrics():
    db = await get_supabase()
    # Count total meals cooked, items saved, etc.
    # In a real app we'd group by month/week
    events_resp = await db.table("analytics_events").select("event_name").in_("event_name", ["cook_session_completed", "shelf_item_saved", "bulk_prep_session_completed"]).execute()
    
    metrics = {
        "cook_sessions": 0,
        "items_saved": 0,
        "prep_sessions": 0
    }
    
    if events_resp.data:
        for e in events_resp.data:
            name = e["event_name"]
            if name == "cook_session_completed":
                metrics["cook_sessions"] += 1
            elif name == "shelf_item_saved":
                metrics["items_saved"] += 1
            elif name == "bulk_prep_session_completed":
                metrics["prep_sessions"] += 1
                
    return {"status": "success", "metrics": metrics}
