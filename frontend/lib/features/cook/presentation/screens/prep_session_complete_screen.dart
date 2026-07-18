/// Plately — Prep Session Complete Screen
/// ========================================
/// Post-prep-session summary screen showing stats, recipe summaries,
/// and time saved estimates. Analogous to CookingRewardScreen.
library;

import 'package:flutter/material.dart';

class PrepSessionCompleteScreen extends StatefulWidget {
  final String planTitle;
  final String planId;
  final int totalPrepMinutes;
  final List<Map<String, dynamic>> recipeSummaries;
  final int totalPortionsStored;
  final int totalCaloriesPlanned;

  const PrepSessionCompleteScreen({
    super.key,
    required this.planTitle,
    required this.planId,
    required this.totalPrepMinutes,
    required this.recipeSummaries,
    required this.totalPortionsStored,
    required this.totalCaloriesPlanned,
  });

  @override
  State<PrepSessionCompleteScreen> createState() => _PrepSessionCompleteScreenState();
}

class _PrepSessionCompleteScreenState extends State<PrepSessionCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  /// Estimated time saved: each stored portion saves ~25 min of daily cooking
  int get _timeSavedMinutes => (widget.totalPortionsStored * 25) - widget.totalPrepMinutes;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              primary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Trophy + Title ──
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primary.withValues(alpha: 0.2),
                          primary.withValues(alpha: 0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(Icons.celebration, size: 44, color: primary),
                  ),
                ),
                const SizedBox(height: 20),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text('Meal Prep Complete! 🎉',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        'You prepped ${widget.recipeSummaries.length} meals in ${widget.totalPrepMinutes} minutes',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Stats grid ──
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Row(
                    children: [
                      _statCard(
                        icon: Icons.timer,
                        value: '${widget.totalPrepMinutes}',
                        label: 'Minutes',
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.restaurant_menu,
                        value: '${widget.totalPortionsStored}',
                        label: 'Portions',
                        color: primary,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        icon: Icons.schedule,
                        value: _timeSavedMinutes > 0 ? '${_timeSavedMinutes}m' : '—',
                        label: 'Time Saved',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Recipe summaries ──
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView(
                      children: [
                        Text('Meals Prepped',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            )),
                        const SizedBox(height: 8),
                        ...widget.recipeSummaries.map((r) {
                          final title = r['title'] ?? 'Recipe';
                          final portions = r['portionsCooked'] ?? 0;
                          final label = r['containerLabel'] ?? '';
                          final zone = r['storageZone'] ?? 'fridge';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.check, size: 18, color: Colors.green),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.onSurface,
                                            )),
                                        Text(
                                          '$portions portions → ${zone == 'freezer' ? '🧊 Freezer' : '🧊 Fridge'}${label.isNotEmpty ? ' · $label' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        icon: const Icon(Icons.kitchen),
                        label: const Text('View Shelf'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('Back to Cook'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}
