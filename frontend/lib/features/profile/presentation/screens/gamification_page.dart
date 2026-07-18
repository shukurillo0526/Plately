// Plately — Gamification Deep Page
// ====================================
// Full badge gallery, XP history, level milestones.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/features/gamification/domain/badges.dart';

import 'package:plately_app/features/social/presentation/screens/squad_screen.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});
  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage> {
  Map<String, dynamic>? _stats;
  Set<String> _earnedBadgeIds = {};
  List<dynamic> _activeChallenges = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final uid = currentUserId();
      final stats = await Supabase.instance.client
          .from('gamification_stats').select().eq('user_id', uid).maybeSingle();
      final earned = computeEarnedBadges(stats);
      
      final challenges = await ApiService().getActiveChallenges();
      
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _earnedBadgeIds = earned.map((b) => b.name).toSet();
        _activeChallenges = challenges;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final xp = _stats?['total_xp'] ?? 0;
    final level = levelFromXp(xp);
    final nextLevelXp = (level + 1) * 100;
    final levelProgress = (xp % 100) / 100.0;
    final earnedIds = _earnedBadgeIds;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Badges & Achievements', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'My Squads',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SquadScreen()));
            },
          )
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : ListView(
              padding: EdgeInsets.all(20),
              children: [
                // Level Card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.15), Theme.of(context).colorScheme.surface],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2))),
                  child: Column(
                    children: [
                      Text('⭐ Level $level',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 28, fontWeight: FontWeight.w800)),
                      SizedBox(height: 8),
                      Text('$xp XP total',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14)),
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: levelProgress, minHeight: 12,
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary)),
                      ),
                      SizedBox(height: 6),
                      Text('${xp % 100} / 100 XP to Level ${level + 1}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Stats (Streaks)
                Text('Current Streaks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _StatCard(label: 'Cooking Streak', value: '${_stats?['current_cooking_streak'] ?? 0} days', emoji: '🍳'),
                    _StatCard(label: 'Waste Saver', value: '${_stats?['current_waste_streak'] ?? 0} days', emoji: '♻️'),
                    _StatCard(label: 'Health Tracker', value: '${_stats?['current_health_streak'] ?? 0} days', emoji: '🍎'),
                    _StatCard(label: 'Meal Prep', value: '${_stats?['current_prep_streak'] ?? 0} days', emoji: '🍱'),
                  ],
                ),
                SizedBox(height: 24),

                // Active Challenges
                if (_activeChallenges.isNotEmpty) ...[
                  Text('Active Challenges', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 12),
                  ..._activeChallenges.map((challenge) {
                    final int target = challenge['goal_target'] ?? 1;
                    final int progress = challenge['progress'] ?? 0;
                    final String status = challenge['status'] ?? 'active';
                    final bool isCompleted = status == 'completed' || progress >= target;
                    final double pct = isCompleted ? 1.0 : (progress / target);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCompleted ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  challenge['title'],
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              if (isCompleted)
                                const Icon(Icons.check_circle, color: Colors.green)
                              else
                                Text('$progress / $target', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(challenge['description'] ?? '', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(isCompleted ? Colors.green : Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 24),
                ],

                // All Badges
                Text('All Badges',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85),
                  itemCount: WasteBadge.values.length,
                  itemBuilder: (ctx, i) {
                    final badge = WasteBadge.values[i];
                    final earned = earnedIds.contains(badge.name);
                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  badge.icon.endsWith('.png') || badge.icon.endsWith('.jpg')
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: Transform.scale(
                                            scale: 1.15,
                                            child: Image.asset(
                                              badge.icon,
                                              height: 200,
                                              width: 200,
                                              fit: BoxFit.cover,
                                              color: earned ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                              colorBlendMode: earned ? null : BlendMode.saturation,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          badge.icon,
                                          style: TextStyle(
                                            fontSize: 100,
                                            color: earned ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                          ),
                                        ),
                                  SizedBox(height: 24),
                                  Text(
                                    badge.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    badge.description,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4),
                                  ),
                                  if (!earned) ...[
                                    SizedBox(height: 16),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '🔒 Locked',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
                                      ),
                                    )
                                  ],
                                  SizedBox(height: 24),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                                    child: Text('Close'),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: earned ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: earned ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 8),
                            badge.icon.endsWith('.png') || badge.icon.endsWith('.jpg')
                                ? Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Transform.scale(
                                            scale: 1.15,
                                            child: Image.asset(
                                              badge.icon,
                                              fit: BoxFit.cover,
                                              color: earned ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                              colorBlendMode: earned ? null : BlendMode.saturation,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Expanded(
                                    child: Center(
                                      child: Text(
                                        badge.icon,
                                        style: TextStyle(fontSize: 40, color: earned ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                                      ),
                                    ),
                                  ),
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                badge.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: earned ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, emoji;
  const _StatCard({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06))),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 22)),
            SizedBox(height: 6),
            Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
