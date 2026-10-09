// Plately — Order Screen (Geo-Filtered)
// ========================================
// Karrot-style hyperlocal food ordering with:
// - GPS-based region detection and neighborhood display
// - Configurable radius (1km, 2km, 5km, 10km)
// - Real-time restaurant list from Supabase PostGIS
// - UberEats/Baemin-inspired UI with delivery time, ratings, prices
// - Category filtering, search, and deals section

import 'package:flutter/material.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:plately_app/core/services/location_service.dart';
import 'package:plately_app/core/services/restaurant_service.dart';
import 'package:plately_app/core/widgets/region_picker_sheet.dart';
import 'package:plately_app/features/order/presentation/screens/restaurant_detail_page.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final LocationService _location = LocationService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<Restaurant> _restaurants = [];
  bool _loading = true;
  String? _searchQuery;

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': '🍽️'},
    {'label': 'Uzbek', 'icon': '🍚'},
    {'label': 'Korean', 'icon': '🇰🇷'},
    {'label': 'Healthy', 'icon': '🥗'},
    {'label': 'Fast Food', 'icon': '🍔'},
    {'label': 'Japanese', 'icon': '🍱'},
    {'label': 'Indian', 'icon': '🫓'},
    {'label': 'Italian', 'icon': '🍕'},
    {'label': 'Desserts', 'icon': '🍰'},
    {'label': 'BBQ', 'icon': '🥩'},
  ];

  @override
  void initState() {
    super.initState();
    _location.addListener(_onLocationChanged);
    _initLocation();
  }

  @override
  void dispose() {
    _location.removeListener(_onLocationChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted) {
      _loadRestaurants();
    }
  }

  Future<void> _initLocation() async {
    await _location.init();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    if (!_location.hasLocation) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    final cuisineFilter = _selectedCategory == 'All'
        ? null
        : [_selectedCategory];

    final restaurants = await RestaurantService.getNearbyRestaurants(
      lat: _location.latitude,
      lng: _location.longitude,
      radius: _location.radiusMeters,
      cuisineFilter: cuisineFilter,
    );

    // If PostGIS RPC returned empty (tables not yet created), use fallback
    if (restaurants.isEmpty) {
      final fallback = await RestaurantService.getAllRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = fallback;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _restaurants = restaurants;
        _loading = false;
      });
    }
  }

  List<Restaurant> get _filteredRestaurants {
    var list = _restaurants;
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final q = _searchQuery!.toLowerCase();
      list = list.where((r) =>
        r.name.toLowerCase().contains(q) ||
        r.cuisineLabel.toLowerCase().contains(q) ||
        r.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }
    return list;
  }

  List<Restaurant> get _dealRestaurants {
    return _filteredRestaurants.where((r) =>
      r.tags.contains('budget') || r.deliveryFee == 0
    ).take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: accent,
          onRefresh: () async {
            await _location.refreshLocation();
            await _loadRestaurants();
          },
          child: CustomScrollView(
            slivers: [
              // ── Location Header ────────────────────────
              SliverToBoxAdapter(
                child: _LocationHeader(
                  location: _location,
                  isDark: isDark,
                  accent: accent,
                  onRadiusChanged: (r) {
                    _location.setRadius(r);
                    _loadRestaurants();
                  },
                  onRegionChanged: () => _loadRestaurants(),
                ),
              ),

              // ── Search Bar ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search restaurants, dishes...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        prefixIcon: Icon(Icons.search,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        suffixIcon: _searchQuery?.isNotEmpty == true
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = null);
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Category Chips ─────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat['label'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat['label'] as String);
                          _loadRestaurants();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? accent : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? accent :
                                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat['icon'] as String, style: TextStyle(fontSize: 14)),
                              SizedBox(width: 6),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Loading / Error / Empty States ─────────
              if (_loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                  ),
                )
              else if (!_location.hasLocation && _restaurants.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(
                    icon: Icons.location_off,
                    title: 'Location Required',
                    subtitle: 'Enable location to discover nearby restaurants',
                    action: 'Enable Location',
                    onAction: () => _location.refreshLocation(),
                    isDark: isDark,
                  ),
                )
              else if (_filteredRestaurants.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(
                    icon: Icons.restaurant_outlined,
                    title: 'No Restaurants Found',
                    subtitle: 'Try increasing your radius or changing the category',
                    isDark: isDark,
                  ),
                )
              else ...[
                // ── Deals Section ──────────────────────────
                if (_dealRestaurants.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      emoji: '🔥',
                      title: 'Deals Near You',
                      isDark: isDark,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 165,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _dealRestaurants.length,
                        separatorBuilder: (_, _) => SizedBox(width: 12),
                        itemBuilder: (ctx, i) => _DealCard(
                          restaurant: _dealRestaurants[i],
                          isDark: isDark,
                          accent: accent,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],

                // ── Popular Near You ───────────────────────
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    emoji: '⭐',
                    title: 'Popular Near You',
                    subtitle: '${_filteredRestaurants.length} restaurants within ${_location.radiusLabel}',
                    isDark: isDark,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── Top-Rated Items (horizontal scroll) ────
                SliverToBoxAdapter(
                  child: _PopularItemsSection(
                    restaurants: _filteredRestaurants,
                    isDark: isDark,
                    accent: accent,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Restaurant List ────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _RestaurantTile(
                      restaurant: _filteredRestaurants[i],
                      isDark: isDark,
                      accent: accent,
                      onTap: () => _openRestaurant(context, _filteredRestaurants[i]),
                    ),
                    childCount: _filteredRestaurants.length,
                  ),
                ),
              ],

              // Bottom padding for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  void _openRestaurant(BuildContext context, Restaurant restaurant) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => RestaurantDetailPage(restaurant: restaurant),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WIDGETS
// ═══════════════════════════════════════════════════════════════════

// ── Location Header with Region + Radius ────────────────────────

class _LocationHeader extends StatelessWidget {
  final LocationService location;
  final bool isDark;
  final Color accent;
  final ValueChanged<int> onRadiusChanged;
  final VoidCallback? onRegionChanged;

  const _LocationHeader({
    required this.location,
    required this.isDark,
    required this.accent,
    required this.onRadiusChanged,
    this.onRegionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          // Location icon with pulse
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: accent, size: 20),
          ),
          SizedBox(width: 10),
          // Region name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        location.regionName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        location.radiusLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (location.locality.isNotEmpty)
                  Text(
                    location.locality,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Map button (Karrot-style region picker)
          GestureDetector(
            onTap: () => _showRegionPicker(context),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(Icons.map_outlined, color: accent, size: 20),
            ),
          ),
          SizedBox(width: 8),
          // Radius settings button
          GestureDetector(
            onTap: () => _showRadiusPicker(context),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(Icons.tune, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showRadiusPicker(BuildContext context) {
    final radiusOptions = [1000, 2000, 5000, 10000];
    final labels = ['1 km', '2 km', '5 km', '10 km'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.radar, color: accent, size: 22),
                SizedBox(width: 8),
                Text(
                  'Search Radius',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Show restaurants within this distance',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                fontSize: 13,
              ),
            ),
            SizedBox(height: 20),
            ...List.generate(radiusOptions.length, (i) {
              final isSelected = location.radiusMeters == radiusOptions[i];
              return GestureDetector(
                onTap: () {
                  onRadiusChanged(radiusOptions[i]);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? accent.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? accent : (Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? accent : (Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        size: 20,
                      ),
                      SizedBox(width: 14),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: isSelected ? accent : (Theme.of(context).colorScheme.onSurface),
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      if (isSelected)
                        Icon(Icons.check_circle, color: accent, size: 20),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showRegionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RegionPickerSheet(
        location: location,
        onRegionChanged: onRegionChanged,
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final bool isDark;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $title',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Deal Card (horizontal scroll) ───────────────────────────────

class _DealCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isDark;
  final Color accent;

  const _DealCard({
    required this.restaurant,
    required this.isDark,
    required this.accent,
  });

  // Cuisine → emoji mapping
  static const _cuisineEmojis = {
    'Uzbek': '🍚', 'Korean': '🥘', 'Japanese': '🍱', 'Indian': '🫓',
    'Italian': '🍕', 'Mexican': '🌮', 'Healthy': '🥗', 'Fast Food': '🍔',
    'BBQ': '🥩', 'Chinese': '🥟', 'Mediterranean': '🫒', 'Desserts': '🍰',
    'European': '☕', 'Café': '☕', 'Salads': '🥗', 'Vegan': '🌱',
    'Dumplings': '🥟', 'Noodles': '🍜', 'Pizza': '🍕', 'Sushi': '🍣',
    'Ice Cream': '🍨', 'Street Food': '🌮', 'Traditional': '🍛',
    'Regional': '🍛', 'Home Food': '🍲', 'American': '🍔', 'Asian': '🍜',
    'Middle Eastern': '🧆', 'Halal': '🌙',
  };

  String get _emoji {
    for (final c in restaurant.cuisineType) {
      if (_cuisineEmojis.containsKey(c)) return _cuisineEmojis[c]!;
    }
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_emoji, style: TextStyle(fontSize: 28)),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  restaurant.priceLabel,
                  style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            restaurant.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            restaurant.cuisineLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
              fontSize: 12,
            ),
            maxLines: 1,
          ),
          Spacer(),
          Row(
            children: [
              Icon(Icons.star, size: 13, color: Colors.amber.shade600),
              SizedBox(width: 3),
              Text('${restaurant.rating}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.schedule, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              SizedBox(width: 3),
              Text('${restaurant.estimatedDeliveryMinutes}min',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11)),
              Spacer(),
              Text(restaurant.distMeters > 0 ? restaurant.distanceLabel : '',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Restaurant Tile (vertical list) ─────────────────────────────

class _RestaurantTile extends StatelessWidget {
  final Restaurant restaurant;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _RestaurantTile({
    required this.restaurant,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  String get _emoji {
    return _DealCard._cuisineEmojis[restaurant.cuisineType.firstOrNull] ?? '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(_emoji, style: TextStyle(fontSize: 26))),
            ),
            SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!restaurant.isOpen)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(AppLocalizations.of(context)?.auto_closed ?? 'Closed', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  if (restaurant.branchName != null) ...[
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.storefront, size: 11, color: accent),
                        SizedBox(width: 3),
                        Text(
                          'Branch: ${restaurant.branchName}',
                          style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 3),
                  Text(
                    restaurant.cuisineLabel,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
                  ),
                  SizedBox(height: 6),
                  // Stats row
                  Row(
                    children: [
                      Icon(Icons.star, size: 13, color: Colors.amber.shade600),
                      SizedBox(width: 2),
                      Text('${restaurant.rating}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(' (${restaurant.reviewCount})',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 11)),
                      SizedBox(width: 10),
                      Icon(Icons.schedule, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                      SizedBox(width: 3),
                      Text('${restaurant.estimatedDeliveryMinutes} min',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11)),
                      SizedBox(width: 10),
                      Text(restaurant.priceLabel,
                          style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (restaurant.storefrontUrl != null) ...[
                    SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(restaurant.storefrontUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language, size: 12, color: accent),
                            SizedBox(width: 4),
                            Text('Branch Website', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700)),
                            SizedBox(width: 3),
                            Icon(Icons.open_in_new, size: 10, color: accent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8),
            // Distance + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (restaurant.distMeters > 0)
                  Text(
                    restaurant.distanceLabel,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                SizedBox(height: 4),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Restaurant Menu Sheet ───────────────────────────────────────

class _RestaurantMenuSheet extends StatefulWidget {
  final Restaurant restaurant;
  const _RestaurantMenuSheet({required this.restaurant});

  @override
  State<_RestaurantMenuSheet> createState() => _RestaurantMenuSheetState();
}

class _RestaurantMenuSheetState extends State<_RestaurantMenuSheet> {
  List<MenuItem> _menuItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final items = await RestaurantService.getMenu(widget.restaurant.id);
    if (mounted) {
      setState(() {
        _menuItems = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final r = widget.restaurant;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Restaurant header
              Text(r.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text(r.cuisineLabel, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 14)),
              SizedBox(height: 8),

              // ── Service badges ─────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (r.hasDelivery)
                    _ServiceBadge(icon: Icons.delivery_dining, label: 'Delivery', color: Colors.green),
                  if (r.hasReservation)
                    _ServiceBadge(icon: Icons.event_seat, label: 'Reservation', color: Colors.blue),
                  if (r.hasDineIn)
                    _ServiceBadge(icon: Icons.restaurant, label: 'Dine-in', color: Colors.orange),
                ],
              ),

              SizedBox(height: 12),
              // Stats row
              Row(
                children: [
                  _StatChip(icon: Icons.star, label: '${r.rating}', color: Colors.amber.shade600),
                  SizedBox(width: 8),
                  _StatChip(icon: Icons.schedule, label: '${r.estimatedDeliveryMinutes} min', color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                  SizedBox(width: 8),
                  if (r.hasDelivery)
                    _StatChip(icon: Icons.delivery_dining, label: r.deliveryFee > 0 ? '${r.deliveryFee.round()} UZS' : 'Free', color: accent),
                  if (r.distMeters > 0) ...[
                    SizedBox(width: 8),
                    _StatChip(icon: Icons.near_me, label: r.distanceLabel, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                  ],
                ],
              ),
              SizedBox(height: 20),
              if (r.address != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(r.address!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 13)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
              // Menu
              Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
              SizedBox(height: 12),
              Text(AppLocalizations.of(context)?.auto_menu ?? 'Menu', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 12),
              if (_loading)
                Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: accent),
                ))
              else if (_menuItems.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(AppLocalizations.of(context)?.auto_menuComingSoon ?? 'Menu coming soon', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                  ),
                )
              else
                ..._menuItems.map((item) => _MenuItemTile(item: item, isDark: isDark, accent: accent)),
              SizedBox(height: 20),

              // ── Smart Action Buttons ───────────────
              _SmartActionBar(restaurant: r, isDark: isDark, accent: accent),
            ],
          ),
        );
      },
    );
  }
}

// ── Service Badge ───────────────────────────────────────────────

class _ServiceBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ServiceBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Smart Action Bar (context-aware buttons) ────────────────────

class _SmartActionBar extends StatelessWidget {
  final Restaurant restaurant;
  final bool isDark;
  final Color accent;
  const _SmartActionBar({required this.restaurant, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final actions = <Widget>[];

    // 1. Order (delivery)
    if (r.hasDelivery) {
      actions.add(_buildActionButton(
        context: context,
        icon: Icons.shopping_bag_outlined,
        label: 'Order',
        gradient: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
        onTap: () => _handleOrder(context, r),
        isPrimary: true,
      ));
    }

    // 2. Reserve a seat
    if (r.hasReservation) {
      actions.add(_buildActionButton(
        context: context,
        icon: Icons.event_seat_outlined,
        label: 'Reserve',
        gradient: [Colors.blue.shade700, Colors.blue.shade400],
        onTap: () => _handleReserve(context, r),
        isPrimary: !r.hasDelivery,
      ));
    }

    // 3. Show on Map / Navigate
    if (r.hasDineIn) {
      actions.add(_buildActionButton(
        context: context,
        icon: Icons.map_outlined,
        label: 'Map',
        gradient: [Colors.teal.shade600, Colors.teal.shade400],
        onTap: () => _handleMap(context, r),
        isPrimary: !r.hasDelivery && !r.hasReservation,
      ));
    }

    // 4. External navigation (always available if we have coordinates)
    if (r.latitude != 0 && r.longitude != 0) {
      actions.add(_buildActionButton(
        context: context,
        icon: Icons.navigation_outlined,
        label: 'Navigate',
        gradient: null,
        onTap: () => _handleNavigate(context, r),
        isPrimary: false,
      ));
    }

    if (actions.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap in rows of max 2 for clean layout
        if (actions.length <= 2)
          Row(
            children: actions.map((a) => Expanded(child: Padding(
              padding: EdgeInsets.only(right: a != actions.last ? 8 : 0),
              child: a,
            ))).toList(),
          )
        else ...[
          Row(
            children: [
              Expanded(child: Padding(padding: EdgeInsets.only(right: 4), child: actions[0])),
              Expanded(child: Padding(padding: EdgeInsets.only(left: 4), child: actions[1])),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: actions.skip(2).map((a) => Expanded(child: Padding(
              padding: EdgeInsets.only(right: a != actions.last ? 4 : 0, left: a != actions[2] ? 4 : 0),
              child: a,
            ))).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<Color>? gradient,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient != null && isPrimary ? LinearGradient(colors: gradient) : null,
          color: gradient != null && !isPrimary
              ? gradient[0].withValues(alpha: 0.1)
              : gradient == null
                  ? (Theme.of(context).colorScheme.surface)
                  : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: gradient != null
                ? gradient[0].withValues(alpha: isPrimary ? 0 : 0.3)
                : (Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          boxShadow: isPrimary && gradient != null ? [
            BoxShadow(color: gradient[0].withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
              color: isPrimary ? Theme.of(context).colorScheme.onSurface : (gradient?[0] ?? (Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
              size: 18,
            ),
            SizedBox(width: 6),
            Text(label,
              style: TextStyle(
                color: isPrimary ? Theme.of(context).colorScheme.onSurface : (gradient?[0] ?? (Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOrder(BuildContext context, Restaurant r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛒 Starting order from ${r.name}...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleReserve(BuildContext context, Restaurant r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🪑 Booking a seat at ${r.name}...'),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleMap(BuildContext context, Restaurant r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Showing ${r.name} on map...'),
        backgroundColor: Colors.teal.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleNavigate(BuildContext context, Restaurant r) async {
    // Open in external maps app
    final url = r.mapsUrl;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧭 Opening navigation to ${r.name}...'),
        backgroundColor: Colors.blueGrey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final MenuItem item;
  final bool isDark;
  final Color accent;
  const _MenuItemTile({required this.item, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
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
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    if (item.tags.contains('bestseller'))
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
                  SizedBox(height: 2),
                  Text(item.description!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
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
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.add, color: accent, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Popular Items Section (horizontal food items) ───────────────

class _PopularItemsSection extends StatefulWidget {
  final List<Restaurant> restaurants;
  final bool isDark;
  final Color accent;

  const _PopularItemsSection({
    required this.restaurants,
    required this.isDark,
    required this.accent,
  });

  @override
  State<_PopularItemsSection> createState() => _PopularItemsSectionState();
}

class _PopularItemsSectionState extends State<_PopularItemsSection> {
  List<_PopularItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void didUpdateWidget(covariant _PopularItemsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restaurants != oldWidget.restaurants) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    final items = <_PopularItem>[];
    // Load menu from top 5 restaurants
    for (final r in widget.restaurants.take(5)) {
      final menu = await RestaurantService.getMenu(r.id);
      for (final item in menu) {
        items.add(_PopularItem(item: item, restaurant: r));
      }
    }
    // Sort: bestsellers first, then by price
    items.sort((a, b) {
      final aBS = a.item.tags.contains('bestseller') ? 0 : 1;
      final bBS = b.item.tags.contains('bestseller') ? 0 : 1;
      if (aBS != bBS) return aBS.compareTo(bBS);
      return b.item.price.compareTo(a.item.price);
    });
    if (mounted) {
      setState(() {
        _items = items.take(15).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 140,
        child: Center(
          child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(color: widget.accent, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_items.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(AppLocalizations.of(context)?.auto_popularDishes ?? '🍽️ Popular Dishes',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 15, fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_items.length}',
                  style: TextStyle(color: widget.accent, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, _) => SizedBox(width: 10),
            itemBuilder: (ctx, i) => _PopularItemCard(
              item: _items[i],
              isDark: widget.isDark,
              accent: widget.accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _PopularItem {
  final MenuItem item;
  final Restaurant restaurant;
  const _PopularItem({required this.item, required this.restaurant});
}

class _PopularItemCard extends StatelessWidget {
  final _PopularItem item;
  final bool isDark;
  final Color accent;

  const _PopularItemCard({required this.item, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final menuItem = item.item;
    final restaurant = item.restaurant;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => RestaurantDetailPage(
            restaurant: restaurant,
            highlightMenuItemId: menuItem.id,
          ),
        ));
      },
      child: Container(
        width: 140,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food emoji + bestseller
            Row(
              children: [
                Text(_foodEmoji(menuItem), style: TextStyle(fontSize: 28)),
                Spacer(),
                if (menuItem.tags.contains('bestseller'))
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('🔥', style: TextStyle(fontSize: 10, color: accent)),
                  ),
              ],
            ),
            SizedBox(height: 6),
            // Item name
            Text(menuItem.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13, fontWeight: FontWeight.w600,
              ),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            Spacer(),
            // Restaurant + price
            Text(restaurant.name,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 10),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text('${menuItem.price.round()} UZS',
                  style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add, color: accent, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _foodEmoji(MenuItem item) {
    final name = item.name.toLowerCase();
    if (name.contains('plov') || name.contains('osh')) return '🍚';
    if (name.contains('lagman')) return '🍜';
    if (name.contains('somsa') || name.contains('samsa')) return '🥟';
    if (name.contains('shashlik') || name.contains('kebab')) return '🥩';
    if (name.contains('shurpa') || name.contains('soup')) return '🍲';
    if (name.contains('salad')) return '🥗';
    if (name.contains('burger')) return '🍔';
    if (name.contains('pizza')) return '🍕';
    if (name.contains('sushi') || name.contains('roll')) return '🍣';
    if (name.contains('tea') || name.contains('choy')) return '🍵';
    if (name.contains('bread') || name.contains('non')) return '🫓';
    if (name.contains('manti')) return '🥟';
    return '🍽️';
  }
}

// ── Empty State ─────────────────────────────────────────────────


class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
          SizedBox(height: 16),
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 17, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13), textAlign: TextAlign.center),
          if (action != null) ...[
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}
