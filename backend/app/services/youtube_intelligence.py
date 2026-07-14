"""
Plately — YouTube Recipe Intelligence Service
================================================
Extracts structured recipe data from YouTube video descriptions
and titles using the local LLM. Works without YouTube Data API
by parsing the video page metadata directly.
"""

import logging
import re
from typing import Optional
from app.services.ai_service import get_ai_service as get_ollama_service

logger = logging.getLogger("plately.youtube_intelligence")


async def extract_recipe_from_youtube(
    video_title: str,
    video_description: str,
    channel_name: str = "",
) -> dict:
    """
    Use the LLM to extract a structured recipe from a YouTube
    video's title + description text.
    
    Returns a dict with recipe fields or {"error": "..."} on failure.
    """
    ollama = get_ollama_service()
    if not await ollama.is_available():
        return {"error": "AI service unavailable"}

    # Truncate description to avoid token overflow (keep first 2000 chars)
    desc_truncated = video_description[:2000] if video_description else ""

    prompt = f"""Extract a cooking recipe from this YouTube video metadata.

Video Title: {video_title}
Channel: {channel_name}
Description:
{desc_truncated}

If this video is NOT a cooking/recipe video, return: {{"is_recipe": false}}

If it IS a recipe, extract and return:
{{
  "is_recipe": true,
  "title": "Recipe name",
  "cuisine": "Korean/Italian/etc or Unknown",
  "difficulty": 1-3 (1=easy, 2=medium, 3=hard),
  "prep_time_minutes": 10,
  "cook_time_minutes": 20,
  "servings": 2,
  "ingredients": [
    {{"name": "ingredient name", "quantity": 1.5, "unit": "cups"}}
  ],
  "steps": [
    {{"step": 1, "text": "Step description", "timer_seconds": null}}
  ],
  "tags": ["quick", "healthy", "comfort food"],
  "estimated_calories": 350
}}

Rules:
- Extract EXACT quantities from the description when available
- If ingredients are listed but without quantities, estimate reasonable amounts
- Convert all measurements to metric when possible
- If steps aren't explicitly listed, infer them from the description/title
- Return ONLY valid JSON"""

    system = (
        "You are a professional chef and recipe extraction expert. "
        "Extract recipe data from YouTube video metadata accurately. "
        "Return only valid JSON."
    )

    result = await ollama.generate_text_json(prompt, system_prompt=system)
    
    # Validate the result has expected shape
    if isinstance(result, dict) and result.get("is_recipe") is False:
        return {"is_recipe": False, "reason": "Video does not appear to be a recipe"}
    
    if isinstance(result, dict) and result.get("is_recipe") is True:
        # Ensure required fields
        result.setdefault("title", video_title)
        result.setdefault("cuisine", "Unknown")
        result.setdefault("difficulty", 2)
        result.setdefault("ingredients", [])
        result.setdefault("steps", [])
        result.setdefault("tags", [])
        return result
    
    return result


def extract_youtube_id(url: str) -> Optional[str]:
    """Extract YouTube video ID from various URL formats."""
    patterns = [
        r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([a-zA-Z0-9_-]{11})',
        r'(?:youtube\.com/shorts/)([a-zA-Z0-9_-]{11})',
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None
