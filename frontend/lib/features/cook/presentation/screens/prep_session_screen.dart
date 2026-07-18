/// Plately — Prep Session Screen
/// ================================
/// Coordinates cooking multiple recipes in sequence for a meal prep session.
/// Shows progress, recipe queue, and interstitials between recipes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cooking_run_screen.dart';
import 'prep_session_complete_screen.dart';
import '../../../../core/services/api_service.dart';

class PrepSessionScreen extends ConsumerStatefulWidget {
  final String planId;
  final String planTitle;
  final List<Map<String, dynamic>> recipes;
  final List<Map<String, dynamic>> shoppingList;

  const PrepSessionScreen({
    super.key,
    required this.planId,
    required this.planTitle,
    required this.recipes,
    required this.shoppingList,
  });

  @override
  ConsumerState<PrepSessionScreen> createState() => _PrepSessionScreenState();
}

class _PrepSessionScreenState extends ConsumerState<PrepSessionScreen>
    with SingleTickerProviderStateMixin {
  int _currentRecipeIndex = 0;
  final List<bool> _completedRecipes = [];
  final Map<int, int> _portionsPerRecipe = {};
  final Map<int, String> _containerLabels = {};
  late DateTime _overallStartTime;
  bool _isShowingInterstitial = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _overallStartTime = DateTime.now();
    _completedRecipes.addAll(List.filled(widget.recipes.length, false));
    for (int i = 0; i < widget.recipes.length; i++) {
      _portionsPerRecipe[i] = (widget.recipes[i]['servings'] as int?) ?? 4;
      _containerLabels[i] = '';
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startRecipe(int index) async {
    final recipe = widget.recipes[index];
    final ingredients = (recipe['ingredients'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final steps = (recipe['steps'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final servings = (recipe['servings'] as int?) ?? 4;

    // Navigate to CookingRunScreen and await its completion
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookingRunScreen(
          recipeId: 'prep_${widget.planId}_$index',
          title: recipe['title'] ?? 'Recipe ${index + 1}',
          steps: steps,
          isBeginnerMode: false,
          ingredients: ingredients,
          matchedIngredientsCount: 0,
          matchPct: 0,
          userInventoryText: '',
          servingsCooked: servings,
          originalServings: servings,
          ownedIngredientIds: const {},
          calories: (recipe['calories_per_serving'] as int? ?? 0) * servings,
        ),
      ),
    );

    // When CookingRunScreen pops, mark this recipe as done
    if (mounted) {
      setState(() {
        _completedRecipes[index] = true;
        _isShowingInterstitial = true;
      });
      _animController.forward(from: 0);

      // Mark recipe as cooked on backend
      try {
        final api = ApiService();
        await api.markPrepRecipeCooked(
          widget.planId,
          index,
          _portionsPerRecipe[index] ?? servings,
        );
        api.dispose();
      } catch (_) {}
    }
  }

  void _nextRecipe() {
    final nextIndex = _completedRecipes.indexWhere((c) => !c);
    if (nextIndex == -1) {
      _finishSession();
    } else {
      setState(() {
        _currentRecipeIndex = nextIndex;
        _isShowingInterstitial = false;
      });
    }
  }

  Future<void> _finishSession() async {
    final totalMinutes = DateTime.now().difference(_overallStartTime).inMinutes;
    int totalPortions = 0;
    int totalCalories = 0;
    final summaries = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.recipes.length; i++) {
      if (_completedRecipes[i]) {
        final portions = _portionsPerRecipe[i] ?? 4;
        totalPortions += portions;
        totalCalories += ((widget.recipes[i]['calories_per_serving'] as int?) ?? 0) * portions;
        summaries.add({
          'title': widget.recipes[i]['title'] ?? 'Recipe ${i + 1}',
          'portionsCooked': portions,
          'containerLabel': _containerLabels[i] ?? '',
          'storageZone': 'fridge',
        });
      }
    }

    // Mark plan as complete on backend
    try {
      final api = ApiService();
      await api.completeMealPrepPlan(widget.planId, totalMinutes);
      api.dispose();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PrepSessionCompleteScreen(
          planTitle: widget.planTitle,
          planId: widget.planId,
          totalPrepMinutes: totalMinutes,
          recipeSummaries: summaries,
          totalPortionsStored: totalPortions,
          totalCaloriesPlanned: totalCalories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.planTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No recipes found in this prep session.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.planTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              'Recipe ${_currentRecipeIndex + 1} of ${widget.recipes.length}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        actions: [
          // Overall timer
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (_, __) {
                final elapsed = DateTime.now().difference(_overallStartTime);
                final h = elapsed.inHours;
                final m = elapsed.inMinutes % 60;
                final s = elapsed.inSeconds % 60;
                return Text(
                  h > 0 ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
                         : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.recipes.length, (i) {
                final done = _completedRecipes[i];
                final current = i == _currentRecipeIndex && !_isShowingInterstitial;
                return Row(
                  children: [
                    if (i > 0)
                      Container(
                        width: 20,
                        height: 2,
                        color: done ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: current ? 36 : 30,
                      height: current ? 36 : 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: done
                            ? Colors.green
                            : current
                                ? primary
                                : theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done
                              ? Colors.green
                              : current
                                  ? primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                          width: current ? 2 : 1,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: current ? Colors.black : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                    ),
                  ],
                );
              }),
            ),
          ),

          // ── Body ──
          Expanded(
            child: _isShowingInterstitial
                ? _buildInterstitial()
                : _buildRecipeOverview(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeOverview() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final recipe = widget.recipes[_currentRecipeIndex];
    final title = recipe['title'] ?? 'Recipe ${_currentRecipeIndex + 1}';
    final desc = recipe['description'] ?? '';
    final cookTime = (recipe['prep_time_minutes'] ?? 0) + (recipe['cook_time_minutes'] ?? 0);
    final servings = recipe['servings'] ?? 4;
    final ingredients = recipe['ingredients'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Recipe header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary.withValues(alpha: 0.08), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          )),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(desc,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            )),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _infoBadge(Icons.timer, '$cookTime min'),
                          _infoBadge(Icons.people, '$servings servings'),
                          if (recipe['calories_per_serving'] != null)
                            _infoBadge(Icons.local_fire_department, '${recipe['calories_per_serving']} kcal'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ingredients preview
                if (ingredients.isNotEmpty) ...[
                  Text('Ingredients (${ingredients.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      )),
                  const SizedBox(height: 8),
                  ...ingredients.map((ing) {
                    final ingMap = ing as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(width: 8),
                          Text(
                            '${ingMap['quantity'] ?? ''} ${ingMap['unit'] ?? ''} ${ingMap['name'] ?? ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Start cooking button
          SafeArea(
            child: FilledButton.icon(
              onPressed: () => _startRecipe(_currentRecipeIndex),
              icon: const Icon(Icons.play_arrow),
              label: Text('Start Cooking: $title'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterstitial() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final justCompletedIndex = _completedRecipes.lastIndexOf(true);
    final recipe = widget.recipes[justCompletedIndex];
    final title = recipe['title'] ?? 'Recipe ${justCompletedIndex + 1}';
    final remaining = _completedRecipes.where((c) => !c).length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated checkmark
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: const Icon(Icons.check, size: 40, color: Colors.green),
            ),
          ),
          const SizedBox(height: 20),

          Text('$title Complete! ✅',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              )),
          const SizedBox(height: 6),
          Text(
            remaining > 0
                ? '$remaining recipe${remaining > 1 ? 's' : ''} remaining'
                : 'All recipes done!',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),

          // Container label
          TextField(
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Label containers (optional)',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              prefixIcon: Icon(Icons.label_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
            ),
            onChanged: (v) => _containerLabels[justCompletedIndex] = v,
          ),
          const SizedBox(height: 24),

          // Next button
          FilledButton.icon(
            onPressed: _nextRecipe,
            icon: Icon(remaining > 0 ? Icons.arrow_forward : Icons.celebration),
            label: Text(remaining > 0 ? 'Next Recipe' : 'Finish Prep Session'),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
