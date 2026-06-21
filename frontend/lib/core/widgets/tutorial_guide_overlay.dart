import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plately_app/core/services/tutorial_controller.dart';

class TutorialGuideOverlay extends ConsumerWidget {
  const TutorialGuideOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorialControllerProvider);
    if (state == TutorialState.none) return const SizedBox.shrink();

    final notifier = ref.read(tutorialControllerProvider.notifier);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

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
        title = 'Plately Interactive Tour';
        description = 'Welcome! Let\'s take a quick 1-minute interactive tour of Plately. We will show you how to manage your ingredients, discover matching recipes, and start cooking!';
        primaryButtonLabel = 'Start Tour 🚀';
        onPrimaryPressed = () => notifier.startTutorial();
        secondaryButtonLabel = 'Skip';
        onSecondaryPressed = () => notifier.skipTutorial();
        break;

      case TutorialState.shelfIntro:
        // Spotlight the entire bottom nav bar containing three tabs
        spotlightRect = Rect.fromLTWH(0, size.height - 80, size.width, 80);
        cardTop = size.height * 0.35;
        emoji = '📦';
        title = 'Your Digital Shelf';
        description = 'This is your digital fridge, freezer, and pantry. Here you can track quantities and expiry dates — we\'ll warn you before food goes bad. Let\'s see how it works!';
        primaryButtonLabel = 'Next →';
        onPrimaryPressed = () => notifier.setStep(TutorialState.clickAdd);
        break;

      case TutorialState.clickAdd:
        // Spotlight the center tab (Scan tab)
        spotlightRect = Rect.fromLTWH(size.width / 3, size.height - 80, size.width / 3, 80);
        cardTop = size.height * 0.45;
        emoji = '📸';
        title = 'Add Ingredients';
        description = 'To add ingredients, tap the Scan tab (center camera icon) in the navigation bar. Go ahead, tap it!';
        // No buttons here, the user must tap the tab!
        // We'll let them click the card to bypass just in case:
        primaryButtonLabel = 'Bypass (Go to Scan)';
        onPrimaryPressed = () {
          // Switch to Scan tab (index 1) and advance
          notifier.setStep(TutorialState.scanIntro);
        };
        break;

      case TutorialState.scanIntro:
        cardTop = size.height * 0.3;
        emoji = '🔍';
        title = 'Scan & Manually Add';
        description = 'Here you can scan receipts, barcodes, or snap a photo of ingredients. For this tutorial, we will automatically load 5 mock ingredients needed for a special stir-fry recipe.';
        primaryButtonLabel = 'Load Mock Ingredients 🛒';
        onPrimaryPressed = () {
          notifier.setStep(TutorialState.shelfAdded);
        };
        break;

      case TutorialState.shelfAdded:
        // Spotlight the bottom right tab (Shelf tab) to go back, or highlight the new items
        // We highlight the Cook tab (index 0) because we've already automatically navigated back to Shelf
        spotlightRect = Rect.fromLTWH(0, size.height - 80, size.width / 3, 80);
        cardTop = size.height * 0.4;
        emoji = '🥦';
        title = 'Ingredients Loaded!';
        description = 'Great! We\'ve loaded: Chicken Breast, Broccoli, Soy Sauce, Garlic, and Sesame Oil. Let\'s see what we can cook! Tap the Cook tab (left restaurant icon) to find matching recipes.';
        primaryButtonLabel = 'Bypass (Go to Cook)';
        onPrimaryPressed = () {
          notifier.setStep(TutorialState.roamCook);
        };
        break;

      case TutorialState.roamCook:
        // Spotlight the top tab bar of CookScreen and the first recipe
        spotlightRect = Rect.fromLTWH(12, 180, size.width - 24, 150);
        cardTop = size.height * 0.45;
        emoji = '🥘';
        title = '5-Tier Recommendations';
        description = 'Here you see the 5-tier recommendation tabs (Perfect, For You, Use It Up, Almost, Explore). Tap around to explore them! When you are ready, tap the "Tutorial Chicken Stir-fry" recipe card under the Perfect tab.';
        primaryButtonLabel = 'Next';
        onPrimaryPressed = () {
          // Keep it simple, just guide the user
        };
        break;

      case TutorialState.recipeDetail:
        cardTop = size.height * 0.4;
        emoji = '📋';
        title = 'Recipe Details';
        description = 'Here you see the ingredients list and steps. Tap the "Start Cooking" button at the bottom of the page to begin!';
        break;

      case TutorialState.cookingPrep:
        cardTop = size.height * 0.4;
        emoji = '🔪';
        title = 'Prep & Ingredients';
        description = 'Before turning on the heat, wash and chop your ingredients. Tap the "Begin Step-by-Step" button to start the cooking assistant!';
        break;

      case TutorialState.cookingRun:
        cardTop = size.height * 0.25;
        emoji = '🍳';
        title = 'Cooking Assistant';
        description = 'The assistant guides you step-by-step. You can also chat with the AI assistant at the bottom for substitutions or cooking questions! Step through the recipe and tap "Finish" on the final step.';
        break;

      case TutorialState.finish:
        cardTop = size.height * 0.3;
        emoji = '🏆';
        title = 'Tutorial Completed!';
        description = 'Congratulations! You\'ve completed the Plately cook tour.\n\nNote: All ingredients and data used in this tutorial will not be saved. This is just a small portion of the app. Tap "Finish Tour" to start your own cooking journey!';
        primaryButtonLabel = 'Finish Tour 🏁';
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
              ),
            ),
          ),
        ),

        // ── Guided Tooltip Card ──
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
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
          ),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;

  _SpotlightPainter({this.targetRect, required this.overlayColor});

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
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(spotlightRect, borderPaint);
    } else {
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      targetRect != oldDelegate.targetRect;
}
