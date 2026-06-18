// Plately — Profile Screen
// ==========================
// User profile with gamification stats, XP progress,
// earned badges, flavor profile visualization, and settings.
// Loads real data from Supabase tables: users, gamification_stats,
// user_flavor_profile.

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/theme/app_theme.dart';
import 'package:plately_app/core/constants/app_info.dart';
import 'package:plately_app/core/widgets/shimmer_loading.dart';
import 'package:plately_app/core/widgets/slide_in_item.dart';
import 'package:plately_app/features/gamification/domain/badges.dart' show levelFromXp, WasteBadge, computeEarnedBadges;
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:plately_app/core/services/app_settings.dart';
import 'package:plately_app/features/profile/presentation/screens/flavor_profile_page.dart';
import 'package:plately_app/features/profile/presentation/screens/nutrition_tracker_page.dart';
import 'package:plately_app/features/profile/presentation/screens/gamification_page.dart';
import 'package:plately_app/features/profile/presentation/screens/meal_planner_page.dart';
import 'package:plately_app/features/profile/presentation/screens/shopping_list_page.dart';
import 'package:plately_app/core/services/social_service.dart';
import 'package:plately_app/core/services/tutorial_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;

  // User data
  String _userName = 'Chef';
  String _username = '';
  String _userEmail = '';
  String _userLocation = '';
  int _totalXp = 0;
  int _level = 1;

  // Social stats
  int _followerCount = 0;
  int _followingCount = 0;
  int _postCount = 0;

  // Gamification stats
  int _mealsCooked = 0;
  int _itemsSaved = 0;
  int _currentStreak = 0;
  Set<WasteBadge> _earnedBadges = {};

  // Flavor profile
  Map<String, double> _flavorValues = {
    'Sweet': 0.5, 'Salty': 0.5, 'Sour': 0.5,
    'Bitter': 0.5, 'Umami': 0.5, 'Spicy': 0.5,
  };

  // Shopping list (local state — persisted via Supabase later)
  final List<Map<String, dynamic>> _shoppingList = [];

  // Meal plan: 7 days, null = no meal planned
  final List<String?> _mealPlan = List.filled(7, null);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;

      // Guest / Anonymous User handling
      if (currentUser == null || currentUser.isAnonymous) {
        setState(() {
          _userName = 'Guest Chef';
          _userEmail = '';
          _totalXp = 0;
          _level = 1;
          _mealsCooked = 0;
          _itemsSaved = 0;
          _currentStreak = 0;
          _earnedBadges = {};
          _flavorValues = {
            'Sweet': 0.5, 'Salty': 0.5, 'Sour': 0.5,
            'Bitter': 0.5, 'Umami': 0.5, 'Spicy': 0.5,
          };
          _shoppingList.clear();
          _mealPlan.fillRange(0, 7, null);
          _loading = false;
        });
        return;
      }

      // Parallel queries for authentic users
      final results = await Future.wait([
        client.from('users').select().eq('id', currentUserId()).maybeSingle(),
        client.from('gamification_stats').select().eq('user_id', currentUserId()).maybeSingle(),
        client.from('user_flavor_profile').select().eq('user_id', currentUserId()).maybeSingle(),
        client.from('shopping_list').select().eq('user_id', currentUserId()).order('created_at'),
        client.from('meal_plan').select('*, recipes(title)').eq('user_id', currentUserId()).gte('planned_date', DateTime.now().toIso8601String().split('T')[0]),
      ]);

      var userData = results[0] as Map<String, dynamic>?;
      var statsData = results[1] as Map<String, dynamic>?;
      var flavorData = results[2] as Map<String, dynamic>?;

      // App-level Self-Healing Fallback for User Initialization
      // If the backend SQL trigger hasn't fired or is missing, we create default rows here.
      if (userData == null) {
        final email = client.auth.currentUser?.email ?? 'chef@plately.local';
        final defaultName = email.split('@')[0];
        try {
          await client.from('users').insert({
            'id': currentUserId(),
            'email': email,
            'display_name': defaultName,
          });
          userData = {'display_name': defaultName};
        } catch (_) {} // Ignore insert errors if it already exists
      }

      if (statsData == null) {
        try {
          await client.from('gamification_stats').insert({'user_id': currentUserId()});
          statsData = {
            'xp_points': 0,
            'total_meals_cooked': 0,
            'items_saved': 0,
            'current_streak': 0,
          };
        } catch (_) {}
      }

      if (flavorData == null) {
        try {
          await client.from('user_flavor_profile').insert({'user_id': currentUserId()});
          flavorData = {
            'sweet': 0.5, 'salty': 0.5, 'sour': 0.5,
            'bitter': 0.5, 'umami': 0.5, 'spicy': 0.5,
          };
        } catch (_) {}
      }

      setState(() {
        // User
        _userName = userData?['display_name'] ?? 'Chef';
        _username = userData?['username'] ?? '';
        _userEmail = client.auth.currentUser?.email ?? '';
        _userLocation = userData?['location'] ?? '';

        // Gamification
        _totalXp = (statsData?['xp_points'] as int?) ?? 0;
        _level = levelFromXp(_totalXp);
        _mealsCooked = (statsData?['total_meals_cooked'] as int?) ?? 0;
        _itemsSaved = (statsData?['items_saved'] as int?) ?? 0;
        _currentStreak = (statsData?['current_streak'] as int?) ?? 0;

        // Badges from JSONB
        final rawBadges = statsData?['badges'];
        _earnedBadges = computeEarnedBadges(statsData);

        // Flavor profile
        if (flavorData != null) {
          _flavorValues = {
            'Sweet': (flavorData['sweet'] as num?)?.toDouble() ?? 0.5,
            'Salty': (flavorData['salty'] as num?)?.toDouble() ?? 0.5,
            'Sour': (flavorData['sour'] as num?)?.toDouble() ?? 0.5,
            'Bitter': (flavorData['bitter'] as num?)?.toDouble() ?? 0.5,
            'Umami': (flavorData['umami'] as num?)?.toDouble() ?? 0.5,
            'Spicy': (flavorData['spicy'] as num?)?.toDouble() ?? 0.5,
          };
        }

        // Shopping List
        final shoppingData = (results[3] as List<dynamic>?) ?? [];
        _shoppingList.clear();
        for (final item in shoppingData) {
          _shoppingList.add({
            'id': item['id'],
            'name': item['ingredient_name'],
            'checked': item['is_purchased'] == true,
          });
        }

        // Meal Plan
        final mealData = (results[4] as List<dynamic>?) ?? [];
        // Reset to nulls
        _mealPlan.fillRange(0, 7, null);
        final today = DateTime.now();
        final todayStr = today.toIso8601String().split('T')[0];
        
        for (final meal in mealData) {
          final plannedDateStr = meal['planned_date'] as String;
          final diffOptions = DateTime.parse(plannedDateStr).difference(DateTime.parse(todayStr)).inDays;
          if (diffOptions >= 0 && diffOptions < 7) {
            final recipeMeta = meal['recipes'] as Map?;
            _mealPlan[diffOptions] = recipeMeta?['title'] as String? ?? 'Unknown Recipe';
          }
        }

        _loading = false;
      });

      // Load social stats (non-blocking)
      _loadSocialStats();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadSocialStats() async {
    try {
      final uid = currentUserId();
      final followers = await SocialService.getFollowerCount(uid);
      final following = await SocialService.getFollowingCount(uid);
      final posts = await Supabase.instance.client
          .from('posts')
          .select('id')
          .eq('author_id', uid);
      if (mounted) {
        setState(() {
          _followerCount = followers;
          _followingCount = following;
          _postCount = (posts as List).length;
        });
      }
    } catch (e) {
      debugPrint('[Profile] social stats error: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const ProfileSkeleton(),
      );
    }

    final l10n = AppLocalizations.of(context);

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                SizedBox(height: 16),
                Text(l10n?.profileLoadError ?? 'Couldn\'t load profile',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadProfile,
                  icon: Icon(Icons.refresh),
                  label: Text(l10n?.retry ?? 'Retry'),
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final nextLevelXp = (_level + 1) * (_level + 1) * 100;
    final progress = _totalXp / nextLevelXp;

    // All possible badges with earned status
    final allBadges = _buildBadgeList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar with animated gradient ring
                      GestureDetector(
                        onTap: _editDisplayName,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.primary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                            child: Center(
                              child: Text('👨‍🍳', style: TextStyle(fontSize: 36)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      // Name (tappable to edit)
                      GestureDetector(
                        onTap: _editDisplayName,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _userName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.edit, size: 14,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      if (_userEmail.isNotEmpty)
                        Text(
                          _userEmail,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      if (_username.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          '@$_username',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${l10n?.profileGamificationLevel(_level) ?? 'Level $_level'} • $_totalXp XP',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadProfile,
                tooltip: l10n?.refresh ?? 'Refresh',
              ),
            ],
          ),

          // ── Body ───────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // XP Progress
                SlideInItem(
                  delay: 0,
                  child: _SectionCard(
                    title: l10n?.profileLevelProgress ?? 'Level Progress',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n?.profileLevel(_level) ?? 'Level $_level',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$_totalXp / $nextLevelXp XP',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.lerp(Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary, value) ?? Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Stats
                SlideInItem(
                  delay: 100,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionTrackerPage())),
                    child: _SectionCard(
                    title: l10n?.profileYourImpact ?? 'Your Impact',
                    trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                    child: Row(
                      children: [
                        _AnimatedStatTile(
                          icon: Icons.restaurant,
                          targetValue: _mealsCooked,
                          label: l10n?.profileMealsCooked ?? 'Meals Cooked',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _AnimatedStatTile(
                          icon: Icons.eco,
                          targetValue: _itemsSaved,
                          label: l10n?.profileItemsSaved ?? 'Items Saved',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        _AnimatedStatTile(
                          icon: Icons.local_fire_department,
                          targetValue: _currentStreak,
                          label: l10n?.profileDayStreak ?? 'Day Streak',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                  ),
                ),

                SizedBox(height: 12),

                // ── Badges Section ─────────────────────────────────────
                SlideInItem(
                  delay: 350,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationPage())),
                    child: _SectionCard(
                      title: l10n?.profileBadges ?? 'Badges & Achievements',
                      trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 24) / 4; // 4 per row
                          return Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: allBadges.map((badge) {
                              return SizedBox(width: itemWidth.clamp(60, 90), child: badge);
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Flavor Profile
                SlideInItem(
                  delay: 200,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlavorProfilePage())),
                    child: _SectionCard(
                      title: l10n?.profileFlavorProfile ?? 'Flavor Profile',
                      trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 16),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _FlavorRadarPainter(
                            values: _flavorValues,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // ── Shopping List Section ─────────────────────────────────

                SlideInItem(
                  delay: 250,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListPage())),
                    child: Builder(
                    builder: (context) {
                      final checkedCount = _shoppingList.where((i) => i['checked'] == true).length;
                      final totalCount = _shoppingList.length;
                      return _SectionCard(
                        title: totalCount > 0
                            ? '${l10n?.profileShoppingList ?? 'Shopping List'} ($checkedCount/$totalCount)'
                            : l10n?.profileShoppingList ?? 'Shopping List',
                        trailing: IconButton(
                          icon: Icon(Icons.add_circle_outline,
                              color: Theme.of(context).colorScheme.primary, size: 22),
                          onPressed: _addShoppingItem,
                          tooltip: l10n?.addShoppingItem ?? 'Add Item',
                        ),
                    child: _shoppingList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Icon(Icons.shopping_cart_outlined,
                                      size: 40,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                                  SizedBox(height: 8),
                                  Text(l10n?.shoppingListEmpty ?? 'Your shopping list is empty',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: _shoppingList.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              return _ShoppingItemTile(
                                name: item['name'] as String,
                                checked: item['checked'] as bool,
                                onToggle: () async {
                                  final newVal = !(item['checked'] as bool);
                                  setState(() {
                                    _shoppingList[idx] = {
                                      ...item,
                                      'checked': newVal,
                                    };
                                  });
                                  await Supabase.instance.client
                                      .from('shopping_list')
                                      .update({'is_purchased': newVal})
                                      .eq('id', item['id']);
                                },
                                onDismiss: () async {
                                  final itemId = item['id'];
                                  setState(() => _shoppingList.removeAt(idx));
                                  await Supabase.instance.client
                                      .from('shopping_list')
                                      .delete()
                                      .eq('id', itemId);
                                },
                              );
                            }).toList(),
                          ),
                      );
                    },
                  ),
                  ),
                ),

                SizedBox(height: 12),

                // ── Meal Planner Section ───────────────────────────────
                SlideInItem(
                  delay: 300,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlannerPage())),
                    child: _SectionCard(
                    title: l10n?.profileMealPlanner ?? 'Meal Planner',
                    child: _mealPlan.every((m) => m == null)
                        ? Container(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.calendar_today, size: 40, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                                SizedBox(height: 8),
                                Text(
                                  l10n?.mealPlannerEmpty ?? 'No meals planned',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                ),
                                SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => _assignMeal(0),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                      side: BorderSide(color: Theme.of(context).colorScheme.primary)),
                                  child: Text(l10n?.planToday ?? 'Plan Today'),
                                )
                              ],
                            ),
                          )
                          // If not all null, show the 7-day list
                          : Column(
                              children: List.generate(7, (i) {
                                final dayDate = DateTime.now().add(Duration(days: i));
                                final dayName = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][dayDate.weekday - 1];
                                final isToday = i == 0;
                                final meal = _mealPlan[i];
                                
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isToday ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1) : Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isToday ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 48,
                                        child: Text(
                                          isToday ? (l10n?.today ?? 'Today') : dayName,
                                          style: TextStyle(
                                            color: isToday ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          meal ?? (l10n?.planMeal ?? 'Plan meal...'),
                                          style: TextStyle(
                                            color: meal != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                                            fontStyle: meal != null ? FontStyle.normal : FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onLongPress: meal != null ? () => _clearMeal(i) : null,
                                        child: IconButton(
                                          icon: Icon(
                                            meal != null ? Icons.edit : Icons.add_circle_outline,
                                            size: 18,
                                            color: meal != null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54) : Theme.of(context).colorScheme.secondary,
                                          ),
                                          onPressed: () => _assignMeal(i),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                  ),
                  ),
                ),

                SizedBox(height: 12),


                SlideInItem(
                  delay: 350,
                  child: _SectionCard(
                    title: AppLocalizations.of(context)?.profileAccount ?? 'Account',
                    child: Column(
                      children: [
                        // Email display
                        if (_userEmail.isNotEmpty)
                          _SettingsRow(
                            icon: Icons.email_outlined,
                            label: _userEmail,
                            trailing: SizedBox.shrink(),
                          ),
                        // Replay Tutorial
                        _SettingsRow(
                          icon: Icons.school_outlined,
                          label: l10n?.tutorial_replay ?? 'Replay Tutorial',
                          onTap: () async {
                            await TutorialService().resetAll();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n?.tutorial_replayConfirm ?? 'Tutorial will show on next app launch.'),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            }
                          },
                        ),
                        // Sign Out
                        _SettingsRow(
                          icon: Icons.logout,
                          label: l10n?.signOut ?? 'Sign Out',
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(AppLocalizations.of(context)?.auto_signOut ?? 'Sign Out?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                content: Text(AppLocalizations.of(context)?.auto_youWillNeedToSignInAgain ?? 'You will need to sign in again.',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(AppLocalizations.of(context)?.auto_cancel ?? 'Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: Text(AppLocalizations.of(context)?.auto_signOut ?? 'Sign Out'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await Supabase.instance.client.auth.signOut();
                              if (mounted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            }
                          },
                        ),
                        // Delete Account
                        _SettingsRow(
                          icon: Icons.delete_forever,
                          label: AppLocalizations.of(context)?.deleteAccount ?? 'Delete Account',
                          iconColor: Colors.redAccent,
                          labelColor: Colors.redAccent,
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(AppLocalizations.of(context)?.auto_deleteAccount ?? 'Delete Account?',
                                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                                content: Text(
                                  'This action is permanent and cannot be undone. All your data will be lost.',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(AppLocalizations.of(context)?.auto_cancel ?? 'Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: Text(AppLocalizations.of(context)?.auto_deleteForever ?? 'Delete Forever'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)?.auto_accountDeletionRequestedContactSupportToFinalize ?? 'Account deletion requested. Contact support to finalize.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // ── Settings Section ───────────────────────────────────
                SlideInItem(
                  delay: 400,
                  child: _SectionCard(
                    title: 'Settings',
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.language,
                          label: AppLocalizations.of(context)?.settingsLanguage ?? 'Language',
                          trailing: Text(
                            '${AppSettings().currentLanguageFlag} ${AppSettings().currentLanguageName}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                          ),
                          onTap: () => _showLanguagePicker(),
                        ),
                        _SettingsRow(
                          icon: Icons.dark_mode,
                            label: AppLocalizations.of(context)?.settingsTheme ?? 'Theme',
                          trailing: Text(
                            AppSettings().currentThemeName,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                          ),
                          onTap: () => _showThemePicker(),
                        ),
                        _SettingsRow(
                          icon: Icons.info_outline,
                            label: AppLocalizations.of(context)?.aboutApp ?? 'About Plately',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Row(
                                  children: [
                                    Text('🧊', style: TextStyle(fontSize: 32)),
                                    SizedBox(width: 12),
                                    Text(AppLocalizations.of(context)?.auto_plately ?? 'Plately', style: TextStyle(fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Version ${AppInfo.version} — The Intelligent Kitchen', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                                    SizedBox(height: 12),
                                    Text(AppLocalizations.of(context)?.auto_platelyIsYourAipoweredKitchenEcosystemItAutomaticallyTracksYourIngredientsPredictsExpirationsGeneratesPersonalizedRecipesAndLetsYouOrderFromLocalRestaurants ?? 'Plately is your AI-powered kitchen ecosystem. It automatically tracks your ingredients, predicts expirations, generates personalized recipes, and lets you order from local restaurants.', style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(AppLocalizations.of(context)?.auto_gotIt ?? 'Got it', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            AppInfo.formattedVersion,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32),

              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Display Name ──────────────────────────────────────────

  void _editDisplayName() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)?.auto_editDisplayName ?? 'Edit Display Name',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)?.auto_cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != _userName) {
                try {
                  await Supabase.instance.client
                      .from('users')
                      .update({'display_name': newName})
                      .eq('id', currentUserId());
                  setState(() => _userName = newName);
                } catch (e) {
                  debugPrint('Error updating name: $e');
                }
              }
              if (mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: Text(AppLocalizations.of(context)?.auto_save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBadgeList() {
    return WasteBadge.values.map((badge) {
      final earned = _earnedBadges.contains(badge);
      return _BadgeTile(
        icon: badge.icon,
        name: badge.title,
        earned: earned,
      );
    }).toList();
  }

  // ── Shopping List Helpers ───────────────────────────────────────

  void _addShoppingItem() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppLocalizations.of(context)?.auto_addShoppingItem ?? 'Add Shopping Item',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'e.g. Eggs, Milk, Rice',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)?.auto_cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  // Optimistic UI insert could go here, but let's just insert and reload
                  final res = await Supabase.instance.client.from('shopping_list').insert({
                    'user_id': currentUserId(),
                    'ingredient_name': text,
                    'is_purchased': false,
                  }).select().single();
                  
                  setState(() {
                    _shoppingList.add({
                      'id': res['id'],
                      'name': text,
                      'checked': false,
                    });
                  });
                }
                if (mounted) Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              child: Text(AppLocalizations.of(context)?.auto_add ?? 'Add'),
            ),
        ],
      ),
    );
  }

  // ── Meal Planner Helpers ────────────────────────────────────────

  void _assignMeal(int dayIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(AppLocalizations.of(context)?.auto_selectRecipeForMeal ?? 'Select Recipe for Meal', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: FutureBuilder(
                  future: Supabase.instance.client.from('recipes').select('id, title, prep_time_minutes, cook_time_minutes').limit(200),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(child: Text(AppLocalizations.of(context)?.auto_failedToLoadRecipes ?? 'Failed to load recipes', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))));
                    }
                    final recipes = snapshot.data as List;
                    if (recipes.isEmpty) {
                      return Center(child: Text(AppLocalizations.of(context)?.auto_noRecipesFound ?? 'No recipes found', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))));
                    }
                    return ListView.builder(
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        final title = recipe['title'] as String;
                        final duration = (recipe['prep_time_minutes'] ?? 0) + (recipe['cook_time_minutes'] ?? 0);
                        return ListTile(
                          title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text('$duration mins', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                          trailing: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                          onTap: () async {
                            final targetDate = DateTime.now().add(Duration(days: dayIndex));
                            final dateStr = targetDate.toIso8601String().split('T')[0];
                            
                            await Supabase.instance.client.from('meal_plan').insert({
                              'user_id': currentUserId(),
                              'recipe_id': recipe['id'],
                              'planned_date': dateStr,
                              'meal_type': 'dinner'
                            });
                            
                            setState(() {
                              _mealPlan[dayIndex] = title;
                            });
                            if (mounted) Navigator.pop(ctx);
                          },
                        );
                      },
                    );
                  }
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // ── Clear Meal Helper ──────────────────────────────────────────

  void _clearMeal(int dayIndex) async {
    final targetDate = DateTime.now().add(Duration(days: dayIndex));
    final dateStr = targetDate.toIso8601String().split('T')[0];
    try {
      await Supabase.instance.client
          .from('meal_plan')
          .delete()
          .eq('user_id', currentUserId())
          .eq('planned_date', dateStr);
      setState(() => _mealPlan[dayIndex] = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.auto_mealCleared ?? 'Meal cleared'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('Error clearing meal: $e');
    }
  }

  void _showLanguagePicker() {
    final settings = AppSettings();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌐 ${AppLocalizations.of(context)?.settingsLanguage ?? 'Language'}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 16),
              ...AppSettings.supportedLanguages.entries.map((entry) {
                final code = entry.key;
                final name = entry.value['name']!;
                final flag = entry.value['flag']!;
                final isActive = settings.locale == AppSettings.parseLocale(code);
                return ListTile(
                  leading: Text(flag, style: TextStyle(fontSize: 24)),
                  title: Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
                  trailing: isActive
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isActive ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
                  onTap: () {
                    settings.setLocale(AppSettings.parseLocale(code));
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker() {
    final settings = AppSettings();
    final options = [
      {'mode': ThemeMode.dark, 'label': 'Dark', 'icon': Icons.dark_mode, 'emoji': '🌙'},
      {'mode': ThemeMode.light, 'label': 'Light', 'icon': Icons.light_mode, 'emoji': '☀️'},
      {'mode': ThemeMode.system, 'label': 'System', 'icon': Icons.settings_suggest, 'emoji': '⚙️'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)?.auto_theme ?? '🎨 Theme',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 16),
              ...options.map((opt) {
                final isActive = settings.themeMode == opt['mode'];
                return ListTile(
                  leading: Text(opt['emoji'] as String, style: TextStyle(fontSize: 24)),
                  title: Text(opt['label'] as String,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
                  trailing: isActive
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: isActive ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
                  onTap: () {
                    settings.setThemeMode(opt['mode'] as ThemeMode);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ── Section Card ─────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Animated Stat Tile ───────────────────────────────────────────

class _AnimatedStatTile extends StatelessWidget {
  final int targetValue;
  final String label;
  final IconData icon;
  final Color color;

  const _AnimatedStatTile({
    required this.targetValue,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: targetValue.toDouble()),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (_, value, _) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(height: 8),
            Text(
              value.toInt().toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Tile ───────────────────────────────────────────────────

class _BadgeTile extends StatelessWidget {
  final String icon;
  final String name;
  final bool earned;

  const _BadgeTile(
      {required this.icon, required this.name, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: earned ? 1.0 : 0.3,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned
                  ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              border: Border.all(
                color: earned
                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: icon.endsWith('.png') || icon.endsWith('.jpg')
                  ? Image.asset(icon, width: 28, height: 28, color: earned ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), colorBlendMode: earned ? null : BlendMode.saturation)
                  : Text(icon, style: TextStyle(fontSize: 24)),
            ),
          ),
          SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: earned ? 0.8 : 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


// ── Flavor Radar Chart Painter ───────────────────────────────────

class _FlavorRadarPainter extends CustomPainter {
  final Map<String, double> values;
  final Color color;

  _FlavorRadarPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 30; // Constrain by smallest dimension
    final axes = values.keys.toList();
    final n = axes.length;
    final angleStep = (2 * math.pi) / n;

    // Normalize values
    double maxVal = 0;
    for (final val in values.values) {
      if (val > maxVal) maxVal = val;
    }
    final normalizedValues = <String, double>{};
    for (final entry in values.entries) {
      normalizedValues[entry.key] = maxVal > 0 ? entry.value / maxVal : 0;
    }

    // Draw grid rings
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final angle = -math.pi / 2 + angleStep * (i % n);
        final p = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, ringPaint);
    }

    // Draw axes and labels
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.6),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..strokeWidth = 1,
      );

      // Label
      final labelPos = Offset(
        center.dx + (radius + 18) * math.cos(angle),
        center.dy + (radius + 18) * math.sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(text: axes[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );
    }

    // Draw data polygon (fill)
    final dataPath = Path();
    for (var i = 0; i <= n; i++) {
      final angle = -math.pi / 2 + angleStep * (i % n);
      final val = normalizedValues[axes[i % n]] ?? 0;
      final r = radius * val;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw data points
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final val = normalizedValues[axes[i]] ?? 0;
      final r = radius * val;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      canvas.drawCircle(p, 4, Paint()..color = color);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Shopping Item Tile ───────────────────────────────────────────

class _ShoppingItemTile extends StatelessWidget {
  final String name;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onDismiss;

  const _ShoppingItemTile({
    required this.name,
    required this.checked,
    required this.onToggle,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(name),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: Colors.redAccent),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          leading: IconButton(
            icon: Icon(
              checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: checked ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
            ),
            onPressed: onToggle,
          ),
          title: Text(
            name,
            style: TextStyle(
              color: checked ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38) : Theme.of(context).colorScheme.onSurface,
              decoration: checked ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Settings Row ─────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ?trailing,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right, size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _SocialStat extends StatelessWidget {
  final String value;
  final String label;
  const _SocialStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45), fontSize: 12)),
      ],
    );
  }
}
