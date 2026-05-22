// ═══════════════════════════════════════════════════════════════════
//  Plately — Cooking Notification Service
//  Manages persistent cooking notifications and timer alerts.
//
//  Features:
//    - Ongoing "Now Cooking" notification (can't be swiped away)
//    - Timer countdown updates in notification
//    - Timer completion alarm with vibration
//    - Action buttons: Next Step, Pause/Resume, Stop
//    - Auto-dismiss on session end
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification IDs
const _kCookingProgressId = 1001;
const _kTimerCompleteId = 1002;

/// Notification channel IDs
const _kCookingProgressChannel = 'cooking_progress';
const _kTimerAlertChannel = 'cooking_timer';

/// Action IDs for notification buttons
const kActionNextStep = 'ACTION_NEXT_STEP';
const kActionPauseTimer = 'ACTION_PAUSE_TIMER';
const kActionResumeTimer = 'ACTION_RESUME_TIMER';
const kActionStopCooking = 'ACTION_STOP_COOKING';

class CookingNotificationService {
  CookingNotificationService._();
  static final instance = CookingNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback for notification actions
  void Function(String actionId)? onAction;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Ongoing cooking progress channel (low priority, silent)
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _kCookingProgressChannel,
            'Cooking Progress',
            description: 'Shows current cooking step and timer',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );

        // Timer alert channel (high priority, with sound)
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _kTimerAlertChannel,
            'Cooking Timer Alerts',
            description: 'Alerts when a cooking timer completes',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    }

    _initialized = true;
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? false;
      return granted;
    }
    return true; // iOS handles in init
  }

  // ── Cooking Progress Notification ──────────────────────────────

  /// Show/update the ongoing cooking notification
  Future<void> showCookingProgress({
    required String recipeTitle,
    required int currentStep,
    required int totalSteps,
    String? timerText,
    bool isTimerRunning = false,
    bool isTimerPaused = false,
  }) async {
    if (!_initialized) return;

    final stepInfo = 'Step $currentStep of $totalSteps';
    final bodyParts = <String>[stepInfo];
    if (timerText != null && timerText.isNotEmpty) {
      final prefix = isTimerPaused ? '⏸ ' : '⏱ ';
      bodyParts.add('$prefix$timerText');
    }

    // Build action buttons
    final actions = <AndroidNotificationAction>[];
    if (currentStep < totalSteps) {
      actions.add(const AndroidNotificationAction(
        kActionNextStep,
        'Next Step',
        showsUserInterface: false,
      ));
    }
    if (isTimerRunning) {
      actions.add(const AndroidNotificationAction(
        kActionPauseTimer,
        'Pause',
        showsUserInterface: false,
      ));
    } else if (isTimerPaused) {
      actions.add(const AndroidNotificationAction(
        kActionResumeTimer,
        'Resume',
        showsUserInterface: false,
      ));
    }
    actions.add(const AndroidNotificationAction(
      kActionStopCooking,
      'Stop',
      showsUserInterface: true,
    ));

    final androidDetails = AndroidNotificationDetails(
      _kCookingProgressChannel,
      'Cooking Progress',
      channelDescription: 'Shows current cooking step and timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Can't be swiped away
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      actions: actions,
      // Progress bar for step completion
      showProgress: true,
      maxProgress: totalSteps,
      progress: currentStep,
      category: AndroidNotificationCategory.progress,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.startForegroundService(
        id: _kCookingProgressId,
        title: '🍳 $recipeTitle',
        body: bodyParts.join(' • '),
        notificationDetails: androidDetails,
      );
    } else {
      await _plugin.show(
        id: _kCookingProgressId,
        title: '🍳 $recipeTitle',
        body: bodyParts.join(' • '),
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
    }
  }

  /// Show timer completion alert
  Future<void> showTimerComplete({
    required String recipeTitle,
    required int stepNumber,
  }) async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      _kTimerAlertChannel,
      'Cooking Timer Alerts',
      channelDescription: 'Alerts when a cooking timer completes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(
          [0, 500, 200, 500, 200, 500]), // Three pulses
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id: _kTimerCompleteId,
      title: '⏰ Timer Done!',
      body: 'Step $stepNumber of "$recipeTitle" is ready',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  /// Show cooking complete notification
  Future<void> showCookingComplete({
    required String recipeTitle,
  }) async {
    if (!_initialized) return;

    // Cancel the ongoing progress notification
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.stopForegroundService();
    }
    await _plugin.cancel(id: _kCookingProgressId);

    final androidDetails = AndroidNotificationDetails(
      _kTimerAlertChannel,
      'Cooking Timer Alerts',
      channelDescription: 'Cooking completion',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
      ongoing: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    await _plugin.show(
      id: _kCookingProgressId,
      title: '🎉 Cooking Complete!',
      body: '$recipeTitle is ready. Bon appétit!',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _plugin.cancel(id: _kCookingProgressId);
    });
  }

  /// Dismiss all cooking notifications
  Future<void> cancelAll() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.stopForegroundService();
    }
    await _plugin.cancel(id: _kCookingProgressId);
    await _plugin.cancel(id: _kTimerCompleteId);
  }

  // ── Private ────────────────────────────────────────────────────

  void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId != null && actionId.isNotEmpty) {
      onAction?.call(actionId);
    }
  }
}
