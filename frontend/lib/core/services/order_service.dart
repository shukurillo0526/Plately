// Plately — Order Service
// =========================
// Handles all order-related API calls and Supabase operations.
// Used by: checkout_screen.dart, order_history_screen.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/api_service.dart';

/// An order from the database.
class UserOrder {
  final String id;
  final String restaurantId;
  final String? restaurantName;
  final String type; // 'pickup' | 'delivery'
  final String status;
  final String? pickupCode;
  final List<dynamic> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final int estimatedMinutes;
  final DateTime createdAt;
  final DateTime? completedAt;

  UserOrder({
    required this.id,
    required this.restaurantId,
    this.restaurantName,
    required this.type,
    required this.status,
    this.pickupCode,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.estimatedMinutes,
    required this.createdAt,
    this.completedAt,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    return UserOrder(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      restaurantName: json['restaurant_name'] as String?,
      type: json['type'] as String? ?? 'pickup',
      status: json['status'] as String? ?? 'confirmed',
      pickupCode: json['pickup_code'] as String?,
      items: json['items'] as List<dynamic>? ?? [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 20,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  /// Human-readable status label.
  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'picked_up':
        return 'Picked Up';
      case 'delivering':
        return 'On the Way';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Whether the order is still active (not completed/cancelled).
  bool get isActive =>
      status != 'completed' && status != 'cancelled';

  /// Time since order was placed.
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Number of items in the order.
  int get itemCount =>
      items.fold(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1));
}

class OrderService {
  static final _client = Supabase.instance.client;

  /// Place a new order via the backend API.
  /// Returns the created order data including pickup code.
  static Future<Map<String, dynamic>> placeOrder({
    required String userId,
    required String restaurantId,
    String? branchId,
    required String type,
    required List<Map<String, dynamic>> items,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? customerNote,
  }) async {
    try {
      // Try backend API first (generates pickup code server-side)
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/orders');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'restaurant_id': restaurantId,
          'branch_id': branchId,
          'type': type,
          'items': items,
          'delivery_address': deliveryAddress,
          'delivery_latitude': deliveryLat,
          'delivery_longitude': deliveryLng,
          'customer_note': customerNote,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return (body['data'] as Map<String, dynamic>?) ?? body;
      }
      throw Exception('Backend returned ${response.statusCode}');
    } catch (e) {
      debugPrint('[OrderService] Backend order failed, using Supabase: $e');
      // Fallback: direct Supabase insert
      final result = await _client.from('orders').insert({
        'user_id': userId,
        'restaurant_id': restaurantId,
        'branch_id': branchId,
        'type': type,
        'status': 'confirmed',
        'items': items,
        'subtotal': items.fold(0.0, (sum, i) =>
            sum + ((i['price'] as num? ?? 0) * (i['quantity'] as num? ?? 1))),
        'delivery_fee': 0,
        'total': items.fold(0.0, (sum, i) =>
            sum + ((i['price'] as num? ?? 0) * (i['quantity'] as num? ?? 1))),
        'estimated_minutes': 20,
        'delivery_address': deliveryAddress,
        'customer_note': customerNote,
      }).select().single();
      return result;
    }
  }

  /// Get user's order history (newest first).
  static Future<List<UserOrder>> getUserOrders(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Try RPC first (includes restaurant name)
      try {
        final data = await _client.rpc('get_user_orders', params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        });
        return (data as List<dynamic>)
            .map((json) => UserOrder.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // RPC not available
      }

      // Fallback: direct query
      final data = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List<dynamic>)
          .map((json) => UserOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user's active (non-completed) orders.
  static Future<List<UserOrder>> getActiveOrders(String userId) async {
    try {
      final data = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .not('status', 'in', '("completed","cancelled")')
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((json) => UserOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Cancel an order.
  static Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _client
          .from('orders')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'cancel_reason': reason,
          })
          .eq('id', orderId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
