// Plately — Recipe Detail Screen
// =================================
// Full recipe view with hero header, ingredient checklist,
// and step-by-step cooking instructions.
// Fetches recipe_ingredients and recipe_steps from Supabase.

import 'package:flutter/material.dart';

import 'package:plately_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/widgets/shimmer_loading.dart';
import 'package:plately_app/core/widgets/slide_in_item.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_prep_screen.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/utils/l10n_helper.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  final String title;
  final String? description;
  final String? cuisine;
  final int? difficulty;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final double matchPct;
  final Color tierColor;
  final Set<String> ownedIngredientIds;
  final int? caloriesPerServing;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.title,
    this.description,
    this.cuisine,
    this.difficulty,
    this.prepTime,
    this.cookTime,
    this.servings,
    this.matchPct = 0,
    required this.tierColor,
    required this.ownedIngredientIds,
    this.caloriesPerServing,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _loading = true;
  bool _isTranslated = false;
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _steps = [];
  String _displayTitle = '';
  String? _displayDescription;
  String? _imageUrl;
  
  // Dynamic Nutrition
  int? _dynamicCalories;
  double? _dynamicProtein;
  double? _dynamicCarbs;
  double? _dynamicFat;

  // Feedback voting
  int _likes = 0;
  int _dislikes = 0;
  int _userVote = 0; // 1 = liked, -1 = disliked, 0 = no vote

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

    Future<void> _loadDetails() async {
    try {
      final supabase = Supabase.instance.client;
      final locale = Localizations.localeOf(context);
      final userLanguage = locale.languageCode;

      // 1. Fetch relational ingredients from recipe_ingredients + ingredients
      final ingredientData = await supabase
          .from('recipe_ingredients')
          .select('ingredient_id, quantity, unit, prep_note, is_optional, display_order, '
              'ingredients(id, canonical_name, display_name_en, display_name_ko, '
              'display_name_uz, display_name_uz_cyrl, display_name_ru, category)')
          .eq('recipe_id', widget.recipeId)
          .order('display_order', ascending: true);

      // 2. Fetch steps and image_url from the recipes table
      final recipeData = await supabase
          .from('recipes')
          .select('steps, image_url')
          .eq('id', widget.recipeId)
          .maybeSingle();

      // 3. Map relational ingredients to the format the UI expects
      final isUzCyrillic = userLanguage == 'uz' && locale.scriptCode == 'Cyrl';

      _ingredients = (ingredientData as List).map<Map<String, dynamic>>((ri) {
        final ing = ri['ingredients'] as Map<String, dynamic>? ?? {};
        // Pick the display name for the user's language
        String name;
        if (isUzCyrillic) {
          name = ing['display_name_uz_cyrl'] ?? ing['display_name_uz'] ?? ing['display_name_en'] ?? 'Unknown';
        } else {
          switch (userLanguage) {
            case 'ko':
              name = ing['display_name_ko'] ?? ing['display_name_en'] ?? 'Unknown';
              break;
            case 'uz':
              name = ing['display_name_uz'] ?? ing['display_name_en'] ?? 'Unknown';
              break;
            case 'ru':
              name = ing['display_name_ru'] ?? ing['display_name_en'] ?? 'Unknown';
              break;
            default:
              name = ing['display_name_en'] ?? 'Unknown';
          }
        }
        return {
          'name': name,
          'ingredient_id': ri['ingredient_id'],
          'quantity': ri['quantity'],
          'unit': ri['unit'] ?? '',
          'prep_note': ri['prep_note'] ?? '',
          'is_optional': ri['is_optional'] ?? false,
          'canonical_name': ing['canonical_name'],
          'category': ing['category'],
          // Keep original English name for AI translation fallback
          'name_en': ing['display_name_en'],
        };
      }).toList();

      _steps = List<Map<String, dynamic>>.from(recipeData?['steps'] ?? []);
      _displayTitle = widget.title;
      _displayDescription = widget.description;
      _imageUrl = recipeData?['image_url'] as String?;

      // 4. If not English, check for cached title/step translations
      if (userLanguage != 'en') {
        try {
          final transData = await supabase
              .from('recipe_translations')
              .select('*')
              .eq('recipe_id', widget.recipeId)
              .eq('language_code', userLanguage)
              .maybeSingle();

          if (transData != null && transData['translation_status'] == 'completed') {
            // Apply cached title and steps (ingredients already localized above)
            if (transData['title'] != null) _displayTitle = transData['title'];
            if (transData['short_description'] != null) {
              _displayDescription = transData['short_description'];
            }
            // Apply translated steps
            final translatedSteps = transData['steps'] as List<dynamic>?;
            if (translatedSteps != null) {
              for (int i = 0; i < _steps.length && i < translatedSteps.length; i++) {
                _steps[i]['translated_text'] = translatedSteps[i]['text'];
              }
            }
            _isTranslated = true;
          } else {
            _triggerBackgroundTranslation(userLanguage);
          }
        } catch (e) {
          debugPrint('DB Translation fetch failed: $e');
          _triggerBackgroundTranslation(userLanguage);
        }
      }

      // 5. Fetch dynamic nutrition data
      try {
        final calResult = await ApiService().getRecipeCalories(
          recipeId: widget.recipeId,
          servings: widget.servings ?? 2,
        );
        final totals = calResult['totals'];
        if (totals != null) {
          final s = widget.servings ?? 2;
          final totalCal = (totals['calories'] as num?)?.toInt() ?? 0;
          _dynamicCalories = totalCal > 0 ? (totalCal ~/ s) : null;
          
          _dynamicProtein = ((totals['protein_g'] as num?)?.toDouble() ?? 0) / s;
          _dynamicCarbs = ((totals['carbs_g'] as num?)?.toDouble() ?? 0) / s;
          _dynamicFat = ((totals['fat_g'] as num?)?.toDouble() ?? 0) / s;
        }
      } catch (e) {
        debugPrint('Failed to load dynamic nutrition: $e');
      }

      // 6. Load recipe sentiment votes
      await _loadSentiment();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSentiment() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Get all sentiment feedback for this recipe
      final response = await supabase
          .from('recipe_feedback')
          .select('rating, user_id')
          .eq('recipe_id', widget.recipeId)
          .eq('feedback_type', 'recipe_sentiment');

      final items = response as List;
      int likes = 0;
      int dislikes = 0;
      int userVote = 0;

      for (final item in items) {
        final rating = (item['rating'] as num?)?.toInt() ?? 0;
        if (rating > 0) likes++;
        if (rating < 0) dislikes++;
        if (userId != null && item['user_id'] == userId) {
          userVote = rating;
        }
      }

      if (mounted) {
        setState(() {
          _likes = likes;
          _dislikes = dislikes;
          _userVote = userVote;
        });
      }
    } catch (e) {
      debugPrint('Failed to load sentiment: $e');
    }
  }

  Future<void> _voteSentiment(int vote) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final locale = Localizations.localeOf(context).languageCode;

      // Toggle: if same vote, remove it
      final newVote = (_userVote == vote) ? 0 : vote;

      if (newVote == 0) {
        // Delete existing vote
        await supabase
            .from('recipe_feedback')
            .delete()
            .eq('recipe_id', widget.recipeId)
            .eq('user_id', userId)
            .eq('feedback_type', 'recipe_sentiment');
      } else {
        // Upsert: delete old then insert new
        await supabase
            .from('recipe_feedback')
            .delete()
            .eq('recipe_id', widget.recipeId)
            .eq('user_id', userId)
            .eq('feedback_type', 'recipe_sentiment');

        await supabase
            .from('recipe_feedback')
            .insert({
              'recipe_id': widget.recipeId,
              'user_id': userId,
              'feedback_type': 'recipe_sentiment',
              'rating': newVote,
              'locale': locale,
            });
      }

      // Update local state immediately
      setState(() {
        if (_userVote == 1) _likes--;
        if (_userVote == -1) _dislikes--;
        _userVote = newVote;
        if (newVote == 1) _likes++;
        if (newVote == -1) _dislikes++;
      });
    } catch (e) {
      debugPrint('Failed to vote: $e');
    }
  }

  void _showFeedbackReportSheet() {
    String? selectedCategory;
    final commentController = TextEditingController();
    int featureRating = 0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Header
                    Row(
                      children: [
                        Icon(Icons.feedback_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Report an Issue',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Help us improve this recipe by reporting any issues.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Category selection
                    Text(
                      'What\'s the issue?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FeedbackCategoryChip(
                          label: '🌐 Translation',
                          value: 'translation',
                          selected: selectedCategory == 'translation',
                          onTap: () => setSheetState(() => selectedCategory = 'translation'),
                        ),
                        _FeedbackCategoryChip(
                          label: '📝 Content',
                          value: 'content',
                          selected: selectedCategory == 'content',
                          onTap: () => setSheetState(() => selectedCategory = 'content'),
                        ),
                        _FeedbackCategoryChip(
                          label: '📸 Photo',
                          value: 'photo',
                          selected: selectedCategory == 'photo',
                          onTap: () => setSheetState(() => selectedCategory = 'photo'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Rating
                    Text(
                      'How would you rate this recipe overall?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starIndex = i + 1;
                        return GestureDetector(
                          onTap: () => setSheetState(() => featureRating = starIndex),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starIndex <= featureRating ? Icons.star : Icons.star_border,
                              color: starIndex <= featureRating
                                  ? Colors.amber
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 20),
                    // Comment
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tell us more about the issue...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (selectedCategory != null || featureRating > 0)
                            ? () async {
                                Navigator.pop(context);
                                try {
                                  final supabase = Supabase.instance.client;
                                  final userId = supabase.auth.currentUser?.id;
                                  final locale = Localizations.localeOf(context).languageCode;
                                  
                                  await supabase.from('recipe_feedback').insert({
                                    'recipe_id': widget.recipeId,
                                    'user_id': userId,
                                    'feedback_type': selectedCategory ?? 'feature_rating',
                                    'rating': featureRating > 0 ? featureRating : null,
                                    'comment': commentController.text.trim().isNotEmpty
                                        ? commentController.text.trim()
                                        : null,
                                    'locale': locale,
                                    'meta_data': {
                                      'recipe_title': widget.title,
                                      'cuisine': widget.cuisine,
                                    },
                                  });
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Thank you for your feedback! 🙏'),
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Failed to submit feedback: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to submit feedback'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        icon: Icon(Icons.send, size: 18),
                        label: Text('Submit Feedback'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Trigger AI translation via backend (runs in background, updates UI when done)
  Future<void> _triggerBackgroundTranslation(String lang) async {
    try {
      final api = ApiService();
      final ingText = _ingredients.map((i) {
        final name = i['name'] ?? 'Unknown';
        final qty = i['quantity'] ?? '';
        final unit = i['unit'] ?? '';
        return '- $qty $unit $name';
      }).join('\n');

      final stepsText = _steps.map((s) {
        final num = s['step_number'] ?? 0;
        final text = s['text'] ?? '';
        return '$num. $text';
      }).join('\n');

      final result = await api.translateRecipe(
        recipeId: widget.recipeId,
        title: widget.title,
        ingredients: ingText,
        steps: stepsText,
        targetLanguage: lang,
      );

      if (result['status'] == 'success' && mounted) {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) {
          _applyTranslation(data);
          setState(() => _isTranslated = true);
        }
      }
    } catch (e) {
      debugPrint('Background translation failed: $e');
      // Silent failure — user sees English, which is acceptable
    }
  }


  void _applyTranslation(Map<String, dynamic> data) {
    setState(() {
      if (data['title'] != null) _displayTitle = data['title'];
      if (data['description'] != null) _displayDescription = data['description'];
      
      try {
        final translatedIngs = data['ingredients'] as List<dynamic>?;
        if (translatedIngs != null) {
            for (int i = 0; i < _ingredients.length && i < translatedIngs.length; i++) {
                _ingredients[i]['translated_name'] = translatedIngs[i]['name'];
            }
        }

        final translatedSteps = data['steps'] as List<dynamic>?;
        if (translatedSteps != null) {
            for (int i = 0; i < _steps.length && i < translatedSteps.length; i++) {
                _steps[i]['translated_text'] = translatedSteps[i]['text'];
            }
        }
      } catch (e) {
         debugPrint('Failed to map translation: $e');
      }
    });
  }

  void _showAdjustPortionsDialog() {
    int newServings = widget.servings ?? 2;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Adjust Portions',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Current recipe makes ${widget.servings ?? "?"} servings.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: newServings > 1 ? () => setStateSB(() => newServings--) : null,
                        icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.primary, size: 32),
                      ),
                      SizedBox(width: 24),
                      Text(
                        '$newServings',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 24),
                      IconButton(
                        onPressed: () => setStateSB(() => newServings++),
                        icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 32),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _adjustWithAi(newServings);
                      },
                      icon: Icon(Icons.auto_awesome),
                      label: Text(AppLocalizations.of(context)?.scaleToNServings(newServings.toString()) ?? 'Scale to $newServings Servings'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _adjustWithAi(int newServings) async {
    final originalServings = widget.servings ?? 4;
    if (newServings == originalServings) return;

    final ratio = newServings / originalServings;

    setState(() {
      for (final ing in _ingredients) {
        final rawQty = ing['quantity'];
        if (rawQty != null) {
          final qty = (rawQty is num) ? rawQty.toDouble() : (double.tryParse('$rawQty') ?? 0);
          ing['quantity'] = (qty * ratio * 100).round() / 100.0; // round to 2 decimals
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scaled to $newServings servings ✓'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get _totalTime => (widget.prepTime ?? 0) + (widget.cookTime ?? 0);

  Future<Map<String, dynamic>> _fetchSubstitutes(String ingredientName, String recipeTitle) async {
    final api = ApiService();
    List<String> inventoryNames = [];
    if (widget.ownedIngredientIds.isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final res = await supabase
            .from('ingredients')
            .select('canonical_name')
            .inFilter('id', widget.ownedIngredientIds.toList());
        inventoryNames = (res as List).map((r) => r['canonical_name'] as String).toList();
      } catch (e) {
        debugPrint('Failed to load inventory names: $e');
      }
    }
    return api.getSubstitution(
      ingredient: ingredientName,
      recipeContext: recipeTitle,
      inventoryIngredients: inventoryNames.isNotEmpty ? inventoryNames : null,
    );
  }

  void _applySwap(String oldName, String newName, String ratioStr) {
    setState(() {
      for (var ing in _ingredients) {
        final currentName = ing['translated_name'] ?? ing['name'];
        if (currentName == oldName) {
          ing['translated_name'] = newName;
          ing['name'] = newName;
          ing['prep_note'] = 'Swapped from $oldName ($ratioStr)';
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Swapped $oldName with $newName!'),
        backgroundColor: Colors.green,
      )
    );
  }

  void _showSubstitutionSheet(String ingredientName, String recipeTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.65,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchSubstitutes(ingredientName, recipeTitle),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                  SizedBox(height: 16),
                  Text(
                    'Finding substitutes for $ingredientName...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Could not find substitutes',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  SizedBox(height: 24),
                ],
              );
            }

            final data = snapshot.data ?? {};
            final substitutes = (data['substitutes'] as List?) ?? [];

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.primary, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Substitutes for "$ingredientName"',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Substitution cards
                  if (substitutes.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No substitutes found for this recipe context.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    )
                  else
                    ...substitutes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final sub = entry.value as Map<String, dynamic>;
                      final subName = sub['name'] ?? sub['substitute'] ?? 'Unknown';
                      final ratio = sub['ratio'] ?? sub['swap_ratio'] ?? '1:1';
                      final notes = sub['notes'] ?? sub['reason'] ?? '';
                      final isAvailable = sub['available'] == true;

                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: idx == 0 ? 0.4 : 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank badge
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subName.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (notes.toString().isNotEmpty)
                                    Text(
                                      notes.toString(),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            // Actions column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ratio.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (isAvailable)
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _applySwap(ingredientName, subName.toString(), ratio.toString());
                                    },
                                    icon: Icon(Icons.check_circle_outline, size: 14),
                                    label: Text('Swap'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      minimumSize: Size(0, 28),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  )
                                else
                                  Text('Could have swapped with this...', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                ),
                onPressed: () => _showFeedbackReportSheet(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Recipe-specific image or gradient fallback
                  if (_imageUrl != null && _imageUrl!.isNotEmpty)
                    Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.tierColor.withValues(alpha: 0.4),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.tierColor.withValues(alpha: 0.4),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  // Gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.4),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        stops: [0.0, 0.75, 1.0],
                      ),
                    ),
                  ),
                  // Content overlay
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(60, 16, 20, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Match badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: widget.tierColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.tierColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${(widget.matchPct * 100).toInt()}% Match',
                            style: TextStyle(
                              color: widget.tierColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        // Title
                        Text(
                          _displayTitle,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        if (_displayDescription != null &&
                            _displayDescription!.isNotEmpty) ...[
                          SizedBox(height: 6),
                          Text(
                            _displayDescription!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),

          // ── Quick Info Chips ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (widget.cuisine != null && widget.cuisine!.isNotEmpty)
                    _QuickChip(icon: Icons.public, label: L10nHelper.translateCuisine(widget.cuisine!, Localizations.localeOf(context))),
                  if (_totalTime > 0)
                    _QuickChip(icon: Icons.timer, label: '$_totalTime ${AppLocalizations.of(context)?.min_tag ?? "min"}'),
                  if (widget.servings != null)
                    _QuickChip(
                      icon: Icons.people,
                      label: '${widget.servings} ${AppLocalizations.of(context)?.servings_tag ?? "servings"}',
                    ),
                  if (widget.difficulty != null)
                    _QuickChip(
                      icon: Icons.signal_cellular_alt,
                      label: '${'⚡' * widget.difficulty!} ${AppLocalizations.of(context)?.difficulty_tag ?? "Difficulty"}',
                    ),
                  if (_dynamicCalories != null && _dynamicCalories! > 0)
                    _QuickChip(
                      icon: Icons.local_fire_department,
                      label: '$_dynamicCalories ${L10nHelper.translateNutritionLabel('kcal/srv', Localizations.localeOf(context).languageCode)}',
                    )
                  else if (widget.caloriesPerServing != null && widget.caloriesPerServing! > 0)
                    _QuickChip(
                      icon: Icons.local_fire_department,
                      label: '${widget.caloriesPerServing} ${L10nHelper.translateNutritionLabel('kcal/srv', Localizations.localeOf(context).languageCode)}',
                    ),
                  if (_dynamicProtein != null && _dynamicProtein! > 0)
                    _QuickChip(icon: Icons.fitness_center, label: '${_dynamicProtein!.toStringAsFixed(1)}${L10nHelper.translateNutritionLabel('g', Localizations.localeOf(context).languageCode)} ${L10nHelper.translateNutritionLabel('P', Localizations.localeOf(context).languageCode)}', color: Colors.blueAccent),
                  if (_dynamicCarbs != null && _dynamicCarbs! > 0)
                    _QuickChip(icon: Icons.bolt, label: '${_dynamicCarbs!.toStringAsFixed(1)}${L10nHelper.translateNutritionLabel('g', Localizations.localeOf(context).languageCode)} ${L10nHelper.translateNutritionLabel('C', Localizations.localeOf(context).languageCode)}', color: Colors.amber),
                  if (_dynamicFat != null && _dynamicFat! > 0)
                    _QuickChip(icon: Icons.water_drop, label: '${_dynamicFat!.toStringAsFixed(1)}${L10nHelper.translateNutritionLabel('g', Localizations.localeOf(context).languageCode)} ${L10nHelper.translateNutritionLabel('F', Localizations.localeOf(context).languageCode)}', color: Colors.orangeAccent),
                ],
              ),
            ),
          ),

          // ── Recipe Sentiment Voting ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    SizedBox(width: 8),
                    Text(
                      'Rate this recipe',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    // Thumbs up
                    GestureDetector(
                      onTap: () => _voteSentiment(1),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _userVote == 1
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _userVote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                              size: 18,
                              color: _userVote == 1
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            if (_likes > 0) ...[
                              SizedBox(width: 4),
                              Text(
                                '$_likes',
                                style: TextStyle(
                                  color: _userVote == 1
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Thumbs down
                    GestureDetector(
                      onTap: () => _voteSentiment(-1),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _userVote == -1
                              ? Colors.redAccent.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _userVote == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                              size: 18,
                              color: _userVote == -1
                                  ? Colors.redAccent
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            if (_dislikes > 0) ...[
                              SizedBox(width: 4),
                              Text(
                                '$_dislikes',
                                style: TextStyle(
                                  color: _userVote == -1
                                      ? Colors.redAccent
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Loading / Content ────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(child: RecipeListSkeleton())
          else ...[
            // ── Ingredients Section ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.checklist,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.ingredientsWithCount(_ingredients.length.toString()) ?? 'Ingredients (${_ingredients.length})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: _showAdjustPortionsDialog,
                      icon: Icon(Icons.auto_awesome, size: 16),
                      label: Text(AppLocalizations.of(context)?.scale ?? 'Scale'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ing = _ingredients[index];
                  
                  final name = ing['translated_name'] ?? ing['name'] ?? 'Unknown';
                  final ingId = ing['ingredient_id'] ?? '';
                  final qty = ing['quantity'];
                  final unit = ing['unit'] ?? '';
                  final isOptional = ing['is_optional'] == true;
                  final prepNote = ing['prep_note'] ?? '';
                  final isOwned = widget.ownedIngredientIds.contains(ingId);

                  return SlideInItem(
                    delay: index * 50,
                    child: _IngredientRow(
                      name: name,
                      quantity: '$qty ${L10nHelper.translateUnit(unit, Localizations.localeOf(context).languageCode)}',
                      prepNote: L10nHelper.translatePrepNote(prepNote, Localizations.localeOf(context).languageCode),
                      isOptional: isOptional,
                      isOwned: isOwned,
                      onSubstitute: (!isOwned && !isOptional)
                          ? () => _showSubstitutionSheet(name, widget.title)
                          : null,
                    ),
                  );
                }, childCount: _ingredients.length),
              ),
            ),

            // ── Add Missing to Shopping List Button ────────────────
            if (_ingredients.any((ing) {
              final id = ing['ingredient_id'];
              return !widget.ownedIngredientIds.contains(id) &&
                  ing['is_optional'] != true;
            }))
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final missingItems = _ingredients.where((ing) {
                        final id = ing['ingredient_id'];
                        return !widget.ownedIngredientIds.contains(id) &&
                            ing['is_optional'] != true;
                      }).toList();

                      if (missingItems.isEmpty) return;

                      final insertData = missingItems.map((ing) {
                        
                        final name = ing['translated_name'] ?? ing['name'] ?? 'Unknown';
                        return {
                          'user_id': currentUserId(),
                          'ingredient_name': name,
                          'quantity': ing['quantity'],
                          'unit': ing['unit'],
                          'is_purchased': false,
                        };
                      }).toList();

                      try {
                        await Supabase.instance.client
                            .from('shopping_list')
                            .insert(insertData);
                            
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)?.addedMissingItemsToShoppingList ?? 'Added missing items to Shopping List!'),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)?.failedToAddItemsX(e.toString()) ?? 'Failed to add items: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.shopping_cart_outlined, size: 20),
                    label: Text(
                      AppLocalizations.of(context)?.addMissingToShoppingList ?? 'Add missing to Shopping List',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

            // ── Steps Section ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 28, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      color: widget.tierColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.cookingStepsWithCount(_steps.length.toString()) ?? 'Cooking Steps (${_steps.length})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_steps.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_fix_high,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No steps available yet',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final step = _steps[index];
                    final isLast = index == _steps.length - 1;
                    return SlideInItem(
                      delay: (_ingredients.length + index) * 50,
                      child: _StepCard(
                        stepNumber: step['step_number'] ?? (index + 1),
                        humanText: step['translated_text'] ?? step['text'] ?? '',
                        estimatedSeconds: step['timer_seconds'],
                        requiresAttention: step['requires_attention'] == true,
                        tierColor: widget.tierColor,
                        isLast: isLast,
                      ),
                    );
                  }, childCount: _steps.length),
                ),
              ),

            // ── "I Cooked This" Button ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      final api = ApiService();
                      await api.recordCook(
                        userId: currentUserId(),
                        recipeId: widget.recipeId,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.celebration, color: Theme.of(context).colorScheme.onSurface, size: 20),
                              SizedBox(width: 8),
                              Text(AppLocalizations.of(context)?.recordedTasteProfileEvolving ?? 'Recorded! Your taste profile is evolving 🧠'),
                            ],
                          ),
                          backgroundColor: Theme.of(context).colorScheme.tertiary,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)?.failedToRecordX(e.toString()) ?? 'Failed to record: $e')),
                      );
                    }
                  },
                  icon: Icon(Icons.restaurant, size: 20),
                  label: Text(
                    AppLocalizations.of(context)?.iCookedThis ?? 'I Cooked This!',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom spacing ─────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _steps.isNotEmpty
          ? SlideInItem(
              delay: 300,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipePrepScreen(
                            recipeId: widget.recipeId,
                            title: widget.title,
                            originalServings: widget.servings ?? 4,
                            ingredients: _ingredients,
                            steps: _steps,
                            ownedIngredientIds: widget.ownedIngredientIds,
                            matchPct: widget.matchPct,
                            tierColor: widget.tierColor,
                            caloriesPerServing: widget.caloriesPerServing,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    icon: Icon(Icons.play_arrow, size: 24),
                    label: Text(
                      AppLocalizations.of(context)?.startCooking ?? 'Start Cooking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ── Quick Info Chip ─────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _QuickChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Ingredient Row ──────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  final String name;
  final String quantity;
  final String prepNote;
  final bool isOptional;
  final bool isOwned;
  final VoidCallback? onSubstitute;

  const _IngredientRow({
    required this.name,
    required this.quantity,
    required this.prepNote,
    required this.isOptional,
    required this.isOwned,
    this.onSubstitute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwned
              ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Owned / Missing indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isOwned
                  ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOwned ? Icons.check : Icons.shopping_cart_outlined,
              size: 16,
              color: isOwned ? Theme.of(context).colorScheme.tertiary : Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          // Name + prep note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOptional) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.optional_tag ?? 'optional',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
                if (prepNote.isNotEmpty)
                  Text(
                    prepNote,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Swap button for missing ingredients
          if (!isOwned && !isOptional && onSubstitute != null) ...[
            InkWell(
              onTap: onSubstitute,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz, size: 14, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 3),
                    Text(
                      AppLocalizations.of(context)?.swapButton ?? 'Swap',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          // Quantity
          Text(
            quantity,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Card ───────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String humanText;
  final int? estimatedSeconds;
  final bool requiresAttention;
  final Color tierColor;
  final bool isLast;

  const _StepCard({
    required this.stepNumber,
    required this.humanText,
    this.estimatedSeconds,
    required this.requiresAttention,
    required this.tierColor,
    required this.isLast,
  });

  String get _timeLabel {
    if (estimatedSeconds == null) return '';
    if (estimatedSeconds! < 60) return '${estimatedSeconds}s';
    final min = estimatedSeconds! ~/ 60;
    final sec = estimatedSeconds! % 60;
    return sec > 0 ? '${min}m ${sec}s' : '${min}m';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: tierColor.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Step content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    humanText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      if (_timeLabel.isNotEmpty) ...[
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        SizedBox(width: 4),
                        Text(
                          _timeLabel,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: requiresAttention
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              requiresAttention ? '👨‍🍳' : '🤖',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            Text(
                              requiresAttention ? (AppLocalizations.of(context)?.handsOn ?? 'Hands-on') : (AppLocalizations.of(context)?.automatic ?? 'Automatic'),
                              style: TextStyle(
                                color: requiresAttention
                                    ? Colors.orange
                                    : Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feedback Category Chip ──────────────────────────────────────────

class _FeedbackCategoryChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  
  const _FeedbackCategoryChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
