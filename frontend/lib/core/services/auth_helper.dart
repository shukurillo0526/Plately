// Plately — Auth Helper
// =====================
// Centralized user ID resolution and profile initialization.
// No fallback UUID — guests use Supabase anonymous auth.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/services/location_service.dart';

/// Returns the current authenticated user's UUID.
/// Throws if called without an auth session (should never happen
/// because the app gates on auth before showing main screens).
String currentUserId() {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    throw StateError('currentUserId() called without an auth session');
  }
  return user.id;
}

/// Returns true if a user is currently signed in (not anonymous guest).
bool isAuthenticated() {
  final session = Supabase.instance.client.auth.currentSession;
  return session != null;
}

/// Returns true if the current user is an anonymous guest.
bool isAnonymousGuest() {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.isAnonymous ?? true;
}

/// Returns the display name from Supabase auth metadata, or 'Chef'.
String currentUserName() {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.userMetadata?['full_name'] as String? ??
      user?.userMetadata?['name'] as String? ??
      user?.email?.split('@').first ??
      'Chef';
}

/// Returns the avatar URL from Supabase auth metadata, or null.
String? currentUserAvatar() {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.userMetadata?['avatar_url'] as String? ??
      user?.userMetadata?['picture'] as String?;
}

/// Ensures the user's profile rows exist in the database.
/// Should be called once after sign-in / sign-up.
/// Idempotent — safe to call multiple times.
/// Also auto-detects location using LocationService if not already set.
Future<void> ensureUserInitialized() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  try {
    final api = ApiService();
    await api.initUser(
      userId: user.id,
      email: user.email ?? '${user.id}@anon.plately.local',
      displayName: user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?,
    );
    api.dispose();
  } catch (e) {
    debugPrint('ensureUserInitialized failed: $e');
    // Non-fatal — profile screen has fallback handling
  }

  // Auto-detect location silently (non-blocking)
  _autoDetectLocation(user.id);
}

/// Auto-detect and store the user's location if not already set.
Future<void> _autoDetectLocation(String userId) async {
  try {
    final client = Supabase.instance.client;
    final existing = await client
        .from('users')
        .select('location')
        .eq('id', userId)
        .maybeSingle();

    // Only set if location is null/empty
    if (existing != null && (existing['location'] == null || existing['location'] == '')) {
      // Use LocationService which is already initialized in main()
      final locationService = LocationService();
      final city = locationService.locality;
      if (city.isNotEmpty) {
        await client.from('users').update({
          'location': city,
        }).eq('id', userId);
        debugPrint('[AuthHelper] Auto-detected location: $city');
      }
    }
  } catch (e) {
    debugPrint('[AuthHelper] Location auto-detect failed (non-fatal): $e');
  }
}

