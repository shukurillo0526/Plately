// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Plately';

  @override
  String get tabShelf => 'Javon';

  @override
  String get tabCook => 'Pishirish';

  @override
  String get tabScan => 'Skanerlash';

  @override
  String get tabProfile => 'Profil';

  @override
  String get profileTitle => 'Profil';

  @override
  String profileGamificationLevel(int level) {
    return '$level-daraja';
  }

  @override
  String get profileMealsCooked => 'Pishirilgan taomlar';

  @override
  String get profileItemsSaved => 'Saqlangan mahsulotlar';

  @override
  String get profileDayStreak => 'Kunlik seriya';

  @override
  String get profileFlavorProfile => 'Ta\'m profili';

  @override
  String get profileBadges => 'Nishonlar va yutuqlar';

  @override
  String get profileShoppingList => 'Xarid ro\'yxati';

  @override
  String get profileMealPlanner => 'Ovqatlanish rejasi';

  @override
  String get actionAdd => 'Qo\'shish';

  @override
  String get actionCancel => 'Bekor qilish';

  @override
  String get actionSave => 'Saqlash';

  @override
  String get actionDelete => 'O\'chirish';

  @override
  String get profileLoadError => 'Profilni yuklab bo\'lmadi';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get refresh => 'Yangilash';

  @override
  String get signOut => 'Chiqish';

  @override
  String get profileLevelProgress => 'Daraja jarayoni';

  @override
  String profileLevel(int level) {
    return '$level-daraja';
  }

  @override
  String get profileYourImpact => 'Sizning ta\'siringiz';

  @override
  String get addShoppingItem => 'Element qo\'shish';

  @override
  String get shoppingListEmpty => 'Xaridlar ro\'yxati bo\'sh';

  @override
  String get mealPlannerEmpty => 'Rejalashtirilgan taomlar yo\'q';

  @override
  String get planToday => 'Bugungi reja';

  @override
  String get today => 'Bugun';

  @override
  String get planMeal => 'Taom rejalashtirish...';

  @override
  String get tabExplore => 'Kashfiyot';

  @override
  String get scanFood => 'Ovqatni skanerlash';

  @override
  String get scanCalories => 'Kaloriya skanerlash';

  @override
  String get takePhoto => 'Suratga olish';

  @override
  String get chooseFromGallery => 'Galereyadan tanlang';

  @override
  String get analyzeCalories => 'Kaloriyalarni tahlil qilish';

  @override
  String get caloriesPerServing => 'kal/porsiya';

  @override
  String get totalCalories => 'jami kal';

  @override
  String get creatorProfile => 'Muallif profili';

  @override
  String get follow => 'Obuna bo\'lish';

  @override
  String get following => 'Obuna bo\'lingan';

  @override
  String get nutritionTracker => 'Oziqlanish kuzatuvi';

  @override
  String get reels => 'Video';

  @override
  String get community => 'Jamoa';

  @override
  String get hasRecipe => 'Retsept bor';

  @override
  String get noReelsYet => 'Hozircha videolar yo\'q';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get settingsLanguage => 'Til';

  @override
  String get settingsTheme => 'Mavzu';

  @override
  String get aboutApp => 'Plately haqida';

  @override
  String get myFridge => '🧊 Mening muzlatgichim';

  @override
  String get expiryAlerts => 'Muddati tugashi haqida ogohlantirishlar';

  @override
  String get errorLoadInventory => 'Omborni yuklab bo‘lmadi';

  @override
  String get errorCheckConnection =>
      'Ulanishingizni tekshiring va qaytadan urining.';

  @override
  String get total => 'Jami';

  @override
  String get fresh => 'Yangi';

  @override
  String get expiring => 'Muddati tugayapti';

  @override
  String get expired => 'Muddati tugagan';

  @override
  String get searchIngredients => 'Ingredientlarni qidirish...';

  @override
  String get all => 'Hammasi';

  @override
  String itemsCount(int count) {
    return '$count elementlari';
  }

  @override
  String zoneEmptyTitle(String zone) {
    return 'Sizning $zone bo\'sh';
  }

  @override
  String get zoneEmptyDesc =>
      'Raqamli oshxonangizni to\'ldirishga tayyor.\nElementlarni qoʻlda qoʻshing yoki skanerlash tugmasini bosing.';

  @override
  String get addIngredient => 'Ingredient qo\'shing';

  @override
  String get urgentCook => 'Hozir pishiring';

  @override
  String urgentUse(String ingredient) {
    return '$ingredient dan foydalaning';
  }

  @override
  String get noItemsMatch => 'Hech qanday element filtringizga mos kelmaydi';

  @override
  String get clearFilters => 'Filtrlarni tozalash';

  @override
  String get expiryAlertsTitle => '🔔 Muddati tugashi haqida ogohlantirishlar';

  @override
  String get allFresh => 'Barcha mahsulotlar yangi! 🎉';

  @override
  String expiredCount(int count) {
    return '❌ Muddati tugagan ($count)';
  }

  @override
  String expiringSoonCount(int count) {
    return '⚠️ Tez orada tugaydi ($count)';
  }

  @override
  String get auto_scanCaloriesIsComingSoon =>
      'Kaloriyalarni skanerlash tez orada!';

  @override
  String get auto_scan => 'Skanerlash';

  @override
  String get auto_addAll => 'Hammasini qo\'shish';

  @override
  String get auto_allAdded => 'Hammasi qo\'shildi';

  @override
  String get auto_scanAnother => 'Boshqasini skanerlash';

  @override
  String get auto_startVisualAudit => 'Vizual auditni boshlang';

  @override
  String get auto_enterBarcode => 'Shtrix kodini kiriting';

  @override
  String get auto_cancel => 'Bekor qilish';

  @override
  String get auto_lookUp => 'Axtarish, izlash';

  @override
  String get auto_fridge => 'Muzlatgich';

  @override
  String get auto_freezer => 'Muzlatish kamerasi';

  @override
  String get auto_pantry => 'Omborxona';

  @override
  String get auto_addToShelf => 'Rafga qo\'shish';

  @override
  String get auto_mealLogged => '✅ Ovqat qayd etildi!';

  @override
  String get auto_snapYourMeal => 'Ovqatlanishni yeng';

  @override
  String get auto_takeAPhotoAndAiWillEstimateCalories =>
      'Suratga oling va AI kaloriyalarni hisoblab chiqadi';

  @override
  String get auto_analyzingFood => 'Oziq-ovqatlarni tahlil qilish...';

  @override
  String get auto_camera => 'Kamera';

  @override
  String get auto_gallery => 'Galereya';

  @override
  String get auto_estimatedCalories => 'taxmin qilingan kaloriyalar';

  @override
  String get auto_cal => 'kal';

  @override
  String get auto_logMeal => 'Kundalik ovqat';

  @override
  String get auto_addSomeIngredientsToYourShelfFirst =>
      'Avval javoningizga ba\'zi ingredientlarni qo\'shing!';

  @override
  String get auto_aiRecipeGenerator => 'AI retsepti generatori';

  @override
  String get auto_any => 'Har qanday';

  @override
  String get auto_shelfOnly => 'Faqat javon';

  @override
  String get auto_generateRecipe => 'Retsept yaratish';

  @override
  String get auto_ingredients => '🧂 Tarkibi';

  @override
  String get auto_steps => '👨‍🍳 Qadamlar';

  @override
  String get auto_importRecipe => 'Import retsepti';

  @override
  String get auto_retry => 'Qayta urinish';

  @override
  String get auto_addItemsToYourShelfToGetRecommendations =>
      'Tavsiyalarni olish uchun javoningizga narsalarni qo\'shing';

  @override
  String get auto_noRecipesMatchThisCuisine =>
      'Hech qanday retsept bu oshxonaga mos kelmaydi';

  @override
  String get auto_clearFilter => 'Filtrni tozalash';

  @override
  String get auto_deleteItem => 'Element oʻchirilsinmi?';

  @override
  String get auto_delete => 'Oʻchirish';

  @override
  String get auto_freshness => 'Yangilik';

  @override
  String get auto_use1Unit => '1 birlikdan foydalaning';

  @override
  String get auto_removeFromInventory => 'Ombordan olib tashlash';

  @override
  String get auto_following => 'Obuna bo\'lingan';

  @override
  String get auto_follow => 'Obuna bo\'lish';

  @override
  String get auto_posts => 'Xabarlar';

  @override
  String get auto_noPostsYet => 'Hozircha postlar yo‘q';

  @override
  String get auto_explore => 'Kashf qilish';

  @override
  String get auto_noReelsYet => 'Hali videolar yo\'q';

  @override
  String get auto_cookThisRecipe => 'Ushbu retseptni pishiring';

  @override
  String get auto_recipeNotFound => 'Retsept topilmadi';

  @override
  String get auto_hasRecipe => 'Retsepti bor';

  @override
  String get auto_noCommunityPostsYet => 'Hozircha jamoat postlari yo‘q';

  @override
  String get auto_beTheFirstToShare => 'Birinchi bo\'lib baham ko\'ring!';

  @override
  String get auto_createPost => 'Post yaratish';

  @override
  String get auto_savedPosts => 'Saqlangan xabarlar';

  @override
  String get auto_noSavedPostsYet => 'Hali hech qanday post saqlangan emas';

  @override
  String get auto_you => 'Siz';

  @override
  String get auto_checkout => 'Ro\'yxatdan o\'chirilish';

  @override
  String get auto_yourCartIsEmpty => 'Savatingiz boʻsh';

  @override
  String get auto_yourOrder => 'Sizning buyurtmangiz';

  @override
  String get auto_total => 'jami';

  @override
  String get auto_orderConfirmed => 'Buyurtma tasdiqlandi!';

  @override
  String get auto_yourPickupCode => 'Qabul qilish kodingiz';

  @override
  String get auto_showThisCodeAtTheCounter =>
      'Ushbu kodni peshtaxtada ko\'rsating';

  @override
  String get auto_deliveryOnTheWay => 'Yetkazib berish yo\'lda';

  @override
  String get auto_aDriverWillBeAssignedShortly =>
      'Tez orada haydovchi tayinlanadi';

  @override
  String get auto_backToHome => 'Uyga qaytish';

  @override
  String get auto_incomingOrders => 'Kiruvchi Buyurtmalar';

  @override
  String get auto_noFoodVideosYet => 'Hozircha ovqat haqida video yo\'q';

  @override
  String get auto_foodFeed => 'Oziq-ovqat';

  @override
  String get auto_myOrders => 'Mening Buyurtmalarim';

  @override
  String get auto_noOrdersYet => 'Hozircha buyurtmalar yo\'q';

  @override
  String get auto_yourOrderHistoryWillAppearHere =>
      'Buyurtmalaringiz tarixi shu yerda paydo bo\'ladi';

  @override
  String get auto_cancelOrder => 'Buyurtma bekor qilinsinmi?';

  @override
  String get auto_keepOrder => 'Buyurtmani saqlang';

  @override
  String get auto_orderCancelled => 'Buyurtma bekor qilindi';

  @override
  String get auto_pickupCode => 'Olib ketish kodi:';

  @override
  String get auto_closed => 'Yopiq';

  @override
  String get auto_menu => 'Menyu';

  @override
  String get auto_menuComingSoon => 'Menyu tez orada';

  @override
  String get auto_best => '🔥 Eng yaxshi';

  @override
  String get auto_popularDishes => '🍽️ Mashhur taomlar';

  @override
  String get auto_fromVideo => 'Videodan';

  @override
  String get auto_bookATable => 'Joy buyurtma qilish';

  @override
  String get auto_confirmReservation => 'Rezervasyonni tasdiqlang';

  @override
  String get auto_locationDirections => 'Joylashuv va yoʻnalishlar';

  @override
  String get auto_mapView => 'Xarita ko\'rinishi';

  @override
  String get auto_openInGoogleMaps => 'Google Xaritalarda oching';

  @override
  String get auto_writeAReview => 'Sharh yozing';

  @override
  String get auto_viewCart => 'Savatni ko\'rish';

  @override
  String get auto_signOut => 'Tizimdan chiqish?';

  @override
  String get auto_youWillNeedToSignInAgain =>
      'Qayta tizimga kirishingiz kerak bo\'ladi.';

  @override
  String get auto_deleteAccount => 'Akkauntni o\'chirish';

  @override
  String get auto_deleteForever => 'Abadiy o\'chirish';

  @override
  String get auto_accountDeletionRequestedContactSupportToFinalize =>
      'Hisobni oʻchirish soʻraldi. Tugatish uchun qo‘llab-quvvatlash xizmatiga murojaat qiling.';

  @override
  String get auto_plately => 'Plately';

  @override
  String
  get auto_platelyIsYourAipoweredKitchenEcosystemItAutomaticallyTracksYourIngredientsPredictsExpirationsGeneratesPersonalizedRecipesAndLetsYouOrderFromLocalRestaurants =>
      'Plately sizning sun\'iy intellekt asosida ishlaydigan oshxona ekotizimingizdir. U avtomatik ravishda ingredientlaringizni kuzatib boradi, amal qilish muddatini bashorat qiladi, moslashtirilgan retseptlar yaratadi va mahalliy restoranlardan buyurtma berish imkonini beradi.';

  @override
  String get auto_gotIt => 'Tushunarli';

  @override
  String get auto_editDisplayName => 'Taqdim etilgan ismni tahrirlash';

  @override
  String get auto_save => 'Saqlash';

  @override
  String get auto_addShoppingItem => 'Xarid qilish elementini qo\'shing';

  @override
  String get auto_add => 'Qo\'shish';

  @override
  String get auto_selectRecipeForMeal => 'Ovqatlanish uchun retseptni tanlang';

  @override
  String get auto_failedToLoadRecipes => 'Retseptlar yuklanmadi';

  @override
  String get auto_noRecipesFound => 'Hech qanday retsept topilmadi';

  @override
  String get auto_mealCleared => 'Ovqat tozalandi';

  @override
  String get auto_theme => '🎨 Mavzu';

  @override
  String get whatToCook => 'Nima pishiramiz?';

  @override
  String get tierPerfect => 'Mukammal';

  @override
  String get tierForYou => 'Siz uchun';

  @override
  String get tierUseItUp => 'Tezroq ishlating';

  @override
  String get tierAlmost => 'Deyarli';

  @override
  String get tierExplore => 'Kashf qilish';

  @override
  String noTierRecipesYet(String tier) {
    return 'Hozircha $tier retseptlari yo\'q';
  }

  @override
  String get addItemsForRecommendations =>
      'Tavsiyalar olish uchun javonga mahsulot qo\'shing';

  @override
  String get scanCaloriesTab => 'Kaloriyani skanerlash';

  @override
  String get scanYourIngredients => 'Ingredientlaringizni skanerlang';

  @override
  String get takePhotoToAdd =>
      'Javonga avtomatik qo\'shish uchun ovqat rasmini oling';

  @override
  String get scanReceipt => 'Chek';

  @override
  String get scanPhoto => 'Rasm';

  @override
  String get scanBarcode => 'Shtrix-kod';

  @override
  String get takePhotoBtn => 'Rasmga olish';

  @override
  String get adjustPortions => 'Porsiyalarni sozlash';

  @override
  String currentRecipeMakesNServings(String servings) {
    return 'Joriy retsept ';
  }

  @override
  String scaleToNServings(String newServings) {
    return '$newServings porsiyalarga o\'lchab ko\'ring';
  }

  @override
  String scaledToNServings(String newServings) {
    return '$newServings porsiyalarga oʻlchandi 🍳';
  }

  @override
  String findingSubstitutesForX(String ingredientName) {
    return '$ingredientName o‘rnini bosuvchilar qidirilmoqda...';
  }

  @override
  String get couldNotFindSubstitutes => 'O‘rinbosarlarni topib bo‘lmadi';

  @override
  String substitutesForX(String ingredientName) {
    return '“$ingredientName” o‘rniga';
  }

  @override
  String get noSubstitutesFoundForThisRecipeContext =>
      'Ushbu retsept konteksti uchun hech qanday o\'rinbosar topilmadi.';

  @override
  String nMatch(String match) {
    return '$match% moslik';
  }

  @override
  String ingredientsWithCount(String count) {
    return 'Mahsulotlar ($count)';
  }

  @override
  String get scale => 'Masshtab';

  @override
  String get addedMissingItemsToShoppingList =>
      'Yetishmayotgan mahsulotlar xarid ro\'yxatiga qo\'shildi!';

  @override
  String failedToAddItemsX(String e) {
    return 'Elementlarni qo‘shib bo‘lmadi: $e';
  }

  @override
  String get addMissingToShoppingList =>
      'Yetishmayotganlarni ro\'yxatga qo\'shish';

  @override
  String cookingStepsWithCount(String count) {
    return 'Pishirish qadamlari ($count)';
  }

  @override
  String get noStepsAvailableYet => 'Hali qadamlar mavjud emas';

  @override
  String get recordedTasteProfileEvolving =>
      'Yozib olindi! Didingiz profili rivojlanmoqda 🧠';

  @override
  String failedToRecordX(String e) {
    return 'Yozib bo‘lmadi: $e';
  }

  @override
  String get iCookedThis => 'Men buni pishirdim!';

  @override
  String get startCooking => 'Pishirishni boshlash';

  @override
  String get optional_tag => 'ixtiyoriy';

  @override
  String get servings_tag => 'porsiya';

  @override
  String get min_tag => 'daq';

  @override
  String get difficulty_tag => 'Qiyinchilik';

  @override
  String get expiringSoon => 'Tez orada tugaydi';

  @override
  String nItemsNeedAttention(String count) {
    return '$count element(lar)iga e\'tibor kerak';
  }

  @override
  String get takeAPhotoOfFoodItems =>
      'Oziq-ovqat mahsulotlarini qo\'shish uchun ularni suratga oling\njavoningizga avtomatik ravishda';

  @override
  String get addManually => 'Qo\'lda qo\'shish';

  @override
  String get recognitionFailed => 'Tanib bo‘lmadi. Qayta urinib ko\'ring.';

  @override
  String get analyzingYourFood => 'Oziq-ovqatingiz tahlil qilinmoqda...';

  @override
  String get aiIsIdentifying => 'AI ingredientlarni aniqlayapti';

  @override
  String nItemsDetected(String count) {
    return '$count elementlari aniqlandi';
  }

  @override
  String get photoAnalysisSelected => 'Fotosurat tahlili tanlandi';

  @override
  String nIngredientsDetected(String count) {
    return '$count ingrediyentlari aniqlandi';
  }

  @override
  String nOfNAdded(String added, String total) {
    return '$added / $total qo\'shildi';
  }

  @override
  String addedItem(String item) {
    return '$item qo\'shildi!';
  }

  @override
  String failedToAddItem(String item) {
    return '$item qo‘shib bo‘lmadi';
  }

  @override
  String addedNItemsToShelf(String count) {
    return '$count buyumlari javonga qo\'shildi!';
  }

  @override
  String noProductFoundForBarcode(String barcode) {
    return '$barcode shtrix-kodi uchun mahsulot topilmadi';
  }

  @override
  String addedItemToShelf(String item) {
    return '$item javonga qo\'shildi!';
  }

  @override
  String errorX(String e) {
    return 'Xato: $e';
  }

  @override
  String analysisFailedX(String e) {
    return 'Tahlil bajarilmadi: $e';
  }

  @override
  String failedToLogX(String e) {
    return 'Jurnalga kiritilmadi: $e';
  }

  @override
  String get scanBarcodeShort => 'Shtrix-kod';

  @override
  String get profileAccount => 'Hisob';

  @override
  String get deleteAccount => 'Hisobni o\'chirish';

  @override
  String get tierBadge1 => '✅ Hamma narsa bor!';

  @override
  String get tierBadge2 => '🔥 Siz uchun tavsiya';

  @override
  String get tierBadge3 => '⏰ Muddati tugayotganlarni ishlating';

  @override
  String get tierBadge4 => '🛒 Bir nechta mahsulot yetishmaydi';

  @override
  String get tierBadge5 => '🌍 Yangi narsa kashf eting';

  @override
  String needLabel(String items) {
    return 'Kerak: $items';
  }

  @override
  String nOfNIngredients(String matched, String total) {
    return '$matched/$total ingredient';
  }

  @override
  String get servingsLabel => 'Porsiya';

  @override
  String nHave(String count) {
    return '$count ta bor';
  }

  @override
  String nMissing(String count) {
    return '$count ta yetishmaydi';
  }

  @override
  String get ingredientsHeader => 'Ingredientlar';

  @override
  String get swapButton => 'Almashtirish →';

  @override
  String get aiAssistant => '🤖 AI yordamchi';

  @override
  String get aiHint =>
      'masalan: \"Menda go\'sht yo\'q, o\'rniga nimani ishlatsam bo\'ladi?\"';

  @override
  String get editIngredient => 'Ingredientni tahrirlash';

  @override
  String get nameLabel => 'Nomi';

  @override
  String get qtyLabel => 'Miqdor';

  @override
  String get unitLabel => 'Birlik';

  @override
  String get handsOn => 'Qo\'lda';

  @override
  String get automatic => 'Avtomatik';

  @override
  String get inv_quantity => 'Miqdor';

  @override
  String get inv_purchased => 'Sotib olingan';

  @override
  String get inv_expires => 'Muddati';

  @override
  String get inv_source => 'Manba';

  @override
  String get inv_storageLocation => 'Saqlash joyi';

  @override
  String get inv_itemState => 'Holati';

  @override
  String get inv_freshLabel => '🟢 Yangi';

  @override
  String get inv_agingLabel => '🟡 Eskirmoqda';

  @override
  String get inv_urgentLabel => '🟠 Shoshilinch';

  @override
  String get inv_criticalLabel => '🔴 Jiddiy';

  @override
  String get inv_expiredLabel => '⚫ Muddati tugagan';

  @override
  String inv_expiredDaysAgo(String days) {
    return '$days kun oldin tugagan';
  }

  @override
  String get inv_expiresToday => 'Bugun tugaydi!';

  @override
  String get inv_expiresTomorrow => 'Ertaga tugaydi';

  @override
  String inv_daysRemaining(String days) {
    return '$days kun qoldi';
  }

  @override
  String get inv_stateOpened => 'OCHILGAN';

  @override
  String get inv_stateFrozen => 'MUZLATILGAN';

  @override
  String get inv_stateThawed => 'ERITILGAN';

  @override
  String get inv_statePartial => 'QISMAN';

  @override
  String get inv_sortExpiry => 'Muddat ↑';

  @override
  String get inv_sortName => 'Nom A-Z';

  @override
  String get inv_sortCategory => 'Kategoriya';

  @override
  String get inv_sortNewest => 'Eng yangi';

  @override
  String inv_removeConfirm(String name) {
    return '\"$name\" inventardan o\'chirilsinmi?';
  }

  @override
  String get manual_addIngredient => 'Ingredient qo\'shish';

  @override
  String get manual_ingredientName => 'Ingredient nomi';

  @override
  String get manual_ingredientHint => 'masalan: Olma, Non, Sut';

  @override
  String get manual_category => 'Kategoriya';

  @override
  String get manual_qty => 'Miqdor';

  @override
  String get manual_metricType => 'O\'lchov turi';

  @override
  String get manual_estimatedExpiry => 'Taxminiy muddat';

  @override
  String get manual_required => 'Majburiy';

  @override
  String get auth_tagline => 'Isrofgarchilik yo\'q, ta\'m eng zo\'r.';

  @override
  String get auth_subtitle => 'Oshxonangiz — aqlli boshqaruv.';

  @override
  String get auth_email => 'Email';

  @override
  String get auth_password => 'Parol';

  @override
  String get auth_continue => 'Davom etish';

  @override
  String get auth_or => 'YOKI';

  @override
  String get auth_continueGoogle => 'Google orqali davom etish';

  @override
  String get auth_continueGuest => 'Mehmon sifatida davom etish';

  @override
  String get auth_autoDetectHint =>
      'Yangi foydalanuvchimisiz? Hisobingiz avtomatik yaratiladi.';

  @override
  String get auth_checkEmail =>
      'Hisobingizni tasdiqlash uchun emailingizni tekshiring.';

  @override
  String get auth_enterBoth => 'Email va parolni kiriting.';

  @override
  String get auth_unexpectedError =>
      'Kutilmagan xatolik yuz berdi. Qayta urinib ko\'ring.';

  @override
  String get auth_googleFailed =>
      'Google orqali kirish amalga oshmadi. Qayta urinib ko\'ring.';

  @override
  String get auth_guestFailed =>
      'Mehmon sifatida kirish amalga oshmadi. Email yoki Google orqali urinib ko\'ring.';

  @override
  String get auth_resetSent =>
      'Parolni tiklash havolasi emailingizga yuborildi. Pochtangizni tekshiring.';

  @override
  String get auth_forgotPassword => 'Parolni unutdingizmi?';

  @override
  String get import_recipe => 'Retsept import qilish';

  @override
  String get import_pasteRaw => 'Retsept matnini joylashtiring';

  @override
  String get import_description =>
      'Veb-sayt, kitob yoki eslatmalar ilovasidan ko\'chirib joylashtiring. Sun\'iy intellektimiz uni bosqichma-bosqich aqlli retseptga aylantiradi.';

  @override
  String get import_hint =>
      'Masalan: Buvining pechene\'si\n2 stakan un va 1 stakan shakarni aralashtiring... 180° da 10 daqiqa pishiring.';

  @override
  String get import_analyzing => 'Retsept tahlil qilinmoqda...';

  @override
  String get import_parseWithAi => 'AI bilan tahlil qilish';

  @override
  String get import_parsedRecipe => 'Tahlil qilingan retsept';

  @override
  String get import_steps => 'Bosqichlar';

  @override
  String get import_saveButton => 'Ajoyib — Retseptlarimga saqlash';

  @override
  String get import_savedLocally => 'Retsept Retseptlarimga saqlandi!';

  @override
  String get tutorial_next => 'Keyingisi →';

  @override
  String get tutorial_gotIt => 'Tushunarli! 🎉';

  @override
  String get tutorial_cookTitle => 'Retseptlaringiz';

  @override
  String get tutorial_cookDesc =>
      'Muzlatgichda bor narsalarga asoslangan AI tomonidan tanlangan retseptlarni ko\'ring. Mos kelish foizi qancha yuqori bo\'lsa, shuncha ko\'p ingredientlar sizda bor!';

  @override
  String get tutorial_scanTitle => 'Ingredientlarni skanerlash';

  @override
  String get tutorial_scanDesc =>
      'Kamerangiz bilan cheklarni, shtrix-kodlarni skanerlang yoki ingredientlar suratini oling. AI ularni bir zumda aniqlaydi.';

  @override
  String get tutorial_shelfTitle => 'Sizning tokchangiz';

  @override
  String get tutorial_shelfDesc =>
      'Raqamli muzlatgich, freezer va omborxona. Yaroqlilik muddatlarini va miqdorlarni kuzatib boring — oziq-ovqat buzilishidan oldin xabardor qilamiz.';

  @override
  String get tutorial_profileTitle => 'Profil va sozlamalar';

  @override
  String get tutorial_profileDesc =>
      'Profil ikonkasiga bosib tilni, mavzuni o\'zgartiring, ta\'m profilingizni boshqaring va pishirish seriyalarini kuzating!';

  @override
  String get tutorial_replay => 'O\'quv qo\'llanmani qayta ko\'rish';

  @override
  String get tutorial_replayConfirm =>
      'Keyingi ishga tushirishda o\'quv qo\'llanma ko\'rsatiladi.';

  @override
  String get auth_enterEmail =>
      'Iltimos, avval elektron pochta manzilingizni kiriting.';

  @override
  String get tutorial_tourTitle => 'Plately Interaktiv Qo\'llanmasi';

  @override
  String get tutorial_tourDesc =>
      'Xush kelibsiz! Keling, Plately bo\'ylab 1 daqiqalik qisqacha sayohat qilamiz. Biz sizga ingredientlarni qanday boshqarishni, mos retseptlarni topishni va pishirishni qanday boshlashni ko\'rsatamiz!';

  @override
  String get tutorial_startTour => 'Boshlash 🚀';

  @override
  String get tutorial_skipTour => 'O\'tkazib yuborish';

  @override
  String get tutorial_shelfIntroTitle => 'Sizning Raqamli Javoningiz';

  @override
  String get tutorial_shelfIntroDesc =>
      'Bu sizning raqamli muzlatgich va omborxonangiz. Bu yerda siz miqdorlarni va yaroqlilik muddatlarini kuzatishingiz mumkin — ovqat buzilishidan oldin sizni ogohlantiramiz. Keling, bu qanday ishlashini ko\'ramiz!';

  @override
  String get tutorial_nextArrow => 'Keyingi →';

  @override
  String get tutorial_addIntroTitle => 'Ingredientlarni Qo\'shish';

  @override
  String get tutorial_addIntroDesc =>
      'Ingredientlarni qo\'shish uchun pastki menyudagi Skanerlash (kamera belgisi) tugmasini bosing. Qani, bosing!';

  @override
  String get tutorial_bypassScan => 'O\'tish (Skanerlashga borish)';

  @override
  String get tutorial_scanIntroTitle => 'Skanerlash va Qo\'lda Qo\'shish';

  @override
  String get tutorial_scanIntroDesc =>
      'Bu yerda siz cheklarni, shtrix-kodlarni skanerlashingiz yoki ingredientlar suratini olishingiz mumkin. Ushbu qo\'llanma uchun biz tovuq qovurish retsepti uchun kerakli 5 ta qalbaki ingredientni avtomatik yuklaymiz.';

  @override
  String get tutorial_loadMock => 'Qalbaki Ingredientlarni Yuklash 🛒';

  @override
  String get tutorial_shelfAddedTitle => 'Ingredientlar Yuklandi!';

  @override
  String get tutorial_shelfAddedDesc =>
      'Ajoyib! Biz bularni yukladik: Tovuq Go\'shti, Brokkoli, Soya Sousi, Sarimsoq va Kunjut Yog\'i. Keling, nima pishirish mumkinligini ko\'ramiz! Mos retseptlarni topish uchun Pishirish tugmasini (chapdagi restoran belgisi) bosing.';

  @override
  String get tutorial_bypassCook => 'O\'tish (Pishirishga borish)';

  @override
  String get tutorial_roamCookTitle => '5 Darajali Tavsiyalar';

  @override
  String get tutorial_roamCookDesc =>
      'Bu yerda siz 5 xil tavsiya sahifalarini ko\'rasiz (Mukammal, Siz uchun, Ishlatib yuborish, Qisman, Kashf qilish). Ularni o\'rganish uchun bosib ko\'ring! Tayyor bo\'lganingizda, Mukammal bo\'limidagi \"Qovurilgan Tovuq\" retsepti kartasini bosing.';

  @override
  String get tutorial_recipeDetailTitle => 'Retsept Tafsilotlari';

  @override
  String get tutorial_recipeDetailDesc =>
      'Bu yerda siz ingredientlar ro\'yxatini va qadamlarni ko\'rasiz. Boshlash uchun sahifa pastidagi \"Pishirishni Boshlash\" tugmasini bosing!';

  @override
  String get tutorial_cookingPrepTitle => 'Tayyorgarlik va Ingredientlar';

  @override
  String get tutorial_cookingPrepDesc =>
      'Olovni yoqishdan oldin, ingredientlarni yuving va to\'g\'rang. Pishirish yordamchisini ishga tushirish uchun \"Qadam-ba-qadam Boshlash\" tugmasini bosing!';

  @override
  String get tutorial_cookingRunTitle => 'Pishirish Yordamchisi';

  @override
  String get tutorial_cookingRunDesc =>
      'Yordamchi sizni qadam-ba-qadam boshqaradi. Siz shuningdek, o\'zgartirishlar yoki pishirish haqidagi savollar uchun pastdagi AI yordamchisi bilan gaplashishingiz mumkin! Retsept qadamlarini bajaring va oxirgi qadamda \"Tugatish\" ni bosing.';

  @override
  String get tutorial_finishTitle => 'Qo\'llanma Yakunlandi!';

  @override
  String get tutorial_finishDesc =>
      'Tabriklaymiz! Siz Plately pishirish qo\'llanmasini yakunladingiz.\n\nEslatma: Ushbu qo\'llanmada ishlatilgan barcha ingredientlar va ma\'lumotlar saqlanmaydi. Bu ilovaning kichik bir qismi xolos. O\'z pishirish sayohatingizni boshlash uchun \"Qo\'llanmani Tugatish\" ni bosing!';

  @override
  String get tutorial_finishTour => 'Qo\'llanmani Tugatish 🏁';

  @override
  String get tutorial_recipeTitle => 'Qovurilgan Tovuq (Qo\'llanma)';

  @override
  String get tutorial_ing_chicken => 'Tovuq Go\'shti';

  @override
  String get tutorial_ing_broccoli => 'Brokkoli';

  @override
  String get tutorial_ing_soy_sauce => 'Soya Sousi';

  @override
  String get tutorial_ing_garlic => 'Sarimsoq';

  @override
  String get tutorial_ing_sesame_oil => 'Kunjut Yog\'i';

  @override
  String get tutorial_step1 =>
      'Tovuq go\'shtini kichik bo\'laklarga va brokkolini kichik qismlarga bo\'ling. Sarimsoqni maydalang.';

  @override
  String get tutorial_step1_beg =>
      'Tovuq go\'shtini ehtiyotkorlik bilan kichik bo\'laklarga kesing. Brokkolini ham kichik qismlarga ajrating. Sarimsoqni tozalang va maydalang.';

  @override
  String get tutorial_step2 =>
      'Katta tovada o\'rta olovda kunjut yog\'ini qizdiring. Maydalangan sarimsoq qo\'shing va 1 daqiqa qovuring.';

  @override
  String get tutorial_step2_beg =>
      'Tovaga kunjut yog\'ini quying. Olovni o\'rta darajaga qo\'ying. Sarimsoq qo\'shing va kuymasligi uchun 1 daqiqa davomida to\'xtovsiz aralashtiring.';

  @override
  String get tutorial_step3 =>
      'Tovaga tovuq bo\'laklarini qo\'shing. 5-6 daqiqa davomida qovuring.';

  @override
  String get tutorial_step3_beg =>
      'Tovuq go\'shtini ehtiyotkorlik bilan tovaga qo\'shing. Tovuq ichida pushti rang qolmaguncha 5-6 daqiqa davomida aralashtirib pishiring.';

  @override
  String get tutorial_step4 =>
      'Brokkoli va soya sousini qo\'shing. Yana 3-4 daqiqa qovuring.';

  @override
  String get tutorial_step4_beg =>
      'Brokkoli qo\'shing va soya sousini quying. Brokkoli biroz yumshaguncha, lekin hali ham yashil rangda qolgunicha hamma narsani 3-4 daqiqa pishiring.';

  @override
  String get tutorial_step5 =>
      'Olovdan oling. Mazali tovuqni guruch bilan yoki o\'zini idishga solib dasturxonga torting!';

  @override
  String get tutorial_step5_beg =>
      'Olovni o\'chiring. Qovurilgan taomni idishga soling. Yangi pishgan taomingizdan rohatlaning!';

  @override
  String get reward_mealCompleted => 'Ovqat Tayyor!';

  @override
  String reward_youCooked(String recipeTitle, String servings) {
    return 'Siz \"$recipeTitle\" tayyorladingiz · $servings porsiya';
  }

  @override
  String get reward_xpEarned => 'Ishlangan XP';

  @override
  String get reward_itemsUsed => 'Ishlatilgan Masalliqlar';

  @override
  String get reward_deducted => 'Javondan olingan';

  @override
  String get reward_backToShelf => 'Javonga qaytish';
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl() : super('uz_Cyrl');

  @override
  String get appTitle => 'Plately';

  @override
  String get tabShelf => 'Жавон';

  @override
  String get tabCook => 'Пишириш';

  @override
  String get tabScan => 'Сканерлаш';

  @override
  String get tabProfile => 'Профил';

  @override
  String get profileTitle => 'Профил';

  @override
  String profileGamificationLevel(int level) {
    return '$level-даража';
  }

  @override
  String get profileMealsCooked => 'Пиширилган таомлар';

  @override
  String get profileItemsSaved => 'Сақланган маҳсулотлар';

  @override
  String get profileDayStreak => 'Кунлик серийа';

  @override
  String get profileFlavorProfile => 'Та\'м профили';

  @override
  String get profileBadges => 'Нишонлар ва йутуқлар';

  @override
  String get profileShoppingList => 'Харид рўйхати';

  @override
  String get profileMealPlanner => 'Овқатланиш режаси';

  @override
  String get actionAdd => 'Қўшиш';

  @override
  String get actionCancel => 'Бекор қилиш';

  @override
  String get actionSave => 'Сақлаш';

  @override
  String get actionDelete => 'Ўчириш';

  @override
  String get profileLoadError => 'Профилни йуклаб бўлмади';

  @override
  String get retry => 'Қайта уриниш';

  @override
  String get refresh => 'Йангилаш';

  @override
  String get signOut => 'Чиқиш';

  @override
  String get profileLevelProgress => 'Даража жарайони';

  @override
  String profileLevel(int level) {
    return '$level-даража';
  }

  @override
  String get profileYourImpact => 'Сизнинг та\'сирингиз';

  @override
  String get addShoppingItem => 'Елемент қўшиш';

  @override
  String get shoppingListEmpty => 'Харидлар рўйхати бўш';

  @override
  String get mealPlannerEmpty => 'Режалаштирилган таомлар йўқ';

  @override
  String get planToday => 'Бугунги режа';

  @override
  String get today => 'Бугун';

  @override
  String get planMeal => 'Таом режалаштириш...';

  @override
  String get tabExplore => 'Кашфийот';

  @override
  String get scanFood => 'Овқатни сканерлаш';

  @override
  String get scanCalories => 'Калорийа сканерлаш';

  @override
  String get takePhoto => 'Суратга олиш';

  @override
  String get chooseFromGallery => 'Галерейадан танланг';

  @override
  String get analyzeCalories => 'Калорийаларни таҳлил қилиш';

  @override
  String get caloriesPerServing => 'кал/порсийа';

  @override
  String get totalCalories => 'жами кал';

  @override
  String get creatorProfile => 'Муаллиф профили';

  @override
  String get follow => 'Кузатиш';

  @override
  String get following => 'Кузатилмоқда';

  @override
  String get nutritionTracker => 'Овқатланиш кузатуви';

  @override
  String get reels => 'Риллар';

  @override
  String get community => 'Жамоа';

  @override
  String get hasRecipe => 'Ретсепт бор';

  @override
  String get noReelsYet => 'Ҳозирча риллар йўқ';

  @override
  String get settings => 'Созламалар';

  @override
  String get settingsLanguage => 'Тил';

  @override
  String get settingsTheme => 'Мавзу';

  @override
  String get aboutApp => 'иФридге ҳақида';

  @override
  String get myFridge => '🧊 Менинг музлатгичим';

  @override
  String get expiryAlerts => 'Муддати тугаши ҳақида огоҳлантиришлар';

  @override
  String get errorLoadInventory => 'Инвентарни йуклаб бўлмади';

  @override
  String get errorCheckConnection =>
      'Уланишингизни текширинг ва қайтадан урининг.';

  @override
  String get total => 'Жами';

  @override
  String get fresh => 'Йанги';

  @override
  String get expiring => 'Муддати тугайапти';

  @override
  String get expired => 'Муддати тугаган';

  @override
  String get searchIngredients => 'Ингредиентларни қидириш...';

  @override
  String get all => 'Ҳаммаси';

  @override
  String itemsCount(int count) {
    return '$count елементлари';
  }

  @override
  String zoneEmptyTitle(String zone) {
    return 'Сизнинг $zone бўш';
  }

  @override
  String get zoneEmptyDesc =>
      'Рақамли ошхонангизни тўлдиришга таййор.\nЕлементларни қўлда қўшинг йоки сканерлаш тугмасини босинг.';

  @override
  String get addIngredient => 'Ингредиент қўшинг';

  @override
  String get urgentCook => 'Ҳозир пиширинг';

  @override
  String urgentUse(String ingredient) {
    return '$ingredient дан фойдаланинг';
  }

  @override
  String get noItemsMatch => 'Ҳеч қандай елемент филтрингизга мос келмайди';

  @override
  String get clearFilters => 'Филтрларни тозалаш';

  @override
  String get expiryAlertsTitle => '🔔 Муддати тугаши ҳақида огоҳлантиришлар';

  @override
  String get allFresh => 'Барча маҳсулотлар йанги! 🎉';

  @override
  String expiredCount(int count) {
    return '❌ Муддати тугаган ($count)';
  }

  @override
  String expiringSoonCount(int count) {
    return '⚠️ Тез орада тугайди ($count)';
  }

  @override
  String get auto_scanCaloriesIsComingSoon =>
      'Калорийаларни сканерлаш тез орада!';

  @override
  String get auto_scan => 'Сканерлаш';

  @override
  String get auto_addAll => 'Ҳаммасини қўшиш';

  @override
  String get auto_allAdded => 'Ҳаммаси қўшилди';

  @override
  String get auto_scanAnother => 'Бошқасини сканерлаш';

  @override
  String get auto_startVisualAudit => 'Визуал аудитни бошланг';

  @override
  String get auto_enterBarcode => 'Штрих кодини киритинг';

  @override
  String get auto_cancel => 'Бекор қилиш';

  @override
  String get auto_lookUp => 'Ахтариш, излаш';

  @override
  String get auto_fridge => 'Музлатгич';

  @override
  String get auto_freezer => 'Музлатиш камераси';

  @override
  String get auto_pantry => 'Омборхона';

  @override
  String get auto_addToShelf => 'Рафга қўшиш';

  @override
  String get auto_mealLogged => '✅ Овқат қайд етилди!';

  @override
  String get auto_snapYourMeal => 'Овқатланишни йенг';

  @override
  String get auto_takeAPhotoAndAiWillEstimateCalories =>
      'Суратга олинг ва АИ калорийаларни ҳисоблаб чиқади';

  @override
  String get auto_analyzingFood => 'Озиқ-овқатларни таҳлил қилиш...';

  @override
  String get auto_camera => 'Камера';

  @override
  String get auto_gallery => 'Галерейа';

  @override
  String get auto_estimatedCalories => 'тахмин қилинган калорийалар';

  @override
  String get auto_cal => 'кал';

  @override
  String get auto_logMeal => 'Кундалик овқат';

  @override
  String get auto_addSomeIngredientsToYourShelfFirst =>
      'Аввал жавонингизга ингредиентларни қўшинг!';

  @override
  String get auto_aiRecipeGenerator => 'АИ ретсепти генератори';

  @override
  String get auto_any => 'Ҳар қандай';

  @override
  String get auto_shelfOnly => 'Фақат жавон';

  @override
  String get auto_generateRecipe => 'Ретсепт йаратиш';

  @override
  String get auto_ingredients => '🧂 Таркиби';

  @override
  String get auto_steps => '👨‍🍳 Қадамлар';

  @override
  String get auto_importRecipe => 'Импорт ретсепти';

  @override
  String get auto_retry => 'Қайта уриниш';

  @override
  String get auto_addItemsToYourShelfToGetRecommendations =>
      'Тавсийаларни олиш учун жавонингизга нарсаларни қўшинг';

  @override
  String get auto_noRecipesMatchThisCuisine =>
      'Ҳеч қандай ретсепт бу ошхонага мос келмайди';

  @override
  String get auto_clearFilter => 'Филтрни тозалаш';

  @override
  String get auto_deleteItem => 'Елемент ўчирилсинми?';

  @override
  String get auto_delete => 'Ўчириш';

  @override
  String get auto_freshness => 'Йангилик';

  @override
  String get auto_use1Unit => '1 бирликдан фойдаланинг';

  @override
  String get auto_removeFromInventory => 'Инвентаризатсийадан олиб ташланг';

  @override
  String get auto_following => 'Кузатиш';

  @override
  String get auto_follow => 'Кузатиш';

  @override
  String get auto_posts => 'Хабарлар';

  @override
  String get auto_noPostsYet => 'Ҳозирча постлар йўқ';

  @override
  String get auto_explore => 'Тадқиқ қилинг';

  @override
  String get auto_noReelsYet => 'Ҳали макаралар йўқ';

  @override
  String get auto_cookThisRecipe => 'Ушбу ретсептни пиширинг';

  @override
  String get auto_recipeNotFound => 'Ретсепт топилмади';

  @override
  String get auto_hasRecipe => 'Ретсепти бор';

  @override
  String get auto_noCommunityPostsYet => 'Ҳозирча ҳамжамийат постлари йўқ';

  @override
  String get auto_beTheFirstToShare => 'Биринчи бўлиб баҳам кўринг!';

  @override
  String get auto_createPost => 'Пост йаратиш';

  @override
  String get auto_savedPosts => 'Сақланган хабарлар';

  @override
  String get auto_noSavedPostsYet => 'Ҳали ҳеч қандай пост сақланган емас';

  @override
  String get auto_you => 'Сиз';

  @override
  String get auto_checkout => 'Рўйхатдан ўчирилиш';

  @override
  String get auto_yourCartIsEmpty => 'Саватингиз бўш';

  @override
  String get auto_yourOrder => 'Сизнинг буйуртмангиз';

  @override
  String get auto_total => 'жами';

  @override
  String get auto_orderConfirmed => 'Буйуртма тасдиқланди!';

  @override
  String get auto_yourPickupCode => 'Қабул қилиш кодингиз';

  @override
  String get auto_showThisCodeAtTheCounter => 'Ушбу кодни пештахтада кўрсатинг';

  @override
  String get auto_deliveryOnTheWay => 'Йўлда йетказиб бериш';

  @override
  String get auto_aDriverWillBeAssignedShortly =>
      'Тез орада ҳайдовчи тайинланади';

  @override
  String get auto_backToHome => 'Уйга қайтиш';

  @override
  String get auto_incomingOrders => 'Кирувчи Буйуртмалар';

  @override
  String get auto_noFoodVideosYet => 'Ҳозирча овқат ҳақида видео йўқ';

  @override
  String get auto_foodFeed => 'Озиқ-овқат';

  @override
  String get auto_myOrders => 'Менинг Буйуртмаларим';

  @override
  String get auto_noOrdersYet => 'Ҳозирча буйуртмалар йўқ';

  @override
  String get auto_yourOrderHistoryWillAppearHere =>
      'Буйуртмаларингиз тарихи шу йерда пайдо бўлади';

  @override
  String get auto_cancelOrder => 'Буйуртма бекор қилинсинми?';

  @override
  String get auto_keepOrder => 'Буйуртмани сақланг';

  @override
  String get auto_orderCancelled => 'Буйуртма бекор қилинди';

  @override
  String get auto_pickupCode => 'Олиб кетиш коди:';

  @override
  String get auto_closed => 'Йопиқ';

  @override
  String get auto_menu => 'Менйу';

  @override
  String get auto_menuComingSoon => 'Менйу тез орада';

  @override
  String get auto_best => '🔥 Енг йахши';

  @override
  String get auto_popularDishes => '🍽️ Машҳур таомлар';

  @override
  String get auto_fromVideo => 'Видеодан';

  @override
  String get auto_bookATable => 'Жадвални брон қилиш';

  @override
  String get auto_confirmReservation => 'Резервасйонни тасдиқланг';

  @override
  String get auto_locationDirections => 'Жойлашув ва йўналишлар';

  @override
  String get auto_mapView => 'Харита кўриниши';

  @override
  String get auto_openInGoogleMaps => 'Гоогле Хариталарда очинг';

  @override
  String get auto_writeAReview => 'Шарҳ йозинг';

  @override
  String get auto_viewCart => 'Саватни кўриш';

  @override
  String get auto_signOut => 'Тизимдан чиқиш?';

  @override
  String get auto_youWillNeedToSignInAgain =>
      'Сиз йана тизимга киришингиз керак бўлади.';

  @override
  String get auto_deleteAccount => 'Аккаунтни ўчириш';

  @override
  String get auto_deleteForever => 'Абадий ўчириш';

  @override
  String get auto_accountDeletionRequestedContactSupportToFinalize =>
      'Ҳисобни ўчириш сўралди. Тугатиш учун қўллаб-қувватлаш хизматига мурожаат қилинг.';

  @override
  String get auto_plately => 'иФридге';

  @override
  String
  get auto_platelyIsYourAipoweredKitchenEcosystemItAutomaticallyTracksYourIngredientsPredictsExpirationsGeneratesPersonalizedRecipesAndLetsYouOrderFromLocalRestaurants =>
      'иФридге сизнинг сунъий интеллект асосида ишлайдиган ошхона екотизимидир. У автоматик равишда ингредиентларингизни кузатиб боради, амал қилиш муддатини башорат қилади, мослаштирилган ретсептлар йаратади ва маҳаллий ресторанлардан буйуртма бериш имконини беради.';

  @override
  String get auto_gotIt => 'Тушундим';

  @override
  String get auto_editDisplayName => 'Дисплей номини таҳрирлаш';

  @override
  String get auto_save => 'Сақлаш';

  @override
  String get auto_addShoppingItem => 'Харид қилиш елементини қўшинг';

  @override
  String get auto_add => 'Қўшиш';

  @override
  String get auto_selectRecipeForMeal => 'Овқатланиш учун ретсептни танланг';

  @override
  String get auto_failedToLoadRecipes => 'Ретсептлар йукланмади';

  @override
  String get auto_noRecipesFound => 'Ҳеч қандай ретсепт топилмади';

  @override
  String get auto_mealCleared => 'Овқат тозаланди';

  @override
  String get auto_theme => '🎨 Мавзу';

  @override
  String get whatToCook => 'Нима пиширамиз?';

  @override
  String get tierPerfect => 'Мукаммал';

  @override
  String get tierForYou => 'Сиз учун';

  @override
  String get tierUseItUp => 'Тезроқ ишлатинг';

  @override
  String get tierAlmost => 'Дейарли';

  @override
  String get tierExplore => 'Кашф қилиш';

  @override
  String noTierRecipesYet(String tier) {
    return 'Ҳозирча $tier ретсептлари йўқ';
  }

  @override
  String get addItemsForRecommendations =>
      'Тавсийалар олиш учун жавонга маҳсулот қўшинг';

  @override
  String get scanCaloriesTab => 'Калорийани сканерлаш';

  @override
  String get scanYourIngredients => 'Ингредиентларингизни сканерланг';

  @override
  String get takePhotoToAdd =>
      'Жавонга автоматик қўшиш учун овқат расмини олинг';

  @override
  String get scanReceipt => 'Чек';

  @override
  String get scanPhoto => 'Расм';

  @override
  String get scanBarcode => 'Штрих-кодни сканерлаш';

  @override
  String get takePhotoBtn => 'Расмга олиш';

  @override
  String get adjustPortions => 'Порсийаларни созлаш';

  @override
  String currentRecipeMakesNServings(String servings) {
    return 'Жорий ретсепт $servings порсийа қилади.';
  }

  @override
  String scaleToNServings(String newServings) {
    return '$newServings порсийаларига ўлчаб кўринг';
  }

  @override
  String scaledToNServings(String newServings) {
    return '$newServings порсийаларига ўлчанди 🍳';
  }

  @override
  String findingSubstitutesForX(String ingredientName) {
    return '$ingredientName ўрнини босувчилар қидирилмоқда...';
  }

  @override
  String get couldNotFindSubstitutes => 'Ўринбосарларни топиб бўлмади';

  @override
  String substitutesForX(String ingredientName) {
    return '\"$ingredientName\" ўрнига';
  }

  @override
  String get noSubstitutesFoundForThisRecipeContext =>
      'Ушбу ретсепт контексти учун ҳеч қандай ўринбосар топилмади.';

  @override
  String nMatch(String match) {
    return '$match% мослик';
  }

  @override
  String ingredientsWithCount(String count) {
    return 'Ингредиентлар ($count)';
  }

  @override
  String get scale => 'Масштаб';

  @override
  String get addedMissingItemsToShoppingList =>
      'Харид қилиш рўйхатига етишмайотган нарсалар қўшилди!';

  @override
  String failedToAddItemsX(String e) {
    return 'Елементларни қўшиб бўлмади: $e';
  }

  @override
  String get addMissingToShoppingList =>
      'Харид қилиш рўйхатига етишмайотган нарсаларни қўшинг';

  @override
  String cookingStepsWithCount(String count) {
    return 'Пишириш босқичлари ($count)';
  }

  @override
  String get noStepsAvailableYet => 'Ҳали қадамлар мавжуд емас';

  @override
  String get recordedTasteProfileEvolving =>
      'Йозиб олинган! Сизнинг дидингиз профили ривожланмоқда 🧠';

  @override
  String failedToRecordX(String e) {
    return 'Йозиб бўлмади: $e';
  }

  @override
  String get iCookedThis => 'Мен буни пиширдим!';

  @override
  String get startCooking => 'Овқат пиширишни бошланг';

  @override
  String get optional_tag => 'ихтийорий';

  @override
  String get servings_tag => 'порсийа';

  @override
  String get min_tag => 'мин';

  @override
  String get difficulty_tag => 'Қийинчилик';

  @override
  String get expiringSoon => 'Тез орада тугайди';

  @override
  String nItemsNeedAttention(String count) {
    return '$count елемент(лар)ига еътибор керак';
  }

  @override
  String get takeAPhotoOfFoodItems =>
      'Озиқ-овқат маҳсулотларини қўшиш учун уларни суратга олинг\nжавонингизга автоматик равишда';

  @override
  String get addManually => 'Қўлда қўшиш';

  @override
  String get recognitionFailed => 'Таниб бўлмади. Қайта уриниб кўринг.';

  @override
  String get analyzingYourFood => 'Озиқ-овқатингиз таҳлил қилинмоқда...';

  @override
  String get aiIsIdentifying => 'АИ ингредиентларни аниқлайди';

  @override
  String nItemsDetected(String count) {
    return '$count елементлари аниқланди';
  }

  @override
  String get photoAnalysisSelected => 'Фотосурат таҳлили танланди';

  @override
  String nIngredientsDetected(String count) {
    return '$count ингредийентлари аниқланди';
  }

  @override
  String nOfNAdded(String added, String total) {
    return '$added / $total қўшилди';
  }

  @override
  String addedItem(String item) {
    return '$item қўшилди!';
  }

  @override
  String failedToAddItem(String item) {
    return '$item қўшиб бўлмади';
  }

  @override
  String addedNItemsToShelf(String count) {
    return '$count буйумлари жавонга қўшилди!';
  }

  @override
  String noProductFoundForBarcode(String barcode) {
    return '$barcode штрих-коди учун маҳсулот топилмади';
  }

  @override
  String addedItemToShelf(String item) {
    return '$item жавонга қўшилди!';
  }

  @override
  String errorX(String e) {
    return 'Хато: $e';
  }

  @override
  String analysisFailedX(String e) {
    return 'Таҳлил бажарилмади: $e';
  }

  @override
  String failedToLogX(String e) {
    return 'Журналга киритилмади: $e';
  }

  @override
  String get scanBarcodeShort => 'Штрих-код';

  @override
  String get profileAccount => 'Ҳисоб';

  @override
  String get deleteAccount => 'Ҳисобни ўчириш';

  @override
  String get tierBadge1 => '✅ Ҳамма нарса бор!';

  @override
  String get tierBadge2 => '🔥 Сиз учун тавсийа';

  @override
  String get tierBadge3 => '⏰ Муддати тугайотганларни ишлатинг';

  @override
  String get tierBadge4 => '🛒 Бир нечта маҳсулот йетишмайди';

  @override
  String get tierBadge5 => '🌍 Йанги нарса кашф етинг';

  @override
  String needLabel(String items) {
    return 'Керак: $items';
  }

  @override
  String nOfNIngredients(String matched, String total) {
    return '$matched/$total ингредиент';
  }

  @override
  String get servingsLabel => 'Порсийа';

  @override
  String nHave(String count) {
    return '$count та бор';
  }

  @override
  String nMissing(String count) {
    return '$count та йетишмайди';
  }

  @override
  String get ingredientsHeader => 'Ингредиентлар';

  @override
  String get swapButton => 'Алмаштириш →';

  @override
  String get aiAssistant => '🤖 АИ йордамчи';

  @override
  String get aiHint =>
      'масалан: \"Менда гўшт йўқ, ўрнига нимани ишлатсам бўлади?\"';

  @override
  String get editIngredient => 'Ингредиентни таҳрирлаш';

  @override
  String get nameLabel => 'Номи';

  @override
  String get qtyLabel => 'Миқдор';

  @override
  String get unitLabel => 'Бирлик';

  @override
  String get handsOn => 'Қўлда';

  @override
  String get automatic => 'Автоматик';

  @override
  String get inv_quantity => 'Миқдор';

  @override
  String get inv_purchased => 'Сотиб олинган';

  @override
  String get inv_expires => 'Муддати';

  @override
  String get inv_source => 'Манба';

  @override
  String get inv_storageLocation => 'Сақлаш жойи';

  @override
  String get inv_itemState => 'Ҳолати';

  @override
  String get inv_freshLabel => '🟢 Йанги';

  @override
  String get inv_agingLabel => '🟡 Ескирмоқда';

  @override
  String get inv_urgentLabel => '🟠 Шошилинч';

  @override
  String get inv_criticalLabel => '🔴 Жиддий';

  @override
  String get inv_expiredLabel => '⚫ Муддати тугаган';

  @override
  String inv_expiredDaysAgo(String days) {
    return '$days кун олдин тугаган';
  }

  @override
  String get inv_expiresToday => 'Бугун тугайди!';

  @override
  String get inv_expiresTomorrow => 'Ертага тугайди';

  @override
  String inv_daysRemaining(String days) {
    return '$days кун қолди';
  }

  @override
  String get inv_stateOpened => 'ОЧИЛГАН';

  @override
  String get inv_stateFrozen => 'МУЗЛАТИЛГАН';

  @override
  String get inv_stateThawed => 'ЕРИТИЛГАН';

  @override
  String get inv_statePartial => 'ҚИСМАН';

  @override
  String get inv_sortExpiry => 'Муддат ↑';

  @override
  String get inv_sortName => 'Ном А-Я';

  @override
  String get inv_sortCategory => 'Категория';

  @override
  String get inv_sortNewest => 'Енг янги';

  @override
  String inv_removeConfirm(String name) {
    return '\"$name\" инвентардан ўчирилсинми?';
  }

  @override
  String get manual_addIngredient => 'Ингредиент қўшиш';

  @override
  String get manual_ingredientName => 'Ингредиент номи';

  @override
  String get manual_ingredientHint => 'масалан: Олма, Нон, Сут';

  @override
  String get manual_category => 'Категория';

  @override
  String get manual_qty => 'Миқдор';

  @override
  String get manual_metricType => 'Ўлчов тури';

  @override
  String get manual_estimatedExpiry => 'Тахминий муддат';

  @override
  String get manual_required => 'Мажбурий';

  @override
  String get auth_tagline => 'Исрофгарчилик йўқ, та\'м энг зўр.';

  @override
  String get auth_subtitle => 'Ошхонангиз — ақлли бошқарув.';

  @override
  String get auth_email => 'Электрон почта';

  @override
  String get auth_password => 'Парол';

  @override
  String get auth_continue => 'Давом этиш';

  @override
  String get auth_or => 'ЙОКИ';

  @override
  String get auth_continueGoogle => 'Google орқали давом этиш';

  @override
  String get auth_continueGuest => 'Меҳмон сифатида давом этиш';

  @override
  String get auth_autoDetectHint =>
      'Йанги фойдаланувчимисиз? Ҳисобингиз автоматик йаратилади.';

  @override
  String get auth_checkEmail =>
      'Ҳисобингизни тасдиқлаш учун электрон почтангизни текширинг.';

  @override
  String get auth_enterBoth => 'Электрон почта ва паролни киритинг.';

  @override
  String get auth_unexpectedError =>
      'Кутилмаган хатолик юз берди. Қайта уриниб кўринг.';

  @override
  String get auth_googleFailed =>
      'Google орқали кириш амалга ошмади. Қайта уриниб кўринг.';

  @override
  String get auth_guestFailed =>
      'Меҳмон сифатида кириш амалга ошмади. Электрон почта йоки Google орқали уриниб кўринг.';

  @override
  String get import_recipe => 'Рецепт импорт қилиш';

  @override
  String get import_pasteRaw => 'Рецепт матнини жойлаштиринг';

  @override
  String get import_description =>
      'Веб-сайт, китоб йоки эслатмалар иловасидан кўчириб жойлаштиринг. Сунъий интеллектимиз уни босқичма-босқич ақлли рецептга айлантиради.';

  @override
  String get import_hint =>
      'Масалан: Бувининг печенеси\n2 стакан ун ва 1 стакан шакарни аралаштиринг... 180° да 10 дақиқа пиширинг.';

  @override
  String get import_analyzing => 'Рецепт таҳлил қилинмоқда...';

  @override
  String get import_parseWithAi => 'AI билан таҳлил қилиш';

  @override
  String get import_parsedRecipe => 'Таҳлил қилинган рецепт';

  @override
  String get import_steps => 'Босқичлар';

  @override
  String get import_saveButton => 'Ажойиб — Рецептларимга сақлаш';

  @override
  String get import_savedLocally => 'Рецепт Рецептларимга сақланди!';

  @override
  String get tutorial_next => 'Кейингиси →';

  @override
  String get tutorial_gotIt => 'Тушунарли! 🎉';

  @override
  String get tutorial_cookTitle => 'Рецептларингиз';

  @override
  String get tutorial_cookDesc =>
      'Музлатгичда бор нарсаларга асосланган AI томонидан танланган рецептларни кўринг. Мос келиш фоизи қанча юқори бўлса, шунча кўп ингредиентлар сизда бор!';

  @override
  String get tutorial_scanTitle => 'Ингредиентларни сканерлаш';

  @override
  String get tutorial_scanDesc =>
      'Камерангиз билан чекларни, штрих-кодларни сканерланг ёки ингредиентлар суратини олинг. AI уларни бир зумда аниқлайди.';

  @override
  String get tutorial_shelfTitle => 'Сизнинг токчангиз';

  @override
  String get tutorial_shelfDesc =>
      'Рақамли музлатгич, фризер ва омборхона. Яроқлилик муддатларини ва миқдорларни кузатиб боринг — озиқ-овқат бузилишидан олдин хабардор қиламиз.';

  @override
  String get tutorial_profileTitle => 'Профил ва созламалар';

  @override
  String get tutorial_profileDesc =>
      'Профил иконкасига босиб тилни, мавзуни ўзгартиринг, таъм профилингизни бошқаринг ва пиширишш сериялариини кузатинг!';

  @override
  String get tutorial_replay => 'Ўқув қўлланмани қайта кўриш';

  @override
  String get tutorial_replayConfirm =>
      'Кейинги ишга туширишда ўқув қўлланма кўрсатилади.';

  @override
  String get auth_enterEmail =>
      'Илтимос, аввал электрон почта манзилингизни киритинг.';

  @override
  String get tutorial_tourTitle => 'Plately Интерактив Қўлланмаси';

  @override
  String get tutorial_tourDesc =>
      'Хуш келибсиз! Келинг, Plately бўйлаб 1 дақиқалик қисқача саёҳат қиламиз. Биз сизга ингредиентларни қандай бошқаришни, мос рецептларни топишни ва пиширишни қандай бошлашни кўрсатамиз!';

  @override
  String get tutorial_startTour => 'Бошлаш 🚀';

  @override
  String get tutorial_skipTour => 'Ўтказиб юбориш';

  @override
  String get tutorial_shelfIntroTitle => 'Сизнинг Рақамли Жавонингиз';

  @override
  String get tutorial_shelfIntroDesc =>
      'Бу сизнинг рақамли музлатгич ва омборхонангиз. Бу ерда сиз миқдорларни ва яроқлилик муддатларини кузатишингиз мумкин — овқат бузилишидан олдин сизни огоҳлантирамиз. Келинг, бу қандай ишлашини кўрамиз!';

  @override
  String get tutorial_nextArrow => 'Кейинги →';

  @override
  String get tutorial_addIntroTitle => 'Ингредиентларни Қўшиш';

  @override
  String get tutorial_addIntroDesc =>
      'Ингредиентларни қўшиш учун пастки менюдаги Сканерлаш (камера белгиси) тугмасини босинг. Қани, босинг!';

  @override
  String get tutorial_bypassScan => 'Ўтиш (Сканерлашга бориш)';

  @override
  String get tutorial_scanIntroTitle => 'Сканерлаш ва Қўлда Қўшиш';

  @override
  String get tutorial_scanIntroDesc =>
      'Бу ерда сиз чекларни, штрих-кодларни сканерлашингиз ёки ингредиентлар суратини олишингиз мумкин. Ушбу қўлланма учун биз товуқ қовуриш рецепти учун керакли 5 та қалбаки ингредиентни автоматик юклаймиз.';

  @override
  String get tutorial_loadMock => 'Қалбаки Ингредиентларни Юклаш 🛒';

  @override
  String get tutorial_shelfAddedTitle => 'Ингредиентлар Юкланди!';

  @override
  String get tutorial_shelfAddedDesc =>
      'Ажойиб! Биз буларни юкладик: Товуқ Гўшти, Брокколи, Соя Соуси, Саримсоқ ва Кунжут Ёғи. Келинг, нима пишириш мумкинлигини кўрамиз! Мос рецептларни топиш учун Пишириш тугмасини (чапдаги ресторан белгиси) босинг.';

  @override
  String get tutorial_bypassCook => 'Ўтиш (Пиширишга бориш)';

  @override
  String get tutorial_roamCookTitle => '5 Даражали Тавсиялар';

  @override
  String get tutorial_roamCookDesc =>
      'Бу ерда сиз 5 хил тавсия саҳифаларини кўрасиз (Мукаммал, Сиз учун, Ишлатиб юбориш, Қисман, Кашф қилиш). Уларни ўрганиш учун босиб кўринг! Тайёр бўлганингизда, Мукаммал бўлимидаги \"Қовурилган Товуқ\" рецепти картасини босинг.';

  @override
  String get tutorial_recipeDetailTitle => 'Рецепт Тафсилотлари';

  @override
  String get tutorial_recipeDetailDesc =>
      'Бу ерда сиз ингредиентлар рўйхатини ва қадамларни кўрасиз. Бошлаш учун саҳифа пастидаги \"Пиширишни Бошлаш\" тугмасини босинг!';

  @override
  String get tutorial_cookingPrepTitle => 'Тайёргарлик ва Ингредиентлар';

  @override
  String get tutorial_cookingPrepDesc =>
      'Оловни ёқишдан олдин, ингредиентларни ювинг ва тўғранг. Пишириш ёрдамчисини ишга тушириш учун \"Қадам-ба-қадам Бошлаш\" тугмасини босинг!';

  @override
  String get tutorial_cookingRunTitle => 'Пишириш Ёрдамчиси';

  @override
  String get tutorial_cookingRunDesc =>
      'Ёрдамчи сизни қадам-ба-қадам бошқаради. Сиз шунингдек, ўзгартиришлар ёки пишириш ҳақидаги саволлар учун пастдаги AI ёрдамчиси билан гаплашишингиз мумкин! Рецепт қадамларини бажаринг ва охирги қадамда \"Тугатиш\" ни босинг.';

  @override
  String get tutorial_finishTitle => 'Қўлланма Якунланди!';

  @override
  String get tutorial_finishDesc =>
      'Табриклаймиз! Сиз Plately пишириш қўлланмасини якунладингиз.\n\nЭслатма: Ушбу қўлланмада ишлатилган барча ингредиентлар ва маълумотлар сақланмайди. Бу илованинг кичик бир қисми холос. Ўз пишириш саёҳатингизни бошлаш учун \"Қўлланмани Тугатиш\" ни босинг!';

  @override
  String get tutorial_finishTour => 'Қўлланмани Тугатиш 🏁';

  @override
  String get tutorial_recipeTitle => 'Qovurilgan Tovuq (Qo\'llanma)';

  @override
  String get tutorial_ing_chicken => 'Tovuq Go\'shti';

  @override
  String get tutorial_ing_broccoli => 'Brokkoli';

  @override
  String get tutorial_ing_soy_sauce => 'Soya Sousi';

  @override
  String get tutorial_ing_garlic => 'Sarimsoq';

  @override
  String get tutorial_ing_sesame_oil => 'Kunjut Yog\'i';

  @override
  String get tutorial_step1 =>
      'Tovuq go\'shtini kichik bo\'laklarga va brokkolini kichik qismlarga bo\'ling. Sarimsoqni maydalang.';

  @override
  String get tutorial_step1_beg =>
      'Tovuq go\'shtini ehtiyotkorlik bilan kichik bo\'laklarga kesing. Brokkolini ham kichik qismlarga ajrating. Sarimsoqni tozalang va maydalang.';

  @override
  String get tutorial_step2 =>
      'Katta tovada o\'rta olovda kunjut yog\'ini qizdiring. Maydalangan sarimsoq qo\'shing va 1 daqiqa qovuring.';

  @override
  String get tutorial_step2_beg =>
      'Tovaga kunjut yog\'ini quying. Olovni o\'rta darajaga qo\'ying. Sarimsoq qo\'shing va kuymasligi uchun 1 daqiqa davomida to\'xtovsiz aralashtiring.';

  @override
  String get tutorial_step3 =>
      'Tovaga tovuq bo\'laklarini qo\'shing. 5-6 daqiqa davomida qovuring.';

  @override
  String get tutorial_step3_beg =>
      'Tovuq go\'shtini ehtiyotkorlik bilan tovaga qo\'shing. Tovuq ichida pushti rang qolmaguncha 5-6 daqiqa davomida aralashtirib pishiring.';

  @override
  String get tutorial_step4 =>
      'Brokkoli va soya sousini qo\'shing. Yana 3-4 daqiqa qovuring.';

  @override
  String get tutorial_step4_beg =>
      'Brokkoli qo\'shing va soya sousini quying. Brokkoli biroz yumshaguncha, lekin hali ham yashil rangda qolgunicha hamma narsani 3-4 daqiqa pishiring.';

  @override
  String get tutorial_step5 =>
      'Olovdan oling. Mazali tovuqni guruch bilan yoki o\'zini idishga solib dasturxonga torting!';

  @override
  String get tutorial_step5_beg =>
      'Olovni o\'chiring. Qovurilgan taomni idishga soling. Yangi pishgan taomingizdan rohatlaning!';

  @override
  String get reward_mealCompleted => 'Ovqat Tayyor!';

  @override
  String reward_youCooked(String recipeTitle, String servings) {
    return 'Siz \"$recipeTitle\" tayyorladingiz · $servings porsiya';
  }

  @override
  String get reward_xpEarned => 'Ishlangan XP';

  @override
  String get reward_itemsUsed => 'Ishlatilgan Masalliqlar';

  @override
  String get reward_deducted => 'Javondan olingan';

  @override
  String get reward_backToShelf => 'Javonga qaytish';
}
