"""Quick end-to-end test of the translation pipeline."""
import asyncio
import json
from app.db.supabase_client import get_supabase
from app.services.translation_service import translate_recipe


async def main():
    db = get_supabase()

    # Get one recipe
    r = db.table("recipes").select("id, title, ingredients, steps").limit(1).execute()
    if not r.data:
        print("No recipes found!")
        return

    recipe = r.data[0]
    title = recipe["title"]
    print(f"Testing with: {title}")

    # Test Uzbek translation (Tier 2, glossary-assisted)
    result = await translate_recipe(
        recipe_id=recipe["id"],
        title=title,
        ingredients=json.dumps(recipe["ingredients"][:4]),
        steps=json.dumps(recipe["steps"][:3]),
        target_language="uz",
    )

    print(f"Status: {result['status']}")
    print(f"Source: {result.get('source', 'n/a')}")

    if result.get("data"):
        d = result["data"]
        print(f"Title (uz): {d.get('title', '?')}")
        print(f"Short desc: {d.get('short_description', '?')}")
        ings = d.get("ingredients", [])
        print(f"Ingredients: {len(ings)} items")
        for ing in ings[:3]:
            if isinstance(ing, dict):
                print(f"  - {ing.get('name', '?')}")
        steps = d.get("steps", [])
        print(f"Steps: {len(steps)} items")
        for s in steps[:2]:
            if isinstance(s, dict):
                print(f"  {s.get('step_number', '?')}. {s.get('text', '?')[:80]}")

    # Verify it was cached
    cached = (
        db.table("recipe_translations")
        .select("*")
        .eq("recipe_id", recipe["id"])
        .eq("language_code", "uz")
        .maybe_single()
        .execute()
    )
    if cached and cached.data:
        print(f"\nCache verified: status={cached.data['translation_status']}, method={cached.data['translation_method']}")
    else:
        print("\nCache NOT found (unexpected)")


if __name__ == "__main__":
    asyncio.run(main())
