import os
import sys

sys.path.insert(0, r"d:\dev\projects\Plately\backend")
from dotenv import load_dotenv
load_dotenv(r"d:\dev\projects\Plately\backend\.env")

from app.db.supabase_client import get_supabase
db = get_supabase()

tables_to_check = ["feedback", "recipe_feedback", "reports", "user_feedback", "recipe_reports"]
for t in tables_to_check:
    try:
        res = db.table(t).select("*").limit(1).execute()
        print(f"Table '{t}' exists! Data count: {len(res.data)}")
    except Exception as e:
        if "does not exist" in str(e) or "404" in str(e):
            print(f"Table '{t}' does not exist.")
        else:
            print(f"Table '{t}' query failed: {e}")
