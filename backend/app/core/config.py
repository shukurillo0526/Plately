"""
Plately Backend — Application Configuration
=============================================
All settings are loaded from environment variables via pydantic-settings.
Create a `.env` file in the backend root with these keys.
"""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment / .env file."""

    # --- App ---
    APP_NAME: str = "Plately API"
    APP_VERSION: str = "0.1.9"
    DEBUG: bool = False
    LOG_LEVEL: str = "INFO"
    STRUCTURED_LOGS: bool = False  # True for production JSON logs

    # --- Supabase ---
    SUPABASE_URL: str = ""
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""

    # --- Clarifai ---
    CLARIFAI_API_KEY: str = ""
    CLARIFAI_FOOD_MODEL_ID: str = "food-item-recognition"

    # --- Vision thresholds ---
    VISION_THRESHOLD_AUTO: float = 0.90
    VISION_THRESHOLD_CONFIRM: float = 0.70

    # --- Recommendation engine weights (must sum to ~1.0) ---
    WEIGHT_EXPIRY: float = 0.25      # Waste reduction urgency
    WEIGHT_FLAVOR: float = 0.20      # Flavor affinity (cosine)
    WEIGHT_FAMILIAR: float = 0.10    # Comfort food boost
    WEIGHT_DIFFICULTY: float = 0.10  # Skill-level match
    WEIGHT_RECENCY: float = 0.10     # Variety (penalize recent)
    WEIGHT_COVERAGE: float = 0.25    # Ingredient match %

    # --- Server ---
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # --- Cloud AI Fallback (optional — set to enable auto-fallback) ---
    OPENAI_API_KEY: str = ""
    GEMINI_API_KEY: str = ""

    # --- Sentry (optional — set to enable crash reporting) ---
    SENTRY_DSN: str = ""

    # --- CORS (comma-separated origins; mobile apps ignore CORS) ---
    CORS_ORIGINS: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    def cors_origins_list(self) -> list[str]:
        """Return allowed browser origins. Localhost is included only in DEBUG."""
        origins: list[str] = [
            "https://app.theplately.com",
            "https://theplately.com",
            "https://shukurillo0526.github.io",
        ]
        if self.CORS_ORIGINS:
            origins.extend(
                origin.strip()
                for origin in self.CORS_ORIGINS.split(",")
                if origin.strip()
            )
        if self.DEBUG:
            origins.extend([
                "http://localhost:3000",
                "http://127.0.0.1:3000",
                "http://localhost:8080",
                "http://127.0.0.1:8080",
                "http://localhost:8000",
                "http://127.0.0.1:8000",
            ])
        # Preserve order while deduplicating
        return list(dict.fromkeys(origins))


@lru_cache()
def get_settings() -> Settings:
    """Cached settings singleton."""
    return Settings()
