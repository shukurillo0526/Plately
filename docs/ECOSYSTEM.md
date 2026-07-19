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
mindmap
  root((Plately Ecosystem))
    Consumer Apps
      Mobile iOS & Android
      Web App Portal
    Cook Mode
      5-Tier Recommendations
        Perfect Match
        For You
        Use It Up
        Almost There
        Explore
      AI Recipe Generator
        Strict Inventory Mode
        Freeform Mode
      Bulk Cooking & Macros
      Cuisine Discovery
    Living Shelf
      Ingredient Categorization
      Expiration Tracking
      Auto-Depletion
    Scanning Suite
      Receipt OCR AI
      Camera & Gallery Import
      Barcode Integration Future
    Social & Profile
      Gamification & Badges
      Flavor Profile Matrix
      Activity Streaks
    Meal Prep & Health
      Macro & Calorie Analytics
      Calendar Planner
    Order Mode & Commerce
      Grocery Auto-Cart
      Delivery Partnerships
      Restaurant Discovery
    Vision & IoT Strategy
      Smart Fridge Integration
      Family Account Sharing
      AI Dietitian
    Technical Architecture
      Flutter Riverpod UI
      Supabase PostgreSQL
      Gemini AI Engine
      GitHub Actions Deployment
```
