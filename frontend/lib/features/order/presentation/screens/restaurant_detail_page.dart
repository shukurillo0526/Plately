// Plately — Restaurant Detail Page
// ====================================
// Full restaurant page with service-aware sections:
// - Menu (with optional highlighted item from feed)
// - Reserve a Seat (if has_reservation)
// - Location & Navigate (if has_dine_in)
// - Reviews section
//
// Navigation: from feeds (with menuItemId) or from order screen.

import 'package:flutter/material.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:plately_app/core/services/restaurant_service.dart';
import 'package:plately_app/core/services/cart_service.dart';
import 'package:plately_app/features/order/presentation/screens/checkout_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Which section to auto-scroll to when opening
enum RestaurantSection { menu, reserve, location, reviews }

class RestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;
  final RestaurantSection initialSection;
  final String? highlightMenuItemId; // from feed video

  const RestaurantDetailPage({
    super.key,
    required this.restaurant,
    this.initialSection = RestaurantSection.menu,
    this.highlightMenuItemId,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MenuItem> _menuItems = [];
  bool _loadingMenu = true;

  // Reviews (mock for now)
  final List<_Review> _reviews = [
    _Review('Sardor M.', 5, 'Best plov in town! Always fresh and generous portions.', '2 days ago'),
    _Review('Dilnoza K.', 4, 'Good food, quick service. Delivery was on time.', '1 week ago'),
    _Review('Bekzod T.', 5, 'My go-to place for lagman. Highly recommend!', '2 weeks ago'),
    _Review('Nilufar A.', 4, 'Nice atmosphere, friendly staff. Prices are fair.', '3 weeks ago'),
    _Review('Jasur R.', 3, 'Food is okay but waiting time could be better.', '1 month ago'),
  ];

  // Reservation state
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  int _guestCount = 2;

  @override
  void initState() {
    super.initState();
    _setupTabs();
    _loadMenu();
  }

  void _setupTabs() {
    final tabCount = _buildTabList().length;
    final initialIndex = _getInitialTabIndex();
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  int _getInitialTabIndex() {
    final tabs = _buildTabList();
    switch (widget.initialSection) {
      case RestaurantSection.menu:
        return 0;
      case RestaurantSection.reserve:
        return tabs.indexWhere((t) => t.key == 'reserve').clamp(0, tabs.length - 1);
      case RestaurantSection.location:
        return tabs.indexWhere((t) => t.key == 'location').clamp(0, tabs.length - 1);
      case RestaurantSection.reviews:
        return tabs.indexWhere((t) => t.key == 'reviews').clamp(0, tabs.length - 1);
    }
  }

  List<_TabInfo> _buildTabList() {
    final r = widget.restaurant;
    final tabs = <_TabInfo>[];
    if (r.hasDelivery || r.hasDineIn) {
      tabs.add(_TabInfo('menu', Icons.restaurant_menu, 'Menu'));
    }
    if (r.hasReservation) {
      tabs.add(_TabInfo('reserve', Icons.event_seat_outlined, 'Reserve'));
    }
    if (r.hasDineIn || (r.latitude != 0 && r.longitude != 0)) {
      tabs.add(_TabInfo('location', Icons.map_outlined, 'Location'));
    }
    tabs.add(_TabInfo('reviews', Icons.star_outline, 'Reviews'));
    return tabs;
  }

  Future<void> _loadMenu() async {
    final items = await RestaurantService.getMenu(widget.restaurant.id);
    if (mounted) {
      setState(() {
        _menuItems = items;
        _loadingMenu = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final r = widget.restaurant;
    final tabs = _buildTabList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          // ── App Bar ────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.6),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 40),
                      Text(_getEmoji(r), style: TextStyle(fontSize: 56)),
                      SizedBox(height: 8),
                      Text(r.name,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Text(r.cuisineLabel,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Info Header ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (r.hasDelivery) _badge('🛵 Delivery', Colors.green, isDark),
                      if (r.hasReservation) _badge('🪑 Reservation', Colors.blue, isDark),
                      if (r.hasDineIn) _badge('📍 Dine-in', Colors.teal, isDark),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                      SizedBox(width: 4),
                      Text('${r.rating}', style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15, fontWeight: FontWeight.w700,
                      )),
                      Text(' (${r.reviewCount})', style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 13,
                      )),
                      SizedBox(width: 16),
                      if (r.hasDelivery) ...[
                        Icon(Icons.schedule, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        SizedBox(width: 4),
                        Text('${r.estimatedDeliveryMinutes} min', style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13,
                        )),
                        SizedBox(width: 16),
                      ],
                      if (r.distMeters > 0) ...[
                        Icon(Icons.near_me, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        SizedBox(width: 4),
                        Text(r.distanceLabel, style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13,
                        )),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),

                  if (r.address != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(r.address!, style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12,
                          )),
                        ),
                      ],
                    ),

                  if (r.branchName != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront, size: 14, color: accent),
                          SizedBox(width: 5),
                          Text('Branch: ${r.branchName}',
                            style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],

                  if (r.storefrontUrl != null) ...[
                    SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(r.storefrontUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language, size: 16, color: accent),
                            SizedBox(width: 6),
                            Text('Visit Official Branch Website',
                              style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Icon(Icons.open_in_new, size: 13, color: accent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Tab Bar ────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: tabs.length > 3,
                labelColor: accent,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                indicatorColor: accent,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: tabs.map((t) => Tab(
                  icon: Icon(t.icon, size: 18),
                  text: t.label,
                )).toList(),
              ),
              Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: tabs.map((t) {
            switch (t.key) {
              case 'menu':
                return _MenuTab(
                  menuItems: _menuItems,
                  loading: _loadingMenu,
                  restaurant: r,
                  highlightItemId: widget.highlightMenuItemId,
                  isDark: isDark,
                );
              case 'reserve':
                return _ReserveTab(
                  restaurant: r,
                  date: _selectedDate,
                  time: _selectedTime,
                  guests: _guestCount,
                  onDateChanged: (d) => setState(() => _selectedDate = d),
                  onTimeChanged: (t) => setState(() => _selectedTime = t),
                  onGuestsChanged: (g) => setState(() => _guestCount = g),
                  isDark: isDark,
                );
              case 'location':
                return _LocationTab(restaurant: r, isDark: isDark);
              case 'reviews':
                return _ReviewsTab(reviews: _reviews, restaurant: r, isDark: isDark);
              default:
                return SizedBox.shrink();
            }
          }).toList(),
        ),
      ),
      // ── Floating Cart Bar ────────────────────────────
      bottomNavigationBar: ListenableBuilder(
        listenable: CartService(),
        builder: (context, _) {
          final cart = CartService();
          if (cart.isEmpty || cart.restaurant?.id != r.id) {
            return SizedBox.shrink();
          }
          return _CartBar(isDark: isDark);
        },
      ),
    );
  }

  Widget _badge(String text, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _getEmoji(Restaurant r) {
    final c = r.cuisineType;
    if (c.contains('Korean')) return '🥘';
    if (c.contains('Japanese') || c.contains('Sushi')) return '🍱';
    if (c.contains('Italian') || c.contains('Pizza')) return '🍕';
    if (c.contains('Fast Food') || c.contains('American')) return '🍔';
    if (c.contains('BBQ')) return '🥩';
    if (c.contains('Noodles')) return '🍜';
    return '🍛';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  _TabBarDelegate(this.tabBar, this.bgColor);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: bgColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _TabInfo {
  final String key;
  final IconData icon;
  final String label;
  const _TabInfo(this.key, this.icon, this.label);
}

// ═══════════════════════════════════════════════════════════════════
//  MENU TAB
// ═══════════════════════════════════════════════════════════════════

class _MenuTab extends StatelessWidget {
  final List<MenuItem> menuItems;
  final bool loading;
  final Restaurant restaurant;
  final String? highlightItemId;
  final bool isDark;

  const _MenuTab({
    required this.menuItems,
    required this.loading,
    required this.restaurant,
    this.highlightItemId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    if (loading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
            SizedBox(height: 12),
            Text(AppLocalizations.of(context)?.auto_menuComingSoon ?? 'Menu coming soon',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 16),
            ),
            SizedBox(height: 4),
            Text('This restaurant hasn\'t added their menu yet.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Group by category
    final categories = <String, List<MenuItem>>{};
    for (final item in menuItems) {
      final cat = item.category ?? 'Other';
      categories.putIfAbsent(cat, () => []).add(item);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // Delivery fee info
        if (restaurant.hasDelivery)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.delivery_dining, size: 16, color: accent),
                SizedBox(width: 8),
                Text(
                  restaurant.deliveryFee > 0
                      ? 'Delivery: ${restaurant.deliveryFee.round()} UZS · ~${restaurant.estimatedDeliveryMinutes} min'
                      : 'Free delivery · ~${restaurant.estimatedDeliveryMinutes} min',
                  style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

        // Menu items by category
        ...categories.entries.expand((entry) => [
          Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 0, 8),
            child: Text(entry.key,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16, fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...entry.value.map((item) {
            final isHighlighted = item.id == highlightItemId;
            return _MenuItemCard(
              item: item,
              isDark: isDark,
              isHighlighted: isHighlighted,
              hasDelivery: restaurant.hasDelivery,
              restaurant: restaurant,
            );
          }),
        ]),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final bool isDark;
  final bool isHighlighted;
  final bool hasDelivery;
  final Restaurant? restaurant;

  const _MenuItemCard({
    required this.item,
    required this.isDark,
    this.isHighlighted = false,
    required this.hasDelivery,
    this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? accent.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? accent
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: isHighlighted ? [
          BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ] : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isHighlighted)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(AppLocalizations.of(context)?.auto_fromVideo ?? 'From video', style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    if (item.tags.contains('bestseller') && !isHighlighted)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(AppLocalizations.of(context)?.auto_best ?? '🔥 Best', style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                if (item.description != null) ...[
                  SizedBox(height: 3),
                  Text(item.description!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 6),
                Row(
                  children: [
                    Text('${item.price.round()} UZS',
                      style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w700)),
                    if (item.calories != null) ...[
                      SizedBox(width: 10),
                      Text('${item.calories} cal',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (hasDelivery && restaurant != null) ...[
            SizedBox(width: 10),
            ListenableBuilder(
              listenable: CartService(),
              builder: (context, _) {
                final cart = CartService();
                final qty = cart.getQuantity(item.id);
                if (qty > 0) {
                  return Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => cart.decrementItem(item.id),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.remove, color: accent, size: 16),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('$qty',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                        GestureDetector(
                          onTap: () => cart.addItem(item, restaurant!),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.add, color: accent, size: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => cart.addItem(item, restaurant!),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add, color: accent, size: 18),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RESERVE TAB
// ═══════════════════════════════════════════════════════════════════

class _ReserveTab extends StatelessWidget {
  final Restaurant restaurant;
  final DateTime date;
  final TimeOfDay time;
  final int guests;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<int> onGuestsChanged;
  final bool isDark;

  const _ReserveTab({
    required this.restaurant,
    required this.date,
    required this.time,
    required this.guests,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onGuestsChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Colors.blue.shade700;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 80),
      children: [
        // Header
        Text(AppLocalizations.of(context)?.auto_bookATable ?? 'Book a Table',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22, fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text('Reserve your spot at ${restaurant.name}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 13),
        ),
        SizedBox(height: 24),

        // ── Date ─────────────────────────────────
        _reserveSection(
          context,
          icon: Icons.calendar_today,
          title: 'Date',
          isDark: isDark,
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) onDateChanged(picked);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: _fieldDecor(isDark, context),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: accent),
                  SizedBox(width: 10),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15, fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),

        // ── Time ─────────────────────────────────
        _reserveSection(
          context,
          icon: Icons.schedule,
          title: 'Time',
          isDark: isDark,
          child: GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) onTimeChanged(picked);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: _fieldDecor(isDark, context),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: accent),
                  SizedBox(width: 10),
                  Text(
                    time.format(context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15, fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),

        // ── Guests ───────────────────────────────
        _reserveSection(
          context,
          icon: Icons.people_outline,
          title: 'Number of Guests',
          isDark: isDark,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: _fieldDecor(isDark, context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _guestBtn(context, Icons.remove, () {
                  if (guests > 1) onGuestsChanged(guests - 1);
                }, isDark),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('$guests',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24, fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _guestBtn(context, Icons.add, () {
                  if (guests < 20) onGuestsChanged(guests + 1);
                }, isDark),
              ],
            ),
          ),
        ),
        SizedBox(height: 32),

        // ── Confirm Button ───────────────────────
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🪑 Table reserved at ${restaurant.name}\n${date.day}/${date.month} at ${time.format(context)} for $guests guests'),
              backgroundColor: accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ));
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_seat, color: Theme.of(context).colorScheme.onSurface, size: 20),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)?.auto_confirmReservation ?? 'Confirm Reservation', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reserveSection(BuildContext context, {required IconData icon, required String title, required bool isDark, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
            SizedBox(width: 6),
            Text(title, style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
              fontSize: 12, fontWeight: FontWeight.w600,
            )),
          ],
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  BoxDecoration _fieldDecor(bool isDark, BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
    );
  }

  Widget _guestBtn(BuildContext context, IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOCATION TAB
// ═══════════════════════════════════════════════════════════════════

class _LocationTab extends StatelessWidget {
  final Restaurant restaurant;
  final bool isDark;

  const _LocationTab({required this.restaurant, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = Colors.teal.shade600;
    final r = restaurant;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 80),
      children: [
        // Header
        Text(AppLocalizations.of(context)?.auto_locationDirections ?? 'Location & Directions',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22, fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 16),

        // Address card
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_on, color: accent, size: 22),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16, fontWeight: FontWeight.w700,
                        )),
                        if (r.address != null)
                          Text(r.address!, style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 13,
                          )),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  if (r.distMeters > 0) ...[
                    Icon(Icons.near_me, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                    SizedBox(width: 4),
                    Text(r.distanceLabel, style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13,
                    )),
                    SizedBox(width: 16),
                  ],
                  Text(
                    '${r.latitude.toStringAsFixed(4)}°N, ${r.longitude.toStringAsFixed(4)}°E',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                      fontSize: 11, fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Map placeholder with gradient
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map, size: 48, color: accent.withValues(alpha: 0.4)),
                SizedBox(height: 8),
                Text(AppLocalizations.of(context)?.auto_mapView ?? 'Map View', style: TextStyle(
                  color: accent.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600,
                )),
                Text('${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
                  style: TextStyle(color: accent.withValues(alpha: 0.4), fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24),

        // Navigate button
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🧭 Opening Google Maps for ${r.name}...\n${r.mapsUrl}'),
              backgroundColor: accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ));
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.teal.shade600, Colors.teal.shade400]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.navigation, color: Theme.of(context).colorScheme.onSurface, size: 20),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)?.auto_openInGoogleMaps ?? 'Open in Google Maps', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  REVIEWS TAB
// ═══════════════════════════════════════════════════════════════════

class _Review {
  final String author;
  final int stars;
  final String text;
  final String timeAgo;
  const _Review(this.author, this.stars, this.text, this.timeAgo);
}

class _ReviewsTab extends StatelessWidget {
  final List<_Review> reviews;
  final Restaurant restaurant;
  final bool isDark;

  const _ReviewsTab({required this.reviews, required this.restaurant, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 80),
      children: [
        // Rating summary
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text('${restaurant.rating}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 40, fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < restaurant.rating.round() ? Icons.star : Icons.star_border,
                      size: 16, color: Colors.amber.shade600,
                    )),
                  ),
                  SizedBox(height: 4),
                  Text('${restaurant.reviewCount} reviews',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
                  ),
                ],
              ),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    // Mock distribution
                    final pct = star == 5 ? 0.55 : star == 4 ? 0.25 : star == 3 ? 0.12 : star == 2 ? 0.05 : 0.03;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text('$star', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11)),
                          SizedBox(width: 6),
                          Icon(Icons.star, size: 10, color: Colors.amber.shade600),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: pct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade600,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Write review button
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('✍️ Write a review for ${restaurant.name}'),
              backgroundColor: accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 16, color: accent),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)?.auto_writeAReview ?? 'Write a Review', style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),

        SizedBox(height: 20),

        // Reviews list
        ...reviews.map((review) => Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(review.author[0],
                        style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review.author, style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14, fontWeight: FontWeight.w600,
                        )),
                        Row(
                          children: [
                            ...List.generate(review.stars, (_) =>
                              Icon(Icons.star, size: 12, color: Colors.amber.shade600)),
                            SizedBox(width: 6),
                            Text(review.timeAgo, style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 11,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(review.text, style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                fontSize: 13, height: 1.4,
              )),
            ],
          ),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FLOATING CART BAR
// ═══════════════════════════════════════════════════════════════════

class _CartBar extends StatelessWidget {
  final bool isDark;
  const _CartBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final cart = CartService();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${cart.itemCount}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(AppLocalizations.of(context)?.auto_viewCart ?? 'View Cart',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                Text('${cart.total.round()} UZS',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
