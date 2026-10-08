/// Plately — Gamification Badges Domain
/// =======================================
library;

enum WasteBadge {
  firstMeal('🍳', 'First Meal', 'Cook your first recipe', 0),
  wasteFighter('🌱', 'Waste Fighter', 'Cook 10 Tier 1 meals', 10),
  wasteWarrior('🌿', 'Waste Warrior', 'Cook 50 Tier 1 meals', 50),
  streak67(
    'assets/images/badges/streak_67.png',
    '6-7 Day Streak',
    'Log in for 6-7 consecutive days!',
    7,
  ),
  streak15(
    '🔥',
    '15 Day Streak',
    'Log in for 15 consecutive days!',
    15,
  ),
  streak30(
    '👑',
    '30 Day Streak',
    'Log in for 30 consecutive days!',
    30,
  ),
  explorer('🧭', 'Flavor Explorer', 'Cook 5 different cuisines', 5),
  rescuer('🦸', 'Expiry Rescuer', 'Save 20 items from expiring', 20),
  zeroWasteWeek('✨', 'Zero Waste Week', 'No expired items for 7 days', 7);

  final String icon;
  final String title;
  final String description;
  final int threshold;

  const WasteBadge(this.icon, this.title, this.description, this.threshold);
}

/// XP reward table for different actions.
class XpRewards {
  static const int tier1Meal = 50;
  static const int tier2Meal = 40;
  static const int tier3Meal = 20;
  static const int tier4Meal = 20;
  static const int urgentItemUsed = 15;
  static const int weekStreakBonus = 100;
  static const int expiredItemPenalty = -5;
}

/// Calculate user level from XP.
int levelFromXp(int xp) {
  // Each level requires 50% more XP than the previous
  // Level 1: 0 XP, Level 2: 100 XP, Level 3: 250 XP, ...
  if (xp < 100) return 1;
  int level = 1;
  int required = 100;
  int remaining = xp;
  while (remaining >= required) {
    remaining -= required;
    level++;
    required = (required * 1.5).round();
  }
  return level;
}

/// XP progress within current level (0.0 – 1.0).
double levelProgress(int xp) {
  if (xp < 100) return xp / 100.0;
  int required = 100;
  int remaining = xp;
  while (remaining >= required) {
    remaining -= required;
    required = (required * 1.5).round();
  }
  return remaining / required;
}

/// Compute earned badges based on gamification stats.
Set<WasteBadge> computeEarnedBadges(Map<String, dynamic>? stats) {
  if (stats == null) return {};
  final meals = stats['total_meals_cooked'] as int? ?? 0;
  final tier1 = stats['tier1_meals'] as int? ?? 0;
  final saved = stats['items_saved'] as int? ?? 0;
  final streak = stats['longest_streak'] as int? ?? 0;

  final earned = <WasteBadge>{};
  if (meals >= 1) earned.add(WasteBadge.firstMeal);
  if (tier1 >= WasteBadge.wasteFighter.threshold) {
    earned.add(WasteBadge.wasteFighter);
  }
  if (tier1 >= WasteBadge.wasteWarrior.threshold) {
    earned.add(WasteBadge.wasteWarrior);
  }
  if (streak >= WasteBadge.streak67.threshold) earned.add(WasteBadge.streak67);
  if (streak >= WasteBadge.streak15.threshold) earned.add(WasteBadge.streak15);
  if (streak >= WasteBadge.streak30.threshold) earned.add(WasteBadge.streak30);
  if (saved >= WasteBadge.rescuer.threshold) earned.add(WasteBadge.rescuer);

  // Derived approximations for things not yet fully tracked:
  if (meals >= 15) earned.add(WasteBadge.explorer);
  if (streak >= 14) earned.add(WasteBadge.zeroWasteWeek);

  return earned;
}
