// ═══════════════════════════════════════════════════════════════════
//  Plately — Cooking Session Provider
//  Riverpod Notifier managing the active cooking session.
//
//  Features:
//    - Single active session at a time
//    - Auto-persists to Hive on every state change
//    - Restores session on app launch
//    - Timer management (start/pause/stop)
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:plately_app/features/cook/models/cooking_session.dart';
import 'package:plately_app/core/services/cooking_notification_service.dart';

/// Hive box name for persisting the cooking session
const _kSessionBoxName = 'cooking_session';
const _kSessionKey = 'active_session';

/// The global cooking session provider
final cookingSessionProvider =
    NotifierProvider<CookingSessionNotifier, CookingSession?>(
  CookingSessionNotifier.new,
);

/// Manages the lifecycle of an active cooking session
class CookingSessionNotifier extends Notifier<CookingSession?> {
  Timer? _countdownTimer;

  @override
  CookingSession? build() {
    // Restore persisted session on first build
    _restoreSessionSync();
    ref.onDispose(() {
      _cancelTimer();
    });
    return state;
  }

  // ── Session Lifecycle ──────────────────────────────────────────

  /// Start a new cooking session
  void startSession({
    required String recipeId,
    required String title,
    String? imageUrl,
    required List<Map<String, dynamic>> steps,
    List<Map<String, dynamic>>? ingredients,
    bool isBeginnerMode = false,
    int servingsCooked = 1,
    int originalServings = 1,
    double matchPct = 0.0,
    int matchedIngredientsCount = 0,
    String userInventoryText = '',
    Set<String> ownedIngredientIds = const {},
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
  }) {
    // Cancel any existing timer
    _cancelTimer();

    state = CookingSession(
      recipeId: recipeId,
      title: title,
      imageUrl: imageUrl,
      steps: steps,
      ingredients: ingredients,
      isBeginnerMode: isBeginnerMode,
      servingsCooked: servingsCooked,
      originalServings: originalServings,
      startedAt: DateTime.now(),
      matchPct: matchPct,
      matchedIngredientsCount: matchedIngredientsCount,
      userInventoryText: userInventoryText,
      ownedIngredientIds: ownedIngredientIds,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );

    _persistSession();
    _updateNotification();
  }

  /// End the current cooking session (user finished or stopped)
  void endSession() {
    final title = state?.title;
    _cancelTimer();
    state = null;
    _clearPersistedSession();

    // Dismiss notification or show "Complete!" 
    if (title != null) {
      CookingNotificationService.instance.showCookingComplete(
        recipeTitle: title,
      );
    } else {
      CookingNotificationService.instance.cancelAll();
    }
  }

  // ── Step Navigation ────────────────────────────────────────────

  /// Move to the next step
  void advanceStep() {
    if (state == null || state!.isLastStep) return;
    _cancelTimer();
    state = state!.copyWith(
      currentStepIndex: state!.currentStepIndex + 1,
      timerStatus: TimerStatus.idle,
      timerTotalSeconds: null,
      timerRemainingSeconds: 0,
      timerStartedAt: null,
    );
    _persistSession();
    _updateNotification();
  }

  /// Move to the previous step
  void previousStep() {
    if (state == null || state!.currentStepIndex <= 0) return;
    _cancelTimer();
    state = state!.copyWith(
      currentStepIndex: state!.currentStepIndex - 1,
      timerStatus: TimerStatus.idle,
      timerTotalSeconds: null,
      timerRemainingSeconds: 0,
      timerStartedAt: null,
    );
    _persistSession();
    _updateNotification();
  }

  /// Jump to a specific step
  void goToStep(int index) {
    if (state == null || index < 0 || index >= state!.totalSteps) return;
    _cancelTimer();
    state = state!.copyWith(
      currentStepIndex: index,
      timerStatus: TimerStatus.idle,
      timerTotalSeconds: null,
      timerRemainingSeconds: 0,
      timerStartedAt: null,
    );
    _persistSession();
    _updateNotification();
  }

  // ── Timer Management ───────────────────────────────────────────

  /// Start the countdown timer for the current step
  void startTimer(int totalSeconds) {
    if (state == null) return;
    _cancelTimer();

    state = state!.copyWith(
      timerTotalSeconds: totalSeconds,
      timerRemainingSeconds: totalSeconds,
      timerStatus: TimerStatus.running,
      timerStartedAt: DateTime.now(),
    );

    _startCountdown();
    _persistSession();
    _updateNotification();
  }

  /// Pause the running timer
  void pauseTimer() {
    if (state == null || state!.timerStatus != TimerStatus.running) return;
    _cancelTimer();

    state = state!.copyWith(
      timerStatus: TimerStatus.paused,
    );
    _persistSession();
    _updateNotification();
  }

  /// Resume a paused timer
  void resumeTimer() {
    if (state == null || state!.timerStatus != TimerStatus.paused) return;

    state = state!.copyWith(
      timerStatus: TimerStatus.running,
      timerStartedAt: DateTime.now(),
    );

    _startCountdown();
    _persistSession();
    _updateNotification();
  }

  /// Stop/reset the timer
  void stopTimer() {
    if (state == null) return;
    _cancelTimer();

    state = state!.copyWith(
      timerStatus: TimerStatus.idle,
      timerTotalSeconds: null,
      timerRemainingSeconds: 0,
      timerStartedAt: null,
    );
    _persistSession();
    _updateNotification();
  }

  /// Callback when timer completes — override this to trigger notifications
  void Function()? onTimerComplete;

  // ── Private Timer Logic ────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == null || state!.timerStatus != TimerStatus.running) {
        _cancelTimer();
        return;
      }

      final remaining = state!.timerRemainingSeconds - 1;
      if (remaining <= 0) {
        // Timer completed!
        _cancelTimer();
        state = state!.copyWith(
          timerRemainingSeconds: 0,
          timerStatus: TimerStatus.completed,
        );
        _persistSession();

        // Show timer complete notification
        CookingNotificationService.instance.showTimerComplete(
          recipeTitle: state!.title,
          stepNumber: state!.currentStepIndex + 1,
        );
        _updateNotification();

        // Trigger notification callback
        onTimerComplete?.call();
      } else {
        state = state!.copyWith(
          timerRemainingSeconds: remaining,
        );
        // Update notification every 5 seconds to avoid excessive updates
        if (remaining % 5 == 0) {
          _persistSession();
          _updateNotification();
        }
      }
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // ── Hive Persistence ───────────────────────────────────────────

  Future<void> _persistSession() async {
    try {
      final box = await Hive.openBox(_kSessionBoxName);
      if (state != null) {
        await box.put(_kSessionKey, state!.toJsonString());
      } else {
        await box.delete(_kSessionKey);
      }
    } catch (e) {
      // Silently fail — persistence is best-effort
    }
  }

  Future<void> _clearPersistedSession() async {
    try {
      final box = await Hive.openBox(_kSessionBoxName);
      await box.delete(_kSessionKey);
    } catch (e) {
      // Silently fail
    }
  }

  void _restoreSessionSync() {
    try {
      // Hive box should already be open from CacheService init
      if (Hive.isBoxOpen(_kSessionBoxName)) {
        final box = Hive.box(_kSessionBoxName);
        final jsonString = box.get(_kSessionKey) as String?;
        if (jsonString != null) {
          final session = CookingSession.fromJsonString(jsonString);

          // If timer was running, calculate elapsed time since save
          if (session.timerStatus == TimerStatus.running &&
              session.timerStartedAt != null) {
            final elapsed =
                DateTime.now().difference(session.timerStartedAt!).inSeconds;
            final remaining = session.timerRemainingSeconds - elapsed;

            if (remaining <= 0) {
              state = session.copyWith(
                timerRemainingSeconds: 0,
                timerStatus: TimerStatus.completed,
              );
            } else {
              state = session.copyWith(
                timerRemainingSeconds: remaining,
              );
              _startCountdown();
            }
          } else {
            state = session;
          }
        }
      } else {
        // Open box async and restore
        Hive.openBox(_kSessionBoxName).then((box) {
          final jsonString = box.get(_kSessionKey) as String?;
          if (jsonString != null) {
            state = CookingSession.fromJsonString(jsonString);
          }
        });
      }
    } catch (e) {
      // If restore fails, start fresh
    }
  }

  // ── Notification Updates ────────────────────────────────────────

  void _updateNotification() {
    if (state == null) return;
    CookingNotificationService.instance.showCookingProgress(
      recipeTitle: state!.title,
      currentStep: state!.currentStepIndex + 1,
      totalSteps: state!.totalSteps,
      timerText: state!.isTimerActive || state!.timerStatus == TimerStatus.paused
          ? state!.timerDisplayString
          : null,
      isTimerRunning: state!.isTimerActive,
      isTimerPaused: state!.timerStatus == TimerStatus.paused,
    );
  }
}
