// Plately — Cart Service
// ========================
// In-memory shopping cart for restaurant ordering.
// Singleton pattern ensures cart persists across screens.
// Binds to a single restaurant — clears if user switches.

import 'package:flutter/foundation.dart';
import 'package:plately_app/core/services/restaurant_service.dart';

/// A single item in the cart with quantity.
class CartItem {
  final MenuItem menuItem;
  int quantity;
  String? specialInstructions;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get subtotal => menuItem.price * quantity;

  CartItem copyWith({int? quantity, String? specialInstructions}) {
    return CartItem(
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

/// Order type: pickup or delivery.
enum OrderType { pickup, delivery }

/// Cart service — singleton, notifies listeners on changes.
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // ── State ──────────────────────────────────────────
  Restaurant? _restaurant;
  final List<CartItem> _items = [];
  OrderType _orderType = OrderType.pickup;

  // ── Getters ────────────────────────────────────────
  Restaurant? get restaurant => _restaurant;
  List<CartItem> get items => List.unmodifiable(_items);
  OrderType get orderType => _orderType;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Total price of all items in cart.
  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Delivery fee (only if delivery type).
  double get deliveryFee =>
      _orderType == OrderType.delivery ? (_restaurant?.deliveryFee ?? 0) : 0;

  /// Grand total including delivery fee.
  double get total => subtotal + deliveryFee;

  /// Estimated time (prep + delivery if applicable).
  int get estimatedMinutes {
    final prep = _restaurant?.avgPrepMinutes ?? 20;
    if (_orderType == OrderType.delivery) {
      return _restaurant?.estimatedDeliveryMinutes ?? (prep + 15);
    }
    return prep;
  }

  // ── Actions ────────────────────────────────────────

  /// Add an item to the cart. If from a different restaurant, clear first.
  void addItem(MenuItem item, Restaurant restaurant) {
    // If switching restaurants, clear the cart
    if (_restaurant != null && _restaurant!.id != restaurant.id) {
      _items.clear();
    }
    _restaurant = restaurant;

    // Check if item already in cart
    final existingIndex =
        _items.indexWhere((ci) => ci.menuItem.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(menuItem: item));
    }
    notifyListeners();
  }

  /// Remove one quantity of an item. Removes entirely if quantity reaches 0.
  void decrementItem(String menuItemId) {
    final index = _items.indexWhere((ci) => ci.menuItem.id == menuItemId);
    if (index < 0) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
      if (_items.isEmpty) _restaurant = null;
    }
    notifyListeners();
  }

  /// Remove an item entirely from the cart.
  void removeItem(String menuItemId) {
    _items.removeWhere((ci) => ci.menuItem.id == menuItemId);
    if (_items.isEmpty) _restaurant = null;
    notifyListeners();
  }

  /// Update quantity directly.
  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }
    final index = _items.indexWhere((ci) => ci.menuItem.id == menuItemId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  /// Update special instructions for an item.
  void updateInstructions(String menuItemId, String? instructions) {
    final index = _items.indexWhere((ci) => ci.menuItem.id == menuItemId);
    if (index >= 0) {
      _items[index].specialInstructions = instructions;
      notifyListeners();
    }
  }

  /// Set the order type (pickup or delivery).
  void setOrderType(OrderType type) {
    _orderType = type;
    notifyListeners();
  }

  /// Get the quantity of a specific menu item in the cart.
  int getQuantity(String menuItemId) {
    final index = _items.indexWhere((ci) => ci.menuItem.id == menuItemId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  /// Clear the entire cart.
  void clear() {
    _items.clear();
    _restaurant = null;
    _orderType = OrderType.pickup;
    notifyListeners();
  }

  /// Convert cart to JSON for order submission.
  Map<String, dynamic> toOrderJson(String userId) {
    return {
      'user_id': userId,
      'restaurant_id': _restaurant?.id,
      'branch_id': _restaurant?.branchId,
      'type': _orderType == OrderType.pickup ? 'pickup' : 'delivery',
      'items': _items.map((ci) => {
        'menu_item_id': ci.menuItem.id,
        'name': ci.menuItem.name,
        'price': ci.menuItem.price,
        'quantity': ci.quantity,
        'special_instructions': ci.specialInstructions,
        'subtotal': ci.subtotal,
      }).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'estimated_minutes': estimatedMinutes,
    };
  }
}
