"""
Verification runner for 020_bulk_cooking_rpc_fix.
Verifies that process_meal_prep accepts the new p_container_label and p_storage_zone arguments.

To apply the SQL:
1. Go to https://supabase.com/dashboard
2. Open your project > SQL Editor
3. Paste contents of: migrations/020_bulk_cooking_rpc_fix.sql
4. Click Run
"""

import asyncio, sys
sys.path.insert(0, "d:/dev/projects/Plately/backend")
from app.db.supabase_client import get_supabase

async def verify_migration():
    db = await get_supabase()
    try:
        # We invoke process_meal_prep with invalid IDs just to check parameter validation/signature
        res = await db.rpc("process_meal_prep", {
            "p_user_id": "00000000-0000-4000-8000-000000000001",
            "p_recipe_id": "00000000-0000-4000-8000-000000000001",
            "p_recipe_title": "test signature",
            "p_portions_cooked": 4,
            "p_portions_eaten": 1,
            "p_ingredients": [],
            "p_cal_per_portion": 500,
            "p_protein_per_portion": 30,
            "p_carbs_per_portion": 40,
            "p_fat_per_portion": 15,
            "p_container_label": "Box",
            "p_storage_zone": "freezer"
        }).execute()
        print("✅ Migration 020 verified! process_meal_prep now supports container_label and storage_zone.")
        return True
    except Exception as e:
        err = str(e)
        if "Could not find the function" in err or "PGRST202" in err:
            print("❌ Old signature still active. Run the migration SQL first:")
            print("   1. Go to https://supabase.com/dashboard")
            print("   2. Open your project > SQL Editor")
            print("   3. Paste contents of: migrations/020_bulk_cooking_rpc_fix.sql")
            print("   4. Click Run")
        elif "foreign key constraint" in err or "23503" in err or "not present in table" in err:
            # Foreign key violation means the function signature matched and executed!
            print("✅ Migration 020 verified! process_meal_prep signature accepted container_label and storage_zone.")
            return True
        else:
            print(f"Verify output: {e}")
            if "23503" in err or "Key (parent_recipe_id)" in err:
                print("✅ Migration 020 verified! process_meal_prep signature accepted container_label and storage_zone.")
                return True
        return False

if __name__ == "__main__":
    asyncio.run(verify_migration())
