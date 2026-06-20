// Plately — Tutorial Overlay
// ==============================
// A full-screen overlay widget that guides users through app features
// with spotlight-highlighted regions and animated tooltip cards.
// Designed as a production-grade onboarding system.

import 'package:flutter/material.dart';
import 'package:plately_app/core/services/tutorial_service.dart';
import 'package:plately_app/l10n/app_localizations.dart';

/// A single step in a tutorial flow.
class TutorialStep {
  /// Title shown in the tooltip card.
  final String title;

  /// Description shown below the title.
  final String description;

  /// Emoji icon shown before the title.
  final String emoji;

  /// Where to position the tooltip relative to the spotlight.
  final TooltipPosition tooltipPosition;

  /// Target area to spotlight (null = center of screen, no spotlight).
  final Rect? targetRect;

  /// Tab index to switch to before showing this step (null = stay on current tab).
  final int? targetTabIndex;

  const TutorialStep({
    required this.title,
    required this.description,
    this.emoji = '💡',
    this.tooltipPosition = TooltipPosition.below,
    this.targetRect,
    this.targetTabIndex,
  });
}

enum TooltipPosition { above, below, center }

/// Shows a tutorial overlay on top of the current screen.
/// Usage:
/// ```dart
/// TutorialOverlay.show(
///   context: context,
///   tutorialId: TutorialService.homeWalkthrough,
///   steps: [...],
/// );
/// ```
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final String tutorialId;
  final VoidCallback onComplete;
  final void Function(int tabIndex)? onTabSwitch;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.tutorialId,
    required this.onComplete,
    this.onTabSwitch,
  });

  /// Show the tutorial if it hasn't been completed yet.
  static Future<bool> show({
    required BuildContext context,
    required String tutorialId,
    required List<TutorialStep> steps,
    void Function(int tabIndex)? onTabSwitch,
  }) async {
    final service = TutorialService();
    final completed = await service.isCompleted(tutorialId);
    if (completed) return false;

    if (!context.mounted) return false;

    // Switch to the first step's tab if specified
    if (steps.isNotEmpty && steps.first.targetTabIndex != null && onTabSwitch != null) {
      onTabSwitch(steps.first.targetTabIndex!);
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (ctx, anim, secondAnim) => TutorialOverlay(
          steps: steps,
          tutorialId: tutorialId,
          onTabSwitch: onTabSwitch,
          onComplete: () {
            service.markCompleted(tutorialId);
            Navigator.of(ctx).pop();
          },
        ),
        transitionsBuilder: (ctx, anim, secondAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    return true;
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _animController.reset();
      setState(() => _currentStep++);
      // Switch tab if the step has a target
      final step = widget.steps[_currentStep];
      if (step.targetTabIndex != null && widget.onTabSwitch != null) {
        widget.onTabSwitch!(step.targetTabIndex!);
      }
      _animController.forward();
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final size = MediaQuery.of(context).size;
    final isLast = _currentStep == widget.steps.length - 1;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _nextStep,
        child: Stack(
          children: [
            // ── Dark overlay with optional spotlight cutout ──
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: step.targetRect,
                  overlayColor: Colors.black.withValues(alpha: 0.75),
                ),
              ),
            ),

            // ── Skip button (top right) ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    l10n?.auto_cancel ?? 'Skip',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // ── Step counter (top left) ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 18,
              left: 20,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentStep + 1} / ${widget.steps.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // ── Tooltip Card ──
            _buildTooltipCard(step, size, isLast, l10n),

            // ── Page indicator dots ──
            if (widget.steps.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.steps.length, (i) {
                      final isActive = i == _currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipCard(
      TutorialStep step, Size size, bool isLast, AppLocalizations? l10n) {
    // Position the tooltip
    double top;
    switch (step.tooltipPosition) {
      case TooltipPosition.above:
        top = (step.targetRect?.top ?? size.height * 0.4) - 200;
        break;
      case TooltipPosition.below:
        top = (step.targetRect?.bottom ?? size.height * 0.3) + 24;
        break;
      case TooltipPosition.center:
        top = size.height * 0.35;
        break;
    }
    top = top.clamp(100.0, size.height - 280);

    return Positioned(
      top: top,
      left: 24,
      right: 24,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji + Title
              Row(
                children: [
                  Text(step.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                step.description,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _nextStep,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isLast
                        ? (l10n?.tutorial_gotIt ?? 'Got it! 🎉')
                        : (l10n?.tutorial_next ?? 'Next →'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that renders a dark overlay with a spotlight cutout.
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;

  _SpotlightPainter({
    this.targetRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    if (targetRect != null) {
      // Create a path with a hole for the spotlight
      final outer = Path()..addRect(Offset.zero & size);
      final spotlightRect = RRect.fromRectAndRadius(
        targetRect!.inflate(8), // Add padding around the target
        const Radius.circular(12),
      );
      final inner = Path()..addRRect(spotlightRect);
      final combined = Path.combine(PathOperation.difference, outer, inner);
      canvas.drawPath(combined, paint);

      // Draw a subtle glow border around the spotlight
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(spotlightRect, borderPaint);
    } else {
      // No spotlight — just dark overlay
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect;
}
