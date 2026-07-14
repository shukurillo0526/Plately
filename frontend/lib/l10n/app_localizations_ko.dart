// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Plately (냉장고)';

  @override
  String get tabShelf => '내 냉장고';

  @override
  String get tabCook => '요리';

  @override
  String get tabScan => '스캔';

  @override
  String get tabProfile => '프로필';

  @override
  String get profileTitle => '프로필';

  @override
  String profileGamificationLevel(int level) {
    return '레벨 $level';
  }

  @override
  String get profileMealsCooked => '요리한 횟수';

  @override
  String get profileItemsSaved => '절약한 식재료';

  @override
  String get profileDayStreak => '연속 달성';

  @override
  String get profileFlavorProfile => '나의 입맛 프로필';

  @override
  String get profileBadges => '배지 및 업적';

  @override
  String get profileShoppingList => '쇼핑 리스트';

  @override
  String get profileMealPlanner => '식단 플래너';

  @override
  String get actionAdd => '추가';

  @override
  String get actionCancel => '취소';

  @override
  String get actionSave => '저장';

  @override
  String get actionDelete => '삭제';

  @override
  String get profileLoadError => '프로필을 불러올 수 없습니다';

  @override
  String get retry => '다시 시도';

  @override
  String get refresh => '새로고침';

  @override
  String get signOut => '로그아웃';

  @override
  String get profileLevelProgress => '레벨 진행도';

  @override
  String profileLevel(int level) {
    return '레벨 $level';
  }

  @override
  String get profileYourImpact => '나의 영향력';

  @override
  String get addShoppingItem => '아이템 추가';

  @override
  String get shoppingListEmpty => '쇼핑 리스트가 비어 있습니다';

  @override
  String get mealPlannerEmpty => '예정된 식사가 없습니다';

  @override
  String get planToday => '오늘 식사 계획하기';

  @override
  String get today => '오늘';

  @override
  String get planMeal => '식사 계획...';

  @override
  String get tabExplore => '탐색';

  @override
  String get scanFood => '음식 스캔';

  @override
  String get scanCalories => '칼로리 스캔';

  @override
  String get takePhoto => '사진 찍기';

  @override
  String get chooseFromGallery => '갤러리에서 선택';

  @override
  String get analyzeCalories => '칼로리 분석';

  @override
  String get caloriesPerServing => 'kcal/인분';

  @override
  String get totalCalories => 'kcal 합계';

  @override
  String get creatorProfile => '크리에이터 프로필';

  @override
  String get follow => '팔로우';

  @override
  String get following => '팔로잉';

  @override
  String get nutritionTracker => '영양 추적기';

  @override
  String get reels => '릴스';

  @override
  String get community => '커뮤니티';

  @override
  String get hasRecipe => '레시피 있음';

  @override
  String get noReelsYet => '아직 릴스가 없습니다';

  @override
  String get settings => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsTheme => '테마';

  @override
  String get aboutApp => 'Plately 정보';

  @override
  String get myFridge => '🧊 내 냉장고';

  @override
  String get expiryAlerts => '만료 알림';

  @override
  String get errorLoadInventory => '인벤토리를 로드할 수 없습니다.';

  @override
  String get errorCheckConnection => '연결을 확인하고 다시 시도하세요.';

  @override
  String get total => '총';

  @override
  String get fresh => '신선한';

  @override
  String get expiring => '만료 예정';

  @override
  String get expired => '만료됨';

  @override
  String get searchIngredients => '성분 검색...';

  @override
  String get all => '모두';

  @override
  String itemsCount(int count) {
    return '$count개 항목';
  }

  @override
  String zoneEmptyTitle(String zone) {
    return '$zone가 비어 있습니다';
  }

  @override
  String get zoneEmptyDesc =>
      '디지털 주방을 가득 채울 준비가 되었습니다.\n수동으로 항목을 추가하거나 스캔을 탭하세요.';

  @override
  String get addIngredient => '성분 추가';

  @override
  String get urgentCook => '지금 요리하세요';

  @override
  String urgentUse(String ingredient) {
    return '$ingredient 사용';
  }

  @override
  String get noItemsMatch => '필터와 일치하는 항목이 없습니다.';

  @override
  String get clearFilters => '필터 지우기';

  @override
  String get expiryAlertsTitle => '🔔 만료 알림';

  @override
  String get allFresh => '모든 항목이 신선합니다! 🎉';

  @override
  String expiredCount(int count) {
    return '❌ 만료됨( $count )';
  }

  @override
  String expiringSoonCount(int count) {
    return '⚠️ 곧 만료됨( $count )';
  }

  @override
  String get auto_scanCaloriesIsComingSoon => '스캔 칼로리가 곧 출시됩니다!';

  @override
  String get auto_scan => '주사';

  @override
  String get auto_addAll => '모두 추가';

  @override
  String get auto_allAdded => '모두 추가됨';

  @override
  String get auto_scanAnother => '다른 스캔';

  @override
  String get auto_startVisualAudit => '시각적 감사 시작';

  @override
  String get auto_enterBarcode => '바코드 입력';

  @override
  String get auto_cancel => '취소';

  @override
  String get auto_lookUp => '찾다';

  @override
  String get auto_fridge => '냉장고';

  @override
  String get auto_freezer => '냉동고';

  @override
  String get auto_pantry => '팬트리';

  @override
  String get auto_addToShelf => '선반에 추가';

  @override
  String get auto_mealLogged => '✅ 식사 기록!';

  @override
  String get auto_snapYourMeal => '식사를 스냅하세요';

  @override
  String get auto_takeAPhotoAndAiWillEstimateCalories =>
      '사진을 찍으면 AI가 칼로리를 추정합니다.';

  @override
  String get auto_analyzingFood => '음식을 분석하는 중...';

  @override
  String get auto_camera => '카메라';

  @override
  String get auto_gallery => '갱도';

  @override
  String get auto_estimatedCalories => '예상 칼로리';

  @override
  String get auto_cal => '칼';

  @override
  String get auto_logMeal => '식사 기록';

  @override
  String get auto_addSomeIngredientsToYourShelfFirst =>
      '먼저 선반에 몇 가지 재료를 추가하세요!';

  @override
  String get auto_aiRecipeGenerator => 'AI 레시피 생성기';

  @override
  String get auto_any => '어느';

  @override
  String get auto_shelfOnly => '선반만';

  @override
  String get auto_generateRecipe => '레시피 생성';

  @override
  String get auto_ingredients => '🧂 재료';

  @override
  String get auto_steps => '👨‍🍳 단계';

  @override
  String get auto_importRecipe => '레시피 가져오기';

  @override
  String get auto_retry => '다시 해 보다';

  @override
  String get auto_addItemsToYourShelfToGetRecommendations =>
      '추천을 받으려면 서가에 항목을 추가하세요.';

  @override
  String get auto_noRecipesMatchThisCuisine => '이 요리와 일치하는 레시피가 없습니다.';

  @override
  String get auto_clearFilter => '필터 지우기';

  @override
  String get auto_deleteItem => '항목을 삭제하시겠습니까?';

  @override
  String get auto_delete => '삭제';

  @override
  String get auto_freshness => '선도';

  @override
  String get auto_use1Unit => '1개 사용';

  @override
  String get auto_removeFromInventory => '인벤토리에서 제거';

  @override
  String get auto_following => '수행원';

  @override
  String get auto_follow => '따르다';

  @override
  String get auto_posts => '게시물';

  @override
  String get auto_noPostsYet => '아직 게시물이 없습니다';

  @override
  String get auto_explore => '탐구하다';

  @override
  String get auto_noReelsYet => '아직 릴이 없습니다.';

  @override
  String get auto_cookThisRecipe => '이 조리법을 요리';

  @override
  String get auto_recipeNotFound => '레시피를 찾을 수 없습니다';

  @override
  String get auto_hasRecipe => '레시피 있음';

  @override
  String get auto_noCommunityPostsYet => '아직 커뮤니티 게시물이 없습니다.';

  @override
  String get auto_beTheFirstToShare => '가장 먼저 공유해 보세요!';

  @override
  String get auto_createPost => '게시물 작성';

  @override
  String get auto_savedPosts => '저장된 게시물';

  @override
  String get auto_noSavedPostsYet => '아직 저장된 게시물이 없습니다.';

  @override
  String get auto_you => '너';

  @override
  String get auto_checkout => '점검';

  @override
  String get auto_yourCartIsEmpty => '장바구니가 비어 있습니다.';

  @override
  String get auto_yourOrder => '귀하의 주문';

  @override
  String get auto_total => '총';

  @override
  String get auto_orderConfirmed => '주문이 확인되었습니다!';

  @override
  String get auto_yourPickupCode => '픽업 코드';

  @override
  String get auto_showThisCodeAtTheCounter => '카운터에서 이 코드를 제시하세요';

  @override
  String get auto_deliveryOnTheWay => '배송 중';

  @override
  String get auto_aDriverWillBeAssignedShortly => '곧 운전기사가 배정될 예정입니다.';

  @override
  String get auto_backToHome => '홈으로 돌아가기';

  @override
  String get auto_incomingOrders => '들어오는 주문';

  @override
  String get auto_noFoodVideosYet => '아직 음식 동영상이 없습니다.';

  @override
  String get auto_foodFeed => '식품 사료';

  @override
  String get auto_myOrders => '내 주문';

  @override
  String get auto_noOrdersYet => '아직 주문이 없습니다';

  @override
  String get auto_yourOrderHistoryWillAppearHere => '주문 내역이 여기에 표시됩니다';

  @override
  String get auto_cancelOrder => '주문을 취소하시겠습니까?';

  @override
  String get auto_keepOrder => '질서 유지';

  @override
  String get auto_orderCancelled => '주문이 취소됨';

  @override
  String get auto_pickupCode => '픽업 코드:';

  @override
  String get auto_closed => '닫은';

  @override
  String get auto_menu => '메뉴';

  @override
  String get auto_menuComingSoon => '곧 나올 메뉴';

  @override
  String get auto_best => '🔥 최고';

  @override
  String get auto_popularDishes => '🍽️ 인기 요리';

  @override
  String get auto_fromVideo => '비디오에서';

  @override
  String get auto_bookATable => '테이블 예약';

  @override
  String get auto_confirmReservation => '예약 확인';

  @override
  String get auto_locationDirections => '위치 및 오시는 길';

  @override
  String get auto_mapView => '지도 보기';

  @override
  String get auto_openInGoogleMaps => 'Google 지도에서 열기';

  @override
  String get auto_writeAReview => '리뷰 작성';

  @override
  String get auto_viewCart => '장바구니 보기';

  @override
  String get auto_signOut => '로그아웃하시겠습니까?';

  @override
  String get auto_youWillNeedToSignInAgain => '다시 로그인해야 합니다.';

  @override
  String get auto_deleteAccount => '계정 삭제';

  @override
  String get auto_deleteForever => '영원히 삭제';

  @override
  String get auto_accountDeletionRequestedContactSupportToFinalize =>
      '계정 삭제를 요청했습니다. 마무리하려면 지원팀에 문의하세요.';

  @override
  String get auto_plately => '아이냉장고';

  @override
  String
  get auto_platelyIsYourAipoweredKitchenEcosystemItAutomaticallyTracksYourIngredientsPredictsExpirationsGeneratesPersonalizedRecipesAndLetsYouOrderFromLocalRestaurants =>
      'Plately는 AI 기반 주방 생태계입니다. 자동으로 재료를 추적하고, 유통기한을 예측하고, 맞춤형 레시피를 생성하고, 현지 레스토랑에서 주문할 수 있습니다.';

  @override
  String get auto_gotIt => '알았어요';

  @override
  String get auto_editDisplayName => '표시 이름 편집';

  @override
  String get auto_save => '구하다';

  @override
  String get auto_addShoppingItem => '쇼핑 아이템 추가';

  @override
  String get auto_add => '추가하다';

  @override
  String get auto_selectRecipeForMeal => '식사 레시피 선택';

  @override
  String get auto_failedToLoadRecipes => '레시피를 로드하지 못했습니다.';

  @override
  String get auto_noRecipesFound => '레시피를 찾을 수 없습니다.';

  @override
  String get auto_mealCleared => '식사 클리어';

  @override
  String get auto_theme => '🎨 테마';

  @override
  String get whatToCook => '무엇을 요리할까요?';

  @override
  String get tierPerfect => '완벽';

  @override
  String get tierForYou => '추천';

  @override
  String get tierUseItUp => '빨리 소비';

  @override
  String get tierAlmost => '거의 비슷';

  @override
  String get tierExplore => '탐색';

  @override
  String noTierRecipesYet(String tier) {
    return '$tier 레시피가 아직 없습니다';
  }

  @override
  String get addItemsForRecommendations => '선반에 재료를 추가하여 추천을 받으세요';

  @override
  String get scanCaloriesTab => '칼로리 스캔';

  @override
  String get scanYourIngredients => '재료를 스캔하세요';

  @override
  String get takePhotoToAdd => '음식 사진을 찍어 선반에 자동으로 추가하세요';

  @override
  String get scanReceipt => '영수증';

  @override
  String get scanPhoto => '사진';

  @override
  String get scanBarcode => '바코드 스캔';

  @override
  String get takePhotoBtn => '사진 찍기';

  @override
  String get adjustPortions => '부분 조정';

  @override
  String currentRecipeMakesNServings(String servings) {
    return '현재 레시피는 $servings인분입니다.';
  }

  @override
  String scaleToNServings(String newServings) {
    return '$newServings회 제공량으로 확장';
  }

  @override
  String scaledToNServings(String newServings) {
    return '$newServings인분으로 확장되었습니다 🍳';
  }

  @override
  String findingSubstitutesForX(String ingredientName) {
    return '$ingredientName의 대체품을 찾는 중...';
  }

  @override
  String get couldNotFindSubstitutes => '대체품을 찾을 수 없습니다.';

  @override
  String substitutesForX(String ingredientName) {
    return '\"$ingredientName\"를 대체합니다.';
  }

  @override
  String get noSubstitutesFoundForThisRecipeContext =>
      '이 레시피 컨텍스트에 대한 대체 항목을 찾을 수 없습니다.';

  @override
  String nMatch(String match) {
    return '$match% 일치';
  }

  @override
  String ingredientsWithCount(String count) {
    return '성분($count)';
  }

  @override
  String get scale => '규모';

  @override
  String get addedMissingItemsToShoppingList => '쇼핑 목록에 누락된 품목을 추가했습니다!';

  @override
  String failedToAddItemsX(String e) {
    return '항목 추가 실패: $e';
  }

  @override
  String get addMissingToShoppingList => '쇼핑 목록에 누락된 항목 추가';

  @override
  String cookingStepsWithCount(String count) {
    return '요리 단계($count)';
  }

  @override
  String get noStepsAvailableYet => '아직 단계가 없습니다';

  @override
  String get recordedTasteProfileEvolving =>
      '녹음되었습니다! 당신의 취향 프로필이 진화하고 있습니다 🧠';

  @override
  String failedToRecordX(String e) {
    return '기록 실패: $e';
  }

  @override
  String get iCookedThis => '내가 이걸 요리했어!';

  @override
  String get startCooking => '요리 시작';

  @override
  String get optional_tag => '선택 과목';

  @override
  String get servings_tag => '인분';

  @override
  String get min_tag => '분';

  @override
  String get difficulty_tag => '어려움';

  @override
  String get expiringSoon => '곧 만료됨';

  @override
  String nItemsNeedAttention(String count) {
    return '$count개 항목에 주의가 필요합니다.';
  }

  @override
  String get takeAPhotoOfFoodItems => '추가하려면 음식 사진을 찍으세요.\n자동으로 선반에';

  @override
  String get addManually => '수동으로 추가';

  @override
  String get recognitionFailed => '인식에 실패했습니다. 다시 시도해 보세요.';

  @override
  String get analyzingYourFood => '음식을 분석하는 중...';

  @override
  String get aiIsIdentifying => 'AI가 성분을 식별하고 있다';

  @override
  String nItemsDetected(String count) {
    return '$count개 항목이 감지되었습니다.';
  }

  @override
  String get photoAnalysisSelected => '사진 분석 선택';

  @override
  String nIngredientsDetected(String count) {
    return '$count 성분이 감지되었습니다';
  }

  @override
  String nOfNAdded(String added, String total) {
    return '$added / $total 추가됨';
  }

  @override
  String addedItem(String item) {
    return '$item를 추가했습니다!';
  }

  @override
  String failedToAddItem(String item) {
    return '$item를 추가하지 못했습니다.';
  }

  @override
  String addedNItemsToShelf(String count) {
    return '$count 항목을 선반에 추가했습니다!';
  }

  @override
  String noProductFoundForBarcode(String barcode) {
    return '바코드 $barcode에 해당하는 제품을 찾을 수 없습니다.';
  }

  @override
  String addedItemToShelf(String item) {
    return '선반에 $item를 추가했습니다!';
  }

  @override
  String errorX(String e) {
    return '오류: $e';
  }

  @override
  String analysisFailedX(String e) {
    return '분석 실패: $e';
  }

  @override
  String failedToLogX(String e) {
    return '로그 실패: $e';
  }

  @override
  String get scanBarcodeShort => '바코드';

  @override
  String get profileAccount => '계정';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get tierBadge1 => '✅ 재료 완비!';

  @override
  String get tierBadge2 => '🔥 추천 레시피';

  @override
  String get tierBadge3 => '⏰ 곧 만료되는 재료 활용';

  @override
  String get tierBadge4 => '🛒 몇 가지 재료 부족';

  @override
  String get tierBadge5 => '🌍 새로운 요리 발견';

  @override
  String needLabel(String items) {
    return '필요: $items';
  }

  @override
  String nOfNIngredients(String matched, String total) {
    return '$matched/$total 재료';
  }

  @override
  String get servingsLabel => '인분';

  @override
  String nHave(String count) {
    return '$count개 보유';
  }

  @override
  String nMissing(String count) {
    return '$count개 부족';
  }

  @override
  String get ingredientsHeader => '재료';

  @override
  String get swapButton => '대체 →';

  @override
  String get aiAssistant => '🤖 AI 어시스턴트';

  @override
  String get aiHint => '예: \"양고기가 없는데 대체할 수 있는 것은?\"';

  @override
  String get editIngredient => '재료 편집';

  @override
  String get nameLabel => '이름';

  @override
  String get qtyLabel => '수량';

  @override
  String get unitLabel => '단위';

  @override
  String get handsOn => '직접';

  @override
  String get automatic => '자동';

  @override
  String get inv_quantity => '수량';

  @override
  String get inv_purchased => '구매일';

  @override
  String get inv_expires => '만료일';

  @override
  String get inv_source => '출처';

  @override
  String get inv_storageLocation => '보관 위치';

  @override
  String get inv_itemState => '상태';

  @override
  String get inv_freshLabel => '🟢 신선';

  @override
  String get inv_agingLabel => '🟡 노화중';

  @override
  String get inv_urgentLabel => '🟠 긴급';

  @override
  String get inv_criticalLabel => '🔴 위험';

  @override
  String get inv_expiredLabel => '⚫ 만료됨';

  @override
  String inv_expiredDaysAgo(String days) {
    return '$days일 전 만료';
  }

  @override
  String get inv_expiresToday => '오늘 만료!';

  @override
  String get inv_expiresTomorrow => '내일 만료';

  @override
  String inv_daysRemaining(String days) {
    return '$days일 남음';
  }

  @override
  String get inv_stateOpened => '개봉';

  @override
  String get inv_stateFrozen => '냉동';

  @override
  String get inv_stateThawed => '해동';

  @override
  String get inv_statePartial => '일부사용';

  @override
  String get inv_sortExpiry => '만료일 ↑';

  @override
  String get inv_sortName => '이름 순';

  @override
  String get inv_sortCategory => '카테고리';

  @override
  String get inv_sortNewest => '최신 순';

  @override
  String inv_removeConfirm(String name) {
    return '\"$name\"을(를) 인벤토리에서 삭제하시겠습니까?';
  }

  @override
  String get manual_addIngredient => '재료 추가';

  @override
  String get manual_ingredientName => '재료 이름';

  @override
  String get manual_ingredientHint => '예: 사과, 빵, 우유';

  @override
  String get manual_category => '카테고리';

  @override
  String get manual_qty => '수량';

  @override
  String get manual_metricType => '단위';

  @override
  String get manual_estimatedExpiry => '예상 유통기한';

  @override
  String get manual_required => '필수';

  @override
  String get auth_tagline => '음식물 낭비 제로, 맛은 최대로.';

  @override
  String get auth_subtitle => '스마트하게 관리되는 당신의 주방.';

  @override
  String get auth_email => '이메일';

  @override
  String get auth_password => '비밀번호';

  @override
  String get auth_continue => '계속하기';

  @override
  String get auth_or => '또는';

  @override
  String get auth_continueGoogle => 'Google로 계속하기';

  @override
  String get auth_continueGuest => '게스트로 계속하기';

  @override
  String get auth_autoDetectHint => '처음이세요? 계정이 자동으로 생성됩니다.';

  @override
  String get auth_checkEmail => '계정 확인을 위해 이메일을 확인하세요.';

  @override
  String get auth_enterBoth => '이메일과 비밀번호를 입력하세요.';

  @override
  String get auth_unexpectedError => '예기치 않은 오류가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get auth_googleFailed => 'Google 로그인에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get auth_guestFailed => '게스트 로그인에 실패했습니다. 이메일이나 Google을 사용해 보세요.';

  @override
  String get auth_resetSent => '비밀번호 재설정 이메일이 발송되었습니다. 받은 편지함을 확인하세요.';

  @override
  String get auth_forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get import_recipe => '레시피 가져오기';

  @override
  String get import_pasteRaw => '레시피 텍스트 붙여넣기';

  @override
  String get import_description =>
      '웹사이트, 책 또는 메모 앱에서 복사하여 붙여넣으세요. AI가 단계별 스마트 레시피로 변환합니다.';

  @override
  String get import_hint => '예: 할머니의 쿠키\n밀가루 2컵과 설탕 1컵을 섞고... 180°에서 10분 굽기.';

  @override
  String get import_analyzing => '레시피 분석 중...';

  @override
  String get import_parseWithAi => 'AI로 분석하기';

  @override
  String get import_parsedRecipe => '분석된 레시피';

  @override
  String get import_steps => '단계';

  @override
  String get import_saveButton => '좋아요 — 내 레시피에 저장';

  @override
  String get import_savedLocally => '레시피가 내 레시피에 저장되었습니다!';

  @override
  String get tutorial_next => '다음 →';

  @override
  String get tutorial_gotIt => '알겠어요! 🎉';

  @override
  String get tutorial_cookTitle => '내 레시피';

  @override
  String get tutorial_cookDesc =>
      '냉장고에 있는 재료를 기반으로 AI가 매칭한 레시피를 탐색하세요. 매칭률이 높을수록 이미 가지고 있는 재료가 많습니다!';

  @override
  String get tutorial_scanTitle => '재료 스캔';

  @override
  String get tutorial_scanDesc =>
      '카메라로 영수증, 바코드를 스캔하거나 재료 사진을 찍으세요. AI가 즉시 인식합니다.';

  @override
  String get tutorial_shelfTitle => '나의 식품 선반';

  @override
  String get tutorial_shelfDesc =>
      '디지털 냉장고, 냉동실, 식품 저장실. 유통기한과 수량을 추적하고 — 음식이 상하기 전에 알려드립니다.';

  @override
  String get tutorial_profileTitle => '프로필 & 설정';

  @override
  String get tutorial_profileDesc =>
      '프로필 아이콘을 눌러 언어, 테마를 변경하고 맛 프로필을 관리하며 요리 스트릭을 추적하세요!';

  @override
  String get tutorial_replay => '튜토리얼 다시 보기';

  @override
  String get tutorial_replayConfirm => '다음 앱 실행 시 튜토리얼이 표시됩니다.';

  @override
  String get auth_enterEmail => '이메일 주소를 먼저 입력해주세요.';

  @override
  String get tutorial_tourTitle => 'Plately 인터랙티브 투어';

  @override
  String get tutorial_tourDesc =>
      '환영합니다! Plately의 1분 인터랙티브 투어를 시작하겠습니다. 재료를 관리하고, 맞는 레시피를 찾고, 요리를 시작하는 방법을 보여드릴게요!';

  @override
  String get tutorial_startTour => '투어 시작 🚀';

  @override
  String get tutorial_skipTour => '건너뛰기';

  @override
  String get tutorial_shelfIntroTitle => '디지털 선반';

  @override
  String get tutorial_shelfIntroDesc =>
      '이곳은 여러분의 디지털 냉장고이자 팬트리입니다. 수량과 유통기한을 추적할 수 있으며, 음식이 상하기 전에 알려드립니다. 어떻게 작동하는지 볼까요!';

  @override
  String get tutorial_nextArrow => '다음 →';

  @override
  String get tutorial_addIntroTitle => '재료 추가하기';

  @override
  String get tutorial_addIntroDesc =>
      '재료를 추가하려면 하단의 스캔 탭(카메라 아이콘)을 누르세요. 어서 눌러보세요!';

  @override
  String get tutorial_bypassScan => '건너뛰기 (스캔으로 이동)';

  @override
  String get tutorial_scanIntroTitle => '스캔 및 수동 추가';

  @override
  String get tutorial_scanIntroDesc =>
      '영수증, 바코드를 스캔하거나 재료 사진을 찍을 수 있습니다. 이 튜토리얼에서는 닭고기 볶음 레시피에 필요한 5가지 가상 재료를 자동으로 불러옵니다.';

  @override
  String get tutorial_loadMock => '가상 재료 불러오기 🛒';

  @override
  String get tutorial_shelfAddedTitle => '재료 불러오기 완료!';

  @override
  String get tutorial_shelfAddedDesc =>
      '좋습니다! 닭가슴살, 브로콜리, 간장, 마늘, 참기름을 불러왔습니다. 무엇을 요리할 수 있을지 볼까요! 요리 탭(레스토랑 아이콘)을 눌러 레시피를 찾아보세요.';

  @override
  String get tutorial_bypassCook => '건너뛰기 (요리로 이동)';

  @override
  String get tutorial_roamCookTitle => '5단계 추천';

  @override
  String get tutorial_roamCookDesc =>
      '5가지 추천 탭(완벽 일치, 추천, 활용, 아쉬움, 탐색)이 있습니다. 탭을 눌러 둘러보세요! 준비가 되면 완벽 일치 탭의 \"닭고기 볶음\" 레시피 카드를 누르세요.';

  @override
  String get tutorial_recipeDetailTitle => '레시피 상세 정보';

  @override
  String get tutorial_recipeDetailDesc =>
      '여기서 재료 목록과 요리 단계를 볼 수 있습니다. 페이지 하단의 \"요리 시작\" 버튼을 눌러 시작하세요!';

  @override
  String get tutorial_cookingPrepTitle => '준비 및 재료';

  @override
  String get tutorial_cookingPrepDesc =>
      '불을 켜기 전에 재료를 씻고 썰어주세요. \"단계별 시작\" 버튼을 눌러 요리 도우미를 실행하세요!';

  @override
  String get tutorial_cookingRunTitle => '요리 도우미';

  @override
  String get tutorial_cookingRunDesc =>
      '도우미가 단계별로 안내합니다. 대체 재료나 질문이 있다면 하단의 AI 도우미와 채팅할 수도 있어요! 레시피 단계를 따라가고 마지막 단계에서 \"완료\"를 누르세요.';

  @override
  String get tutorial_finishTitle => '튜토리얼 완료!';

  @override
  String get tutorial_finishDesc =>
      '축하합니다! Plately 요리 투어를 완료했습니다.\n\n참고: 이 튜토리얼에 사용된 모든 재료와 데이터는 저장되지 않습니다. 이것은 앱의 아주 작은 부분일 뿐입니다. \"투어 완료\"를 눌러 나만의 요리 여정을 시작하세요!';

  @override
  String get tutorial_finishTour => '투어 완료 🏁';

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
