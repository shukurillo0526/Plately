import os
import sys

sys.path.insert(0, r"d:\dev\projects\Plately\backend")
from dotenv import load_dotenv
load_dotenv(r"d:\dev\projects\Plately\backend\.env")

from app.db.supabase_client import get_supabase
db = get_supabase()

data = db.table("recipes").select("id, title, image_url, cuisine").execute().data
for i, r in enumerate(data[:30]):
    print(f"{i+1}. {r['title']} ({r['cuisine']}): {r['image_url']}")
