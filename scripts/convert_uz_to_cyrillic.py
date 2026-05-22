"""
Plately — Convert Uzbek Latin translations to Uzbek Cyrillic
=============================================================
Instead of generating separate Cyrillic translations via AI, this script
reads existing 'uz' translations and transliterates them to 'uz_Cyrl'
using the official Latin→Cyrillic mapping.

Usage:
    python scripts/convert_uz_to_cyrillic.py [--dry-run]
"""

import os
import sys
import json
import argparse

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(__file__), "..", "backend", ".env"))

from app.db.supabase_client import get_supabase


# ── Uzbek Latin → Cyrillic transliteration ────────────────────────

# Digraphs must be checked BEFORE single letters (order matters)
DIGRAPH_MAP = {
    "Sh": "Ш", "sh": "ш",
    "Ch": "Ч", "ch": "ч",
    "G'": "Ғ", "g'": "ғ",  # with apostrophe
    "Gʻ": "Ғ", "gʻ": "ғ",  # with modifier letter turned comma
    "G\u02BB": "Ғ", "g\u02BB": "ғ",  # unicode variant
    "O'": "Ў", "o'": "ў",
    "Oʻ": "Ў", "oʻ": "ў",
    "O\u02BB": "Ў", "o\u02BB": "ў",
    "Ng": "Нг", "ng": "нг",
    "Ye": "Е", "ye": "е",  # at start of word / after vowel
    "Yo": "Ё", "yo": "ё",
    "Yu": "Ю", "yu": "ю",
    "Ya": "Я", "ya": "я",
    "Ts": "Ц", "ts": "ц",
}

SINGLE_MAP = {
    "A": "А", "a": "а",
    "B": "Б", "b": "б",
    "D": "Д", "d": "д",
    "E": "Э", "e": "э",
    "F": "Ф", "f": "ф",
    "G": "Г", "g": "г",
    "H": "Ҳ", "h": "ҳ",
    "I": "И", "i": "и",
    "J": "Ж", "j": "ж",
    "K": "К", "k": "к",
    "L": "Л", "l": "л",
    "M": "М", "m": "м",
    "N": "Н", "n": "н",
    "O": "О", "o": "о",
    "P": "П", "p": "п",
    "Q": "Қ", "q": "қ",
    "R": "Р", "r": "р",
    "S": "С", "s": "с",
    "T": "Т", "t": "т",
    "U": "У", "u": "у",
    "V": "В", "v": "в",
    "X": "Х", "x": "х",
    "Y": "Й", "y": "й",
    "Z": "З", "z": "з",
}

# Sorted digraphs by length (longest first) for greedy matching
DIGRAPHS_SORTED = sorted(DIGRAPH_MAP.keys(), key=len, reverse=True)


def latin_to_cyrillic(text: str) -> str:
    """Convert Uzbek Latin text to Cyrillic."""
    if not text:
        return text

    result = []
    i = 0
    while i < len(text):
        matched = False
        # Try digraphs first (longest match)
        for digraph in DIGRAPHS_SORTED:
            if text[i:i+len(digraph)] == digraph:
                result.append(DIGRAPH_MAP[digraph])
                i += len(digraph)
                matched = True
                break
        if not matched:
            ch = text[i]
            if ch in SINGLE_MAP:
                result.append(SINGLE_MAP[ch])
            else:
                result.append(ch)  # Keep punctuation, numbers, spaces etc.
            i += 1
    return "".join(result)


def convert_steps(steps: list) -> list:
    """Convert all text fields in steps from Latin to Cyrillic."""
    converted = []
    for step in steps:
        new_step = dict(step)
        for field in ["text", "human_text", "beginner_text"]:
            if new_step.get(field):
                new_step[field] = latin_to_cyrillic(new_step[field])
        converted.append(new_step)
    return converted


def convert_ingredients(ingredients: list) -> list:
    """Convert ingredient text fields from Latin to Cyrillic."""
    if not ingredients:
        return ingredients
    converted = []
    for ing in ingredients:
        if isinstance(ing, dict):
            new_ing = dict(ing)
            for field in ["name", "prep_note", "unit"]:
                if new_ing.get(field) and isinstance(new_ing[field], str):
                    new_ing[field] = latin_to_cyrillic(new_ing[field])
            converted.append(new_ing)
        elif isinstance(ing, str):
            converted.append(latin_to_cyrillic(ing))
        else:
            converted.append(ing)
    return converted


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    db = get_supabase()

    print("=" * 60)
    print("Plately — Uzbek Latin → Cyrillic Conversion")
    print("=" * 60)

    # Get all uz translations
    uz_translations = (
        db.table("recipe_translations")
        .select("recipe_id, language_code, title, short_description, ingredients, steps")
        .eq("language_code", "uz")
        .execute()
        .data
    )
    print(f"\nFound {len(uz_translations)} Uzbek (Latin) translations")

    # Get existing uz_Cyrl translations
    existing_cyrl = (
        db.table("recipe_translations")
        .select("recipe_id")
        .eq("language_code", "uz_Cyrl")
        .execute()
        .data
    )
    existing_ids = {r["recipe_id"] for r in existing_cyrl}
    print(f"Found {len(existing_cyrl)} existing Uzbek (Cyrillic) translations")

    updated = 0
    created = 0
    skipped = 0

    for i, uz in enumerate(uz_translations):
        recipe_id = uz["recipe_id"]
        title_lat = uz.get("title") or ""
        desc_lat = uz.get("short_description") or ""
        ingredients_lat = uz.get("ingredients") or []
        steps_lat = uz.get("steps") or []

        # Convert
        title_cyrl = latin_to_cyrillic(title_lat)
        desc_cyrl = latin_to_cyrillic(desc_lat)
        ingredients_cyrl = convert_ingredients(ingredients_lat)
        steps_cyrl = convert_steps(steps_lat)

        status = ""
        if args.dry_run:
            status = "DRY-RUN"
        elif recipe_id in existing_ids:
            # Update existing
            db.table("recipe_translations").update({
                "title": title_cyrl,
                "short_description": desc_cyrl,
                "ingredients": ingredients_cyrl,
                "steps": steps_cyrl,
            }).eq("recipe_id", recipe_id).eq("language_code", "uz_Cyrl").execute()
            updated += 1
            status = "UPDATED"
        else:
            # Insert new
            db.table("recipe_translations").insert({
                "recipe_id": recipe_id,
                "language_code": "uz_Cyrl",
                "title": title_cyrl,
                "short_description": desc_cyrl,
                "ingredients": ingredients_cyrl,
                "steps": steps_cyrl,
            }).execute()
            created += 1
            status = "CREATED"

        print(f"  [{i+1}/{len(uz_translations)}] {title_lat[:40]}... → {title_cyrl[:40]}... {status}")

    print(f"\n{'=' * 60}")
    print(f"DONE! Updated: {updated}, Created: {created}, Skipped: {skipped}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
