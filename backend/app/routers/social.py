from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, List
import random
import string
from app.db.supabase_client import get_supabase
from app.core.auth import CurrentUser

router = APIRouter(prefix="/social", tags=["Social Squads"])

def generate_invite_code(length=6):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))

class CreateSquadRequest(BaseModel):
    name: str

class JoinSquadRequest(BaseModel):
    invite_code: str

@router.post("/squads/create")
async def create_squad(req: CreateSquadRequest, user_id: str = Depends(CurrentUser)):
    db = await get_supabase()
    
    invite_code = generate_invite_code()
    
    try:
        # Create squad
        squad_resp = await db.table("squads").insert({
            "name": req.name,
            "invite_code": invite_code,
            "created_by": user_id
        }).execute()
        squad = squad_resp.data[0]
        
        # Add creator as owner
        await db.table("squad_members").insert({
            "squad_id": squad["id"],
            "user_id": user_id,
            "role": "owner"
        }).execute()
        
        return {"status": "success", "squad": squad}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/squads/join")
async def join_squad(req: JoinSquadRequest, user_id: str = Depends(CurrentUser)):
    db = await get_supabase()
    
    # Find squad
    squad_resp = await db.table("squads").select("*").eq("invite_code", req.invite_code.upper()).execute()
    if not squad_resp.data:
        raise HTTPException(status_code=404, detail="Invalid invite code.")
    
    squad = squad_resp.data[0]
    
    # Check if already member
    member_resp = await db.table("squad_members").select("*").eq("squad_id", squad["id"]).eq("user_id", user_id).execute()
    if member_resp.data:
        raise HTTPException(status_code=400, detail="Already a member of this squad.")
    
    # Join squad
    try:
        await db.table("squad_members").insert({
            "squad_id": squad["id"],
            "user_id": user_id,
            "role": "member"
        }).execute()
        return {"status": "success", "squad": squad}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/squads/{squad_id}/leaderboard")
async def get_squad_leaderboard(squad_id: str, user_id: str = Depends(CurrentUser)):
    db = await get_supabase()
    
    # Verify user is in squad
    member_resp = await db.table("squad_members").select("*").eq("squad_id", squad_id).eq("user_id", user_id).execute()
    if not member_resp.data:
        raise HTTPException(status_code=403, detail="Not a member of this squad.")
    
    # Fetch from optimized view
    leaderboard_resp = await db.table("v_squad_leaderboard").select("*").eq("squad_id", squad_id).order("total_xp", desc=True).execute()
    
    return {"status": "success", "leaderboard": leaderboard_resp.data or []}

@router.get("/squads/my")
async def get_my_squads(user_id: str = Depends(CurrentUser)):
    db = await get_supabase()
    
    memberships = await db.table("squad_members").select("squad_id").eq("user_id", user_id).execute()
    if not memberships.data:
        return {"status": "success", "squads": []}
        
    squad_ids = [m["squad_id"] for m in memberships.data]
    squads_resp = await db.table("squads").select("*").in_("id", squad_ids).execute()
    
    return {"status": "success", "squads": squads_resp.data}
