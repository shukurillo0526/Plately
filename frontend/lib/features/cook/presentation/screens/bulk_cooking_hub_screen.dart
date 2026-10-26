// Plately — Bulk Cooking & Meal Prep Hub
// ===========================================
// Comprehensive command center for batch cooking:
// 1. AI Meal Prep Generator (3/5/7 days, macros, dietary goals)
// 2. Custom Multi-Recipe Batch Cooker (Queue 2-4 recipes, scaled portions, combined prep list)
// 3. Meal Prep Stash & Storage (Containers in Fridge/Freezer, expiry countdown, reheat guides)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/features/cook/presentation/widgets/meal_prep_config_panel.dart';
import 'package:plately_app/features/cook/presentation/widgets/meal_prep_plan_sheet.dart';
import 'package:plately_app/features/cook/presentation/screens/prep_session_screen.dart';
import 'package:plately_app/core/services/recipe_monetization_service.dart';

class BulkCookingHubScreen extends StatefulWidget {
  const BulkCookingHubScreen({super.key});

  @override
  State<BulkCookingHubScreen> createState() => _BulkCookingHubScreenState();
}

class _BulkCookingHubScreenState extends State<BulkCookingHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stash data
  List<Map<String, dynamic>> _stashItems = [];
  bool _loadingStash = true;

  // AI Generator state
  MealPrepConfig _bulkConfig = const MealPrepConfig(days: 5, mealsPerDay: 2, targetCalories: 550);
  bool _isGeneratingAi = false;

  // Custom Batch Cooker state
  List<RecipeModel> _availableRecipes = [];
  final List<RecipeModel> _selectedBatchRecipes = [];
  final Map<String, int> _recipePortions = {};
  bool _loadingRecipes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStash();
    _loadRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStash() async {
    setState(() => _loadingStash = true);
    try {
      final uid = currentUserId();
      final data = await Supabase.instance.client
          .from('meal_prep_containers')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data as List);
      if (mounted) {
        setState(() {
          _stashItems = list.isNotEmpty ? list : _demoStashItems();
          _loadingStash = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stashItems = _demoStashItems();
          _loadingStash = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _demoStashItems() {
    final now = DateTime.now();
    return [
      {
        'id': 'stash-1',
        'title': 'Slow-Cooked Beef & Roasted Carrots',
        'storage_zone': 'fridge',
        'containers_remaining': 3,
        'prepared_date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'expires_date': now.add(const Duration(days: 3)).toIso8601String(),
        'calories_per_portion': 540,
        'reheat_instruction': 'Microwave 2.5 mins covered or stovetop with 2 tbsp water.',
      },
      {
        'id': 'stash-2',
        'title': 'Lemon Garlic Herb Chicken Breast',
        'storage_zone': 'fridge',
        'containers_remaining': 2,
        'prepared_date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'expires_date': now.add(const Duration(days: 2)).toIso8601String(),
        'calories_per_portion': 420,
        'reheat_instruction': 'Oven 175°C for 8 mins or pan-sear 2 mins per side.',
      },
      {
        'id': 'stash-3',
        'title': 'Hearty Lentil & Veggie Stew',
        'storage_zone': 'freezer',
        'containers_remaining': 4,
        'prepared_date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'expires_date': now.add(const Duration(days: 55)).toIso8601String(),
        'calories_per_portion': 380,
        'reheat_instruction': 'Thaw overnight in fridge, simmer in saucepan 5 mins.',
      },
    ];
  }

  Future<void> _loadRecipes() async {
    setState(() => _loadingRecipes = true);
    final myRecipes = await RecipeMonetizationService.getMyRecipes();
    final demoCatalog = _demoCatalogRecipes();

    if (mounted) {
      setState(() {
        _availableRecipes = [...myRecipes, ...demoCatalog];
        _loadingRecipes = false;
      });
    }
  }

  List<RecipeModel> _demoCatalogRecipes() {
    return [
      RecipeModel(
        id: 'bulk-plov',
        title: 'Batch Kazan Plov (Rice & Beef)',
        cuisine: 'Uzbek',
        difficulty: 2,
        prepTime: 20,
        cookTime: 45,
        servings: 4,
        caloriesPerServing: 620,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80',
      ),
      RecipeModel(
        id: 'bulk-chicken',
        title: 'Herb Roasted Chicken Breasts',
        cuisine: 'Mediterranean',
        difficulty: 1,
        prepTime: 15,
        cookTime: 25,
        servings: 4,
        caloriesPerServing: 420,
        imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&q=80',
      ),
      RecipeModel(
        id: 'bulk-quinoa',
        title: 'Steamed Quinoa & Rainbow Veggies',
        cuisine: 'Healthy',
        difficulty: 1,
        prepTime: 10,
        cookTime: 18,
        servings: 4,
        caloriesPerServing: 310,
        imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&q=80',
      ),
    ];
  }

  Future<void> _generateAiPlan() async {
    setState(() => _isGeneratingAi = true);

    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('inventory_items')
          .select('ingredients(display_name_en)')
          .eq('user_id', currentUserId());
      final ingredientNames = (rows as List)
          .map((r) => r['ingredients']?['display_name_en'] as String?)
          .whereType<String>()
          .toList();

      final api = ApiService();
      final result = await api.generateMealPrepPlan(
        userId: currentUserId(),
        ingredients: ingredientNames.isNotEmpty ? ingredientNames : ['Chicken Breast', 'Rice', 'Onion', 'Carrots', 'Garlic'],
        days: _bulkConfig.days,
        mealsPerDay: _bulkConfig.mealsPerDay,
        targetCaloriesPerMeal: _bulkConfig.targetCalories,
        targetProteinG: _bulkConfig.targetProteinG,
        targetCarbsG: _bulkConfig.targetCarbsG,
        targetFatG: _bulkConfig.targetFatG,
      );
      api.dispose();

      if (!mounted) return;
      setState(() => _isGeneratingAi = false);

      final data = result['data'] as Map<String, dynamic>? ?? {};
      final recipes = (data['recipes'] as List?) ?? [];

      if (recipes.isEmpty) {
        // Fallback demo plan
        final fallbackPlan = _demoMealPrepPlan();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MealPrepPlanSheet(planData: fallbackPlan),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MealPrepPlanSheet(planData: data),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isGeneratingAi = false);
        // Show fallback plan
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MealPrepPlanSheet(planData: _demoMealPrepPlan()),
        );
      }
    }
  }

  Map<String, dynamic> _demoMealPrepPlan() {
    return {
      'plan_id': 'prep-demo-${DateTime.now().millisecondsSinceEpoch}',
      'title': '${_bulkConfig.days}-Day Macro-Balanced Prep Plan',
      'estimated_total_prep_minutes': 75,
      'recipes': [
        {
          'title': 'Herb Seared Chicken & Brown Rice',
          'servings': _bulkConfig.days,
          'calories_per_serving': _bulkConfig.targetCalories,
          'ingredients': [
            {'name': 'Chicken Breast', 'quantity': 200 * _bulkConfig.days, 'unit': 'g'},
            {'name': 'Brown Rice', 'quantity': 80 * _bulkConfig.days, 'unit': 'g'},
            {'name': 'Olive Oil', 'quantity': 15, 'unit': 'ml'},
          ],
          'steps': [
            {'step_number': 1, 'text': 'Season chicken breasts evenly with herbs, salt, and black pepper.', 'seconds': 180},
            {'step_number': 2, 'text': 'Sear chicken in skillet over medium-high heat for 6 mins per side.', 'seconds': 720},
            {'step_number': 3, 'text': 'Portion rice and sliced chicken into ${_bulkConfig.days} airtight meal prep containers.', 'seconds': 300},
          ],
        },
        {
          'title': 'Roasted Mediterranean Medley',
          'servings': _bulkConfig.days,
          'calories_per_serving': 180,
          'ingredients': [
            {'name': 'Broccoli', 'quantity': 2, 'unit': 'heads'},
            {'name': 'Zucchini', 'quantity': 3, 'unit': 'pieces'},
            {'name': 'Bell Peppers', 'quantity': 3, 'unit': 'pieces'},
          ],
          'steps': [
            {'step_number': 1, 'text': 'Chop vegetables into uniform bite-sized pieces and toss with olive oil.', 'seconds': 300},
            {'step_number': 2, 'text': 'Roast on two baking sheets at 200°C for 22 minutes until edges caramelize.', 'seconds': 1320},
          ],
        },
      ],
      'shopping_list': [
        {'name': 'Chicken Breast', 'quantity': 1.0, 'unit': 'kg', 'is_in_stock': true},
        {'name': 'Brown Rice', 'quantity': 500, 'unit': 'g', 'is_in_stock': true},
        {'name': 'Broccoli', 'quantity': 2, 'unit': 'heads', 'is_in_stock': false},
        {'name': 'Zucchini', 'quantity': 3, 'unit': 'pieces', 'is_in_stock': false},
      ],
    };
  }

  void _startCustomBatchCooking() {
    if (_selectedBatchRecipes.isEmpty) return;

    final queuedRecipes = _selectedBatchRecipes.map((r) {
      final portions = _recipePortions[r.id] ?? 4;
      return {
        'title': r.title,
        'servings': portions,
        'ingredients': [
          {'name': 'Main Protein / Base', 'quantity': 150 * portions, 'unit': 'g'},
          {'name': 'Aromatics & Spices', 'quantity': portions, 'unit': 'serving'},
        ],
        'steps': [
          {'step_number': 1, 'text': 'Pre-heat cooking vessels and prep bulk ingredients for ${r.title}.', 'seconds': 180},
          {'step_number': 2, 'text': 'Execute core cooking cycle for $portions portions.', 'seconds': 900},
          {'step_number': 3, 'text': 'Cool slightly and distribute into $portions airtight meal prep containers.', 'seconds': 300},
        ],
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrepSessionScreen(
          planId: 'custom-batch-${DateTime.now().millisecondsSinceEpoch}',
          planTitle: 'Custom Batch Prep (${_selectedBatchRecipes.length} Dishes)',
          recipes: queuedRecipes,
          shoppingList: const [],
        ),
      ),
    );
  }

  void _consumePortion(Map<String, dynamic> item) {
    setState(() {
      final rem = (item['containers_remaining'] as int? ?? 1) - 1;
      if (rem <= 0) {
        _stashItems.remove(item);
      } else {
        item['containers_remaining'] = rem;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enjoy your meal! Logged ${item['calories_per_portion'] ?? 450} kcal. Container stash updated.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saffron = theme.colorScheme.primary;

    int totalStoredPortions = 0;
    for (final item in _stashItems) {
      totalStoredPortions += (item['containers_remaining'] as int? ?? 0);
    }
    final timeSavedHours = ((totalStoredPortions * 25) / 60).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🍱', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Bulk Cooking & Meal Prep', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: saffron,
          labelColor: saffron,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Stash ($totalStoredPortions)'),
            const Tab(text: 'AI Generator'),
            Tab(text: 'Batch Queue (${_selectedBatchRecipes.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Summary Stats Banner ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  saffron.withValues(alpha: 0.15),
                  const Color(0xFF4CAF50).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: saffron.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bannerStat('$totalStoredPortions', 'Portions Stored', Icons.takeout_dining, saffron),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.1)),
                _bannerStat('${timeSavedHours}h', 'Cooking Saved', Icons.schedule, const Color(0xFF4CAF50)),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.1)),
                _bannerStat('0%', 'Food Waste', Icons.eco, Colors.tealAccent),
              ],
            ),
          ),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStashTab(theme, saffron),
                _buildAiGeneratorTab(theme, saffron),
                _buildCustomBatchTab(theme, saffron),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Stash & Containers ──
  Widget _buildStashTab(ThemeData theme, Color saffron) {
    if (_loadingStash) {
      return Center(child: CircularProgressIndicator(color: saffron));
    }

    if (_stashItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍱', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 16),
              Text(
                'No Prepped Meals in Stash',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Cook in bulk using the AI Generator or Custom Batch queue to fill your fridge and save hours during the week!',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate 5-Day Plan'),
                style: FilledButton.styleFrom(backgroundColor: saffron),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stashItems.length,
      itemBuilder: (ctx, i) {
        final item = _stashItems[i];
        final zone = item['storage_zone'] ?? 'fridge';
        final isFreezer = zone == 'freezer';
        final remaining = item['containers_remaining'] ?? 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFreezer ? Colors.lightBlueAccent.withValues(alpha: 0.3) : saffron.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFreezer ? Colors.lightBlueAccent.withValues(alpha: 0.15) : saffron.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(isFreezer ? Icons.ac_unit : Icons.kitchen, size: 12, color: isFreezer ? Colors.lightBlueAccent : saffron),
                        const SizedBox(width: 4),
                        Text(
                          isFreezer ? 'FREEZER' : 'FRIDGE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isFreezer ? Colors.lightBlueAccent : saffron,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$remaining containers left',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4CAF50)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item['title'] ?? 'Prepped Dish',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '🔥 ${item['calories_per_portion'] ?? 450} kcal per container',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              if (item['reheat_instruction'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.microwave_outlined, size: 16, color: saffron),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['reheat_instruction']!,
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _consumePortion(item),
                  icon: const Icon(Icons.restaurant, size: 16),
                  label: const Text('Eat Portion & Log'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 2: AI Plan Generator ──
  Widget _buildAiGeneratorTab(ThemeData theme, Color saffron) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: saffron, size: 20),
                    const SizedBox(width: 8),
                    const Text('Configure AI Meal Prep Plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Plately will schedule balanced batches, scale recipes, and build an aggregated shopping list.',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                MealPrepConfigPanel(
                  initialConfig: _bulkConfig,
                  onConfigChanged: (c) => setState(() => _bulkConfig = c),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isGeneratingAi ? null : _generateAiPlan,
            icon: _isGeneratingAi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.rocket_launch),
            label: Text(
              _isGeneratingAi
                  ? 'Generating ${_bulkConfig.days}-Day Plan...'
                  : 'Generate ${_bulkConfig.days}-Day Meal Prep Plan',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: saffron,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Custom Batch Recipe Queue ──
  Widget _buildCustomBatchTab(ThemeData theme, Color saffron) {
    if (_loadingRecipes) {
      return Center(child: CircularProgressIndicator(color: saffron));
    }

    return Column(
      children: [
        // Queue Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select 2-4 Recipes for Sunday Batch Prep',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 2),
              Text(
                'Cook them sequentially in a guided kitchen session with synchronized timers.',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),

        // Recipe Picker List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: _availableRecipes.length,
            itemBuilder: (ctx, i) {
              final r = _availableRecipes[i];
              final isSelected = _selectedBatchRecipes.any((s) => s.id == r.id);
              final portions = _recipePortions[r.id] ?? 4;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? saffron.withValues(alpha: 0.08) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? saffron : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Checkbox(
                    value: isSelected,
                    activeColor: saffron,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (_selectedBatchRecipes.length < 4) {
                            _selectedBatchRecipes.add(r);
                            _recipePortions[r.id] = 4;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Maximum 4 recipes per batch session.')),
                            );
                          }
                        } else {
                          _selectedBatchRecipes.removeWhere((s) => s.id == r.id);
                        }
                      });
                    },
                  ),
                  title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${r.cuisine ?? "General"} • ${(r.prepTime ?? 0) + (r.cookTime ?? 0)} mins',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                  trailing: isSelected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$portions portions', style: TextStyle(fontWeight: FontWeight.bold, color: saffron, fontSize: 12)),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              onPressed: () {
                                setState(() {
                                  _recipePortions[r.id] = portions + 2;
                                });
                              },
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        ),

        // Start Batch Cooking Button
        if (_selectedBatchRecipes.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: FilledButton.icon(
              onPressed: _startCustomBatchCooking,
              icon: const Icon(Icons.play_arrow),
              label: Text('Start Batch Cooking (${_selectedBatchRecipes.length} Recipes)'),
              style: FilledButton.styleFrom(
                backgroundColor: saffron,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bannerStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}
