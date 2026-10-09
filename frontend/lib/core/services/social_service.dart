// Plately — Social Service
// ===========================
// Central service for social interactions:
// - Follow / Unfollow
// - Like / Unlike posts
// - Comments (CRUD + threading)
// - Post creation with media upload
// - Social counts (followers, following, likes)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plately_app/core/services/auth_helper.dart';

class SocialService {
  static final _client = Supabase.instance.client;
  static final _picker = ImagePicker();

  // ═══════════════════════════════════════════════════════════
  //  FOLLOW SYSTEM
  // ═══════════════════════════════════════════════════════════

  /// Check if current user follows [targetUserId].
  static Future<bool> isFollowing(String targetUserId) async {
    try {
      final uid = currentUserId();
      final res = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', uid)
          .eq('following_id', targetUserId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint('[Social] isFollowing error: $e');
      return false;
    }
  }

  /// Follow a user.
  static Future<void> follow(String targetUserId) async {
    try {
      final uid = currentUserId();
      await _client.from('follows').insert({
        'follower_id': uid,
        'following_id': targetUserId,
      });
    } catch (e) {
      debugPrint('[Social] follow error: $e');
    }
  }

  /// Unfollow a user.
  static Future<void> unfollow(String targetUserId) async {
    try {
      final uid = currentUserId();
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', uid)
          .eq('following_id', targetUserId);
    } catch (e) {
      debugPrint('[Social] unfollow error: $e');
    }
  }

  /// Get follower count for a user.
  static Future<int> getFollowerCount(String userId) async {
    try {
      final res = await _client.rpc('get_follower_count', params: {'target_user_id': userId});
      return (res as int?) ?? 0;
    } catch (e) {
      debugPrint('[Social] getFollowerCount error: $e');
      return 0;
    }
  }

  /// Get following count for a user.
  static Future<int> getFollowingCount(String userId) async {
    try {
      final res = await _client.rpc('get_following_count', params: {'target_user_id': userId});
      return (res as int?) ?? 0;
    } catch (e) {
      debugPrint('[Social] getFollowingCount error: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  LIKES
  // ═══════════════════════════════════════════════════════════

  /// Check if current user has liked a post.
  static Future<bool> hasLiked(String postId) async {
    try {
      final uid = currentUserId();
      final res = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', uid)
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint('[Social] hasLiked error: $e');
      return false;
    }
  }

  /// Like a post.
  static Future<void> likePost(String postId) async {
    try {
      final uid = currentUserId();
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': uid,
      });
      // Increment denormalized count
      await _client.rpc('increment_field', params: {
        'table_name': 'posts',
        'field_name': 'like_count',
        'row_id': postId,
      }).catchError((_) {});
    } catch (e) {
      debugPrint('[Social] likePost error: $e');
    }
  }

  /// Unlike a post.
  static Future<void> unlikePost(String postId) async {
    try {
      final uid = currentUserId();
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
      // Decrement denormalized count
      await _client.rpc('decrement_field', params: {
        'table_name': 'posts',
        'field_name': 'like_count',
        'row_id': postId,
      }).catchError((_) {});
    } catch (e) {
      debugPrint('[Social] unlikePost error: $e');
    }
  }

  /// Get like count for a post.
  static Future<int> getLikeCount(String postId) async {
    try {
      final res = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId);
      return (res as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  COMMENTS
  // ═══════════════════════════════════════════════════════════

  /// Get comments for a post (with author info).
  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final data = await _client
          .from('post_comments')
          .select('*, users!post_comments_author_id_fkey(display_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[Social] getComments error: $e');
      return [];
    }
  }

  /// Add a comment to a post.
  static Future<Map<String, dynamic>?> addComment(
    String postId,
    String body, {
    String? parentCommentId,
  }) async {
    try {
      final uid = currentUserId();
      final res = await _client.from('post_comments').insert({
        'post_id': postId,
        'author_id': uid,
        'body': body,
        'parent_comment_id': ?parentCommentId,
      }).select('*, users!post_comments_author_id_fkey(display_name, avatar_url)').single();
      // Increment comment count
      await _client.rpc('increment_field', params: {
        'table_name': 'posts',
        'field_name': 'comment_count',
        'row_id': postId,
      }).catchError((_) {});
      return res;
    } catch (e) {
      debugPrint('[Social] addComment error: $e');
      return null;
    }
  }

  /// Delete a comment.
  static Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _client.from('post_comments').delete().eq('id', commentId);
      await _client.rpc('decrement_field', params: {
        'table_name': 'posts',
        'field_name': 'comment_count',
        'row_id': postId,
      }).catchError((_) {});
    } catch (e) {
      debugPrint('[Social] deleteComment error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  MEDIA UPLOAD
  // ═══════════════════════════════════════════════════════════

  /// Pick an image from camera or gallery.
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('[Social] pickImage error: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery.
  static Future<List<XFile>> pickMultipleImages() async {
    try {
      return await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('[Social] pickMultipleImages error: $e');
      return [];
    }
  }

  /// Upload a media file to Supabase Storage.
  /// Returns the public URL of the uploaded file.
  static Future<String?> uploadMedia(XFile file) async {
    try {
      final uid = currentUserId();
      final ext = file.path.split('.').last;
      final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

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
      debugPrint('[Social] uploadMedia error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  POST CREATION
  // ═══════════════════════════════════════════════════════════

  /// Create a new community post.
  static Future<Map<String, dynamic>?> createPost({
    required String caption,
    required String postType,    // 'photo', 'restaurant_visit', 'food_tip', 'reel'
    List<String> mediaUrls = const [],
    List<String> tags = const [],
    String? locationName,
    double? locationLat,
    double? locationLng,
    String? recipeId,
    String? restaurantId,
    String visibility = 'public',
  }) async {
    try {
      final uid = currentUserId();
      final res = await _client.from('posts').insert({
        'author_id': uid,
        'caption': caption,
        'post_type': postType,
        'media_urls': mediaUrls,
        'tags': tags,
        'location_name': locationName,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'recipe_id': recipeId,
        'restaurant_id': restaurantId,
        'visibility': visibility,
        'like_count': 0,
        'view_count': 0,
        'comment_count': 0,
      }).select().single();
      return res;
    } catch (e) {
      debugPrint('[Social] createPost error: $e');
      return null;
    }
  }

  /// Get community feed posts (friends first, then public).
  static Future<List<Map<String, dynamic>>> getCommunityFeed({int limit = 30}) async {
    try {
      // Get posts — friends' posts + public posts, most recent first
      final data = await _client
          .from('posts')
          .select('*, users!posts_author_id_fkey(display_name, avatar_url)')
          .inFilter('post_type', ['photo', 'restaurant_visit', 'food_tip', 'recipe'])
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[Social] getCommunityFeed error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BOOKMARKS
  // ═══════════════════════════════════════════════════════════

  /// Bookmark a post.
  static Future<void> bookmarkPost(String postId) async {
    try {
      final uid = currentUserId();
      await _client.from('post_bookmarks').insert({
        'post_id': postId,
        'user_id': uid,
      });
    } catch (e) {
      debugPrint('[Social] bookmark error: $e');
    }
  }

  /// Remove bookmark.
  static Future<void> unbookmarkPost(String postId) async {
    try {
      final uid = currentUserId();
      await _client
          .from('post_bookmarks')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    } catch (e) {
      debugPrint('[Social] unbookmark error: $e');
    }
  }

  /// Check if post is bookmarked.
  static Future<bool> isBookmarked(String postId) async {
    try {
      final uid = currentUserId();
      final res = await _client
          .from('post_bookmarks')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', uid)
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }
}
