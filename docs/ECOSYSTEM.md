# Plately Smart Kitchen & Food Ecosystem

This document outlines the comprehensive current state, specific technical details, and the broader future vision of the Plately ecosystem.

## Flow & Detailed Feature Breakdown

### 📱 Consumer Applications (Cross-Platform)
*   **Unified Interface**
    *   Flutter-built architecture supporting iOS, Android, and Web simultaneously.
    *   Responsive design with dynamic theming and dual-mode navigation.

### 🍳 Cook Mode (Smart Cooking & AI)
*   **5-Tier Recommendation Engine** (Learning algorithm based on interaction history)
    1.  **Perfect Match:** 100% ingredient match with current Living Shelf.
    2.  **For You:** High affinity based on past likes and Flavor Profile.
    3.  **Use It Up:** Prioritizes recipes containing soon-to-expire ingredients to reduce waste.
    4.  **Almost There:** 75%+ ingredient match (suggests missing items).
    5.  **Explore:** Discovery of trending, new, and diverse recipes globally.
*   **Cuisine & Dietary Sorting**
    *   Dynamic filtering by global cuisines (Uzbek, Korean, Italian, Mexican, etc.) and dietary needs.
*   **Gemini AI Recipe Generator**
    *   *Constraint-based generation:* Creates unique recipes strictly using available ingredients.
    *   *Freeform generation:* Inspires new ideas regardless of current inventory.
*   **Bulk Cooking & Meal Prep Engine**
    *   Input target days and meals/day.
    *   Target macro-nutrient optimization (custom calorie and protein goals).
*   **Recipe Execution**
    *   Interactive, step-by-step cooking interface with ingredient portioning.

### 🥫 Living Shelf (Inventory Management)
*   **Smart Ingredient Tracking**
    *   Categorized storage structures (Produce, Meat, Dairy, Pantry, Spices, etc.).
    *   Visual expiration monitoring with color-coded freshness indicators.
*   **Automated Lifecycle**
    *   Auto-depletion of ingredients from the shelf upon cooking a recipe.
*   **Manual & Quick Management**
    *   Add, edit, delete functionality with smart emoji/icon pairing.

### 📸 Scanning & Vision Suite
*   **AI Receipt Parsing**
    *   Camera integration for real-time scanning of grocery receipts.
    *   Gallery import for digital receipts.
    *   Automated OCR text extraction, parsed by AI into structured Living Shelf items.
*   **Future Vision:** Direct barcode scanning and food packaging recognition.

### 🥗 Meal Prep & Health Analytics
*   **Nutrition Tracking**
    *   Detailed macro-nutrient breakdowns (Protein, Carbs, Fats).
    *   Caloric tracking against user health goals.
*   **Calendar & Scheduling**
    *   Weekly calendar view for scheduled meals.
    *   Prep-day optimization and batch cooking schedules.

### 👤 Social & User Profile
*   **Gamification & Rewards Engine**
    *   Activity streaks and dynamic point accumulation.
    *   Unlockable achievements and badges (e.g., Novice Chef, AI Master, Wok Star).
    *   Tier progression leveling system.
*   **Flavor Profile Analytics**
    *   Taste mapping analytics (Spicy, Sweet, Savory, Sour preferences).
    *   Ingredient diversity scoring.
    *   Cooking habits and frequency dashboard.

### 🛒 Order Mode & Commerce (Foundation)
*   **Grocery Delivery Integration**
    *   Auto-cart generation: automatically adds "missing ingredients" from a recipe to a shopping list.
    *   *Future:* Direct API partnerships with delivery services (Instacart, Whole Foods).
*   **Restaurant Discovery**
    *   Local dining recommendations tailored by the user's AI Flavor Profile.

### 🌐 Vision & Future Strategy
*   **Hyper-Personalization**
    *   AI Dietitian for automated health goal coaching.
    *   Family and household account sharing (shared Living Shelves).
*   **Smart Kitchen IoT**
    *   Smart Fridge camera integration to auto-update the Living Shelf.
    *   Smart Scale and Smart Oven connectivity for precision cooking.
*   **Monetization & Scale**
    *   Plately+ Premium Subscription (Advanced AI analytics, unlimited receipt scans).

### ⚙️ Technical Architecture
*   **Frontend:** Flutter UI, Riverpod State Management.
*   **Backend:** Supabase (PostgreSQL, Auth, Edge Functions, Row Level Security).
*   **AI/ML:** Google Gemini Multimodal AI (Text + Vision) with custom JSON parsing guards and rate limiting.
*   **DevOps:** GitHub Actions CI/CD pipelines for automated Web/Mobile deployment.

---

## The Broader Ecosystem Mindmap

```mermaid
flowchart LR
    %% Styling to match the dark aesthetic
    classDef root fill:#444b5a,color:#fff,stroke:none,rx:5,ry:5,padding:20px;
    classDef level1 fill:#374149,color:#fff,stroke:none,rx:5,ry:5;
    classDef level2 fill:#374149,color:#fff,stroke:none,rx:5,ry:5;
    classDef level3 fill:#344e41,color:#fff,stroke:none,rx:5,ry:5;

    Root["Plately Smart Kitchen & Food Ecosystem"]:::root
    
    %% Level 1
    Root --> App["Existing Consumer App"]:::level1
    Root --> Vision["Vision & Future Strategy"]:::level1
    Root --> Tech["Technical Architecture"]:::level1
    Root --> Market["Market Advantage"]:::level1

    %% Level 2 - App
    App --> Cook["Cook Mode"]:::level2
    App --> Shelf["Living Shelf (Inventory)"]:::level2
    App --> Scan["Scanning Suite"]:::level2
    App --> Prep["Meal Prep & Health"]:::level2
    App --> Social["Social & Profile"]:::level2
    App --> Order["Order Mode Foundation"]:::level2

    %% Level 3 - Cook
    Cook --> Rec["5-Tier Recommendations"]:::level3
    Cook --> Gen["AI Recipe Generator"]:::level3
    Cook --> Bulk["Bulk Cooking & Macros"]:::level3
    Cook --> Cuis["Cuisine Discovery"]:::level3

    %% Level 3 - Shelf
    Shelf --> Cat["Ingredient Categorization"]:::level3
    Shelf --> Exp["Expiration Tracking"]:::level3
    Shelf --> Dep["Auto-Depletion"]:::level3

    %% Level 3 - Scan
    Scan --> Ocr["Receipt OCR AI"]:::level3
    Scan --> Cam["Camera & Gallery Import"]:::level3

    %% Level 3 - Prep
    Prep --> Mac["Macro & Calorie Analytics"]:::level3
    Prep --> Cal["Calendar Planner"]:::level3

    %% Level 3 - Social
    Social --> Gam["Gamification & Badges"]:::level3
    Social --> Fla["Flavor Profile Matrix"]:::level3
    Social --> Str["Activity Streaks"]:::level3

    %% Level 3 - Order
    Order --> Cart["Grocery Auto-Cart"]:::level3
    Order --> Del["Delivery Partnerships"]:::level3
    Order --> Res["Restaurant Discovery"]:::level3

    %% Level 2 - Vision
    Vision --> IoT["Smart Fridge Integration"]:::level3
    Vision --> Fam["Family Account Sharing"]:::level3
    Vision --> Diet["AI Dietitian"]:::level3

    %% Level 2 - Tech
    Tech --> Flu["Flutter Riverpod UI"]:::level3
    Tech --> Sup["Supabase PostgreSQL"]:::level3
    Tech --> Gem["Gemini AI Engine"]:::level3
    Tech --> Git["GitHub Actions CI/CD"]:::level3
    
    %% Level 2 - Market Advantage
    Market --> Sp["Hyper-Personalized AI"]:::level3
    Market --> Cross["Cross-Platform Sync"]:::level3
    Market --> Waste["Zero-Waste Focus"]:::level3
```
