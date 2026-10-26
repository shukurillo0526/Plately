import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plately_app/core/services/api_service.dart' show ApiConfig;
import 'dart:async';

/// Offline-first caching service with Hive storage and SharedPreferences fallback.
///
/// Strategy:
///   1. Show cached data instantly on screen load
///   2. Fetch fresh data from network in background
///   3. Update cache + UI when fresh data arrives
///   4. Queue writes when offline → flush on reconnect
///   5. Graceful fallback to SharedPreferences if Hive fails (private mode, quota)
///
/// Boxes / Key spaces:
///   - 'inventory' — user's inventory items
///   - 'recipes' — recipe list with match data
///   - 'user_profile' — user profile, flavor, gamification
///   - 'sync_queue' — pending writes to flush when online
///   - 'local_recipes' — user-created or AI generated offline recipes
class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  bool _initialized = false;
  bool _hiveAvailable = false;

  Box? _inventoryBox;
  Box? _recipesBox;
  Box? _profileBox;
  Box? _syncQueueBox;
  Box? _metaBox;
  Box? _localRecipesBox;

  SharedPreferences? _prefs;

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChange => _connectivityController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Initialize Hive and SharedPreferences fallback.
  /// Call this once in main() before runApp().
  Future<void> initialize() async {
    if (_initialized) return;

    // Always initialize SharedPreferences as dependable fallback
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[Cache] SharedPreferences init error: $e');
    }

    try {
      await Hive.initFlutter();

      _inventoryBox = await Hive.openBox('inventory');
      _recipesBox = await Hive.openBox('recipes');
      _profileBox = await Hive.openBox('user_profile');
      _syncQueueBox = await Hive.openBox('sync_queue');
      _metaBox = await Hive.openBox('cache_meta');
      _localRecipesBox = await Hive.openBox('local_recipes');

      _hiveAvailable = true;
      debugPrint(
        '[Cache] Hive initialized — ${_inventoryBox?.length ?? 0} inventory, '
        '${_recipesBox?.length ?? 0} recipes, ${_localRecipesBox?.length ?? 0} local recipes cached',
      );
    } catch (e) {
      _hiveAvailable = false;
      debugPrint('[Cache] Hive storage unavailable (falling back to SharedPreferences): $e');
    }

    _initialized = true;

    // Monitor connectivity
    try {
      Connectivity().onConnectivityChanged.listen((results) {
        final wasOffline = !_isOnline;
        _isOnline = results.any((r) => r != ConnectivityResult.none);
        _connectivityController.add(_isOnline);

        if (wasOffline && _isOnline) {
          debugPrint('[Cache] Back online — flushing sync queue');
          flushSyncQueue();
        }
      });

      // Check initial connectivity
      final result = await Connectivity().checkConnectivity();
      _isOnline = result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('[Cache] Connectivity listener init error: $e');
    }
  }

  // ── Inventory Cache ────────────────────────────────────────────

  /// Get cached inventory items for a user with optional TTL.
  List<Map<String, dynamic>>? getInventory(String userId, {Duration? maxAge}) {
    if (maxAge != null && isInventoryStale(userId, maxAge: maxAge)) {
      return null;
    }

    String? raw;
    if (_hiveAvailable && _inventoryBox != null) {
      raw = _inventoryBox!.get('inventory_$userId') as String?;
    } else {
      raw = _prefs?.getString('cache_inventory_$userId');
    }

    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[Cache] Error decoding inventory: $e');
      return null;
    }
  }

  /// Cache inventory items.
  Future<void> setInventory(String userId, List<dynamic> items) async {
    final encoded = jsonEncode(items);
    final nowIso = DateTime.now().toIso8601String();

    if (_hiveAvailable && _inventoryBox != null && _metaBox != null) {
      await _inventoryBox!.put('inventory_$userId', encoded);
      await _metaBox!.put('inventory_${userId}_ts', nowIso);
    } else if (_prefs != null) {
      await _prefs!.setString('cache_inventory_$userId', encoded);
      await _prefs!.setString('cache_meta_inventory_${userId}_ts', nowIso);
    }
  }

  /// Check if inventory cache is stale (older than maxAge).
  bool isInventoryStale(String userId, {Duration maxAge = const Duration(minutes: 5)}) {
    String? ts;
    if (_hiveAvailable && _metaBox != null) {
      ts = _metaBox!.get('inventory_${userId}_ts') as String?;
    } else {
      ts = _prefs?.getString('cache_meta_inventory_${userId}_ts');
    }

    if (ts == null) return true;
    final cached = DateTime.tryParse(ts);
    if (cached == null) return true;
    return DateTime.now().difference(cached) > maxAge;
  }

  // ── Recipes Cache ─────────────────────────────────────────────

  /// Get cached recipes.
  List<Map<String, dynamic>>? getRecipes(String userId, {Duration? maxAge}) {
    if (maxAge != null && isRecipesStale(userId, maxAge: maxAge)) {
      return null;
    }

    String? raw;
    if (_hiveAvailable && _recipesBox != null) {
      raw = _recipesBox!.get('recipes_$userId') as String?;
    } else {
      raw = _prefs?.getString('cache_recipes_$userId');
    }

    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[Cache] Error decoding recipes: $e');
      return null;
    }
  }

  /// Cache recipes.
  Future<void> setRecipes(String userId, List<dynamic> recipes) async {
    final encoded = jsonEncode(recipes);
    final nowIso = DateTime.now().toIso8601String();

    if (_hiveAvailable && _recipesBox != null && _metaBox != null) {
      await _recipesBox!.put('recipes_$userId', encoded);
      await _metaBox!.put('recipes_${userId}_ts', nowIso);
    } else if (_prefs != null) {
      await _prefs!.setString('cache_recipes_$userId', encoded);
      await _prefs!.setString('cache_meta_recipes_${userId}_ts', nowIso);
    }
  }

  bool isRecipesStale(String userId, {Duration maxAge = const Duration(minutes: 15)}) {
    String? ts;
    if (_hiveAvailable && _metaBox != null) {
      ts = _metaBox!.get('recipes_${userId}_ts') as String?;
    } else {
      ts = _prefs?.getString('cache_meta_recipes_${userId}_ts');
    }

    if (ts == null) return true;
    final cached = DateTime.tryParse(ts);
    if (cached == null) return true;
    return DateTime.now().difference(cached) > maxAge;
  }

  // ── User Profile Cache ────────────────────────────────────────

  /// Get cached user profile.
  Map<String, dynamic>? getProfile(String userId) {
    String? raw;
    if (_hiveAvailable && _profileBox != null) {
      raw = _profileBox!.get('profile_$userId') as String?;
    } else {
      raw = _prefs?.getString('cache_profile_$userId');
    }

    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Cache] Error decoding profile: $e');
      return null;
    }
  }

  /// Cache user profile.
  Future<void> setProfile(String userId, Map<String, dynamic> profile) async {
    final encoded = jsonEncode(profile);
    if (_hiveAvailable && _profileBox != null) {
      await _profileBox!.put('profile_$userId', encoded);
    } else if (_prefs != null) {
      await _prefs!.setString('cache_profile_$userId', encoded);
    }
  }

  // ── Offline Write Queue ───────────────────────────────────────

  /// Queue a write operation for later sync.
  Future<void> queueWrite({
    required String endpoint,
    required String method,
    required Map<String, dynamic> body,
  }) async {
    final queue = _getQueue();
    queue.add({
      'endpoint': endpoint,
      'method': method,
      'body': body,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await _saveQueue(queue);
    debugPrint('[Cache] Queued offline write: $method $endpoint');
  }

  /// Get the number of pending sync operations.
  int get pendingSyncCount => _getQueue().length;

  /// Flush all queued writes to the server.
  Future<void> flushSyncQueue() async {
    final queue = _getQueue();
    if (queue.isEmpty) return;

    debugPrint('[Cache] Flushing ${queue.length} queued writes...');
    final failed = <Map<String, dynamic>>[];

    for (final item in queue) {
      try {
        final endpoint = item['endpoint'] as String;
        final method = item['method'] as String;
        final body = item['body'] as Map<String, dynamic>;
        final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
        final headers = {'Content-Type': 'application/json'};
        final jsonBody = jsonEncode(body);
        debugPrint('[Cache] Syncing: $method $endpoint');

        http.Response response;
        if (method == 'POST') {
          response = await http.post(url, headers: headers, body: jsonBody);
        } else if (method == 'PUT') {
          response = await http.put(url, headers: headers, body: jsonBody);
        } else if (method == 'PATCH') {
          response = await http.patch(url, headers: headers, body: jsonBody);
        } else if (method == 'DELETE') {
          response = await http.delete(url, headers: headers);
        } else {
          continue;
        }

        if (response.statusCode >= 400) {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('[Cache] Sync failed: $e');
        failed.add(item);
      }
    }

    await _saveQueue(failed);
    debugPrint('[Cache] Flush complete — ${failed.length} remaining');
  }

  List<Map<String, dynamic>> _getQueue() {
    String? raw;
    if (_hiveAvailable && _syncQueueBox != null) {
      raw = _syncQueueBox!.get('queue') as String?;
    } else {
      raw = _prefs?.getString('cache_sync_queue');
    }

    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    final encoded = jsonEncode(queue);
    if (_hiveAvailable && _syncQueueBox != null) {
      await _syncQueueBox!.put('queue', encoded);
    } else if (_prefs != null) {
      await _prefs!.setString('cache_sync_queue', encoded);
    }
  }

  // ── Cache Management ──────────────────────────────────────────

  /// Clear all cached data (e.g., on logout).
  Future<void> clearAll() async {
    if (_hiveAvailable) {
      await _inventoryBox?.clear();
      await _recipesBox?.clear();
      await _profileBox?.clear();
      await _syncQueueBox?.clear();
      await _metaBox?.clear();
    }
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((k) => k.startsWith('cache_') && !k.startsWith('cache_local_recipes_')).toList();
      for (final k in keys) {
        await _prefs!.remove(k);
      }
    }
    debugPrint('[Cache] All transient caches cleared');
  }

  // ── Local Recipes (Imported/AI-generated) ──────────────────────

  /// Save a recipe to local-only storage.
  String saveLocalRecipe(String userId, Map<String, dynamic> recipe) {
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    recipe['local_id'] = id;
    recipe['user_id'] = userId;
    recipe['created_at'] = DateTime.now().toIso8601String();
    recipe['is_local'] = true;
    final encoded = jsonEncode(recipe);

    if (_hiveAvailable && _localRecipesBox != null) {
      _localRecipesBox!.put(id, encoded);
    } else if (_prefs != null) {
      _prefs!.setString('cache_local_recipes_$id', encoded);
      final indexKey = 'cache_local_recipe_ids_$userId';
      final ids = _prefs!.getStringList(indexKey) ?? [];
      if (!ids.contains(id)) {
        ids.add(id);
        _prefs!.setStringList(indexKey, ids);
      }
    }
    debugPrint('[Cache] Saved local recipe: ${recipe['title']} ($id)');
    return id;
  }

  /// Get all local recipes for a user.
  List<Map<String, dynamic>> getLocalRecipes(String userId) {
    final results = <Map<String, dynamic>>[];

    if (_hiveAvailable && _localRecipesBox != null) {
      for (final key in _localRecipesBox!.keys) {
        final raw = _localRecipesBox!.get(key);
        if (raw == null) continue;
        try {
          final recipe = jsonDecode(raw as String) as Map<String, dynamic>;
          if (recipe['user_id'] == userId) {
            results.add(recipe);
          }
        } catch (_) {}
      }
    } else if (_prefs != null) {
      final ids = _prefs!.getStringList('cache_local_recipe_ids_$userId') ?? [];
      for (final id in ids) {
        final raw = _prefs!.getString('cache_local_recipes_$id');
        if (raw == null) continue;
        try {
          final recipe = jsonDecode(raw) as Map<String, dynamic>;
          results.add(recipe);
        } catch (_) {}
      }
    }

    results.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    return results;
  }

  /// Delete a local recipe by its local ID.
  Future<void> deleteLocalRecipe(String localId) async {
    if (_hiveAvailable && _localRecipesBox != null) {
      await _localRecipesBox!.delete(localId);
    }
    if (_prefs != null) {
      await _prefs!.remove('cache_local_recipes_$localId');
      // Clean up index lists
      for (final key in _prefs!.getKeys().where((k) => k.startsWith('cache_local_recipe_ids_'))) {
        final ids = _prefs!.getStringList(key);
        if (ids != null && ids.contains(localId)) {
          ids.remove(localId);
          await _prefs!.setStringList(key, ids);
        }
      }
    }
    debugPrint('[Cache] Deleted local recipe: $localId');
  }

  /// Get count of local recipes for a user.
  int localRecipeCount(String userId) {
    return getLocalRecipes(userId).length;
  }

  /// Safe cache statistics for debugging.
  Map<String, dynamic> get stats => {
    'storage_backend': _hiveAvailable ? 'Hive' : 'SharedPreferences',
    'inventory_entries': _inventoryBox?.length ?? 0,
    'recipes_entries': _recipesBox?.length ?? 0,
    'profiles_entries': _profileBox?.length ?? 0,
    'pending_syncs': pendingSyncCount,
    'is_online': _isOnline,
  };
}
