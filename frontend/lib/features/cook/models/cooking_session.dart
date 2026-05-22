// ═══════════════════════════════════════════════════════════════════
//  Plately — Cooking Session Model
//  Immutable data class representing an active cooking session.
//  Persisted to Hive so sessions survive app restarts.
// ═══════════════════════════════════════════════════════════════════

import 'dart:convert';

/// Timer state for a cooking step
enum TimerStatus { idle, running, paused, completed }

/// Represents an active cooking session
class CookingSession {
  final String recipeId;
  final String title;
  final String? imageUrl;
  final List<Map<String, dynamic>> steps;
  final List<Map<String, dynamic>>? ingredients;
  final int currentStepIndex;
  final bool isBeginnerMode;
  final int servingsCooked;
  final int originalServings;
  final DateTime startedAt;

  // Timer state
  final int? timerTotalSeconds;
  final int timerRemainingSeconds;
  final TimerStatus timerStatus;
  final DateTime? timerStartedAt;

  // Extra context for CookingRunScreen restoration
  final double matchPct;
  final int matchedIngredientsCount;
  final String userInventoryText;
  final Set<String> ownedIngredientIds;
  final int? calories;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;

  const CookingSession({
    required this.recipeId,
    required this.title,
    this.imageUrl,
    required this.steps,
    this.ingredients,
    this.currentStepIndex = 0,
    this.isBeginnerMode = false,
    this.servingsCooked = 1,
    this.originalServings = 1,
    required this.startedAt,
    this.timerTotalSeconds,
    this.timerRemainingSeconds = 0,
    this.timerStatus = TimerStatus.idle,
    this.timerStartedAt,
    this.matchPct = 0.0,
    this.matchedIngredientsCount = 0,
    this.userInventoryText = '',
    this.ownedIngredientIds = const {},
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  /// Current step data
  Map<String, dynamic> get currentStep =>
      currentStepIndex < steps.length ? steps[currentStepIndex] : {};

  /// Whether we're on the last step
  bool get isLastStep => currentStepIndex >= steps.length - 1;

  /// Total number of steps
  int get totalSteps => steps.length;

  /// Progress as a fraction (0.0 to 1.0)
  double get progress =>
      steps.isEmpty ? 0.0 : (currentStepIndex + 1) / steps.length;

  /// Whether a timer is actively counting down
  bool get isTimerActive => timerStatus == TimerStatus.running;

  /// Timer display string (e.g. "5:30")
  String get timerDisplayString {
    final mins = timerRemainingSeconds ~/ 60;
    final secs = timerRemainingSeconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  /// Create a copy with modified fields
  CookingSession copyWith({
    String? recipeId,
    String? title,
    String? imageUrl,
    List<Map<String, dynamic>>? steps,
    List<Map<String, dynamic>>? ingredients,
    int? currentStepIndex,
    bool? isBeginnerMode,
    int? servingsCooked,
    int? originalServings,
    DateTime? startedAt,
    int? timerTotalSeconds,
    int? timerRemainingSeconds,
    TimerStatus? timerStatus,
    DateTime? timerStartedAt,
    double? matchPct,
    int? matchedIngredientsCount,
    String? userInventoryText,
    Set<String>? ownedIngredientIds,
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
  }) {
    return CookingSession(
      recipeId: recipeId ?? this.recipeId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      steps: steps ?? this.steps,
      ingredients: ingredients ?? this.ingredients,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isBeginnerMode: isBeginnerMode ?? this.isBeginnerMode,
      servingsCooked: servingsCooked ?? this.servingsCooked,
      originalServings: originalServings ?? this.originalServings,
      startedAt: startedAt ?? this.startedAt,
      timerTotalSeconds: timerTotalSeconds ?? this.timerTotalSeconds,
      timerRemainingSeconds:
          timerRemainingSeconds ?? this.timerRemainingSeconds,
      timerStatus: timerStatus ?? this.timerStatus,
      timerStartedAt: timerStartedAt ?? this.timerStartedAt,
      matchPct: matchPct ?? this.matchPct,
      matchedIngredientsCount:
          matchedIngredientsCount ?? this.matchedIngredientsCount,
      userInventoryText: userInventoryText ?? this.userInventoryText,
      ownedIngredientIds: ownedIngredientIds ?? this.ownedIngredientIds,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
    );
  }

  /// Serialize to JSON string for Hive storage
  String toJsonString() {
    return jsonEncode({
      'recipeId': recipeId,
      'title': title,
      'imageUrl': imageUrl,
      'steps': steps,
      'ingredients': ingredients,
      'currentStepIndex': currentStepIndex,
      'isBeginnerMode': isBeginnerMode,
      'servingsCooked': servingsCooked,
      'originalServings': originalServings,
      'startedAt': startedAt.toIso8601String(),
      'timerTotalSeconds': timerTotalSeconds,
      'timerRemainingSeconds': timerRemainingSeconds,
      'timerStatus': timerStatus.index,
      'timerStartedAt': timerStartedAt?.toIso8601String(),
      'matchPct': matchPct,
      'matchedIngredientsCount': matchedIngredientsCount,
      'userInventoryText': userInventoryText,
      'ownedIngredientIds': ownedIngredientIds.toList(),
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
    });
  }

  /// Deserialize from JSON string
  factory CookingSession.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return CookingSession(
      recipeId: map['recipeId'] as String,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String?,
      steps: List<Map<String, dynamic>>.from(
        (map['steps'] as List).map((s) => Map<String, dynamic>.from(s)),
      ),
      ingredients: map['ingredients'] != null
          ? List<Map<String, dynamic>>.from(
              (map['ingredients'] as List)
                  .map((s) => Map<String, dynamic>.from(s)),
            )
          : null,
      currentStepIndex: map['currentStepIndex'] as int? ?? 0,
      isBeginnerMode: map['isBeginnerMode'] as bool? ?? false,
      servingsCooked: map['servingsCooked'] as int? ?? 1,
      originalServings: map['originalServings'] as int? ?? 1,
      startedAt: DateTime.parse(map['startedAt'] as String),
      timerTotalSeconds: map['timerTotalSeconds'] as int?,
      timerRemainingSeconds: map['timerRemainingSeconds'] as int? ?? 0,
      timerStatus:
          TimerStatus.values[map['timerStatus'] as int? ?? 0],
      timerStartedAt: map['timerStartedAt'] != null
          ? DateTime.parse(map['timerStartedAt'] as String)
          : null,
      matchPct: (map['matchPct'] as num?)?.toDouble() ?? 0.0,
      matchedIngredientsCount:
          map['matchedIngredientsCount'] as int? ?? 0,
      userInventoryText: map['userInventoryText'] as String? ?? '',
      ownedIngredientIds: Set<String>.from(
        (map['ownedIngredientIds'] as List?)?.cast<String>() ?? [],
      ),
      calories: map['calories'] as int?,
      proteinG: map['proteinG'] as int?,
      carbsG: map['carbsG'] as int?,
      fatG: map['fatG'] as int?,
    );
  }
}
