// Plately — Recipe Paywall Sheet
// ===================================
// Premium unlock bottom sheet for Executive Masterclass recipes.
// Displays chef credentials, copy count, price in UZS/USD,
// blurred secret step preview, and one-tap unlock.

import 'package:flutter/material.dart';
import 'package:plately_app/core/services/recipe_monetization_service.dart';

class RecipePaywallSheet extends StatefulWidget {
  final RecipeModel recipe;
  final VoidCallback? onUnlocked;

  const RecipePaywallSheet({
    super.key,
    required this.recipe,
    this.onUnlocked,
  });

  static Future<bool?> show(BuildContext context, RecipeModel recipe, {VoidCallback? onUnlocked}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipePaywallSheet(recipe: recipe, onUnlocked: onUnlocked),
    );
  }

  @override
  State<RecipePaywallSheet> createState() => _RecipePaywallSheetState();
}

class _RecipePaywallSheetState extends State<RecipePaywallSheet> {
  bool _isProcessing = false;
  String? _errorMessage;

  String get _uzsPrice {
    final priceCents = widget.recipe.priceCents;
    if (priceCents <= 0) return 'Free';
    // 100 cents = $1 ~= 12,800 UZS
    final uzs = (priceCents * 128).round();
    final formatted = uzs.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted UZS';
  }

  Future<void> _handleUnlock() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final success = await RecipeMonetizationService.purchaseRecipe(
        widget.recipe.id,
        widget.recipe.priceCents,
      );

      if (!mounted) return;

      if (success) {
        widget.onUnlocked?.call();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unlocked "${widget.recipe.title}"! Masterclass added to your Chef Portfolio.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Purchase could not be completed. Please try again.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.recipe;
    final primarySaffron = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7861C), Color(0xFFFFB300)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 14, color: Colors.black87),
                    SizedBox(width: 4),
                    Text(
                      'EXECUTIVE MASTERCLASS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Recipe Title
          Text(
            r.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
          ),

          if (r.description != null && r.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.description!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 14),

          // Quick stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.timer_outlined,
                  label: '${(r.prepTime ?? 0) + (r.cookTime ?? 0)} mins',
                ),
                _StatItem(
                  icon: Icons.local_fire_department_outlined,
                  label: '${r.caloriesPerServing ?? 380} kcal',
                ),
                _StatItem(
                  icon: Icons.people_outline,
                  label: '${r.copyCount} unlocked',
                ),
                _StatItem(
                  icon: Icons.restaurant_menu,
                  label: r.cuisine ?? 'Master',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Blurred Secret Steps Preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color: Color(0xFFFFB300)),
                    const SizedBox(width: 8),
                    Text(
                      'Executive Chef Secrets & Precise Timers',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Includes proprietary flavor pairings, kitchen temp schedules, pan countdown timers, and full nutritional breakdown.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pricing Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primarySaffron.withValues(alpha: 0.12),
                  const Color(0xFFFFB300).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primarySaffron.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ONE-TIME UNLOCK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: primarySaffron,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _uzsPrice,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${r.priceDisplay})',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.verified_user_outlined, color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 4),
                const Text(
                  'Lifetime Access',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),

          // Unlock Button
          FilledButton(
            onPressed: _isProcessing ? null : _handleUnlock,
            style: FilledButton.styleFrom(
              backgroundColor: primarySaffron,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_open_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Unlock Masterclass Recipe • $_uzsPrice',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
