import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/services/cache_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  Plately — Riverpod Providers
//  Centralized state management for shared data across screens.
//
//  Strategy:
//    - Cache-first: show cached data instantly, refresh in background
//    - Shared: inventory loaded once, used by Shelf, Cook, Scan
//    - Reactive: UI updates automatically when state changes
// ═══════════════════════════════════════════════════════════════════

/// Current authenticated user ID
final currentUserIdProvider = Provider<String>((ref) {
  return Supabase.instance.client.auth.currentUser?.id ?? '';
});

/// API service singleton
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Cache service singleton
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

// ── Inventory ───────────────────────────────────────────────────

/// Inventory state — cached, shared across Shelf/Cook/Scan
final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<Map<String, dynamic>>>(
  InventoryNotifier.new,
);

class InventoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId.isEmpty) return [];

    final cache = ref.read(cacheServiceProvider);

    // 1. Return cache immediately if available
    final cached = cache.getInventory(userId);
    if (cached != null && !cache.isInventoryStale(userId)) {
      return cached;
    }

    // 2. Fetch from network
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('inventory')
          .select('*, ingredients(name, category, emoji)')
          .eq('user_id', userId)
          .order('expiry_date', ascending: true);

      final items = List<Map<String, dynamic>>.from(response);

      // 3. Update cache
      await cache.setInventory(userId, items);
      return items;
    } catch (e) {
      // 4. Fall back to stale cache if network fails
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Force refresh from network
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Add an item (optimistic update)
  Future<void> addItem(Map<String, dynamic> item) async {
    final current = state.value ?? [];
    state = AsyncValue.data([...current, item]);
    // Network sync happens through the existing add-item API
  }

  /// Remove an item
  Future<void> removeItem(String inventoryId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.where((i) => i['id'] != inventoryId).toList(),
    );
  }
}

// ── User Profile ────────────────────────────────────────────────

/// User profile (flavor, gamification, preferences)
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, Map<String, dynamic>>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId.isEmpty) return {};

    final cache = ref.read(cacheServiceProvider);
    final api = ref.read(apiServiceProvider);

    // Check cache first
    final cached = cache.getProfile(userId);

    try {
      final result = await api.getUserDashboard(userId: userId);
      final profile = result['data'] as Map<String, dynamic>? ?? {};
      await cache.setProfile(userId, profile);
      return profile;
    } catch (e) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// ── Recipes / Recommendations ───────────────────────────────────

/// Recommendations provider — 6-signal scoring results
final recommendationsProvider =
    AsyncNotifierProvider<RecommendationsNotifier, Map<String, dynamic>>(
  RecommendationsNotifier.new,
);

class RecommendationsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId.isEmpty) return {};

    final api = ref.read(apiServiceProvider);
    final cache = ref.read(cacheServiceProvider);

    // Check cache
    final cached = cache.getRecipes(userId);

    try {
      final result = await api.getRecommendations(userId: userId);
      final data = result['data'] as Map<String, dynamic>? ?? {};
      return data;
    } catch (e) {
      // Fall back to cached
      if (cached != null) return {'cached': true, 'recipes': cached};
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// ── Shopping List ───────────────────────────────────────────────

/// Local shopping list state (synced with API when possible)
final shoppingListProvider =
    NotifierProvider<ShoppingListNotifier, List<Map<String, String>>>(
  ShoppingListNotifier.new,
);

class ShoppingListNotifier extends Notifier<List<Map<String, String>>> {
  @override
  List<Map<String, String>> build() => [];

  void addItem(String name, {String category = 'Other'}) {
    // Avoid duplicates
    if (state.any((i) => i['name']?.toLowerCase() == name.toLowerCase())) return;
    state = [...state, {'name': name, 'category': category, 'checked': 'false'}];
  }

  void removeItem(String name) {
    state = state.where((i) => i['name'] != name).toList();
  }

  void toggleItem(String name) {
    state = state.map((i) {
      if (i['name'] == name) {
        return {...i, 'checked': i['checked'] == 'true' ? 'false' : 'true'};
      }
      return i;
    }).toList();
  }

  void clearChecked() {
    state = state.where((i) => i['checked'] != 'true').toList();
  }

  void clearAll() {
    state = [];
  }
}

// ── Connectivity ────────────────────────────────────────────────

/// Whether the device is currently online
final isOnlineProvider = NotifierProvider<IsOnlineNotifier, bool>(
  IsOnlineNotifier.new,
);

class IsOnlineNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(cacheServiceProvider).isOnline;
  }

  void setOnline(bool value) {
    state = value;
  }
}
