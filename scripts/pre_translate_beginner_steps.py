"""
Plately — Pre-Translate Beginner Mode Steps
=============================================
Generates beginner-friendly step text for all 133 recipes using Gemini 2.5 Flash.
The beginner text breaks each step into micro-actions with technique guidance,
safety tips, and visual cues for new cooks.

Usage:
    python scripts/pre_translate_beginner_steps.py [--dry-run] [--limit N] [--lang CODE]

Flags:
    --dry-run   Preview prompts without calling the API
    --limit N   Process only N recipes
    --lang CODE Process only one language (en, uz, ru, ko, uz_Cyrl)
"""

import os
import sys
import json
import asyncio
import argparse
import time
import httpx
from dotenv import load_dotenv

sys.stdout.reconfigure(encoding='utf-8')

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "backend", ".env"))

from app.db.supabase_client import get_supabase

# ── Config ──────────────────────────────────────────────────────────
GEMINI_MODEL = "gemini-2.5-flash"
MAX_RPM = 14  # Gemini 2.5 Flash free tier: ~15 RPM
DELAY_BETWEEN_CALLS = 60.0 / MAX_RPM  # ~4.3 seconds between calls

LANGUAGE_NAMES = {
    "en": "English",
    "uz": "O'zbek (Uzbek, Latin)",
    "uz_Cyrl": "Ўзбек (Uzbek, Cyrillic)",
    "ru": "Русский (Russian)",
    "ko": "한국어 (Korean)",
}


def build_beginner_prompt(title: str, steps: list, lang_code: str = "en") -> str:
    """Build the Gemini prompt for generating beginner step text."""
    lang_name = LANGUAGE_NAMES.get(lang_code, "English")
    
    steps_text = ""
    for s in steps:
        num = s.get("step_number", "?")
        text = s.get("text", "")
        timer = s.get("timer_seconds")
        timer_note = f" (timer: {timer}s)" if timer else ""
        steps_text += f"\n  Step {num}: {text}{timer_note}"

    prompt = f"""You are a world-class cooking instructor helping COMPLETE BEGINNERS learn to cook.

**Recipe:** {title}
**Current steps:**{steps_text}

**Task:** For EACH step, write a beginner-friendly version that:
1. Breaks complex actions into small micro-steps
2. Explains technique (e.g., "fold gently means..." or "sauté means cook in hot oil while stirring")
3. Adds safety tips where relevant (e.g., "careful — the oil will splatter", "use oven mitts")
4. Includes visual/sensory cues (e.g., "cook until edges turn golden brown", "the onion should look translucent")
5. Keeps the same step numbering
6. Is written in {lang_name}

**Rules:**
- Keep timer_seconds values EXACTLY the same
- Do NOT change step_number values
- Write naturally, as if talking to a friend who has never cooked before
- Keep each step concise but informative (2-4 sentences max)

Return strictly valid JSON — an array of objects with EXACTLY these keys:
[
  {{"step_number": 1, "beginner_text": "..."}},
  {{"step_number": 2, "beginner_text": "..."}}
]"""

    return prompt


async def generate_beginner_steps(
    client: httpx.AsyncClient,
    api_key: str,
    title: str,
    steps: list,
    lang_code: str = "en",
    max_retries: int = 3,
) -> list:
    """Call Gemini 2.5 Flash to generate beginner step text with retry logic."""
    prompt = build_beginner_prompt(title, steps, lang_code)
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={api_key}"
    
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.7,
        },
    }

    for attempt in range(max_retries):
        try:
            resp = await client.post(url, json=payload, timeout=30.0)
            if resp.status_code in (503, 429, 500):
                wait = (attempt + 1) * 5
                print(f"(retry {attempt+1}, wait {wait}s)", end=" ", flush=True)
                await asyncio.sleep(wait)
                continue
            resp.raise_for_status()
            data = resp.json()
            
            raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
            
            # Clean potential markdown wrapping
            if raw_text.startswith("```json"):
                raw_text = raw_text.strip("```json").strip("```").strip()
            elif raw_text.startswith("```"):
                raw_text = raw_text.strip("```").strip()

            parsed = json.loads(raw_text)
            return parsed
        except (httpx.HTTPStatusError, httpx.ConnectError, httpx.ReadTimeout) as e:
            if attempt < max_retries - 1:
                wait = (attempt + 1) * 5
                print(f"(retry {attempt+1}, wait {wait}s)", end=" ", flush=True)
                await asyncio.sleep(wait)
            else:
                raise
    
    raise Exception(f"Failed after {max_retries} retries")


async def main():
    parser = argparse.ArgumentParser(description="Generate beginner step text for Plately recipes")
    parser.add_argument("--dry-run", action="store_true", help="Preview without API calls")
    parser.add_argument("--limit", type=int, default=0, help="Process only N recipes (0 = all)")
    parser.add_argument("--lang", type=str, default="all", help="Language code or 'all'")
    args = parser.parse_args()

    db = get_supabase()
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key and not args.dry_run:
        print("ERROR: GEMINI_API_KEY not set in .env")
        return

    # ── Phase 1: Add beginner_text to English steps (recipes table) ──
    print("=" * 60)
    print("Plately Beginner Mode Pre-Translation")
    print(f"Model: {GEMINI_MODEL}")
    print(f"Languages: {args.lang if args.lang != 'all' else ', '.join(LANGUAGE_NAMES.keys())}")
    print("=" * 60)

    recipes = db.table("recipes").select("id, title, steps").execute().data
    print(f"\nLoaded {len(recipes)} recipes from database")

    if args.limit > 0:
        recipes = recipes[: args.limit]
        print(f"  (limited to {args.limit} recipes)")

    # Filter recipes that already have beginner_text
    needs_english = []
    for r in recipes:
        steps = r.get("steps", [])
        has_beginner = any(s.get("beginner_text") for s in steps)
        if not has_beginner and steps:
            needs_english.append(r)

    print(f"  {len(needs_english)} recipes need English beginner text")
    print(f"  {len(recipes) - len(needs_english)} already have beginner text")

    if args.lang in ("en", "all"):
        total_api_calls = len(needs_english)
        est_time = total_api_calls * DELAY_BETWEEN_CALLS
        print(f"\nEstimated time for English: {est_time / 60:.1f} minutes ({total_api_calls} API calls)")

        if args.dry_run and needs_english:
            sample = needs_english[0]
            print("\n--- DRY RUN SAMPLE PROMPT ---")
            print(build_beginner_prompt(sample["title"], sample["steps"], "en"))
            print("--- END PROMPT ---\n")
        elif needs_english:
            async with httpx.AsyncClient() as client:
                for idx, recipe in enumerate(needs_english):
                    rid = recipe["id"]
                    title = recipe["title"]
                    steps = recipe["steps"]

                    print(f"  [{idx + 1}/{len(needs_english)}] {title}...", end=" ", flush=True)

                    try:
                        beginner_steps = await generate_beginner_steps(
                            client, api_key, title, steps, "en"
                        )

                        # Merge beginner_text into existing steps
                        beginner_map = {s["step_number"]: s["beginner_text"] for s in beginner_steps}
                        updated_steps = []
                        for step in steps:
                            step_copy = dict(step)
                            sn = step_copy.get("step_number")
                            if sn in beginner_map:
                                step_copy["beginner_text"] = beginner_map[sn]
                            updated_steps.append(step_copy)

                        # Update the recipe's steps JSONB
                        db.table("recipes").update({"steps": updated_steps}).eq("id", rid).execute()
                        print("OK")

                    except Exception as e:
                        print(f"FAILED: {e}")

                    await asyncio.sleep(DELAY_BETWEEN_CALLS)

    # ── Phase 2: Add beginner_text to translations ──────────────────
    if args.lang != "en":
        target_langs = (
            [args.lang] if args.lang != "all" else [k for k in LANGUAGE_NAMES if k != "en"]
        )

        for lang in target_langs:
            print(f"\n{'=' * 60}")
            print(f"Processing translations for: {lang} ({LANGUAGE_NAMES.get(lang, lang)})")
            print("=" * 60)

            translations = (
                db.table("recipe_translations")
                .select("recipe_id, language_code, steps, title")
                .eq("language_code", lang)
                .execute()
                .data
            )

            needs_beginner = []
            for tr in translations:
                steps = tr.get("steps", [])
                # Skip malformed translations (e.g. list of strings instead of dicts)
                if not isinstance(steps, list) or not steps:
                    continue
                if not all(isinstance(s, dict) for s in steps):
                    continue
                has_beginner = any(s.get("beginner_text") for s in steps)
                if not has_beginner:
                    needs_beginner.append(tr)

            if args.limit > 0:
                needs_beginner = needs_beginner[: args.limit]

            print(f"  {len(needs_beginner)} translations need beginner text")

            est_time = len(needs_beginner) * DELAY_BETWEEN_CALLS
            print(f"  Estimated time: {est_time / 60:.1f} minutes")

            if args.dry_run and needs_beginner:
                sample = needs_beginner[0]
                print("\n--- DRY RUN SAMPLE PROMPT ---")
                print(build_beginner_prompt(sample["title"], sample["steps"], lang))
                print("--- END PROMPT ---\n")
            elif needs_beginner:
                async with httpx.AsyncClient() as client:
                    for idx, tr in enumerate(needs_beginner):
                        rid = tr["recipe_id"]
                        title = tr["title"]
                        steps = tr["steps"]

                        print(
                            f"  [{idx + 1}/{len(needs_beginner)}] {title}...",
                            end=" ",
                            flush=True,
                        )

                        try:
                            beginner_steps = await generate_beginner_steps(
                                client, api_key, title, steps, lang
                            )

                            beginner_map = {
                                s["step_number"]: s["beginner_text"] for s in beginner_steps
                            }
                            updated_steps = []
                            for step in steps:
                                step_copy = dict(step)
                                sn = step_copy.get("step_number")
                                if sn in beginner_map:
                                    step_copy["beginner_text"] = beginner_map[sn]
                                updated_steps.append(step_copy)

                            # Update the translation's steps JSONB
                            (
                                db.table("recipe_translations")
                                .update({"steps": updated_steps})
                                .eq("recipe_id", rid)
                                .eq("language_code", lang)
                                .execute()
                            )
                            print("OK")

                        except Exception as e:
                            print(f"FAILED: {e}")

                        await asyncio.sleep(DELAY_BETWEEN_CALLS)

    print("\n" + "=" * 60)
    print("DONE! Beginner mode step text generation complete.")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
