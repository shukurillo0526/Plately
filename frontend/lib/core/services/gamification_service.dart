import 'package:flutter/material.dart';

class GamificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Process the gamification payload returned from the backend
  static void handleGamificationResult(Map<String, dynamic> gamificationData) {
    final List<dynamic>? badgesUnlocked = gamificationData['badges_unlocked'];
    final List<dynamic>? streaksUpdated = gamificationData['streaks_updated'];
    final List<dynamic>? challengesCompleted = gamificationData['challenges_completed'];

    if (badgesUnlocked != null && badgesUnlocked.isNotEmpty) {
      for (final badgeId in badgesUnlocked) {
        _showBadgeUnlock(badgeId.toString());
      }
    }

    if (challengesCompleted != null && challengesCompleted.isNotEmpty) {
      for (final challengeTitle in challengesCompleted) {
        _showChallengeComplete(challengeTitle.toString());
      }
    }

    if (streaksUpdated != null && streaksUpdated.isNotEmpty) {
      for (final streak in streaksUpdated) {
        final current = streak['current'] as int;
        // Trigger a subtle snackbar or in-app notification if a streak milestone is hit
        if (current > 0 && current % 3 == 0) { // e.g., 3-day, 6-day, etc.
          _showStreakMilestone(streak['type'].toString(), current);
        }
      }
    }
  }

  static void _showChallengeComplete(String title) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amberAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Challenge Completed: $title!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void _showBadgeUnlock(String badgeId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // A simple overlay or snackbar for now.
    // Ideally this would be a beautiful Confetti + Lottie animation.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Achievement Unlocked: ${_formatBadgeName(badgeId)}!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void _showStreakMilestone(String streakType, int days) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 12),
            Text(
              '$days-Day ${_formatStreakName(streakType)} Streak!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static String _formatBadgeName(String id) {
    return id.split('_').map((word) => word.substring(0, 1).toUpperCase() + word.substring(1)).join(' ');
  }

  static String _formatStreakName(String type) {
    switch (type) {
      case 'cooking': return 'Cooking';
      case 'waste_saver': return 'Waste Saver';
      case 'health': return 'Health';
      case 'prep': return 'Prep';
      default: return 'App';
    }
  }
}
