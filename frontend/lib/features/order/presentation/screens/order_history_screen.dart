// Plately — Order History Screen
// =================================
// Shows user's past and active orders with status tracking.
// Accessible from the Profile/Manage tab.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:plately_app/core/services/order_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<UserOrder> _orders = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _subscribeToOrderUpdates();
  }

  @override
  void dispose() {
    _orderSubscription?.unsubscribe();
    super.dispose();
  }

  void _subscribeToOrderUpdates() {
    try {
      final userId = currentUserId();
      if (userId.isEmpty) return;

      _orderSubscription = Supabase.instance.client
          .channel('user_orders_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (mounted) {
                _loadOrders();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[OrderHistory] Realtime subscription error: $e');
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = currentUserId();
      final orders = await OrderService.getUserOrders(userId);
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load orders';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.auto_myOrders ?? 'My Orders',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _error != null
              ? _buildError(isDark)
              : _orders.isEmpty
                  ? _buildEmpty(isDark)
                  : _buildOrderList(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
          SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                  fontSize: 16)),
          SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadOrders,
            icon: Icon(Icons.refresh, size: 18),
            label: Text(AppLocalizations.of(context)?.auto_retry ?? 'Retry'),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)?.auto_noOrdersYet ?? 'No orders yet',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text(AppLocalizations.of(context)?.auto_yourOrderHistoryWillAppearHere ?? 'Your order history will appear here',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildOrderList(bool isDark) {
    // Separate active and past orders
    final active = _orders.where((o) => o.isActive).toList();
    final past = _orders.where((o) => !o.isActive).toList();

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // ── Active Orders ─────────────────────────────
          if (active.isNotEmpty) ...[
            _sectionHeader('Active Orders', '${active.length}', isDark),
            SizedBox(height: 8),
            ...active.map((o) => _OrderCard(
                  order: o,
                  isDark: isDark,
                  onCancel: () => _cancelOrder(o),
                  isActive: true,
                )),
            SizedBox(height: 24),
          ],

          // ── Past Orders ───────────────────────────────
          if (past.isNotEmpty) ...[
            _sectionHeader('Past Orders', '${past.length}', isDark),
            SizedBox(height: 8),
            ...past.map((o) => _OrderCard(
                  order: o,
                  isDark: isDark,
                  isActive: false,
                )),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String count, bool isDark) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(count,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Future<void> _cancelOrder(UserOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)?.auto_cancelOrder ?? 'Cancel Order?'),
        content: Text(
            'Cancel your order from ${order.restaurantName ?? "this restaurant"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)?.auto_keepOrder ?? 'Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)?.auto_cancelOrder ?? 'Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await OrderService.cancelOrder(order.id);
      if (success && mounted) {
        _loadOrders();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)?.auto_orderCancelled ?? 'Order cancelled'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ORDER CARD
// ═══════════════════════════════════════════════════════════════════

class _OrderCard extends StatelessWidget {
  final UserOrder order;
  final bool isDark;
  final bool isActive;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.order,
    required this.isDark,
    required this.isActive,
    this.onCancel,
  });



  @override
  Widget build(BuildContext context) {
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Restaurant + Status ──────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  order.type == 'delivery'
                      ? Icons.delivery_dining
                      : Icons.shopping_bag_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName ?? 'Restaurant',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${order.itemCount} items · ${order.timeAgo}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: order.status, isDark: isDark),
            ],
          ),

          // ── Status Progress (for active orders) ─────
          if (isActive) ...[
            SizedBox(height: 16),
            _StatusProgress(status: order.status, type: order.type),
          ],

          // ── Pickup Code (if pickup and active) ──────
          if (isActive &&
              order.type == 'pickup' &&
              order.pickupCode != null) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)?.auto_pickupCode ?? 'Pickup Code: ',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                          fontSize: 13)),
                  Text(order.pickupCode!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3)),
                ],
              ),
            ),
          ],

          SizedBox(height: 12),

          // ── Footer: Total + Cancel ──────────────────
          Row(
            children: [
              Text('${order.total.round()} UZS',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              SizedBox(width: 8),
              Text(
                order.type == 'delivery' ? '· Delivery' : '· Pickup',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                    fontSize: 12),
              ),
              Spacer(),
              if (isActive && onCancel != null)
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(AppLocalizations.of(context)?.auto_cancel ?? 'Cancel',
                        style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATUS CHIP
// ═══════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusChip({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      'confirmed' => (Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), Theme.of(context).colorScheme.primary),
      'preparing' => (Colors.blue.withValues(alpha: 0.12), Colors.blue),
      'ready' => (Colors.green.withValues(alpha: 0.12), Colors.green),
      'picked_up' || 'delivering' => (Colors.purple.withValues(alpha: 0.12), Colors.purple),
      'completed' => (Colors.green.withValues(alpha: 0.08), Colors.green.withValues(alpha: 0.6)),
      'cancelled' => (Colors.red.withValues(alpha: 0.08), Colors.red.withValues(alpha: 0.6)),
      _ => (Colors.grey.withValues(alpha: 0.1), Colors.grey),
    };

    final label = switch (status) {
      'confirmed' => 'Confirmed',
      'preparing' => 'Preparing',
      'ready' => 'Ready',
      'picked_up' => 'Picked Up',
      'delivering' => 'On the Way',
      'completed' => 'Done',
      'cancelled' => 'Cancelled',
      _ => status,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATUS PROGRESS BAR
// ═══════════════════════════════════════════════════════════════════

class _StatusProgress extends StatelessWidget {
  final String status;
  final String type;

  const _StatusProgress({required this.status, required this.type});



  @override
  Widget build(BuildContext context) {
    final steps = type == 'delivery'
        ? ['Confirmed', 'Preparing', 'Ready', 'Delivering', 'Done']
        : ['Confirmed', 'Preparing', 'Ready', 'Done'];

    final currentStep = switch (status) {
      'confirmed' => 0,
      'preparing' => 1,
      'ready' => 2,
      'picked_up' || 'delivering' => 3,
      'completed' => steps.length - 1,
      _ => 0,
    };

    return Row(
      children: List.generate(steps.length, (i) {
        final isCompleted = i <= currentStep;
        final isLast = i == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
