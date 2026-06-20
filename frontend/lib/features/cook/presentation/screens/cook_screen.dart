// Plately — Cook Screen
// =======================
// Displays recipe recommendations sorted into 5 tiers by ingredient match %.
// Queries recipes + recipe_ingredients from Supabase, compares against the
// user's inventory, and computes a match score.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/theme/app_theme.dart';
import 'package:plately_app/core/widgets/shimmer_loading.dart';
import 'package:plately_app/core/widgets/slide_in_item.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/utils/l10n_helper.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_detail_screen.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_import_screen.dart';
import 'package:plately_app/features/cook/presentation/screens/my_recipes_screen.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_prep_screen.dart';
import 'package:plately_app/core/services/cache_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/core/services/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plately_app/core/services/tutorial_controller.dart';

class CookScreen extends ConsumerStatefulWidget {
  const CookScreen({super.key});

  @override
  ConsumerState<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends ConsumerState<CookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  // Recipes grouped by tier key ('1'–'5')
  Map<String, List<Map<String, dynamic>>> _tiers = {};
  Set<String> _ownedIngredientIds = {};

  Map<String, List<Map<String, dynamic>>> get _displayTiers {
    final tutorialState = ref.watch(tutorialControllerProvider);
    if (tutorialState != TutorialState.none) {
      return {
        '1': [{
          'id': 'tutorial-stir-fry',
          'title': 'Tutorial Chicken Stir-fry',
          'description': 'A quick and healthy chicken stir-fry packed with broccoli and savory garlic sauce.',
          'cuisine': 'Asian',
          'difficulty': 1,
          'prep_time_minutes': 10,
          'cook_time_minutes': 15,
          'servings': 2,
          'tags': ['Healthy', 'Stir-fry', 'Quick'],
          'match_pct': 1.0,
          'matched': 5,
          'total': 5,
          'missing': [],
          'image_url': 'https://images.unsplash.com/photo-1603105037880-880cd4edfb0d?w=400&q=80',
        }],
        '2': [{
          'id': 'tutorial-salmon',
          'title': 'Sesame Ginger Salmon',
          'description': 'Pan-seared salmon fillet glazed with soy sauce, sesame oil, and ginger.',
          'cuisine': 'Asian',
          'difficulty': 2,
          'prep_time_minutes': 10,
          'cook_time_minutes': 12,
          'servings': 2,
          'tags': ['Seafood', 'Omega-3'],
          'match_pct': 0.8,
          'matched': 4,
          'total': 5,
          'missing': ['Salmon Fillet'],
          'image_url': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400&q=80',
        }],
        '3': [{
          'id': 'tutorial-broccoli-soup',
          'title': 'Broccoli Cheddar Soup',
          'description': 'Rich and creamy soup featuring fresh broccoli and cheddar cheese.',
          'cuisine': 'American',
          'difficulty': 2,
          'prep_time_minutes': 15,
          'cook_time_minutes': 20,
          'servings': 4,
          'tags': ['Soup', 'Comfort Food'],
          'match_pct': 0.6,
          'matched': 3,
          'total': 5,
          'missing': ['Cheddar Cheese', 'Chicken Broth'],
          'image_url': 'https://images.unsplash.com/photo-1607532941433-304659e8198a?w=400&q=80',
        }],
        '4': [{
          'id': 'tutorial-garlic-bread',
          'title': 'Garlic Bread',
          'description': 'Crispy toasted baguette brushed with garlic, butter, and sesame oil.',
          'cuisine': 'Italian',
          'difficulty': 1,
          'prep_time_minutes': 5,
          'cook_time_minutes': 8,
          'servings': 4,
          'tags': ['Appetizer', 'Quick'],
          'match_pct': 0.33,
          'matched': 1,
          'total': 3,
          'missing': ['Baguette', 'Butter'],
          'image_url': 'https://images.unsplash.com/photo-1573140247632-f8fd74997d5c?w=400&q=80',
        }],
        '5': [{
          'id': 'tutorial-lasagna',
          'title': 'Classic Beef Lasagna',
          'description': 'Layers of pasta sheets, savory beef sauce, and melted ricotta cheese.',
          'cuisine': 'Italian',
          'difficulty': 3,
          'prep_time_minutes': 30,
          'cook_time_minutes': 45,
          'servings': 6,
          'tags': ['Pasta', 'Bake', 'Classic'],
          'match_pct': 0.0,
          'matched': 0,
          'total': 8,
          'missing': ['Ground Beef', 'Lasagna Sheets', 'Tomato Sauce', 'Ricotta', 'Mozzarella', 'Parmesan', 'Onion', 'Egg'],
          'image_url': 'https://images.unsplash.com/photo-1574894709920-11b28e7367e3?w=400&q=80',
        }],
      };
    }
    return _tiers;
  }

  // Cuisine filter (Batch 2)
  String? _cuisineFilter;

  List<({String label, IconData icon, String key})> _getTierMeta(BuildContext context) => [
    (label: AppLocalizations.of(context)?.tierExplore ?? 'Explore', icon: Icons.explore, key: '5'),
    (label: AppLocalizations.of(context)?.tierPerfect ?? 'Perfect', icon: Icons.verified, key: '1'),
    (label: AppLocalizations.of(context)?.tierForYou ?? 'For You', icon: Icons.auto_awesome, key: '2'),
    (label: AppLocalizations.of(context)?.tierUseItUp ?? 'Use It Up', icon: Icons.timer, key: '3'),
    (label: AppLocalizations.of(context)?.tierAlmost ?? 'Almost', icon: Icons.shopping_cart_outlined, key: '4'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _lastLang = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLang = Localizations.localeOf(context).languageCode;
    if (_lastLang.isNotEmpty && _lastLang != currentLang) {
      _lastLang = currentLang;
      _fetchRecipes();
    } else if (_lastLang.isEmpty) {
      _lastLang = currentLang;
    }
  }

  // ── Data Loading ─────────────────────────────────────────────

  Future<void> _fetchRecipes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // 1. Get user's inventory ingredient names for matching
      final inventoryRows = await client
          .from('inventory_items')
          .select('ingredient_id, ingredients(display_name_en)')
          .eq('user_id', currentUserId());

      final ownedIds = (inventoryRows as List)
          .map((r) => r['ingredient_id'] as String)
          .toSet();

      // 2. Try server-side 6-signal scoring first (fastest, most accurate)
      bool useServerScoring = false;
      try {
        final api = ApiService();
        final serverResult = await api.getRecommendations(
          userId: currentUserId(),
          maxPerTier: 10,
          cuisineFilter: _cuisineFilter,
        ).timeout(const Duration(seconds: 3));

        final data = serverResult['data'] as Map<String, dynamic>?;
        if (data != null && data['tiers'] != null) {
          final serverTiers = data['tiers'] as Map<String, dynamic>;
          final Map<String, List<Map<String, dynamic>>> tiers = {
            '1': [], '2': [], '3': [], '4': [], '5': [],
          };

          for (final entry in serverTiers.entries) {
            final tierKey = entry.key;
            final recipes = entry.value as List? ?? [];
            tiers[tierKey] = recipes.map((r) {
              final recipe = r as Map<String, dynamic>;
              return {
                'id': recipe['recipe_id'],
                'title': recipe['title'],
                'description': '',
                'cuisine': recipe['cuisine'] ?? '',
                'difficulty': 1,
                'prep_time_minutes': recipe['prep_time_minutes'],
                'cook_time_minutes': null,
                'servings': null,
                'tags': <String>[],
                'match_pct': recipe['match_percentage'] ?? recipe['relevance_score'] ?? 0.0,
                'matched': 0,
                'total': 0,
                'missing': (recipe['missing_ingredients'] as List?)?.cast<String>() ?? [],
                'relevance_score': recipe['relevance_score'] ?? 0.0,
                'image_url': recipe['image_url'],
              };
            }).toList();
          }

          setState(() {
            _tiers = tiers;
            _ownedIngredientIds = ownedIds;
            _loading = false;
          });
          useServerScoring = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _autoNavigateToBestTier());
        }
      } on TimeoutException {
        debugPrint('[Cook] Server scoring timed out, falling back to client');
      } catch (e) {
        debugPrint('[Cook] Server scoring unavailable, falling back to client: $e');
      }

      if (useServerScoring) return;

      // 3. Fallback: Client-side scoring (RPC → direct query)
      List<dynamic> rpcResponse = [];
      bool useDirectQuery = false;

      try {
        rpcResponse = await client.rpc('get_recommended_recipes', params: {
          'p_user_id': currentUserId(),
          'p_limit': 50,
        });
        if (rpcResponse.isEmpty) useDirectQuery = true;
      } catch (_) {
        useDirectQuery = true;
      }

      List<Map<String, dynamic>> scored = [];
      
      final currentLang = AppSettings().locale.languageCode;
      Map<String, Map<String, dynamic>> translations = {};
      if (currentLang != 'en') {
        try {
          final transRows = await client
              .from('recipe_translations')
              .select('recipe_id, title, ingredients, translation_status')
              .eq('language_code', currentLang)
              .eq('translation_status', 'completed');
          for (final t in transRows) {
            translations[t['recipe_id']] = t;
          }
        } catch (_) {}
      }

      // Pre-fetch ALL recipe_ingredients in ONE query (avoid N+1)
      final allRiRows = await client
          .from('recipe_ingredients')
          .select('recipe_id, ingredient_id, ingredients(display_name_en, display_name_ko, display_name_uz, display_name_uz_cyrl, display_name_ru)');

      // Group by recipe_id
      final Map<String, List<Map<String, dynamic>>> riByRecipe = {};
      for (final ri in (allRiRows as List)) {
        final rid = ri['recipe_id'] as String;
        riByRecipe.putIfAbsent(rid, () => []);
        riByRecipe[rid]!.add(ri);
      }

      if (useDirectQuery) {
        // ── Direct Query Fallback ─────────────────────────────
        final recipeRows = await client
            .from('recipes')
            .select('id, title, description, cuisine, difficulty, prep_time_minutes, cook_time_minutes, servings, tags, image_url')
            .limit(200);

        for (final recipe in (recipeRows as List)) {
          final riRows = riByRecipe[recipe['id']] ?? [];
          final totalRequired = riRows.length;
          final t = translations[recipe['id']];

          int matchedCount = 0;
          final List<String> missing = [];
          for (final ri in riRows) {
            final ingId = ri['ingredient_id'] as String;
            final ingData = ri['ingredients'] as Map?;
            final displayName = _localizedIngName(ingData, currentLang);

            if (ownedIds.contains(ingId)) {
              matchedCount++;
            } else {
              missing.add(displayName);
            }
          }
          final matchPct = totalRequired > 0 ? matchedCount / totalRequired : 0.0;

          scored.add({
            'id': recipe['id'],
            'title': t?['title'] ?? recipe['title'],
            'description': recipe['description'],
            'cuisine': recipe['cuisine'] ?? '',
            'difficulty': recipe['difficulty'] ?? 1,
            'prep_time_minutes': recipe['prep_time_minutes'],
            'cook_time_minutes': recipe['cook_time_minutes'],
            'servings': recipe['servings'],
            'tags': (recipe['tags'] as List?)?.cast<String>() ?? [],
            'match_pct': matchPct,
            'matched': matchedCount,
            'total': totalRequired,
            'missing': missing,
            'image_url': recipe['image_url'],
          });
        }
      } else {
        // ── RPC Path ──────────────────────────────────────────
        final recipeIds = rpcResponse.map((r) => r['recipe_id'] as String).toList();

        final recipeRows = await client
            .from('recipes')
            .select('id, title, description, cuisine, difficulty, prep_time_minutes, cook_time_minutes, servings, tags, image_url')
            .inFilter('id', recipeIds);

        for (final r in rpcResponse) {
          final recipeId = r['recipe_id'];
          final scoreRaw = r['match_score'];
          double score = 0.0;
          if (scoreRaw is num) {
            score = scoreRaw.toDouble();
          } else if (scoreRaw is String) {
            score = double.tryParse(scoreRaw) ?? 0.0;
          }

          final recipeDetails = (recipeRows as List).firstWhere(
              (row) => row['id'] == recipeId,
              orElse: () => null);

          if (recipeDetails == null) continue;

          final riRows = riByRecipe[recipeId] ?? [];
          final totalRequired = riRows.length;
          final t = translations[recipeDetails['id']];

          int matchedCount = 0;
          final List<String> missing = [];
          for (final ri in riRows) {
            final ingId = ri['ingredient_id'] as String;
            final ingData = ri['ingredients'] as Map?;
            final displayName = _localizedIngName(ingData, currentLang);

            if (ownedIds.contains(ingId)) {
              matchedCount++;
            } else {
              missing.add(displayName);
            }
          }

          scored.add({
            'id': recipeDetails['id'],
            'title': t?['title'] ?? recipeDetails['title'],
            'description': recipeDetails['description'],
            'cuisine': recipeDetails['cuisine'] ?? '',
            'difficulty': recipeDetails['difficulty'] ?? 1,
            'prep_time_minutes': recipeDetails['prep_time_minutes'],
            'cook_time_minutes': recipeDetails['cook_time_minutes'],
            'servings': recipeDetails['servings'],
            'tags': (recipeDetails['tags'] as List?)?.cast<String>() ?? [],
            'match_pct': score,
            'matched': matchedCount,
            'total': totalRequired,
            'missing': missing,
            'image_url': recipeDetails['image_url'],
          });
        }
      }

      // 3. Sort into 5 Tiers
      final Map<String, List<Map<String, dynamic>>> tiers = {
        '1': [], '2': [], '3': [], '4': [], '5': [],
      };

      for (final r in scored) {
        final score = (r['match_pct'] as num).toDouble();
        if (score >= 0.90) {
          tiers['1']!.add(r);
        } else if (score >= 0.70) {
          tiers['2']!.add(r);
        } else if (score >= 0.50) {
          tiers['3']!.add(r);
        } else if (score >= 0.30) {
          tiers['4']!.add(r);
        } else {
          tiers['5']!.add(r);
        }
      }

      setState(() {
        _tiers = tiers;
        _ownedIngredientIds = ownedIds;
        _loading = false;
      });

      // Auto-navigate to the first non-empty tier
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoNavigateToBestTier());

      // Trigger batch title translation for non-English users
      if (currentLang != 'en') {
        _batchTranslateTitles(currentLang);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Auto-navigate to the first non-empty tier in display order.
  void _autoNavigateToBestTier() {
    final displayOrder = _getTierMeta(context);
    for (int i = 0; i < displayOrder.length; i++) {
      final key = displayOrder[i].key;
      if ((_displayTiers[key] ?? []).isNotEmpty) {
        if (_tabController.index != i) {
          _tabController.animateTo(i);
        }
        return;
      }
    }
  }

  /// Batch-translate recipe titles in background for smooth list view
  Future<void> _batchTranslateTitles(String lang) async {
    try {
      // Collect all recipe IDs that still have English titles
      final allIds = <String>[];
      for (final tier in _displayTiers.values) {
        for (final r in tier) {
          allIds.add(r['id'] as String);
        }
      }
      if (allIds.isEmpty) return;

      // Batch up to 20 at a time
      final api = ApiService();
      for (int i = 0; i < allIds.length; i += 20) {
        final batch = allIds.sublist(i, (i + 20).clamp(0, allIds.length));
        try {
          final result = await api.translateTitles(
            recipeIds: batch,
            targetLanguage: lang,
          );
          final data = result['data'] as Map<String, dynamic>?;
          if (data != null && mounted) {
            setState(() {
              for (final tier in _displayTiers.values) {
                for (final r in tier) {
                  final t = data[r['id']];
                  if (t != null && t['title'] != null) {
                    r['title'] = t['title'];
                  }
                }
              }
            });
          }
        } catch (e) {
          debugPrint('[Cook] Batch translate failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[Cook] Batch title translation error: $e');
    }
  }

  /// Pick the localized ingredient name from joined data.
  String _localizedIngName(Map? ingData, String langCode) {
    if (ingData == null) return 'Unknown';
    final locale = AppSettings().locale;
    if (locale.languageCode == 'uz' && locale.scriptCode == 'Cyrl') {
      return ingData['display_name_uz_cyrl'] ?? ingData['display_name_uz'] ?? ingData['display_name_en'] ?? 'Unknown';
    }
    switch (langCode) {
      case 'ko': return ingData['display_name_ko'] ?? ingData['display_name_en'] ?? 'Unknown';
      case 'uz': return ingData['display_name_uz'] ?? ingData['display_name_en'] ?? 'Unknown';
      case 'ru': return ingData['display_name_ru'] ?? ingData['display_name_en'] ?? 'Unknown';
      default: return ingData['display_name_en'] ?? 'Unknown';
    }
  }

  void _openSearch(BuildContext context) {
    // Collect all recipes across tiers for search
    final allRecipes = <Map<String, dynamic>>[];
    for (final tier in _displayTiers.values) {
      allRecipes.addAll(tier);
    }
    showSearch(
      context: context,
      delegate: _RecipeSearchDelegate(
        allRecipes: allRecipes,
        ownedIngredientIds: _ownedIngredientIds,
      ),
    );
  }

  void _openAiGenerate(BuildContext context) async {
    // Get user's inventory ingredient names
    final client = Supabase.instance.client;
    final rows = await client
        .from('inventory_items')
        .select('ingredients(display_name_en)')
        .eq('user_id', currentUserId());
    final ingredientNames = (rows as List)
        .map((r) => r['ingredients']?['display_name_en'] as String?)
        .whereType<String>()
        .toList();

    if (!context.mounted) return;
    if (ingredientNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.auto_addSomeIngredientsToYourShelfFirst ?? 'Add some ingredients to your shelf first!')),
      );
      return;
    }

    // Show options sheet before generating
    String? selectedCuisine;
    int selectedDifficulty = 2;
    int selectedMaxTime = 30;
    int selectedServings = 2;
    bool shelfOnly = false;

    final shouldGenerate = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: 16),
            Row(children: [
              Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.auto_aiRecipeGenerator ?? 'AI Recipe Generator',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ]),
            SizedBox(height: 6),
            Text('Using your ${ingredientNames.length} ingredients',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
            SizedBox(height: 20),

            // Cuisine
            _aiOptionRow('Cuisine', DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedCuisine,
                isDense: true,
                dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                hint: Text(AppLocalizations.of(context)?.auto_any ?? 'Any', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                items: [null, 'Korean', 'Italian', 'Japanese', 'Mexican', 'Chinese', 'Indian', 'American']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c ?? 'Any')))
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedCuisine = v),
              ),
            )),
            SizedBox(height: 12),

            // Max time
            _aiOptionRow('Max Time', Row(children: [
              Text('$selectedMaxTime min',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
              Expanded(
                child: Slider(
                  value: selectedMaxTime.toDouble(),
                  min: 10, max: 120, divisions: 11,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) => setSheetState(() => selectedMaxTime = v.round()),
                ),
              ),
            ])),
            SizedBox(height: 12),

            // Servings
            _aiOptionRow('Servings', Row(children: [
              ...List.generate(4, (i) {
                final s = i + 1;
                final active = s == selectedServings;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setSheetState(() => selectedServings = s),
                    child: Container(
                      width: 36, height: 36, alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
                      ),
                      child: Text('$s',
                          style: TextStyle(
                              color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  ),
                );
              }),
            ])),
            SizedBox(height: 16),

            // Shelf Only toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
              ),
              child: SwitchListTile(
                value: shelfOnly,
                onChanged: (v) => setSheetState(() => shelfOnly = v),
                title: Text(AppLocalizations.of(context)?.auto_shelfOnly ?? 'Shelf Only',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                subtitle: Text(
                  shelfOnly
                      ? 'Only use ingredients from your shelf'
                      : 'AI may suggest extra ingredients',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11),
                ),
                secondary: Icon(
                  shelfOnly ? Icons.kitchen : Icons.add_shopping_cart,
                  color: shelfOnly ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                activeThumbColor: Theme.of(context).colorScheme.primary,
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: Icon(Icons.auto_awesome, size: 18),
                label: Text(AppLocalizations.of(context)?.auto_generateRecipe ?? 'Generate Recipe'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 8),
          ]),
        ),
      ),
    );

    if (shouldGenerate != true || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: 8),
          CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          SizedBox(height: 20),
          Text('Generating your ${selectedCuisine ?? ''} recipe...',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14)),
        ]),
      ),
    );

    try {
      final api = ApiService();
      final result = await api.generateRecipe(
        ingredients: ingredientNames,
        cuisine: selectedCuisine,
        maxTimeMinutes: selectedMaxTime,
        difficulty: selectedDifficulty,
        servings: selectedServings,
        shelfOnly: shelfOnly,
        locale: AppLocalizations.of(context)?.localeName,
      );
      api.dispose();
      if (!context.mounted) return;
      Navigator.of(context).pop();

      final data = result['data'] ?? {};

      // Show formatted result bottom sheet
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _GeneratedRecipeSheet(recipeData: data),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      debugPrint('AI generate recipe error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.onSurface, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(
              'AI is temporarily unavailable. Please try again later.',
              style: TextStyle(fontSize: 13),
            )),
          ]),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _aiOptionRow(String label, Widget child) {
    return Row(children: [
      SizedBox(
        width: 80,
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
      Expanded(child: child),
    ]);
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.whatToCook ?? 'What to Cook?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _openSearch(context),
            tooltip: 'Search recipes',
          ),
          IconButton(
            icon: Icon(Icons.auto_awesome),
            onPressed: () => _openAiGenerate(context),
            tooltip: 'AI Generate',
          ),
          IconButton(
            icon: Icon(Icons.post_add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeImportScreen()));
            },
            tooltip: AppLocalizations.of(context)?.auto_importRecipe ?? 'Import Recipe',
          ),
          IconButton(
            icon: Icon(Icons.menu_book),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRecipesScreen()));
            },
            tooltip: 'My Recipes',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRecipes,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
          tabAlignment: TabAlignment.start,
          tabs: _getTierMeta(context).map((t) {
            final count = (_displayTiers[t.key] ?? []).length;
            return Tab(
              icon: Icon(t.icon, size: 18),
              text: count > 0 ? '${t.label} ($count)' : t.label,
            );
          }).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isTutorial = ref.watch(tutorialControllerProvider) != TutorialState.none;
    if (_loading && !isTutorial) {
      return const RecipeListSkeleton();
    }

    if (_error != null && !isTutorial) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              SizedBox(height: 16),
              Text(
                'Couldn\'t load recipes',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _fetchRecipes,
                icon: Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)?.auto_retry ?? 'Retry'),
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: _getTierMeta(context).map((t) => _buildTierList(t.key, t.label)).toList(),
    );
  }

  /// All unique cuisines across all loaded recipes.
  /// Uzbek is always pinned as the first option.
  static const _pinnedCuisines = ['Uzbek', 'Korean', 'Japanese', 'Italian', 'Mexican', 'Indian', 'Chinese'];
  List<String> get _allCuisines {
    final c = <String>{};
    for (final tier in _displayTiers.values) {
      for (final r in tier) {
        final cuisine = (r['cuisine'] ?? '').toString().trim();
        if (cuisine.isNotEmpty) c.add(cuisine);
      }
    }
    // Ensure pinned cuisines are always present
    c.addAll(_pinnedCuisines);
    final pinned = _pinnedCuisines.where((p) => c.contains(p)).toList();
    final rest = (c.toList()..sort()).where((e) => !_pinnedCuisines.contains(e)).toList();
    return [...pinned, ...rest];
  }

  Widget _buildTierList(String tierKey, String tierLabel) {
    var recipes = _displayTiers[tierKey] ?? [];

    // Apply cuisine filter
    if (_cuisineFilter != null) {
      recipes = recipes
          .where((r) => (r['cuisine'] ?? '').toString().toLowerCase() ==
              _cuisineFilter!.toLowerCase())
          .toList();
    }

    if ((_displayTiers[tierKey] ?? []).isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu,
                size: 56, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            SizedBox(height: 12),
            Text(AppLocalizations.of(context)?.noTierRecipesYet(tierLabel) ?? 'No $tierLabel recipes yet',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 15)),
            SizedBox(height: 6),
            Text(AppLocalizations.of(context)?.auto_addItemsToYourShelfToGetRecommendations ?? 'Add items to your shelf to get recommendations',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRecipes,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          // Cuisine filter chips
          if (_allCuisines.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 2),
                  children: [
                    _cuisineChip(null, AppLocalizations.of(context)?.all ?? 'All'),
                    ..._allCuisines.map((c) => _cuisineChip(c, L10nHelper.translateCuisine(c, Localizations.localeOf(context)))),
                  ],
                ),
              ),
            ),

          // Empty filter result
          if (recipes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off, size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  SizedBox(height: 12),
                  Text(AppLocalizations.of(context)?.auto_noRecipesMatchThisCuisine ?? 'No recipes match this cuisine',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14)),
                  TextButton(
                    onPressed: () => setState(() => _cuisineFilter = null),
                    child: Text(AppLocalizations.of(context)?.auto_clearFilter ?? 'Clear filter'),
                  ),
                ]),
              ),
            ),

          // Recipe list
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SlideInItem(
                  delay: index * 80,
                  child: _RecipeCard(
                    recipe: recipes[index],
                    tierKey: tierKey,
                    ownedIngredientIds: _ownedIngredientIds,
                  ),
                ),
                childCount: recipes.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _cuisineChip(String? cuisine, String label) {
    final active = _cuisineFilter == cuisine;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: active,
        label: Text(label,
            style: TextStyle(
                color: active ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        onSelected: (_) => setState(() => _cuisineFilter = cuisine),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        checkmarkColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(
          color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        padding: EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

// ── Recipe Card Widget ─────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final String tierKey;
  final Set<String> ownedIngredientIds;

  const _RecipeCard({
    required this.recipe,
    required this.tierKey,
    required this.ownedIngredientIds,
  });

  Color get _tierColor {
    switch (tierKey) {
      case '1':
        return AppTheme.tier1;
      case '2':
        return AppTheme.tier2;
      case '3':
        return AppTheme.tier3;
      case '4':
        return AppTheme.tier4;
      default:
        return AppTheme.tier5;
    }
  }

  String _getTierBadge(BuildContext context) {
    switch (tierKey) {
      case '1':
        return AppLocalizations.of(context)?.tierBadge1 ?? '✅ Everything you need!';
      case '2':
        return AppLocalizations.of(context)?.tierBadge2 ?? '🔥 Recommended for you';
      case '3':
        return AppLocalizations.of(context)?.tierBadge3 ?? '⏰ Use expiring items';
      case '4':
        return AppLocalizations.of(context)?.tierBadge4 ?? '🛒 Just a few items away';
      default:
        return AppLocalizations.of(context)?.tierBadge5 ?? '🌍 Discover something new';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = recipe['title'] ?? 'Untitled';
    final description = recipe['description'] ?? '';
    final matchPct = ((recipe['match_pct'] ?? 0.0) as double) * 100;
    final matched = recipe['matched'] ?? 0;
    final total = recipe['total'] ?? 0;
    final missing = (recipe['missing'] as List?) ?? [];
    final cuisine = recipe['cuisine'] ?? '';
    final prepTime = recipe['prep_time_minutes'];
    final cookTime = recipe['cook_time_minutes'];
    final difficulty = recipe['difficulty'] ?? 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              recipeId: recipe['id'] as String,
              title: title,
              description: description,
              cuisine: cuisine,
              difficulty: difficulty as int?,
              prepTime: prepTime as int?,
              cookTime: cookTime as int?,
              servings: recipe['servings'] as int?,
              matchPct: recipe['match_pct'] as double? ?? 0.0,
              tierColor: _tierColor,
              ownedIngredientIds: ownedIngredientIds,
              caloriesPerServing: recipe['calories_per_serving'] as int?,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _tierColor.withValues(alpha: matchPct >= 90 ? 0.6 : 0.3),
            width: matchPct >= 90 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _tierColor.withValues(alpha: matchPct >= 90 ? 0.2 : 0.1),
              blurRadius: matchPct >= 90 ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image header
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    recipe['image_url']?.toString().isNotEmpty == true
                        ? recipe['image_url']
                        : _cuisineImageUrl(cuisine),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                alignment: Alignment.bottomRight,
                padding: EdgeInsets.all(10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tierColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${matchPct.toInt()}%',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title — AnimatedSwitcher for smooth translation fade-in
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Recommendation Reason Badge
              SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getTierBadge(context),
                      style: TextStyle(
                        color: _tierColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Relevance score (if available from server scoring)
                  if (recipe['relevance_score'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tierColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${((recipe['relevance_score'] as num) * 100).toInt()}% fit',
                        style: TextStyle(
                          color: _tierColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              // Relevance score bar
              if (recipe['relevance_score'] != null) ...[
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (recipe['relevance_score'] as num).toDouble().clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(_tierColor),
                  ),
                ),
              ],

              if (description.isNotEmpty) ...[
                SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],

              SizedBox(height: 10),

              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.inventory_2,
                    label: AppLocalizations.of(context)?.nOfNIngredients(matched.toString(), total.toString()) ?? '$matched/$total ingredients',
                    color: matchPct >= 100
                        ? Theme.of(context).colorScheme.tertiary
                        : Colors.orange,
                  ),
                  if (cuisine.isNotEmpty)
                    _InfoChip(
                      icon: Icons.public,
                      label: L10nHelper.translateCuisine(cuisine, Localizations.localeOf(context)),
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                  if (prepTime != null)
                    _InfoChip(
                      icon: Icons.timer,
                      label: cookTime != null
                          ? '${prepTime + cookTime} ${AppLocalizations.of(context)?.min_tag ?? "min"}'
                          : '$prepTime ${AppLocalizations.of(context)?.min_tag ?? "min"}',
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                  _InfoChip(
                    icon: Icons.signal_cellular_alt,
                    label: '${'⚡' * (difficulty as int)} ${AppLocalizations.of(context)?.difficulty_tag ?? ""}'.trim(),
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                  ),
                ],
              ),

              // Missing ingredients
              if (missing.isNotEmpty) ...[
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 14,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.needLabel(missing.join(", ")) ?? 'Need: ${missing.join(", ")}',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }

  /// Maps cuisine names to category image URLs for the hero header.
  String _cuisineImageUrl(String cuisine) {
    const cuisineImages = <String, String>{
      'uzbek': 'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600&q=80',
      'korean': 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=600&q=80',
      'japanese': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=600&q=80',
      'chinese': 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600&q=80',
      'italian': 'https://images.unsplash.com/photo-1498579150354-977475b7ea0b?w=600&q=80',
      'indian': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=600&q=80',
      'mexican': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600&q=80',
      'american': 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=600&q=80',
      'thai': 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=600&q=80',
      'french': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&q=80',
      'mediterranean': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80',
    };
    return cuisineImages[cuisine.toLowerCase()] ??
        'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=600&q=80';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

// -- Search Delegate --

class _RecipeSearchDelegate extends SearchDelegate<void> {
  final List<Map<String, dynamic>> allRecipes;
  final Set<String> ownedIngredientIds;

  _RecipeSearchDelegate({
    required this.allRecipes,
    required this.ownedIngredientIds,
  }) : super(
          searchFieldLabel: 'Search recipes...',
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
      ),
      scaffoldBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  List<Map<String, dynamic>> _filterResults() {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return allRecipes.where((r) {
      final title = (r['title'] ?? '').toString().toLowerCase();
      final desc = (r['description'] ?? '').toString().toLowerCase();
      return title.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget buildResults(BuildContext context) => _buildResultsList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildResultsList(context);

  Widget _buildResultsList(BuildContext context) {
    final results = _filterResults();
    if (query.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
          SizedBox(height: 12),
          Text('Type to search ${allRecipes.length} recipes',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14)),
        ]),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
          SizedBox(height: 12),
          Text('No recipes matching "$query"',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14)),
        ]),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = results[index];
        final title = r['title'] ?? 'Untitled';
        final desc = (r['description'] ?? '').toString();
        final matchPct = r['match_pct'] ?? 0.0;
        final pctLabel = '${(matchPct * 100).round()}% match';
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
            subtitle: Text(
              desc.length > 80 ? '${desc.substring(0, 80)}...' : desc,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
              child: Text(pctLabel, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w700))),
            onTap: () {
              close(context, null);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(
                  recipeId: r['id'] ?? '',
                  title: r['title'] ?? 'Untitled',
                  description: r['description'],
                  cuisine: r['cuisine'],
                  difficulty: r['difficulty'],
                  prepTime: r['prep_time_minutes'],
                  cookTime: r['cook_time_minutes'],
                  servings: r['servings'],
                  matchPct: (r['match_pct'] ?? 0.0).toDouble(),
                  tierColor: Theme.of(context).colorScheme.primary,
                  ownedIngredientIds: ownedIngredientIds,
                  caloriesPerServing: r['calories_per_serving'] as int?,
                ),
              ));
            },
          ),
        );
      },
    );
  }
}

class _GeneratedRecipeSheet extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const _GeneratedRecipeSheet({required this.recipeData});

  @override
  State<_GeneratedRecipeSheet> createState() => _GeneratedRecipeSheetState();
}

class _GeneratedRecipeSheetState extends State<_GeneratedRecipeSheet> {
  bool _saving = false;

  Future<void> _saveRecipe() async {
    setState(() => _saving = true);
    try {
      final userId = currentUserId();
      CacheService().saveLocalRecipe(userId, widget.recipeData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to My Recipes!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cookNow() {
    Navigator.pop(context);
    
    // Map JSON steps to the format expected by RecipePrepScreen
    final stepsList = (widget.recipeData['steps'] as List?) ?? [];
    final mappedSteps = stepsList.map<Map<String, dynamic>>((s) {
      if (s is Map) return Map<String, dynamic>.from(s);
      return {'text': s.toString()};
    }).toList();

    // Map ingredients
    final aiIngredients = (widget.recipeData['ingredients'] as List?) ?? [];
    final mappedIngredients = aiIngredients.map<Map<String, dynamic>>((ing) {
      if (ing is Map) {
        return {
          'name': ing['name'] ?? 'Unknown',
          'quantity': ing['quantity'] ?? 1,
          'unit': ing['unit'] ?? '',
          'ingredient_id': 'ai_${DateTime.now().millisecondsSinceEpoch}',
        };
      }
      return {
        'name': ing.toString(),
        'quantity': 1,
        'unit': '',
        'ingredient_id': 'ai_${DateTime.now().millisecondsSinceEpoch}',
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePrepScreen(
          recipeId: 'ai_generated',
          title: widget.recipeData['title'] ?? 'AI Recipe',
          originalServings: widget.recipeData['servings'] ?? 2,
          ingredients: mappedIngredients,
          steps: mappedSteps,
          ownedIngredientIds: const <String>{}, // We don't have matching IDs since it's raw text
          matchPct: 100,
          tierColor: Theme.of(context).colorScheme.primary,
          caloriesPerServing: widget.recipeData['calories_per_serving'] ?? 400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.recipeData['title'] ?? 'AI Recipe';
    final desc = widget.recipeData['description'] ?? '';
    final stepsList = (widget.recipeData['steps'] as List?) ?? [];
    final aiIngredients = (widget.recipeData['ingredients'] as List?) ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                  if (desc.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(desc,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Ingredients
                  if (aiIngredients.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(AppLocalizations.of(context)?.auto_ingredients ?? '🧂 Ingredients',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...aiIngredients.map((ing) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Icon(Icons.circle, size: 6, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ing is Map ? '${ing['quantity'] ?? ''} ${ing['unit'] ?? ''} ${ing['name'] ?? ing}' : '$ing',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ]),
                        )),
                  ],

                  // Steps
                  if (stepsList.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(AppLocalizations.of(context)?.auto_steps ?? '👨‍🍳 Steps',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...List.generate(stepsList.length, (i) {
                      final step = stepsList[i];
                      final text = step is Map ? (step['text'] ?? '') : '$step';
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(text,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  SizedBox(height: 80), // Padding for buttons
                ],
              ),
            ),
            
            // Action Buttons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _saveRecipe,
                      icon: _saving 
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.bookmark_border),
                      label: Text(AppLocalizations.of(context)?.auto_save ?? 'Save'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _cookNow,
                      icon: Icon(Icons.restaurant),
                      label: Text(AppLocalizations.of(context)?.startCooking ?? 'Cook Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
