import os
import sys
import json
from dotenv import load_dotenv
from supabase import create_client

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("Error: Missing Supabase credentials in .env")
    sys.exit(1)

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

recipes = [
    {
        "title": "Batch Turkey Chili",
        "description": "A high-protein, freezer-friendly turkey chili that tastes even better the next day.",
        "prep_time_minutes": 15,
        "cook_time_minutes": 45,
        "servings": 8,
        "difficulty": 1,
        "cuisine": "American",
        "calories_per_serving": 380,
        "image_url": "https://images.unsplash.com/photo-1548943487-a2e4b43b4853?w=600&q=80",
        "ingredients": [
            {"name": "Ground Turkey", "quantity": 2, "unit": "lbs"},
            {"name": "Kidney Beans", "quantity": 2, "unit": "cans"},
            {"name": "Crushed Tomatoes", "quantity": 28, "unit": "oz"},
            {"name": "Onion", "quantity": 2, "unit": "whole"},
            {"name": "Chili Powder", "quantity": 3, "unit": "tbsp"}
        ],
        "steps": [
            {"step_number": 1, "text": "Dice onions and sauté until translucent.", "timer_seconds": 300},
            {"step_number": 2, "text": "Add ground turkey and brown.", "timer_seconds": 480},
            {"step_number": 3, "text": "Add tomatoes, beans, and spices. Simmer for 30 minutes.", "timer_seconds": 1800}
        ],
        "tags": ["bulk_cooking", "high_protein", "freezer_friendly"]
    },
    {
        "title": "Sheet Pan Chicken Fajitas",
        "description": "Massive batch of chicken fajitas baked on two sheet pans for easy weekly lunches.",
        "prep_time_minutes": 15,
        "cook_time_minutes": 25,
        "servings": 6,
        "difficulty": 1,
        "cuisine": "Mexican",
        "calories_per_serving": 420,
        "image_url": "https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=600&q=80",
        "ingredients": [
            {"name": "Chicken Breast", "quantity": 2, "unit": "lbs"},
            {"name": "Bell Peppers", "quantity": 4, "unit": "whole"},
            {"name": "Red Onion", "quantity": 2, "unit": "whole"},
            {"name": "Fajita Seasoning", "quantity": 3, "unit": "tbsp"},
            {"name": "Olive Oil", "quantity": 4, "unit": "tbsp"}
        ],
        "steps": [
            {"step_number": 1, "text": "Slice chicken, peppers, and onions.", "timer_seconds": 600},
            {"step_number": 2, "text": "Toss everything in olive oil and seasoning on sheet pans.", "timer_seconds": 300},
            {"step_number": 3, "text": "Bake at 400°F (200°C) for 25 minutes.", "timer_seconds": 1500}
        ],
        "tags": ["bulk_cooking", "low_carb", "meal_prep"]
    },
    {
        "title": "Bulk Quinoa Salad Bowls",
        "description": "Refreshing and filling grain bowl base that keeps perfectly in the fridge for 5 days.",
        "prep_time_minutes": 20,
        "cook_time_minutes": 20,
        "servings": 5,
        "difficulty": 1,
        "cuisine": "Mediterranean",
        "calories_per_serving": 350,
        "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80",
        "ingredients": [
            {"name": "Quinoa", "quantity": 2, "unit": "cups"},
            {"name": "Cherry Tomatoes", "quantity": 2, "unit": "pints"},
            {"name": "Cucumber", "quantity": 2, "unit": "whole"},
            {"name": "Feta Cheese", "quantity": 1, "unit": "cup"},
            {"name": "Lemon Vinaigrette", "quantity": 0.5, "unit": "cup"}
        ],
        "steps": [
            {"step_number": 1, "text": "Cook quinoa and let it cool completely.", "timer_seconds": 1200},
            {"step_number": 2, "text": "Chop tomatoes and cucumber.", "timer_seconds": 600},
            {"step_number": 3, "text": "Mix everything in a massive bowl and portion into 5 containers.", "timer_seconds": 300}
        ],
        "tags": ["bulk_cooking", "vegetarian", "no_reheat"]
    },
    {
        "title": "Big Batch Bolognese Sauce",
        "description": "Rich, slow-cooked meat sauce. Freeze half for later, use half this week.",
        "prep_time_minutes": 20,
        "cook_time_minutes": 120,
        "servings": 12,
        "difficulty": 2,
        "cuisine": "Italian",
        "calories_per_serving": 290,
        "image_url": "https://images.unsplash.com/photo-1626844131082-256783844137?w=600&q=80",
        "ingredients": [
            {"name": "Ground Beef", "quantity": 2, "unit": "lbs"},
            {"name": "Ground Pork", "quantity": 1, "unit": "lb"},
            {"name": "Carrot", "quantity": 3, "unit": "whole"},
            {"name": "Celery", "quantity": 3, "unit": "stalks"},
            {"name": "Tomato Paste", "quantity": 6, "unit": "oz"},
            {"name": "Crushed Tomatoes", "quantity": 56, "unit": "oz"}
        ],
        "steps": [
            {"step_number": 1, "text": "Finely chop carrots, celery, and onions. Sauté until soft.", "timer_seconds": 600},
            {"step_number": 2, "text": "Brown the meats and stir in tomato paste.", "timer_seconds": 600},
            {"step_number": 3, "text": "Add crushed tomatoes and simmer on low for 2 hours.", "timer_seconds": 7200}
        ],
        "tags": ["bulk_cooking", "freezer_friendly", "sauce"]
    },
    {
        "title": "Overnight Oats (5 Days)",
        "description": "Prep your entire work week's breakfast in 10 minutes.",
        "prep_time_minutes": 10,
        "cook_time_minutes": 0,
        "servings": 5,
        "difficulty": 1,
        "cuisine": "American",
        "calories_per_serving": 310,
        "image_url": "https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=600&q=80",
        "ingredients": [
            {"name": "Rolled Oats", "quantity": 2.5, "unit": "cups"},
            {"name": "Milk (or Almond Milk)", "quantity": 2.5, "unit": "cups"},
            {"name": "Chia Seeds", "quantity": 5, "unit": "tbsp"},
            {"name": "Honey", "quantity": 5, "unit": "tbsp"},
            {"name": "Mixed Berries", "quantity": 2, "unit": "cups"}
        ],
        "steps": [
            {"step_number": 1, "text": "Line up 5 jars.", "timer_seconds": 60},
            {"step_number": 2, "text": "Add 1/2 cup oats, 1/2 cup milk, 1 tbsp chia, and 1 tbsp honey to each jar.", "timer_seconds": 300},
            {"step_number": 3, "text": "Top with berries and refrigerate overnight.", "timer_seconds": 120}
        ],
        "tags": ["bulk_cooking", "breakfast", "no_cook"]
    },
    {
        "title": "Lentil Soup for the Soul",
        "description": "Huge pot of hearty lentil soup that reheats perfectly.",
        "prep_time_minutes": 15,
        "cook_time_minutes": 40,
        "servings": 8,
        "difficulty": 1,
        "cuisine": "Global",
        "calories_per_serving": 220,
        "image_url": "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&q=80",
        "ingredients": [
            {"name": "Brown Lentils", "quantity": 2, "unit": "cups"},
            {"name": "Vegetable Broth", "quantity": 8, "unit": "cups"},
            {"name": "Carrots", "quantity": 4, "unit": "whole"},
            {"name": "Spinach", "quantity": 4, "unit": "cups"},
            {"name": "Cumin", "quantity": 1, "unit": "tbsp"}
        ],
        "steps": [
            {"step_number": 1, "text": "Chop vegetables and sauté in a large pot.", "timer_seconds": 300},
            {"step_number": 2, "text": "Add lentils, broth, and cumin. Boil, then simmer 30 mins.", "timer_seconds": 1800},
            {"step_number": 3, "text": "Stir in spinach until wilted.", "timer_seconds": 120}
        ],
        "tags": ["bulk_cooking", "vegan", "soup"]
    },
    {
        "title": "Mega Meatball Prep",
        "description": "Bake 40 meatballs at once. Use them in pasta, subs, or bowls.",
        "prep_time_minutes": 20,
        "cook_time_minutes": 20,
        "servings": 10,
        "difficulty": 1,
        "cuisine": "Italian",
        "calories_per_serving": 410,
        "image_url": "https://images.unsplash.com/photo-1529042410759-befb1204b468?w=600&q=80",
        "ingredients": [
            {"name": "Ground Beef", "quantity": 2, "unit": "lbs"},
            {"name": "Ground Pork", "quantity": 1, "unit": "lb"},
            {"name": "Breadcrumbs", "quantity": 1, "unit": "cup"},
            {"name": "Eggs", "quantity": 3, "unit": "whole"},
            {"name": "Parmesan Cheese", "quantity": 1, "unit": "cup"}
        ],
        "steps": [
            {"step_number": 1, "text": "Mix all ingredients gently in a large bowl.", "timer_seconds": 300},
            {"step_number": 2, "text": "Roll into 1.5-inch meatballs and place on lined baking sheets.", "timer_seconds": 600},
            {"step_number": 3, "text": "Bake at 400°F (200°C) for 20 minutes.", "timer_seconds": 1200}
        ],
        "tags": ["bulk_cooking", "freezer_friendly", "protein"]
    },
    {
        "title": "Teriyaki Chicken and Broccoli",
        "description": "Classic meal prep. High protein, simple, and holds up well.",
        "prep_time_minutes": 15,
        "cook_time_minutes": 20,
        "servings": 5,
        "difficulty": 1,
        "cuisine": "Asian",
        "calories_per_serving": 550,
        "image_url": "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600&q=80",
        "ingredients": [
            {"name": "Chicken Thighs", "quantity": 2.5, "unit": "lbs"},
            {"name": "Broccoli", "quantity": 4, "unit": "heads"},
            {"name": "Teriyaki Sauce", "quantity": 1, "unit": "cup"},
            {"name": "Rice", "quantity": 2, "unit": "cups"}
        ],
        "steps": [
            {"step_number": 1, "text": "Start cooking rice in a rice cooker.", "timer_seconds": 1200},
            {"step_number": 2, "text": "Chop chicken and cook in a large wok or skillet.", "timer_seconds": 600},
            {"step_number": 3, "text": "Steam broccoli. Combine chicken and sauce. Portion into 5 boxes.", "timer_seconds": 600}
        ],
        "tags": ["bulk_cooking", "meal_prep", "high_protein"]
    },
    {
        "title": "Batch Breakfast Burritos",
        "description": "Wrap in foil and freeze. Microwave for 2 mins for a hot breakfast.",
        "prep_time_minutes": 30,
        "cook_time_minutes": 20,
        "servings": 10,
        "difficulty": 2,
        "cuisine": "Tex-Mex",
        "calories_per_serving": 480,
        "image_url": "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600&q=80",
        "ingredients": [
            {"name": "Eggs", "quantity": 12, "unit": "whole"},
            {"name": "Breakfast Sausage", "quantity": 1, "unit": "lb"},
            {"name": "Hash Browns", "quantity": 4, "unit": "cups"},
            {"name": "Cheddar Cheese", "quantity": 2, "unit": "cups"},
            {"name": "Large Tortillas", "quantity": 10, "unit": "whole"}
        ],
        "steps": [
            {"step_number": 1, "text": "Cook sausage and hash browns.", "timer_seconds": 600},
            {"step_number": 2, "text": "Scramble all eggs.", "timer_seconds": 300},
            {"step_number": 3, "text": "Assemble burritos with cheese, wrap tightly in foil, and freeze.", "timer_seconds": 900}
        ],
        "tags": ["bulk_cooking", "breakfast", "freezer_friendly"]
    },
    {
        "title": "Pulled Pork Shoulder (Slow Cooker)",
        "description": "Cook once, eat for a week. Great for tacos, sandwiches, and bowls.",
        "prep_time_minutes": 10,
        "cook_time_minutes": 480,
        "servings": 12,
        "difficulty": 1,
        "cuisine": "American",
        "calories_per_serving": 320,
        "image_url": "https://images.unsplash.com/photo-1633321702518-7feccafb94d5?w=600&q=80",
        "ingredients": [
            {"name": "Pork Shoulder", "quantity": 5, "unit": "lbs"},
            {"name": "BBQ Rub", "quantity": 0.5, "unit": "cup"},
            {"name": "Apple Cider Vinegar", "quantity": 0.5, "unit": "cup"},
            {"name": "Chicken Broth", "quantity": 1, "unit": "cup"}
        ],
        "steps": [
            {"step_number": 1, "text": "Rub pork shoulder with BBQ seasoning.", "timer_seconds": 300},
            {"step_number": 2, "text": "Place in slow cooker with liquids. Cook on Low for 8 hours.", "timer_seconds": 28800},
            {"step_number": 3, "text": "Shred with two forks.", "timer_seconds": 300}
        ],
        "tags": ["bulk_cooking", "slow_cooker", "meat"]
    }
]

def generate_uz_translation(recipe):
    # Dummy translator logic just to ensure it works for Uzbek testing.
    return {
        "title": f"[UZ] {recipe['title']}",
        "short_description": recipe['description'],
        "ingredients": recipe['ingredients'],
        "steps": recipe['steps'],
        "translation_status": "completed",
        "translation_method": "manual_seed"
    }

def main():
    print("Deleting old seed bulk recipes...")
    # Delete recipes with "bulk_cooking" tag to avoid duplicates and refresh with photos/macros
    old = supabase.table("recipes").select("id, tags").execute()
    count_deleted = 0
    for r in old.data:
        if r.get('tags') and "bulk_cooking" in r['tags']:
            supabase.table("recipes").delete().eq("id", r['id']).execute()
            count_deleted += 1
    print(f"Deleted {count_deleted} old recipes.")

    print(f"Inserting {len(recipes)} fully populated bulk recipes...")
    count = 0
    for recipe in recipes:
        try:
            res = supabase.table("recipes").insert(recipe).execute()
            new_id = res.data[0]['id']
            
            # Add Uzbek Translation
            uz_trans = generate_uz_translation(recipe)
            uz_trans['recipe_id'] = new_id
            uz_trans['language_code'] = 'uz'
            supabase.table("recipe_translations").insert(uz_trans).execute()
            
            count += 1
            print(f"Added: {recipe['title']} (with UZ translation)")
        except Exception as e:
            print(f"Failed to add {recipe['title']}: {e}")
            
    print(f"Successfully added {count} complete recipes!")

if __name__ == "__main__":
    main()
