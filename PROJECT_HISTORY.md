# I-Fridge: Project History & Vision Alignment

This document tracks the development history of **I-Fridge**—an ambitious smart-kitchen ecosystem capable of tracking physical inventory and recommending hyper-personalized recipes.

## 🌟 The Core Vision & Pivot

Originally conceived with robotic hardware integrations in mind, I-Fridge has **pivoted to focus entirely on a premium consumer app experience**. We realized that before automating physical cooking, the core user experience of managing ingredients and finding the perfect recipe needs to be flawlessly executed.

The master plan for I-Fridge encompasses:
1. **Living Shelf:** A digital representation of a real shelf/fridge showing available ingredients with freshness tracking.
2. **Social-Style Recommendations:** Replacing clinical filters with engaging feeds (For You, Use It Up, Explore) powered by intelligent match algorithms.
3. **Frictionless Ingestion:** Making it incredibly easy to add items via parsing grocery receipts and analyzing photos of loose ingredients using AI Vision.
4. **Human-First Cooking:** Providing distraction-free, interactive step-by-step tutorials with inline timers and contextual guidance.

---

## 🏗️ What We Have Built (The Consumer Pivot - Phases 1-7)

We have successfully completed the 7-phase consumer pivot, resulting in a polished, AI-powered MVP that is fully deployed as a responsive Web Application via GitHub Pages.

### Phase 1: Existing UI/UX Polish & Functional Fixes
- Audited all current screens (Shelf, Scan, Cook, Profile).
- Removed dead-end settings and broken placeholders to ensure a clean, functional UI.
- Enhanced empty states and loading indicators using Shimmer skeleton screens.

### Phase 2: Ingredient Adding & Expiry Intelligence
- **Advanced Manual Entry:** Upgraded the Scan screen's manual entry with a highly-responsive Supabase **Autocomplete** functionality. Upon selecting a Google-like suggestion, it automatically infers category and metric type.
- **Smart Expiry Engine:** Implemented a robust offline fallback system that algorithmically assigns Estimated Expiry Dates based purely on the selected ingredient category natively in Dart.
- **OCR Receipt Parsing:** Built a FastAPI backend integrating Google Gemini 1.5 Flash. Tuned the prompt specifically for complex Korean grocery receipts (e.g., 진안식자재마트), successfully extracting items, sizes, origin markers, and tax-exempt tags.
- **Direct Photo Scan Logic:** Completely separated the UI logic so receipt parsing and direct photo ingredient detection (loose items on a counter) use dedicated APIs, eliminating cross-contamination of display metrics.

### Phase 3: Social-Style Recommendation Algorithm
- Rebranded the rigid 5-tier matching system into engaging social-style feeds:
  - **Perfect Match** (✅ Everything you need!)
  - **For You** (🔥 Recommended for you)
  - **Use It Up** (⏰ Use expiring items)
  - **Almost** (🛒 Just a few items away)
  - **Explore** (🌍 Discover something new)
- Added contextual recommendation badges to recipe cards.

### Phase 4: Data Pipeline & Knowledge Base
- Developed an ETL pipeline (`etl_foodcom.py`) to flawlessly map large-scale recipe datasets into the strict Supabase schema.
- Structured barcode lookup routers for automated Open Food Facts enrichment.

### Phase 5: Direct Photo Ingredient Detection
- Created a new `/api/v1/vision/detect-ingredients` FastAPI endpoint.
- Tuned a Gemini Vision prompt to analyze photos of loose ingredients on a counter, estimating name, quantity, category, confidence, and visual *freshness*.

### Phase 6: Human-First "Cook Mode" Tutorial
- **Removed Robot Actions:** Stripped out all legacy robot chef JSON payloads and terminology.
- **Interactive UI:** Redesigned `CookingRunScreen` into a swipeable, step-by-step tutorial.
- Added contextual cooking icons based on step text (e.g., 🔥 for heat, ✂️ for cut, 🍳 for fry).
- Built **inline interactive timers** that users can tap to start directly within the instructions.
- Added automated "Needs Your Attention" flags for manual steps.

### Phase 7: Polish, Verification & Final Delivery
- Executed strict linting (`flutter analyze`) ensuring zero errors.
- Fully documented the architecture and implementation in a comprehensive project walkthrough.
- Tuned the AI pipeline using real-world user receipt test data.

---

## 🧠 Phase 8-11: Local AI Integration (Free & Offline)

Following the consumer pivot, we replaced expensive cloud AI services with local models running entirely on consumer hardware (GTX 1650 Ti).

### Phase 8: Local Ollama Backend
- **Unified Service Layer:** Created `ollama_service.py` using `/api/chat` and `/api/embed` with auto-model resolution.
- **Model Fallbacks:** Rewired receipt and photo vision to use local `moondream`, gracefully falling back to Gemini or Mock.
- **Prompt Engineering:** Solved `qwen3:8b`'s `<think>` tag empty responses via strict `/no_think` directives and output stripping.
- **New AI Capabilities:** Added endpoints for recipe generation (`generate-recipe`), ingredient swaps (`substitute`), and step-by-step help (`cooking-tip`).

### Phase 9: Flutter AI Wiring
- Added a **"💡 Ask AI for a tip"** button inside the cooking tutorial that dynamically fetches advice from the local LLM.
- Hooked up an **"AI Generate"** recipe prompt in the Cook screen that reads user inventory from Supabase and streams back a custom recipe.

### Phase 10: Vector Search & Embeddings
- Integrated `nomic-embed-text` to generate embeddings for recipes and user cooking histories.
- Implemented `/api/v1/ai/semantic-search` and `/api/v1/ai/personalize` using cosine similarity ranking to personalize the "For You" feed.

### Phase 11: Smart Search
- Added an AI-powered Search overlay in the Cook screen (`_RecipeSearchDelegate`).
- Enables fuzzy semantic-style filtering across all recommended recipes natively in Flutter.

---

## 🚀 Phase 12-13: Deployment & Branding (Complete)

### Phase 12: Application Branding
- Explicitly standardized the application name exactly as **"iFridge"**.
- Generated a custom, ultra-premium 1:1 squircle iOS app icon featuring a glassmorphic 3D rendering of a refrigerator holding vibrant fruits.
- Spliced, cropped, and embedded this custom icon into the `manifest.json` as `Icon-192`, `Icon-512`, and `favicon.png`.

### Phase 13: GitHub Monorepo & CI/CD
- Demolished fractured sub-git folders and consolidated both Flutter Front-end and FastAPI Back-end into a single **Monorepo**.
- Programmed a `flutter_web_deploy.yml` GitHub Actions Workflow to autonomously trigger on `main` branch pushes.
- Fixed notorious WASM CanvasKit web-rendering blank screen crashes and Case-Sensitive (`--base-href /iFridge/`) directory routing issues on GitHub Pages.
- Synced the Flutter application directly to the live Railway Production API, cleanly publishing the app to the internet.

---

## 🎨 Phase 14: Page-by-Page UX Overhaul (Complete)

Systematically iterated through each major screen, fixing bugs, adding features, and elevating the visual experience.

### Cook Page
- **AI Recipe Generation:** Added an "AI Generate" feature that reads the user's current shelf inventory from Supabase and streams a custom recipe from the local `qwen2.5:3b` model.
- **Shelf-Only Toggle:** Introduced a switch to constrain AI-generated recipes to only ingredients currently available on the shelf.
- **AI Tips Integration:** Wired "💡 Ask AI for a tip" button in CookingRunScreen to fetch contextual cooking advice from the local LLM.

### Scan Page
- **Two-Stage AI Pipeline:** Completely rewrote the receipt scanning (`ocr_parser.py`) and photo detection (`vision_detect.py`) backends to use a robust two-stage pipeline: `moondream` (vision) describes the image → `qwen2.5:3b` (text LLM) structures the output into JSON.
- **Frontend Data Path Fix:** Corrected the `_captureImage` and `_capturePhoto` functions to unwrap the `data` key from API responses, resolving the "0 items detected" bug.
- **Item Addition Tracking:** Added `_addedIndices` to visually mark items already added with a checkmark and reduced opacity.
- **Bulk Add:** Implemented "Add All to Shelf" button for efficient batch operations.
- **Scan Summary Counter:** Added a counter (e.g., "3 / 12 added") to the results screen.
- **Manual Entry:** Added a location picker (Fridge, Freezer, Pantry) to the manual entry form.
- **RLS Bypass:** Created a new backend endpoint (`/api/v1/inventory/add-item`) using the service role key to bypass Supabase Row Level Security restrictions on the `ingredients` table. All inventory operations (single add, bulk add, manual add, audit accept) now route through this endpoint.

### Audit Screen
- **Category Images:** Integrated `categoryImageUrl()` on audit cards for visual identification.
- **Undo-Reject:** Implemented an undo button with `_undoStack` to recover accidentally rejected items.
- **RLS Fix:** Routed ingredient creation through the new backend API endpoint.

### Profile Page
- **Header Redesign:** Replaced the basic avatar with a `SweepGradient` ring effect, added email subtitle, and made the display name tappable to edit (saves to Supabase `users.display_name`).
- **Animated Stats:** Replaced static stat tiles with `TweenAnimationBuilder` count-up animations and color-coded icon backgrounds (green/teal/orange).
- **Badge Layout Fix:** Used `LayoutBuilder` to constrain badges to 4 per row, preventing overflow on small screens.
- **Account Section:** Added email display, Sign Out (with confirmation dialog — moved from AppBar), and Delete Account (with warning).
- **Settings Section:** Added Language display, Theme indicator, "About iFridge" dialog, and version number.
- **Shopping List Counter:** Title now shows checked vs total count (e.g., "Shopping List (2/5)").
- **Meal Planner Clear:** Long-press the edit icon on any planned meal to remove it from the schedule.

---

## 🗄️ Phase 15: Data Architecture Overhaul (Complete)

Systematically audited and rebuilt the app's data layer for efficiency, consistency, and proper per-user isolation.

### Database Fixes
- **`increment_gamification_stats` RPC:** Was literally empty (0 bytes). Now atomically handles XP increment, level calculation (`floor(sqrt(xp/100))+1`), streak management (consecutive day detection), and stat counters.
- **`get_recommended_recipes` RPC:** Fixed broken reference to non-existent `master_ingredients` → `ingredients`, and `expiry_date` → `computed_expiry`.

### Backend Data API (`v3.2.0`)
- **`user_data.py` Router:** 8 new endpoints — `POST /init` (atomic user profile creation), `GET /{id}/dashboard` (single call replaces 5 parallel queries), `PATCH /profile`, shopping list CRUD, meal plan CRUD.
- **`inventory.py` Expansion:** Added `PATCH /{id}`, `DELETE /{id}`, `POST /consume` (wraps `consume_inventory_item` RPC).
- All writes now route through the backend (service role key), ensuring consistent RLS bypass.

### Frontend Repository Layer
- **`InventoryRepository`:** Centralized read/write/realtime for inventory. Reads via Supabase anon key (RLS), writes via backend API.
- **`UserRepository`:** Dashboard (1 API call → replaces 5 parallel Supabase queries), profile, shopping, meal plan mutations.
- **`ApiService`:** 11 new methods added for all backend endpoints.

### Schema Hardening (`migration_006`)
- Added `updated_at` columns + triggers to `shopping_list` and `meal_plan`.
- Tightened `ingredients` INSERT policy (service role only).
- Added unique constraint on `inventory_items(user_id, ingredient_id, location)` to prevent duplicates.
- Added trigram index on `ingredients.display_name_en` for faster autocomplete.
- **Removed shared demo UUID** — guests now use Supabase anonymous auth with real UUIDs, eliminating data collision.

## 🍽️ Phase 16: Recipe Seeding & Ingredient Icons (Complete)

Massively expanded the recipe database and introduced per-ingredient visual identity.

### 100-Recipe Collection
- **Seeded 100 recipes** across 4 SQL files (`seed_recipes_part1-4.sql`), each with full `recipe_ingredients` and `recipe_steps` (human text + robot action JSON).
- **Cuisines covered:** American, Korean, Japanese, Italian, Thai, Mexican, French, Indian, Spanish, Greek, Chinese, Turkish, Vietnamese, Middle Eastern, British, Russian, Mediterranean.
- **Tags span:** breakfast, lunch, dinner, dessert, side, soup, salad, appetizer, snack, quick, baking, fried, grilled, spicy, healthy, vegetarian, comfort, no-cook.
- **Highlights:** American Pancakes, Korean Maeuntang (spicy fish soup), Bibimbap, Tteokbokki, Bulgogi, Doenjang Jjigae, Shoyu Ramen, Margherita Pizza, Pad Thai, Butter Chicken, and more.
- **Helper function:** `_ensure_ing()` auto-creates missing ingredients with proper `canonical_name` during seeding.

### Ingredient Icon System
- **`seed_ingredients.sql`:** 24 common ingredients with bilingual names (EN/KO), shelf-life data, and storage zones.
- **`migration_007`:** Added `image_url` column to `ingredients` table.
- **`ingredient_icons.dart`:** 70+ emoji mappings (🥔🥕🧅🥚🍗🍚🥛 etc.) with per-ingredient match → category fallback → default.
- **`InventoryItemCard`:** Replaced unreliable Unsplash `NetworkImage` with instant-loading emoji icons.

### Inventory Add Fix
- **Upsert logic:** Backend `add-item` endpoint now checks for existing items at the same `(user_id, ingredient_id, location)` — increments quantity instead of failing with `duplicate key` constraint violation.
- **`canonical_name`:** Now properly set when creating new ingredients (was missing, caused NOT NULL violations).
- **Location normalization:** Lowercased on insert for consistent shelf filtering.

### Query Limits
- Increased recipe query limits from 50 → 200 in Cook screen and Profile screen to display all 100 recipes.

---

## 🌟 Gap Analysis & Deep Refinement (Phases A-E)

Following the initial 16 phases, a comprehensive gap analysis was conducted to refine the core ingredients system, polish recipes, build out deep profile features, and introduce creator capabilities.

### Phase A: Ingredient Foundation & Auto-Fill
- **DB Expansion**: Seeded over 500+ real-world ingredients into the Supabase database with extensive metadata (shelf life, calories, category).
- **Auto-Fill Pipeline**: Wired the photo/barcode/receipt scanners to automatically query the core DB. When an ingredient is detected, the app auto-populates its image, category, and expiry date.
- **Metric Refactor**: Added `UnitConverter.simplifyMetric` to gracefully display quantities (e.g., showing "2 kg" instead of "2000 g"), which is now live in the prep screen.

### Phase B: Recipe System Polish
- **AI Scaling**: Fixed the AI scaling bug allowing smooth portion control.
- **Ingredient Metrics**: Added gamified, highly visible ingredient metrics.
- **Cooking Controls**: Added manual timer toggle support for cooking mode.
- **Fallback Generation**: Handled empty steps with UI to auto-generate instructions via AI.

### Phase C: Profile Deep Pages
- **New Screens**: Created full, robust screens for **Meal Planner**, **Nutrition Tracker**, and **Shopping List**.
- **Navigation**: Wired these deep links from the profile cards.
- **Flavor Profile**: Enhanced the feature to track prepared foods and consumed calories.

### Phase D: Explore & Creator Enhancements
- **Creator Studio**: Built a robust creator dashboard inside the Profile page reflecting views, followers, and engagement metrics.
- **Post Upload Form**: Implemented a comprehensive UI for community chefs to upload reels/videos, attach tags, and link existing recipes.
- **Inline Recipe Viewer (Reels)**: When a user encounters a cooking reel in the Explore tab, tapping the `Recipe` button now opens an immersive, draggable bottom sheet displaying ingredients & instructions seamlessly over the video instead of breaking navigation.

### Phase E: Raw Recipe Parser
- **Backend AI Engine**: Deployed a `/api/v1/ai/parse-raw` endpoint in FastAPI. This utilizes the local `gemma3:1b` model to digest raw, unstructured text (e.g., from blogs or books) and return precise JSON recipes.
- **Frontend Import UI**: Created the `RecipeImportScreen` (accessed via a floating action button in the Cook tab). Users can paste any recipe text, and the AI immediately structures it into prep time, ingredients, and steps.
- **Auto-Timers Capability**: The dynamic regex step-parser inherently processes these AI-generated steps, successfully creating single-tap automated timers (e.g., "bake for 10 minutes") without requiring backend schema migrations.

### Phase F: Hyperlocal Food Discovery & Native Video Feeds
- **Native Inline Video Feeds**: Migrated from clunky webviews to high-performance `dart:ui_web` Platform View Factories for inline YouTube playback without app freezes. 
- **TikTok-Style UI Architecture**: Revamped the `ExploreScreen` (Reels Tab) and `OrderFeedsScreen` using vertical `PageView` builders with robust full-screen video overlays.
- **Context-Aware Interactions**: Added "Close" overlays that properly unmount iframes and return scroll control to the user. Implemented interactive "Cook This Recipe" sidebars for cooking context, and "Order/Reserve" localized actions for restaurant context.
- **Content Bootstrapping via Supabase**: Hand-seeded over 40+ high-quality multi-language (English, Korean, Russian, Uzbek) video shorts directly into a new `video_feeds` schema, completely managed by Supabase, enabling zero-code content pushes.

### Phase G: Security & Algorithm Hardening
- **SQL Injection Fix**: Eliminated critical vulnerability in `recommendation_engine.py` where raw `.format()` string interpolation was used in SQL queries. Replaced with UUID validation + safe Supabase ORM query builder fallback. No raw SQL is ever built from user input.
- **Urgent Items Bug Fix**: Fixed `_get_urgent_items()` which was silently returning zero results — the date range filter used `.lte(today)` instead of `.lte(today + 2 days)`, meaning only items expiring *exactly* today were found.
- **N+1 Query Elimination**: Urgent items previously issued a separate DB query per ingredient to fetch its name. Refactored to a single query with JOIN — O(1) instead of O(N) database calls.
- **CORS Hardening**: Restricted `allow_origins` from wildcard `*` to only `localhost:8080`, `127.0.0.1:8080`, and `shukurillo0526.github.io`.
- **Rate Limiting**: Added `slowapi` rate limiting (10 req/min) on expensive AI endpoints (`generate-recipe`, `detect-ingredients`) to prevent GPU abuse.
- **Dead Code Cleanup**: Removed unused `video_feed_service` import from `cook_screen.dart`.
- **API Version Bump**: Backend version bumped from `3.2.0` → `3.3.0`.

### Phase H: Algorithm & Intelligence Upgrades
- **6-Signal Composite Scoring**: Upgraded from 3-signal scoring (expiry, flavor, familiarity) to 6-signal (+ difficulty fit, recency penalty, match coverage). Weights are configurable via environment variables and sum to 1.0.
- **Difficulty Fit Signal**: Recipes now match against the user's estimated cooking skill level (auto-derived from cooking history count, or explicit `skill_level` column).
- **Recency Penalty Signal**: Recently cooked recipes are penalized to promote variety. 14-day cooldown window with linear ramp.
- **Match Coverage Signal**: A power-curve scoring function that rewards high ingredient match percentages (100% match → 1.0, 50% → 0.45).
- **Server-Side Recommendations API**: New `/api/v1/recommendations/{user_id}` endpoint returns pre-scored, pre-tiered recipes. The Flutter client now tries this first, falling back to client-side scoring if the backend is unreachable. Dramatically reduces data transfer (200 recipes → 50 pre-scored).
- **Ingredient Substitution UI**: Added "🔄 Swap" button on missing ingredients in `RecipeDetailScreen`. Tapping it opens a glassmorphic bottom sheet that calls `/api/v1/ai/substitute` and displays 3 AI-suggested alternatives with swap ratios.
- **Standardized API Response Envelope**: Created `ApiResponse` model with `success/error/partial` status, `data`, `message`, `error`, and `meta` fields for consistent response shapes across all new endpoints.

### Phase I: UX & Performance Overhaul
- **Onboarding Flow**: Built animated 3-step onboarding (PageView with elastic emoji animations, gradient backgrounds, skip controls). Shows once for first-time users, persisted via `SharedPreferences`. Wired into `_AuthGate` without modifying existing auth logic.
- **Recipe Card Redesign**: Enhanced `_RecipeCard` with glowing border for high-match recipes (≥90%), relevance score progress bar (showing the 6-signal composite score), and "% fit" chip. All existing card elements preserved.
- **Image Caching**: Added `cached_network_image` package. Recipe card hero images now use `CachedNetworkImageProvider` instead of raw `NetworkImage`, preventing redundant downloads during scroll.
- **iframe Memory Management**: Fixed memory leak in both `ExploreScreen` (Reels) and `OrderFeedsScreen` — added `didUpdateWidget` to auto-stop video playback when cards scroll off-screen. Previously, iframes stayed alive in memory after scrolling away.

### Phase J: YouTube Intelligence & Advanced Features
- **YouTube Recipe Extraction**: New `youtube_intelligence.py` service + `/api/v1/ai/youtube-recipe` endpoint. Extracts structured recipe data (ingredients, steps, cuisine, difficulty) from YouTube video titles + descriptions using the local LLM. No YouTube Data API required.
- **Flavor Profile Auto-Learning**: New `flavor_learning.py` service. When user taps "I Cooked This", their flavor profile is updated via EMA (15% decay). Creates a feedback loop: cook → profile shifts → better recommendations.
- **"I Cooked This" Button**: Added to `RecipeDetailScreen`. Records cook event, updates flavor profile, and shows a success snackbar. Feeds both the recency signal (for variety) and the flavor learning (for personalization).
- **Smart Shopping List**: New `/api/v1/ai/shopping-list` endpoint generates a consolidated, category-grouped shopping list from missing ingredients across multiple selected recipes. Deduplicates shared ingredients.
- **Video Engagement Tracking**: New `/api/v1/user/engagement` endpoint persists likes, saves, and views to `user_video_engagement` table. Supports like/unlike, save/unsave, and view actions.
- **Frontend API Methods**: Added `recordCook`, `trackEngagement`, `extractYouTubeRecipe`, `generateShoppingList` to `ApiService`.

### Phase K: Scalability & Production Readiness
- **Request ID Middleware**: `RequestIdMiddleware` injects/preserves `X-Request-ID` headers for end-to-end request tracing across frontend → backend → logs. Also adds `X-Response-Time` timing headers.
- **Input Validation Middleware**: `InputValidationMiddleware` enforces 10MB body size limits, validates UUID path parameters, and rejects malformed requests before they hit business logic.
- **Structured Logging**: New `logging_config.py` with JSON-structured logs (or readable dev-mode). Every log entry includes timestamp, level, logger, message, and `request_id` for correlation.
- **Health Check System**: New `/api/v1/health` deep health probe tests Supabase connectivity, Ollama AI availability, and rate limiter status with latency measurements. Returns `healthy`/`degraded`/`unhealthy`. Lightweight `/api/v1/health/ping` liveness probe also added.
- **Global Error Handlers**: Standardized error envelope (`{"status": "error", "code": "...", "message": "...", "request_id": "..."}`) for all HTTP exceptions, validation errors, and unhandled crashes. Tracebacks logged server-side but never exposed to clients.
- **API Documentation**: Enriched OpenAPI spec with descriptive tags (Health, Vision, AI, Recipes, Inventory, User Data, Nutrition, Embeddings), detailed app description, and version bump to 3.4.0.

### Phase L: Testing & CI Pipeline
- **Test Suite**: Created 40 unit/integration tests across 3 test files — all passing in 0.84s:
  - `test_scoring.py` (24 tests): Every signal in the 6-signal composite scoring engine (expiry urgency, flavor affinity, difficulty fit, recency penalty, match coverage, and composite score).
  - `test_middleware.py` (9 tests): Request ID injection/preservation, response timing, body size limits, UUID validation, error formatting.
  - `test_health.py` (7 tests): Root endpoint, ping liveness probe, deep health check, 404 error envelopes.
- **GitHub Actions CI**: `.github/workflows/backend-tests.yml` — runs all tests on every push/PR to `main` with Python 3.12, pip caching, and JUnit result artifacts.
- **Documentation Update**: Updated `QUICK_START.md` (v3.4.0 endpoints, architecture diagram, API table), rewrote `ROADMAP.md` (marked all completed sprints), created `API_REFERENCE.md` (full endpoint reference with request/response shapes, error codes, headers).

### Phase M: AI Upgrades — Chat, Expiry Prediction, Freshness Detection
- **Conversational Kitchen Assistant**: New `chat.py` router with `/api/v1/ai/chat` endpoint supporting SSE streaming and non-streaming modes. Multi-turn conversation with kitchen-aware system prompt. Streaming uses `generate_text_stream()` added to `OllamaService` for token-by-token delivery.
- **Smart Expiry Prediction**: New `expiry_prediction.py` service with category-based shelf life (16 categories), storage location multipliers (freezer=6x, pantry=0.5x, counter=0.3x), packaging factors (sealed=+50%), and shelf-stable overrides. Endpoint: `/api/v1/inventory/predict-expiry`. 12 unit tests.
- **Visual Freshness Detection**: New `/api/v1/inventory/assess-freshness` endpoint. Accepts a photo of an ingredient, uses vision AI to score freshness (0.0-1.0), identifies visual cues, and returns an adjusted expiry date. Integrates with `expiry_prediction.py` for shelf-life calculations.
- **Test Suite Growth**: 40 → 52 tests (added `test_expiry.py` with 12 tests). All passing in 0.88s.

### Phase N: Voice, Offline, State Management, Cloud AI, Sentry (v3.5.0)
- **Voice Commands**: `speech_to_text` package with `VoiceCommandService` for intent parsing (recipe requests, shopping list additions, timer, general assistant). `VoiceCommandFab` widget with pulsing mic animation and bottom-sheet AI reply display.
- **Offline-First Caching**: `hive_flutter` cache service with 5 Hive boxes (inventory, recipes, profile, sync_queue, meta). `connectivity_plus` auto-detects online/offline and flushes queued writes on reconnect. Cache-first strategy with staleness detection.
- **Cloud AI Fallback**: `cloud_ai_service.py` supports OpenAI GPT-4o-mini and Gemini 2.0 Flash. Automatic fallback chain wired into `OllamaService.generate_text()`: Ollama → Cloud → error. Activate by adding `OPENAI_API_KEY` or `GEMINI_API_KEY` to `.env`.
- **Sentry Integration**: Backend `main.py` auto-initializes Sentry with FastAPI + Starlette integrations when `SENTRY_DSN` is set. 0.2 trace sample rate, production environment.
- **Riverpod State Management**: `flutter_riverpod` with `ProviderScope` wrapper. Created `app_providers.dart` with `inventoryProvider` (cache-first async), `userProfileProvider`, `recommendationsProvider`, `shoppingListProvider` (local state), and `isOnlineProvider`. Screens can now gradually migrate from `setState()`.

---

## 🏪 Phase O: Production Hardening & App Polish (Complete)

Systematic preparation of the app for public release:

### Navigation & Layout Fixes
- **DualModeNavBar Overflow**: Replaced fixed-width Row children with `Expanded` widgets, eliminating horizontal overflow on narrow screens.
- **FAB/Scrollbar Bleeding**: Removed `extendBody: true` from AppShell to prevent content clipping behind the custom navigation bar.
- **ScrollbarThemeData**: Overrode default scrollbar colors (which inherited the green primary) with neutral semi-transparent styling.
- **Scan Screen Overflow**: Wrapped capture-state content in `SingleChildScrollView` for small screens.

### Location & Emulator Support
- **Location Fallback**: Implemented robust fallback in `LocationService` — defaults to Tashkent coordinates when GPS/permissions fail on emulators, preventing the Order screen from blocking.

### Build & Security
- **`--dart-define` Pattern**: Secured Supabase credentials for production store builds.
- **Android ProGuard/R8**: Configured `build.gradle.kts` for production minification and resource shrinking.

### Documentation
- **QUICK_START.md**: Complete rewrite covering 4+ testing methods and 5 deployment platforms.

---

## 🛒 Phase P: Marketplace Ecosystem — "VISION" (Complete)

The pivotal phase where iFridge evolved from a personal kitchen app into a **three-sided food commerce marketplace**.

### Phase P-1: Cart & Checkout System
- **Cart Service** (`cart_service.dart`): Singleton in-memory cart with quantity management, restaurant binding (auto-clears on restaurant switch), order type toggle (pickup/delivery), special instructions, and JSON serialization for order submission.
- **Menu Integration**: Replaced dead "Add to cart" snackbar button with real `CartService.addItem()`. Shows quantity stepper (`- N +`) when items are in cart.
- **Floating Cart Bar**: Appears at bottom of restaurant detail page showing item count + total, navigates to checkout.
- **Checkout Screen** (`checkout_screen.dart`): Pickup/delivery toggle, order review with quantity controls, price summary (subtotal + delivery fee + total), estimated time, and "Place Order" button.
- **Order Confirmation**: Displays generated pickup code (e.g., `AB742`) for pickup orders, or delivery status for delivery orders. Shows estimated preparation time.

### Phase P-2: Order Service & Backend API
- **Orders Table** (`007_orders.sql`): Full PostgreSQL migration with status lifecycle (`confirmed → preparing → ready → picked_up → delivering → completed → cancelled`), JSONB items array, delivery fields, RLS policies, indexes, and `get_user_orders` RPC function with restaurant name JOIN.
- **Order Router** (`orders.py`): 6 REST endpoints — `POST /orders` (create with pickup code gen), `GET /orders/{id}`, `GET /orders/user/{id}` (history with RPC fallback), `GET /orders/active/{id}`, `PATCH /orders/{id}/status`, `POST /orders/{id}/cancel` (with status validation).
- **Order Service** (`order_service.dart`): Frontend service with `UserOrder` model, HTTP + Supabase dual-path for order placement, history fetching, active order queries, and cancellation.

### Phase P-3: Order History & Tracking
- **Order History Screen** (`order_history_screen.dart`): Active/past order separation, status progress bar (dot + line visualization), pickup code display, cancel with confirmation dialog, pull-to-refresh.
- **Status Chips**: Color-coded badges (orange=confirmed, blue=preparing, green=ready, purple=delivering).
- **Profile Integration**: Added "My Orders" card to Profile/Manage screen with navigation to order history.

### Phase P-4: Restaurant Order Management
- **Incoming Orders Page** (`incoming_orders_page.dart`): 3-tab layout (New/Preparing/Ready) for restaurant owners. Each order card shows pickup code, item list with quantities, special instructions, customer notes, and a one-tap status advancement button.
- **Restaurant Dashboard Integration**: Added "Manage Orders" action card to the existing restaurant dashboard linking to the incoming orders page.

### The Complete Ordering Loop
```
Consumer                           Restaurant
   │                                   │
   ├─ Browse restaurants ─────────────►│
   ├─ Add items to cart                │
   ├─ Checkout (pickup/delivery)       │
   ├─ Get pickup code (e.g. AB742) ───►│ See in "New" tab
   │                                   ├─ "Start Preparing"
   │                                   ├─ "Mark Ready"
   ├─ Show code at counter ───────────►├─ "Complete"
   ├─ View in Order History            │
   └─ Rate & Reorder                   │
```

---

# 📦 v0.0.1 — Preparation for the First Public Deploy

Initial public release of the iFridge consumer app. Deployed to GitHub Pages via Flutter Web with CI/CD pipeline.

### Highlights
- **Full Consumer MVP:** All screens functional — Shelf, Scan, Cook, Profile, Order.
- **Marketplace Foundation:** Cart, checkout, order lifecycle, restaurant dashboard all operational.
- **Local AI Pipeline:** Ollama-powered recipe generation, ingredient detection, and cooking tips running on consumer hardware.
- **GitHub Pages Deployment:** Automated via `flutter_web_deploy.yml` on every push to `main`.
- **33 Uzbek Recipes:** Seeded `seed_recipes_uzbek.sql` with traditional dishes (Plov, Lagman, Somsa, Shashlik, Manti, Chuchvara, Norin, etc.) — bringing total recipe count to 133.

---

# 📦 v0.0.2 — Multilingual Infrastructure & Locale System

Built the full internationalization (i18n) framework and added 4-language UI support.

### Highlights
- **Flutter Locale System:** Implemented `AppSettings` locale management with `Locale.fromSubtags()` supporting language + script code combinations.
- **5 ARB Files:** `app_en.arb`, `app_ko.arb`, `app_uz.arb`, `app_uz_Cyrl.arb`, `app_ru.arb` — covering all UI strings.
- **Language Picker:** Profile settings screen with runtime language switching (persisted via `SharedPreferences`).
- **Uzbek Cyrillic Detection:** Script-aware localization using `Localizations.localeOf(context).scriptCode == 'Cyrl'` to differentiate Uzbek Latin vs Cyrillic.
- **Supabase Ingredient Columns:** Added `display_name_ko`, `display_name_uz`, `display_name_uz_cyrl`, `display_name_ru` to the `ingredients` table.

---

# 📦 v0.0.3 — AI Translation Pipeline & Recipe Translations

Translated all recipes and ingredients across 4 languages using a hybrid AI pipeline.

### Highlights
- **Hybrid Translation Engine:** `qwen3:14b` via Ollama (primary) with Google Gemini Flash fallback when rate-limited.
- **Culinary Glossary:** Curated term mappings ensuring domain-accurate translations (e.g., "gochujang" → "고추장", "plov" → "плов").
- **Recipe Translations:** Title, description, and step-by-step instructions for all 133 recipes translated and cached in `recipe_translations` table.
- **Ingredient Translations:** 319 canonical ingredients translated to Korean, Uzbek Latin, Uzbek Cyrillic, and Russian (100% coverage across all languages).
- **Translation Scripts:** `scripts/translate_all.py`, `scripts/translate_missed.py`, `scripts/patch_translation_ollama.py` for batch and incremental translation runs.

---

# 📦 v0.0.4 — Plately: Multilingual Ingredients, Relational Recipes & Rebrand

The pivotal release where I-Fridge became **Plately** — rebuilt the recipe-ingredient data model from the ground up with full multilingual support.

### Phase Q-1: Multilingual Translation System
- **4-Language Support:** English, Korean (한국어), Uzbek Latin (O'zbekcha), Uzbek Cyrillic (Ўзбекча), Russian (Русский).
- **AI Translation Pipeline:** Hybrid local/cloud system — `qwen3:14b` via Ollama (primary) with Gemini Flash fallback when rate-limited.
- **Glossary System:** Curated culinary glossary ensuring consistent translation of specialized terms (e.g., "gochujang" → "고추장" not "빨간 고추 된장").
- **Ingredient Translations:** All 319 canonical ingredients translated to 4 languages with full coverage:
  - Korean: 319/319 (100%)
  - Uzbek Latin: 319/319 (100%)
  - Russian: 319/319 (100%)
- **Recipe Translations:** Title, description, and cooking steps translated via AI with caching in `recipe_translations` table.

### Phase Q-2: Ingredient Database Expansion
- **319 canonical ingredients** (up from ~100) with complete metadata:
  - Display names in 4 languages (EN/KO/UZ/RU) + Uzbek Cyrillic
  - Category, default unit, sealed/opened shelf life, storage zone
- **41 new ingredients added** via migration 013: broths, ground meats, specialty items (dashima, nori, panko, lemongrass, tamarind, wonton wrappers, etc.).
- **Normalization map:** 255 unique recipe ingredient strings → canonical names (100% mapped, 0 unmatched).

### Phase Q-3: Relational Recipe-Ingredient Architecture
- **Restored `recipe_ingredients` table** with proper foreign keys:
  ```sql
  recipe_ingredients(recipe_id → recipes, ingredient_id → ingredients,
                     quantity, unit, prep_note, is_optional, display_order)
  ```
- **1,218 relational links** created across 133 recipes (avg 9.2 ingredients/recipe).
- **Frontend migration:** All 4 consumer screens updated:
  - `recipe_detail_screen`: Reads from `recipe_ingredients` JOIN `ingredients` — ingredient names auto-localized per user's language.
  - `cook_screen`: Scoring uses ingredient ID matching instead of fuzzy name strings.
  - `cooking_run_screen`: Updated data format for relational ingredients.
  - `recipe_import_screen`: Creates `recipe_ingredients` entries on recipe import.
- **Cyrillic support:** `uz_Cyrl` locale detection via `scriptCode` — uses `display_name_uz_cyrl` column.

### Phase Q-4: Performance Fix
- **Batch query optimization:** Replaced 133 individual `recipe_ingredients` queries in cook_screen with a single batch fetch, then client-side grouping. Loading time reduced from ~30s to <1s.

### Phase Q-5: Full Rebrand — I-Fridge → Plately
- **229 files renamed** across the entire codebase (670 replacements).
- Package: `ifridge_app` → `plately_app`
- Android: `com.ifridge.ifridge_app` → `com.plately.plately_app`
- iOS: `com.ifridge.ifridgeApp` → `com.plately.platelyApp`, display name "Plately"
- Windows: project name and window title updated
- Web: manifest, index.html, service worker
- Git remote: `shukurillo0526/Plately.git`
- Zero remaining references to iFridge in source files.

---

# 📦 v0.0.5 — Smart Ingredient Resolution, Inventory & Scan UI Localization

Full localization of the inventory and scan modules, a smart ingredient resolution system for unknown inputs, and category translation infrastructure.

### Phase 1: Ingredient Index & Database Schema
- **`code` column:** Added stable integer index to `ingredients` table for cross-module referencing (AI, recipes, inventory).
- **New metadata columns:** `type_primary`, `type_secondary`, `protein`, `fat`, `carbs`, `source`, `verified`, `created_by` — laying groundwork for nutritional data and user-contributed ingredients.
- **`pg_trgm` extension:** Enabled in Supabase for trigram-based fuzzy matching.
- **`fuzzy_match_ingredient` RPC:** PostgreSQL function using `similarity()` for typo-tolerant ingredient lookups (threshold: 0.3).

### Phase 2: Smart Ingredient Resolution (Backend)
- **`/api/v1/ingredients/resolve` endpoint:** Cascading resolution flow:
  1. Exact match on `canonical_name`
  2. Canonical match (lowercased, stripped)
  3. Fuzzy match via `pg_trgm` similarity scoring
  4. Auto-create as `user_contributed` with provenance tracking (`source='user_contributed'`, `verified=false`, `created_by=user_id`)
- **`/api/v1/ingredients/fuzzy` endpoint:** Standalone fuzzy search returning similarity scores for autocomplete/suggestions.
- **Provenance tracking in `add-item`:** All auto-created ingredients tagged with source and creator for later admin review.

### Phase 3: Inventory UI Full Localization
- **25 new ARB keys × 5 languages = 125 translations** covering:
  - Detail labels: `inv_quantity`, `inv_purchased`, `inv_expires`, `inv_source`
  - Section headers: `inv_storageLocation`, `inv_itemState`
  - Freshness states: `inv_freshLabel` → `inv_expiredLabel` (5 states)
  - State badges: `inv_stateOpened`, `inv_stateFrozen`, `inv_stateThawed`, `inv_statePartial`
  - Expiry messages: `inv_expiredDaysAgo`, `inv_expiresToday`, `inv_expiresTomorrow`, `inv_daysRemaining`
  - Sort modes: `inv_sortExpiry`, `inv_sortName`, `inv_sortCategory`, `inv_sortNewest`
- **`inventory_detail_sheet.dart`:** All labels wired to `AppLocalizations.of(context)?.inv_*` keys.
- **`inventory_item_card.dart`:** State badges and expiry labels fully localized.

### Phase 4: Scan / Add Ingredient Dialog Localization
- **8 new `manual_*` ARB keys × 5 languages** for the manual entry form:
  - `manual_addIngredient`, `manual_ingredientName`, `manual_ingredientHint`, `manual_category`, `manual_qty`, `manual_metricType`, `manual_estimatedExpiry`, `manual_required`
- **Multi-language autocomplete search:** Queries across all `display_name_*` columns (`en`, `ko`, `uz`, `uz_cyrl`, `ru`) + `canonical_name` simultaneously.
- **Localized search results:** Ingredient names and category subtitles displayed in current language.
- **`L10nHelper.translateCategory()`:** New utility translating 30 ingredient categories to UZ/RU/KO — used in both the category dropdown and search result tiles.

### Phase 5: Locale Parity Fix
- **UZ_Cyrl ARB cleanup:** Fixed all broken `Х0Х` / `Х1Х` hardcoded placeholders → proper ICU `{param}` format. Removed duplicate keys and corrupted lines.
- **KO ARB backfill:** Added 29 missing recipe-related keys (`tierBadge1-5`, `needLabel`, `nOfNIngredients`, `servingsLabel`, `nHave`, `nMissing`, `ingredientsHeader`, `swapButton`, `aiAssistant`, `aiHint`, `editIngredient`, `nameLabel`, `qtyLabel`, `unitLabel`, `handsOn`, `automatic`, `noStepsAvailableYet`, `failedToRecordX`, `failedToAddItemsX`).
- **Result:** `flutter gen-l10n` produces **zero untranslated message warnings** across all 5 locales.

### Frontend API Methods
- `fuzzySearchIngredients(query)` — trigram-based fuzzy search
- `resolveIngredient(name, userId)` — smart resolve-or-create

# 📦 v0.0.6 — Branding, Gamification & CI/CD
### App Branding & Iconography
- Configured `flutter_launcher_icons` to generate native Android, iOS, and PWA icons using a professional 3D "P" logo.

### Gamification Overhaul
- **New Achievements:** Added highly requested meme-based badges: `streak15` ("Flatten the Chaos") and `streak30` ("Determined March").
- **UI Modernization:** Refactored the rigid `GamificationPage` grid into an interactive, tap-to-expand premium badge gallery using `ClipRRect` and scalable dialogs.

### CI/CD Fixes
- Fixed `.github/workflows/backend-tests.yml` to explicitly install testing frameworks (`pytest`), keeping `requirements.txt` strictly optimized for production.

---

# 📦 v0.0.7 — Gemini 2.5 Architecture & UI Polish
### AI Engine Overhaul (Gemini 2.5 Triad)
- **Primary Engine (`gemini-2.5-flash`):** Set as the core backend model for high-volume receipt scanning, raw recipe parsing, and Tier-1 translations.
- **Cost-Optimized Engine (`gemini-2.5-flash-lite`):** Specifically routed high-frequency, simple endpoints (Cooking Tips, Ingredient Substitutes) to the extremely cheap `$0.10/1M` model.
- **Complex Reasoning Engine (`gemini-2.5-pro`):** Dynamically triggered solely for translating recipes into low-resource languages (e.g., Uzbek) to guarantee native grammar and context.
- **SDK Optimization:** Ripped out the heavy `google.generativeai` package in favor of lightweight native REST calls via `httpx` with strict `application/json` enforcement.

### UI & Asset Polish
- **Web Favicon:** Built a Python-based processing script (`round_icon.py`) to flawlessly zoom-crop and squircle-mask the web tab icon to match Apple/Instagram standards.
- **Gamification Images:** Added a dynamic `Transform.scale` mask in the Flutter UI to perfectly crop out blurred screenshot UI edges from user-provided meme badge images, preserving the original text context while looking natively embedded.

---

# 📦 v0.0.8 — Context-Aware AI & Dynamic Nutrition

This update dramatically enhances the cooking experience by providing the AI with global inventory awareness and surfacing crucial nutritional information directly in the cooking flow.

### Highlights
- **Global Inventory AI Context:** Re-architected the `RecipePrepScreen` and `CookingRunScreen` context builders. The AI now pulls the user's *entire* inventory (not just the recipe's ingredients) from Supabase on demand, allowing it to suggest highly accurate, personalized ingredient substitutions based on what the user actually owns.
- **Dynamic Macro Calculations:** Integrated the backend's dynamic calorie calculator directly into the frontend. The `RecipeDetailScreen` now fetches and visually displays Calories, Protein, Carbs, and Fat scaled per serving in real-time.
- **Inventory Deduction Fix:** Patched a critical bug in the post-cooking `Skip` dialog where skipping deduction would falsely return an empty array (which triggered a full deduction) instead of gracefully bypassing it.
- **Curated Recipe Photography:** Successfully populated all 133 recipes with high-quality, verified stock photography mapped to their respective cuisines, replacing the placeholder gradient fallback system.

---

## 🚀 The VISION — Three-Pillar Marketplace

Plately is now positioned as a **3-sided food commerce ecosystem**:

| Side | App | Value |
|------|-----|-------|
| **Consumers** | Plately (existing) | Cook at home + order food (pickup/delivery) |
| **Restaurants** | Plately Business (in-app dashboard) | Receive orders, manage menu, no cashier needed |
| **Drivers** | Plately Fleet (planned) | Shared delivery fleet, more jobs, lower commission |

### Planned Pillars:
1. **Mobile Order & Pickup** (Luckin Coffee model) — ✅ Foundation built
2. **Self-Service Kiosk Hardware** (Korean 무인주문기 model) — 🔲 Planned
3. **Shared Delivery Network** (Plately Fleet) — 🔲 Planned

### Competitive Edge:
- **3–5% commission** vs 30%+ on Uber Eats/Coupang Eats
- Restaurant **owns their customer data**
- Full **AI kitchen integration** (recipes, inventory, smart suggestions)
- **Open hardware** (any Android tablet for kiosk)

See `vision_docs/VISION_ABOUT.md` and `vision_docs/ECOSYSTEM_STRATEGY.md` for the complete business plan and technical architecture.

---

# 📦 v0.0.9 — Performance & Usability Overhaul

A massive polishing release ensuring stability, extensive localization, local-first data behavior, and AI infrastructure optimizations for a true production-ready app.

### Phase 1: Auth & Navigation Polish
- **Unified Login/Signup Flow**: Seamless automatic detection of login vs sign up. Language picker added directly to the login screen for accessibility.
- **Sign-Out Navigation Fix**: Safely clears auth state and routes users immediately back to the AuthGate without pushing dead-end screens.

### Phase 2: Comprehensive Localization & Gamification
- **In-Depth i18n Maps**: `L10nHelper` now fully translates over 50+ cooking measurement units, 14 common prep notes, and dynamic nutritional chips (kcal, Protein, Carbs, Fat) across all 5 supported locales (EN, KO, UZ Latin, UZ Cyrl, RU).
- **Gamification Badges**: Simplified 15 and 30-day streak badges for visual clarity while keeping higher-tier streak badges meme-centric. 
- **Navigation Icons**: Standardized core navigation icons (e.g. `restaurant`, `camera_alt`).

### Phase 3: Local-First Recipe Storage & Inventory-Aware Swaps
- **Offline-First Storage**: Implemented `local_recipes` Hive box within `CacheService`. Recipe imports now instantly save locally without requiring remote Supabase sync.
- **Inventory-Aware AI**: The AI now actively pulls from the user's `inventory_ingredients` and prioritizes suggesting substitutes the user already has, marking them explicitly as available.

### Phase 4: In-App Tutorial Walkthrough
- **Production-Grade Onboarding**: Developed a robust `TutorialOverlay` employing custom painters for dynamic UI spotlights.
- **Supabase Ingredient Columns:** Added `display_name_ko`, `display_name_uz`, `display_name_uz_cyrl`, `display_name_ru` to the `ingredients` table.

---

# 📦 v0.0.3 — AI Translation Pipeline & Recipe Translations

Translated all recipes and ingredients across 4 languages using a hybrid AI pipeline.

### Highlights
- **Hybrid Translation Engine:** `qwen3:14b` via Ollama (primary) with Google Gemini Flash fallback when rate-limited.
- **Culinary Glossary:** Curated term mappings ensuring domain-accurate translations (e.g., "gochujang" → "고추장", "plov" → "плов").
- **Recipe Translations:** Title, description, and step-by-step instructions for all 133 recipes translated and cached in `recipe_translations` table.
- **Ingredient Translations:** 319 canonical ingredients translated to Korean, Uzbek Latin, Uzbek Cyrillic, and Russian (100% coverage across all languages).
- **Translation Scripts:** `scripts/translate_all.py`, `scripts/translate_missed.py`, `scripts/patch_translation_ollama.py` for batch and incremental translation runs.

---

# 📦 v0.0.4 — Plately: Multilingual Ingredients, Relational Recipes & Rebrand

The pivotal release where I-Fridge became **Plately** — rebuilt the recipe-ingredient data model from the ground up with full multilingual support.

### Phase Q-1: Multilingual Translation System
- **4-Language Support:** English, Korean (한국어), Uzbek Latin (O'zbekcha), Uzbek Cyrillic (Ўзбекча), Russian (Русский).
- **AI Translation Pipeline:** Hybrid local/cloud system — `qwen3:14b` via Ollama (primary) with Gemini Flash fallback when rate-limited.
- **Glossary System:** Curated culinary glossary ensuring consistent translation of specialized terms (e.g., "gochujang" → "고추장" not "빨간 고추 된장").
- **Ingredient Translations:** All 319 canonical ingredients translated to 4 languages with full coverage:
  - Korean: 319/319 (100%)
  - Uzbek Latin: 319/319 (100%)
  - Russian: 319/319 (100%)
- **Recipe Translations:** Title, description, and cooking steps translated via AI with caching in `recipe_translations` table.

### Phase Q-2: Ingredient Database Expansion
- **319 canonical ingredients** (up from ~100) with complete metadata:
  - Display names in 4 languages (EN/KO/UZ/RU) + Uzbek Cyrillic
  - Category, default unit, sealed/opened shelf life, storage zone
- **41 new ingredients added** via migration 013: broths, ground meats, specialty items (dashima, nori, panko, lemongrass, tamarind, wonton wrappers, etc.).
- **Normalization map:** 255 unique recipe ingredient strings → canonical names (100% mapped, 0 unmatched).

### Phase Q-3: Relational Recipe-Ingredient Architecture
- **Restored `recipe_ingredients` table** with proper foreign keys:
  ```sql
  recipe_ingredients(recipe_id → recipes, ingredient_id → ingredients,
                     quantity, unit, prep_note, is_optional, display_order)
  ```
- **1,218 relational links** created across 133 recipes (avg 9.2 ingredients/recipe).
- **Frontend migration:** All 4 consumer screens updated:
  - `recipe_detail_screen`: Reads from `recipe_ingredients` JOIN `ingredients` — ingredient names auto-localized per user's language.
  - `cook_screen`: Scoring uses ingredient ID matching instead of fuzzy name strings.
  - `cooking_run_screen`: Updated data format for relational ingredients.
  - `recipe_import_screen`: Creates `recipe_ingredients` entries on recipe import.
- **Cyrillic support:** `uz_Cyrl` locale detection via `scriptCode` — uses `display_name_uz_cyrl` column.

### Phase Q-4: Performance Fix
- **Batch query optimization:** Replaced 133 individual `recipe_ingredients` queries in cook_screen with a single batch fetch, then client-side grouping. Loading time reduced from ~30s to <1s.

### Phase Q-5: Full Rebrand — I-Fridge → Plately
- **229 files renamed** across the entire codebase (670 replacements).
- Package: `ifridge_app` → `plately_app`
- Android: `com.ifridge.ifridge_app` → `com.plately.plately_app`
- iOS: `com.ifridge.ifridgeApp` → `com.plately.platelyApp`, display name "Plately"
- Windows: project name and window title updated
- Web: manifest, index.html, service worker
- Git remote: `shukurillo0526/Plately.git`
- Zero remaining references to iFridge in source files.

---

# 📦 v0.0.5 — Smart Ingredient Resolution, Inventory & Scan UI Localization

Full localization of the inventory and scan modules, a smart ingredient resolution system for unknown inputs, and category translation infrastructure.

### Phase 1: Ingredient Index & Database Schema
- **`code` column:** Added stable integer index to `ingredients` table for cross-module referencing (AI, recipes, inventory).
- **New metadata columns:** `type_primary`, `type_secondary`, `protein`, `fat`, `carbs`, `source`, `verified`, `created_by` — laying groundwork for nutritional data and user-contributed ingredients.
- **`pg_trgm` extension:** Enabled in Supabase for trigram-based fuzzy matching.
- **`fuzzy_match_ingredient` RPC:** PostgreSQL function using `similarity()` for typo-tolerant ingredient lookups (threshold: 0.3).

### Phase 2: Smart Ingredient Resolution (Backend)
- **`/api/v1/ingredients/resolve` endpoint:** Cascading resolution flow:
  1. Exact match on `canonical_name`
  2. Canonical match (lowercased, stripped)
  3. Fuzzy match via `pg_trgm` similarity scoring
  4. Auto-create as `user_contributed` with provenance tracking (`source='user_contributed'`, `verified=false`, `created_by=user_id`)
- **`/api/v1/ingredients/fuzzy` endpoint:** Standalone fuzzy search returning similarity scores for autocomplete/suggestions.
- **Provenance tracking in `add-item`:** All auto-created ingredients tagged with source and creator for later admin review.

### Phase 3: Inventory UI Full Localization
- **25 new ARB keys × 5 languages = 125 translations** covering:
  - Detail labels: `inv_quantity`, `inv_purchased`, `inv_expires`, `inv_source`
  - Section headers: `inv_storageLocation`, `inv_itemState`
  - Freshness states: `inv_freshLabel` → `inv_expiredLabel` (5 states)
  - State badges: `inv_stateOpened`, `inv_stateFrozen`, `inv_stateThawed`, `inv_statePartial`
  - Expiry messages: `inv_expiredDaysAgo`, `inv_expiresToday`, `inv_expiresTomorrow`, `inv_daysRemaining`
  - Sort modes: `inv_sortExpiry`, `inv_sortName`, `inv_sortCategory`, `inv_sortNewest`
- **`inventory_detail_sheet.dart`:** All labels wired to `AppLocalizations.of(context)?.inv_*` keys.
- **`inventory_item_card.dart`:** State badges and expiry labels fully localized.

### Phase 4: Scan / Add Ingredient Dialog Localization
- **8 new `manual_*` ARB keys × 5 languages** for the manual entry form:
  - `manual_addIngredient`, `manual_ingredientName`, `manual_ingredientHint`, `manual_category`, `manual_qty`, `manual_metricType`, `manual_estimatedExpiry`, `manual_required`
- **Multi-language autocomplete search:** Queries across all `display_name_*` columns (`en`, `ko`, `uz`, `uz_cyrl`, `ru`) + `canonical_name` simultaneously.
- **Localized search results:** Ingredient names and category subtitles displayed in current language.
- **`L10nHelper.translateCategory()`:** New utility translating 30 ingredient categories to UZ/RU/KO — used in both the category dropdown and search result tiles.

### Phase 5: Locale Parity Fix
- **UZ_Cyrl ARB cleanup:** Fixed all broken `Х0Х` / `Х1Х` hardcoded placeholders → proper ICU `{param}` format. Removed duplicate keys and corrupted lines.
- **KO ARB backfill:** Added 29 missing recipe-related keys (`tierBadge1-5`, `needLabel`, `nOfNIngredients`, `servingsLabel`, `nHave`, `nMissing`, `ingredientsHeader`, `swapButton`, `aiAssistant`, `aiHint`, `editIngredient`, `nameLabel`, `qtyLabel`, `unitLabel`, `handsOn`, `automatic`, `noStepsAvailableYet`, `failedToRecordX`, `failedToAddItemsX`).
- **Result:** `flutter gen-l10n` produces **zero untranslated message warnings** across all 5 locales.

### Frontend API Methods
- `fuzzySearchIngredients(query)` — trigram-based fuzzy search
- `resolveIngredient(name, userId)` — smart resolve-or-create

# 📦 v0.0.6 — Branding, Gamification & CI/CD
### App Branding & Iconography
- Configured `flutter_launcher_icons` to generate native Android, iOS, and PWA icons using a professional 3D "P" logo.

### Gamification Overhaul
- **New Achievements:** Added highly requested meme-based badges: `streak15` ("Flatten the Chaos") and `streak30` ("Determined March").
- **UI Modernization:** Refactored the rigid `GamificationPage` grid into an interactive, tap-to-expand premium badge gallery using `ClipRRect` and scalable dialogs.

### CI/CD Fixes
- Fixed `.github/workflows/backend-tests.yml` to explicitly install testing frameworks (`pytest`), keeping `requirements.txt` strictly optimized for production.

---

# 📦 v0.0.7 — Gemini 2.5 Architecture & UI Polish
### AI Engine Overhaul (Gemini 2.5 Triad)
- **Primary Engine (`gemini-2.5-flash`):** Set as the core backend model for high-volume receipt scanning, raw recipe parsing, and Tier-1 translations.
- **Cost-Optimized Engine (`gemini-2.5-flash-lite`):** Specifically routed high-frequency, simple endpoints (Cooking Tips, Ingredient Substitutes) to the extremely cheap `$0.10/1M` model.
- **Complex Reasoning Engine (`gemini-2.5-pro`):** Dynamically triggered solely for translating recipes into low-resource languages (e.g., Uzbek) to guarantee native grammar and context.
- **SDK Optimization:** Ripped out the heavy `google.generativeai` package in favor of lightweight native REST calls via `httpx` with strict `application/json` enforcement.

### UI & Asset Polish
- **Web Favicon:** Built a Python-based processing script (`round_icon.py`) to flawlessly zoom-crop and squircle-mask the web tab icon to match Apple/Instagram standards.
- **Gamification Images:** Added a dynamic `Transform.scale` mask in the Flutter UI to perfectly crop out blurred screenshot UI edges from user-provided meme badge images, preserving the original text context while looking natively embedded.

---

# 📦 v0.0.8 — Context-Aware AI & Dynamic Nutrition

This update dramatically enhances the cooking experience by providing the AI with global inventory awareness and surfacing crucial nutritional information directly in the cooking flow.

### Highlights
- **Global Inventory AI Context:** Re-architected the `RecipePrepScreen` and `CookingRunScreen` context builders. The AI now pulls the user's *entire* inventory (not just the recipe's ingredients) from Supabase on demand, allowing it to suggest highly accurate, personalized ingredient substitutions based on what the user actually owns.
- **Dynamic Macro Calculations:** Integrated the backend's dynamic calorie calculator directly into the frontend. The `RecipeDetailScreen` now fetches and visually displays Calories, Protein, Carbs, and Fat scaled per serving in real-time.
- **Inventory Deduction Fix:** Patched a critical bug in the post-cooking `Skip` dialog where skipping deduction would falsely return an empty array (which triggered a full deduction) instead of gracefully bypassing it.
- **Curated Recipe Photography:** Successfully populated all 133 recipes with high-quality, verified stock photography mapped to their respective cuisines, replacing the placeholder gradient fallback system.

---

## 🚀 The VISION — Three-Pillar Marketplace

Plately is now positioned as a **3-sided food commerce ecosystem**:

| Side | App | Value |
|------|-----|-------|
| **Consumers** | Plately (existing) | Cook at home + order food (pickup/delivery) |
| **Restaurants** | Plately Business (in-app dashboard) | Receive orders, manage menu, no cashier needed |
| **Drivers** | Plately Fleet (planned) | Shared delivery fleet, more jobs, lower commission |

### Planned Pillars:
1. **Mobile Order & Pickup** (Luckin Coffee model) — ✅ Foundation built
2. **Self-Service Kiosk Hardware** (Korean 무인주문기 model) — 🔲 Planned
3. **Shared Delivery Network** (Plately Fleet) — 🔲 Planned

### Competitive Edge:
- **3–5% commission** vs 30%+ on Uber Eats/Coupang Eats
- Restaurant **owns their customer data**
- Full **AI kitchen integration** (recipes, inventory, smart suggestions)
- **Open hardware** (any Android tablet for kiosk)

See `vision_docs/VISION_ABOUT.md` and `vision_docs/ECOSYSTEM_STRATEGY.md` for the complete business plan and technical architecture.

---

# 📦 v0.0.9 — Performance & Usability Overhaul

A massive polishing release ensuring stability, extensive localization, local-first data behavior, and AI infrastructure optimizations for a true production-ready app.

### Phase 1: Auth & Navigation Polish
- **Unified Login/Signup Flow**: Seamless automatic detection of login vs sign up. Language picker added directly to the login screen for accessibility.
- **Sign-Out Navigation Fix**: Safely clears auth state and routes users immediately back to the AuthGate without pushing dead-end screens.

### Phase 2: Comprehensive Localization & Gamification
- **In-Depth i18n Maps**: `L10nHelper` now fully translates over 50+ cooking measurement units, 14 common prep notes, and dynamic nutritional chips (kcal, Protein, Carbs, Fat) across all 5 supported locales (EN, KO, UZ Latin, UZ Cyrl, RU).
- **Gamification Badges**: Simplified 15 and 30-day streak badges for visual clarity while keeping higher-tier streak badges meme-centric. 
- **Navigation Icons**: Standardized core navigation icons (e.g. `restaurant`, `camera_alt`).

### Phase 3: Local-First Recipe Storage & Inventory-Aware Swaps
- **Offline-First Storage**: Implemented `local_recipes` Hive box within `CacheService`. Recipe imports now instantly save locally without requiring remote Supabase sync.
- **Inventory-Aware AI**: The AI now actively pulls from the user's `inventory_ingredients` and prioritizes suggesting substitutes the user already has, marking them explicitly as available.

### Phase 4: In-App Tutorial Walkthrough
- **Production-Grade Onboarding**: Developed a robust `TutorialOverlay` employing custom painters for dynamic UI spotlights.
- **Guided Flow**: Introduces a 4-step home walkthrough (Cook Tab, Scan Fab, Shelf, Profile) that automatically runs for new users.
- **State Persistence**: Uses SharedPreferences (`TutorialService`) to ensure users only see it once. Users can manually re-trigger it from their Profile settings.

### Phase 5: AI Token & Performance Optimization
- **Static Substitution Map**: Deployed an offline, hardcoded 105-rule dictionary for 35+ of the most common cooking ingredients. Completely eliminates ~60% of AI calls for simple swaps (like butter to oil).
- **AI Response LRU Cache**: Implemented an in-memory, TTL-backed LRU cache using SHA-256 key hashing to serve identical requests instantly across the user base.
- **Three-Tier Pipeline**: Substitutions now check Static Map -> AI Cache -> Live AI (Gemini Flash Lite), saving massive amounts of latency and LLM token usage. Included `/api/v1/ai/cache-stats` for monitoring.
U p d a t e d   G a m i f i c a t i o n ,   N u t r i t i o n ,   B a c k e n d   N a m e E r r o r ,   a n d   M y   R e c i p e s   U I  
   
### Phase 6: AI Cooking Flow and Nutrition History  
- **AI Recipe Save vs Cook Flow:** Replaced the static AI recipe modal with a dynamic _GeneratedRecipeSheet. Ephemeral AI recipes can now be saved natively to Hive local storage or directly cooked using a zero-persistence Cook Now path.  
- **Nutrition Tracker History:** Implemented a scrollable Cooking History section inside the Nutrition Tracker. It directly queries user_recipe_history, presenting chronological meal logs with thumbnail images, dates, and calorie chips.  
- **Code Cleanup:** Resolved 13+ use_build_context_synchronously warnings across async gaps in recipe_detail_screen.dart via modern context.mounted checks. 

---

# 📦 v0.1.5 — In-Memory Sandboxed Interactive Tutorial

A fully sandboxed, task-oriented interactive tutorial that guides new users through the complete Plately cycle—from ingredient scanning to active cooking—without affecting production database records.

### Highlights
- **Interactive Multi-Step Guided Workflow:** Replaced the static overlay walkthrough with an interactive task-oriented state machine managed via Riverpod (`TutorialState` and `TutorialController`).
- **Step-by-Step Milestones:**
  - **Launch Dialog:** Asks users if they want to complete the interactive tutorial or skip.
  - **Shelf Discovery:** Guides the user through the three storage tabs (Fridge, Freezer, Pantry) and prompts them to tap the "Add Ingredient" FAB.
  - **Simulated Scanning:** Introduces the scanning pipeline and automatically populates mock ingredients (Chicken Breast, Broccoli, Garlic) for the tutorial.
  - **Shelf Updates:** Displays the freshly added mock ingredients in-memory on the Shelf and directs the user to the Cook tab.
  - **Match Feeds & Recipe Selection:** Explains the 5 recipe match tiers and requests selection of the special Tutorial Chicken Stir-Fry recipe.
  - **Preparation & Active Cooking:** Walks the user through the Prep screen and step-by-step cook flow with inline interactive timers.
- **Strict In-Memory Sandboxing:**
  - **Data Isolation:** All operations performed during the tutorial are isolated in transient RAM state. Absolutely no database records are inserted or deleted in Supabase.
  - **Clean State Persistence:** Inventory additions, consumed items, calories, macro history, and gamification rewards (XP/streaks) earned during the tutorial are not written to the backend DB, ensuring the user's actual profile is completely clean.
- **Tutorial Replay Support:** Added a "Replay Tutorial" action button under the Profile settings screen, allowing users to re-trigger the guided interactive walkthrough at any time.
- **Bug Fixes:** 
  - Resolved a critical layout crash (`type 'ParentData' is not a subtype of type 'StackParentData' in type cast`) caused by wrapping a `Positioned` widget inside a non-Stack wrapper (`IgnorePointer`) in `tutorial_guide_overlay.dart`. Proper layout ordering restored.
  - Fixed an unresponsive "Load Mock Ingredients" button on the Scan step of the tutorial. The overlay card's empty `onPrimaryPressed` callback was wired to set the state to `shelfAdded`, enabling smooth navigation back to the Shelf with populated ingredients.
  - Bypassed repeated onboarding (nickname/preferences prompts) on every login. The `AuthGate` now queries the database upon login. If a user profile is found in the `users` table with a non-empty username or display name, they are automatically marked as onboarded (`onboarding_complete = true`), and the setup screens are bypassed.
  - Added onboarding state cleanup to the signout handler to ensure correct onboarding state evaluations when switching accounts on the same device.
  - Resolved async `setState` warnings in `cook_screen.dart` via checking widget `mounted` state.
