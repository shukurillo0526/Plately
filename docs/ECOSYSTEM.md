# Plately Smart Kitchen Ecosystem

This document reflects the exact feature set currently available in the Plately consumer app across the 4 primary launch tabs: **Cook, Shelf, Scan, and Profile**.

## Flow & Detailed Feature Breakdown

### 🍳 Cook Mode
*   **5-Tier Recommendation Engine:** Tailored algorithms for *Perfect Match*, *For You*, *Use It Up*, *Almost There*, and *Explore*.
*   **Gemini AI Recipe Generator:** Generates recipes strictly from inventory constraints or entirely freeform.
*   **Cuisine Discovery & Sorting:** Dynamic filtering by global cuisines.
*   **Interactive Recipe Execution:** Step-by-step cooking interface with automated ingredient portioning.
*   **Vertical Recipe Feeds:** Swipeable video-style feeds for recipe discovery.
*   **Post-Cook Rewards:** Gamified XP drops upon completing a cooking session.

### 🥫 Shelf (Living Shelf)
*   **Smart Ingredient Tracking:** Categorized storage (Produce, Meat, Dairy, Pantry, etc.) with visual expiration monitoring.
*   **Automated Lifecycle:** Auto-depletion of ingredients from the shelf upon finishing a recipe.
*   **Manual Management:** Add, edit, and delete functionality with smart icon/emoji pairing.

### 📸 Scanning Suite
*   **AI Receipt Parsing:** Extracts and categorizes items from grocery receipts via camera or gallery import.
*   **Live Barcode Scanner:** Real-time UPC barcode scanning for instant item identification.
*   **Food Photo Recognition:** Direct AI recognition of loose ingredients (e.g., loose vegetables).
*   **Audit Flow:** Manual review screen to confirm or correct AI-extracted items before adding to the shelf.

### 👤 Profile (Health & Social)
*   **Gamification Dashboard:** Visual XP progress, level progression, activity streaks, and unlockable badges.
*   **Flavor Profile Analytics:** Radar matrix plotting taste preferences (Sweet, Salty, Sour, Bitter, Umami, Spicy).
*   **Nutrition Tracker:** Macro-nutrient and caloric tracking against user health goals.
*   **Meal Planner:** 7-day calendar view for scheduling upcoming recipes.
*   **Smart Shopping List:** Interactive checklist that auto-syncs across devices.
*   **Social & Creator Hub:** Follower tracking, user-generated post uploads, and creator/restaurant dashboards.

---

## Launch Ecosystem Map

```mermaid
flowchart LR
    %% Styling to match the dark aesthetic
    classDef root fill:#444b5a,color:#fff,stroke:none,rx:5,ry:5,padding:20px;
    classDef level1 fill:#374149,color:#fff,stroke:none,rx:5,ry:5;
    classDef level2 fill:#374149,color:#fff,stroke:none,rx:5,ry:5;
    classDef level3 fill:#344e41,color:#fff,stroke:none,rx:5,ry:5;

    Root["Plately Consumer App"]:::root

    %% Launch Tabs
    Root --> Cook["Cook Mode"]:::level1
    Root --> Shelf["Living Shelf"]:::level1
    Root --> Scan["Scanning Suite"]:::level1
    Root --> Profile["Social & Profile"]:::level1

    %% Cook Features
    Cook --> Rec["5-Tier Recommendations"]:::level2
    Cook --> Gen["Gemini AI Generator"]:::level2
    Cook --> Exec["Interactive Cooking"]:::level2
    Cook --> Feed["Vertical Recipe Feeds"]:::level2
    Cook --> Rew["Gamified Cooking Rewards"]:::level2

    %% Shelf Features
    Shelf --> Cat["Categorized Tracking"]:::level2
    Shelf --> Exp["Expiration Monitoring"]:::level2
    Shelf --> Dep["Auto-Depletion"]:::level2
    Shelf --> Man["Manual Management"]:::level2

    %% Scan Features
    Scan --> Receipt["AI Receipt Parsing"]:::level2
    Scan --> Barcode["Live Barcode Scanner"]:::level2
    Scan --> Photo["Food Photo Recognition"]:::level2
    Scan --> Audit["Extraction Audit Flow"]:::level2

    %% Profile Features
    Profile --> Gam["Gamification & Badges"]:::level2
    Profile --> Flav["Flavor Profile Matrix"]:::level2
    Profile --> Nutri["Nutrition Tracker"]:::level2
    Profile --> Plan["7-Day Meal Planner"]:::level2
    Profile --> Shop["Smart Shopping List"]:::level2
    Profile --> Soc["Social & Creator Hub"]:::level2
```
