import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CookPortionsSheet extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;
  final int initialServings;
  final List<Map<String, dynamic>> ingredients; // [{ingredient_id, quantity_per_portion, unit}]
  final double caloriesPerPortion;
  final double proteinPerPortion;
  final double carbsPerPortion;
  final double fatPerPortion;
  final Function(Map<String, dynamic> result) onComplete;

  const CookPortionsSheet({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
    required this.initialServings,
    required this.ingredients,
    required this.caloriesPerPortion,
    required this.proteinPerPortion,
    required this.carbsPerPortion,
    required this.fatPerPortion,
    required this.onComplete,
  });

  static Future<void> show({
    required BuildContext context,
    required String recipeId,
    required String recipeTitle,
    required int initialServings,
    required List<Map<String, dynamic>> ingredients,
    required double caloriesPerPortion,
    required double proteinPerPortion,
    required double carbsPerPortion,
    required double fatPerPortion,
    required Function(Map<String, dynamic> result) onComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookPortionsSheet(
        recipeId: recipeId,
        recipeTitle: recipeTitle,
        initialServings: initialServings,
        ingredients: ingredients,
        caloriesPerPortion: caloriesPerPortion,
        proteinPerPortion: proteinPerPortion,
        carbsPerPortion: carbsPerPortion,
        fatPerPortion: fatPerPortion,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<CookPortionsSheet> createState() => _CookPortionsSheetState();
}

class _CookPortionsSheetState extends State<CookPortionsSheet> {
  late int _portionsCooked;
  late int _portionsEaten;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _portionsCooked = widget.initialServings.clamp(1, 12);
    _portionsEaten = 1.clamp(0, _portionsCooked);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User session not found.");

      // Prepare ingredient scaling details (baseAmountPerPortion = quantity_per_serving)
      final ingredientPayload = widget.ingredients.map((ing) {
        return {
          'ingredient_id': ing['ingredient_id'],
          'quantity_per_portion': ing['quantity_per_portion'] ?? ing['quantity'] ?? 1.0,
          'unit': ing['unit'] ?? 'pcs',
        };
      }).toList();

      // Trigger the atomic process_meal_prep transaction in Supabase
      final response = await Supabase.instance.client.rpc(
        'process_meal_prep',
        params: {
          'p_user_id': userId,
          'p_recipe_id': widget.recipeId,
          'p_recipe_title': widget.recipeTitle,
          'p_portions_cooked': _portionsCooked,
          'p_portions_eaten': _portionsEaten,
          'p_ingredients': ingredientPayload,
          'p_cal_per_portion': widget.caloriesPerPortion,
          'p_protein_per_portion': widget.proteinPerPortion,
          'p_carbs_per_portion': widget.carbsPerPortion,
          'p_fat_per_portion': widget.fatPerPortion,
        },
      );

      final Map<String, dynamic> result = Map<String, dynamic>.from(response as Map);

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        widget.onComplete(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final caloriesLogged = (widget.caloriesPerPortion * _portionsEaten).round();
    final leftoversStored = _portionsCooked - _portionsEaten;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                '🥘 Cook & Store leftovers',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Confirm servings cooked vs eaten raw to auto-log macros and store the rest in your fridge.',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Error banner
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Portions Cooked (Static)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Portions Cooked',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_portionsCooked portions',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Slider B: Portions Eaten Now
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Eating Right Now',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_portionsEaten portions',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _portionsEaten.toDouble(),
                min: 0,
                max: _portionsCooked.toDouble(),
                divisions: _portionsCooked,
                activeColor: theme.colorScheme.tertiary,
                inactiveColor: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                onChanged: _submitting
                    ? null
                    : (val) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _portionsEaten = val.round();
                        });
                      },
              ),
              const SizedBox(height: 24),

              // Live Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Preview:',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _previewItem(
                      icon: Icons.remove_circle_outline,
                      color: theme.colorScheme.error,
                      text: 'Deducting raw ingredients for $_portionsCooked portions from shelf.',
                    ),
                    const SizedBox(height: 10),
                    _previewItem(
                      icon: Icons.insights_outlined,
                      color: theme.colorScheme.tertiary,
                      text: _portionsEaten > 0
                          ? 'Logging $_portionsEaten portion(s) of macros ($caloriesLogged kcal) to today\'s diary.'
                          : 'No calories or macros will be logged immediately.',
                    ),
                    const SizedBox(height: 10),
                    _previewItem(
                      icon: Icons.inventory_2_outlined,
                      color: Colors.green,
                      text: leftoversStored > 0
                          ? 'Storing $leftoversStored leftover portion(s) in your virtual fridge.'
                          : 'No leftovers will be stored (all portions consumed).',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action button
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        leftoversStored > 0 ? 'Cook & Save Leftovers' : 'Cook & Log Meal',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}
