// Plately — Story Service
// ==========================
// Handles story CRUD, restaurant stories from Workshop,
// interactive action stickers (Order, Cook, Tip), and expiry logic.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plately_app/core/services/auth_helper.dart';

/// A single story item with interactive food action metadata.
class StoryItem {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final bool isViewed;

  // ── Workshop & Action Sticker Extensions ──
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantLogo;
  final String? recipeId;
  final String? recipeTitle;
  final String storyActionType; // 'order' | 'cook' | 'tip' | 'none'
  final String? actionLabel;
  final String? actionPayload;

  StoryItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.isViewed = false,
    this.restaurantId,
    this.restaurantName,
    this.restaurantLogo,
    this.recipeId,
    this.recipeTitle,
    this.storyActionType = 'none',
    this.actionLabel,
    this.actionPayload,
  });

  bool get isRestaurantStory => restaurantId != null && restaurantId!.isNotEmpty;
  bool get hasAction => storyActionType != 'none';
}

/// A group of stories from one entity (Restaurant Kitchen, Creator Chef, or Diner).
class StoryGroup {
  final String groupId;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final List<StoryItem> stories;
  final bool hasUnviewed;
  final bool isOwn;
  final bool isRestaurant;
  final String badgeType; // 'restaurant' | 'executive_chef' | 'home_cook'

  StoryGroup({
    String? groupId,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.stories,
    required this.hasUnviewed,
    this.isOwn = false,
    this.isRestaurant = false,
    this.badgeType = 'home_cook',
  }) : groupId = groupId ?? userId;
}

class StoryService {
  static final _client = Supabase.instance.client;
  static final _picker = ImagePicker();

  /// Get all active stories grouped by entity.
  /// Ordering: Own stories -> Live restaurant specials -> Unviewed creator/friends -> Viewed.
  static Future<List<StoryGroup>> getStoryGroups() async {
    try {
      final uid = currentUserId();

      // Fetch active (non-expired) stories
      final data = await _client
          .from('stories')
          .select('*, users!stories_author_id_fkey(display_name, avatar_url)')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      final stories = List<Map<String, dynamic>>.from(data);

      // Get viewed story IDs for current user
      final viewedData = await _client
          .from('story_views')
          .select('story_id')
          .eq('viewer_id', uid);
      final viewedIds = Set<String>.from(
        (viewedData as List).map((v) => v['story_id'] as String),
      );

      // Fetch restaurant metadata for linked stories
      final restaurantIds = stories
          .map((s) => s['restaurant_id'] as String?)
          .whereType<String>()
          .toSet();

      final Map<String, Map<String, dynamic>> restaurantMap = {};
      if (restaurantIds.isNotEmpty) {
        try {
          final restData = await _client
              .from('restaurants')
              .select('id, name, logo_url_hi_res, image_url')
              .filter('id', 'in', restaurantIds.toList());
          for (final r in (restData as List)) {
            restaurantMap[r['id'] as String] = r as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('[Story] Failed to fetch linked restaurants: $e');
        }
      }

      // Group stories by entity (restaurant_id if present, otherwise author_id)
      final Map<String, List<StoryItem>> grouped = {};
      final Map<String, Map<String, dynamic>> entityInfo = {};

      for (final s in stories) {
        final storyId = s['id'] as String;
        final authorId = s['author_id'] as String? ?? 'unknown';
        final user = s['users'] as Map<String, dynamic>?;
        final restId = s['restaurant_id'] as String?;

        final isRest = restId != null && restId.isNotEmpty;
        final groupKey = isRest ? 'rest_$restId' : 'user_$authorId';

        String entityName = isRest
            ? (restaurantMap[restId]?['name'] ?? 'Restaurant Partner')
            : (user?['display_name'] ?? 'Plately Cook');
        String? entityAvatar = isRest
            ? (restaurantMap[restId]?['logo_url_hi_res'] ?? restaurantMap[restId]?['image_url'])
            : (user?['avatar_url'] as String?);

        // Determine action type
        String actionType = 'none';
        String? actionLabel;
        if (isRest) {
          actionType = 'order';
          actionLabel = 'Order Today\'s Special';
        } else if (s['recipe_id'] != null) {
          actionType = 'cook';
          actionLabel = 'Cook This Recipe';
        }

        entityInfo[groupKey] = {
          'id': isRest ? restId : authorId,
          'name': entityName,
          'avatar': entityAvatar,
          'isRestaurant': isRest,
        };

        grouped.putIfAbsent(groupKey, () => []);
        grouped[groupKey]!.add(StoryItem(
          id: storyId,
          authorId: authorId,
          authorName: entityName,
          authorAvatar: entityAvatar,
          mediaUrl: s['media_url'] as String? ?? '',
          mediaType: s['media_type'] as String? ?? 'image',
          caption: s['caption'] as String?,
          createdAt: DateTime.tryParse(s['created_at'] as String? ?? '') ?? DateTime.now(),
          expiresAt: DateTime.tryParse(s['expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(hours: 24)),
          isViewed: viewedIds.contains(storyId),
          restaurantId: restId,
          restaurantName: isRest ? entityName : null,
          restaurantLogo: isRest ? entityAvatar : null,
          recipeId: s['recipe_id'] as String?,
          storyActionType: actionType,
          actionLabel: actionLabel,
        ));
      }

      // Build groups
      final groups = <StoryGroup>[];
      for (final entry in grouped.entries) {
        final key = entry.key;
        final items = entry.value;
        final info = entityInfo[key]!;
        final hasUnviewed = items.any((s) => !s.isViewed);
        final isOwn = !info['isRestaurant'] && info['id'] == uid;

        groups.add(StoryGroup(
          groupId: key,
          userId: info['id'] as String,
          userName: info['name'] as String,
          avatarUrl: info['avatar'] as String?,
          stories: items,
          hasUnviewed: hasUnviewed,
          isOwn: isOwn,
          isRestaurant: info['isRestaurant'] as bool,
          badgeType: info['isRestaurant'] as bool ? 'restaurant' : 'home_cook',
        ));
      }

      // Sort: Own first -> Restaurants with live specials -> Unviewed -> Recent
      groups.sort((a, b) {
        if (a.isOwn) return -1;
        if (b.isOwn) return 1;
        if (a.isRestaurant && !b.isRestaurant) return -1;
        if (!a.isRestaurant && b.isRestaurant) return 1;
        if (a.hasUnviewed && !b.hasUnviewed) return -1;
        if (!a.hasUnviewed && b.hasUnviewed) return 1;
        return b.stories.first.createdAt.compareTo(a.stories.first.createdAt);
      });

      // If database is empty (brand new install / staging), provide vibrant showcase stories
      if (groups.isEmpty) {
        return _getDemoShowcaseStories(uid);
      }

      return groups;
    } catch (e) {
      debugPrint('[Story] getStoryGroups error: $e');
      return _getDemoShowcaseStories(currentUserId());
    }
  }

  /// Create a new story.
  static Future<bool> createStory({
    required String mediaUrl,
    String mediaType = 'image',
    String? caption,
    String? restaurantId,
    String? recipeId,
  }) async {
    try {
      final insertData = <String, dynamic>{
        'author_id': currentUserId(),
        'media_url': mediaUrl,
        'media_type': mediaType,
        'caption': caption,
      };
      if (restaurantId != null) insertData['restaurant_id'] = restaurantId;
      if (recipeId != null) insertData['recipe_id'] = recipeId;

      await _client.from('stories').insert(insertData);
      return true;
    } catch (e) {
      debugPrint('[Story] createStory error: $e');
      return false;
    }
  }

  /// Mark a story as viewed.
  static Future<void> markViewed(String storyId) async {
    try {
      final uid = currentUserId();
      if (uid.isEmpty) return;
      await _client.from('story_views').upsert({
        'story_id': storyId,
        'viewer_id': uid,
      });
    } catch (e) {
      debugPrint('[Story] markViewed error: $e');
    }
  }

  /// Upload story media (image from camera/gallery).
  static Future<String?> uploadStoryMedia(XFile file) async {
    try {
      final uid = currentUserId();
      final ext = file.path.split('.').last;
      final path = 'stories/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await _client.storage
            .from('post-media')
            .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: 'image/$ext'));
      } else {
        await _client.storage
            .from('post-media')
            .upload(path, File(file.path));
      }

      return _client.storage.from('post-media').getPublicUrl(path);
    } catch (e) {
      debugPrint('[Story] uploadStoryMedia error: $e');
      return null;
    }
  }

  /// Pick image for story.
  static Future<XFile?> pickStoryImage({ImageSource source = ImageSource.camera}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('[Story] pickStoryImage error: $e');
      return null;
    }
  }

  /// Delete own story.
  static Future<void> deleteStory(String storyId) async {
    try {
      await _client.from('stories').delete().eq('id', storyId);
    } catch (e) {
      debugPrint('[Story] deleteStory error: $e');
    }
  }

  /// Fallback demo showcase stories demonstrating restaurant specials and executive recipes.
  static List<StoryGroup> _getDemoShowcaseStories(String currentUid) {
    final now = DateTime.now();
    return [
      StoryGroup(
        groupId: 'rest_kamolon',
        userId: 'demo_kamolon_chef',
        userName: 'Kamolon Osh Markazi',
        avatarUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200',
        isRestaurant: true,
        hasUnviewed: true,
        badgeType: 'restaurant',
        stories: [
          StoryItem(
            id: 'demo_story_1',
            authorId: 'demo_kamolon_chef',
            authorName: 'Kamolon Osh Markazi',
            authorAvatar: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200',
            mediaUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=900',
            caption: '🔥 Fresh Chust Plov fresh out of the kazan! Lunch discount: 20% off until 2:30 PM.',
            createdAt: now.subtract(const Duration(hours: 2)),
            expiresAt: now.add(const Duration(hours: 10)),
            restaurantId: 'demo-rest-kamolon',
            restaurantName: 'Kamolon Osh Markazi',
            storyActionType: 'order',
            actionLabel: 'Order Lunch Special • 38,000 UZS',
            actionPayload: 'kamolon-plov',
          ),
          StoryItem(
            id: 'demo_story_2',
            authorId: 'demo_kamolon_chef',
            authorName: 'Kamolon Osh Markazi',
            authorAvatar: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200',
            mediaUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=900',
            caption: 'Crispy tandem somsa batch just baked! Golden crust & succulent lamb filling.',
            createdAt: now.subtract(const Duration(hours: 1)),
            expiresAt: now.add(const Duration(hours: 11)),
            restaurantId: 'demo-rest-kamolon',
            restaurantName: 'Kamolon Osh Markazi',
            storyActionType: 'order',
            actionLabel: 'Order Tandir Somsa • 12,000 UZS',
            actionPayload: 'tandir-somsa',
          ),
        ],
      ),
      StoryGroup(
        groupId: 'chef_aziza',
        userId: 'demo_chef_aziza',
        userName: 'Chef Aziza',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        isRestaurant: false,
        hasUnviewed: true,
        badgeType: 'executive_chef',
        stories: [
          StoryItem(
            id: 'demo_story_3',
            authorId: 'demo_chef_aziza',
            authorName: 'Chef Aziza',
            authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
            mediaUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=900',
            caption: '🥗 Zero-waste Green Garden Bowl cooked in 15 mins using pantry ingredients!',
            createdAt: now.subtract(const Duration(hours: 3)),
            expiresAt: now.add(const Duration(hours: 21)),
            recipeId: 'demo-recipe-green-bowl',
            recipeTitle: 'Green Garden Bowl',
            storyActionType: 'cook',
            actionLabel: 'Cook This Recipe • 90% Pantry Match',
          ),
        ],
      ),
      StoryGroup(
        groupId: 'cook_bekzod',
        userId: 'demo_cook_bekzod',
        userName: 'Bekzod K.',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        isRestaurant: false,
        hasUnviewed: false,
        badgeType: 'home_cook',
        stories: [
          StoryItem(
            id: 'demo_story_4',
            authorId: 'demo_cook_bekzod',
            authorName: 'Bekzod K.',
            authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
            mediaUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=900',
            caption: 'First time making Lagman noodles by hand! Thanks to Plately timers!',
            createdAt: now.subtract(const Duration(hours: 5)),
            expiresAt: now.add(const Duration(hours: 19)),
            recipeId: 'demo-recipe-lagman',
            recipeTitle: 'Hand-pulled Lagman',
            storyActionType: 'cook',
            actionLabel: 'View Recipe',
            isViewed: true,
          ),
        ],
      ),
    ];
  }
}
