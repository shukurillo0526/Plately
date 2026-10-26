// Plately — Explore Screen
// ===========================
// Social discovery hub with two tabs:
// 1. Reels — vertical video/tip feed
// 2. Community — recipe cards from the community
// Features: likes, bookmarks, external video links, tags.

import 'package:flutter/material.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:plately_app/core/services/video_feed_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/features/explore/presentation/screens/creator_page.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_detail_screen.dart';
import 'package:plately_app/core/widgets/youtube_embed.dart';
import 'package:plately_app/core/widgets/community_post_card.dart';
import 'package:plately_app/core/services/social_service.dart';
import 'package:plately_app/features/profile/presentation/screens/post_upload_form.dart';
import 'package:plately_app/core/widgets/story_ring.dart';
import 'package:plately_app/features/explore/presentation/screens/social_search_page.dart';
import 'package:plately_app/core/services/restaurant_service.dart';
import 'package:plately_app/features/order/presentation/screens/restaurant_detail_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plately_app/core/services/recipe_monetization_service.dart';
import 'package:plately_app/features/cook/presentation/widgets/recipe_paywall_sheet.dart';
import 'package:plately_app/core/widgets/recipe_share_card.dart';
import 'package:plately_app/features/cook/presentation/screens/executive_recipe_studio_screen.dart';
import 'package:plately_app/features/cook/presentation/screens/my_recipes_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF7861C), Color(0xFFFFB300)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('🍽️', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plately Social',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Kitchens, Cooks & Masterclasses',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Search button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SocialSearchPage())),
                      tooltip: 'Search Food & Chefs',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chef Portfolio button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.menu_book, size: 20, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyRecipesScreen())),
                      tooltip: "Chef's Portfolio",
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bookmarks button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.bookmark_outline, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      onPressed: () => _showBookmarks(context),
                      tooltip: 'Saved',
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ─────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                ),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                tabs: const [
                  Tab(text: '🌟 For You'),
                  Tab(text: '🍽️ Community'),
                  Tab(text: '💎 Executive'),
                ],
              ),
            ),

            // ── Tab Content ─────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ReelsFeed(),
                  _CommunityFeed(),
                  _ExecutiveRecipesFeed(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const _BookmarksSheet(),
    );
  }
}

// ── YouTube-Backed Reels Feed ──────────────────────────────────────────

class _ReelsFeed extends StatefulWidget {
  const _ReelsFeed();
  @override
  State<_ReelsFeed> createState() => _ReelsFeedState();
}

class _ReelsFeedState extends State<_ReelsFeed> {
  final PageController _pgCtrl = PageController();
  List<VideoFeed> _videos = [];
  int _current = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _pgCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final v = await VideoFeedService.getCookFeeds();
    if (mounted) setState(() { _videos = v; _loading = false; });
  }

  void _reg(String ytId) {
    registerYouTubeView(ytId);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    if (_videos.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('🎬', style: TextStyle(fontSize: 48)),
      SizedBox(height: 12),
      Text(AppLocalizations.of(context)?.auto_noReelsYet ?? 'No reels yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16)),
    ]));
    }

    return PageView.builder(
      controller: _pgCtrl,
      scrollDirection: Axis.vertical,
      itemCount: _videos.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (ctx, i) => _YTReelCard(video: _videos[i], isActive: i == _current, reg: _reg),
    );
  }
}

class _YTReelCard extends StatefulWidget {
  final VideoFeed video;
  final bool isActive;
  final void Function(String) reg;
  const _YTReelCard({required this.video, required this.isActive, required this.reg});
  @override
  State<_YTReelCard> createState() => _YTReelCardState();
}

class _YTReelCardState extends State<_YTReelCard> {
  bool _liked = false;
  bool _playing = false;
  bool _showRecipe = false;
  bool _saved = false;

  @override
  void didUpdateWidget(covariant _YTReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-stop playback when scrolled off-screen to free iframe memory
    if (oldWidget.isActive && !widget.isActive && _playing) {
      setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    const green = Color(0xFF4CAF50);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video or Thumbnail ──────────────────
          if (_playing && widget.isActive) ...[
            Builder(builder: (_) { widget.reg(v.youtubeId); return YouTubeEmbed(youtubeId: v.youtubeId); }),
            // Close button to stop video and resume scrolling
            Positioned(top: 12, right: 12, child: GestureDetector(
              onTap: () => setState(() => _playing = false),
              child: Container(padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6), shape: BoxShape.circle),
                child: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface, size: 20)))),
          ] else
            GestureDetector(
              onTap: () => setState(() => _playing = true),
              child: Stack(fit: StackFit.expand, children: [
                Image.network(v.thumbnailUrl, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
                Container(decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)]))),
                Center(child: Container(padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: green.withValues(alpha: 0.25), shape: BoxShape.circle),
                  child: Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.onSurface, size: 44))),
              ]),
            ),

          // ── Recipe overlay ──────────────────────
          if (_showRecipe && v.hasRecipe)
            _VideoRecipeSheet(video: v, onClose: () => setState(() => _showRecipe = false)),

          // ── Sidebar ──────────────────────────────
          if (!_showRecipe && !_playing)
            Positioned(right: 12, bottom: 80, child: Column(children: [
              _FeedSideBtn(icon: _liked ? Icons.favorite : Icons.favorite_border,
                label: v.likesLabel, color: _liked ? Colors.red : Theme.of(context).colorScheme.onSurface,
                onTap: () => setState(() => _liked = !_liked)),
              SizedBox(height: 16),
              if (v.hasRecipe)
                _FeedSideBtn(icon: Icons.restaurant_menu, label: 'Cook', color: green,
                  highlighted: true, onTap: () => setState(() => _showRecipe = true)),
              if (v.hasRecipe) SizedBox(height: 16),
              _FeedSideBtn(icon: Icons.reply_outlined, label: 'Share', color: Theme.of(context).colorScheme.onSurface,
                onTap: () => SharePlus.instance.share(ShareParams(
                  text: '${v.title}\nhttps://youtube.com/watch?v=${v.youtubeId}',
                ))),
              SizedBox(height: 16),
              _FeedSideBtn(icon: _saved ? Icons.bookmark : Icons.bookmark_outline,
                label: _saved ? 'Saved' : 'Save',
                color: _saved ? green : Theme.of(context).colorScheme.onSurface,
                onTap: () => setState(() => _saved = !_saved)),
              SizedBox(height: 16),
              Container(width: 38, height: 38, decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)),
                child: Center(child: Text(v.authorName.isNotEmpty ? v.authorName[0] : '?',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w800)))),
            ])),

          // ── Bottom info ──────────────────────────
          if (!_showRecipe && !_playing)
            Positioned(left: 16, right: 70, bottom: 12, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Text('@${v.authorName.replaceAll(' ', '_').toLowerCase()}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
                    if (v.restaurantId != null) ...[
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 10, color: Colors.amber),
                            SizedBox(width: 2),
                            Text('RESTAURANT', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(v.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                if (v.hasRecipe) Row(children: [
                  if (v.recipePrepTime.isNotEmpty) _pill('⏱ ${v.recipePrepTime}', green),
                  if (v.recipeCookTime.isNotEmpty) ...[SizedBox(width: 5), _pill('🔥 ${v.recipeCookTime}', Colors.orange)],
                ]),
                SizedBox(height: 4),
                if (v.tags.isNotEmpty) Wrap(spacing: 5, children: v.tags.take(3).map((t) =>
                  Text('#$t', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w600))).toList()),
                if (v.restaurantId != null) ...[
                  SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final restData = await Supabase.instance.client
                            .from('restaurants')
                            .select()
                            .eq('id', v.restaurantId!)
                            .maybeSingle();
                        if (restData != null && context.mounted) {
                          final rest = Restaurant.fromJson(restData);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => RestaurantDetailPage(restaurant: rest),
                          ));
                        }
                      } catch (_) {}
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant, size: 13, color: Colors.amber),
                          SizedBox(width: 5),
                          Text('Order from Restaurant',
                            style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(width: 3),
                          Icon(Icons.chevron_right, size: 14, color: Colors.amber),
                        ],
                      ),
                    ),
                  ),
                ],
              ])),
        ],
      ),
    );
  }

  Widget _pill(String t, Color c) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w700)));
}

class _FeedSideBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final bool highlighted; final VoidCallback onTap;
  const _FeedSideBtn({required this.icon, required this.label, required this.color, this.highlighted = false, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Column(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: highlighted ? color.withValues(alpha: 0.2) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          border: highlighted ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5) : null),
        child: Icon(icon, size: 20, color: color)),
      SizedBox(height: 2),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 9, fontWeight: FontWeight.w600)),
    ]));
}

class _VideoRecipeSheet extends StatelessWidget {
  final VideoFeed video;
  final VoidCallback onClose;
  const _VideoRecipeSheet({required this.video, required this.onClose});
  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF4CAF50);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(video.recipeTitle,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w800))),
          GestureDetector(onTap: onClose, child: Container(padding: EdgeInsets.all(6),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface, size: 16))),
        ]),
        SizedBox(height: 8),
        Expanded(child: ListView(children: [
          Text(AppLocalizations.of(context)?.auto_ingredients ?? 'Ingredients', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          ...video.recipeIngredients.map((i) => Padding(padding: EdgeInsets.only(bottom: 2),
            child: Row(children: [
              Container(width: 4, height: 4, decoration: BoxDecoration(color: green, shape: BoxShape.circle)),
              SizedBox(width: 8),
              Expanded(child: Text(i, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12))),
            ]))),
          SizedBox(height: 10),
          Text(AppLocalizations.of(context)?.auto_steps ?? 'Steps', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          ...video.recipeSteps.asMap().entries.map((e) => Padding(padding: EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 20, height: 20,
                decoration: BoxDecoration(color: green.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Center(child: Text('${e.key + 1}', style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.w700)))),
              SizedBox(width: 8),
              Expanded(child: Text(e.value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, height: 1.3))),
            ]))),
        ])),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ "${video.recipeTitle}" saved!'),
            backgroundColor: green, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); onClose(); },
          child: Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF81C784)]),
              borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.onSurface, size: 16),
              SizedBox(width: 6),
              Text(AppLocalizations.of(context)?.auto_cookThisRecipe ?? 'Cook This Recipe', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
            ])),
        ),
      ]),
    );
  }
}



class _ReelCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const _ReelCard({required this.post});
  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard> {
  bool _liked = false;
  bool _bookmarked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post['like_count'] ?? 0;
    _checkUserInteractions();
  }

  Future<void> _checkUserInteractions() async {
    try {
      final userId = currentUserId();
      final postId = widget.post['id'];
      final likes = await Supabase.instance.client
          .from('post_likes').select('user_id')
          .eq('user_id', userId).eq('post_id', postId);
      final bookmarks = await Supabase.instance.client
          .from('post_bookmarks').select('user_id')
          .eq('user_id', userId).eq('post_id', postId);
      if (mounted) {
        setState(() {
          _liked = (likes as List).isNotEmpty;
          _bookmarked = (bookmarks as List).isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final userId = currentUserId();
    final postId = widget.post['id'];
    setState(() { _liked = !_liked; _likeCount += _liked ? 1 : -1; });
    try {
      if (_liked) {
        await Supabase.instance.client.from('post_likes').insert({'user_id': userId, 'post_id': postId});
      } else {
        await Supabase.instance.client.from('post_likes').delete().eq('user_id', userId).eq('post_id', postId);
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    final userId = currentUserId();
    final postId = widget.post['id'];
    setState(() => _bookmarked = !_bookmarked);
    try {
      if (_bookmarked) {
        await Supabase.instance.client.from('post_bookmarks').insert({'user_id': userId, 'post_id': postId});
      } else {
        await Supabase.instance.client.from('post_bookmarks').delete().eq('user_id', userId).eq('post_id', postId);
      }
    } catch (_) {}
  }

  void _showInlineRecipe(BuildContext context, String recipeId, String caption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: FutureBuilder(
                future: Supabase.instance.client
                    .from('recipes')
                    .select('*')
                    .eq('id', recipeId)
                    .maybeSingle(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text(AppLocalizations.of(context)?.auto_recipeNotFound ?? 'Recipe not found', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))));
                  }
                  
                  final recipe = snapshot.data as Map<String, dynamic>;
                  final ingredients = (recipe['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  final rawSteps = recipe['steps'];
                  final steps = rawSteps is List 
                      ? rawSteps.map((s) => s is Map ? (s['text'] ?? '$s') : '$s').toList().cast<String>()
                      : (rawSteps is String ? rawSteps.split('. ') : <String>[]);

                  return Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 12),
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)),
                      ),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(recipe['title'] ?? 'Recipe', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold))),
                            IconButton(
                              icon: Icon(Icons.open_in_new, color: Theme.of(context).colorScheme.primary),
                              tooltip: 'Open Full Recipe',
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(
                                    recipeId: recipeId,
                                    title: recipe['title'] ?? '',
                                    tierColor: Theme.of(context).colorScheme.primary,
                                    ownedIngredientIds: const {},
                                  )
                                ));
                              },
                            )
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.all(20),
                          children: [
                            // Quick stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _InfoChip(icon: Icons.timer, label: '${recipe['prep_time_minutes'] ?? 0}m prep'),
                                _InfoChip(icon: Icons.local_fire_department, label: '${recipe['calories_per_serving'] ?? 0} cal'),
                              ],
                            ),
                            SizedBox(height: 24),
                            
                            // Ingredients (JSONB)
                            Text(AppLocalizations.of(context)?.auto_ingredients ?? 'Ingredients', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            ...ingredients.map((ing) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                                      SizedBox(width: 12),
                                      Expanded(child: Text(ing['name'] ?? 'Unknown', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15))),
                                      Text('${ing['quantity'] ?? ''} ${ing['unit'] ?? ''}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                                    ],
                                  ),
                                );
                            }),
                            
                            SizedBox(height: 24),
                            // Steps
                            Text(AppLocalizations.of(context)?.auto_steps ?? 'Steps', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            ...steps.asMap().entries.map((req) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24, height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                                      child: Text('${req.key + 1}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(child: Text(req.value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9), height: 1.5))),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.post['caption'] ?? '';
    final tags = List<String>.from(widget.post['tags'] ?? []);
    final videoUrl = widget.post['video_url'];
    final author = widget.post['users'] as Map<String, dynamic>?;
    final authorName = author?['display_name'] ?? 'Chef';
    final postType = widget.post['post_type'] ?? 'tip';
    final isReel = postType == 'reel' && videoUrl != null;
    final recipeId = widget.post['recipe_id'];

    // Color based on post type
    final gradColors = isReel
        ? [Colors.deepPurple.withValues(alpha: 0.5), Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)]
        : [Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradColors,
        ),
      ),
      child: Stack(
        children: [
          // Center icon / type indicator
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isReel ? Icons.play_circle_outline : Icons.lightbulb_outline,
                  size: 72, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                SizedBox(height: 8),
                Text(isReel ? 'Video Reel' : 'Cooking Tip',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Right-side action column (TikTok-style)
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                // Author avatar
                GestureDetector(
                  onTap: () {
                    final authorId = widget.post['author_id'];
                    if (authorId != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CreatorPage(creatorId: authorId, creatorName: authorName)));
                    }
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    child: Text(authorName[0].toUpperCase(),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
                SizedBox(height: 20),
                // Like
                _VerticalAction(
                  icon: _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.red : Theme.of(context).colorScheme.onSurface,
                  label: '$_likeCount',
                  onTap: _toggleLike),
                SizedBox(height: 16),
                // Bookmark
                _VerticalAction(
                  icon: _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _bookmarked ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                  label: _bookmarked ? 'Saved' : 'Save',
                  onTap: _toggleBookmark),
                SizedBox(height: 16),
                if (recipeId != null)
                  _VerticalAction(
                    icon: Icons.restaurant_menu,
                    color: Colors.orange,
                    label: 'Recipe',
                    onTap: () => _showInlineRecipe(context, recipeId, caption)),
                if (recipeId != null) SizedBox(height: 16),
                // Play video
                if (isReel)
                  _VerticalAction(
                    icon: Icons.play_arrow,
                    color: Colors.red,
                    label: 'Play',
                    onTap: () async {
                      final uri = Uri.parse(videoUrl);
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }),
              ],
            ),
          ),

          // Bottom overlay — caption, author, tags
          Positioned(
            left: 16,
            right: 60,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name
                GestureDetector(
                  onTap: () {
                    final authorId = widget.post['author_id'];
                    if (authorId != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CreatorPage(creatorId: authorId, creatorName: authorName)));
                    }
                  },
                  child: Text('@$authorName',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                SizedBox(height: 6),
                // Caption
                Text(caption,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, height: 1.4)),
                SizedBox(height: 8),
                // Tags
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((t) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text('#$t',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11)),
                    )).toList(),
                  ),
                // Recipe badge
                if (recipeId != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(AppLocalizations.of(context)?.auto_hasRecipe ?? 'Has Recipe', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _VerticalAction({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Community Recipe Feed ─────────────────────────────────────────

class _CommunityFeed extends StatefulWidget {
  const _CommunityFeed();
  @override
  State<_CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<_CommunityFeed> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final data = await SocialService.getCommunityFeed(limit: 30);
      if (mounted) setState(() { _posts = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCreatePost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EnhancedPostUploadForm()),
    );
    if (result == true) _loadPosts(); // Refresh after new post
  }

  void _showCreationMenu(BuildContext context) {
    final theme = Theme.of(context);
    final saffron = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Create & Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: saffron.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_a_photo, color: saffron, size: 22),
              ),
              title: const Text('Share Food Moment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Post dish photos, tag recipes, or share culinary thoughts.', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _openCreatePost();
              },
            ),
            const Divider(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium, color: Color(0xFFFFB300), size: 22),
              ),
              title: const Text('Craft Executive Recipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Design steps, timers, and monetize masterclasses.', style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const ExecutiveRecipeStudioScreen()),
                );
                if (res == true) _loadPosts();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
    }

    return Stack(
      children: [
        // Main content
        _posts.isEmpty
          ? Column(
              children: [
                // Story ring even when no posts
                const StoryRing(),
                Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12), height: 1),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\u{1F37D}\u{FE0F}', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(AppLocalizations.of(context)?.auto_noCommunityPostsYet ?? 'No community posts yet',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16)),
                        SizedBox(height: 8),
                        Text(AppLocalizations.of(context)?.auto_beTheFirstToShare ?? 'Be the first to share!',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13)),
                        SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _openCreatePost,
                          icon: Icon(Icons.add_a_photo, size: 18),
                          label: Text(AppLocalizations.of(context)?.auto_createPost ?? 'Create Post'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: _loadPosts,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                itemCount: _posts.length + 1, // +1 for story ring
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return Column(
                      children: [
                        const StoryRing(),
                        Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06), height: 1),
                        SizedBox(height: 8),
                      ],
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CommunityPostCard(post: _posts[i - 1]),
                  );
                },
              ),
            ),

        // \u2500\u2500 FAB: Create new post \u2500\u2500
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'community_fab',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            onPressed: () => _showCreationMenu(context),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }
}

// ── Bookmarks Sheet ─────────────────────────────────────────────

class _BookmarksSheet extends StatefulWidget {
  const _BookmarksSheet();
  @override
  State<_BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends State<_BookmarksSheet> {
  List<Map<String, dynamic>> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final userId = currentUserId();
      final data = await Supabase.instance.client
          .from('post_bookmarks')
          .select('*, posts(caption, post_type, tags)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      setState(() { _bookmarks = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary, size: 22),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.auto_savedPosts ?? 'Saved Posts',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 16),
          if (_loading)
            Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          else if (_bookmarks.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(AppLocalizations.of(context)?.auto_noSavedPostsYet ?? 'No saved posts yet',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _bookmarks.length,
                itemBuilder: (ctx, i) {
                  final bm = _bookmarks[i];
                  final post = bm['posts'] as Map<String, dynamic>?;
                  final caption = post?['caption'] ?? 'Saved post';
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (post != null) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('📖 ${post['caption'] ?? 'Viewing saved post'}'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(caption,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
          SizedBox(width: 6),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════
// 💎 EXECUTIVE RECIPES FEED
// ═════════════════════════════════════════════════════════════════════

class _ExecutiveRecipesFeed extends StatefulWidget {
  const _ExecutiveRecipesFeed();

  @override
  State<_ExecutiveRecipesFeed> createState() => _ExecutiveRecipesFeedState();
}

class _ExecutiveRecipesFeedState extends State<_ExecutiveRecipesFeed> {
  List<RecipeModel> _recipes = [];
  bool _loading = true;
  String _activeFilter = 'All';

  final List<String> _filters = ['All', 'Uzbek', 'Italian', 'Masterclasses', 'Quick (<30m)'];

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
        description: 'Golden laser rice, tender mutton shoulder, yellow carrots, barberries, and roasted whole garlic.',
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
        // ── Filter Chips ──
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8),
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
                    child: Text(
                      'No recipes in this category yet',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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

                // Gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Left: Cuisine & Difficulty
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
