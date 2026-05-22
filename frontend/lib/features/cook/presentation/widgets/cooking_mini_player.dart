// ═══════════════════════════════════════════════════════════════════
//  Plately — Cooking Mini-Player
//  Spotify-style floating bar shown when a cooking session is active.
//  Displays recipe title, current step, timer, and provides
//  quick access back to the cooking screen.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plately_app/features/cook/models/cooking_session.dart';
import 'package:plately_app/features/cook/providers/cooking_session_provider.dart';
import 'package:plately_app/features/cook/presentation/screens/cooking_run_screen.dart';

class CookingMiniPlayer extends ConsumerWidget {
  const CookingMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(cookingSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, offset * 80),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.15),
              cs.surface.withValues(alpha: 0.95),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToCooking(context, session),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // ── Recipe thumbnail ──
                  _buildThumbnail(session, cs),
                  const SizedBox(width: 12),

                  // ── Info column ──
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu,
                                size: 12,
                                color: cs.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'Step ${session.currentStepIndex + 1}/${session.totalSteps}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            if (session.isTimerActive ||
                                session.timerStatus ==
                                    TimerStatus.paused) ...[
                              const SizedBox(width: 8),
                              _buildTimerChip(session, cs, theme),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Quick actions ──
                  if (session.isTimerActive)
                    IconButton(
                      icon: const Icon(Icons.pause_rounded, size: 22),
                      color: cs.primary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        ref
                            .read(cookingSessionProvider.notifier)
                            .pauseTimer();
                      },
                    )
                  else if (session.timerStatus == TimerStatus.paused)
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      color: cs.primary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        ref
                            .read(cookingSessionProvider.notifier)
                            .resumeTimer();
                      },
                    ),

                  // ── Close button ──
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showStopDialog(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(CookingSession session, ColorScheme cs) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: cs.primary.withValues(alpha: 0.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: session.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: session.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Icon(Icons.restaurant,
                  color: cs.primary.withValues(alpha: 0.5), size: 20),
              errorWidget: (_, __, ___) => Icon(Icons.restaurant,
                  color: cs.primary.withValues(alpha: 0.5), size: 20),
            )
          : Icon(Icons.restaurant,
              color: cs.primary.withValues(alpha: 0.5), size: 20),
    );
  }

  Widget _buildTimerChip(
      CookingSession session, ColorScheme cs, ThemeData theme) {
    final isRunning = session.timerStatus == TimerStatus.running;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRunning
            ? cs.primary.withValues(alpha: 0.2)
            : cs.tertiary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRunning ? Icons.timer : Icons.pause,
            size: 10,
            color: isRunning ? cs.primary : cs.tertiary,
          ),
          const SizedBox(width: 3),
          Text(
            session.timerDisplayString,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: isRunning ? cs.primary : cs.tertiary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCooking(BuildContext context, CookingSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CookingRunScreen(
          recipeId: session.recipeId,
          title: session.title,
          steps: session.steps,
          ingredients: session.ingredients,
          matchedIngredientsCount: session.matchedIngredientsCount,
          matchPct: session.matchPct,
          userInventoryText: session.userInventoryText,
          servingsCooked: session.servingsCooked,
          originalServings: session.originalServings,
          ownedIngredientIds: session.ownedIngredientIds,
          calories: session.calories,
          proteinG: session.proteinG,
          carbsG: session.carbsG,
          fatG: session.fatG,
          isBeginnerMode: session.isBeginnerMode,
          restoreFromSession: true,
        ),
      ),
    );
  }

  void _showStopDialog(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 24),
            const SizedBox(width: 8),
            const Text('Stop Cooking?'),
          ],
        ),
        content: const Text(
          'This will end your current cooking session. '
          'Timer progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Cooking',
                style: TextStyle(color: cs.primary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(cookingSessionProvider.notifier).endSession();
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}
