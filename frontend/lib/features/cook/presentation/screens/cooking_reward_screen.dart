// Plately — Cooking Reward Screen
// ==================================
// Celebratory screen shown after completing a recipe.
// Awards XP, deducts inventory, logs nutrition, and provides a return to the dashboard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:plately_app/features/gamification/data/gamification_repository.dart';
import 'package:plately_app/core/services/tutorial_controller.dart';

class CookingRewardScreen extends ConsumerStatefulWidget {
  final String recipeId;
  final String title;
  final int matchedIngredientsCount;
  final double matchPct;
  final int servingsCooked;
  final int originalServings;
  final List<String> skippedIngredientIds;
  final List<Map<String, dynamic>>? ingredients;
  final int? calories;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final Map<String, dynamic>? prepResult;

  const CookingRewardScreen({
    super.key,
    required this.recipeId,
    required this.title,
    required this.matchedIngredientsCount,
    required this.matchPct,
    required this.servingsCooked,
    required this.originalServings,
    this.skippedIngredientIds = const [],
    this.ingredients,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.prepResult,
  });

  @override
  ConsumerState<CookingRewardScreen> createState() => _CookingRewardScreenState();
}

class _CookingRewardScreenState extends ConsumerState<CookingRewardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isSaving = true;
  String? _error;

  // Base reward is 50 XP, bonus is +5 for every matched ingredient
  late int _xpEarned;

  // Consumption results
  List<Map<String, dynamic>> _consumedItems = [];
  int? _caloriesLogged;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _xpEarned = 50 + (widget.matchedIngredientsCount * 5);
    _saveRewards();
  }

  Future<void> _saveRewards() async {
    if (widget.recipeId == 'tutorial-stir-fry') {
      try {
        _consumedItems = [
          {'name': 'Chicken Breast', 'deducted': 125.0, 'unit': 'g'},
          {'name': 'Broccoli', 'deducted': 0.25, 'unit': 'head'},
          {'name': 'Soy Sauce', 'deducted': 15.0, 'unit': 'ml'},
          {'name': 'Garlic', 'deducted': 1.0, 'unit': 'clove'},
          {'name': 'Sesame Oil', 'deducted': 5.0, 'unit': 'ml'},
        ];
        _caloriesLogged = 380;
        // Defer provider modification past the widget tree build phase
        Future(() {
          ref.read(tutorialControllerProvider.notifier).setStep(TutorialState.finish);
        });
      } catch (e) {
        debugPrint('[Reward] Tutorial finish error (non-critical): $e');
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _animController.forward();
      }
      return;
    }
    try {
      final user = Supabase.instance.client.auth.currentUser;
      // Using demo user ID for prototype if no auth
      final userId = user?.id ?? '00000000-0000-4000-8000-000000000001';

      // 1. Save XP & cooking history
      final repo = GamificationRepository();
      await repo.completeCookingSession(
        userId: userId,
        recipeId: widget.recipeId,
        xpGain: _xpEarned,
        matchedIngredientsCount: widget.matchedIngredientsCount,
      );

      // 2. Flavor profile update
      try {
        await _api.recordCook(userId: userId, recipeId: widget.recipeId);
        debugPrint('[Reward] Flavor profile recorded');
      } catch (e) {
        debugPrint('[Reward] Flavor record failed (non-critical): $e');
      }

      if (widget.prepResult != null) {
        // If prepResult is provided, database operations have already run atomically!
        _caloriesLogged = widget.prepResult!['calories_logged'] as int?;
        
        final skippedIds = Set<String>.from(widget.skippedIngredientIds);
        final consumedList = <Map<String, dynamic>>[];
        final scale = widget.servingsCooked / (widget.originalServings > 0 ? widget.originalServings : 2);
        
        for (final ing in widget.ingredients ?? []) {
          final iid = ing['ingredient_id'] ?? ing['id'];
          if (iid == null || skippedIds.contains(iid)) continue;
          
          final qty = ((ing['quantity'] as num?) ?? 0) * scale;
          if (qty <= 0) continue;
          
          consumedList.add({
            'name': ing['display_name_en'] ?? ing['name'] ?? 'Item',
            'deducted': qty,
            'unit': ing['unit'] ?? 'pcs',
          });
        }
        _consumedItems = consumedList;
      } else {
        // 3. Deduct inventory via Supabase RPC (fallback if no prepResult passed)
        try {
          final skippedIds = Set<String>.from(widget.skippedIngredientIds);
          final inventoryItems = await Supabase.instance.client
              .from('inventory_items')
              .select('id, ingredient_id, quantity, unit, ingredients(display_name_en)')
              .eq('user_id', userId)
              .gt('quantity', 0);
              
          final invMap = <String, Map<String, dynamic>>{};
          for (final item in inventoryItems) {
            invMap[item['ingredient_id']] = item;
          }

          final consumedList = <Map<String, dynamic>>[];
          final recipeIngredients = widget.ingredients ?? [];
          final scale = widget.servingsCooked / (widget.originalServings > 0 ? widget.originalServings : 2);

          for (final ing in recipeIngredients) {
            final iid = ing['ingredient_id'] ?? ing['id'];
            if (iid == null || skippedIds.contains(iid)) continue;
            
            final invItem = invMap[iid];
            if (invItem == null) continue;

            final qty = ((ing['quantity'] as num?) ?? 0) * scale;
            if (qty <= 0) continue;

            final deduct = qty < invItem['quantity'] ? qty : invItem['quantity'];
            await Supabase.instance.client.rpc('consume_inventory_item', params: {
              'p_inventory_id': invItem['id'],
              'p_qty_to_consume': deduct,
            });

            consumedList.add({
              'name': invItem['ingredients']?['display_name_en'] ?? ing['name'] ?? '',
              'deducted': deduct,
              'unit': invItem['unit'] ?? ing['unit'] ?? '',
            });
          }
          
          _consumedItems = consumedList;
          debugPrint('[Reward] Inventory deducted: ${_consumedItems.length} items');
        } catch (e) {
          debugPrint('[Reward] Inventory deduction failed (non-critical): $e');
        }

        // 4. Log nutrition (fallback if no prepResult passed)
        try {
          final cal = widget.calories ?? 0;
          if (cal > 0) {
            _caloriesLogged = cal;
            await Supabase.instance.client.from('nutrition_logs').insert({
              'user_id': userId,
              'meal_type': 'cooked',
              'calories': cal,
              'protein_g': widget.proteinG ?? 0,
              'carbs_g': widget.carbsG ?? 0,
              'fat_g': widget.fatG ?? 0,
              'food_items': [
                {
                  'name': widget.title,
                  'calories': cal,
                  'protein_g': widget.proteinG ?? 0,
                  'carbs_g': widget.carbsG ?? 0,
                  'fat_g': widget.fatG ?? 0,
                }
              ],
              'notes': 'Cooked ${widget.servingsCooked} servings',
            });
            debugPrint('[Reward] Nutrition logged: $cal kcal');
          }
        } catch (e) {
          debugPrint('[Reward] Nutrition logging failed (non-critical): $e');
        }
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save progress. $e';
          _isSaving = false;
        });
        // Still animate so user can dismiss
        _animController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _api.dispose();
    super.dispose();
  }

  void _finish() {
    // Pop back to the main app shell
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: _isSaving
                ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 40),

                            // ── Confetti / Icon ──────────────────────
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.workspace_premium,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                            SizedBox(height: 32),

                            // ── Title ────────────────────────────────
                            Text(
                              AppLocalizations.of(context)?.reward_mealCompleted ?? 'Meal Completed!',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                AppLocalizations.of(context)?.reward_youCooked(widget.title, widget.servingsCooked.toString()) ?? 'You cooked "${widget.title}" · ${widget.servingsCooked} servings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            SizedBox(height: 32),

                            // ── Stats Cards ──────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatCard(
                                  icon: Icons.star,
                                  value: '+$_xpEarned',
                                  label: AppLocalizations.of(context)?.reward_xpEarned ?? 'XP Earned',
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 12),
                                _StatCard(
                                  icon: Icons.eco,
                                  value: '${_consumedItems.isNotEmpty ? _consumedItems.length : widget.matchedIngredientsCount}',
                                  label: AppLocalizations.of(context)?.reward_itemsUsed ?? 'Items Used',
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                if (_caloriesLogged != null && _caloriesLogged! > 0) ...[
                                  SizedBox(width: 12),
                                  _StatCard(
                                    icon: Icons.local_fire_department,
                                    value: '$_caloriesLogged',
                                    label: 'kcal',
                                    color: Colors.orange,
                                  ),
                                ],
                              ],
                            ),

                             // ── Leftovers Stored Card ────────────────
                             if (widget.prepResult != null && (widget.prepResult!['portions_stored'] as int? ?? 0) > 0) ...[
                               SizedBox(height: 24),
                               Container(
                                 width: double.infinity,
                                 padding: EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   color: Theme.of(context).colorScheme.surface,
                                   borderRadius: BorderRadius.circular(16),
                                   border: Border.all(
                                     color: Colors.green.withValues(alpha: 0.3),
                                   ),
                                 ),
                                 child: Row(
                                   children: [
                                     Icon(Icons.inventory_2, color: Colors.green, size: 24),
                                     SizedBox(width: 12),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text(
                                             'Leftovers Stored!',
                                             style: TextStyle(
                                               color: Colors.green,
                                               fontWeight: FontWeight.bold,
                                               fontSize: 14,
                                             ),
                                           ),
                                           SizedBox(height: 2),
                                           Text(
                                             'Stored ${widget.prepResult!['portions_stored']} portion(s) of "${widget.title}" in your fridge.',
                                             style: TextStyle(
                                               color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                               fontSize: 13,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ],

                            // ── Consumed Items Summary ───────────────
                            if (_consumedItems.isNotEmpty) ...[
                              SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.inventory_2_outlined,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 16),
                                        SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)?.reward_deducted ?? 'Deducted from shelf',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    ..._consumedItems.take(6).map((item) => Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '  - ${item['deducted']?.toStringAsFixed(1) ?? ''} ${item['unit'] ?? ''} ${item['name'] ?? ''}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontSize: 13)),
                                    )),
                                    if (_consumedItems.length > 6)
                                      Text('  ... and ${_consumedItems.length - 6} more',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                          fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],

                            if (_error != null) ...[
                              SizedBox(height: 24),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],

                            SizedBox(height: 40),

                            // ── Done Button ──────────────────────────
                            FilledButton(
                              onPressed: _finish,
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.onSurface,
                                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 48,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)?.reward_backToShelf ?? 'Back to Shelf',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
