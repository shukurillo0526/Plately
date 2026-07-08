import json
import glob
import sys

tutorial_keys = {
    "auth_enterEmail": "Please enter your email address first.",
    "tutorial_tourTitle": "Plately Interactive Tour",
    "tutorial_tourDesc": "Welcome! Let's take a quick 1-minute interactive tour of Plately. We will show you how to manage your ingredients, discover matching recipes, and start cooking!",
    "tutorial_startTour": "Start Tour 🚀",
    "tutorial_skipTour": "Skip",
    
    "tutorial_shelfIntroTitle": "Your Digital Shelf",
    "tutorial_shelfIntroDesc": "This is your digital fridge, freezer, and pantry. Here you can track quantities and expiry dates — we'll warn you before food goes bad. Let's see how it works!",
    "tutorial_nextArrow": "Next →",
    
    "tutorial_addIntroTitle": "Add Ingredients",
    "tutorial_addIntroDesc": "To add ingredients, tap the Scan tab (center camera icon) in the navigation bar. Go ahead, tap it!",
    "tutorial_bypassScan": "Bypass (Go to Scan)",
    
    "tutorial_scanIntroTitle": "Scan & Manually Add",
    "tutorial_scanIntroDesc": "Here you can scan receipts, barcodes, or snap a photo of ingredients. For this tutorial, we will automatically load 5 mock ingredients needed for a special stir-fry recipe.",
    "tutorial_loadMock": "Load Mock Ingredients 🛒",
    
    "tutorial_shelfAddedTitle": "Ingredients Loaded!",
    "tutorial_shelfAddedDesc": "Great! We've loaded: Chicken Breast, Broccoli, Soy Sauce, Garlic, and Sesame Oil. Let's see what we can cook! Tap the Cook tab (left restaurant icon) to find matching recipes.",
    "tutorial_bypassCook": "Bypass (Go to Cook)",
    
    "tutorial_roamCookTitle": "5-Tier Recommendations",
    "tutorial_roamCookDesc": "Here you see the 5-tier recommendation tabs (Perfect, For You, Use It Up, Almost, Explore). Tap around to explore them! When you are ready, tap the \"Tutorial Chicken Stir-fry\" recipe card under the Perfect tab.",
    
    "tutorial_recipeDetailTitle": "Recipe Details",
    "tutorial_recipeDetailDesc": "Here you see the ingredients list and steps. Tap the \"Start Cooking\" button at the bottom of the page to begin!",
    
    "tutorial_cookingPrepTitle": "Prep & Ingredients",
    "tutorial_cookingPrepDesc": "Before turning on the heat, wash and chop your ingredients. Tap the \"Begin Step-by-Step\" button to start the cooking assistant!",
    
    "tutorial_cookingRunTitle": "Cooking Assistant",
    "tutorial_cookingRunDesc": "The assistant guides you step-by-step. You can also chat with the AI assistant at the bottom for substitutions or cooking questions! Step through the recipe and tap \"Finish\" on the final step.",
    
    "tutorial_finishTitle": "Tutorial Completed!",
    "tutorial_finishDesc": "Congratulations! You've completed the Plately cook tour.\n\nNote: All ingredients and data used in this tutorial will not be saved. This is just a small portion of the app. Tap \"Finish Tour\" to start your own cooking journey!",
    "tutorial_finishTour": "Finish Tour 🏁"
}

email_trans = {
    'app_ko.arb': '이메일 주소를 먼저 입력해주세요.',
    'app_uz.arb': 'Iltimos, avval elektron pochta manzilingizni kiriting.',
    'app_uz_Cyrl.arb': 'Илтимос, аввал электрон почта манзилингизни киритинг.',
    'app_ru.arb': 'Пожалуйста, сначала введите ваш адрес электронной почты.',
}

import os
# Write to the current directory (l10n)
for f in glob.glob('app_*.arb'):
    with open(f, 'r', encoding='utf-8') as file:
        data = json.load(file)
        
    for k, v in tutorial_keys.items():
        if k not in data:
            if k == 'auth_enterEmail' and os.path.basename(f) in email_trans:
                data[k] = email_trans[os.path.basename(f)]
            else:
                data[k] = v
                
    with open(f, 'w', encoding='utf-8') as file:
        json.dump(data, file, ensure_ascii=False, indent=2)
        
print("Patched all .arb files successfully.")
