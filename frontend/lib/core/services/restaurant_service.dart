// Plately — Restaurant Service
// ===============================
// Wraps Supabase PostGIS RPC calls for geo-filtered restaurant discovery.
// Handles restaurant listing, menu items, orders, and seat bookings.
//
// Service types per restaurant:
//   has_delivery    → user can order food delivered
//   has_reservation → user can book a table/seat
//   has_dine_in     → user can walk in (show on map / navigate)

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/location_service.dart';

/// A restaurant or branch outlet returned from the nearby_restaurants RPC or listing.
class Restaurant {
  final String id;
  final String name;
  final String? description;
  final List<String> cuisineType;
  final int priceRange;
  final double rating;
  final int reviewCount;
  final String? address;
  final String? imageUrl;
  final bool isOpen;
  final int avgPrepMinutes;
  final double deliveryFee;
  final List<String> tags;
  final double distMeters;
  final double latitude;
  final double longitude;

  // ── Service Types ──────────────────────────────────
  final bool hasDelivery;
  final bool hasReservation;
  final bool hasDineIn;

  // ── Branch & Workshop Website Links ────────────────
  final String? slug;
  final String? branchId;
  final String? branchName;
  final String? storefrontUrl;
  final String? phone;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    required this.cuisineType,
    required this.priceRange,
    required this.rating,
    required this.reviewCount,
    this.address,
    this.imageUrl,
    required this.isOpen,
    required this.avgPrepMinutes,
    required this.deliveryFee,
    required this.tags,
    required this.distMeters,
    required this.latitude,
    required this.longitude,
    this.hasDelivery = true,
    this.hasReservation = false,
    this.hasDineIn = true,
    this.slug,
    this.branchId,
    this.branchName,
    this.storefrontUrl,
    this.phone,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as String?;
    final branchId = json['branch_id'] as String?;
    final branchName = json['branch_name'] as String?;
    final phone = json['phone'] as String?;
    final rawStorefrontUrl = json['storefront_url'] as String?;
    final storefrontUrl = rawStorefrontUrl ??
        (slug != null && slug.isNotEmpty ? 'https://workshop.plately.uz/store/$slug' : null);

    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      cuisineType: List<String>.from(json['cuisine_type'] ?? []),
      priceRange: (json['price_range'] as num?)?.toInt() ?? 1,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      address: json['address'] as String?,
      imageUrl: json['image_url'] as String?,
      isOpen: json['is_open'] as bool? ?? true,
      avgPrepMinutes: (json['avg_prep_minutes'] as num?)?.toInt() ?? 20,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      distMeters: (json['dist_meters'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      hasDelivery: json['has_delivery'] as bool? ?? true,
      hasReservation: json['has_reservation'] as bool? ?? false,
      hasDineIn: json['has_dine_in'] as bool? ?? true,
      slug: slug,
      branchId: branchId,
      branchName: branchName,
      storefrontUrl: storefrontUrl,
      phone: phone,
    );
  }

  /// Human-readable distance
  String get distanceLabel {
    final loc = LocationService();
    return loc.formatDistance(distMeters);
  }

  /// Price range as dollar signs
  String get priceLabel => '\$' * priceRange;

  /// Estimated delivery time (prep + rough distance calc)
  int get estimatedDeliveryMinutes {
    final deliveryMin = (distMeters / 1000 * 3).round();
    return avgPrepMinutes + deliveryMin;
  }

  /// Cuisine display string
  String get cuisineLabel => cuisineType.join(' · ');

  /// Service summary for display: "Delivery · Dine-in"
  String get serviceLabel {
    final services = <String>[];
    if (hasDelivery) services.add('Delivery');
    if (hasReservation) services.add('Reserve');
    if (hasDineIn) services.add('Dine-in');
    return services.join(' · ');
  }

  /// Google Maps URL for navigation
  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

/// A menu item from a restaurant.
class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? category;
  final bool isAvailable;
  final int? calories;
  final List<String> tags;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    required this.isAvailable,
    this.calories,
    required this.tags,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      calories: (json['calories'] as num?)?.toInt(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class RestaurantService {
  static final _client = Supabase.instance.client;

  /// Fetch restaurants within radius of user's location, sorted by distance.
  /// Also expands branches so each branch outlet appears in the Order page.
  static Future<List<Restaurant>> getNearbyRestaurants({
    required double lat,
    required double lng,
    int radius = 2000,
    List<String>? cuisineFilter,
    int? priceFilter,
  }) async {
    try {
      final response = await _client.rpc('nearby_restaurants', params: {
        'user_lat': lat,
        'user_long': lng,
        'radius_m': radius,
        'cuisine_filter': cuisineFilter,
        'price_filter': priceFilter,
      });

      final data = response as List<dynamic>;
      if (data.isEmpty) {
        return getAllRestaurants();
      }

      // Collect IDs to attach slug and branch info
      final ids = data.map((e) => e['id'] as String).toList();
      final Map<String, Map<String, dynamic>> extraInfo = {};
      try {
        final extras = await _client
            .from('restaurants')
            .select('id, slug, branches(*)')
            .inFilter('id', ids);
        for (final item in (extras as List<dynamic>)) {
          extraInfo[item['id'] as String] = item as Map<String, dynamic>;
        }
      } catch (_) {}

      final List<Restaurant> results = [];
      for (final json in data) {
        final map = Map<String, dynamic>.from(json as Map<String, dynamic>);
        final restId = map['id'] as String;
        final extra = extraInfo[restId];
        final slug = extra?['slug'] as String?;
        final rawBranches = (extra?['branches'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        final activeBranches = rawBranches.where((b) => b['is_active'] != false).toList();
        final storefrontUrl = (slug != null && slug.isNotEmpty)
            ? 'https://workshop.plately.uz/store/$slug'
            : null;

        if (activeBranches.isNotEmpty) {
          for (final b in activeBranches) {
            final bName = b['name'] as String?;
            final displayName = (bName != null && bName.isNotEmpty && bName != 'Main Branch')
                ? '${map['name']} · $bName'
                : (map['name'] as String);

            results.add(Restaurant(
              id: restId,
              name: displayName,
              description: map['description'] as String?,
              cuisineType: List<String>.from(map['cuisine_type'] ?? []),
              priceRange: (map['price_range'] as num?)?.toInt() ?? 1,
              rating: (map['rating'] as num?)?.toDouble() ?? 0,
              reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
              address: (b['address'] as String?) ?? (map['address'] as String?),
              imageUrl: map['image_url'] as String?,
              isOpen: map['is_open'] as bool? ?? true,
              avgPrepMinutes: (b['default_prep_time_minutes'] as num?)?.toInt() ??
                  (map['avg_prep_minutes'] as num?)?.toInt() ?? 20,
              deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
              tags: List<String>.from(map['tags'] ?? []),
              distMeters: (map['dist_meters'] as num?)?.toDouble() ?? 0,
              latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
              longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
              hasDelivery: (b['accepts_delivery'] as bool?) ?? (map['has_delivery'] as bool?) ?? true,
              hasReservation: map['has_reservation'] as bool? ?? false,
              hasDineIn: (b['accepts_dine_in'] as bool?) ?? (map['has_dine_in'] as bool?) ?? true,
              slug: slug,
              branchId: b['id'] as String?,
              branchName: bName,
              storefrontUrl: storefrontUrl,
              phone: (b['phone'] as String?) ?? (map['phone'] as String?),
            ));
          }
        } else {
          map['slug'] = slug;
          map['storefront_url'] = storefrontUrl;
          results.add(Restaurant.fromJson(map));
        }
      }
      return results;
    } catch (e) {
      return getAllRestaurants();
    }
  }

  /// Fetch menu items for a specific restaurant.
  static Future<List<MenuItem>> getMenu(String restaurantId) async {
    try {
      final data = await _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .order('sort_order');

      return (data as List<dynamic>)
          .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch all restaurants with branch expansions and storefront URLs.
  static Future<List<Restaurant>> getAllRestaurants() async {
    try {
      final data = await _client
          .from('restaurants')
          .select('*, branches(*)')
          .eq('is_open', true)
          .order('rating', ascending: false)
          .limit(50);

      final List<Restaurant> results = [];
      for (final json in (data as List<dynamic>)) {
        final map = json as Map<String, dynamic>;
        final rawBranches = (map['branches'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        final activeBranches = rawBranches.where((b) => b['is_active'] != false).toList();
        final slug = map['slug'] as String?;
        final storefrontUrl = (slug != null && slug.isNotEmpty)
            ? 'https://workshop.plately.uz/store/$slug'
            : null;

        if (activeBranches.isNotEmpty) {
          for (final b in activeBranches) {
            final bName = b['name'] as String?;
            final displayName = (bName != null && bName.isNotEmpty && bName != 'Main Branch')
                ? '${map['name']} · $bName'
                : (map['name'] as String);

            results.add(Restaurant(
              id: map['id'] as String,
              name: displayName,
              description: map['description'] as String?,
              cuisineType: List<String>.from(map['cuisine_type'] ?? []),
              priceRange: (map['price_range'] as num?)?.toInt() ?? 1,
              rating: (map['rating'] as num?)?.toDouble() ?? 0,
              reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
              address: (b['address'] as String?) ?? (map['address'] as String?),
              imageUrl: map['image_url'] as String?,
              isOpen: map['is_open'] as bool? ?? true,
              avgPrepMinutes: (b['default_prep_time_minutes'] as num?)?.toInt() ??
                  (map['avg_prep_minutes'] as num?)?.toInt() ?? 20,
              deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
              tags: List<String>.from(map['tags'] ?? []),
              distMeters: 0,
              latitude: 0,
              longitude: 0,
              hasDelivery: (b['accepts_delivery'] as bool?) ?? (map['has_delivery'] as bool?) ?? true,
              hasReservation: map['has_reservation'] as bool? ?? false,
              hasDineIn: (b['accepts_dine_in'] as bool?) ?? (map['has_dine_in'] as bool?) ?? true,
              slug: slug,
              branchId: b['id'] as String?,
              branchName: bName,
              storefrontUrl: storefrontUrl,
              phone: (b['phone'] as String?) ?? (map['phone'] as String?),
            ));
          }
        } else {
          results.add(Restaurant(
            id: map['id'] as String,
            name: map['name'] as String,
            description: map['description'] as String?,
            cuisineType: List<String>.from(map['cuisine_type'] ?? []),
            priceRange: (map['price_range'] as num?)?.toInt() ?? 1,
            rating: (map['rating'] as num?)?.toDouble() ?? 0,
            reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
            address: map['address'] as String?,
            imageUrl: map['image_url'] as String?,
            isOpen: map['is_open'] as bool? ?? true,
            avgPrepMinutes: (map['avg_prep_minutes'] as num?)?.toInt() ?? 20,
            deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0,
            tags: List<String>.from(map['tags'] ?? []),
            distMeters: 0,
            latitude: 0,
            longitude: 0,
            hasDelivery: map['has_delivery'] as bool? ?? true,
            hasReservation: map['has_reservation'] as bool? ?? false,
            hasDineIn: map['has_dine_in'] as bool? ?? true,
            slug: slug,
            branchId: null,
            branchName: null,
            storefrontUrl: storefrontUrl,
            phone: map['phone'] as String?,
          ));
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }
}
