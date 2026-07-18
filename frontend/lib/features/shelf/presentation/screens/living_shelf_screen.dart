// Plately — Living Shelf Screen
// The Digital Twin of the user's kitchen — a reactive grid of inventory items
// organized by storage zone (fridge, freezer, pantry).
// Connected to Supabase with Realtime for live updates.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/widgets/shimmer_loading.dart';
import 'package:plately_app/core/widgets/empty_state_illustration.dart';
import 'package:plately_app/core/widgets/slide_in_item.dart';
import 'package:plately_app/features/shelf/domain/inventory_item.dart';
import 'package:plately_app/features/shelf/presentation/widgets/inventory_item_card.dart';
import 'package:plately_app/features/cook/presentation/screens/cook_screen.dart';
import 'package:plately_app/features/scan/presentation/screens/scan_screen.dart';
import 'package:plately_app/features/shelf/presentation/widgets/inventory_detail_sheet.dart';
import 'package:plately_app/core/utils/category_images.dart';
import 'package:plately_app/core/utils/l10n_helper.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plately_app/core/services/tutorial_controller.dart';

class LivingShelfScreen extends ConsumerStatefulWidget {
  const LivingShelfScreen({super.key});

  @override
  ConsumerState<LivingShelfScreen> createState() => _LivingShelfScreenState();
}

class _LivingShelfScreenState extends ConsumerState<LivingShelfScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _zones = ['Fridge', 'Freezer', 'Pantry'];

  List<InventoryItem> _items = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  List<InventoryItem> get _displayItems {
    final tutorialState = ref.watch(tutorialControllerProvider);
    if (tutorialState != TutorialState.none) {
      if (tutorialState == TutorialState.shelfIntro ||
          tutorialState == TutorialState.clickAdd ||
          tutorialState == TutorialState.scanIntro ||
          tutorialState == TutorialState.welcome) {
        return [];
      } else {
        return _getMockTutorialItems();
      }
    }
    return _items;
  }

  List<InventoryItem> _getMockTutorialItems() {
    final now = DateTime.now();
    final purchase = now.subtract(const Duration(days: 1));
    return [
      InventoryItem(
        id: 'tutorial-chicken',
        ingredientId: 'ing-chicken',
        name: 'Chicken Breast',
        quantity: 500,
        unit: 'g',
        itemState: 'sealed',
        purchaseDate: purchase,
        computedExpiry: now.add(const Duration(days: 6)),
        location: 'fridge',
        category: 'poultry',
        localizedNames: {
          'en': 'Chicken Breast',
          'ko': '닭가슴살',
          'uz': 'Tovuq ko\'kragi',
          'uz_cyrl': 'Товуқ кўкраги',
          'ru': 'Куриная грудка',
        },
      ),
      InventoryItem(
        id: 'tutorial-broccoli',
        ingredientId: 'ing-broccoli',
        name: 'Broccoli',
        quantity: 1,
        unit: 'head',
        itemState: 'sealed',
        purchaseDate: purchase,
        computedExpiry: now.add(const Duration(days: 4)),
        location: 'fridge',
        category: 'vegetable',
        localizedNames: {
          'en': 'Broccoli',
          'ko': '브로콜리',
          'uz': 'Brokkoli',
          'uz_cyrl': 'Брокколи',
          'ru': 'Брокколи',
        },
      ),
      InventoryItem(
        id: 'tutorial-soysauce',
        ingredientId: 'ing-soysauce',
        name: 'Soy Sauce',
        quantity: 150,
        unit: 'ml',
        itemState: 'opened',
        purchaseDate: purchase,
        computedExpiry: now.add(const Duration(days: 180)),
        location: 'pantry',
        category: 'sauce',
        localizedNames: {
          'en': 'Soy Sauce',
          'ko': '간장',
          'uz': 'Soya sousi',
          'uz_cyrl': 'Соя соуси',
          'ru': 'Соевый соус',
        },
      ),
      InventoryItem(
        id: 'tutorial-garlic',
        ingredientId: 'ing-garlic',
        name: 'Garlic',
        quantity: 3,
        unit: 'cloves',
        itemState: 'sealed',
        purchaseDate: purchase,
        computedExpiry: now.add(const Duration(days: 14)),
        location: 'pantry',
        category: 'vegetable',
        localizedNames: {
          'en': 'Garlic',
          'ko': '마늘',
          'uz': 'Sarimsoq',
          'uz_cyrl': 'Саримсоқ',
          'ru': 'Чеснок',
        },
      ),
      InventoryItem(
        id: 'tutorial-sesameoil',
        ingredientId: 'ing-sesameoil',
        name: 'Sesame Oil',
        quantity: 50,
        unit: 'ml',
        itemState: 'opened',
        purchaseDate: purchase,
        computedExpiry: now.add(const Duration(days: 90)),
        location: 'pantry',
        category: 'oil',
        localizedNames: {
          'en': 'Sesame Oil',
          'ko': '참기름',
          'uz': 'Kunjut yog\'i',
          'uz_cyrl': 'Кунжут ёғи',
          'ru': 'Кунжутное масло',
        },
      ),
    ];
  }

  // ── Search, Filter & Sort state ─────────────────────────────
  String _searchQuery = '';
  String? _selectedCategory;
  _SortMode _sortMode = _SortMode.expiry;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _zones.length, vsync: this);
    _loadInventory();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _channel?.unsubscribe();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────────

  Future<void> _loadInventory() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await Supabase.instance.client
          .from('inventory_items')
          .select('*, ingredients(display_name_en, display_name_ko, display_name_uz, display_name_uz_cyrl, display_name_ru, category)')
          .eq('user_id', currentUserId())
          .order('computed_expiry', ascending: true);


      setState(() {
        _items = (data as List)
            .map((row) =>
                InventoryItem.fromSupabase(row as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Realtime Subscription ────────────────────────────────────

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
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
          callback: (payload) {
            // Reload full inventory on any change
            _loadInventory();
          },
        )
        .subscribe();
  }

  List<InventoryItem> _itemsForZone(String zone) {
    var filtered = _displayItems.where((i) => i.location == zone.toLowerCase());

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((i) {
        final q = _searchQuery.toLowerCase();
        // Search across all localized names
        if (i.name.toLowerCase().contains(q)) return true;
        for (final n in i.localizedNames.values) {
          if (n.toLowerCase().contains(q)) return true;
        }
        return false;
      });
    }

    // Category filter
    if (_selectedCategory != null) {
      filtered = filtered
          .where((i) => i.category.toLowerCase() == _selectedCategory);
    }

    final list = filtered.toList();

    // Sort
    switch (_sortMode) {
      case _SortMode.expiry:
        list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
      case _SortMode.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _SortMode.category:
        list.sort((a, b) => a.category.compareTo(b.category));
      case _SortMode.newest:
        list.sort((a, b) => (b.purchaseDate ?? DateTime(2000))
            .compareTo(a.purchaseDate ?? DateTime(2000)));
    }
    return list;
  }

  /// All unique categories currently in the inventory.
  List<String> get _categories {
    final cats = _displayItems.map((i) => i.category.toLowerCase()).toSet().toList()
      ..sort();
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.myFridge ?? '🧊 My Fridge'),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.refresh),
            onPressed: _loadInventory,
            tooltip: AppLocalizations.of(context)?.refresh ?? 'Refresh',
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _alertCount > 0,
              label: Text('$_alertCount',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
              backgroundColor: Theme.of(context).colorScheme.error,
              child: Icon(CupertinoIcons.bell),
            ),
            onPressed: _showExpiryAlerts,
            tooltip: AppLocalizations.of(context)?.expiryAlerts ?? 'Expiry alerts',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          tabs: _zones.map((z) => Tab(text: _getLocalizedZone(z))).toList(),
        ),
      ),
      body: (ref.watch(tutorialControllerProvider) != TutorialState.none ? false : _loading)
          ? const ShelfSkeleton()
          : (ref.watch(tutorialControllerProvider) != TutorialState.none ? null : _error) != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: _zones.map((zone) {
                    final items = _itemsForZone(zone);
                    return _buildShelfGrid(items, zone);
                  }).toList(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: EdgeInsets.only(top: 100),
      child: EmptyStateIllustration(
        emoji: '🔌',
        title: AppLocalizations.of(context)?.errorLoadInventory ?? 'Couldn\'t load inventory',
        description: AppLocalizations.of(context)?.errorCheckConnection ?? 'Check your connection and try again.',
        actionLabel: AppLocalizations.of(context)?.retry ?? 'Retry',
        onAction: _loadInventory,
      ),
    );
  }

  // ── Summary Stats Banner ──────────────────────────────────────

  Widget _buildSummaryBanner(List<InventoryItem> zoneItems) {
    final total = zoneItems.length;
    final expiring =
        zoneItems.where((i) => i.daysUntilExpiry >= 0 && i.daysUntilExpiry <= 3).length;
    final expired = zoneItems.where((i) => i.daysUntilExpiry < 0).length;
    final fresh = total - expiring - expired;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(child: _statChip('$total', AppLocalizations.of(context)?.total ?? 'Total', Theme.of(context).colorScheme.primary)),
          _buildVerticalDivider(),
          Expanded(child: _statChip('$fresh', AppLocalizations.of(context)?.fresh ?? 'Fresh', Theme.of(context).colorScheme.tertiary)),
          _buildVerticalDivider(),
          Expanded(child: _statChip('$expiring', AppLocalizations.of(context)?.expiring ?? 'Expiring', Theme.of(context).colorScheme.primary)),
          _buildVerticalDivider(),
          Expanded(child: _statChip('$expired', AppLocalizations.of(context)?.expired ?? 'Expired', Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)?.searchIngredients ?? 'Search ingredients...',
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
          prefixIcon:
              Icon(CupertinoIcons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(CupertinoIcons.clear_thick, size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }

  // ── Category Chips ────────────────────────────────────────────

  Widget _buildCategoryChips() {
    if (_categories.isEmpty) return SizedBox.shrink();
    final hasPrepItems = _displayItems.any((i) => i.isCookedLeftover);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip(null, AppLocalizations.of(context)?.all ?? 'All'),
          if (hasPrepItems)
            _filterChip('prepared', '🍱 Meal Prep'),
          ..._categories.where((c) => c != 'prepared').map((c) => _filterChip(c, L10nHelper.translateCategory(c, Localizations.localeOf(context)))),
        ],
      ),
    );
  }

  Widget _filterChip(String? cat, String label) {
    final active = _selectedCategory == cat;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: active,
        label: Text(
          cat != null ? '${categoryEmoji(cat)} $label' : label,
          style: TextStyle(
            color: active ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onSelected: (_) => setState(() => _selectedCategory = cat),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        checkmarkColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        padding: EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // ── Sort Row ──────────────────────────────────────────────────

  Widget _buildSortRow(int count) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Text(AppLocalizations.of(context)?.itemsCount(count) ?? '$count items',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        Spacer(),
        SizedBox(
          height: 28,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_SortMode>(
              value: _sortMode,
              isDense: true,
              icon: Icon(CupertinoIcons.arrow_up_arrow_down,
                  size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12),
              items: _SortMode.values
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(_getSortModeLabel(context, m))))
                  .toList(),
              onChanged: (m) {
                if (m != null) setState(() => _sortMode = m);
              },
            ),
          ),
        ),
      ]),
    );
  }

  // ── Shelf Grid (the main zone content) ────────────────────────

  Widget _buildShelfGrid(List<InventoryItem> items, String zone) {
    // Get ALL zone items before search/filter for the summary banner
    final allZoneItems = _displayItems
        .where((i) => i.location == zone.toLowerCase())
        .toList();

    if (allZoneItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInventory,
        color: Theme.of(context).colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: EmptyStateIllustration(
                    emoji: _zoneEmoji(zone),
                    title: AppLocalizations.of(context)?.zoneEmptyTitle(_getLocalizedZone(zone)) ?? 'Your ${_getLocalizedZone(zone)} is Empty',
                    description:
                        AppLocalizations.of(context)?.zoneEmptyDesc ?? 'Ready to fill up your digital kitchen.\nAdd items manually or tap scan.',
                    actionLabel: AppLocalizations.of(context)?.addIngredient ?? 'Add Ingredient',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Separate urgent items for the banner
    final urgentItems =
        allZoneItems.where((i) => i.daysUntilExpiry <= 2 && i.daysUntilExpiry >= 0).toList();

    return RefreshIndicator(
      onRefresh: _loadInventory,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          // --- Summary Banner ---
          SliverToBoxAdapter(child: _buildSummaryBanner(allZoneItems)),

          // --- Search Bar ---
          SliverToBoxAdapter(child: _buildSearchBar()),

          // --- Category Chips ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: _buildCategoryChips(),
            ),
          ),

          // --- Expiring Soon Banner ---
          if (urgentItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.fromLTRB(16, 4, 16, 4),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color:
                          Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Text('⚠️', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)?.expiringSoon ?? 'Expiring Soon',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          Text(
                              AppLocalizations.of(context)?.nItemsNeedAttention('${urgentItems.length}') ?? '${urgentItems.length} item(s) need attention',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 11)),
                        ]),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CookScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      padding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                    ),
                    child: Text(AppLocalizations.of(context)?.urgentCook ?? 'Cook Now',
                        style:
                            TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface)),
                  ),
                ]),
              ),
            ),

          // --- Sort Row ---
          SliverToBoxAdapter(child: _buildSortRow(items.length)),

          // --- Empty search result ---
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('🕵️', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text(AppLocalizations.of(context)?.noItemsMatch ?? 'No items match your filters',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 14)),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _searchQuery = '';
                        _searchCtrl.clear();
                        _selectedCategory = null;
                      }),
                      child: Text(AppLocalizations.of(context)?.clearFilters ?? 'Clear filters'),
                    ),
                  ]),
                ),
              ),
            ),

          // --- Main Grid ---
          if (items.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridColumns(context),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SlideInItem(
                    delay: index * 60,
                    child: InventoryItemCard(
                      item: items[index],
                      onTap: () =>
                          InventoryDetailSheet.show(context, items[index]),
                    ),
                  ),
                  childCount: items.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _zoneEmoji(String zone) {
    if (zone == 'Fridge') return '🧊';
    if (zone == 'Freezer') return '🥶';
    if (zone == 'Pantry') return '🥫';
    return '📦';
  }

  String _getLocalizedZone(String zone) {
    switch (zone) {
      case 'Fridge': return AppLocalizations.of(context)?.auto_fridge ?? 'Fridge';
      case 'Freezer': return AppLocalizations.of(context)?.auto_freezer ?? 'Freezer';
      case 'Pantry': return AppLocalizations.of(context)?.auto_pantry ?? 'Pantry';
      default: return zone;
    }
  }

  int get _alertCount =>
      _displayItems.where((i) => i.daysUntilExpiry <= 3).length;

  int _gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return 6;
    if (w > 900) return 5;
    if (w > 600) return 4;
    if (w > 400) return 3;
    return 2;
  }

  void _showExpiryAlerts() {
    final expiring = _displayItems
        .where((i) => i.daysUntilExpiry >= 0 && i.daysUntilExpiry <= 3)
        .toList();
    final expired = _displayItems.where((i) => i.daysUntilExpiry < 0).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)?.expiryAlertsTitle ?? '🔔 Expiry Alerts',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 16),
            if (expired.isEmpty && expiring.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(AppLocalizations.of(context)?.allFresh ?? 'All items are fresh! 🎉',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 15)),
                ),
              ),
            if (expired.isNotEmpty) ...[
              Text(AppLocalizations.of(context)?.expiredCount(expired.length) ?? '❌ Expired (${expired.length})',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              SizedBox(height: 8),
              ...expired.take(5).map((item) => _alertTile(item, true)),
              SizedBox(height: 16),
            ],
            if (expiring.isNotEmpty) ...[
              Text(AppLocalizations.of(context)?.expiringSoonCount(expiring.length) ?? '⚠️ Expiring Soon (${expiring.length})',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              SizedBox(height: 8),
              ...expiring.take(5).map((item) => _alertTile(item, false)),
            ],
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(InventoryItem item, bool isExpired) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Text(categoryEmoji(item.category),
              style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.localizedName(context),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(
                    isExpired
                        ? '${AppLocalizations.of(context)?.expired ?? "Expired"} ${-item.daysUntilExpiry}d'
                        : item.daysUntilExpiry == 0
                            ? AppLocalizations.of(context)?.expiringSoon ?? 'Expires today'
                            : '${item.daysUntilExpiry}d',
                    style: TextStyle(
                        color: isExpired
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        fontSize: 11),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }

  String _getSortModeLabel(BuildContext context, _SortMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case _SortMode.expiry:
        return l10n?.sortByExpiry ?? 'Expiry ↑';
      case _SortMode.name:
        return l10n?.sortByName ?? 'Name A-Z';
      case _SortMode.category:
        return l10n?.sortByCategory ?? 'Category';
      case _SortMode.newest:
        return l10n?.sortByNewest ?? 'Newest first';
    }
  }
}

// ── Sort Mode Enum ──────────────────────────────────────────────

enum _SortMode {
  expiry('Expiry ↑'),
  name('Name A-Z'),
  category('Category'),
  newest('Newest first');

  final String label;
  const _SortMode(this.label);
}
