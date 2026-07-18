// Plately — Inventory Repository
// =================================
// Centralized data access layer for inventory operations.
// Reads: direct Supabase (RLS-protected, anon key is fine).
// Writes: routed through backend API (service role bypasses RLS).

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/services/analytics_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';

class InventoryRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final ApiService _api = ApiService();

  RealtimeChannel? _channel;

  // ── Reads (direct Supabase — RLS ensures user isolation) ───

  /// Load all inventory items for the current user.
  Future<List<Map<String, dynamic>>> loadInventory() async {
    final data = await _client
        .from('inventory_items')
        .select('*, ingredients(display_name_en, display_name_ko, display_name_uz, display_name_uz_cyrl, display_name_ru, category)')
        .eq('user_id', currentUserId())
        .order('computed_expiry', ascending: true);

    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Subscribe to real-time inventory changes for the current user.
  void subscribeRealtime(void Function() onChanged) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('inventory_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'inventory_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId(),
          ),
          callback: (_) => onChanged(),
        )
        .subscribe();
  }

  /// Dispose the realtime subscription.
  void disposeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }

  // ── Writes (through backend API — bypasses RLS) ────────────

  /// Add a new item to inventory.
  Future<Map<String, dynamic>> addItem({
    required String ingredientName,
    String category = 'Pantry',
    double quantity = 1.0,
    String unit = 'pcs',
    String location = 'Fridge',
    String? expiryDate,
  }) async {
    final result = await _api.addInventoryItem(
      userId: currentUserId(),
      ingredientName: ingredientName,
      category: category,
      quantity: quantity,
      unit: unit,
      location: location,
      expiryDate: expiryDate,
    );
    
    // Instrument analytics
    AnalyticsService.logEvent('shelf_item_added', {
      'ingredient_name': ingredientName,
      'source': 'unknown', // can be passed through if needed
    });

    return result;
  }

  /// Update an inventory item's properties.
  Future<Map<String, dynamic>> updateItem({
    required String itemId,
    double? quantity,
    String? unit,
    String? itemState,
    String? location,
    String? notes,
  }) async {
    return await _api.updateInventoryItem(
      itemId: itemId,
      quantity: quantity,
      unit: unit,
      itemState: itemState,
      location: location,
      notes: notes,
    );
  }

  /// Delete an inventory item.
  Future<Map<String, dynamic>> deleteItem(String itemId) async {
    return await _api.deleteInventoryItem(itemId);
  }

  /// Consume (decrement) an inventory item's quantity.
  Future<Map<String, dynamic>> consumeItem({
    required String inventoryId,
    required double quantityToConsume,
  }) async {
    return await _api.consumeInventoryItem(
      inventoryId: inventoryId,
      quantityToConsume: quantityToConsume,
    );
  }

  void dispose() {
    disposeRealtime();
    _api.dispose();
  }
}
