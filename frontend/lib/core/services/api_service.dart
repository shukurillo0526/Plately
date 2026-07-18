// Plately — API Service
// ======================
// Shared HTTP client for all Flutter ↔ backend communication.
// Auto-detects environment: localhost → local backend, GitHub Pages / Play Store → Railway.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiConfig {
  static const String _productionUrl =
      'https://merry-motivation-production-3529.up.railway.app';

  /// Set to true only when running local FastAPI server on port 8000.
  static const bool useLocalBackend = false;

  /// Automatically picks the right backend URL based on where the app is running.
  static String get baseUrl {
    if (!useLocalBackend) {
      return _productionUrl;
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host != 'localhost' && host != '127.0.0.1') {
        return _productionUrl;
      }
      return 'http://localhost:8000';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return kReleaseMode ? _productionUrl : 'http://10.0.2.2:8000';
    }
    if (!kIsWeb && Platform.isIOS) {
      return kReleaseMode ? _productionUrl : 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  /// True when connecting to the local backend (Ollama AI available).
  static bool get isLocal => baseUrl.contains('localhost') || baseUrl.contains('10.0.2.2');
}


class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ── Vision ───────────────────────────────────────────────────────

  /// Send a grocery receipt image for OCR and AI analysis.
  /// Returns a structured JSON list of detected ingredients and expirations.
  Future<Map<String, dynamic>> parseReceipt({
    required Uint8List imageBytes,
    String filename = 'receipt.jpg',
    String lang = 'en',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/receipt/scan?lang=$lang');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Accept': 'application/json'}) // No auth header needed for this MVP endpoint yet
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));

    final streamedResponse = await _client.send(request).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw Exception('Scanning timed out. Please check your connection and try again.'),
    );
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }


  // ── AI (Local Ollama) ───────────────────────────────────────────

  /// Detect food ingredients in a photo (loose items, not receipts).
  /// Uses the /api/v1/vision/detect-ingredients endpoint.
  Future<Map<String, dynamic>> detectIngredients({
    required Uint8List imageBytes,
    String filename = 'photo.jpg',
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/vision/detect-ingredients');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Accept': 'application/json'})
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));

    final streamedResponse = await _client.send(request).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw Exception('Food scanning timed out. Please try again.'),
    );
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  /// Get a cooking tip for a recipe step from the local AI.
  Future<Map<String, dynamic>> getCookingTip({
    required String stepText,
    String? question,
    String? locale,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/cooking-tip');
    final body = {
      'step_text': stepText,
      'question': ?question,
      'locale': ?locale,
    };
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Generate a recipe from available ingredients using local AI.
  Future<Map<String, dynamic>> generateRecipe({
    required List<String> ingredients,
    String? cuisine,
    int? maxTimeMinutes,
    int? difficulty,
    int servings = 2,
    bool shelfOnly = false,
    String? locale,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/generate-recipe');
    final body = {
      'ingredients': ingredients,
      if (cuisine != null) 'cuisine': cuisine,
      if (maxTimeMinutes != null) 'max_time_minutes': maxTimeMinutes,
      if (difficulty != null) 'difficulty': difficulty,
      'servings': servings,
      'shelf_only': shelfOnly,
      if (locale != null) 'locale': locale,
    };
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Suggest substitutes for a missing ingredient.
  Future<Map<String, dynamic>> suggestSubstitute({
    required String ingredient,
    String? recipeContext,
    String? locale,
    List<String>? inventoryIngredients,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/substitute');
    final body = {
      'ingredient': ingredient,
      'recipe_context': ?recipeContext,
      'locale': ?locale,
      if (inventoryIngredients != null) 'inventory_ingredients': inventoryIngredients,
    };
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Parse unstructured raw text into a structured recipe object.
  Future<Map<String, dynamic>> parseRawRecipe({
    required String rawText,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/parse-raw');
    final body = {
      'raw_text': rawText,
    };
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Check AI pipeline health (Ollama status + loaded models).
  Future<Map<String, dynamic>> getAiStatus() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/status');
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  // ── Inventory ─────────────────────────────────────────────────

  /// Add an item to inventory via the backend (bypasses RLS).
  Future<Map<String, dynamic>> addInventoryItem({
    required String userId,
    required String ingredientName,
    String category = 'Pantry',
    double quantity = 1.0,
    String unit = 'pcs',
    String location = 'Fridge',
    String? expiryDate,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/inventory/add-item');
    final body = {
      'user_id': userId,
      'ingredient_name': ingredientName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'expiry_date': ?expiryDate,
    };
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ── Ingredient Search ───────────────────────────────────────────

  /// Search ingredients by name (EN, KO, canonical) with full metadata.
  Future<List<Map<String, dynamic>>> searchIngredients(String query, {int limit = 8}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ingredients/search?q=${Uri.encodeComponent(query)}&limit=$limit');
    final response = await _client.get(uri, headers: _headers);
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['ingredients'] ?? []);
  }

  /// Fuzzy search ingredients using pg_trgm similarity (typo-tolerant).
  Future<List<Map<String, dynamic>>> fuzzySearchIngredients(String query, {int limit = 5}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ingredients/fuzzy?q=${Uri.encodeComponent(query)}&limit=$limit');
    final response = await _client.get(uri, headers: _headers);
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['ingredients'] ?? []);
  }

  /// Resolve an ingredient: fuzzy-match first, auto-create if no match.
  /// Returns: {ingredient: {...}, resolution: 'exact'|'fuzzy'|'created', created: bool}
  Future<Map<String, dynamic>> resolveIngredient({
    required String name,
    String category = 'other',
    String? userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ingredients/resolve');
    final body = {
      'name': name,
      'category': category,
      if (userId != null) 'user_id': userId,
    };
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ── Calorie Analysis ───────────────────────────────────────────

  /// Analyze food items for calorie content.
  Future<Map<String, dynamic>> analyzeCalories(List<String> foodItems) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/calories/analyze');
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'food_items': foodItems}),
    );
    return _handleResponse(response);
  }

  /// Log a meal's nutrition.
  Future<Map<String, dynamic>> logNutrition({
    required String userId,
    required String mealType,
    required List<Map<String, dynamic>> foodItems,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/calories/log');
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'meal_type': mealType,
        'food_items': foodItems,
        'notes': ?notes,
      }),
    );
    return _handleResponse(response);
  }

  /// Get daily nutrition summary.
  Future<Map<String, dynamic>> getDailyNutrition(String userId, {String? date}) async {
    final params = date != null ? '?date=$date' : '';
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/calories/daily/$userId$params');
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// Analyze a food photo for calorie content via vision AI.
  Future<Map<String, dynamic>> analyzeCaloriesImage(List<int> imageBytes, String filename) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/calories/analyze-image');
    final request = http.MultipartRequest('POST', uri);
    // Add auth and accept headers to multipart request
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    request.headers['Accept'] = 'application/json';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    ));
    final streamed = await request.send().timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw Exception('Calorie scanning timed out. Please try again.'),
    );
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // ── Health ───────────────────────────────────────────────────────

  /// Check backend health status.
  Future<Map<String, dynamic>> healthCheck() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/health');
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// Translate a full recipe (cache-first, tier-aware AI pipeline).
  /// Tier 1 (ru, ko, es): direct AI. Tier 2 (uz): glossary-assisted.
  Future<Map<String, dynamic>> translateRecipe({
    required String recipeId,
    required String title,
    required String ingredients,
    required String steps,
    required String targetLanguage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/translate-recipe');
    final body = {
      'recipe_id': recipeId,
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'target_language': targetLanguage,
    };
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Batch-translate recipe titles for list view (single AI call for up to 30).
  Future<Map<String, dynamic>> translateTitles({
    required List<String> recipeIds,
    required String targetLanguage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/translate-titles');
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipe_ids': recipeIds,
        'target_language': targetLanguage,
      }),
    );
    return _handleResponse(response);
  }

  /// Rate a translation quality (0.0 = bad, 1.0 = good).
  /// Low scores trigger automatic re-translation.
  Future<Map<String, dynamic>> rateTranslation({
    required String recipeId,
    required String languageCode,
    required double score,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/rate-translation');
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipe_id': recipeId,
        'language_code': languageCode,
        'score': score,
      }),
    );
    return _handleResponse(response);
  }

  // ── Internals ────────────────────────────────────────────────────

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  // ── Barcode Lookup ───────────────────────────────────────────────

  Future<Map<String, dynamic>?> lookupBarcode(String code) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/barcode/lookup?code=$code'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Inventory CRUD ──────────────────────────────────────────────

  /// Update an inventory item's properties.
  Future<Map<String, dynamic>> updateInventoryItem({
    required String itemId,
    double? quantity,
    String? unit,
    String? itemState,
    String? location,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (quantity != null) body['quantity'] = quantity;
    if (unit != null) body['unit'] = unit;
    if (itemState != null) body['item_state'] = itemState;
    if (location != null) body['location'] = location;
    if (notes != null) body['notes'] = notes;

    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/inventory/$itemId'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Delete an inventory item.
  Future<Map<String, dynamic>> deleteInventoryItem(String itemId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/inventory/$itemId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Consume (decrement) an inventory item.
  Future<Map<String, dynamic>> consumeInventoryItem({
    required String inventoryId,
    required double quantityToConsume,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/inventory/consume'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'inventory_id': inventoryId,
        'quantity_to_consume': quantityToConsume,
      }),
    );
    return _handleResponse(response);
  }

  // ── User Data ───────────────────────────────────────────────────

  /// Initialize a user's profile rows (idempotent).
  Future<Map<String, dynamic>> initUser({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/init'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'email': email,
        'display_name': ?displayName,
      }),
    );
    return _handleResponse(response);
  }

  /// Fetch the complete user dashboard in a single call.
  Future<Map<String, dynamic>> getUserDashboard({
    required String userId,
  }) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/$userId/dashboard'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Update user profile fields.
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? displayName,
    List<String>? dietaryTags,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{'user_id': userId};
    if (displayName != null) body['display_name'] = displayName;
    if (dietaryTags != null) body['dietary_tags'] = dietaryTags;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/profile'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ── Shopping List ───────────────────────────────────────────────

  /// Add an item to the shopping list.
  Future<Map<String, dynamic>> addShoppingItem({
    required String userId,
    required String ingredientName,
    double quantity = 1.0,
    String unit = 'pcs',
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/shopping-list'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'ingredient_name': ingredientName,
        'quantity': quantity,
        'unit': unit,
      }),
    );
    return _handleResponse(response);
  }

  /// Toggle a shopping list item's purchased status.
  Future<Map<String, dynamic>> toggleShoppingItem({
    required String itemId,
    required bool isPurchased,
  }) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/shopping-list/$itemId'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'is_purchased': isPurchased}),
    );
    return _handleResponse(response);
  }

  /// Delete a shopping list item.
  Future<Map<String, dynamic>> deleteShoppingItem(String itemId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/shopping-list/$itemId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ── Meal Plan ───────────────────────────────────────────────────

  /// Plan a recipe for a specific date.
  Future<Map<String, dynamic>> addMealPlan({
    required String userId,
    required String recipeId,
    required String plannedDate,
    String mealType = 'dinner',
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/meal-plan'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'recipe_id': recipeId,
        'planned_date': plannedDate,
        'meal_type': mealType,
      }),
    );
    return _handleResponse(response);
  }

  /// Delete a planned meal.
  Future<Map<String, dynamic>> deleteMealPlan(String mealId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/meal-plan/$mealId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// Get AI-powered ingredient substitutions
  Future<Map<String, dynamic>> getSubstitution({
    required String ingredient,
    String? recipeContext,
    List<String>? inventoryIngredients,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/substitute'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'ingredient': ingredient,
        'recipe_context': recipeContext,
        if (inventoryIngredients != null) 'inventory_ingredients': inventoryIngredients,
      }),
    );
    return _handleResponse(response);
  }

  /// Get server-side computed recipe recommendations (6-signal scoring)
  Future<Map<String, dynamic>> getRecommendations({
    required String userId,
    int maxPerTier = 10,
    bool includeTier5 = true,
    String? cuisineFilter,
  }) async {
    final params = <String, String>{
      'max_per_tier': maxPerTier.toString(),
      'include_tier5': includeTier5.toString(),
    };
    if (cuisineFilter != null) params['cuisine_filter'] = cuisineFilter;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/recommendations/$userId',
    ).replace(queryParameters: params);

    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// Record that the user cooked a recipe (triggers flavor profile learning)
  Future<Map<String, dynamic>> recordCook({
    required String userId,
    required String recipeId,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/cook'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'recipe_id': recipeId}),
    );
    return _handleResponse(response);
  }

  /// Track video engagement (like, save, view)
  Future<Map<String, dynamic>> trackEngagement({
    required String userId,
    required String videoId,
    required String action,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/user/engagement'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'video_id': videoId,
        'action': action,
      }),
    );
    return _handleResponse(response);
  }

  /// Extract recipe from YouTube video metadata
  Future<Map<String, dynamic>> extractYouTubeRecipe({
    required String videoTitle,
    String videoDescription = '',
    String channelName = '',
    String? youtubeId,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/youtube-recipe'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'video_title': videoTitle,
        'video_description': videoDescription,
        'channel_name': channelName,
        'youtube_id': youtubeId,
      }),
    );
    return _handleResponse(response);
  }

  /// Generate smart shopping list from missing ingredients
  Future<Map<String, dynamic>> generateShoppingList({
    required String userId,
    required List<String> recipeIds,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/shopping-list'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'recipe_ids': recipeIds,
      }),
    );
    return _handleResponse(response);
  }

  /// Send a chat message to the kitchen assistant (non-streaming)
  Future<Map<String, dynamic>> chatWithAssistant({
    required List<Map<String, String>> messages,
    String? context,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/chat'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': messages,
        'stream': false,
        'context': context,
      }),
    );
    return _handleResponse(response);
  }

  /// Predict expiry date for an ingredient
  Future<Map<String, dynamic>> predictExpiry({
    required String category,
    String? purchaseDate,
    String storageLocation = 'fridge',
    String packaging = 'opened',
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/inventory/predict-expiry'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'category': category,
        'purchase_date': purchaseDate,
        'storage_location': storageLocation,
        'packaging': packaging,
      }),
    );
    return _handleResponse(response);
  }

  /// Get computed calories + macros for a recipe (per-ingredient breakdown)
  Future<Map<String, dynamic>> getRecipeCalories({
    required String recipeId,
    int? servings,
  }) async {
    final params = <String, String>{};
    if (servings != null) params['servings'] = servings.toString();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/calories/recipe/$recipeId',
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// Batch-deduct recipe ingredients from inventory after cooking
  Future<Map<String, dynamic>> consumeRecipeIngredients({
    required String userId,
    required String recipeId,
    required double servingsCooked,
    List<String> skippedIngredientIds = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/inventory/consume-recipe'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'recipe_id': recipeId,
        'servings_cooked': servingsCooked,
        'skipped_ingredient_ids': skippedIngredientIds,
      }),
    );
    return _handleResponse(response);
  }

  /// Submit recipe feedback (thumbs up/down, feature rating, report)
  Future<Map<String, dynamic>> submitFeedback({
    required String recipeId,
    required String userId,
    required String feedbackType,
    required String locale,
    int? rating,
    String? comment,
    Map<String, dynamic>? metaData,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/feedback/submit'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipe_id': recipeId,
        'user_id': userId,
        'feedback_type': feedbackType,
        'locale': locale,
        if (rating != null) 'rating': rating,
        if (comment != null) 'comment': comment,
        if (metaData != null) 'meta_data': metaData,
      }),
    );
    return _handleResponse(response);
  }

  /// Get aggregated sentiment (likes/dislikes) for a recipe
  Future<Map<String, dynamic>> getRecipeSentiment({
    required String recipeId,
    String? userId,
  }) async {
    final params = <String, String>{};
    if (userId != null) params['user_id'] = userId;
    
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/feedback/recipe/$recipeId/sentiment',
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  // ── Meal Prep Plan APIs ────────────────────────────────────────

  /// Generate a multi-day meal prep plan via AI.
  Future<Map<String, dynamic>> generateMealPrepPlan({
    required String userId,
    required List<String> ingredients,
    required int days,
    required int mealsPerDay,
    int? targetCaloriesPerMeal,
    double? targetProteinG,
    double? targetCarbsG,
    double? targetFatG,
    String? cuisine,
    bool shelfOnly = false,
    String? locale,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-prep/generate');
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'days': days,
        'meals_per_day': mealsPerDay,
        'target_calories_per_meal': targetCaloriesPerMeal,
        'target_protein_g': targetProteinG,
        'target_carbs_g': targetCarbsG,
        'target_fat_g': targetFatG,
        'cuisine': cuisine,
        'available_ingredients': ingredients,
        'shelf_only': shelfOnly,
        'locale': locale,
      }),
    );
    return _handleResponse(response);
  }

  /// List user's meal prep plans.
  Future<Map<String, dynamic>> getMealPrepPlans() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-prep/plans');
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// Get a single meal prep plan with recipes.
  Future<Map<String, dynamic>> getMealPrepPlan(String planId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-prep/$planId');
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// Mark a meal prep plan as in_progress.
  Future<Map<String, dynamic>> startMealPrepPlan(String planId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-prep/$planId/start');
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    return _handleResponse(response);
  }

  /// Mark a meal prep plan as completed.
  Future<Map<String, dynamic>> completeMealPrepPlan(String planId, int actualMinutes) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-prep/$planId/complete');
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'actual_prep_time_minutes': actualMinutes}),
    );
    return _handleResponse(response);
  }

  /// Mark an individual recipe in a prep plan as cooked.
  Future<Map<String, dynamic>> markPrepRecipeCooked(
    String planId, int recipeIndex, int portionsCooked,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-prep/$planId/recipe/$recipeIndex/cooked',
    );
    final response = await _client.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'portions_cooked': portionsCooked}),
    );
    return _handleResponse(response);
  }

  /// Get meal prep stock levels and expiry warnings.
  Future<Map<String, dynamic>> getPrepStatus(String userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/notifications/prep-status/$userId',
    );
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
