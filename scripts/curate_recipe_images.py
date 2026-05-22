"""
Plately — Recipe Image Curation via Pexels API
================================================
Fetches unique, high-quality food photography for all 133 recipes.
Uses Pexels API (200 req/hr free tier).

Usage:
    python scripts/curate_recipe_images.py [--dry-run] [--limit N]
"""

import os
import sys
import json
import asyncio
import argparse
import httpx
from dotenv import load_dotenv

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "backend", ".env"))

from app.db.supabase_client import get_supabase

PEXELS_API_KEY = "paPRnfnebm8gxDcvCuLwqGQOP0XpFUuezB3dNNm8NI0YYluwemvCAcd9"
PEXELS_SEARCH_URL = "https://api.pexels.com/v1/search"

# Track used photo IDs to avoid duplicates across recipes
used_photo_ids = set()


async def search_pexels(client: httpx.AsyncClient, query: str, per_page: int = 5) -> list:
    """Search Pexels for food photos matching the query."""
    headers = {"Authorization": PEXELS_API_KEY}
    params = {
        "query": query,
        "per_page": per_page,
        "orientation": "landscape",
    }
    resp = await client.get(PEXELS_SEARCH_URL, headers=headers, params=params, timeout=10.0)
    resp.raise_for_status()
    data = resp.json()
    return data.get("photos", [])


def pick_best_photo(photos: list) -> dict | None:
    """Pick the best unused photo from the search results."""
    for photo in photos:
        pid = photo["id"]
        if pid not in used_photo_ids:
            used_photo_ids.add(pid)
            return photo
    return None


def get_search_queries(title: str, cuisine: str) -> list[str]:
    """Generate search queries, from most specific to most generic."""
    queries = [
        f"{title} food",            # Most specific: "Chicken Nuggets food"
        title,                       # Just the title
    ]
    if cuisine:
        queries.append(f"{cuisine} {title.split()[0]} dish")  # "Korean Chicken dish"
    
    # Fallback: extract key food words
    food_words = []
    skip = {"with", "and", "on", "in", "the", "a", "of", "classic", "simple", "quick", "easy",
            "creamy", "crispy", "loaded", "one-pot", "baked", "grilled", "fried", "stuffed",
            "caramelized", "honey", "butter", "garlic", "soy", "spicy"}
    for word in title.split():
        w = word.strip("()").lower()
        if w not in skip and len(w) > 2:
            food_words.append(word)
    if food_words:
        queries.append(f"{' '.join(food_words[:2])} recipe")
    
    return queries


async def find_photo_for_recipe(
    client: httpx.AsyncClient, title: str, cuisine: str
) -> str | None:
    """Try multiple search queries to find a unique, relevant photo."""
    queries = get_search_queries(title, cuisine)
    
    for query in queries:
        try:
            photos = await search_pexels(client, query, per_page=5)
            photo = pick_best_photo(photos)
            if photo:
                # Use the "large" size (940px wide) — good balance of quality vs bandwidth
                url = photo["src"]["large"]
                return url
        except Exception as e:
            print(f"(search error: {e})", end=" ", flush=True)
    
    return None


async def main():
    parser = argparse.ArgumentParser(description="Curate recipe images from Pexels")
    parser.add_argument("--dry-run", action="store_true", help="Preview without updating DB")
    parser.add_argument("--limit", type=int, default=0, help="Process only N recipes")
    args = parser.parse_args()

    db = get_supabase()

    print("=" * 60)
    print("Plately Recipe Image Curation (Pexels API)")
    print("=" * 60)

    # Verify API key
    async with httpx.AsyncClient() as client:
        try:
            test = await search_pexels(client, "food", per_page=1)
            if test:
                print(f"API key verified OK (test photo: {test[0]['src']['tiny'][:50]}...)")
            else:
                print("ERROR: API key invalid or no results returned")
                return
        except Exception as e:
            print(f"ERROR: API key verification failed: {e}")
            return

    recipes = db.table("recipes").select("id, title, cuisine, image_url").execute().data
    print(f"\nLoaded {len(recipes)} recipes")

    if args.limit > 0:
        recipes = recipes[:args.limit]
        print(f"  (limited to {args.limit})")

    updated = 0
    failed = 0
    skipped = 0

    async with httpx.AsyncClient() as client:
        for idx, recipe in enumerate(recipes):
            rid = recipe["id"]
            title = recipe["title"]
            cuisine = recipe.get("cuisine", "")
            
            print(f"  [{idx+1}/{len(recipes)}] {title}...", end=" ", flush=True)

            new_url = await find_photo_for_recipe(client, title, cuisine)

            if new_url:
                if args.dry_run:
                    print(f"WOULD UPDATE -> {new_url[:60]}...")
                else:
                    try:
                        db.table("recipes").update({"image_url": new_url}).eq("id", rid).execute()
                        print("OK")
                        updated += 1
                    except Exception as e:
                        print(f"DB ERROR: {e}")
                        failed += 1
            else:
                print("NO PHOTO FOUND")
                failed += 1

            # Small delay to stay well within 200 req/hr limit
            # Each recipe uses 1-3 searches, so ~400 requests for 133 recipes
            # At 200/hr, we need ~0.5s delay per search = ~1.5s per recipe
            await asyncio.sleep(1.0)

    print(f"\n{'=' * 60}")
    print(f"DONE! Updated: {updated}, Failed: {failed}, Skipped: {skipped}")
    print(f"Unique photos used: {len(used_photo_ids)}")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
