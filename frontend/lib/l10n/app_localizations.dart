import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('ru'),
    Locale('uz'),
    Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Plately'**
  String get appTitle;

  /// No description provided for @tabShelf.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get tabShelf;

  /// No description provided for @tabCook.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get tabCook;

  /// No description provided for @tabScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get tabScan;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileGamificationLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String profileGamificationLevel(int level);

  /// No description provided for @profileMealsCooked.
  ///
  /// In en, this message translates to:
  /// **'Meals Cooked'**
  String get profileMealsCooked;

  /// No description provided for @profileItemsSaved.
  ///
  /// In en, this message translates to:
  /// **'Items Saved'**
  String get profileItemsSaved;

  /// No description provided for @profileDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get profileDayStreak;

  /// No description provided for @profileFlavorProfile.
  ///
  /// In en, this message translates to:
  /// **'Flavor Profile'**
  String get profileFlavorProfile;

  /// No description provided for @profileBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges & Achievements'**
  String get profileBadges;

  /// No description provided for @profileShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get profileShoppingList;

  /// No description provided for @profileMealPlanner.
  ///
  /// In en, this message translates to:
  /// **'Meal Planner'**
  String get profileMealPlanner;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load profile'**
  String get profileLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @profileLevelProgress.
  ///
  /// In en, this message translates to:
  /// **'Level Progress'**
  String get profileLevelProgress;

  /// No description provided for @profileLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String profileLevel(int level);

  /// No description provided for @profileYourImpact.
  ///
  /// In en, this message translates to:
  /// **'Your Impact'**
  String get profileYourImpact;

  /// No description provided for @addShoppingItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addShoppingItem;

  /// No description provided for @shoppingListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get shoppingListEmpty;

  /// No description provided for @mealPlannerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meals planned'**
  String get mealPlannerEmpty;

  /// No description provided for @planToday.
  ///
  /// In en, this message translates to:
  /// **'Plan Today'**
  String get planToday;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @planMeal.
  ///
  /// In en, this message translates to:
  /// **'Plan meal...'**
  String get planMeal;

  /// No description provided for @tabExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get tabExplore;

  /// No description provided for @scanFood.
  ///
  /// In en, this message translates to:
  /// **'Scan Food'**
  String get scanFood;

  /// No description provided for @scanCalories.
  ///
  /// In en, this message translates to:
  /// **'Scan Calories'**
  String get scanCalories;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @analyzeCalories.
  ///
  /// In en, this message translates to:
  /// **'Analyze Calories'**
  String get analyzeCalories;

  /// No description provided for @caloriesPerServing.
  ///
  /// In en, this message translates to:
  /// **'cal/serving'**
  String get caloriesPerServing;

  /// No description provided for @totalCalories.
  ///
  /// In en, this message translates to:
  /// **'cal total'**
  String get totalCalories;

  /// No description provided for @creatorProfile.
  ///
  /// In en, this message translates to:
  /// **'Creator Profile'**
  String get creatorProfile;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @nutritionTracker.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Tracker'**
  String get nutritionTracker;

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @hasRecipe.
  ///
  /// In en, this message translates to:
  /// **'Has Recipe'**
  String get hasRecipe;

  /// No description provided for @noReelsYet.
  ///
  /// In en, this message translates to:
  /// **'No reels yet'**
  String get noReelsYet;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Plately'**
  String get aboutApp;

  /// No description provided for @myFridge.
  ///
  /// In en, this message translates to:
  /// **'🧊 My Fridge'**
  String get myFridge;

  /// No description provided for @expiryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Expiry alerts'**
  String get expiryAlerts;

  /// No description provided for @errorLoadInventory.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load inventory'**
  String get errorLoadInventory;

  /// No description provided for @errorCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get errorCheckConnection;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @fresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get fresh;

  /// No description provided for @expiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get expiring;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @searchIngredients.
  ///
  /// In en, this message translates to:
  /// **'Search ingredients...'**
  String get searchIngredients;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @zoneEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your {zone} is Empty'**
  String zoneEmptyTitle(String zone);

  /// No description provided for @zoneEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Ready to fill up your digital kitchen.\nAdd items manually or tap scan.'**
  String get zoneEmptyDesc;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get addIngredient;

  /// No description provided for @urgentCook.
  ///
  /// In en, this message translates to:
  /// **'Cook Now'**
  String get urgentCook;

  /// No description provided for @urgentUse.
  ///
  /// In en, this message translates to:
  /// **'Use {ingredient}'**
  String urgentUse(String ingredient);

  /// No description provided for @noItemsMatch.
  ///
  /// In en, this message translates to:
  /// **'No items match your filters'**
  String get noItemsMatch;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @expiryAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'🔔 Expiry Alerts'**
  String get expiryAlertsTitle;

  /// No description provided for @allFresh.
  ///
  /// In en, this message translates to:
  /// **'All items are fresh! 🎉'**
  String get allFresh;

  /// No description provided for @expiredCount.
  ///
  /// In en, this message translates to:
  /// **'❌ Expired ({count})'**
  String expiredCount(int count);

  /// No description provided for @expiringSoonCount.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Expiring Soon ({count})'**
  String expiringSoonCount(int count);

  /// No description provided for @auto_scanCaloriesIsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Scan Calories is coming soon!'**
  String get auto_scanCaloriesIsComingSoon;

  /// No description provided for @auto_scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get auto_scan;

  /// No description provided for @auto_addAll.
  ///
  /// In en, this message translates to:
  /// **'Add All'**
  String get auto_addAll;

  /// No description provided for @auto_allAdded.
  ///
  /// In en, this message translates to:
  /// **'All Added'**
  String get auto_allAdded;

  /// No description provided for @auto_scanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan Another'**
  String get auto_scanAnother;

  /// No description provided for @auto_startVisualAudit.
  ///
  /// In en, this message translates to:
  /// **'Start Visual Audit'**
  String get auto_startVisualAudit;

  /// No description provided for @auto_enterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter Barcode'**
  String get auto_enterBarcode;

  /// No description provided for @auto_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get auto_cancel;

  /// No description provided for @auto_lookUp.
  ///
  /// In en, this message translates to:
  /// **'Look Up'**
  String get auto_lookUp;

  /// No description provided for @auto_fridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get auto_fridge;

  /// No description provided for @auto_freezer.
  ///
  /// In en, this message translates to:
  /// **'Freezer'**
  String get auto_freezer;

  /// No description provided for @auto_pantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get auto_pantry;

  /// No description provided for @auto_addToShelf.
  ///
  /// In en, this message translates to:
  /// **'Add to Shelf'**
  String get auto_addToShelf;

  /// No description provided for @auto_mealLogged.
  ///
  /// In en, this message translates to:
  /// **'✅ Meal logged!'**
  String get auto_mealLogged;

  /// No description provided for @auto_snapYourMeal.
  ///
  /// In en, this message translates to:
  /// **'Snap Your Meal'**
  String get auto_snapYourMeal;

  /// No description provided for @auto_takeAPhotoAndAiWillEstimateCalories.
  ///
  /// In en, this message translates to:
  /// **'Take a photo and AI will estimate calories'**
  String get auto_takeAPhotoAndAiWillEstimateCalories;

  /// No description provided for @auto_analyzingFood.
  ///
  /// In en, this message translates to:
  /// **'Analyzing food...'**
  String get auto_analyzingFood;

  /// No description provided for @auto_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get auto_camera;

  /// No description provided for @auto_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get auto_gallery;

  /// No description provided for @auto_estimatedCalories.
  ///
  /// In en, this message translates to:
  /// **'estimated calories'**
  String get auto_estimatedCalories;

  /// No description provided for @auto_cal.
  ///
  /// In en, this message translates to:
  /// **'cal'**
  String get auto_cal;

  /// No description provided for @auto_logMeal.
  ///
  /// In en, this message translates to:
  /// **'Log Meal'**
  String get auto_logMeal;

  /// No description provided for @auto_addSomeIngredientsToYourShelfFirst.
  ///
  /// In en, this message translates to:
  /// **'Add some ingredients to your shelf first!'**
  String get auto_addSomeIngredientsToYourShelfFirst;

  /// No description provided for @auto_aiRecipeGenerator.
  ///
  /// In en, this message translates to:
  /// **'AI Recipe Generator'**
  String get auto_aiRecipeGenerator;

  /// No description provided for @auto_any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get auto_any;

  /// No description provided for @auto_shelfOnly.
  ///
  /// In en, this message translates to:
  /// **'Shelf Only'**
  String get auto_shelfOnly;

  /// No description provided for @auto_generateRecipe.
  ///
  /// In en, this message translates to:
  /// **'Generate Recipe'**
  String get auto_generateRecipe;

  /// No description provided for @auto_ingredients.
  ///
  /// In en, this message translates to:
  /// **'🧂 Ingredients'**
  String get auto_ingredients;

  /// No description provided for @auto_steps.
  ///
  /// In en, this message translates to:
  /// **'👨‍🍳 Steps'**
  String get auto_steps;

  /// No description provided for @auto_importRecipe.
  ///
  /// In en, this message translates to:
  /// **'Import Recipe'**
  String get auto_importRecipe;

  /// No description provided for @auto_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get auto_retry;

  /// No description provided for @auto_addItemsToYourShelfToGetRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Add items to your shelf to get recommendations'**
  String get auto_addItemsToYourShelfToGetRecommendations;

  /// No description provided for @auto_noRecipesMatchThisCuisine.
  ///
  /// In en, this message translates to:
  /// **'No recipes match this cuisine'**
  String get auto_noRecipesMatchThisCuisine;

  /// No description provided for @auto_clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get auto_clearFilter;

  /// No description provided for @auto_deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get auto_deleteItem;

  /// No description provided for @auto_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get auto_delete;

  /// No description provided for @auto_freshness.
  ///
  /// In en, this message translates to:
  /// **'Freshness'**
  String get auto_freshness;

  /// No description provided for @auto_use1Unit.
  ///
  /// In en, this message translates to:
  /// **'Use 1 Unit'**
  String get auto_use1Unit;

  /// No description provided for @auto_removeFromInventory.
  ///
  /// In en, this message translates to:
  /// **'Remove from Inventory'**
  String get auto_removeFromInventory;

  /// No description provided for @auto_following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get auto_following;

  /// No description provided for @auto_follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get auto_follow;

  /// No description provided for @auto_posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get auto_posts;

  /// No description provided for @auto_noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get auto_noPostsYet;

  /// No description provided for @auto_explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get auto_explore;

  /// No description provided for @auto_noReelsYet.
  ///
  /// In en, this message translates to:
  /// **'No reels yet'**
  String get auto_noReelsYet;

  /// No description provided for @auto_cookThisRecipe.
  ///
  /// In en, this message translates to:
  /// **'Cook This Recipe'**
  String get auto_cookThisRecipe;

  /// No description provided for @auto_recipeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recipe not found'**
  String get auto_recipeNotFound;

  /// No description provided for @auto_hasRecipe.
  ///
  /// In en, this message translates to:
  /// **'Has Recipe'**
  String get auto_hasRecipe;

  /// No description provided for @auto_noCommunityPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No community posts yet'**
  String get auto_noCommunityPostsYet;

  /// No description provided for @auto_beTheFirstToShare.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share!'**
  String get auto_beTheFirstToShare;

  /// No description provided for @auto_createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get auto_createPost;

  /// No description provided for @auto_savedPosts.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get auto_savedPosts;

  /// No description provided for @auto_noSavedPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved posts yet'**
  String get auto_noSavedPostsYet;

  /// No description provided for @auto_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get auto_you;

  /// No description provided for @auto_checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get auto_checkout;

  /// No description provided for @auto_yourCartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get auto_yourCartIsEmpty;

  /// No description provided for @auto_yourOrder.
  ///
  /// In en, this message translates to:
  /// **'Your Order'**
  String get auto_yourOrder;

  /// No description provided for @auto_total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get auto_total;

  /// No description provided for @auto_orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed!'**
  String get auto_orderConfirmed;

  /// No description provided for @auto_yourPickupCode.
  ///
  /// In en, this message translates to:
  /// **'Your Pickup Code'**
  String get auto_yourPickupCode;

  /// No description provided for @auto_showThisCodeAtTheCounter.
  ///
  /// In en, this message translates to:
  /// **'Show this code at the counter'**
  String get auto_showThisCodeAtTheCounter;

  /// No description provided for @auto_deliveryOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Delivery on the way'**
  String get auto_deliveryOnTheWay;

  /// No description provided for @auto_aDriverWillBeAssignedShortly.
  ///
  /// In en, this message translates to:
  /// **'A driver will be assigned shortly'**
  String get auto_aDriverWillBeAssignedShortly;

  /// No description provided for @auto_backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get auto_backToHome;

  /// No description provided for @auto_incomingOrders.
  ///
  /// In en, this message translates to:
  /// **'Incoming Orders'**
  String get auto_incomingOrders;

  /// No description provided for @auto_noFoodVideosYet.
  ///
  /// In en, this message translates to:
  /// **'No food videos yet'**
  String get auto_noFoodVideosYet;

  /// No description provided for @auto_foodFeed.
  ///
  /// In en, this message translates to:
  /// **'Food Feed'**
  String get auto_foodFeed;

  /// No description provided for @auto_myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get auto_myOrders;

  /// No description provided for @auto_noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get auto_noOrdersYet;

  /// No description provided for @auto_yourOrderHistoryWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your order history will appear here'**
  String get auto_yourOrderHistoryWillAppearHere;

  /// No description provided for @auto_cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order?'**
  String get auto_cancelOrder;

  /// No description provided for @auto_keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep Order'**
  String get auto_keepOrder;

  /// No description provided for @auto_orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get auto_orderCancelled;

  /// No description provided for @auto_pickupCode.
  ///
  /// In en, this message translates to:
  /// **'Pickup Code:'**
  String get auto_pickupCode;

  /// No description provided for @auto_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get auto_closed;

  /// No description provided for @auto_menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get auto_menu;

  /// No description provided for @auto_menuComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Menu coming soon'**
  String get auto_menuComingSoon;

  /// No description provided for @auto_best.
  ///
  /// In en, this message translates to:
  /// **'🔥 Best'**
  String get auto_best;

  /// No description provided for @auto_popularDishes.
  ///
  /// In en, this message translates to:
  /// **'🍽️ Popular Dishes'**
  String get auto_popularDishes;

  /// No description provided for @auto_fromVideo.
  ///
  /// In en, this message translates to:
  /// **'From video'**
  String get auto_fromVideo;

  /// No description provided for @auto_bookATable.
  ///
  /// In en, this message translates to:
  /// **'Book a Table'**
  String get auto_bookATable;

  /// No description provided for @auto_confirmReservation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reservation'**
  String get auto_confirmReservation;

  /// No description provided for @auto_locationDirections.
  ///
  /// In en, this message translates to:
  /// **'Location & Directions'**
  String get auto_locationDirections;

  /// No description provided for @auto_mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get auto_mapView;

  /// No description provided for @auto_openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get auto_openInGoogleMaps;

  /// No description provided for @auto_writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get auto_writeAReview;

  /// No description provided for @auto_viewCart.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get auto_viewCart;

  /// No description provided for @auto_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get auto_signOut;

  /// No description provided for @auto_youWillNeedToSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again.'**
  String get auto_youWillNeedToSignInAgain;

  /// No description provided for @auto_deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get auto_deleteAccount;

  /// No description provided for @auto_deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get auto_deleteForever;

  /// No description provided for @auto_accountDeletionRequestedContactSupportToFinalize.
  ///
  /// In en, this message translates to:
  /// **'Account deletion requested. Contact support to finalize.'**
  String get auto_accountDeletionRequestedContactSupportToFinalize;

  /// No description provided for @auto_plately.
  ///
  /// In en, this message translates to:
  /// **'Plately'**
  String get auto_plately;

  /// No description provided for @auto_platelyIsYourAipoweredKitchenEcosystemItAutomaticallyTracksYourIngredientsPredictsExpirationsGeneratesPersonalizedRecipesAndLetsYouOrderFromLocalRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Plately is your AI-powered kitchen ecosystem. It automatically tracks your ingredients, predicts expirations, generates personalized recipes, and lets you order from local restaurants.'**
  String
  get auto_platelyIsYourAipoweredKitchenEcosystemItAutomaticallyTracksYourIngredientsPredictsExpirationsGeneratesPersonalizedRecipesAndLetsYouOrderFromLocalRestaurants;

  /// No description provided for @auto_gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get auto_gotIt;

  /// No description provided for @auto_editDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Edit Display Name'**
  String get auto_editDisplayName;

  /// No description provided for @auto_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get auto_save;

  /// No description provided for @auto_addShoppingItem.
  ///
  /// In en, this message translates to:
  /// **'Add Shopping Item'**
  String get auto_addShoppingItem;

  /// No description provided for @auto_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get auto_add;

  /// No description provided for @auto_selectRecipeForMeal.
  ///
  /// In en, this message translates to:
  /// **'Select Recipe for Meal'**
  String get auto_selectRecipeForMeal;

  /// No description provided for @auto_failedToLoadRecipes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load recipes'**
  String get auto_failedToLoadRecipes;

  /// No description provided for @auto_noRecipesFound.
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get auto_noRecipesFound;

  /// No description provided for @auto_mealCleared.
  ///
  /// In en, this message translates to:
  /// **'Meal cleared'**
  String get auto_mealCleared;

  /// No description provided for @auto_theme.
  ///
  /// In en, this message translates to:
  /// **'🎨 Theme'**
  String get auto_theme;

  /// No description provided for @whatToCook.
  ///
  /// In en, this message translates to:
  /// **'What to Cook?'**
  String get whatToCook;

  /// No description provided for @tierPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get tierPerfect;

  /// No description provided for @tierForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get tierForYou;

  /// No description provided for @tierUseItUp.
  ///
  /// In en, this message translates to:
  /// **'Use It Up'**
  String get tierUseItUp;

  /// No description provided for @tierAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost'**
  String get tierAlmost;

  /// No description provided for @tierExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get tierExplore;

  /// No description provided for @noTierRecipesYet.
  ///
  /// In en, this message translates to:
  /// **'No {tier} recipes yet'**
  String noTierRecipesYet(String tier);

  /// No description provided for @addItemsForRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Add items to your shelf to get recommendations'**
  String get addItemsForRecommendations;

  /// No description provided for @scanCaloriesTab.
  ///
  /// In en, this message translates to:
  /// **'Scan Calories'**
  String get scanCaloriesTab;

  /// No description provided for @scanYourIngredients.
  ///
  /// In en, this message translates to:
  /// **'Scan Your Ingredients'**
  String get scanYourIngredients;

  /// No description provided for @takePhotoToAdd.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of food items to add them to your shelf automatically'**
  String get takePhotoToAdd;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get scanReceipt;

  /// No description provided for @scanPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get scanPhoto;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @takePhotoBtn.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhotoBtn;

  /// No description provided for @adjustPortions.
  ///
  /// In en, this message translates to:
  /// **'Adjust Portions'**
  String get adjustPortions;

  /// No description provided for @currentRecipeMakesNServings.
  ///
  /// In en, this message translates to:
  /// **'Current recipe makes {servings} servings.'**
  String currentRecipeMakesNServings(String servings);

  /// No description provided for @scaleToNServings.
  ///
  /// In en, this message translates to:
  /// **'Scale to {newServings} Servings'**
  String scaleToNServings(String newServings);

  /// No description provided for @scaledToNServings.
  ///
  /// In en, this message translates to:
  /// **'Scaled to {newServings} servings 🍳'**
  String scaledToNServings(String newServings);

  /// No description provided for @findingSubstitutesForX.
  ///
  /// In en, this message translates to:
  /// **'Finding substitutes for {ingredientName}...'**
  String findingSubstitutesForX(String ingredientName);

  /// No description provided for @couldNotFindSubstitutes.
  ///
  /// In en, this message translates to:
  /// **'Could not find substitutes'**
  String get couldNotFindSubstitutes;

  /// No description provided for @substitutesForX.
  ///
  /// In en, this message translates to:
  /// **'Substitutes for \"{ingredientName}\"'**
  String substitutesForX(String ingredientName);

  /// No description provided for @noSubstitutesFoundForThisRecipeContext.
  ///
  /// In en, this message translates to:
  /// **'No substitutes found for this recipe context.'**
  String get noSubstitutesFoundForThisRecipeContext;

  /// No description provided for @nMatch.
  ///
  /// In en, this message translates to:
  /// **'{match}% Match'**
  String nMatch(String match);

  /// No description provided for @ingredientsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Ingredients ({count})'**
  String ingredientsWithCount(String count);

  /// No description provided for @scale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get scale;

  /// No description provided for @addedMissingItemsToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Added missing items to Shopping List!'**
  String get addedMissingItemsToShoppingList;

  /// No description provided for @failedToAddItemsX.
  ///
  /// In en, this message translates to:
  /// **'Failed to add items: {e}'**
  String failedToAddItemsX(String e);

  /// No description provided for @addMissingToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Add missing to Shopping List'**
  String get addMissingToShoppingList;

  /// No description provided for @cookingStepsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Cooking Steps ({count})'**
  String cookingStepsWithCount(String count);

  /// No description provided for @noStepsAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No steps available yet'**
  String get noStepsAvailableYet;

  /// No description provided for @recordedTasteProfileEvolving.
  ///
  /// In en, this message translates to:
  /// **'Recorded! Your taste profile is evolving 🧠'**
  String get recordedTasteProfileEvolving;

  /// No description provided for @failedToRecordX.
  ///
  /// In en, this message translates to:
  /// **'Failed to record: {e}'**
  String failedToRecordX(String e);

  /// No description provided for @iCookedThis.
  ///
  /// In en, this message translates to:
  /// **'I Cooked This!'**
  String get iCookedThis;

  /// No description provided for @startCooking.
  ///
  /// In en, this message translates to:
  /// **'Start Cooking'**
  String get startCooking;

  /// No description provided for @optional_tag.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional_tag;

  /// No description provided for @servings_tag.
  ///
  /// In en, this message translates to:
  /// **'servings'**
  String get servings_tag;

  /// No description provided for @min_tag.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min_tag;

  /// No description provided for @difficulty_tag.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty_tag;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiringSoon;

  /// No description provided for @nItemsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) need attention'**
  String nItemsNeedAttention(String count);

  /// No description provided for @takeAPhotoOfFoodItems.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of food items to add them\nto your shelf automatically'**
  String get takeAPhotoOfFoodItems;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get addManually;

  /// No description provided for @recognitionFailed.
  ///
  /// In en, this message translates to:
  /// **'Recognition failed. Try again.'**
  String get recognitionFailed;

  /// No description provided for @analyzingYourFood.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your food...'**
  String get analyzingYourFood;

  /// No description provided for @aiIsIdentifying.
  ///
  /// In en, this message translates to:
  /// **'AI is identifying ingredients'**
  String get aiIsIdentifying;

  /// No description provided for @nItemsDetected.
  ///
  /// In en, this message translates to:
  /// **'{count} Items Detected'**
  String nItemsDetected(String count);

  /// No description provided for @photoAnalysisSelected.
  ///
  /// In en, this message translates to:
  /// **'Photo Analysis Selected'**
  String get photoAnalysisSelected;

  /// No description provided for @nIngredientsDetected.
  ///
  /// In en, this message translates to:
  /// **'{count} Ingredients Detected'**
  String nIngredientsDetected(String count);

  /// No description provided for @nOfNAdded.
  ///
  /// In en, this message translates to:
  /// **'{added} / {total} added'**
  String nOfNAdded(String added, String total);

  /// No description provided for @addedItem.
  ///
  /// In en, this message translates to:
  /// **'Added {item}!'**
  String addedItem(String item);

  /// No description provided for @failedToAddItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to add {item}'**
  String failedToAddItem(String item);

  /// No description provided for @addedNItemsToShelf.
  ///
  /// In en, this message translates to:
  /// **'Added {count} items to shelf!'**
  String addedNItemsToShelf(String count);

  /// No description provided for @noProductFoundForBarcode.
  ///
  /// In en, this message translates to:
  /// **'No product found for barcode {barcode}'**
  String noProductFoundForBarcode(String barcode);

  /// No description provided for @addedItemToShelf.
  ///
  /// In en, this message translates to:
  /// **'Added {item} to shelf!'**
  String addedItemToShelf(String item);

  /// No description provided for @errorX.
  ///
  /// In en, this message translates to:
  /// **'Error: {e}'**
  String errorX(String e);

  /// No description provided for @analysisFailedX.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed: {e}'**
  String analysisFailedX(String e);

  /// No description provided for @failedToLogX.
  ///
  /// In en, this message translates to:
  /// **'Failed to log: {e}'**
  String failedToLogX(String e);

  /// No description provided for @scanBarcodeShort.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get scanBarcodeShort;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @tierBadge1.
  ///
  /// In en, this message translates to:
  /// **'✅ Everything you need!'**
  String get tierBadge1;

  /// No description provided for @tierBadge2.
  ///
  /// In en, this message translates to:
  /// **'🔥 Recommended for you'**
  String get tierBadge2;

  /// No description provided for @tierBadge3.
  ///
  /// In en, this message translates to:
  /// **'⏰ Use expiring items'**
  String get tierBadge3;

  /// No description provided for @tierBadge4.
  ///
  /// In en, this message translates to:
  /// **'🛒 Just a few items away'**
  String get tierBadge4;

  /// No description provided for @tierBadge5.
  ///
  /// In en, this message translates to:
  /// **'🌍 Discover something new'**
  String get tierBadge5;

  /// No description provided for @needLabel.
  ///
  /// In en, this message translates to:
  /// **'Need: {items}'**
  String needLabel(String items);

  /// No description provided for @nOfNIngredients.
  ///
  /// In en, this message translates to:
  /// **'{matched}/{total} ingredients'**
  String nOfNIngredients(String matched, String total);

  /// No description provided for @servingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get servingsLabel;

  /// No description provided for @nHave.
  ///
  /// In en, this message translates to:
  /// **'{count} have'**
  String nHave(String count);

  /// No description provided for @nMissing.
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String nMissing(String count);

  /// No description provided for @ingredientsHeader.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsHeader;

  /// No description provided for @swapButton.
  ///
  /// In en, this message translates to:
  /// **'Swap →'**
  String get swapButton;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'🤖 AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"I don\'t have lamb, suggest alternatives\"'**
  String get aiHint;

  /// No description provided for @editIngredient.
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredient'**
  String get editIngredient;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qtyLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @handsOn.
  ///
  /// In en, this message translates to:
  /// **'Hands-on'**
  String get handsOn;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @inv_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inv_quantity;

  /// No description provided for @inv_purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get inv_purchased;

  /// No description provided for @inv_expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get inv_expires;

  /// No description provided for @inv_source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get inv_source;

  /// No description provided for @inv_storageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get inv_storageLocation;

  /// No description provided for @inv_itemState.
  ///
  /// In en, this message translates to:
  /// **'Item State'**
  String get inv_itemState;

  /// No description provided for @inv_freshLabel.
  ///
  /// In en, this message translates to:
  /// **'🟢 Fresh'**
  String get inv_freshLabel;

  /// No description provided for @inv_agingLabel.
  ///
  /// In en, this message translates to:
  /// **'🟡 Aging'**
  String get inv_agingLabel;

  /// No description provided for @inv_urgentLabel.
  ///
  /// In en, this message translates to:
  /// **'🟠 Urgent'**
  String get inv_urgentLabel;

  /// No description provided for @inv_criticalLabel.
  ///
  /// In en, this message translates to:
  /// **'🔴 Critical'**
  String get inv_criticalLabel;

  /// No description provided for @inv_expiredLabel.
  ///
  /// In en, this message translates to:
  /// **'⚫ Expired'**
  String get inv_expiredLabel;

  /// No description provided for @inv_expiredDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Expired {days}d ago'**
  String inv_expiredDaysAgo(String days);

  /// No description provided for @inv_expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today!'**
  String get inv_expiresToday;

  /// No description provided for @inv_expiresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Expires tomorrow'**
  String get inv_expiresTomorrow;

  /// No description provided for @inv_daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String inv_daysRemaining(String days);

  /// No description provided for @inv_stateOpened.
  ///
  /// In en, this message translates to:
  /// **'OPENED'**
  String get inv_stateOpened;

  /// No description provided for @inv_stateFrozen.
  ///
  /// In en, this message translates to:
  /// **'FROZEN'**
  String get inv_stateFrozen;

  /// No description provided for @inv_stateThawed.
  ///
  /// In en, this message translates to:
  /// **'THAWED'**
  String get inv_stateThawed;

  /// No description provided for @inv_statePartial.
  ///
  /// In en, this message translates to:
  /// **'PARTIAL'**
  String get inv_statePartial;

  /// No description provided for @inv_sortExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry ↑'**
  String get inv_sortExpiry;

  /// No description provided for @inv_sortName.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get inv_sortName;

  /// No description provided for @inv_sortCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inv_sortCategory;

  /// No description provided for @inv_sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get inv_sortNewest;

  /// No description provided for @inv_removeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from your inventory?'**
  String inv_removeConfirm(String name);

  /// No description provided for @manual_addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get manual_addIngredient;

  /// No description provided for @manual_ingredientName.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Name'**
  String get manual_ingredientName;

  /// No description provided for @manual_ingredientHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Apples, Bread, Milk'**
  String get manual_ingredientHint;

  /// No description provided for @manual_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get manual_category;

  /// No description provided for @manual_qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get manual_qty;

  /// No description provided for @manual_metricType.
  ///
  /// In en, this message translates to:
  /// **'Metric Type'**
  String get manual_metricType;

  /// No description provided for @manual_estimatedExpiry.
  ///
  /// In en, this message translates to:
  /// **'Estimated Expiry'**
  String get manual_estimatedExpiry;

  /// No description provided for @manual_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get manual_required;

  /// No description provided for @auth_tagline.
  ///
  /// In en, this message translates to:
  /// **'Zero‑Waste, Maximum Taste.'**
  String get auth_tagline;

  /// No description provided for @auth_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen, intelligently managed.'**
  String get auth_subtitle;

  /// No description provided for @auth_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_email;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get auth_continue;

  /// No description provided for @auth_or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get auth_or;

  /// No description provided for @auth_continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get auth_continueGoogle;

  /// No description provided for @auth_continueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get auth_continueGuest;

  /// No description provided for @auth_autoDetectHint.
  ///
  /// In en, this message translates to:
  /// **'New here? We\'ll create your account automatically.'**
  String get auth_autoDetectHint;

  /// No description provided for @auth_checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Please check your email to verify your account.'**
  String get auth_checkEmail;

  /// No description provided for @auth_enterBoth.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password.'**
  String get auth_enterBoth;

  /// No description provided for @auth_unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get auth_unexpectedError;

  /// No description provided for @auth_googleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign‑in failed. Please try again.'**
  String get auth_googleFailed;

  /// No description provided for @auth_guestFailed.
  ///
  /// In en, this message translates to:
  /// **'Guest sign‑in failed. Please try email or Google instead.'**
  String get auth_guestFailed;

  /// No description provided for @auth_resetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get auth_resetSent;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get auth_forgotPassword;

  /// No description provided for @import_recipe.
  ///
  /// In en, this message translates to:
  /// **'Import Recipe'**
  String get import_recipe;

  /// No description provided for @import_pasteRaw.
  ///
  /// In en, this message translates to:
  /// **'Paste Raw Recipe'**
  String get import_pasteRaw;

  /// No description provided for @import_description.
  ///
  /// In en, this message translates to:
  /// **'Copy and paste instructions from a website, book, or notes app. Our AI will magically convert it into a step-by-step smart recipe.'**
  String get import_description;

  /// No description provided for @import_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grandma\'s Cookies\nMix 2 cups flour with 1 cup sugar... bake at 350 for 10 mins.'**
  String get import_hint;

  /// No description provided for @import_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Recipe...'**
  String get import_analyzing;

  /// No description provided for @import_parseWithAi.
  ///
  /// In en, this message translates to:
  /// **'Parse with AI'**
  String get import_parseWithAi;

  /// No description provided for @import_parsedRecipe.
  ///
  /// In en, this message translates to:
  /// **'Parsed Recipe'**
  String get import_parsedRecipe;

  /// No description provided for @import_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get import_steps;

  /// No description provided for @import_saveButton.
  ///
  /// In en, this message translates to:
  /// **'Looks Good — Save to My Recipes'**
  String get import_saveButton;

  /// No description provided for @import_savedLocally.
  ///
  /// In en, this message translates to:
  /// **'Recipe saved to My Recipes!'**
  String get import_savedLocally;

  /// No description provided for @tutorial_next.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get tutorial_next;

  /// No description provided for @tutorial_gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it! 🎉'**
  String get tutorial_gotIt;

  /// No description provided for @tutorial_cookTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Recipes'**
  String get tutorial_cookTitle;

  /// No description provided for @tutorial_cookDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse AI-matched recipes based on what\'s in your fridge. The higher the match %, the more ingredients you already have!'**
  String get tutorial_cookDesc;

  /// No description provided for @tutorial_scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Ingredients'**
  String get tutorial_scanTitle;

  /// No description provided for @tutorial_scanDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your camera to scan receipts, barcodes, or snap a photo of ingredients. Our AI will identify them instantly.'**
  String get tutorial_scanDesc;

  /// No description provided for @tutorial_shelfTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Living Shelf'**
  String get tutorial_shelfTitle;

  /// No description provided for @tutorial_shelfDesc.
  ///
  /// In en, this message translates to:
  /// **'Your digital fridge, freezer, and pantry. Track expiry dates and quantities — we\'ll warn you before food goes bad.'**
  String get tutorial_shelfDesc;

  /// No description provided for @tutorial_profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get tutorial_profileTitle;

  /// No description provided for @tutorial_profileDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the profile icon to change language, theme, manage your flavor profile, and track cooking streaks!'**
  String get tutorial_profileDesc;

  /// No description provided for @tutorial_replay.
  ///
  /// In en, this message translates to:
  /// **'Replay Tutorial'**
  String get tutorial_replay;

  /// No description provided for @tutorial_replayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Tutorial will show on next app launch.'**
  String get tutorial_replayConfirm;

  /// No description provided for @auth_enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address first.'**
  String get auth_enterEmail;

  /// No description provided for @tutorial_tourTitle.
  ///
  /// In en, this message translates to:
  /// **'Plately Interactive Tour'**
  String get tutorial_tourTitle;

  /// No description provided for @tutorial_tourDesc.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Let\'s take a quick 1-minute interactive tour of Plately. We will show you how to manage your ingredients, discover matching recipes, and start cooking!'**
  String get tutorial_tourDesc;

  /// No description provided for @tutorial_startTour.
  ///
  /// In en, this message translates to:
  /// **'Start Tour 🚀'**
  String get tutorial_startTour;

  /// No description provided for @tutorial_skipTour.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorial_skipTour;

  /// No description provided for @tutorial_shelfIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Digital Shelf'**
  String get tutorial_shelfIntroTitle;

  /// No description provided for @tutorial_shelfIntroDesc.
  ///
  /// In en, this message translates to:
  /// **'This is your digital fridge, freezer, and pantry. Here you can track quantities and expiry dates — we\'ll warn you before food goes bad. Let\'s see how it works!'**
  String get tutorial_shelfIntroDesc;

  /// No description provided for @tutorial_nextArrow.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get tutorial_nextArrow;

  /// No description provided for @tutorial_addIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredients'**
  String get tutorial_addIntroTitle;

  /// No description provided for @tutorial_addIntroDesc.
  ///
  /// In en, this message translates to:
  /// **'To add ingredients, tap the Scan tab (center camera icon) in the navigation bar. Go ahead, tap it!'**
  String get tutorial_addIntroDesc;

  /// No description provided for @tutorial_bypassScan.
  ///
  /// In en, this message translates to:
  /// **'Bypass (Go to Scan)'**
  String get tutorial_bypassScan;

  /// No description provided for @tutorial_scanIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan & Manually Add'**
  String get tutorial_scanIntroTitle;

  /// No description provided for @tutorial_scanIntroDesc.
  ///
  /// In en, this message translates to:
  /// **'Here you can scan receipts, barcodes, or snap a photo of ingredients. For this tutorial, we will automatically load 5 mock ingredients needed for a special stir-fry recipe.'**
  String get tutorial_scanIntroDesc;

  /// No description provided for @tutorial_loadMock.
  ///
  /// In en, this message translates to:
  /// **'Load Mock Ingredients 🛒'**
  String get tutorial_loadMock;

  /// No description provided for @tutorial_shelfAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients Loaded!'**
  String get tutorial_shelfAddedTitle;

  /// No description provided for @tutorial_shelfAddedDesc.
  ///
  /// In en, this message translates to:
  /// **'Great! We\'ve loaded: Chicken Breast, Broccoli, Soy Sauce, Garlic, and Sesame Oil. Let\'s see what we can cook! Tap the Cook tab (left restaurant icon) to find matching recipes.'**
  String get tutorial_shelfAddedDesc;

  /// No description provided for @tutorial_bypassCook.
  ///
  /// In en, this message translates to:
  /// **'Bypass (Go to Cook)'**
  String get tutorial_bypassCook;

  /// No description provided for @tutorial_roamCookTitle.
  ///
  /// In en, this message translates to:
  /// **'5-Tier Recommendations'**
  String get tutorial_roamCookTitle;

  /// No description provided for @tutorial_roamCookDesc.
  ///
  /// In en, this message translates to:
  /// **'Here you see the 5-tier recommendation tabs (Perfect, For You, Use It Up, Almost, Explore). Tap around to explore them! When you are ready, tap the \"Tutorial Chicken Stir-fry\" recipe card under the Perfect tab.'**
  String get tutorial_roamCookDesc;

  /// No description provided for @tutorial_recipeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe Details'**
  String get tutorial_recipeDetailTitle;

  /// No description provided for @tutorial_recipeDetailDesc.
  ///
  /// In en, this message translates to:
  /// **'Here you see the ingredients list and steps. Tap the \"Start Cooking\" button at the bottom of the page to begin!'**
  String get tutorial_recipeDetailDesc;

  /// No description provided for @tutorial_cookingPrepTitle.
  ///
  /// In en, this message translates to:
  /// **'Prep & Ingredients'**
  String get tutorial_cookingPrepTitle;

  /// No description provided for @tutorial_cookingPrepDesc.
  ///
  /// In en, this message translates to:
  /// **'Before turning on the heat, wash and chop your ingredients. Tap the \"Begin Step-by-Step\" button to start the cooking assistant!'**
  String get tutorial_cookingPrepDesc;

  /// No description provided for @tutorial_cookingRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking Assistant'**
  String get tutorial_cookingRunTitle;

  /// No description provided for @tutorial_cookingRunDesc.
  ///
  /// In en, this message translates to:
  /// **'The assistant guides you step-by-step. You can also chat with the AI assistant at the bottom for substitutions or cooking questions! Step through the recipe and tap \"Finish\" on the final step.'**
  String get tutorial_cookingRunDesc;

  /// No description provided for @tutorial_finishTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial Completed!'**
  String get tutorial_finishTitle;

  /// No description provided for @tutorial_finishDesc.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve completed the Plately cook tour.\n\nNote: All ingredients and data used in this tutorial will not be saved. This is just a small portion of the app. Tap \"Finish Tour\" to start your own cooking journey!'**
  String get tutorial_finishDesc;

  /// No description provided for @tutorial_finishTour.
  ///
  /// In en, this message translates to:
  /// **'Finish Tour 🏁'**
  String get tutorial_finishTour;

  /// No description provided for @tutorial_recipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial Chicken Stir-fry'**
  String get tutorial_recipeTitle;

  /// No description provided for @tutorial_ing_chicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken Breast'**
  String get tutorial_ing_chicken;

  /// No description provided for @tutorial_ing_broccoli.
  ///
  /// In en, this message translates to:
  /// **'Broccoli'**
  String get tutorial_ing_broccoli;

  /// No description provided for @tutorial_ing_soy_sauce.
  ///
  /// In en, this message translates to:
  /// **'Soy Sauce'**
  String get tutorial_ing_soy_sauce;

  /// No description provided for @tutorial_ing_garlic.
  ///
  /// In en, this message translates to:
  /// **'Garlic'**
  String get tutorial_ing_garlic;

  /// No description provided for @tutorial_ing_sesame_oil.
  ///
  /// In en, this message translates to:
  /// **'Sesame Oil'**
  String get tutorial_ing_sesame_oil;

  /// No description provided for @tutorial_step1.
  ///
  /// In en, this message translates to:
  /// **'Chop the chicken breast into bite-sized pieces and cut the broccoli into small florets. Mince the garlic cloves.'**
  String get tutorial_step1;

  /// No description provided for @tutorial_step1_beg.
  ///
  /// In en, this message translates to:
  /// **'Carefully slice the chicken breast into small pieces. Cut the broccoli head into tiny florets. Peel and finely chop the garlic cloves.'**
  String get tutorial_step1_beg;

  /// No description provided for @tutorial_step2.
  ///
  /// In en, this message translates to:
  /// **'Heat sesame oil in a large pan or wok over medium-high heat. Add minced garlic and sauté for 1 minute until fragrant.'**
  String get tutorial_step2;

  /// No description provided for @tutorial_step2_beg.
  ///
  /// In en, this message translates to:
  /// **'Pour the sesame oil into a skillet. Turn the heat to medium. Add the garlic and stir it constantly for 1 minute so it doesn\'t burn.'**
  String get tutorial_step2_beg;

  /// No description provided for @tutorial_step3.
  ///
  /// In en, this message translates to:
  /// **'Add chicken breast pieces to the pan. Sauté for 5-6 minutes until cooked through and lightly browned.'**
  String get tutorial_step3;

  /// No description provided for @tutorial_step3_beg.
  ///
  /// In en, this message translates to:
  /// **'Carefully add the chopped chicken to the pan. Cook and stir occasionally for 5 to 6 minutes until the chicken is no longer pink inside.'**
  String get tutorial_step3_beg;

  /// No description provided for @tutorial_step4.
  ///
  /// In en, this message translates to:
  /// **'Add broccoli florets and soy sauce. Stir fry for another 3-4 minutes until broccoli is tender-crisp.'**
  String get tutorial_step4;

  /// No description provided for @tutorial_step4_beg.
  ///
  /// In en, this message translates to:
  /// **'Add the broccoli florets and pour in the soy sauce. Cook and stir everything together for 3 to 4 minutes until the broccoli is slightly soft but still bright green.'**
  String get tutorial_step4_beg;

  /// No description provided for @tutorial_step5.
  ///
  /// In en, this message translates to:
  /// **'Remove from heat. Serve your delicious chicken stir-fry warm over rice or by itself!'**
  String get tutorial_step5;

  /// No description provided for @tutorial_step5_beg.
  ///
  /// In en, this message translates to:
  /// **'Turn off the heat. Scoop the stir-fry onto a plate. Enjoy your freshly cooked meal!'**
  String get tutorial_step5_beg;

  /// No description provided for @reward_mealCompleted.
  ///
  /// In en, this message translates to:
  /// **'Meal Completed!'**
  String get reward_mealCompleted;

  /// No description provided for @reward_youCooked.
  ///
  /// In en, this message translates to:
  /// **'You cooked \"{recipeTitle}\" · {servings} servings'**
  String reward_youCooked(String recipeTitle, String servings);

  /// No description provided for @reward_xpEarned.
  ///
  /// In en, this message translates to:
  /// **'XP Earned'**
  String get reward_xpEarned;

  /// No description provided for @reward_itemsUsed.
  ///
  /// In en, this message translates to:
  /// **'Items Used'**
  String get reward_itemsUsed;

  /// No description provided for @reward_deducted.
  ///
  /// In en, this message translates to:
  /// **'Deducted from shelf'**
  String get reward_deducted;

  /// No description provided for @reward_backToShelf.
  ///
  /// In en, this message translates to:
  /// **'Back to Shelf'**
  String get reward_backToShelf;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'uz':
      {
        switch (locale.scriptCode) {
          case 'Cyrl':
            return AppLocalizationsUzCyrl();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
