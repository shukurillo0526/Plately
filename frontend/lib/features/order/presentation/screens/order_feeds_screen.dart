// Plately — Order Feeds Screen (Restaurant-linked, YouTube-backed)
// ===================================================================
// TikTok-style vertical food video feed.
// Videos are linked to nearby restaurants.
// Right sidebar: Like, Order/Reserve/Go (context-aware), Share, Save
// Tap thumbnail → opens YouTube. Buttons navigate to RestaurantDetailPage.

import 'package:flutter/material.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:plately_app/core/services/video_feed_service.dart';
import 'package:plately_app/core/services/location_service.dart';
import 'package:plately_app/core/services/restaurant_service.dart';
import 'package:plately_app/features/order/presentation/screens/restaurant_detail_page.dart';
import 'package:plately_app/core/widgets/youtube_embed.dart';
import 'package:share_plus/share_plus.dart';

class OrderFeedsScreen extends StatefulWidget {
  const OrderFeedsScreen({super.key});

  @override
  State<OrderFeedsScreen> createState() => _OrderFeedsScreenState();
}

class _OrderFeedsScreenState extends State<OrderFeedsScreen> {
  final LocationService _location = LocationService();
  final PageController _pageController = PageController();
  List<_FeedItem> _feeds = [];
  int _currentPage = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);

    // Load videos and restaurants in parallel
    final videosFuture = VideoFeedService.getOrderFeeds();
    final restaurantsFuture = RestaurantService.getNearbyRestaurants(
      lat: _location.latitude,
      lng: _location.longitude,
      radius: _location.radiusMeters,
    );

    final videos = await videosFuture;
    final restaurants = await restaurantsFuture;

    // Pair each video with a restaurant (round-robin assignment)
    final feeds = <_FeedItem>[];
    for (int i = 0; i < videos.length; i++) {
      final v = videos[i];
      // If video has a linked restaurant_id, find it. Otherwise assign round-robin.
      Restaurant? r;
      if (v.restaurantId != null) {
        r = restaurants.where((rest) => rest.id == v.restaurantId).firstOrNull;
      }
      r ??= restaurants.isNotEmpty ? restaurants[i % restaurants.length] : null;
      feeds.add(_FeedItem(video: v, restaurant: r));
    }

    if (mounted) {
      setState(() {
        _feeds = feeds;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    if (_feeds.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, size: 56, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)?.auto_noFoodVideosYet ?? 'No food videos yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _feeds.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => _OrderVideoCard(feed: _feeds[i], isActive: i == _currentPage),
          ),

          // ── Top overlay ────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)?.auto_foodFeed ?? 'Food Feed', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('${_location.regionName} · ${_feeds.length} videos',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
                    ],
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${_currentPage + 1} / ${_feeds.length}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════

class _FeedItem {
  final VideoFeed video;
  final Restaurant? restaurant;
  const _FeedItem({required this.video, this.restaurant});
}

// ═══════════════════════════════════════════════════════════════════
//  ORDER VIDEO CARD
// ═══════════════════════════════════════════════════════════════════

class _OrderVideoCard extends StatefulWidget {
  final _FeedItem feed;
  final bool isActive;
  const _OrderVideoCard({required this.feed, required this.isActive});

  @override
  State<_OrderVideoCard> createState() => _OrderVideoCardState();
}

class _OrderVideoCardState extends State<_OrderVideoCard> {
  bool _liked = false;
  bool _saved = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(covariant _OrderVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-stop playback when scrolled off-screen to free iframe memory
    if (oldWidget.isActive && !widget.isActive && _playing) {
      setState(() => _playing = false);
    }
  }

  void _registerView() {
    registerYouTubeView(widget.feed.video.youtubeId);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.feed.video;
    final r = widget.feed.restaurant;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final likes = v.likes + (_liked ? 1 : 0);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background: thumbnail or video ────────────
          if (_playing) ...[
            YouTubeEmbed(youtubeId: widget.feed.video.youtubeId),
            // Close button to resume scrolling
            Positioned(top: 12, right: 12, child: GestureDetector(
              onTap: () => setState(() => _playing = false),
              child: Container(padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6), shape: BoxShape.circle),
                child: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface, size: 20)))),
          ]
          else
            GestureDetector(
              onTap: () => setState(() => _playing = true),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(v.thumbnailUrl, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), size: 48)))),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.onSurface, size: 44),
                    ),
                  ),
                ],
              ),
            ),

          // ── Right sidebar ──────────────────────────
          Positioned(
            right: 12,
            bottom: 100 + bottomPad,
            child: Column(
              children: [
                // Like
                _SideBtn(icon: _liked ? Icons.favorite : Icons.favorite_border,
                  label: _fmt(likes), color: _liked ? Colors.red : Theme.of(context).colorScheme.onSurface,
                  onTap: () => setState(() => _liked = !_liked)),
                SizedBox(height: 18),

                // Context-aware action buttons (based on restaurant services)
                if (r != null) ...[
                  if (r.hasDelivery)
                    _SideBtn(icon: Icons.shopping_bag_outlined, label: 'Order',
                      color: accent, highlighted: true,
                      onTap: () => _navigate(context, r, RestaurantSection.menu)),
                  if (r.hasDelivery) SizedBox(height: 18),

                  if (r.hasReservation)
                    _SideBtn(icon: Icons.event_seat_outlined, label: 'Reserve',
                      color: Colors.blue.shade400, highlighted: true,
                      onTap: () => _navigate(context, r, RestaurantSection.reserve)),
                  if (r.hasReservation) SizedBox(height: 18),

                  if (r.hasDineIn)
                    _SideBtn(icon: Icons.place_outlined, label: 'Go',
                      color: Colors.teal.shade400, highlighted: true,
                      onTap: () => _navigate(context, r, RestaurantSection.location)),
                  if (r.hasDineIn) SizedBox(height: 18),
                ],

                // Share
                _SideBtn(icon: Icons.reply_outlined, label: 'Share', color: Theme.of(context).colorScheme.onSurface,
                  onTap: () => SharePlus.instance.share(ShareParams(
                    text: '${v.title}\nhttps://youtube.com/watch?v=${v.youtubeId}',
                  ))),
                SizedBox(height: 18),

                // Save
                _SideBtn(icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                  label: _saved ? 'Saved' : 'Save', color: _saved ? accent : Theme.of(context).colorScheme.onSurface,
                  onTap: () => setState(() => _saved = !_saved)),
                SizedBox(height: 18),

                // Restaurant avatar
                if (r != null) _RestaurantAvatar(restaurant: r),
              ],
            ),
          ),

          // ── Bottom info ────────────────────────────
          Positioned(
            left: 16, right: 70, bottom: 16 + bottomPad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant name
                if (r != null)
                  Row(children: [
                    Text(r.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.verified, size: 14, color: Colors.blue.shade300),
                  ]),
                SizedBox(height: 6),

                // Video title
                Text(v.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),

                // Description
                if (v.description != null)
                  Text(v.description!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 8),

                // Restaurant service badges + distance
                if (r != null)
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (r.hasDelivery) _badge('🛵 Delivery', accent),
                    if (r.hasReservation) _badge('🪑 Reserve', Colors.blue.shade400),
                    if (r.hasDineIn) _badge('📍 Dine-in', Colors.teal.shade400),
                    if (r.distMeters > 0) _badge('📏 ${r.distanceLabel}', Theme.of(context).colorScheme.onSurface),
                  ]),

                // Tags
                if (r == null && v.tags.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: v.tags.take(4).map((t) =>
                    Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('#$t', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600)))).toList()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color c) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: c.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w600)));

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  void _navigate(BuildContext context, Restaurant r, RestaurantSection section) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RestaurantDetailPage(restaurant: r, initialSection: section),
    ));
  }
}

// ── Shared Widgets ──────────────────────────────────────────────

class _SideBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final bool highlighted; final VoidCallback onTap;
  const _SideBtn({required this.icon, required this.label, required this.color, this.highlighted = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Column(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: highlighted ? color.withValues(alpha: 0.2) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          border: highlighted ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5) : null),
        child: Icon(icon, size: 22, color: color)),
      SizedBox(height: 3),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w600)),
    ]));
}

class _RestaurantAvatar extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantAvatar({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final initial = restaurant.name.isNotEmpty ? restaurant.name[0] : '?';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => RestaurantDetailPage(restaurant: restaurant))),
      child: Column(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary]),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)),
          child: Center(child: Text(initial,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)))),
        SizedBox(height: 3),
        SizedBox(width: 50, child: Text(restaurant.name,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
