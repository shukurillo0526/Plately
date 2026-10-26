// Plately — Story Ring
// ======================
// Horizontal scrollable row of food story avatars:
// - Saffron Flame ring = Restaurant Kitchens with Live Daily Specials
// - Emerald Mint ring = Diner & Home Cook moments
// - Royal Gold/Purple ring = Executive Chef masterclass drops
// - Distinct icon badges (Chef Hat for restaurants, Verified star for chefs)
// - Real avatar image caching with initials fallback

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plately_app/core/services/story_service.dart';
import 'package:plately_app/core/widgets/story_viewer.dart';

class StoryRing extends StatefulWidget {
  final VoidCallback? onStoryAdded;
  const StoryRing({super.key, this.onStoryAdded});

  @override
  State<StoryRing> createState() => StoryRingState();
}

class StoryRingState extends State<StoryRing> {
  List<StoryGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadStories();
  }

  Future<void> loadStories() async {
    final groups = await StoryService.getStoryGroups();
    if (mounted) setState(() { _groups = groups; _loading = false; });
  }

  void _openStoryViewer(int index) async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) => StoryViewer(
          groups: _groups,
          initialGroupIndex: index,
        ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (result == true) loadStories();
  }

  void _addStory() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text('Post a 24h Food Story',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Share what you just cooked, your pantry meal, or your restaurant review.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Choose Gallery',
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await StoryService.pickStoryImage(source: source);
    if (file == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2)),
          const SizedBox(width: 12),
          const Text('Publishing food story...'),
        ]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 10),
      ),
    );

    final url = await StoryService.uploadStoryMedia(file);
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final success = await StoryService.createStory(mediaUrl: url);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✨ Story live on Plately Pulse!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      loadStories();
      widget.onStoryAdded?.call();
    }
  }

  Widget _sourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _loading
          ? Center(
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
              ),
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                // ── Add Story Button ──
                _AddStoryAvatar(onTap: _addStory),

                // ── Story groups ──
                ..._groups.asMap().entries.map((entry) {
                  final group = entry.value;
                  return _StoryAvatar(
                    name: group.isOwn ? 'Your Story' : group.userName,
                    avatarUrl: group.avatarUrl,
                    hasUnviewed: group.hasUnviewed,
                    isOwn: group.isOwn,
                    isRestaurant: group.isRestaurant,
                    badgeType: group.badgeType,
                    storyCount: group.stories.length,
                    onTap: () => _openStoryViewer(entry.key),
                  );
                }),
              ],
            ),
    );
  }
}

// ── Add Story Avatar ──

class _AddStoryAvatar extends StatelessWidget {
  final VoidCallback onTap;
  const _AddStoryAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Add Story',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Story Avatar Ring ──

class _StoryAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool hasUnviewed;
  final bool isOwn;
  final bool isRestaurant;
  final String badgeType;
  final int storyCount;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.name,
    this.avatarUrl,
    required this.hasUnviewed,
    required this.isOwn,
    required this.isRestaurant,
    required this.badgeType,
    required this.storyCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Choose ring gradient according to story identity
    Gradient? ringGradient;
    if (hasUnviewed) {
      if (isRestaurant) {
        // Saffron Flame for Restaurant Kitchens
        ringGradient = const SweepGradient(
          colors: [Color(0xFFF7861C), Color(0xFFFFB300), Color(0xFFFF5722), Color(0xFFF7861C)],
        );
      } else if (badgeType == 'executive_chef') {
        // Royal Gold / Purple for Executive Creators
        ringGradient = const SweepGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFFFD700), Color(0xFFEC4899), Color(0xFF8B5CF6)],
        );
      } else {
        // Emerald Mint for Community Diners & Home Cooks
        ringGradient = const SweepGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF059669), Color(0xFF10B981)],
        );
      }
    }

    // Badge icon on bottom right
    IconData? badgeIcon;
    Color badgeBg = const Color(0xFFF7861C);
    if (isRestaurant) {
      badgeIcon = Icons.restaurant_menu_rounded;
      badgeBg = const Color(0xFFF7861C);
    } else if (badgeType == 'executive_chef') {
      badgeIcon = Icons.star_rounded;
      badgeBg = const Color(0xFF8B5CF6);
    } else if (isOwn) {
      badgeIcon = Icons.person_rounded;
      badgeBg = const Color(0xFF10B981);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ring
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ringGradient,
                    border: hasUnviewed
                        ? null
                        : Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15), width: 1.8),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) => _fallbackInitials(context),
                            )
                          : _fallbackInitials(context),
                    ),
                  ),
                ),

                // Corner Badge Icon
                if (badgeIcon != null)
                  Positioned(
                    bottom: 0,
                    right: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                      child: Icon(badgeIcon, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              name,
              style: TextStyle(
                color: hasUnviewed ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: hasUnviewed ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackInitials(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
