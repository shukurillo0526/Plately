// Plately — Story Viewer
// ========================
// Full-screen food story viewer with:
// - Auto-advance timer (5s per story)
// - Instagram-style progress bars at top
// - Interactive Action Stickers (Order Special, Cook Recipe, Tip Chef)
// - Pause on long-press or modal open
// - Author identity badge (Restaurant kitchen, verified creator, diner)
// - Swipe-down dismiss

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plately_app/core/services/story_service.dart';
import 'package:plately_app/core/services/restaurant_service.dart';
import 'package:plately_app/features/order/presentation/screens/restaurant_detail_page.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_detail_screen.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  const StoryViewer({
    super.key,
    required this.groups,
    this.initialGroupIndex = 0,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late int _groupIndex;
  int _storyIndex = 0;
  late AnimationController _progressController;
  Timer? _autoAdvanceTimer;

  static const _storyDuration = Duration(seconds: 5);

  StoryGroup get _currentGroup => widget.groups[_groupIndex];
  StoryItem get _currentStory => _currentGroup.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );
    _startStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _startStory() {
    _progressController.reset();
    _progressController.forward();

    // Mark as viewed
    StoryService.markViewed(_currentStory.id);

    // Auto-advance after duration
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(_storyDuration, _nextStory);
  }

  void _nextStory() {
    if (_storyIndex < _currentGroup.stories.length - 1) {
      setState(() => _storyIndex++);
      _startStory();
    } else {
      _nextGroup();
    }
  }

  void _prevStory() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _startStory();
    } else {
      _prevGroup();
    }
  }

  void _nextGroup() {
    if (_groupIndex < widget.groups.length - 1) {
      setState(() {
        _groupIndex++;
        _storyIndex = 0;
      });
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevGroup() {
    if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _storyIndex = 0;
      });
      _startStory();
    }
  }

  void _pause() {
    _progressController.stop();
    _autoAdvanceTimer?.cancel();
  }

  void _resume() {
    _progressController.forward();
    final remaining = _storyDuration * (1 - _progressController.value);
    _autoAdvanceTimer = Timer(remaining, _nextStory);
  }

  void _handleStoryAction(StoryItem story) async {
    _pause();

    if (story.storyActionType == 'order') {
      // Find or build restaurant
      final rest = Restaurant(
        id: story.restaurantId ?? 'demo-rest',
        name: story.restaurantName ?? story.authorName,
        cuisineType: ['National', 'Uzbek'],
        priceRange: 2,
        rating: 4.8,
        reviewCount: 320,
        imageUrl: story.restaurantLogo ?? story.mediaUrl,
        isOpen: true,
        avgPrepMinutes: 20,
        deliveryFee: 5000,
        tags: ['Featured', 'Daily Special'],
        distMeters: 1200,
        latitude: 41.3111,
        longitude: 69.2797,
        hasDelivery: true,
        hasReservation: true,
        hasDineIn: true,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantDetailPage(restaurant: rest, initialSection: RestaurantSection.menu),
        ),
      );
    } else if (story.storyActionType == 'cook') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipeId: story.recipeId ?? 'demo-recipe-1',
            title: story.recipeTitle ?? 'Signature Dish',
            tierColor: const Color(0xFF10B981),
            ownedIngredientIds: const {},
          ),
        ),
      );
    }

    _resume();
  }

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final group = _currentGroup;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Tap left third = prev, right two-thirds = next
        onTapUp: (details) {
          final w = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < w / 3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Story Media ──
            CachedNetworkImage(
              imageUrl: story.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => const Center(
                child: CircularProgressIndicator(color: Color(0xFFF7861C), strokeWidth: 2),
              ),
              errorWidget: (_, _, _) => Container(
                color: const Color(0xFF161B22),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24, size: 56),
                ),
              ),
            ),

            // ── Top Gradient Overlay ──
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 130 + topPad,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Bottom Gradient Overlay ──
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 220 + bottomPad,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xE6000000), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Segmented Progress Bars ──
            Positioned(
              top: topPad + 8,
              left: 10, right: 10,
              child: Row(
                children: List.generate(group.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 2.5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: i < _storyIndex
                            ? Container(color: Colors.white)
                            : i == _storyIndex
                                ? AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (_, _) => LinearProgressIndicator(
                                      value: _progressController.value,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 2.5,
                                    ),
                                  )
                                : Container(color: Colors.white24),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Author Header ──
            Positioned(
              top: topPad + 20,
              left: 14, right: 14,
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: group.isRestaurant ? const Color(0xFFF7861C) : Colors.white30,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: group.avatarUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => _avatarFallback(group.userName),
                            )
                          : _avatarFallback(group.userName),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + Badge + Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                group.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (group.isRestaurant) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7861C),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'KITCHEN',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _timeAgo(story.createdAt),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Delete button (own stories)
                  if (group.isOwn) ...[
                    GestureDetector(
                      onTap: () async {
                        await StoryService.deleteStory(story.id);
                        if (!context.mounted) return;
                        if (group.stories.length <= 1) {
                          Navigator.pop(context, true);
                        } else {
                          setState(() {
                            group.stories.removeAt(_storyIndex);
                            if (_storyIndex >= group.stories.length) {
                              _storyIndex = group.stories.length - 1;
                            }
                          });
                          _startStory();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white70, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Action & Caption Container ──
            Positioned(
              bottom: 20 + bottomPad,
              left: 16, right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption Pill
                  if (story.caption != null && story.caption!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        story.caption!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Floating Interactive Action Sticker (Order / Cook / Tip)
                  if (story.hasAction)
                    GestureDetector(
                      onTap: () => _handleStoryAction(story),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: story.storyActionType == 'order'
                                ? [const Color(0xFFF7861C), const Color(0xFFFFA000)]
                                : [const Color(0xFF10B981), const Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (story.storyActionType == 'order' ? const Color(0xFFF7861C) : const Color(0xFF10B981))
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              story.storyActionType == 'order'
                                  ? Icons.shopping_bag_rounded
                                  : Icons.outdoor_grill_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              story.actionLabel ?? (story.storyActionType == 'order' ? 'Order Special' : 'Cook This Recipe'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: const Color(0xFF21262D),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
