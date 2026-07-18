from datetime import date, timedelta
from typing import Dict, Any, List

class GamificationEngine:
    def __init__(self, db_client):
        self.db = db_client

    async def process_event(self, user_id: str, event_name: str, properties: Dict[str, Any]) -> Dict[str, Any]:
        """
        Processes a single event and updates streaks/badges if applicable.
        Returns a dictionary containing any newly unlocked badges or updated streaks.
        """
        result = {
            "streaks_updated": [],
            "badges_unlocked": []
        }

        # 1. Fetch current gamification stats
        stats_response = await self.db.table("gamification_stats").select("*").eq("user_id", user_id).execute()
        if not stats_response.data:
            # Stats record might not exist yet, so we insert a default one
            await self.db.table("gamification_stats").insert({"user_id": user_id}).execute()
            stats = {"user_id": user_id}
        else:
            stats = stats_response.data[0]

        today_str = date.today().isoformat()
        yesterday_str = (date.today() - timedelta(days=1)).isoformat()

        # Update dict for DB
        updates = {}

        # Helper to process streaks
        async def process_streak(streak_type: str, last_date_field: str, current_streak_field: str, best_streak_field: str):
            last_date = stats.get(last_date_field)
            current_streak = stats.get(current_streak_field) or 0
            best_streak = stats.get(best_streak_field) or 0

            if last_date == today_str:
                return # Already updated today
            elif last_date == yesterday_str:
                # Extend streak
                current_streak += 1
            else:
                # Reset and start new streak
                current_streak = 1
            
            updates[last_date_field] = today_str
            updates[current_streak_field] = current_streak
            
            if current_streak > best_streak:
                updates[best_streak_field] = current_streak
                
            result["streaks_updated"].append({
                "type": streak_type,
                "current": current_streak,
                "best": max(current_streak, best_streak)
            })

        # --- Streaks Logic ---
        if event_name == "cook_session_completed":
            await process_streak("cooking", "last_cooking_date", "current_cooking_streak", "best_cooking_streak")
            
        elif event_name in ["shelf_item_consumed", "shelf_item_saved"]:
            # Let's say user explicitly saves an expiring item
            if properties.get("is_expired") == True and properties.get("thrown_out") == False:
                await process_streak("waste_saver", "last_waste_save_date", "current_waste_streak", "best_waste_streak")
                
        elif event_name in ["meal_logged_auto", "meal_logged_photo"]:
            await process_streak("health", "last_health_log_date", "current_health_streak", "best_health_streak")

        elif event_name in ["bulk_prep_session_completed", "bulk_prep_portions_stored"]:
            await process_streak("prep", "last_prep_date", "current_prep_streak", "best_prep_streak")

        # Apply DB updates if any streaks changed
        if updates:
            await self.db.table("gamification_stats").update(updates).eq("user_id", user_id).execute()

        # --- Badges Logic ---
        # Fetch existing user badges
        badges_response = await self.db.table("user_badges").select("badge_id").eq("user_id", user_id).execute()
        existing_badges = {b["badge_id"] for b in badges_response.data}
        
        new_badges = []

        async def grant_badge(badge_id: str):
            if badge_id not in existing_badges:
                new_badges.append({"user_id": user_id, "badge_id": badge_id})
                result["badges_unlocked"].append(badge_id)
                existing_badges.add(badge_id)

        # First Day Achievements (Core "Firsts")
        if event_name == "cook_session_completed":
            await grant_badge("first_cook")
        
        if event_name in ["shelf_item_consumed", "shelf_item_saved"] and properties.get("is_expired") == True and properties.get("thrown_out") == False:
            await grant_badge("fridge_guardian")
            
        if event_name in ["meal_logged_auto", "meal_logged_photo"]:
            await grant_badge("first_log")
            
        if event_name == "bulk_prep_portions_stored":
            portions = properties.get("count", 0)
            if portions >= 10:
                await grant_badge("week_in_boxes")
            else:
                await grant_badge("first_prep")

        # Insert new badges into DB
        if new_badges:
            await self.db.table("user_badges").insert(new_badges).execute()

            # Also update the legacy JSONB badges column in gamification_stats for backward compatibility
            # It expects a list of badge strings
            legacy_badges = list(existing_badges)
            await self.db.table("gamification_stats").update({"badges": legacy_badges}).eq("user_id", user_id).execute()

        # --- Challenges Logic ---
        result["challenges_completed"] = []
        result["challenges_progress"] = []

        # Map events to pillars and progress amounts
        progress_updates = {} # pillar -> amount
        
        if event_name == "cook_session_completed":
            progress_updates["cooking"] = 1
        elif event_name in ["shelf_item_consumed", "shelf_item_saved"] and properties.get("is_expired") == True and properties.get("thrown_out") == False:
            progress_updates["waste"] = 1
        elif event_name in ["meal_logged_auto", "meal_logged_photo"]:
            progress_updates["health"] = 1
        elif event_name == "bulk_prep_portions_stored":
            progress_updates["prep"] = properties.get("count", 1)
            
        if progress_updates:
            # Fetch active challenges for these pillars
            active_pillars = list(progress_updates.keys())
            challenges_resp = await self.db.table("challenges").select("id, pillar, goal_target, title").in_("pillar", active_pillars).execute()
            
            if challenges_resp.data:
                challenge_ids = [c["id"] for c in challenges_resp.data]
                
                # Fetch user's current progress on these challenges
                user_chal_resp = await self.db.table("user_challenges").select("id, challenge_id, progress, status").eq("user_id", user_id).in_("challenge_id", challenge_ids).eq("status", "active").execute()
                user_chal_map = {uc["challenge_id"]: uc for uc in user_chal_resp.data}
                
                for challenge in challenges_resp.data:
                    c_id = challenge["id"]
                    pillar = challenge["pillar"]
                    goal = challenge["goal_target"]
                    added_progress = progress_updates.get(pillar, 0)
                    
                    if added_progress > 0:
                        uc = user_chal_map.get(c_id)
                        if uc:
                            new_progress = uc["progress"] + added_progress
                            is_completed = new_progress >= goal
                            
                            update_data = {"progress": new_progress}
                            if is_completed:
                                update_data["status"] = "completed"
                                update_data["completed_at"] = today_str
                                result["challenges_completed"].append(challenge["title"])
                            else:
                                result["challenges_progress"].append({"title": challenge["title"], "progress": new_progress, "goal": goal})
                                
                            await self.db.table("user_challenges").update(update_data).eq("id", uc["id"]).execute()
                        else:
                            # Auto-enroll
                            new_progress = added_progress
                            is_completed = new_progress >= goal
                            
                            insert_data = {
                                "user_id": user_id,
                                "challenge_id": c_id,
                                "progress": new_progress,
                                "status": "completed" if is_completed else "active"
                            }
                            if is_completed:
                                insert_data["completed_at"] = today_str
                                result["challenges_completed"].append(challenge["title"])
                            else:
                                result["challenges_progress"].append({"title": challenge["title"], "progress": new_progress, "goal": goal})
                                
                            await self.db.table("user_challenges").insert(insert_data).execute()

        return result
