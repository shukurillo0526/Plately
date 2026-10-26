// Plately — Executive Recipes Feed
// ==================================
// Dedicated showcase for Executive Masterclass and Chef-monetized recipes.
// Placed directly in Cook Mode alongside the 5 tiers for seamless cooking access.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plately_app/core/services/recipe_monetization_service.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_detail_screen.dart';
import 'package:plately_app/features/cook/presentation/screens/executive_recipe_studio_screen.dart';
import 'package:plately_app/features/cook/presentation/widgets/recipe_paywall_sheet.dart';
import 'package:plately_app/core/widgets/recipe_share_card.dart';

class ExecutiveRecipesFeed extends StatefulWidget {
  const ExecutiveRecipesFeed({super.key});

  @override
  State<ExecutiveRecipesFeed> createState() => _ExecutiveRecipesFeedState();
}

class _ExecutiveRecipesFeedState extends State<ExecutiveRecipesFeed> {
  List<RecipeModel> _recipes = [];
  bool _loading = true;
  String _activeFilter = 'All';

  final List<String> _filters = ['All', 'Uzbek', 'Italian', 'Japanese', 'Masterclasses', 'Quick (<30m)'];

  @override
  void initState() {
    super.initState();
    _loadExecutiveRecipes();
  }

  Future<void> _loadExecutiveRecipes() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('recipes')
          .select()
          .or('is_community.eq.true,is_premium.eq.true')
          .order('created_at', ascending: false)
          .limit(40);

      final list = (res as List).map((m) => RecipeModel.fromMap(m)).toList();
      if (mounted) {
        setState(() {
          _recipes = list.isNotEmpty ? list : _demoExecutiveRecipes();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recipes = _demoExecutiveRecipes();
          _loading = false;
        });
      }
    }
  }

  List<RecipeModel> _demoExecutiveRecipes() {
    return [
      RecipeModel(
        id: 'exec-plov-001',
        title: "Samarkand Wedding Plov (To'y Oshi)",
        description: 'Golden laser rice, tender mutton shoulder, yellow carrots, barberries, and roasted whole garlic cooked to perfection in a cast-iron kazan.',
        cuisine: 'Uzbek',
        difficulty: 3,
        prepTime: 30,
        cookTime: 90,
        servings: 8,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
        isPremium: true,
        priceCents: 199,
        copyCount: 142,
        caloriesPerServing: 680,
      ),
      RecipeModel(
        id: 'exec-pasta-002',
        title: 'Handmade Truffle Tagliolini',
        description: 'Silky egg yolk dough tossed in cultured Normandy butter, aged Parmigiano Reggiano, and shaved black winter truffles.',
        cuisine: 'Italian',
        difficulty: 2,
        prepTime: 25,
        cookTime: 12,
        servings: 2,
        imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80',
        isPremium: false,
        priceCents: 0,
        copyCount: 89,
        caloriesPerServing: 490,
      ),
      RecipeModel(
        id: 'exec-steak-003',
        title: 'Kagoshima A5 Wagyu Ribeye & Charred Scallions',
        description: 'Reverse-seared marbled Japanese wagyu with tare glaze, sea salt crystals, and smoked garlic scallion oil.',
        cuisine: 'Japanese',
        difficulty: 3,
        prepTime: 15,
        cookTime: 15,
        servings: 2,
        imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80',
        isPremium: true,
        priceCents: 299,
        copyCount: 215,
        caloriesPerServing: 590,
      ),
      RecipeModel(
        id: 'exec-lagman-004',
        title: 'Hand-Pulled Uyghur Lagman with Rich Jus',
        description: 'Traditional stretched noodles served with wok-seared beef slivers, Chinese celery, bell peppers, and fragrant star anise broth.',
        cuisine: 'Uzbek',
        difficulty: 3,
        prepTime: 40,
        cookTime: 25,
        servings: 4,
        imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=800&q=80',
        isPremium: false,
        priceCents: 0,
        copyCount: 167,
        caloriesPerServing: 520,
      ),
    ];
  }

  List<RecipeModel> get _filteredRecipes {
    if (_activeFilter == 'All') return _recipes;
    if (_activeFilter == 'Masterclasses') return _recipes.where((r) => r.isPremium).toList();
    if (_activeFilter == 'Quick (<30m)') {
      return _recipes.where((r) => ((r.prepTime ?? 0) + (r.cookTime ?? 0)) <= 30).toList();
    }
    return _recipes.where((r) => (r.cuisine ?? '').toLowerCase() == _activeFilter.toLowerCase()).toList();
  }

  void _onRecipeTap(RecipeModel recipe) async {
    if (recipe.isPremium && !recipe.isOwn) {
      final hasAccess = await RecipeMonetizationService.hasAccess(recipe.id);
      if (!hasAccess && mounted) {
        RecipePaywallSheet.show(context, recipe, onUnlocked: () {
          _openDetail(recipe);
        });
        return;
      }
    }
    _openDetail(recipe);
  }

  void _openDetail(RecipeModel recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipeId: recipe.id,
          title: recipe.title,
          description: recipe.description,
          cuisine: recipe.cuisine,
          difficulty: recipe.difficulty,
          prepTime: recipe.prepTime,
          cookTime: recipe.cookTime,
          servings: recipe.servings,
          tierColor: Theme.of(context).colorScheme.primary,
          ownedIngredientIds: const {},
          caloriesPerServing: recipe.caloriesPerServing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saffron = theme.colorScheme.primary;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: saffron));
    }

    final list = _filteredRecipes;

    return Column(
      children: [
        // ── Studio CTA Banner ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                saffron.withValues(alpha: 0.15),
                const Color(0xFFFFB300).withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: saffron.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: saffron.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium, color: saffron, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Executive Recipe Studio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Craft precision recipes with multi-step timers',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExecutiveRecipeStudioScreen()),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: saffron,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Craft', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
        ),

        // ── Filter Chips ──
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (ctx, i) {
              final f = _filters[i];
              final isSel = f == _activeFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: isSel,
                  onSelected: (val) => setState(() => _activeFilter = f),
                  selectedColor: saffron.withValues(alpha: 0.2),
                  checkmarkColor: saffron,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? saffron : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(
                    color: isSel ? saffron : Colors.white.withValues(alpha: 0.08),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
        ),

        // ── Recipe List ──
        Expanded(
          child: RefreshIndicator(
            color: saffron,
            onRefresh: _loadExecutiveRecipes,
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'No executive recipes in this category yet',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _activeFilter = 'All'),
                          child: const Text('View All Categories'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final r = list[i];
                      return _buildExecutiveCard(r, theme, saffron);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveCard(RecipeModel r, ThemeData theme, Color saffron) {
    final totalTime = (r.prepTime ?? 0) + (r.cookTime ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: r.isPremium
              ? const Color(0xFFFFB300).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onRecipeTap(r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Photo Stack
            Stack(
              children: [
                if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: r.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => _fallbackHeader(saffron),
                  )
                else
                  _fallbackHeader(saffron),

                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Left: Cuisine & Masterclass pill
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      if (r.cuisine != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            r.cuisine!.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (r.isPremium) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFF7861C), Color(0xFFFFB300)]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.workspace_premium, size: 12, color: Colors.black87),
                              SizedBox(width: 3),
                              Text(
                                'MASTERCLASS',
                                style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Top Right: Share
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.share, size: 16, color: Colors.white),
                    ),
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
                ),

                // Bottom Left on image: Title
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Text(
                    r.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.description != null && r.description!.isNotEmpty)
                    Text(
                      r.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Meta Row
                  Row(
                    children: [
                      if (totalTime > 0) ...[
                        Icon(Icons.timer_outlined, size: 14, color: saffron),
                        const SizedBox(width: 4),
                        Text(
                          '${totalTime}m',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (r.caloriesPerServing != null) ...[
                        const Icon(Icons.local_fire_department_outlined, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${r.caloriesPerServing} kcal',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (r.copyCount > 0) ...[
                        Icon(Icons.people_outline, size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text(
                          '${r.copyCount} unlocked',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                        ),
                      ],
                      const Spacer(),
                      // Price Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: r.isPremium
                              ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: r.isPremium
                                ? const Color(0xFFFFB300).withValues(alpha: 0.4)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          r.isPremium ? '${(r.priceCents * 128).round()} UZS' : 'Free Recipe',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: r.isPremium ? const Color(0xFFFFB300) : const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackHeader(Color saffron) {
    return Container(
      height: 160,
      width: double.infinity,
      color: saffron.withValues(alpha: 0.15),
      child: Center(
        child: Icon(Icons.restaurant_menu, color: saffron, size: 40),
      ),
    );
  }
}
