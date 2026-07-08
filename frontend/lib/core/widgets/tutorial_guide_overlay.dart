import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plately_app/core/services/tutorial_controller.dart';
import 'package:plately_app/l10n/app_localizations.dart';

class TutorialGuideOverlay extends ConsumerStatefulWidget {
  const TutorialGuideOverlay({super.key});

  @override
  ConsumerState<TutorialGuideOverlay> createState() => _TutorialGuideOverlayState();
}

class _TutorialGuideOverlayState extends ConsumerState<TutorialGuideOverlay> {
  bool _isMinimized = false;
  bool _isSimulatingScan = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialControllerProvider);
    if (state == TutorialState.none) return const SizedBox.shrink();

    final notifier = ref.read(tutorialControllerProvider.notifier);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    // Define spotlights based on step
    Rect? spotlightRect;
    double cardTop;
    String emoji = '💡';
    String title = '';
    String description = '';
    String? primaryButtonLabel;
    VoidCallback? onPrimaryPressed;
    String? secondaryButtonLabel;
    VoidCallback? onSecondaryPressed;

    switch (state) {
      case TutorialState.welcome:
        cardTop = size.height * 0.3;
        emoji = '🧑‍🍳';
        title = l10n?.tutorial_tourTitle ?? 'Plately Interactive Tour';
        description = l10n?.tutorial_tourDesc ?? 'Welcome! Let\'s take a quick 1-minute interactive tour of Plately. We will show you how to manage your ingredients, discover matching recipes, and start cooking!';
        primaryButtonLabel = l10n?.tutorial_startTour ?? 'Start Tour 🚀';
        onPrimaryPressed = () => notifier.startTutorial();
        secondaryButtonLabel = l10n?.tutorial_skipTour ?? 'Skip';
        onSecondaryPressed = () => notifier.skipTutorial();
        break;

      case TutorialState.shelfIntro:
        // Spotlight the entire bottom nav bar containing three tabs
        spotlightRect = Rect.fromLTWH(0, size.height - 80, size.width, 80);
        cardTop = size.height * 0.35;
        emoji = '📦';
        title = l10n?.tutorial_shelfIntroTitle ?? 'Your Digital Shelf';
        description = l10n?.tutorial_shelfIntroDesc ?? 'This is your digital fridge, freezer, and pantry. Here you can track quantities and expiry dates — we\'ll warn you before food goes bad. Let\'s see how it works!';
        primaryButtonLabel = l10n?.tutorial_nextArrow ?? 'Next →';
        onPrimaryPressed = () => notifier.setStep(TutorialState.clickAdd);
        break;

      case TutorialState.clickAdd:
        // Spotlight the center tab (Scan tab)
        spotlightRect = Rect.fromLTWH(size.width / 3, size.height - 80, size.width / 3, 80);
        cardTop = size.height * 0.45;
        emoji = '📸';
        title = l10n?.tutorial_addIntroTitle ?? 'Add Ingredients';
        description = l10n?.tutorial_addIntroDesc ?? 'To add ingredients, tap the Scan tab (center camera icon) in the navigation bar. Go ahead, tap it!';
        primaryButtonLabel = l10n?.tutorial_bypassScan ?? 'Bypass (Go to Scan)';
        onPrimaryPressed = () {
          notifier.setStep(TutorialState.scanIntro);
        };
        break;

      case TutorialState.scanIntro:
        cardTop = size.height * 0.3;
        emoji = '🔍';
        title = l10n?.tutorial_scanIntroTitle ?? 'Scan & Manually Add';
        description = l10n?.tutorial_scanIntroDesc ?? 'Here you can scan receipts, barcodes, or snap a photo of ingredients. For this tutorial, we will automatically load 5 mock ingredients needed for a special stir-fry recipe.';
        primaryButtonLabel = l10n?.tutorial_loadMock ?? 'Load Mock Ingredients 🛒';
        onPrimaryPressed = () async {
          setState(() => _isSimulatingScan = true);
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            setState(() => _isSimulatingScan = false);
            notifier.setStep(TutorialState.shelfAdded);
          }
        };
        break;

      case TutorialState.shelfAdded:
        // Spotlight the bottom right tab (Shelf tab) to go back, or highlight the new items
        // We highlight the Cook tab (index 0) because we've already automatically navigated back to Shelf
        spotlightRect = Rect.fromLTWH(0, size.height - 80, size.width / 3, 80);
        cardTop = size.height * 0.4;
        emoji = '🥦';
        title = l10n?.tutorial_shelfAddedTitle ?? 'Ingredients Loaded!';
        description = l10n?.tutorial_shelfAddedDesc ?? 'Great! We\'ve loaded: Chicken Breast, Broccoli, Soy Sauce, Garlic, and Sesame Oil. Let\'s see what we can cook! Tap the Cook tab (left restaurant icon) to find matching recipes.';
        primaryButtonLabel = l10n?.tutorial_bypassCook ?? 'Bypass (Go to Cook)';
        onPrimaryPressed = () {
          notifier.setStep(TutorialState.roamCook);
        };
        break;

      case TutorialState.roamCook:
        // Spotlight the top tab bar of CookScreen and the first recipe
        spotlightRect = Rect.fromLTWH(12, 180, size.width - 24, 450);
        cardTop = size.height * 0.45;
        emoji = '🥘';
        title = l10n?.tutorial_roamCookTitle ?? '5-Tier Recommendations';
        description = l10n?.tutorial_roamCookDesc ?? 'Here you see the 5-tier recommendation tabs (Perfect, For You, Use It Up, Almost, Explore). Tap around to explore them! When you are ready, tap the "Tutorial Chicken Stir-fry" recipe card under the Perfect tab.';
        // Removed the Next button as requested, user must tap the recipe card directly.
        break;

      case TutorialState.recipeDetail:
        cardTop = size.height * 0.4;
        emoji = '📋';
        title = l10n?.tutorial_recipeDetailTitle ?? 'Recipe Details';
        description = l10n?.tutorial_recipeDetailDesc ?? 'Here you see the ingredients list and steps. Tap the "Start Cooking" button at the bottom of the page to begin!';
        break;

      case TutorialState.cookingPrep:
        cardTop = size.height * 0.4;
        emoji = '🔪';
        title = l10n?.tutorial_cookingPrepTitle ?? 'Prep & Ingredients';
        description = l10n?.tutorial_cookingPrepDesc ?? 'Before turning on the heat, wash and chop your ingredients. Tap the "Begin Step-by-Step" button to start the cooking assistant!';
        break;

      case TutorialState.cookingRun:
        cardTop = size.height * 0.25;
        emoji = '🍳';
        title = l10n?.tutorial_cookingRunTitle ?? 'Cooking Assistant';
        description = l10n?.tutorial_cookingRunDesc ?? 'The assistant guides you step-by-step. You can also chat with the AI assistant at the bottom for substitutions or cooking questions! Step through the recipe and tap "Finish" on the final step.';
        break;

      case TutorialState.finish:
        cardTop = size.height * 0.3;
        emoji = '🏆';
        title = l10n?.tutorial_finishTitle ?? 'Tutorial Completed!';
        description = l10n?.tutorial_finishDesc ?? 'Congratulations! You\'ve completed the Plately cook tour.\n\nNote: All ingredients and data used in this tutorial will not be saved. This is just a small portion of the app. Tap "Finish Tour" to start your own cooking journey!';
        primaryButtonLabel = l10n?.tutorial_finishTour ?? 'Finish Tour 🏁';
        onPrimaryPressed = () => notifier.completeTutorial();
        break;

      default:
        return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // ── Spotlight Mask ──
        Positioned.fill(
          child: IgnorePointer(
            ignoring: state == TutorialState.clickAdd || state == TutorialState.shelfAdded || state == TutorialState.roamCook,
            child: CustomPaint(
              painter: _SpotlightPainter(
                targetRect: spotlightRect,
                overlayColor: Colors.black.withValues(alpha: 0.7),
                borderColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),

        // ── Guided Tooltip Card ──
        if (_isMinimized)
          Positioned(
            top: cardTop,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => setState(() => _isMinimized = false),
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          )
        else
          Positioned(
            top: cardTop,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 32),
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                      if (primaryButtonLabel != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (secondaryButtonLabel != null) ...[
                              TextButton(
                                onPressed: onSecondaryPressed,
                                child: Text(
                                  secondaryButtonLabel,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: FilledButton(
                                onPressed: onPrimaryPressed,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  primaryButtonLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: Icon(Icons.close_fullscreen, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      onPressed: () => setState(() => _isMinimized = true),
                      tooltip: 'Minimize',
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Simulating Scan Overlay ──
        if (_isSimulatingScan)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.import_analyzing ?? 'Analyzing...',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;
  final Color borderColor;

  _SpotlightPainter({
    this.targetRect, 
    required this.overlayColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    if (targetRect != null) {
      final outer = Path()..addRect(Offset.zero & size);
      final spotlightRect = RRect.fromRectAndRadius(
        targetRect!.inflate(8),
        const Radius.circular(16),
      );
      final inner = Path()..addRRect(spotlightRect);
      final combined = Path.combine(PathOperation.difference, outer, inner);
      canvas.drawPath(combined, paint);

      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawRRect(spotlightRect, borderPaint);
    } else {
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect || borderColor != oldDelegate.borderColor;
}
