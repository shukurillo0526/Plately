// ═══════════════════════════════════════════════════════════════════
//  Plately — Step Timer Widget
//  Circular countdown timer with animated progress ring.
//  Integrates with CookingSessionProvider for state persistence.
// ═══════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plately_app/features/cook/models/cooking_session.dart';
import 'package:plately_app/features/cook/providers/cooking_session_provider.dart';

class StepTimerWidget extends ConsumerStatefulWidget {
  final int timerSeconds;
  final VoidCallback? onComplete;

  const StepTimerWidget({
    super.key,
    required this.timerSeconds,
    this.onComplete,
  });

  @override
  ConsumerState<StepTimerWidget> createState() => _StepTimerWidgetState();
}

class _StepTimerWidgetState extends ConsumerState<StepTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(cookingSessionProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final timerStatus = session?.timerStatus ?? TimerStatus.idle;
    final remaining = session?.timerRemainingSeconds ?? 0;
    final total = session?.timerTotalSeconds ?? widget.timerSeconds;
    final progress = total > 0 ? remaining / total : 0.0;

    // Pulse animation when < 30 seconds
    if (timerStatus == TimerStatus.running && remaining <= 30 && remaining > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    // Timer complete callback
    if (timerStatus == TimerStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete?.call();
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getTimerColor(timerStatus, remaining, cs)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Timer ring ──
          SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = timerStatus == TimerStatus.running &&
                        remaining <= 30 &&
                        remaining > 0
                    ? 1.0 + (_pulseController.value * 0.03)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: CustomPaint(
                    painter: _TimerRingPainter(
                      progress: progress,
                      color: _getTimerColor(timerStatus, remaining, cs),
                      backgroundColor:
                          cs.onSurface.withValues(alpha: 0.1),
                      strokeWidth: 6,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(remaining),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _getTimerColor(
                                  timerStatus, remaining, cs),
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          if (timerStatus == TimerStatus.completed)
                            Text(
                              'Done!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Controls ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (timerStatus == TimerStatus.idle ||
                  timerStatus == TimerStatus.completed) ...[
                _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: timerStatus == TimerStatus.completed
                      ? 'Restart'
                      : 'Start',
                  color: cs.primary,
                  onTap: () {
                    ref
                        .read(cookingSessionProvider.notifier)
                        .startTimer(widget.timerSeconds);
                  },
                ),
              ],
              if (timerStatus == TimerStatus.running) ...[
                _ActionButton(
                  icon: Icons.pause_rounded,
                  label: 'Pause',
                  color: cs.tertiary,
                  onTap: () {
                    ref
                        .read(cookingSessionProvider.notifier)
                        .pauseTimer();
                  },
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.stop_rounded,
                  label: 'Stop',
                  color: cs.error,
                  onTap: () {
                    ref
                        .read(cookingSessionProvider.notifier)
                        .stopTimer();
                  },
                ),
              ],
              if (timerStatus == TimerStatus.paused) ...[
                _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Resume',
                  color: cs.primary,
                  onTap: () {
                    ref
                        .read(cookingSessionProvider.notifier)
                        .resumeTimer();
                  },
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.stop_rounded,
                  label: 'Stop',
                  color: cs.error,
                  onTap: () {
                    ref
                        .read(cookingSessionProvider.notifier)
                        .stopTimer();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getTimerColor(TimerStatus status, int remaining, ColorScheme cs) {
    switch (status) {
      case TimerStatus.running when remaining <= 30:
        return cs.error;
      case TimerStatus.running:
        return cs.primary;
      case TimerStatus.paused:
        return cs.tertiary;
      case TimerStatus.completed:
        return cs.primary;
      case TimerStatus.idle:
        return cs.onSurface.withValues(alpha: 0.4);
    }
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }
}

// ── Action Button ──────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timer Ring Painter ─────────────────────────────────────────

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        2 * math.pi * progress, // Sweep clockwise
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}
