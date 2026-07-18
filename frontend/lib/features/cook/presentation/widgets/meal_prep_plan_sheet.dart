/// Plately — Meal Prep Plan Sheet
/// ================================
/// DraggableScrollableSheet that displays an AI-generated meal prep plan
/// with shopping list, recipe cards, and action buttons.
library;

import 'package:flutter/material.dart';
import '../screens/prep_session_screen.dart';
import '../../../../core/services/api_service.dart';

class MealPrepPlanSheet extends StatefulWidget {
  final Map<String, dynamic> planData;

  const MealPrepPlanSheet({super.key, required this.planData});

  @override
  State<MealPrepPlanSheet> createState() => _MealPrepPlanSheetState();
}

class _MealPrepPlanSheetState extends State<MealPrepPlanSheet> {
  bool _saving = false;
  bool _shoppingExpanded = true;
  final Set<int> _expandedRecipes = {};

  Map<String, dynamic> get _data => widget.planData;
  List get _recipes => _data['recipes'] as List? ?? [];
  List get _shoppingList => _data['shopping_list'] as List? ?? [];
  String get _title => _data['title'] as String? ?? 'Meal Prep Plan';
  int get _totalMinutes => _data['estimated_total_prep_minutes'] as int? ?? 0;
  String? get _planId => _data['plan_id'] as String?;

  Future<void> _startPrep() async {
    if (_recipes.isEmpty) return;
    // Mark plan as started
    if (_planId != null) {
      try {
        final api = ApiService();
        await api.startMealPrepPlan(_planId!);
        api.dispose();
      } catch (_) {
        // Non-critical, continue with session
      }
    }

    if (!mounted) return;
    Navigator.pop(context); // Close this sheet

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrepSessionScreen(
          planId: _planId ?? '',
          planTitle: _title,
          recipes: List<Map<String, dynamic>>.from(
            _recipes.map((r) => Map<String, dynamic>.from(r as Map)),
          ),
          shoppingList: List<Map<String, dynamic>>.from(
            _shoppingList.map((s) => Map<String, dynamic>.from(s as Map)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Scrollable content ──
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: primary, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  )),
                              if (_totalMinutes > 0)
                                Text('~$_totalMinutes min total prep time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    )),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_recipes.length} recipes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Shopping List ──
                    if (_shoppingList.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => setState(() => _shoppingExpanded = !_shoppingExpanded),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shopping_cart, size: 18, color: primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Shopping List (${_shoppingList.length} items)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _shoppingExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(Icons.expand_more,
                                        size: 20,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                  ),
                                ],
                              ),
                              if (_shoppingExpanded) ...[
                                const SizedBox(height: 10),
                                ...(_shoppingList).map((item) {
                                  final name = item['name'] ?? '';
                                  final qty = item['total_quantity'] ?? '';
                                  final unit = item['unit'] ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            size: 16,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$qty $unit $name',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
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
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Recipe Cards ──
                    Text('Recipes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        )),
                    const SizedBox(height: 8),
                    if (_recipes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.restaurant_menu, size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No recipes found for this plan.',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: theme.colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please try generating with fewer days or simpler preferences.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_recipes.length, (i) {
                        final recipe = _recipes[i] as Map<String, dynamic>;
                        final expanded = _expandedRecipes.contains(i);
                        return _recipeCard(i, recipe, expanded, theme, primary);
                      }),
                  ],
                ),
              ),

              // ── Action buttons ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (_saving || _recipes.isEmpty) ? null : _startPrep,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_recipes.isEmpty ? 'No Recipes Available' : 'Start Prep Session'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _recipeCard(
    int index,
    Map<String, dynamic> recipe,
    bool expanded,
    ThemeData theme,
    Color primary,
  ) {
    final title = recipe['title'] ?? 'Recipe ${index + 1}';
    final cuisine = recipe['cuisine'] as String?;
    final cal = recipe['calories_per_serving'];
    final protein = recipe['protein_g'];
    final carbs = recipe['carbs_g'];
    final fat = recipe['fat_g'];
    final servings = recipe['servings'] ?? 4;
    final cookTime = (recipe['prep_time_minutes'] ?? 0) + (recipe['cook_time_minutes'] ?? 0);
    final ingredients = recipe['ingredients'] as List? ?? [];
    final steps = recipe['steps'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (expanded) {
              _expandedRecipes.remove(index);
            } else {
              _expandedRecipes.add(index);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (cuisine != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cuisine,
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Macro badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (cal != null) _macroBadge(Icons.local_fire_department, '$cal kcal', Colors.deepOrange),
                  if (protein != null) _macroBadge(Icons.fitness_center, '${protein}g P', Colors.blueAccent),
                  if (carbs != null) _macroBadge(Icons.bolt, '${carbs}g C', Colors.amber),
                  if (fat != null) _macroBadge(Icons.water_drop, '${fat}g F', Colors.orangeAccent),
                  _macroBadge(Icons.people, '$servings srv', theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  if (cookTime > 0) _macroBadge(Icons.timer, '$cookTime min', theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),

              // Expanded content
              if (expanded) ...[
                const SizedBox(height: 12),
                Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                const SizedBox(height: 8),

                // Ingredients
                if (ingredients.isNotEmpty) ...[
                  Text('Ingredients',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )),
                  const SizedBox(height: 4),
                  ...ingredients.map((ing) {
                    final ingMap = ing as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${ingMap['quantity'] ?? ''} ${ingMap['unit'] ?? ''} ${ingMap['name'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],

                // Steps
                if (steps.isNotEmpty) ...[
                  Text('Steps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )),
                  const SizedBox(height: 4),
                  ...steps.map((step) {
                    final stepMap = step as Map<String, dynamic>;
                    final num = stepMap['step_number'] ?? stepMap['step'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '$num. ${stepMap['text'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
