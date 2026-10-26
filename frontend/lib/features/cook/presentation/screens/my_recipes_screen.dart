// Plately — My Recipes Screen (Executive Chef's Portfolio)
// ========================================================
// Multi-tab culinary portfolio for home chefs and creators:
// 1. Created by Me (Monetized & Community recipes with stats)
// 2. Saved & Masterclasses (Unlocked from community chefs)
// 3. Offline Imports (Cached local recipes from external URLs)
// Features instant entry into Executive Recipe Studio.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/cache_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/core/services/recipe_monetization_service.dart';
import 'package:plately_app/core/widgets/recipe_share_card.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_detail_screen.dart';
import 'package:plately_app/features/cook/presentation/screens/executive_recipe_studio_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<RecipeModel> _myCreatedRecipes = [];
  List<RecipeModel> _savedRecipes = [];
  List<Map<String, dynamic>> _offlineRecipes = [];

  bool _loadingCreated = true;
  bool _loadingSaved = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAll() {
    _loadCreatedRecipes();
    _loadSavedRecipes();
    _loadOfflineRecipes();
  }

  Future<void> _loadCreatedRecipes() async {
    setState(() => _loadingCreated = true);
    final list = await RecipeMonetizationService.getMyRecipes();
    if (mounted) {
      setState(() {
        _myCreatedRecipes = list;
        _loadingCreated = false;
      });
    }
  }

  Future<void> _loadSavedRecipes() async {
    setState(() => _loadingSaved = true);
    try {
      final uid = currentUserId();
      final data = await Supabase.instance.client
          .from('recipe_copies')
          .select('id, is_paid, recipes(*)')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final list = <RecipeModel>[];
      for (final row in (data as List)) {
        if (row['recipes'] is Map) {
          list.add(RecipeModel.fromMap(Map<String, dynamic>.from(row['recipes'])));
        }
      }

      if (mounted) {
        setState(() {
          _savedRecipes = list;
          _loadingSaved = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  void _loadOfflineRecipes() {
    final userId = currentUserId();
    setState(() {
      _offlineRecipes = CacheService().getLocalRecipes(userId);
    });
  }

  Future<void> _openStudio() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ExecutiveRecipeStudioScreen()),
    );
    if (created == true) {
      _loadCreatedRecipes();
    }
  }

  void _openRecipeDetail(RecipeModel r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipeId: r.id,
          title: r.title,
          description: r.description,
          cuisine: r.cuisine,
          difficulty: r.difficulty,
          prepTime: r.prepTime,
          cookTime: r.cookTime,
          servings: r.servings,
          tierColor: Theme.of(context).colorScheme.primary,
          ownedIngredientIds: const {},
          caloriesPerServing: r.caloriesPerServing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saffron = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chef\'s Portfolio', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: saffron,
          labelColor: saffron,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Created (${_myCreatedRecipes.length})'),
            Tab(text: 'Saved (${_savedRecipes.length})'),
            Tab(text: 'Offline (${_offlineRecipes.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreatedTab(theme, saffron),
          _buildSavedTab(theme, saffron),
          _buildOfflineTab(theme, saffron),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'craft_recipe_fab',
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        onPressed: _openStudio,
        icon: const Icon(Icons.add),
        label: const Text('Craft Executive Recipe', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  // ── Tab 1: Created by Me ──
  Widget _buildCreatedTab(ThemeData theme, Color saffron) {
    if (_loadingCreated) {
      return Center(child: CircularProgressIndicator(color: saffron));
    }

    if (_myCreatedRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👨‍🍳', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 16),
              Text(
                'No recipes created yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Craft your first executive recipe, set timers, and share or monetize with the Plately community!',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openStudio,
                icon: const Icon(Icons.add),
                label: const Text('Craft Your First Recipe'),
                style: FilledButton.styleFrom(backgroundColor: saffron),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: saffron,
      onRefresh: _loadCreatedRecipes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _myCreatedRecipes.length,
        itemBuilder: (ctx, i) {
          final r = _myCreatedRecipes[i];
          return _buildRecipeCard(r, theme, saffron, isCreated: true);
        },
      ),
    );
  }

  // ── Tab 2: Saved & Unlocked ──
  Widget _buildSavedTab(ThemeData theme, Color saffron) {
    if (_loadingSaved) {
      return Center(child: CircularProgressIndicator(color: saffron));
    }

    if (_savedRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💎', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 16),
              Text(
                'No unlocked recipes yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore the Executive Recipes feed to discover and unlock masterclasses from culinary artists.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: saffron,
      onRefresh: _loadSavedRecipes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _savedRecipes.length,
        itemBuilder: (ctx, i) {
          final r = _savedRecipes[i];
          return _buildRecipeCard(r, theme, saffron, isCreated: false);
        },
      ),
    );
  }

  // ── Tab 3: Offline Imports ──
  Widget _buildOfflineTab(ThemeData theme, Color saffron) {
    if (_offlineRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 54, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                'No offline recipes cached',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Recipes imported from outside web links for offline use will be stored here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: _offlineRecipes.length,
      itemBuilder: (ctx, i) {
        final rec = _offlineRecipes[i];
        final title = rec['title'] ?? 'Imported Recipe';
        final cuisine = rec['cuisine'] ?? 'General';
        final cal = rec['calories_per_serving'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: saffron.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bookmark_outline, color: saffron),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '$cuisine • ${cal > 0 ? "$cal kcal" : "Offline"}',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening "$title"...')),
              );
            },
          ),
        );
      },
    );
  }

  // ── Recipe Card Builder ──
  Widget _buildRecipeCard(RecipeModel r, ThemeData theme, Color saffron, {required bool isCreated}) {
    final totalTime = (r.prepTime ?? 0) + (r.cookTime ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: r.isPremium ? const Color(0xFFFFB300).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        onTap: () => _openRecipeDetail(r),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: r.imageUrl != null && r.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: r.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _fallbackThumb(saffron),
                      )
                    : _fallbackThumb(saffron),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier badge & Title
                    Row(
                      children: [
                        if (r.isPremium) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.workspace_premium, size: 12, color: Color(0xFFFFB300)),
                                SizedBox(width: 2),
                                Text(
                                  'MASTERCLASS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFB300),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            r.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.description ?? '${r.cuisine ?? "Executive"} Recipe',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Quick Stats & Actions
                    Row(
                      children: [
                        if (totalTime > 0) ...[
                          Icon(Icons.timer_outlined, size: 13, color: saffron),
                          const SizedBox(width: 3),
                          Text(
                            '${totalTime}m',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (isCreated) ...[
                          Icon(Icons.people_outline, size: 13, color: Colors.blueAccent),
                          const SizedBox(width: 3),
                          Text(
                            '${r.copyCount} copies',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                        const Spacer(),
                        // Share Button
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          onPressed: () {
                            RecipeShareDialog.show(
                              context,
                              recipeId: r.id,
                              title: r.title,
                              imageUrl: r.imageUrl,
                              cuisine: r.cuisine,
                              prepTime: r.prepTime,
                              cookTime: r.cookTime,
                              calories: r.caloriesPerServing,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackThumb(Color saffron) {
    return Container(
      width: 80,
      height: 80,
      color: saffron.withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.restaurant_menu, color: saffron, size: 28),
      ),
    );
  }
}
