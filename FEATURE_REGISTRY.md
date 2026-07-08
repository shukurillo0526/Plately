# 🍽️ Plately — Feature Registry

> **Complete catalog of every feature, screen, widget, service, and interaction in the Plately app.**
> Last updated: 2026-07-08 (v0.1.8)

---

## Table of Contents

- [1. Navigation & App Shell](#1-navigation--app-shell)
- [2. Cook Mode — Screens](#2-cook-mode--screens)
- [3. Scan Feature](#3-scan-feature)
- [4. Living Shelf (Inventory)](#4-living-shelf-inventory)
- [5. Explore & Social](#5-explore--social)
- [6. Order Mode](#6-order-mode)
- [7. Profile & Settings](#7-profile--settings)
- [8. Gamification](#8-gamification)
- [9. Onboarding & Auth](#9-onboarding--auth)
- [10. Core Widgets (Shared)](#10-core-widgets-shared)
- [11. Core Services](#11-core-services)
- [12. Backend API Endpoints](#12-backend-api-endpoints)
- [13. Localization](#13-localization)
- [14. Models & Providers](#14-models--providers)

---

## 1. Navigation & App Shell

### 1.1 AppShell
- **File:** `lib/main.dart` → `AppShell`, `_AppShellState`
- **Purpose:** Root container for the entire app after authentication. Manages navigation tabs and mode switching.
- **UI Elements:**
  - **Mode Switch Bar** (`_ModeSwitchBar`) — Top bar showing "Plately" brand name + profile avatar icon
  - **Screen Content** — `AnimatedSwitcher` that fades between tabs
  - **Cooking Mini-Player** (`CookingMiniPlayer`) — Persistent floating bar at bottom when a cooking session is active
  - **Bottom Navigation** (`DualModeNavBar`) — Three-tab nav: Cook, Scan, Shelf
- **Interactions:**
  - Tap profile avatar → navigates to `ProfileScreen`
  - Tap nav tabs → switch between Cook, Scan, Shelf screens
  - Notification action buttons (Next, Pause, Stop) wired to `CookingSessionNotifier`
  - First-time tutorial overlay auto-shown via `_showHomeTutorialIfNeeded()`
- **Location:** Bottom of every screen (persistent shell)

### 1.2 DualModeNavBar
- **File:** `lib/core/widgets/dual_mode_nav_bar.dart` → `DualModeNavBar`, `NavItem`, `_CenterButton`, `_NavButton`
- **Purpose:** Custom animated bottom navigation bar with a raised center button (Scan).
- **UI Elements:**
  - Three nav buttons with icons + labels
  - Center button is elevated/circular (camera icon for Scan)
  - Active indicator animation
- **Visual:** Glassmorphic semi-transparent background, smooth icon transitions

### 1.3 ModeSwitchBar
- **File:** `lib/main.dart` → `_ModeSwitchBar`
- **Purpose:** Top app bar in the shell. Shows "Plately" title and profile button.
- **UI Elements:** Brand text (left), profile `CircleAvatar` (right)
- **Interactions:** Tap profile → `ProfileScreen`

---

## 2. Cook Mode — Screens

### 2.1 Cook Screen (Home / Recipe Browser)
- **File:** `lib/features/cook/presentation/screens/cook_screen.dart` → `CookScreen`, `_CookScreenState`
- **Purpose:** Main recipe discovery screen. Shows AI-matched recipes organized by match quality tabs.
- **UI Elements:**
  - **"What to Cook?" header** with action icons: Search, AI Generate, My Recipes, Cook Feeds, Refresh
  - **Tab Bar** with 5 tabs:
    - 🟢 **Perfect** — 100% ingredient match
    - ✨ **For You** — AI personalized recommendations
    - 🍳 **Use It Up** — recipes using expiring ingredients (count shown)
    - 🛒 **Almost** — recipes missing 1-2 ingredients (count shown)
    - 🔍 **Explore** — all recipes (count shown)
  - **Recipe Cards** (`_RecipeCard`) — Each card shows:
    - Recipe image (cached network image with shimmer placeholder)
    - Recipe title
    - Cuisine/origin label
    - Match percentage badge (color-coded: green ≥80%, orange ≥50%, red <50%)
    - Prep time chip
    - Difficulty chip
    - Ingredient count chip
  - **Search** (`_RecipeSearchDelegate`) — Full-screen search with results and suggestions
  - **AI Recipe Generator** (`_GeneratedRecipeSheet`) — Bottom sheet to generate custom recipes with AI
  - **Shimmer Loading** — Skeleton placeholders while data loads
  - **Empty State** — "No Perfect recipes yet" with icon when no matches
- **Interactions:**
  - Tap recipe card → `RecipeDetailScreen`
  - Tap search icon → opens search delegate
  - Tap AI sparkle icon → opens AI recipe generator bottom sheet
  - Tap clipboard icon → opens `MyRecipesScreen`
  - Tap play/feeds icon → opens `CookFeedsScreen`
  - Tap refresh icon → re-fetches recipes
  - Pull to refresh
  - Swipe between tabs
- **Data Source:** Supabase `recipes` table + `recipe_translations` + user inventory matching

### 2.2 Recipe Detail Screen
- **File:** `lib/features/cook/presentation/screens/recipe_detail_screen.dart` → `RecipeDetailScreen`, `_RecipeDetailScreenState`
- **Purpose:** Full recipe view with ingredients, steps, nutrition, and social features.
- **UI Elements:**
  - **SliverAppBar** (expandable, 300px) with:
    - Recipe hero image
    - Gradient overlay (transparent → surface)
    - Back button, Share button, Report/Flag button
  - **Quick Info Chips** (`_QuickChip`) — Prep time, servings, difficulty, cuisine
  - **Thumbs Up/Down Voting** — Like/dislike with counts
    - `_likes`, `_dislikes`, `_userVote` state
    - `_loadSentiment()` — fetches current votes from API
    - `_voteSentiment()` — submits vote to API
  - **Ingredients Section** with:
    - **Ingredient Rows** (`_IngredientRow`) — Shows ingredient name, quantity, unit
    - Have/Need indicators (green ✓ / red ✕ based on shelf inventory)
    - Serving scaler slider
  - **Steps Section** with:
    - **Step Cards** (`_StepCard`) — Numbered step cards with instruction text
    - Timer indicator if step has a duration
    - Step icons (🔥 heat, 🥣 mix, 🔪 prep, etc.)
  - **Nutrition Info** — Calories, protein, carbs, fat bars
  - **Report/Feedback Sheet** (`_showFeedbackReportSheet`) — Bottom sheet with:
    - Category chips (`_FeedbackCategoryChip`): Inaccurate, Offensive, Spam, Translation, Other
    - Free text input
    - Submit button → `submitFeedback()` API
  - **"Start Cooking" Button** — Large CTA at bottom → `RecipePrepScreen`
- **Interactions:**
  - Scroll for parallax SliverAppBar
  - Tap 👍/👎 to vote
  - Tap 🚩 to report
  - Tap share → native share sheet
  - Tap "Start Cooking" → `RecipePrepScreen`
  - Adjust servings → ingredient quantities update

### 2.3 Recipe Prep Screen
- **File:** `lib/features/cook/presentation/screens/recipe_prep_screen.dart` → `RecipePrepScreen`, `_RecipePrepScreenState`
- **Purpose:** Pre-cooking setup. Review ingredients, check what you have, toggle beginner mode.
- **UI Elements:**
  - Recipe name header
  - **Ingredient Checklist** — Checkboxes for each ingredient with have/need status
  - **Beginner Mode Toggle** (`SwitchListTile`) — `_isBeginnerMode` state variable
    - When ON: cooking steps show simplified `beginner_text` instead of standard instructions
  - **Status Chips** (`_StatusChip`) — "Ready" / "Missing items" indicators
  - **Missing Ingredients Warning** — Shows which ingredients you don't have
  - **"Start Cooking" Button** — navigates to `CookingRunScreen` with `isBeginnerMode` parameter
- **Interactions:**
  - Check/uncheck ingredients
  - Toggle beginner mode switch
  - Tap "Start Cooking" → `CookingRunScreen`

### 2.4 Cooking Run Screen
- **File:** `lib/features/cook/presentation/screens/cooking_run_screen.dart` → `CookingRunScreen`, `_CookingRunScreenState`
- **Purpose:** Active cooking walkthrough. Step-by-step guided cooking with timer and AI assistant.
- **Parameters:** `isBeginnerMode` (from prep screen)
- **UI Elements:**
  - **Progress Bar** — Linear progress showing current step / total steps
  - **Step Indicator** — "Step X of Y"
  - **Cooking Step Card** (`_CookingStepCard`) — Shows step info in a vertically scrollable card (`SingleChildScrollView`) to prevent clipping:
    - Step icon (context-aware: heat, mix, prep, etc.)
    - Step instruction text (uses `beginner_text` when beginner mode is ON)
    - Edit icon for notes
  - **Step Timer Widget** (`StepTimerWidget`) — Circular countdown timer with:
    - Timer ring animation (`_TimerRingPainter`)
    - Start/Pause/Resume/Stop buttons (`_ActionButton`)
    - Time remaining display
    - Auto-starts if step has a timer duration
  - **AI Chat Assistant** — Bottom section with:
    - "Ask a question or request substitution..." input field
    - Context-aware prompting (includes recipe, current step, beginner mode)
    - Sends to `chatWithAssistant()` API
  - **"Next Step" Button** — Advances to next step
  - **Cooking Mini-Player** (external) — Appears on other screens while cooking
- **Interactions:**
  - Tap "Next Step" → advance step
  - Swipe to go back/forward steps
  - Start/Pause/Resume timer
  - Type question → AI chat response
  - Navigate away → mini-player appears, cooking continues
- **Background Features:**
  - Session persisted to Hive (survives app restart)
  - Notification with progress bar and action buttons (Android)
  - Wakelock to keep screen on

### 2.5 Cooking Reward Screen
- **File:** `lib/features/cook/presentation/screens/cooking_reward_screen.dart` → `CookingRewardScreen`, `_CookingRewardScreenState`
- **Purpose:** Post-cooking celebration. Shows stats, XP earned, streak info, and presents the portion logging and leftover storage sheet.
- **UI Elements:**
  - 🎉 Celebration animation
  - **Recipe Completed** title
  - **Stat Cards** (`_StatCard`):
    - Total cooking time
    - Steps completed
    - XP earned
  - Cooking streak counter
  - Share button
- **Interactions:**
  - View stats
  - Share completion
  - Return to home / Complete → triggers the **Cook Portions Sheet** (`CookPortionsSheet`) to specify immediate consumption vs leftovers storage before returning to the main dashboard.

### 2.6 Cook Feeds Screen (Video Recipes)
- **File:** `lib/features/cook/presentation/screens/cook_feeds_screen.dart` → `CookFeedsScreen`, `_CookFeedsScreenState`
- **Purpose:** TikTok/Reels-style vertical video feed of cooking videos.
- **UI Elements:**
  - **Video Cards** (`_CookVideoCard`) — Full-screen video player cards
  - **Side Buttons** (`_SideBtn`) — Like, Comment, Share, Bookmark
  - **Recipe Overlay** (`_RecipeOverlay`) — Recipe info overlay on video
  - **Channel Avatar** (`_ChannelAvatar`) — Creator profile picture
- **Interactions:**
  - Swipe up/down to browse videos
  - Tap side buttons for social interactions
  - Tap recipe overlay → recipe detail

### 2.7 My Recipes Screen
- **File:** `lib/features/cook/presentation/screens/my_recipes_screen.dart` → `MyRecipesScreen`, `_MyRecipesScreenState`
- **Purpose:** User's saved/bookmarked/created recipes collection.
- **UI Elements:**
  - List of recipe cards (user's collection)
  - Empty state when no saved recipes
- **Interactions:**
  - Tap recipe → `RecipeDetailScreen`
  - Import new recipe

### 2.8 Recipe Import Screen
- **File:** `lib/features/cook/presentation/screens/recipe_import_screen.dart` → `RecipeImportScreen`, `_RecipeImportScreenState`
- **Purpose:** Import recipes from URLs, text, or YouTube links. AI parses them into structured format.
- **UI Elements:**
  - URL/text input field
  - **Parsed Recipe Preview** (`_ParsedRecipePreview`) — Shows AI-parsed result
  - Import confirmation
- **Interactions:**
  - Paste URL or text → AI parses → preview → save
  - YouTube link → `extractYouTubeRecipe()` API
  - Raw text → `parseRawRecipe()` API

### 2.9 Cooking Mini-Player
- **File:** `lib/features/cook/presentation/widgets/cooking_mini_player.dart` → `CookingMiniPlayer`
- **Purpose:** Spotify-style floating bar shown on all screens when a cooking session is active.
- **UI Elements:**
  - Recipe thumbnail (small)
  - Recipe title
  - Current step indicator
  - Timer countdown (if running)
  - Play/Pause icon
- **Visual:** Gradient background with primary color tint, rounded corners, slide-up animation
- **Interactions:**
  - Tap → navigates back to `CookingRunScreen` with full session
  - Shows on all screens (CookScreen, ShelfScreen, ScanScreen, etc.)

### 2.10 Step Timer Widget
- **File:** `lib/features/cook/presentation/widgets/step_timer_widget.dart` → `StepTimerWidget`, `_StepTimerWidgetState`
- **Purpose:** Visual countdown timer for cooking steps that have time requirements.
- **UI Elements:**
  - Circular ring animation (`_TimerRingPainter`) — fills/empties as time progresses
  - Digital time display (MM:SS)
  - Action buttons (`_ActionButton`): Start, Pause, Resume, Stop
- **Interactions:**
  - Tap Start → countdown begins
  - Tap Pause → freezes
  - Tap Resume → continues
  - Tap Stop → resets
  - Auto-completes with notification alert

### 2.11 Cook Portions Sheet
- **File:** `lib/features/cook/presentation/widgets/cook_portions_sheet.dart` → `CookPortionsSheet`, `_CookPortionsSheetState`
- **Purpose:** Bottom sheet presented upon recipe completion. Handles logging eaten meals and storing leftover portions in the fridge.
- **UI Elements:**
  - **Servings Cooked display** — static read-only text showing total portions cooked (from prep screen servings)
  - **Servings Eaten slider** — interactive slider to select portions eaten immediately (0 to total cooked)
  - **Store Leftovers switch** — toggles whether to save remaining portions to the Shelf
  - **Nutritional Summary** — displays total calories, protein, carbs, and fat to be logged
- **Interactions:**
  - Slide "Eaten" slider → updates leftovers count (`Cooked - Eaten`) and macro summaries
  - Toggle "Store Leftovers" → enables/disables fridge storage
  - Tap "Finish & Log" → executes atomic database transaction (`process_meal_prep`) to deduct ingredients, log nutrition, and optionally create a leftover item on the Shelf

---

## 3. Scan Feature

### 3.1 Scan Screen
- **File:** `lib/features/scan/presentation/screens/scan_screen.dart` → `ScanScreen`, `_ScanScreenState`
- **Purpose:** Multi-mode ingredient scanner. Uses camera for receipt OCR, barcode scanning, and visual ingredient detection.
- **UI Elements:**
  - **Top Tab Bar** with modes:
    - 📸 **Camera** — Visual AI ingredient detection
    - 🧾 **Receipt** — OCR receipt parsing
    - 📊 **Barcode** — Barcode product lookup
    - ✏️ **Manual** — Manual text entry
  - **Camera Preview** — Live camera feed (using `mobile_scanner`)
  - **Mode Tabs** (`_ModeTab`) — Visual tab switcher
  - **Calorie Scan Tab** (`_CalorieScanTab`) — Visual Plate Calorie Scanner. Takes a photo of a prepared meal, estimates portion size and total plate calories/macros in a single optimized pass, lists plate components, and provides interactive **Consume** (logs to diary) and **Cancel** (resets scanner) options.
  - **Manual Entry Sheet** (`_ManualEntryBottomSheet`) — Text input for manual ingredient addition
  - **Results Overlay** — Shows detected items with checkmarks
- **Interactions:**
  - Switch between scan modes
  - Tap capture → sends to appropriate API
  - Camera: `detectIngredients()` → AI vision
  - Receipt: `parseReceipt()` → OCR
  - Barcode: `lookupBarcode()` → product database
  - Manual: text entry → ingredient search
  - Tap detected items → add to shelf
  - After adding → navigates to `AuditScreen`

### 3.2 Audit Screen
- **File:** `lib/features/scan/presentation/screens/audit_screen.dart` → `AuditScreen`, `_AuditScreenState`, `AuditItem`
- **Purpose:** Review and correct AI-detected ingredients before adding to shelf.
- **UI Elements:**
  - List of detected items with:
    - Item name (editable)
    - Category assignment
    - Quantity
    - Expiry date picker
    - Confidence indicator
  - Approve/Edit/Remove individual items
  - "Add All to Shelf" button
- **Interactions:**
  - Edit item details
  - Change categories
  - Set expiry dates
  - Remove incorrect detections
  - Bulk add to inventory

---

## 4. Living Shelf (Inventory)

### 4.1 Living Shelf Screen
- **File:** `lib/features/shelf/presentation/screens/living_shelf_screen.dart` → `LivingShelfScreen`, `_LivingShelfScreenState`
- **Purpose:** Digital fridge/freezer/pantry. Shows all ingredients with freshness status and expiry tracking.
- **UI Elements:**
  - **Zone Tabs** — Fridge, Freezer, Pantry (with item counts)
  - **Inventory Item Cards** (`InventoryItemCard`) — Each shows:
    - Item name (localized)
    - Category emoji
    - Quantity and unit
    - Freshness color bar (green → yellow → red)
    - Days remaining / expired badge
  - **Freshness Overlay** (`FreshnessOverlay`) — Visual urgency indicator
  - **Urgency Pulse** (`UrgencyPulse`) — Pulsing animation for expiring items
  - **Empty State** — "Your [zone] is empty" with illustration
  - **Shimmer Loading** (`ShelfSkeleton`) — Skeleton placeholder
  - **Add Button** — FAB to add items manually
- **Interactions:**
  - Tap item → `InventoryDetailSheet` (bottom sheet with full details)
  - **Swipe Right (Green / Consume)** → triggers a confirmation dialog asking how much is being consumed, logging macros/calories in the diary and calling `consume_inventory_item` or `eat_leftover_portion` Supabase RPCs.
  - **Swipe Left (Red / Discard)** → triggers a warning dialog asking how much is being thrown away, deleting the card or reducing quantity.
  - **Tutorial Guard** → intercepts swipes on items with IDs starting with `'tutorial'` to prevent database API exceptions during onboarding.
  - Tap zone tabs to filter
  - Tap FAB → add ingredient flow
  - Pull to refresh (syncs with Supabase realtime)

### 4.2 Inventory Item Card
- **File:** `lib/features/shelf/presentation/widgets/inventory_item_card.dart` → `InventoryItemCard`
- **Purpose:** Card widget for each inventory item. Integrates interactive swiping behaviors (via `Dismissible` with distinct green/red background states) and displays portions for cooked leftovers.
- **Visual:** Rounded card with emoji, name, portions or weight quantity, colored freshness strip on left edge.

### 4.3 Inventory Detail Sheet
- **File:** `lib/features/shelf/presentation/widgets/inventory_detail_sheet.dart` → `InventoryDetailSheet`, `_InventoryDetailSheetState`
- **Purpose:** Bottom sheet showing full item details with edit/consume/delete actions.
- **UI Elements:**
  - Item name, category, zone
  - Quantity editor (increment/decrement)
  - Expiry date display and picker
  - Freshness assessment (AI-predicted)
  - "Use in Recipe" quick action
  - Delete button with confirmation
- **Interactions:**
  - Edit quantity
  - Change expiry date
  - Mark as consumed
  - Delete item

### 4.4 Freshness Overlay
- **File:** `lib/features/shelf/presentation/widgets/freshness_overlay.dart` → `FreshnessOverlay`, `UrgencyPulse`
- **Purpose:** Visual indicator showing urgency level for expiring items.
- **Visual:** Color-coded overlay (green = fresh, yellow = use soon, red = expired), pulsing animation for urgent items

---

## 5. Explore & Social

### 5.1 Explore Screen
- **File:** `lib/features/explore/presentation/screens/explore_screen.dart` → `ExploreScreen`, `_ExploreScreenState`
- **Purpose:** Social discovery hub with reels, community posts, and bookmarks.
- **UI Elements:**
  - **Tab Bar:** Reels, Community, Bookmarks
  - **Reels Feed** (`_ReelsFeed`) — TikTok-style vertical scroll
    - `_YTReelCard` — YouTube-sourced cooking reel
    - `_ReelCard` — Native cooking reel
    - Side buttons: Like, Comment, Share, Bookmark (`_FeedSideBtn`, `_VerticalAction`)
    - `_VideoRecipeSheet` — Recipe info slide-up
  - **Community Feed** (`_CommunityFeed`) — Social post timeline
    - Uses `CommunityPostCard` shared widget
  - **Bookmarks Sheet** (`_BookmarksSheet`) — Saved content
  - **Info Chips** (`_InfoChip`) — Quick info badges
- **Interactions:**
  - Swipe through reels
  - Like/comment/share/bookmark
  - Tap creator avatar → `CreatorPage`
  - Search → `SocialSearchPage`

### 5.2 Creator Page
- **File:** `lib/features/explore/presentation/screens/creator_page.dart` → `CreatorPage`, `_CreatorPageState`
- **Purpose:** Public profile page for recipe creators.
- **UI Elements:**
  - Profile header with avatar, name, bio
  - **Stat Columns** (`_StatCol`) — Recipes, Followers, Likes
  - Follow button
  - Creator's recipe grid
- **Interactions:**
  - Follow/Unfollow
  - Tap recipe → detail view

### 5.3 Social Search Page
- **File:** `lib/features/explore/presentation/screens/social_search_page.dart` → `SocialSearchPage`, `_SocialSearchPageState`
- **Purpose:** Search for recipes, creators, and tags across the social feed.
- **UI Elements:**
  - Search text field
  - Tag results (`_TagResult`) — Clickable tags
  - Creator results
  - Recipe results
- **Interactions:**
  - Type query → live results
  - Tap result → navigate to content

---

## 6. Order Mode

### 6.1 Order Screen
- **File:** `lib/features/order/presentation/screens/order_screen.dart` → `OrderScreen`, `_OrderScreenState`
- **Purpose:** Food ordering hub. Browse nearby restaurants, deals, and popular items.
- **UI Elements:**
  - **Location Header** (`_LocationHeader`) — Current delivery location
  - **Section Headers** (`_SectionHeader`) — Category labels
  - **Smart Action Bar** (`_SmartActionBar`) — Quick action buttons
  - **Deal Cards** (`_DealCard`) — Promotional offers
  - **Restaurant Tiles** (`_RestaurantTile`) — Restaurant listing with:
    - Restaurant image, name, rating
    - Delivery time and distance
    - Service badges (`_ServiceBadge`) — Delivery, Pickup, Dine-in
  - **Restaurant Menu Sheet** (`_RestaurantMenuSheet`) — Quick menu preview
  - **Popular Items** (`_PopularItemsSection`, `_PopularItemCard`) — Trending dishes
  - **Stat Chips** (`_StatChip`) — Rating, time, price range
  - **Menu Item Tiles** (`_MenuItemTile`) — Individual menu items with add to cart
  - **Empty State** (`_EmptyState`) — When no restaurants found
- **Interactions:**
  - Tap restaurant → `RestaurantDetailPage`
  - Tap menu item → add to cart
  - Search restaurants
  - Filter by cuisine/price/distance

### 6.2 Restaurant Detail Page
- **File:** `lib/features/order/presentation/screens/restaurant_detail_page.dart` → `RestaurantDetailPage`, `_RestaurantDetailPageState`
- **Purpose:** Full restaurant view with menu, reviews, and reservation.
- **UI Elements:**
  - Hero image header
  - **Tab Bar** (`_TabBarDelegate`, `_TabInfo`):
    - **Menu Tab** (`_MenuTab`) — Full menu with categories, items (`_MenuItemCard`)
    - **Reserve Tab** (`_ReserveTab`) — Table reservation form
    - **Location Tab** (`_LocationTab`) — Map and directions
    - **Reviews Tab** (`_ReviewsTab`) — Customer reviews (`_Review`)
  - **Cart Bar** (`_CartBar`) — Floating cart summary at bottom
- **Interactions:**
  - Browse menu and add items
  - Make reservation
  - View location
  - Read/write reviews
  - Tap cart → `CheckoutScreen`

### 6.3 Checkout Screen
- **File:** `lib/features/order/presentation/screens/checkout_screen.dart` → `CheckoutScreen`, `_CheckoutScreenState`
- **Purpose:** Order review and payment.
- **UI Elements:**
  - Cart items list
  - Delivery/pickup toggle
  - Address input
  - Payment method selector
  - Order total with breakdown
  - "Place Order" button
  - **Order Confirmation** (`_OrderConfirmationScreen`) — Success screen
- **Interactions:**
  - Edit quantities
  - Add special instructions
  - Select payment method
  - Place order

### 6.4 Order History Screen
- **File:** `lib/features/order/presentation/screens/order_history_screen.dart` → `OrderHistoryScreen`, `_OrderHistoryScreenState`
- **Purpose:** Past orders list.
- **UI Elements:**
  - **Order Cards** (`_OrderCard`) — Each shows restaurant, items, total, date
  - **Status Chips** (`_StatusChip`) — Pending, Preparing, Delivered, Cancelled
  - **Status Progress** (`_StatusProgress`) — Timeline visualization
- **Interactions:**
  - Tap order → view details
  - Reorder past orders

### 6.5 Order Feeds Screen
- **File:** `lib/features/order/presentation/screens/order_feeds_screen.dart` → `OrderFeedsScreen`, `_OrderFeedsScreenState`
- **Purpose:** Restaurant-focused video feed (like TikTok for restaurants).
- **UI Elements:**
  - `_FeedItem`, `_OrderVideoCard` — Video cards of restaurant dishes
  - `_SideBtn` — Social action buttons
  - `_RestaurantAvatar` — Restaurant profile icon
- **Interactions:**
  - Swipe through food videos
  - Tap to order from restaurant

### 6.6 Incoming Orders Page
- **File:** `lib/features/order/presentation/screens/incoming_orders_page.dart` → `IncomingOrdersPage`, `_IncomingOrdersPageState`
- **Purpose:** For restaurant owners — view and manage incoming customer orders.
- **Interactions:**
  - Accept/reject orders
  - Update order status

---

## 7. Profile & Settings

### 7.1 Profile Screen
- **File:** `lib/features/profile/presentation/screens/profile_screen.dart` → `ProfileScreen`, `_ProfileScreenState`
- **Purpose:** User profile hub. Settings, stats, and feature access.
- **UI Elements:**
  - Profile header (avatar, name, email)
  - **Section Cards** (`_SectionCard`) — Grouped settings
  - **Animated Stat Tiles** (`_AnimatedStatTile`) — Recipes cooked, streak, XP
  - **Badge Grid** (`_BadgeTile`) — Earned badges display
  - **Flavor Radar** (`_FlavorRadarPainter`) — Small flavor profile preview
  - **Shopping Items** (`_ShoppingItemTile`) — Quick shopping list view
  - **Settings Rows** (`_SettingsRow`) — Setting toggles and navigators:
    - Language selector
    - Theme toggle (dark/light)
    - Notifications toggle
    - Region selector
    - Flavor Profile link → `FlavorProfilePage`
    - Gamification link → `GamificationPage`
    - Meal Planner link → `MealPlannerPage`
    - Nutrition Tracker link → `NutritionTrackerPage`
    - Shopping List link → `ShoppingListPage`
    - Creator Dashboard link → `CreatorDashboardPage`
    - Restaurant Dashboard link → `RestaurantDashboardPage`
  - **Social Stats** (`_SocialStat`) — Followers, following, recipes shared
  - Sign Out button
- **Interactions:**
  - Change language (en, uz, uz_Cyrl, ru, ko)
  - Toggle dark/light theme
  - Navigate to sub-pages
  - Sign out

### 7.2 Flavor Profile Page
- **File:** `lib/features/profile/presentation/screens/flavor_profile_page.dart` → `FlavorProfilePage`, `_FlavorProfilePageState`
- **Purpose:** Visual flavor preference radar chart. Users can adjust their taste preferences.
- **UI Elements:**
  - **Radar Chart** (`_RadarPainter`) — Spider/radar chart with axes:
    - Sweet, Salty, Sour, Bitter, Spicy, Umami
  - Sliders for each axis
  - Save button
- **Interactions:**
  - Adjust flavor sliders
  - Save preferences → influences recipe recommendations

### 7.3 Gamification Page
- **File:** `lib/features/profile/presentation/screens/gamification_page.dart` → `GamificationPage`, `_GamificationPageState`
- **Purpose:** Detailed XP, levels, badges, and achievements view.
- **UI Elements:**
  - Current level and XP bar
  - **Stat Cards** (`_StatCard`) — Total cooks, streak, badges earned
  - Badge collection grid
  - Level progression chart
- **Interactions:**
  - View badges (earned and locked)
  - Track progress toward next level

### 7.4 Meal Planner Page
- **File:** `lib/features/profile/presentation/screens/meal_planner_page.dart` → `MealPlannerPage`, `_MealPlannerPageState`
- **Purpose:** Weekly meal planning calendar.
- **UI Elements:**
  - Day-of-week headers
  - **Meal Type Rows** (`_MealTypeRow`) — Breakfast, Lunch, Dinner, Snack
  - Recipe slots (drag-and-drop or tap to assign)
  - Add meal button
- **Interactions:**
  - Assign recipes to meal slots
  - Delete meal plans
  - Auto-generate shopping list from planned meals

### 7.5 Nutrition Tracker Page
- **File:** `lib/features/profile/presentation/screens/nutrition_tracker_page.dart` → `NutritionTrackerPage`, `_NutritionTrackerPageState`
- **Purpose:** Daily calorie and macro tracking with visual ring charts.
- **UI Elements:**
  - **Ring Charts** (`_RingPainter`) — Circular progress for:
    - Calories (daily target vs consumed)
    - Protein
    - Carbs
    - Fat
  - Daily log list
  - Date picker
- **Interactions:**
  - View daily nutrition
  - Navigate between dates
  - Log food manually
  - Scan food for calorie estimation

### 7.6 Shopping List Page
- **File:** `lib/features/profile/presentation/screens/shopping_list_page.dart` → `ShoppingListPage`, `_ShoppingListPageState`
- **Purpose:** Grocery shopping list with check-off functionality.
- **UI Elements:**
  - **Item Tiles** (`_ItemTile`) — Checkable items with name and quantity
  - Add item input
  - Clear checked button
  - Auto-generated from meal plans or missing recipe ingredients
- **Interactions:**
  - Add items
  - Check/uncheck items
  - Delete items
  - Generate from recipe (`generateShoppingList()` API)

### 7.7 Creator Dashboard Page
- **File:** `lib/features/profile/presentation/screens/creator_dashboard_page.dart` → `CreatorDashboardPage`, `_CreatorDashboardPageState`
- **Purpose:** Dashboard for recipe creators — analytics and content management.
- **UI Elements:**
  - **Stat Cards** (`_StatCard`) — Views, likes, followers, revenue
  - Recipe performance list
  - Upload new content button
- **Interactions:**
  - View analytics
  - Manage published recipes
  - Upload new content → `EnhancedPostUploadForm`

### 7.8 Post Upload Form
- **File:** `lib/features/profile/presentation/screens/post_upload_form.dart` → `EnhancedPostUploadForm`, `_EnhancedPostUploadFormState`
- **Purpose:** Create and publish community posts with recipe attachments.
- **UI Elements:**
  - Image/video picker
  - Caption text field
  - Recipe attachment widget
  - Tags input
  - Publish button
- **Interactions:**
  - Select media
  - Write caption
  - Attach recipe
  - Add tags
  - Publish post

### 7.9 Restaurant Dashboard Page
- **File:** `lib/features/profile/presentation/screens/restaurant_dashboard_page.dart` → `RestaurantDashboardPage`, `_RestaurantDashboardPageState`
- **Purpose:** Restaurant owner management panel.
- **UI Elements:**
  - **Stat Tiles** (`_StatTile`) — Orders today, revenue, rating
  - **Action Cards** (`_ActionCard`) — Quick actions (menu edit, hours, etc.)
  - **Analytic Tiles** (`_AnalyticTile`) — Performance metrics
  - **Dialog Fields** (`_DialogField`) — Inline edit dialogs
- **Interactions:**
  - Manage menu items
  - View order analytics
  - Update restaurant info
  - View incoming orders → `IncomingOrdersPage`

---

## 8. Gamification

### 8.1 XP & Leveling System
- **File:** `lib/features/gamification/domain/badges.dart` → `XpRewards`
- **Purpose:** Defines XP rewards for actions and level thresholds.
- **Methods:** `levelFromXp()`, `levelProgress()`
- **XP Triggers:** Cooking a recipe, scanning ingredients, adding to shelf, maintaining streaks

### 8.2 Gamification Repository
- **File:** `lib/features/gamification/data/gamification_repository.dart` → `GamificationRepository`
- **Purpose:** Manages badge earning, XP tracking, and streak calculation via Supabase.

### 8.3 XP Toast
- **File:** `lib/features/gamification/presentation/widgets/xp_toast.dart` → `_XpToastAnimation`
- **Purpose:** Animated popup showing XP earned after actions.
- **Visual:** Floating "+50 XP" toast with bounce-in animation
- **Trigger:** `showXpReward()` — Called after cooking, scanning, etc.

---

## 9. Onboarding & Auth

### 9.1 Auth Screen
- **File:** `lib/features/auth/presentation/screens/auth_screen.dart` → `AuthScreen`, `_AuthScreenState`
- **Purpose:** Login/signup screen.
- **UI Elements:**
  - **Auth Buttons** (`_AuthButton`) — Google Sign-In, Email/Password, Anonymous
  - **Text Fields** (`_TextField`) — Email, Password inputs
  - Toggle between Login and Sign Up modes
  - "Continue as Guest" option
- **Interactions:**
  - Google OAuth sign-in
  - Email/password authentication
  - Anonymous guest access
  - Switch login ↔ signup

### 9.2 Onboarding Screen
- **File:** `lib/features/onboarding/presentation/screens/onboarding_screen.dart` → `OnboardingScreen`, `_OnboardingScreenState`
- **Purpose:** First-time user welcome walkthrough (shown once after signup).
- **UI Elements:**
  - **Onboarding Pages** (`_OnboardingPage`) — Swipeable pages with:
    - Illustration/emoji
    - Feature title
    - Feature description
  - Page indicator dots
  - Skip button
  - "Get Started" button on last page
- **Interactions:**
  - Swipe through pages
  - Tap Skip → go to app
  - Tap "Get Started" → mark onboarding complete, go to app

### 9.3 Auth Gate
- **File:** `lib/main.dart` → `_AuthGate`, `_AuthGateState`
- **Purpose:** Route guard that directs to AuthScreen, OnboardingScreen, or AppShell based on auth state.
- **Logic:**
  - No session → `AuthScreen`
  - Session + not onboarded → `OnboardingScreen`
  - Session + onboarded → `AppShell`

---

## 10. Core Widgets (Shared)

### 10.1 Tutorial Overlay
- **File:** `lib/core/widgets/tutorial_overlay.dart` → `TutorialOverlay`, `_TutorialOverlayState`, `TutorialStep`
- **Purpose:** Spotlight-based tutorial walkthrough system. Shows steps with highlighted UI areas.
- **Visual:** Dark overlay with spotlight cutout, tooltip bubble with emoji, title, description
- **Painter:** `_SpotlightPainter` — Custom painter for spotlight effect
- **Usage:** Home tutorial (3 steps: Cook, Scan, Shelf), shown once via `TutorialService`

### 10.2 Comment Sheet
- **File:** `lib/core/widgets/comment_sheet.dart` → `CommentSheet`, `_CommentTile`
- **Purpose:** Bottom sheet for viewing and posting comments on recipes/posts.
- **UI Elements:** Comment list with avatars, text input, send button

### 10.3 Community Post Card
- **File:** `lib/core/widgets/community_post_card.dart` → `CommunityPostCard`, `_CommunityPostCardState`
- **Purpose:** Social media-style post card for the community feed.
- **UI Elements:** User avatar, username, post image, caption, like/comment/share buttons, timestamp

### 10.4 Recipe Attachment Widget
- **File:** `lib/core/widgets/recipe_attachment_widget.dart` → `RecipeAttachmentWidget`, `RecipeAttachmentResult`, `NewRecipeData`
- **Purpose:** Widget for attaching a recipe to a community post.
- **Sub-widgets:** `_RecipeTile`, `_FormField`, `_NumberPicker`

### 10.5 Region Picker Sheet
- **File:** `lib/core/widgets/region_picker_sheet.dart` → `RegionPickerSheet`, `_RegionPickerSheetState`
- **Purpose:** Bottom sheet to select user's region/country for localized content.

### 10.6 Shimmer Loading
- **File:** `lib/core/widgets/shimmer_loading.dart` → `ShimmerBox`, `ShelfSkeleton`, `RecipeListSkeleton`, `ProfileSkeleton`
- **Purpose:** Animated loading placeholder skeletons for different screens.
- **Visual:** Silver/gray gradient animation sweeping left-to-right

### 10.7 Slide-In Item
- **File:** `lib/core/widgets/slide_in_item.dart` → `SlideInItem`, `_SlideInItemState`
- **Purpose:** Animation wrapper that slides children in from the side with staggered delay.

### 10.8 Story Ring & Story Viewer
- **File:** `lib/core/widgets/story_ring.dart` → `StoryRing`, `_AddStoryAvatar`, `_StoryAvatar`
- **File:** `lib/core/widgets/story_viewer.dart` → `StoryViewer`, `_StoryViewerState`
- **Purpose:** Instagram-style story circles and full-screen story viewer.
- **Visual:** Gradient ring around avatar, full-screen viewer with progress bars

### 10.9 Voice Command FAB
- **File:** `lib/core/widgets/voice_command_fab.dart` → `VoiceCommandFab`, `_VoiceCommandFabState`
- **Purpose:** Floating action button for voice commands during cooking.
- **Visual:** Microphone icon, pulsing animation while listening
- **Usage:** Available during cooking for hands-free control

### 10.10 YouTube Embed
- **File:** `lib/core/widgets/youtube_embed.dart` → `YouTubeEmbed`
- **Purpose:** Embedded YouTube player for recipe videos.
- **Platform variants:** `youtube_embed_stub.dart` (mobile), `youtube_embed_web.dart` (web)

### 10.11 Empty State Illustration
- **File:** `lib/core/widgets/empty_state_illustration.dart` → `EmptyStateIllustration`, `_EmptyStateIllustrationState`
- **Purpose:** Reusable empty state with animated icon, title, and subtitle.

### 10.12 Mode Switch
- **File:** `lib/core/widgets/mode_switch.dart` → `ModeSwitch`, `_ModeTab`
- **Purpose:** Toggle between Cook mode and Order mode.

---

## 11. Core Services

### 11.1 API Service
- **File:** `lib/core/services/api_service.dart`
- **Purpose:** Central HTTP client for all backend API calls.
- **Key Methods:** `parseReceipt()`, `recognizeImage()`, `detectIngredients()`, `generateRecipe()`, `suggestSubstitute()`, `parseRawRecipe()`, `addInventoryItem()`, `searchIngredients()`, `analyzeCalories()`, `logNutrition()`, `translateRecipe()`, `lookupBarcode()`, `chatWithAssistant()`, `submitFeedback()`, `getRecipeSentiment()`, `recordCook()`, `extractYouTubeRecipe()`, `generateShoppingList()`, `predictExpiry()`, `consumeRecipeIngredients()`, and more.

### 11.2 App Settings
- **File:** `lib/core/services/app_settings.dart`
- **Purpose:** Manages app-wide settings (theme, language, app mode).
- **Persisted via:** SharedPreferences

### 11.3 Auth Helper
- **File:** `lib/core/services/auth_helper.dart`
- **Purpose:** Convenience methods for current user info.
- **Methods:** `currentUserId`, `isAuthenticated`, `isAnonymousGuest`, `currentUserName`

### 11.4 Cache Service
- **File:** `lib/core/services/cache_service.dart`
- **Purpose:** Local caching layer for inventory and recipes using Hive.
- **Methods:** `isInventoryStale()`, `isRecipesStale()`, `saveLocalRecipe()`, `localRecipeCount()`

### 11.5 Cart Service
- **File:** `lib/core/services/cart_service.dart`
- **Purpose:** Shopping cart management for Order mode.
- **Methods:** `addItem()`, `decrementItem()`, `removeItem()`, `updateQuantity()`, `updateInstructions()`, `setOrderType()`, `getQuantity()`, `clear()`

### 11.6 Cooking Notification Service
- **File:** `lib/core/services/cooking_notification_service.dart`
- **Purpose:** Persistent notifications during cooking sessions (Android/iOS only, no-op on desktop).
- **Features:**
  - Ongoing "Now Cooking" notification (non-dismissible)
  - Timer countdown updates
  - Action buttons: Next Step, Pause/Resume, Stop
  - Timer completion alarm with vibration
  - Auto-dismiss on session end

### 11.7 Location Service
- **File:** `lib/core/services/location_service.dart` → `LocationService`, `Region`
- **Purpose:** GPS location, distance calculation, and region detection.
- **Methods:** `distanceTo()`, `formatDistance()`

### 11.8 Notification Service
- **File:** `lib/core/services/notification_service.dart` → `NotificationService`
- **Purpose:** General push notification management (not cooking-specific).

### 11.9 Order Service
- **File:** `lib/core/services/order_service.dart` → `OrderService`, `UserOrder`
- **Purpose:** Order lifecycle management (create, track, cancel).

### 11.10 Recipe Monetization Service
- **File:** `lib/core/services/recipe_monetization_service.dart` → `RecipeMonetizationService`, `RecipeModel`
- **Purpose:** Handles recipe creator monetization (premium recipes, tips).

### 11.11 Restaurant Service
- **File:** `lib/core/services/restaurant_service.dart` → `RestaurantService`, `Restaurant`, `MenuItem`
- **Purpose:** Restaurant data management for Order mode.

### 11.12 Social Service
- **File:** `lib/core/services/social_service.dart` → `SocialService`
- **Purpose:** Social features (follow, like, comment, share).

### 11.13 Story Service
- **File:** `lib/core/services/story_service.dart` → `StoryService`, `StoryItem`, `StoryGroup`
- **Purpose:** Instagram-style stories management.

### 11.14 Tutorial Service
- **File:** `lib/core/services/tutorial_service.dart` → `TutorialService`
- **Purpose:** Tracks which tutorials the user has seen (persisted via SharedPreferences).
- **Tutorials:** `homeWalkthrough` — shown once on first app launch

### 11.15 Video Feed Service
- **File:** `lib/core/services/video_feed_service.dart` → `VideoFeedService`, `VideoFeed`
- **Purpose:** Provides video content for Cook Feeds and Order Feeds screens.

### 11.16 Voice Command Service
- **File:** `lib/core/services/voice_command_service.dart` → `VoiceCommandService`, `VoiceIntent`
- **Purpose:** Speech-to-text voice command processing for hands-free cooking.
- **Uses:** `speech_to_text` package
- **Intents:** Navigate steps, set timer, ask question, etc.

### 11.17 Business Service
- **File:** `lib/core/services/business_service.dart`
- **Purpose:** Business logic for restaurant/order operations.

---

## 12. Backend API Endpoints

### 12.1 Vision & Scanning
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/vision/detect-ingredients` | POST | AI visual ingredient detection from camera image |
| `/api/v1/receipt/scan` | POST | OCR receipt parsing |
| `/api/v1/product/{barcode}` | GET | Barcode product lookup |

### 12.2 AI & Recipe Intelligence
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/ai/generate-recipe` | POST | Generate custom recipe from ingredients |
| `/api/v1/ai/substitute` | POST | Suggest ingredient substitutions |
| `/api/v1/ai/cooking-tip` | POST | Get AI cooking tip for a step |
| `/api/v1/ai/chat` | POST | AI cooking assistant chat |
| `/api/v1/ai/normalize-recipe` | POST | Normalize recipe structure |
| `/api/v1/ai/parse-raw` | POST | Parse raw text into recipe format |
| `/api/v1/ai/youtube-recipe` | POST | Extract recipe from YouTube video |
| `/api/v1/ai/translate-recipe` | POST | Translate recipe to another language |
| `/api/v1/ai/translate-titles` | POST | Translate recipe titles batch |
| `/api/v1/ai/rate-translation` | POST | Rate translation quality |
| `/api/v1/ai/shopping-list` | POST | Generate shopping list from recipes |
| `/api/v1/ai/embed` | POST | Create text embedding |
| `/api/v1/ai/embed-batch` | POST | Batch text embeddings |
| `/api/v1/ai/semantic-search` | POST | Semantic recipe search |
| `/api/v1/ai/personalize` | POST | Personalized recipe ranking |
| `/api/v1/ai/cache-stats` | GET | AI cache statistics |

### 12.3 Inventory
| Endpoint / RPC | Method | Purpose |
|----------------|--------|---------|
| `/api/v1/inventory/add-item` | POST | Add item to shelf |
| `/api/v1/inventory/{item_id}` | PATCH | Update inventory item |
| `/api/v1/inventory/{item_id}` | DELETE | Remove inventory item |
| `/api/v1/inventory/consume` | POST | Mark item as consumed |
| `/api/v1/inventory/consume-recipe` | POST | Consume recipe ingredients from shelf |
| `/api/v1/inventory/predict-expiry` | POST | AI-predicted expiry date |
| `/api/v1/inventory/assess-freshness` | POST | AI freshness assessment |
| `/api/v1/ingredients/search` | GET | Search ingredient database |
| `/api/v1/ingredients/fuzzy` | GET | Fuzzy search ingredients |
| `/api/v1/ingredients/resolve` | POST | Resolve ingredient to canonical form |
| RPC: `process_meal_prep` | DB Function | Atomic transaction to deduct ingredients, log cooked macros, and save leftovers |
| RPC: `eat_leftover_portion` | DB Function | Consume cooked leftover portion, log macros, and decrement leftover count |
| RPC: `consume_inventory_item` | DB Function | Consume raw ingredient, compute and log macros, and decrement/delete item |

### 12.4 Calories & Nutrition
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/calories/analyze-image` | POST | Single-pass visual plate portion calorie & macro estimation |
| `/api/v1/calories/analyze` | POST | Analyze food items for nutrition |
| `/api/v1/calories/log` | POST | Log daily nutrition |
| `/api/v1/calories/daily/{user_id}` | GET | Get daily nutrition summary |
| `/api/v1/calories/recipe/{recipe_id}` | GET | Get recipe calorie info |

### 12.5 Feedback
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/feedback/submit` | POST | Submit recipe feedback/report |
| `/api/v1/feedback/recipe/{recipe_id}/sentiment` | GET | Get recipe like/dislike counts |

### 12.6 Recommendations
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/recommendations/{user_id}` | GET | AI-ranked recipe recommendations |

### 12.7 User Data
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/init` | POST | Initialize new user profile |
| `/{user_id}/dashboard` | GET | Get user dashboard data |
| `/profile` | PATCH | Update user profile |
| `/shopping-list` | POST | Add shopping list item |
| `/shopping-list/{item_id}` | PATCH | Toggle shopping item |
| `/shopping-list/{item_id}` | DELETE | Delete shopping item |
| `/meal-plan` | POST | Add meal plan entry |
| `/meal-plan/{meal_id}` | DELETE | Delete meal plan |
| `/cook` | POST | Record completed cook |
| `/engagement` | POST | Track user engagement event |

### 12.8 Orders
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/orders` | POST | Create new order |
| `/orders/{order_id}` | GET | Get order details |
| `/orders/user/{user_id}` | GET | Get user's order history |
| `/orders/active/{user_id}` | GET | Get active orders |
| `/orders/{order_id}/status` | PATCH | Update order status |
| `/orders/{order_id}/cancel` | POST | Cancel order |

### 12.9 Notifications & Health
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/notifications/expiring/{user_id}` | GET | Get expiring item alerts |
| `/api/v1/health` | GET | Server health check |
| `/api/v1/health/ping` | GET | Quick ping |

---

## 13. Localization

### 13.1 Supported Languages
| Code | Language | File |
|------|----------|------|
| `en` | English | `l10n/app_localizations_en.dart` |
| `uz` | Uzbek (Latin) | `l10n/app_localizations_uz.dart` |
| `uz_Cyrl` | Uzbek (Cyrillic) | `l10n/app_localizations_uz.dart` (second class) |
| `ru` | Russian | `l10n/app_localizations_ru.dart` |
| `ko` | Korean | `l10n/app_localizations_ko.dart` |

### 13.2 L10n Helper
- **File:** `lib/core/utils/l10n_helper.dart` → `L10nHelper`
- **Purpose:** Translation helpers for dynamic content (cuisines, units, categories, etc.)
- **Methods:** `translateCuisine()`, `translateUnit()`, `translateNutritionLabel()`, `translatePrepNote()`, `translateCategory()`, `translateLocation()`, `translateState()`, `translateSource()`

---

## 14. Models & Providers

### 14.1 Cooking Session Model
- **File:** `lib/features/cook/models/cooking_session.dart` → `CookingSession`
- **Purpose:** Represents an active cooking session state.
- **Key Fields:** recipeId, recipeTitle, recipeImage, steps, currentStep, totalSteps, timerSeconds, timerStatus, isBeginnerMode
- **Serialization:** `toJsonString()` / `fromJsonString()` — persisted to Hive

### 14.2 Cooking Session Provider
- **File:** `lib/features/cook/providers/cooking_session_provider.dart` → `CookingSessionNotifier`
- **Purpose:** Riverpod 3.x Notifier managing the active cooking session lifecycle.
- **Methods:** `startSession()`, `endSession()`, `advanceStep()`, `previousStep()`, `goToStep()`, `startTimer()`, `pauseTimer()`, `resumeTimer()`, `stopTimer()`
- **Features:** Hive persistence, notification sync, wakelock management

### 14.3 Inventory Item Model
- **File:** `lib/features/shelf/domain/inventory_item.dart` → `InventoryItem`
- **Purpose:** Represents a single inventory item on the shelf.
- **Key Fields:** id, name, category, quantity, unit, zone, expiryDate, addedDate, source
- **Methods:** `localizedName()` — returns translated name based on current locale

### 14.4 Inventory Repository
- **File:** `lib/core/data/inventory_repository.dart` → (InventoryRepository)
- **Purpose:** CRUD operations for inventory items via Supabase with realtime subscription.
- **Methods:** `subscribeRealtime()`, `disposeRealtime()`

### 14.5 User Repository
- **File:** `lib/core/data/user_repository.dart`
- **Purpose:** User profile and preferences data access.

### 14.6 App Providers
- **File:** `lib/core/providers/app_providers.dart`
- **Purpose:** Global Riverpod providers for shopping list, connectivity, etc.
- **Methods:** `addItem()`, `removeItem()`, `toggleItem()`, `clearChecked()`, `clearAll()`, `setOnline()`

---

## 15. Utilities

### 15.1 Category Images
- **File:** `lib/core/utils/category_images.dart`
- **Purpose:** Maps food categories to image URLs and emoji.
- **Methods:** `categoryImageUrl()`, `categoryEmoji()`

### 15.2 Ingredient Icons
- **File:** `lib/core/utils/ingredient_icons.dart` → `IngredientIcons`
- **Purpose:** Maps ingredient names to emoji icons.
- **Method:** `getEmoji()` — e.g., "chicken" → 🍗

### 15.3 Unit Converter
- **File:** `lib/core/utils/unit_converter.dart` → `UnitConverter`
- **Purpose:** Scales recipe quantities, formats measurements, and checks ingredient sufficiency.
- **Methods:** `scale()`, `formatQuantity()`, `simplifyMetric()`, `hasEnough()`

### 15.4 UI Utils
- **File:** `lib/core/utils/ui_utils.dart` → `Haptics`, `SmoothPageRoute`
- **Purpose:** Haptic feedback helpers and smooth page transitions.
- **Methods:** `Haptics.light()`, `Haptics.medium()`, `Haptics.heavy()`, `Haptics.selection()`, `formatCount()`

### 15.5 App Theme
- **File:** `lib/core/theme/app_theme.dart` → `AppTheme`
- **Purpose:** Dark and light theme definitions with custom color scheme, typography, and component themes.

### 15.6 App Info Constants
- **File:** `lib/core/constants/app_info.dart`
- **Purpose:** App version, build number, and other constants.

---

## 16. Security & Hardening Layer (v0.1.8)

### 16.1 Backend Security Utilities
- **File:** `backend/app/core/security.py`
- **Purpose:** Centralized SAST-compliant security helpers.
- **Methods:**
  - `raise_internal_error(logger, message, exc)` — Logs detailed traceback internally while returning sanitized generic error messages to API consumers.
  - `sanitize_search_query(query)` — Strips PostgREST filter injection symbols before executing database queries.
  - `mask_user_id(user_id)` — Obfuscates user UUIDs for GDPR-compliant PII logging.
  - `validate_image_upload(file)` — Validates uploaded image content type, magic bytes, and size limits.

### 16.2 HTTP Security Headers & Middleware
- **File:** `backend/app/main.py`
- **Purpose:** Enforces production security headers across all API responses (`Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`).

### 16.3 Client Runtime Environment Hardening
- **File:** `frontend/lib/main.dart`
- **Purpose:** Validates environment variable definitions (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) passed via `--dart-define`, failing fast in release builds if credentials are missing.
