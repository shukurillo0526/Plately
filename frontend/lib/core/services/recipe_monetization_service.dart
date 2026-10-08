// Plately — Recipe Monetization Service
// =========================================
// Manages recipe creation, premium pricing, copies, and access control.
// Supports: create, attach to post, copy (free/paid), check access.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/auth_helper.dart';

class RecipeModel {
  final String id;
  final String title;
  final String? description;
  final String? cuisine;
  final int? difficulty;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final String? imageUrl;
  final List<String> tags;
  final bool isPremium;
  final int priceCents;
  final String? creatorId;
  final String? linkedPostId;
  final int copyCount;
  final int? caloriesPerServing;

  RecipeModel({
    required this.id,
    required this.title,
    this.description,
    this.cuisine,
    this.difficulty,
    this.prepTime,
    this.cookTime,
    this.servings,
    this.imageUrl,
    this.tags = const [],
    this.isPremium = false,
    this.priceCents = 0,
    this.creatorId,
    this.linkedPostId,
    this.copyCount = 0,
    this.caloriesPerServing,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> m) => RecipeModel(
    id: m['id'] as String,
    title: m['title'] as String? ?? 'Untitled',
    description: m['description'] as String?,
    cuisine: m['cuisine'] as String?,
    difficulty: m['difficulty'] as int?,
    prepTime: m['prep_time_minutes'] as int?,
    cookTime: m['cook_time_minutes'] as int?,
    servings: m['servings'] as int?,
    imageUrl: m['image_url'] as String?,
    tags: List<String>.from(m['tags'] ?? []),
    isPremium: m['is_premium'] as bool? ?? false,
    priceCents: m['price_cents'] as int? ?? 0,
    creatorId: m['creator_id'] as String?,
    linkedPostId: m['linked_post_id'] as String?,
    copyCount: m['copy_count'] as int? ?? 0,
    caloriesPerServing: m['calories_per_serving'] as int?,
  );

  String get priceDisplay {
    if (!isPremium || priceCents == 0) return 'Free';
    final dollars = priceCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  bool get isOwn => creatorId == currentUserId();
}

class RecipeMonetizationService {
  static final _client = Supabase.instance.client;

  /// Get all recipes created by current user.
  static Future<List<RecipeModel>> getMyRecipes() async {
    try {
      final uid = currentUserId();
      final data = await _client
          .from('recipes')
          .select()
          .or('creator_id.eq.$uid,author_id.eq.$uid')
          .order('created_at', ascending: false);
      return (data as List).map((m) => RecipeModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('[RecipeMon] getMyRecipes error: $e');
      return [];
    }
  }

  /// Create a new recipe with optional premium pricing.
  static Future<RecipeModel?> createRecipe({
    required String title,
    String? description,
    String? cuisine,
    int? difficulty,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? imageUrl,
    List<String> tags = const [],
    bool isPremium = false,
    int priceCents = 0,
    String? linkedPostId,
    int? caloriesPerServing,
    List<Map<String, dynamic>>? ingredients,
    List<Map<String, dynamic>>? steps,
  }) async {
    try {
      final uid = currentUserId();

      final jsonIngredients = ingredients?.map((ing) => {
        'name': ing['name'] ?? 'Ingredient',
        'quantity': ing['quantity'] ?? 1,
        'unit': ing['unit'] ?? 'piece',
        'prep_note': ing['prep_note'] ?? ''
      }).toList() ?? [];

      final jsonSteps = steps?.asMap().entries.map((e) => {
        'step_number': e.key + 1,
        'text': e.value['text'] ?? '',
        'timer_seconds': e.value['seconds'],
      }).toList() ?? [];

      final recipeData = await _client.from('recipes').insert({
        'title': title,
        'description': description,
        'cuisine': cuisine,
        'difficulty': difficulty,
        'prep_time_minutes': prepTime,
        'cook_time_minutes': cookTime,
        'servings': servings,
        'image_url': imageUrl,
        'tags': tags,
        'is_premium': isPremium,
        'price_cents': isPremium ? priceCents : 0,
        'creator_id': uid,
        'author_id': uid,
        'is_community': true,
        'linked_post_id': linkedPostId,
        'calories_per_serving': caloriesPerServing,
        'ingredients': jsonIngredients,
        'steps': jsonSteps,
      }).select().single();

      final recipe = RecipeModel.fromMap(recipeData);

      return recipe;
    } catch (e) {
      debugPrint('[RecipeMon] createRecipe error: $e');
      return null;
    }
  }

  /// Link an existing recipe to a post.
  static Future<bool> linkRecipeToPost(String recipeId, String postId) async {
    try {
      await _client.from('recipes').update({
        'linked_post_id': postId,
      }).eq('id', recipeId);
      await _client.from('posts').update({
        'recipe_id': recipeId,
      }).eq('id', postId);
      return true;
    } catch (e) {
      debugPrint('[RecipeMon] linkRecipeToPost error: $e');
      return false;
    }
  }

  /// Check if user has access to a recipe (free, owns copy, or is creator).
  static Future<bool> hasAccess(String recipeId) async {
    try {
      final uid = currentUserId();
      final res = await _client.rpc('has_recipe_access', params: {
        'p_recipe_id': recipeId,
        'p_user_id': uid,
      });
      return res as bool? ?? false;
    } catch (e) {
      // Fallback: check manually
      try {
        final recipe = await _client.from('recipes').select('is_premium, creator_id').eq('id', recipeId).single();
        if (!(recipe['is_premium'] as bool? ?? false)) return true;
        if (recipe['creator_id'] == currentUserId()) return true;
        final copy = await _client.from('recipe_copies')
            .select('id').eq('recipe_id', recipeId).eq('user_id', currentUserId()).maybeSingle();
        return copy != null;
      } catch (_) {
        return false;
      }
    }
  }

  /// Copy a free recipe to user's collection.
  static Future<bool> copyFreeRecipe(String recipeId) async {
    try {
      final uid = currentUserId();
      await _client.from('recipe_copies').insert({
        'recipe_id': recipeId,
        'user_id': uid,
        'is_paid': false,
        'amount_cents': 0,
      });
      // Increment copy count
      await _client.rpc('increment_field', params: {
        'table_name': 'recipes',
        'field_name': 'copy_count',
        'row_id': recipeId,
      }).catchError((_) {});
      return true;
    } catch (e) {
      debugPrint('[RecipeMon] copyFreeRecipe error: $e');
      return false;
    }
  }

  /// Purchase a premium recipe.
  static Future<bool> purchaseRecipe(String recipeId, int priceCents) async {
    try {
      final uid = currentUserId();
      // In production: integrate payment gateway here
      // For now: record the copy with price
      await _client.from('recipe_copies').insert({
        'recipe_id': recipeId,
        'user_id': uid,
        'is_paid': true,
        'amount_cents': priceCents,
      });
      await _client.rpc('increment_field', params: {
        'table_name': 'recipes',
        'field_name': 'copy_count',
        'row_id': recipeId,
      }).catchError((_) {});
      return true;
    } catch (e) {
      debugPrint('[RecipeMon] purchaseRecipe error: $e');
      return false;
    }
  }

  /// Get recipe with full details.
  static Future<RecipeModel?> getRecipe(String recipeId) async {
    try {
      final data = await _client.from('recipes').select().eq('id', recipeId).single();
      return RecipeModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  /// Search recipes by title.
  static Future<List<RecipeModel>> searchRecipes(String query) async {
    try {
      final data = await _client
          .from('recipes')
          .select()
          .ilike('title', '%${query.trim()}%')
          .order('created_at', ascending: false)
          .limit(20);
      return (data as List).map((m) => RecipeModel.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }
}
