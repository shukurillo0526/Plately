// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plately';

  @override
  String get tabShelf => 'Shelf';

  @override
  String get tabCook => 'Cook';

  @override
  String get tabScan => 'Scan';

  @override
  String get tabProfile => 'Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String profileGamificationLevel(int level) {
    return 'Level $level';
  }

  @override
  String get profileMealsCooked => 'Meals Cooked';

  @override
  String get profileItemsSaved => 'Items Saved';

  @override
  String get profileDayStreak => 'Day Streak';

  @override
  String get profileFlavorProfile => 'Flavor Profile';

  @override
  String get profileBadges => 'Badges & Achievements';

  @override
  String get profileShoppingList => 'Shopping List';

  @override
  String get profileMealPlanner => 'Meal Planner';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get profileLoadError => 'Couldn\'t load profile';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get signOut => 'Sign Out';

  @override
  String get profileLevelProgress => 'Level Progress';

  @override
  String profileLevel(int level) {
    return 'Level $level';
  }

  @override
  String get profileYourImpact => 'Your Impact';

  @override
  String get addShoppingItem => 'Add Item';

  @override
  String get shoppingListEmpty => 'Your shopping list is empty';

  @override
  String get mealPlannerEmpty => 'No meals planned';

  @override
  String get planToday => 'Plan Today';

  @override
  String get today => 'Today';

  @override
  String get planMeal => 'Plan meal...';

  @override
  String get tabExplore => 'Explore';

  @override
  String get scanFood => 'Scan Food';

  @override
  String get scanCalories => 'Scan Calories';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get analyzeCalories => 'Analyze Calories';

  @override
  String get caloriesPerServing => 'cal/serving';

  @override
  String get totalCalories => 'cal total';

  @override
  String get creatorProfile => 'Creator Profile';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get nutritionTracker => 'Nutrition Tracker';

  @override
  String get reels => 'Reels';

  @override
  String get community => 'Community';

  @override
  String get hasRecipe => 'Has Recipe';

  @override
  String get noReelsYet => 'No reels yet';

  @override
  String get settings => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get aboutApp => 'About Plately';

  @override
  String get myFridge => '🧊 My Fridge';

  @override
  String get expiryAlerts => 'Expiry alerts';

  @override
  String get errorLoadInventory => 'Couldn\'t load inventory';

  @override
  String get errorCheckConnection => 'Check your connection and try again.';

  @override
  String get total => 'Total';

  @override
  String get fresh => 'Fresh';

  @override
  String get expiring => 'Expiring';

  @override
  String get expired => 'Expired';

  @override
  String get searchIngredients => 'Search ingredients...';

  @override
  String get all => 'All';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String zoneEmptyTitle(String zone) {
    return 'Your $zone is Empty';
  }

  @override
  String get zoneEmptyDesc =>
      'Ready to fill up your digital kitchen.\nAdd items manually or tap scan.';

  @override
  String get addIngredient => 'Add Ingredient';

  @override
  String get urgentCook => 'Cook Now';

  @override
  String urgentUse(String ingredient) {
    return 'Use $ingredient';
  }

  @override
  String get noItemsMatch => 'No items match your filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get expiryAlertsTitle => '🔔 Expiry Alerts';

  @override
  String get allFresh => 'All items are fresh! 🎉';

  @override
  String expiredCount(int count) {
    return '❌ Expired ($count)';
  }

  @override
  String expiringSoonCount(int count) {
    return '⚠️ Expiring Soon ($count)';
  }

  @override
  String get auto_scanCaloriesIsComingSoon => 'Scan Calories is coming soon!';

  @override
  String get auto_scan => 'Scan';

  @override
  String get auto_addAll => 'Add All';

  @override
  String get auto_allAdded => 'All Added';

  @override
  String get auto_scanAnother => 'Scan Another';

  @override
  String get auto_startVisualAudit => 'Start Visual Audit';

  @override
  String get auto_enterBarcode => 'Enter Barcode';

  @override
  String get auto_cancel => 'Cancel';

  @override
  String get auto_lookUp => 'Look Up';

  @override
  String get auto_fridge => 'Fridge';

  @override
  String get auto_freezer => 'Freezer';

  @override
  String get auto_pantry => 'Pantry';

  @override
  String get auto_addToShelf => 'Add to Shelf';

  @override
  String get auto_mealLogged => '✅ Meal logged!';

  @override
  String get auto_snapYourMeal => 'Snap Your Meal';

  @override
  String get auto_takeAPhotoAndAiWillEstimateCalories =>
      'Take a photo and AI will estimate calories';

  @override
  String get auto_analyzingFood => 'Analyzing food...';

  @override
  String get auto_camera => 'Camera';

  @override
  String get auto_gallery => 'Gallery';

  @override
  String get auto_estimatedCalories => 'estimated calories';

  @override
  String get auto_cal => 'cal';

  @override
  String get auto_logMeal => 'Log Meal';

  @override
  String get auto_addSomeIngredientsToYourShelfFirst =>
      'Add some ingredients to your shelf first!';

  @override
  String get auto_aiRecipeGenerator => 'AI Recipe Generator';

  @override
  String get auto_any => 'Any';

  @override
  String get auto_shelfOnly => 'Shelf Only';

  @override
  String get auto_generateRecipe => 'Generate Recipe';

  @override
  String get auto_ingredients => '🧂 Ingredients';

  @override
  String get auto_steps => '👨‍🍳 Steps';

  @override
  String get auto_importRecipe => 'Import Recipe';

  @override
  String get auto_retry => 'Retry';

  @override
  String get auto_addItemsToYourShelfToGetRecommendations =>
      'Add items to your shelf to get recommendations';

  @override
  String get auto_noRecipesMatchThisCuisine => 'No recipes match this cuisine';

  @override
  String get auto_clearFilter => 'Clear filter';

  @override
  String get auto_deleteItem => 'Delete item?';

  @override
  String get auto_delete => 'Delete';

  @override
  String get auto_freshness => 'Freshness';

  @override
  String get auto_use1Unit => 'Use 1 Unit';

  @override
  String get auto_removeFromInventory => 'Remove from Inventory';

  @override
  String get auto_following => 'Following';

  @override
  String get auto_follow => 'Follow';

  @override
  String get auto_posts => 'Posts';

  @override
  String get auto_noPostsYet => 'No posts yet';

  @override
  String get auto_explore => 'Explore';

  @override
  String get auto_noReelsYet => 'No reels yet';

  @override
  String get auto_cookThisRecipe => 'Cook This Recipe';

  @override
  String get auto_recipeNotFound => 'Recipe not found';

  @override
  String get auto_hasRecipe => 'Has Recipe';

  @override
  String get auto_noCommunityPostsYet => 'No community posts yet';

  @override
  String get auto_beTheFirstToShare => 'Be the first to share!';

  @override
  String get auto_createPost => 'Create Post';

  @override
  String get auto_savedPosts => 'Saved Posts';

  @override
  String get auto_noSavedPostsYet => 'No saved posts yet';

  @override
  String get auto_you => 'You';

  @override
  String get auto_checkout => 'Checkout';

  @override
  String get auto_yourCartIsEmpty => 'Your cart is empty';

  @override
  String get auto_yourOrder => 'Your Order';

  @override
  String get auto_total => 'total';

  @override
  String get auto_orderConfirmed => 'Order Confirmed!';

  @override
  String get auto_yourPickupCode => 'Your Pickup Code';

  @override
  String get auto_showThisCodeAtTheCounter => 'Show this code at the counter';

  @override
  String get auto_deliveryOnTheWay => 'Delivery on the way';

  @override
  String get auto_aDriverWillBeAssignedShortly =>
      'A driver will be assigned shortly';

  @override
  String get auto_backToHome => 'Back to Home';

  @override
  String get auto_incomingOrders => 'Incoming Orders';

  @override
  String get auto_noFoodVideosYet => 'No food videos yet';

  @override
  String get auto_foodFeed => 'Food Feed';

  @override
  String get auto_myOrders => 'My Orders';

  @override
  String get auto_noOrdersYet => 'No orders yet';

  @override
  String get auto_yourOrderHistoryWillAppearHere =>
      'Your order history will appear here';

  @override
  String get auto_cancelOrder => 'Cancel Order?';

  @override
  String get auto_keepOrder => 'Keep Order';

  @override
  String get auto_orderCancelled => 'Order cancelled';

  @override
  String get auto_pickupCode => 'Pickup Code:';

  @override
  String get auto_closed => 'Closed';

  @override
  String get auto_menu => 'Menu';

  @override
  String get auto_menuComingSoon => 'Menu coming soon';

  @override
  String get auto_best => '🔥 Best';

  @override
  String get auto_popularDishes => '🍽️ Popular Dishes';

  @override
  String get auto_fromVideo => 'From video';

  @override
  String get auto_bookATable => 'Book a Table';

  @override
  String get auto_confirmReservation => 'Confirm Reservation';

  @override
  String get auto_locationDirections => 'Location & Directions';

  @override
  String get auto_mapView => 'Map View';

  @override
  String get auto_openInGoogleMaps => 'Open in Google Maps';

  @override
  String get auto_writeAReview => 'Write a Review';

  @override
  String get auto_viewCart => 'View Cart';

  @override
  String get auto_signOut => 'Sign Out?';

  @override
  String get auto_youWillNeedToSignInAgain => 'You will need to sign in again.';

  @override
  String get auto_deleteAccount => 'Delete Account?';

  @override
  String get auto_deleteForever => 'Delete Forever';

  @override
  String get auto_accountDeletionRequestedContactSupportToFinalize =>
      'Account deletion requested. Contact support to finalize.';

  @override
  String get auto_plately => 'Plately';

  @override
  String
  get auto_platelyIsYourAipoweredKitchenEcosystemItAutomaticallyTracksYourIngredientsPredictsExpirationsGeneratesPersonalizedRecipesAndLetsYouOrderFromLocalRestaurants =>
      'Plately is your AI-powered kitchen ecosystem. It automatically tracks your ingredients, predicts expirations, generates personalized recipes, and lets you order from local restaurants.';

  @override
  String get auto_gotIt => 'Got it';

  @override
  String get auto_editDisplayName => 'Edit Display Name';

  @override
  String get auto_save => 'Save';

  @override
  String get auto_addShoppingItem => 'Add Shopping Item';

  @override
  String get auto_add => 'Add';

  @override
  String get auto_selectRecipeForMeal => 'Select Recipe for Meal';

  @override
  String get auto_failedToLoadRecipes => 'Failed to load recipes';

  @override
  String get auto_noRecipesFound => 'No recipes found';

  @override
  String get auto_mealCleared => 'Meal cleared';

  @override
  String get auto_theme => '🎨 Theme';

  @override
  String get whatToCook => 'What to Cook?';

  @override
  String get tierPerfect => 'Perfect';

  @override
  String get tierForYou => 'For You';

  @override
  String get tierUseItUp => 'Use It Up';

  @override
  String get tierAlmost => 'Almost';

  @override
  String get tierExplore => 'Explore';

  @override
  String noTierRecipesYet(String tier) {
    return 'No $tier recipes yet';
  }

  @override
  String get addItemsForRecommendations =>
      'Add items to your shelf to get recommendations';

  @override
  String get scanCaloriesTab => 'Scan Calories';

  @override
  String get scanYourIngredients => 'Scan Your Ingredients';

  @override
  String get takePhotoToAdd =>
      'Take a photo of food items to add them to your shelf automatically';

  @override
  String get scanReceipt => 'Receipt';

  @override
  String get scanPhoto => 'Photo';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get takePhotoBtn => 'Take Photo';

  @override
  String get adjustPortions => 'Adjust Portions';

  @override
  String currentRecipeMakesNServings(String servings) {
    return 'Current recipe makes $servings servings.';
  }

  @override
  String scaleToNServings(String newServings) {
    return 'Scale to $newServings Servings';
  }

  @override
  String scaledToNServings(String newServings) {
    return 'Scaled to $newServings servings 🍳';
  }

  @override
  String findingSubstitutesForX(String ingredientName) {
    return 'Finding substitutes for $ingredientName...';
  }

  @override
  String get couldNotFindSubstitutes => 'Could not find substitutes';

  @override
  String substitutesForX(String ingredientName) {
    return 'Substitutes for \"$ingredientName\"';
  }

  @override
  String get noSubstitutesFoundForThisRecipeContext =>
      'No substitutes found for this recipe context.';

  @override
  String nMatch(String match) {
    return '$match% Match';
  }

  @override
  String ingredientsWithCount(String count) {
    return 'Ingredients ($count)';
  }

  @override
  String get scale => 'Scale';

  @override
  String get addedMissingItemsToShoppingList =>
      'Added missing items to Shopping List!';

  @override
  String failedToAddItemsX(String e) {
    return 'Failed to add items: $e';
  }

  @override
  String get addMissingToShoppingList => 'Add missing to Shopping List';

  @override
  String cookingStepsWithCount(String count) {
    return 'Cooking Steps ($count)';
  }

  @override
  String get noStepsAvailableYet => 'No steps available yet';

  @override
  String get recordedTasteProfileEvolving =>
      'Recorded! Your taste profile is evolving 🧠';

  @override
  String failedToRecordX(String e) {
    return 'Failed to record: $e';
  }

  @override
  String get iCookedThis => 'I Cooked This!';

  @override
  String get startCooking => 'Start Cooking';

  @override
  String get optional_tag => 'optional';

  @override
  String get servings_tag => 'servings';

  @override
  String get min_tag => 'min';

  @override
  String get difficulty_tag => 'Difficulty';

  @override
  String get expiringSoon => 'Expiring Soon';

  @override
  String nItemsNeedAttention(String count) {
    return '$count item(s) need attention';
  }

  @override
  String get takeAPhotoOfFoodItems =>
      'Take a photo of food items to add them\nto your shelf automatically';

  @override
  String get addManually => 'Add Manually';

  @override
  String get recognitionFailed => 'Recognition failed. Try again.';

  @override
  String get analyzingYourFood => 'Analyzing your food...';

  @override
  String get aiIsIdentifying => 'AI is identifying ingredients';

  @override
  String nItemsDetected(String count) {
    return '$count Items Detected';
  }

  @override
  String get photoAnalysisSelected => 'Photo Analysis Selected';

  @override
  String nIngredientsDetected(String count) {
    return '$count Ingredients Detected';
  }

  @override
  String nOfNAdded(String added, String total) {
    return '$added / $total added';
  }

  @override
  String addedItem(String item) {
    return 'Added $item!';
  }

  @override
  String failedToAddItem(String item) {
    return 'Failed to add $item';
  }

  @override
  String addedNItemsToShelf(String count) {
    return 'Added $count items to shelf!';
  }

  @override
  String noProductFoundForBarcode(String barcode) {
    return 'No product found for barcode $barcode';
  }

  @override
  String addedItemToShelf(String item) {
    return 'Added $item to shelf!';
  }

  @override
  String errorX(String e) {
    return 'Error: $e';
  }

  @override
  String analysisFailedX(String e) {
    return 'Analysis failed: $e';
  }

  @override
  String failedToLogX(String e) {
    return 'Failed to log: $e';
  }

  @override
  String get scanBarcodeShort => 'Barcode';

  @override
  String get profileAccount => 'Account';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get tierBadge1 => '✅ Everything you need!';

  @override
  String get tierBadge2 => '🔥 Recommended for you';

  @override
  String get tierBadge3 => '⏰ Use expiring items';

  @override
  String get tierBadge4 => '🛒 Just a few items away';

  @override
  String get tierBadge5 => '🌍 Discover something new';

  @override
  String needLabel(String items) {
    return 'Need: $items';
  }

  @override
  String nOfNIngredients(String matched, String total) {
    return '$matched/$total ingredients';
  }

  @override
  String get servingsLabel => 'Servings';

  @override
  String nHave(String count) {
    return '$count have';
  }

  @override
  String nMissing(String count) {
    return '$count missing';
  }

  @override
  String get ingredientsHeader => 'Ingredients';

  @override
  String get swapButton => 'Swap →';

  @override
  String get aiAssistant => '🤖 AI Assistant';

  @override
  String get aiHint => 'e.g. \"I don\'t have lamb, suggest alternatives\"';

  @override
  String get editIngredient => 'Edit Ingredient';

  @override
  String get nameLabel => 'Name';

  @override
  String get qtyLabel => 'Qty';

  @override
  String get unitLabel => 'Unit';

  @override
  String get handsOn => 'Hands-on';

  @override
  String get automatic => 'Automatic';

  @override
  String get inv_quantity => 'Quantity';

  @override
  String get inv_purchased => 'Purchased';

  @override
  String get inv_expires => 'Expires';

  @override
  String get inv_source => 'Source';

  @override
  String get inv_storageLocation => 'Storage Location';

  @override
  String get inv_itemState => 'Item State';

  @override
  String get inv_freshLabel => '🟢 Fresh';

  @override
  String get inv_agingLabel => '🟡 Aging';

  @override
  String get inv_urgentLabel => '🟠 Urgent';

  @override
  String get inv_criticalLabel => '🔴 Critical';

  @override
  String get inv_expiredLabel => '⚫ Expired';

  @override
  String inv_expiredDaysAgo(String days) {
    return 'Expired ${days}d ago';
  }

  @override
  String get inv_expiresToday => 'Expires today!';

  @override
  String get inv_expiresTomorrow => 'Expires tomorrow';

  @override
  String inv_daysRemaining(String days) {
    return '$days days remaining';
  }

  @override
  String get inv_stateOpened => 'OPENED';

  @override
  String get inv_stateFrozen => 'FROZEN';

  @override
  String get inv_stateThawed => 'THAWED';

  @override
  String get inv_statePartial => 'PARTIAL';

  @override
  String get inv_sortExpiry => 'Expiry ↑';

  @override
  String get inv_sortName => 'Name A-Z';

  @override
  String get inv_sortCategory => 'Category';

  @override
  String get inv_sortNewest => 'Newest first';

  @override
  String inv_removeConfirm(String name) {
    return 'Remove \"$name\" from your inventory?';
  }

  @override
  String get manual_addIngredient => 'Add Ingredient';

  @override
  String get manual_ingredientName => 'Ingredient Name';

  @override
  String get manual_ingredientHint => 'e.g. Apples, Bread, Milk';

  @override
  String get manual_category => 'Category';

  @override
  String get manual_qty => 'Qty';

  @override
  String get manual_metricType => 'Metric Type';

  @override
  String get manual_estimatedExpiry => 'Estimated Expiry';

  @override
  String get manual_required => 'Required';

  @override
  String get auth_tagline => 'Zero‑Waste, Maximum Taste.';

  @override
  String get auth_subtitle => 'Your kitchen, intelligently managed.';

  @override
  String get auth_email => 'Email';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_continue => 'Continue';

  @override
  String get auth_or => 'OR';

  @override
  String get auth_continueGoogle => 'Continue with Google';

  @override
  String get auth_continueGuest => 'Continue as Guest';

  @override
  String get auth_autoDetectHint =>
      'New here? We\'ll create your account automatically.';

  @override
  String get auth_checkEmail =>
      'Please check your email to verify your account.';

  @override
  String get auth_enterBoth => 'Please enter both email and password.';

  @override
  String get auth_unexpectedError =>
      'An unexpected error occurred. Please try again.';

  @override
  String get auth_googleFailed => 'Google sign‑in failed. Please try again.';

  @override
  String get auth_guestFailed =>
      'Guest sign‑in failed. Please try email or Google instead.';

  @override
  String get auth_resetSent => 'Password reset email sent. Check your inbox.';

  @override
  String get auth_forgotPassword => 'Forgot Password?';

  @override
  String get import_recipe => 'Import Recipe';

  @override
  String get import_pasteRaw => 'Paste Raw Recipe';

  @override
  String get import_description =>
      'Copy and paste instructions from a website, book, or notes app. Our AI will magically convert it into a step-by-step smart recipe.';

  @override
  String get import_hint =>
      'e.g. Grandma\'s Cookies\nMix 2 cups flour with 1 cup sugar... bake at 350 for 10 mins.';

  @override
  String get import_analyzing => 'Analyzing Recipe...';

  @override
  String get import_parseWithAi => 'Parse with AI';

  @override
  String get import_parsedRecipe => 'Parsed Recipe';

  @override
  String get import_steps => 'Steps';

  @override
  String get import_saveButton => 'Looks Good — Save to My Recipes';

  @override
  String get import_savedLocally => 'Recipe saved to My Recipes!';

  @override
  String get tutorial_next => 'Next →';

  @override
  String get tutorial_gotIt => 'Got it! 🎉';

  @override
  String get tutorial_cookTitle => 'Your Recipes';

  @override
  String get tutorial_cookDesc =>
      'Browse AI-matched recipes based on what\'s in your fridge. The higher the match %, the more ingredients you already have!';

  @override
  String get tutorial_scanTitle => 'Scan Ingredients';

  @override
  String get tutorial_scanDesc =>
      'Use your camera to scan receipts, barcodes, or snap a photo of ingredients. Our AI will identify them instantly.';

  @override
  String get tutorial_shelfTitle => 'Your Living Shelf';

  @override
  String get tutorial_shelfDesc =>
      'Your digital fridge, freezer, and pantry. Track expiry dates and quantities — we\'ll warn you before food goes bad.';

  @override
  String get tutorial_profileTitle => 'Profile & Settings';

  @override
  String get tutorial_profileDesc =>
      'Tap the profile icon to change language, theme, manage your flavor profile, and track cooking streaks!';

  @override
  String get tutorial_replay => 'Replay Tutorial';

  @override
  String get tutorial_replayConfirm => 'Tutorial will show on next app launch.';

  @override
  String get auth_enterEmail => 'Please enter your email address first.';

  @override
  String get tutorial_tourTitle => 'Plately Interactive Tour';

  @override
  String get tutorial_tourDesc =>
      'Welcome! Let\'s take a quick 1-minute interactive tour of Plately. We will show you how to manage your ingredients, discover matching recipes, and start cooking!';

  @override
  String get tutorial_startTour => 'Start Tour 🚀';

  @override
  String get tutorial_skipTour => 'Skip';

  @override
  String get tutorial_shelfIntroTitle => 'Your Digital Shelf';

  @override
  String get tutorial_shelfIntroDesc =>
      'This is your digital fridge, freezer, and pantry. Here you can track quantities and expiry dates — we\'ll warn you before food goes bad. Let\'s see how it works!';

  @override
  String get tutorial_nextArrow => 'Next →';

  @override
  String get tutorial_addIntroTitle => 'Add Ingredients';

  @override
  String get tutorial_addIntroDesc =>
      'To add ingredients, tap the Scan tab (center camera icon) in the navigation bar. Go ahead, tap it!';

  @override
  String get tutorial_bypassScan => 'Bypass (Go to Scan)';

  @override
  String get tutorial_scanIntroTitle => 'Scan & Manually Add';

  @override
  String get tutorial_scanIntroDesc =>
      'Here you can scan receipts, barcodes, or snap a photo of ingredients. For this tutorial, we will automatically load 5 mock ingredients needed for a special stir-fry recipe.';

  @override
  String get tutorial_loadMock => 'Load Mock Ingredients 🛒';

  @override
  String get tutorial_shelfAddedTitle => 'Ingredients Loaded!';

  @override
  String get tutorial_shelfAddedDesc =>
      'Great! We\'ve loaded: Chicken Breast, Broccoli, Soy Sauce, Garlic, and Sesame Oil. Let\'s see what we can cook! Tap the Cook tab (left restaurant icon) to find matching recipes.';

  @override
  String get tutorial_bypassCook => 'Bypass (Go to Cook)';

  @override
  String get tutorial_roamCookTitle => '5-Tier Recommendations';

  @override
  String get tutorial_roamCookDesc =>
      'Here you see the 5-tier recommendation tabs (Perfect, For You, Use It Up, Almost, Explore). Tap around to explore them! When you are ready, tap the \"Tutorial Chicken Stir-fry\" recipe card under the Perfect tab.';

  @override
  String get tutorial_recipeDetailTitle => 'Recipe Details';

  @override
  String get tutorial_recipeDetailDesc =>
      'Here you see the ingredients list and steps. Tap the \"Start Cooking\" button at the bottom of the page to begin!';

  @override
  String get tutorial_cookingPrepTitle => 'Prep & Ingredients';

  @override
  String get tutorial_cookingPrepDesc =>
      'Before turning on the heat, wash and chop your ingredients. Tap the \"Begin Step-by-Step\" button to start the cooking assistant!';

  @override
  String get tutorial_cookingRunTitle => 'Cooking Assistant';

  @override
  String get tutorial_cookingRunDesc =>
      'The assistant guides you step-by-step. You can also chat with the AI assistant at the bottom for substitutions or cooking questions! Step through the recipe and tap \"Finish\" on the final step.';

  @override
  String get tutorial_finishTitle => 'Tutorial Completed!';

  @override
  String get tutorial_finishDesc =>
      'Congratulations! You\'ve completed the Plately cook tour.\n\nNote: All ingredients and data used in this tutorial will not be saved. This is just a small portion of the app. Tap \"Finish Tour\" to start your own cooking journey!';

  @override
  String get tutorial_finishTour => 'Finish Tour 🏁';

  @override
  String get tutorial_recipeTitle => 'Tutorial Chicken Stir-fry';

  @override
  String get tutorial_ing_chicken => 'Chicken Breast';

  @override
  String get tutorial_ing_broccoli => 'Broccoli';

  @override
  String get tutorial_ing_soy_sauce => 'Soy Sauce';

  @override
  String get tutorial_ing_garlic => 'Garlic';

  @override
  String get tutorial_ing_sesame_oil => 'Sesame Oil';

  @override
  String get tutorial_step1 =>
      'Chop the chicken breast into bite-sized pieces and cut the broccoli into small florets. Mince the garlic cloves.';

  @override
  String get tutorial_step1_beg =>
      'Carefully slice the chicken breast into small pieces. Cut the broccoli head into tiny florets. Peel and finely chop the garlic cloves.';

  @override
  String get tutorial_step2 =>
      'Heat sesame oil in a large pan or wok over medium-high heat. Add minced garlic and sauté for 1 minute until fragrant.';

  @override
  String get tutorial_step2_beg =>
      'Pour the sesame oil into a skillet. Turn the heat to medium. Add the garlic and stir it constantly for 1 minute so it doesn\'t burn.';

  @override
  String get tutorial_step3 =>
      'Add chicken breast pieces to the pan. Sauté for 5-6 minutes until cooked through and lightly browned.';

  @override
  String get tutorial_step3_beg =>
      'Carefully add the chopped chicken to the pan. Cook and stir occasionally for 5 to 6 minutes until the chicken is no longer pink inside.';

  @override
  String get tutorial_step4 =>
      'Add broccoli florets and soy sauce. Stir fry for another 3-4 minutes until broccoli is tender-crisp.';

  @override
  String get tutorial_step4_beg =>
      'Add the broccoli florets and pour in the soy sauce. Cook and stir everything together for 3 to 4 minutes until the broccoli is slightly soft but still bright green.';

  @override
  String get tutorial_step5 =>
      'Remove from heat. Serve your delicious chicken stir-fry warm over rice or by itself!';

  @override
  String get tutorial_step5_beg =>
      'Turn off the heat. Scoop the stir-fry onto a plate. Enjoy your freshly cooked meal!';

  @override
  String get reward_mealCompleted => 'Meal Completed!';

  @override
  String reward_youCooked(String recipeTitle, String servings) {
    return 'You cooked \"$recipeTitle\" · $servings servings';
  }

  @override
  String get reward_xpEarned => 'XP Earned';

  @override
  String get reward_itemsUsed => 'Items Used';

  @override
  String get reward_deducted => 'Deducted from shelf';

  @override
  String get reward_backToShelf => 'Back to Shelf';

  @override
  String get sortByExpiry => 'Expiry ↑';

  @override
  String get sortByName => 'Name A-Z';

  @override
  String get sortByCategory => 'Category';

  @override
  String get sortByNewest => 'Newest first';
}
