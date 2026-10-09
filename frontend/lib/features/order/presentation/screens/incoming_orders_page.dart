// Plately — Incoming Orders Page (Restaurant Side)
// ====================================================
// Order management for restaurant owners.
// Shows incoming, preparing, and ready orders with status controls.
// Restaurant can advance order status: confirmed → preparing → ready → completed.

import 'package:flutter/material.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomingOrdersPage extends StatefulWidget {
  final String restaurantId;

  const IncomingOrdersPage({super.key, required this.restaurantId});

  @override
  State<IncomingOrdersPage> createState() => _IncomingOrdersPageState();
}

class _IncomingOrdersPageState extends State<IncomingOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('restaurant_id', widget.restaurantId)
          .not('status', 'in', '("completed","cancelled")')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      final update = <String, dynamic>{'status': newStatus};
      final now = DateTime.now().toIso8601String();
      if (newStatus == 'ready') update['ready_at'] = now;
      if (newStatus == 'completed') update['completed_at'] = now;

      await Supabase.instance.client
          .from('orders')
          .update(update)
          .eq('id', orderId);

      _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order updated to: ${_statusLabel(newStatus)}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'confirmed' => 'New',
      'preparing' => 'Preparing',
      'ready' => 'Ready',
      'completed' => 'Done',
      'cancelled' => 'Cancelled',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = _orders.where((o) => o['status'] == 'confirmed').toList();
    final preparing = _orders.where((o) => o['status'] == 'preparing').toList();
    final ready = _orders.where((o) => o['status'] == 'ready').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.auto_incomingOrders ?? 'Incoming Orders',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'New (${confirmed.length})'),
            Tab(text: 'Preparing (${preparing.length})'),
            Tab(text: 'Ready (${ready.length})'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(confirmed, 'confirmed'),
                _buildOrderList(preparing, 'preparing'),
                _buildOrderList(ready, 'ready'),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, String status) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
            SizedBox(height: 12),
            Text('No ${_statusLabel(status).toLowerCase()} orders',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(orders[index], status),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String currentStatus) {
    final items = order['items'] as List<dynamic>? ?? [];
    final type = order['type'] as String? ?? 'pickup';
    final pickupCode = order['pickup_code'] as String?;
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final createdAt = DateTime.tryParse(order['created_at']?.toString() ?? '');
    final timeAgo = createdAt != null
        ? _formatTimeAgo(DateTime.now().difference(createdAt))
        : '';
    final note = order['customer_note'] as String?;

    // Determine next status action
    final (String? nextStatus, String nextLabel, IconData nextIcon, Color nextColor) =
        switch (currentStatus) {
      'confirmed' => ('preparing', 'Start Preparing', Icons.restaurant, Colors.blue),
      'preparing' => ('ready', 'Mark Ready', Icons.check_circle, Colors.green),
      'ready' => ('completed', 'Complete', Icons.done_all, Theme.of(context).colorScheme.primary),
      _ => (null, '', Icons.check, Colors.grey),
    };

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (type == 'delivery' ? Colors.purple : Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  type == 'delivery'
                      ? Icons.delivery_dining
                      : Icons.shopping_bag_outlined,
                  color: type == 'delivery' ? Colors.purple : Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (pickupCode != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(pickupCode,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2)),
                          ),
                          SizedBox(width: 8),
                        ],
                        Text(
                          type == 'delivery' ? 'Delivery' : 'Pickup',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(timeAgo,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            fontSize: 11)),
                  ],
                ),
              ),
              Text('${total.round()} UZS',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),

          SizedBox(height: 12),

          // ── Items List ─────────────────────────────
          ...items.map((item) {
            final name = item['name'] ?? 'Item';
            final qty = item['quantity'] ?? 1;
            final special = item['special_instructions'];
            return Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('$qty',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$name',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                fontSize: 13)),
                        if (special != null && special.toString().isNotEmpty)
                          Text('$special',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Customer Note ──────────────────────────
          if (note != null && note.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 14,
                      color: Colors.amber.withValues(alpha: 0.6)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(note,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          // ── Action Button ──────────────────────────
          if (nextStatus != null) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => _updateStatus(order['id'], nextStatus),
                icon: Icon(nextIcon, size: 18),
                label: Text(nextLabel,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: nextColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(Duration diff) {
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
