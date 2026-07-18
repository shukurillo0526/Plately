from fastapi import APIRouter, Depends, HTTPException
from typing import Dict, Any, List
from app.db.supabase_client import get_supabase
from app.core.auth import CurrentUser

router = APIRouter(prefix="/challenges", tags=["Gamification Challenges"])

@router.get("/active")
async def get_active_challenges(user_id: str = Depends(CurrentUser)):
    db = await get_supabase()
    
    # 1. Fetch all active challenges
    challenges_resp = await db.table("challenges").select("*").execute()
    challenges = challenges_resp.data

    if not challenges:
        return {"status": "success", "challenges": []}

    # 2. Fetch user's progress for these challenges
    challenge_ids = [c["id"] for c in challenges]
    user_chal_resp = await db.table("user_challenges").select("*").eq("user_id", user_id).in_("challenge_id", challenge_ids).execute()
    
    user_chal_map = {uc["challenge_id"]: uc for uc in user_chal_resp.data}
    
    result = []
    for c in challenges:
        c_id = c["id"]
        uc = user_chal_map.get(c_id)
        
        c_data = {
            "id": c_id,
            "title": c["title"],
            "description": c["description"],
            "pillar": c["pillar"],
            "goal_target": c["goal_target"],
            "season": c["season"],
            "start_date": c["start_date"],
            "end_date": c["end_date"],
            "progress": uc["progress"] if uc else 0,
            "status": uc["status"] if uc else "unstarted"
        }
        result.append(c_data)

    return {"status": "success", "challenges": result}
