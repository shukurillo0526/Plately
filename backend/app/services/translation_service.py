"""
Plately — Recipe Translation Service
=======================================
Multi-tier translation pipeline with cache-first strategy,
glossary-assisted prompts for low-resource languages (Uzbek),
and cloud AI preference for translation quality.

Flow: Cache check → Pending lock → Tier detection → AI call → Save
"""

import json
import logging
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional, Dict, Any

from app.db.supabase_client import get_supabase
from app.services.ai_service import get_ai_service as get_ollama_service

logger = logging.getLogger("plately.translation")

# ── Language Configuration ──────────────────────────────────────────

LANGUAGE_CONFIG = {
    # Tier 1: High-resource — direct AI translation works well
    "ru": {"tier": 1, "method": "ai_direct",   "name": "Russian"},
    "ko": {"tier": 1, "method": "ai_direct",   "name": "Korean"},
    "es": {"tier": 1, "method": "ai_direct",   "name": "Spanish"},
    "fr": {"tier": 1, "method": "ai_direct",   "name": "French"},
    "de": {"tier": 1, "method": "ai_direct",   "name": "German"},
    "ja": {"tier": 1, "method": "ai_direct",   "name": "Japanese"},
    "zh": {"tier": 1, "method": "ai_direct",   "name": "Chinese"},
    "ar": {"tier": 1, "method": "ai_direct",   "name": "Arabic"},
    "tr": {"tier": 1, "method": "ai_direct",   "name": "Turkish"},
    "hi": {"tier": 1, "method": "ai_direct",   "name": "Hindi"},

    # Tier 2: Low-resource — needs glossary-assisted prompt
    "uz": {"tier": 2, "method": "ai_glossary", "name": "Uzbek"},
    "tg": {"tier": 2, "method": "ai_glossary", "name": "Tajik"},
    "kk": {"tier": 2, "method": "ai_glossary", "name": "Kazakh"},
    "ky": {"tier": 2, "method": "ai_glossary", "name": "Kyrgyz"},
}

GLOSSARY_DIR = Path(__file__).parent.parent.parent / "data"
RETRY_DELAY_MINUTES = 30

# ── Glossary Loading ────────────────────────────────────────────────

_glossary_cache: Dict[str, dict] = {}


def load_glossary(lang_code: str) -> Optional[dict]:
    """Load a cooking glossary for a language. Cached in memory."""
    if lang_code in _glossary_cache:
        return _glossary_cache[lang_code]

    path = GLOSSARY_DIR / f"glossary_{lang_code}.json"
    if not path.exists():
        logger.warning(f"[Translation] No glossary file for '{lang_code}' at {path}")
        return None

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        _glossary_cache[lang_code] = data
        logger.info(f"[Translation] Loaded glossary for '{lang_code}' v{data.get('meta', {}).get('version', '?')}")
        return data
    except Exception as e:
        logger.error(f"[Translation] Failed to load glossary for '{lang_code}': {e}")
        return None


def get_lang_config(lang_code: str) -> dict:
    """Get config for a language, defaulting to Tier 1 direct translation."""
    return LANGUAGE_CONFIG.get(lang_code, {"tier": 1, "method": "ai_direct", "name": lang_code})


# ── Prompt Builders ─────────────────────────────────────────────────

JSON_FORMAT = """{{"title":"...","short_description":"... (max 15 words)","ingredients":[{{"name":"...","quantity":1,"unit":"...","prep_note":"..."}}],"steps":[{{"step_number":1,"text":"...","timer_seconds":null}}]}}"""


def build_direct_prompt(title: str, ingredients: str, steps: str, lang_name: str) -> str:
    """Build a translation prompt for high-resource languages."""
    return f"""Translate this cooking recipe into natural {lang_name}.
Make instructions clear, warm, and easy to follow.
Keep all measurements exactly the same (grams, ml, spoons, etc.).
Keep step numbers intact.

Title: {title}

Ingredients:
{ingredients}

Steps:
{steps}

Return ONLY valid JSON in this exact format:
{JSON_FORMAT}"""


def build_glossary_prompt(title: str, ingredients: str, steps: str, lang_name: str, glossary: dict) -> str:
    """Build a glossary-assisted prompt for low-resource languages."""
    glossary_text = ""
    for category, terms in glossary.items():
        if category == "meta":
            continue
        glossary_text += f"\n{category.upper()}:\n"
        for eng, native in terms.items():
            glossary_text += f"  {eng} → {native}\n"

    return f"""You are a professional Uzbek chef and mother who has been cooking traditional and modern meals for 30 years. Your job is to translate the following recipe from English into natural, warm, and easy-to-understand {lang_name} language.

Translate as if you are explaining it to your daughter or close friend in the kitchen. Use natural spoken {lang_name} that real people actually use when cooking.

REFERENCE GLOSSARY (use these exact terms when applicable):
{glossary_text}

RULES:
- NEVER translate word by word.
- USE the glossary terms above — they are the correct {lang_name} cooking vocabulary.
- If a term is NOT in the glossary, use your best natural {lang_name}.
- Keep all measurements EXACTLY the same (grams, milliliters, spoons, etc.).
- Keep step numbers intact.
- Make it sound like a real person speaking, not a robot.
- Use friendly and natural sentence structure.

RECIPE TO TRANSLATE:

Title: {title}

Ingredients:
{ingredients}

Steps:
{steps}

Return ONLY valid JSON in this exact format:
{JSON_FORMAT}"""


def build_batch_titles_prompt(titles: list, lang_name: str) -> str:
    """Build a prompt to translate multiple recipe titles in one call."""
    items = "\n".join([
        f'- ID:{t["id"]} | Title: {t["title"]} | Desc: {(t.get("description") or "")[:80]}'
        for t in titles
    ])
    return f"""Translate these recipe titles and write a short description (max 15 words each) in natural {lang_name}.

{items}

Return ONLY a valid JSON array:
[{{"id":"...","title":"translated title","short_description":"translated short desc"}}]"""


# ── AI Call Routing ─────────────────────────────────────────────────

TRANSLATION_SYSTEM_PROMPT = "You are a professional recipe translator. Return only valid JSON. No markdown, no explanation."


async def call_translation_ai(prompt: str, model: str = "gemini-2.5-flash") -> dict:
    """
    Call the best available AI for translation.
    Priority: Gemini 2.5 Pro/Flash → OpenAI → Local Ollama
    Translation quality matters more than speed since results are cached forever.
    """
    # Try cloud AI first (better quality for translations)
    try:
        from app.services.cloud_ai_service import get_cloud_ai_service
        cloud = get_cloud_ai_service()
        if cloud.is_configured:
            logger.info(f"[Translation] Using cloud AI ({cloud.provider}, model={model}) for translation")
            raw = await cloud.generate_text(
                prompt,
                system_prompt=TRANSLATION_SYSTEM_PROMPT,
                temperature=0.2,
                max_tokens=4096,
                format="json",
                model=model,
            )
            return _parse_json(raw)
    except Exception as e:
        logger.warning(f"[Translation] Cloud AI failed, falling back to Ollama: {e}")

    # Fallback to local Ollama
    ollama = get_ollama_service()
    if await ollama.is_available():
        logger.info("[Translation] Using local Ollama for translation")
        return await ollama.generate_text_json(
            prompt,
            system_prompt=TRANSLATION_SYSTEM_PROMPT,
            max_tokens=4096,
        )

    raise RuntimeError("No AI provider available for translation")


def _parse_json(raw: str) -> dict:
    """Parse JSON from raw AI response, handling code fences."""
    text = raw.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        text = "\n".join(lines[1:])
        if text.rstrip().endswith("```"):
            text = text.rstrip()[:-3]
        text = text.strip()

    try:
        result = json.loads(text)
        if isinstance(result, list):
            return {"items": result}
        return result
    except json.JSONDecodeError:
        pass

    # Try extracting JSON object
    start = text.find("{")
    end = text.rfind("}") + 1
    if start >= 0 and end > start:
        try:
            return json.loads(text[start:end])
        except json.JSONDecodeError:
            pass

    # Try extracting JSON array
    start = text.find("[")
    end = text.rfind("]") + 1
    if start >= 0 and end > start:
        try:
            result = json.loads(text[start:end])
            return {"items": result} if isinstance(result, list) else result
        except json.JSONDecodeError:
            pass

    raise ValueError(f"Failed to parse JSON from AI response: {text[:200]}")


# ── Main Translation Functions ──────────────────────────────────────

async def translate_recipe(
    recipe_id: str,
    title: str,
    ingredients: str,
    steps: str,
    target_language: str,
) -> dict:
    """
    Full recipe translation with cache-first strategy.

    Flow:
    1. Check cache → return if completed
    2. Claim pending lock → prevent duplicate AI calls
    3. Detect language tier → build appropriate prompt
    4. Call AI → parse result
    5. Save to DB → return translation
    """
    db = get_supabase()
    lang_config = get_lang_config(target_language)

    # ── Step 1: Check cache ──
    try:
        cached = (
            db.table("recipe_translations")
            .select("*")
            .eq("recipe_id", recipe_id)
            .eq("language_code", target_language)
            .maybe_single()
            .execute()
        )
        if cached and cached.data:
            status = cached.data["translation_status"]

            if status == "completed":
                logger.info(f"[Translation] Cache hit for {recipe_id}/{target_language}")
                return {
                    "status": "success",
                    "source": "cache",
                    "data": {
                        "title": cached.data["title"],
                        "short_description": cached.data.get("short_description"),
                        "ingredients": cached.data["ingredients"],
                        "steps": cached.data["steps"],
                    },
                }

            if status == "pending":
                logger.info(f"[Translation] Already pending for {recipe_id}/{target_language}")
                return {"status": "in_progress", "message": "Translation is being processed"}

            if status == "failed":
                retry_after = cached.data.get("retry_after")
                if retry_after:
                    retry_dt = datetime.fromisoformat(retry_after.replace("Z", "+00:00")) if isinstance(retry_after, str) else retry_after
                    if datetime.now(timezone.utc) < retry_dt:
                        return {
                            "status": "failed",
                            "message": "Translation failed, retry later",
                            "retry_after": str(retry_after),
                        }
    except Exception as e:
        logger.warning(f"[Translation] Cache check error: {e}")

    # ── Step 2: Claim lock ──
    try:
        db.table("recipe_translations").upsert({
            "recipe_id": recipe_id,
            "language_code": target_language,
            "title": title,
            "ingredients": [],
            "steps": [],
            "translation_status": "pending",
            "translation_method": lang_config["method"],
        }).execute()
    except Exception as e:
        logger.warning(f"[Translation] Lock claim error: {e}")

    # ── Step 3: Build prompt ──
    method = lang_config["method"]
    target_model = "gemini-2.5-pro" if lang_config["tier"] == 2 else "gemini-2.5-flash"
    
    if method == "ai_glossary":
        glossary = load_glossary(target_language)
        if glossary:
            prompt = build_glossary_prompt(title, ingredients, steps, lang_config["name"], glossary)
        else:
            prompt = build_direct_prompt(title, ingredients, steps, lang_config["name"])
            method = "ai_direct"
    else:
        prompt = build_direct_prompt(title, ingredients, steps, lang_config["name"])

    # ── Step 4: Call AI ──
    try:
        result = await call_translation_ai(prompt, model=target_model)

        if "error" in result:
            raise ValueError(result.get("raw_response", "AI returned invalid JSON"))

        # ── Step 5: Save success ──
        translation_data = {
            "recipe_id": recipe_id,
            "language_code": target_language,
            "title": result.get("title", title),
            "short_description": result.get("short_description", ""),
            "ingredients": result.get("ingredients", []),
            "steps": result.get("steps", []),
            "translation_status": "completed",
            "translation_method": method,
            "translated_at": datetime.now(timezone.utc).isoformat(),
            "retry_after": None,
        }
        db.table("recipe_translations").upsert(translation_data).execute()

        logger.info(f"[Translation] Completed {recipe_id}/{target_language} via {method}")

        return {
            "status": "success",
            "source": f"ai_{method}",
            "data": {
                "title": translation_data["title"],
                "short_description": translation_data["short_description"],
                "ingredients": translation_data["ingredients"],
                "steps": translation_data["steps"],
            },
        }

    except Exception as e:
        logger.error(f"[Translation] Failed for {recipe_id}/{target_language}: {e}")
        # Save failure with retry delay
        try:
            db.table("recipe_translations").upsert({
                "recipe_id": recipe_id,
                "language_code": target_language,
                "title": title,
                "ingredients": [],
                "steps": [],
                "translation_status": "failed",
                "translation_method": method,
                "retry_after": (datetime.now(timezone.utc) + timedelta(minutes=RETRY_DELAY_MINUTES)).isoformat(),
            }).execute()
        except Exception as save_err:
            logger.error(f"[Translation] Failed to save failure state: {save_err}")

        return {
            "status": "error",
            "message": f"Translation failed: {str(e)}",
        }


async def translate_titles_batch(
    recipe_ids: list,
    target_language: str,
) -> dict:
    """
    Batch-translate recipe titles for list view.
    Single AI call for up to 20 recipes.
    """
    db = get_supabase()
    lang_config = get_lang_config(target_language)

    # 1. Check which are already cached
    try:
        cached = (
            db.table("recipe_translations")
            .select("recipe_id, title, short_description")
            .in_("recipe_id", recipe_ids)
            .eq("language_code", target_language)
            .eq("translation_status", "completed")
            .execute()
        )
        cached_map = {r["recipe_id"]: r for r in (cached.data or [])}
    except Exception:
        cached_map = {}

    missing_ids = [rid for rid in recipe_ids if rid not in cached_map]

    if not missing_ids:
        return {"status": "success", "data": cached_map}

    # 2. Fetch English titles for missing recipes
    try:
        recipes = (
            db.table("recipes")
            .select("id, title, description")
            .in_("id", missing_ids)
            .execute()
        )
        titles_to_translate = [
            {"id": r["id"], "title": r["title"], "description": r.get("description", "")}
            for r in (recipes.data or [])
        ]
    except Exception as e:
        logger.error(f"[Translation] Failed to fetch recipes for batch: {e}")
        return {"status": "error", "data": cached_map}

    if not titles_to_translate:
        return {"status": "success", "data": cached_map}

    # 3. Single AI call for all missing titles
    prompt = build_batch_titles_prompt(titles_to_translate, lang_config["name"])
    target_model = "gemini-2.5-pro" if lang_config["tier"] == 2 else "gemini-2.5-flash"

    try:
        result = await call_translation_ai(prompt, model=target_model)
        items = result.get("items", [result] if "title" in result else [])

        # 4. Save each and merge into result
        for item in items:
            rid = item.get("id", "")
            if not rid:
                continue
            try:
                db.table("recipe_translations").upsert({
                    "recipe_id": rid,
                    "language_code": target_language,
                    "title": item.get("title", ""),
                    "short_description": item.get("short_description", ""),
                    "ingredients": [],
                    "steps": [],
                    "translation_method": lang_config["method"],
                    "translation_status": "partial",
                }).execute()
            except Exception as e:
                logger.warning(f"[Translation] Failed to save batch title for {rid}: {e}")

            cached_map[rid] = {
                "recipe_id": rid,
                "title": item.get("title", ""),
                "short_description": item.get("short_description", ""),
            }

        return {"status": "success", "data": cached_map}

    except Exception as e:
        logger.error(f"[Translation] Batch title translation failed: {e}")
        return {"status": "partial", "data": cached_map, "error": str(e)}


async def rate_translation(
    recipe_id: str,
    language_code: str,
    score: float,
) -> dict:
    """Record user quality feedback for a translation (0.0 = bad, 1.0 = good)."""
    db = get_supabase()
    try:
        db.table("recipe_translations").update({
            "quality_score": max(0.0, min(1.0, score)),
        }).eq("recipe_id", recipe_id).eq("language_code", language_code).execute()

        # If score is very low, mark for re-translation
        if score <= 0.3:
            db.table("recipe_translations").update({
                "translation_status": "failed",
                "retry_after": None,  # Allow immediate retry
            }).eq("recipe_id", recipe_id).eq("language_code", language_code).execute()
            logger.info(f"[Translation] Marked {recipe_id}/{language_code} for re-translation (score={score})")

        return {"status": "success", "message": "Feedback recorded"}
    except Exception as e:
        logger.error(f"[Translation] Failed to save feedback: {e}")
        return {"status": "error", "message": str(e)}
