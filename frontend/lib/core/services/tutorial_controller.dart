import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plately_app/core/services/tutorial_service.dart';

/// The different states of our interactive task-oriented tutorial.
enum TutorialState {
  none,          // Tutorial not active
  welcome,       // Welcome prompt showing (Start vs Skip)
  shelfIntro,    // On Shelf tab, explaining the three tabs
  clickAdd,      // On Shelf tab, prompting the user to click the "Add Ingredient" FAB
  scanIntro,     // On Scan tab, explaining scanning and prompting to load mock ingredients
  shelfAdded,    // Back on Shelf tab, showing the loaded ingredients, prompting to go to Cook tab
  roamCook,      // On Cook tab, explaining the 5 tiers, prompting to choose the stir-fry recipe
  recipeDetail,  // On Recipe Detail screen, prompting to tap "Start Cooking"
  cookingPrep,   // On Prep screen, prompting to tap "Begin Step-by-Step"
  cookingRun,    // On Cooking Run screen, guiding them through steps to the end
  finish,        // Cooking finished, showing the final cleanup/sandbox completion dialog
}

/// State notifier that manages the interactive tutorial lifecycle in-memory.
class TutorialController extends Notifier<TutorialState> {
  static const String _skippedKey = 'tutorial_skipped';

  @override
  TutorialState build() {
    _init();
    return TutorialState.none;
  }

  Future<void> _init() async {
    // We check if the tutorial has been completed.
    final completed = await TutorialService().isCompleted(TutorialService.homeWalkthrough);
    if (!completed) {
      // If not completed, start directly at the tutorial steps without the initial welcome popup.
      state = TutorialState.shelfIntro;
    }
  }

  /// Start the interactive tutorial.
  void startTutorial() {
    state = TutorialState.shelfIntro;
  }

  /// Skip the tutorial from the welcome dialog.
  Future<void> skipTutorial() async {
    state = TutorialState.none;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skippedKey, true);
    await TutorialService().markCompleted(TutorialService.homeWalkthrough);
  }

  /// Set explicit tutorial state (used for stepping through actions).
  void setStep(TutorialState nextState) {
    if (state != TutorialState.none) {
      state = nextState;
    }
  }

  /// Reset the tutorial to show again (e.g. from Profile settings).
  Future<void> resetAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skippedKey);
    await TutorialService().reset(TutorialService.homeWalkthrough);
    state = TutorialState.shelfIntro;
  }

  /// Check if the tutorial was previously skipped by the user.
  Future<bool> wasSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skippedKey) ?? false;
  }

  /// Finish the tutorial and mark it as completed.
  Future<void> completeTutorial() async {
    state = TutorialState.none;
    await TutorialService().markCompleted(TutorialService.homeWalkthrough);
  }
}

/// Provider for the TutorialState.
final tutorialControllerProvider =
    NotifierProvider<TutorialController, TutorialState>(TutorialController.new);
