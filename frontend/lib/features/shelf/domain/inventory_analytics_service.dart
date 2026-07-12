import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum FoodAnalyticsEventType {
  eatenExpired,     // "Tummy Hurt Risk"
  thrownOutExpired, // "Food Waste"
  consumedFresh,    // Normal consumption
}

class InventoryAnalyticsEvent {
  final String id;
  final String itemId;
  final String itemName;
  final double quantity;
  final String unit;
  final FoodAnalyticsEventType eventType;
  final DateTime timestamp;

  InventoryAnalyticsEvent({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.eventType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'item_name': itemName,
        'quantity': quantity,
        'unit': unit,
        'event_type': eventType.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory InventoryAnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return InventoryAnalyticsEvent(
      id: json['id'] as String? ?? '',
      itemId: json['item_id'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      eventType: FoodAnalyticsEventType.values.firstWhere(
        (e) => e.name == (json['event_type'] as String?),
        orElse: () => FoodAnalyticsEventType.consumedFresh,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class InventoryAnalyticsService {
  static const String _prefsKey = 'inventory_analytics_events';

  /// Log food consumption or throwing out expired item
  static Future<void> logEvent({
    required String itemId,
    required String itemName,
    required double quantity,
    required String unit,
    required bool isExpired,
    required bool thrownOut,
  }) async {
    final eventType = isExpired
        ? (thrownOut
            ? FoodAnalyticsEventType.thrownOutExpired
            : FoodAnalyticsEventType.eatenExpired)
        : FoodAnalyticsEventType.consumedFresh;

    final event = InventoryAnalyticsEvent(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      itemId: itemId,
      itemName: itemName,
      quantity: quantity,
      unit: unit,
      eventType: eventType,
      timestamp: DateTime.now(),
    );

    // 1. Save locally in SharedPreferences for immediate metrics
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey) ?? [];
      list.add(jsonEncode(event.toJson()));
      await prefs.setStringList(_prefsKey, list);
    } catch (e) {
      debugPrint('Local inventory analytics save error: $e');
    }

    // 2. Sync to Supabase table if available
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('inventory_analytics').insert({
          'user_id': userId,
          'item_id': itemId,
          'item_name': itemName,
          'quantity': quantity,
          'unit': unit,
          'event_type': eventType.name,
          'is_expired': isExpired,
          'thrown_out': thrownOut,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Gracefully ignore cloud insert if table doesn't exist yet
      debugPrint('Cloud inventory analytics save info: $e');
    }
  }

  /// Retrieve all local analytics events
  static Future<List<InventoryAnalyticsEvent>> getEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey) ?? [];
      return list
          .map((s) => InventoryAnalyticsEvent.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
