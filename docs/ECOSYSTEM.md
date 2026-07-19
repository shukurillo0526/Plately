# Plately Smart Kitchen Ecosystem

This document reflects the exact feature set currently available in the Plately consumer app across the 4 primary launch tabs, alongside the broader strategic vision for the platform.

## Flow & Detailed Feature Breakdown

### 📱 Consumer App (Existing Features)

*   **🍳 Cook Mode**
    *   **5-Tier Recommendation Engine:** Tailored algorithms for *Perfect Match*, *For You*, *Use It Up*, *Almost There*, and *Explore*.
    *   **Gemini AI Recipe Generator:** Generates recipes strictly from inventory constraints or entirely freeform.
    *   **Cuisine Discovery & Sorting:** Dynamic filtering by global cuisines.
    *   **Interactive Recipe Execution:** Step-by-step cooking interface with automated ingredient portioning.
    *   **Vertical Recipe Feeds:** Swipeable video-style feeds for recipe discovery.
    *   **Post-Cook Rewards:** Gamified XP drops upon completing a cooking session.

*   **🥫 Shelf (Living Shelf)**
    *   **Smart Ingredient Tracking:** Categorized storage (Produce, Meat, Dairy, Pantry, etc.) with visual expiration monitoring.
    *   **Automated Lifecycle:** Auto-depletion of ingredients from the shelf upon finishing a recipe.
    *   **Manual Management:** Add, edit, and delete functionality with smart icon/emoji pairing.

*   **📸 Scanning Suite**
    *   **AI Receipt Parsing:** Extracts and categorizes items from grocery receipts via camera or gallery import.
    *   **Live Barcode Scanner:** Real-time UPC barcode scanning for instant item identification.
    *   **Food Photo Recognition:** Direct AI recognition of loose ingredients (e.g., loose vegetables).
    *   **Audit Flow:** Manual review screen to confirm or correct AI-extracted items before adding to the shelf.

*   **👤 Profile (Health & Social)**
    *   **Gamification Dashboard:** Visual XP progress, level progression, activity streaks, and unlockable badges.
    *   **Flavor Profile Analytics:** Radar matrix plotting taste preferences (Sweet, Salty, Sour, Bitter, Umami, Spicy).
    *   **Nutrition Tracker:** Macro-nutrient and caloric tracking against user health goals.
    *   **Meal Planner:** 7-day calendar view for scheduling upcoming recipes.
    *   **Smart Shopping List:** Interactive checklist that auto-syncs across devices.
    *   **Social & Creator Hub:** Follower tracking, user-generated post uploads, and creator/restaurant dashboards.

### 🌐 Vision (Future Strategy)

*   **Smart Kitchen IoT**
    *   **Smart Fridge Integration:** Camera integration to auto-update the Living Shelf passively.
    *   **Smart Scale Connectivity:** Precision measuring paired directly with Cook Mode instructions.
*   **Hyper-Personalization**
    *   **AI Dietitian:** Automated health goal coaching and macro adherence.
    *   **Family Account Sharing:** Shared Living Shelves and aggregated household flavor profiles.
*   **Order Mode & Commerce**
    *   **Grocery Auto-Cart:** Instantly push missing ingredients to delivery APIs (Instacart, Whole Foods).
    *   **Restaurant Discovery:** Local dining recommendations tailored by the user's AI Flavor Profile.

---

## Ecosystem Map

```mermaid
flowchart LR
    %% Styling to match the dark aesthetic
    classDef root fill:#444b5a,color:#fff,stroke:none,rx:5,ry:5,padding:20px;
    classDef level1 fill:#374149,color:#fff,stroke:none,rx:5,ry:5;
    classDef level2 fill:#374149,color:#fff,stroke:none,rx:5,ry:5;
    classDef level3 fill:#344e41,color:#fff,stroke:none,rx:5,ry:5;

    Root["Plately"]:::root

    %% Level 1
    Root --> App["Consumer App"]:::level1
    Root --> Vision["Vision"]:::level1

    %% Level 2 - App Modules
    App --> Cook["Cook Mode"]:::level2
    App --> Shelf["Living Shelf"]:::level2
    App --> Scan["Scanning Suite"]:::level2
    App --> Profile["Social & Profile"]:::level2

    %% Level 3 - Cook
    Cook --> Rec["5-Tier Recommendations"]:::level3
    Cook --> Gen["Gemini AI Generator"]:::level3
    Cook --> Exec["Interactive Cooking"]:::level3
    Cook --> Feed["Vertical Recipe Feeds"]:::level3
    Cook --> Rew["Gamified Cooking Rewards"]:::level3

    %% Level 3 - Shelf
    Shelf --> Cat["Categorized Tracking"]:::level3
    Shelf --> Exp["Expiration Monitoring"]:::level3
    Shelf --> Dep["Auto-Depletion"]:::level3
    Shelf --> Man["Manual Management"]:::level3

    %% Level 3 - Scan
    Scan --> Receipt["AI Receipt Parsing"]:::level3
    Scan --> Barcode["Live Barcode Scanner"]:::level3
    Scan --> Photo["Food Photo Recognition"]:::level3
    Scan --> Audit["Extraction Audit Flow"]:::level3

    %% Level 3 - Profile
    Profile --> Gam["Gamification & Badges"]:::level3
    Profile --> Flav["Flavor Profile Matrix"]:::level3
    Profile --> Nutri["Nutrition Tracker"]:::level3
    Profile --> Plan["7-Day Meal Planner"]:::level3
    Profile --> Shop["Smart Shopping List"]:::level3
    Profile --> Soc["Social & Creator Hub"]:::level3

    %% Level 2 - Vision
    Vision --> IoT["Smart Kitchen IoT"]:::level2
    Vision --> Hyper["Hyper-Personalization"]:::level2
    Vision --> Order["Order Mode & Commerce"]:::level2

    %% Level 3 - Vision -> IoT
    IoT --> Fridge["Smart Fridge Integration"]:::level3
    IoT --> Scale["Smart Scale Connectivity"]:::level3

    %% Level 3 - Vision -> Hyper
    Hyper --> Diet["AI Dietitian"]:::level3
    Hyper --> Fam["Family Account Sharing"]:::level3

    %% Level 3 - Vision -> Order
    Order --> Cart["Grocery Auto-Cart"]:::level3
    Order --> Res["Restaurant Discovery"]:::level3
```
