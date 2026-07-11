// Plately — Location Service
// =============================
// Singleton service for GPS location, reverse geocoding, and region management.
// Implements the Karrot-style hyperlocal region system:
// - Detects user's current neighborhood via GPS + reverse geocoding
// - Fetches nearby regions from Supabase
// - User manually picks a region (Karrot-style)
// - Allows configurable radius (1km, 2km, 5km, 10km)
// - Caches the last known location + selected region for fast access
// - Web-compatible via geolocator_web

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A region/neighborhood from the Supabase `regions` table.
class Region {
  final String id;
  final String name;
  final String? nameLocal;
  final double latitude;
  final double longitude;
  final String city;
  double distMeters; // distance from user

  Region({
    required this.id,
    required this.name,
    this.nameLocal,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.distMeters = 0,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      name: json['name'] as String,
      nameLocal: json['name_local'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      city: json['city'] as String? ?? '',
    );
  }

  /// Display: "Asaka (Асака)" or just "Asaka"
  String get displayName {
    if (nameLocal != null && nameLocal!.isNotEmpty && nameLocal != name) {
      return '$name ($nameLocal)';
    }
    return name;
  }
}

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // ── State ──────────────────────────────────────────
  Position? _currentPosition;
  String _regionName = 'Detecting...';
  String _subLocality = '';
  String _locality = '';
  int _radiusMeters = 2000; // Default 2km
  bool _locationGranted = false;
  bool _loading = false;
  String? _error;

  // ── Region Selection (Karrot-style) ────────────────
  Region? _selectedRegion; // User-chosen region
  List<Region> _nearbyRegions = [];

  // ── Getters ────────────────────────────────────────
  Position? get currentPosition => _currentPosition;
  double get latitude => _selectedRegion?.latitude ?? _currentPosition?.latitude ?? 0;
  double get longitude => _selectedRegion?.longitude ?? _currentPosition?.longitude ?? 0;
  String get regionName => _selectedRegion?.name ?? _regionName;
  String get subLocality => _subLocality;
  String get locality => _selectedRegion?.city ?? _locality;
  int get radiusMeters => _radiusMeters;
  bool get locationGranted => _locationGranted;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null || _selectedRegion != null;
  Region? get selectedRegion => _selectedRegion;
  List<Region> get nearbyRegions => _nearbyRegions;
  bool get hasSelectedRegion => _selectedRegion != null;

  /// The actual GPS position (not the region center)
  double get gpsLatitude => _currentPosition?.latitude ?? 0;
  double get gpsLongitude => _currentPosition?.longitude ?? 0;

  /// Human-readable radius label
  String get radiusLabel {
    if (_radiusMeters >= 1000) {
      return '${(_radiusMeters / 1000).toStringAsFixed(_radiusMeters % 1000 == 0 ? 0 : 1)}km';
    }
    return '${_radiusMeters}m';
  }

  /// Full location display: "Asaka · 2km"
  String get locationDisplay => '$regionName · $radiusLabel';

  // ── Persistence Keys ───────────────────────────────
  static const String _keyRadius = 'location_radius';
  static const String _keyCachedLat = 'cached_lat';
  static const String _keyCachedLng = 'cached_lng';
  static const String _keyCachedRegion = 'cached_region';
  static const String _keySelectedRegionId = 'selected_region_id';
  static const String _keySelectedRegionName = 'selected_region_name';
  static const String _keySelectedRegionLat = 'selected_region_lat';
  static const String _keySelectedRegionLng = 'selected_region_lng';
  static const String _keySelectedRegionCity = 'selected_region_city';

  /// Initialize: restore cached location + region, then request fresh GPS.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _radiusMeters = prefs.getInt(_keyRadius) ?? 2000;

    // Restore cached selected region
    final savedRegionId = prefs.getString(_keySelectedRegionId);
    if (savedRegionId != null) {
      _selectedRegion = Region(
        id: savedRegionId,
        name: prefs.getString(_keySelectedRegionName) ?? 'Your Area',
        latitude: prefs.getDouble(_keySelectedRegionLat) ?? 0,
        longitude: prefs.getDouble(_keySelectedRegionLng) ?? 0,
        city: prefs.getString(_keySelectedRegionCity) ?? '',
      );
    }

    // Restore cached GPS location for instant display
    final cachedLat = prefs.getDouble(_keyCachedLat);
    final cachedLng = prefs.getDouble(_keyCachedLng);
    final cachedRegion = prefs.getString(_keyCachedRegion);
    if (cachedLat != null && cachedLng != null) {
      _currentPosition = Position(
        latitude: cachedLat,
        longitude: cachedLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _regionName = cachedRegion ?? 'Unknown Area';
      _locationGranted = true;
    }

    notifyListeners();

    // Request fresh location in background (fire-and-forget, never blocks startup)
    unawaited(refreshLocation());
  }

  /// Request fresh GPS location and update region.
  /// Falls back to default location (Tashkent) if GPS fails (e.g. on emulator).
  Future<void> refreshLocation() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _applyDefaultLocation('Location services disabled — using default');
        return;
      }

      // Check / request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _applyDefaultLocation('Location permission denied — using default');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _applyDefaultLocation('Location permission permanently denied — using default');
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _locationGranted = true;

      // Reverse geocode to get fallback region name
      await _resolveRegionName();

      // Fetch nearby regions from Supabase
      await fetchNearbyRegions();

      // Cache the result
      await _cacheLocation();

      _loading = false;
      notifyListeners();
    } catch (e) {
      // GPS timeout or other failure — use fallback
      _applyDefaultLocation('Could not get GPS — using default location');
    }
  }

  /// Apply a hardcoded default location so the app is usable
  /// even when GPS is unavailable (e.g. Android emulator).
  void _applyDefaultLocation(String reason) {
    debugPrint('[LocationService] $reason');
    // Default: Tashkent, Uzbekistan (41.2995, 69.2401)
    _currentPosition = Position(
      latitude: 41.2995,
      longitude: 69.2401,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    _regionName = 'Tashkent';
    _locality = 'Tashkent';
    _locationGranted = true;
    _loading = false;
    _error = null;
    notifyListeners();

    // Still try to fetch regions in the background
    fetchNearbyRegions();
  }

  /// Fetch regions from Supabase and calculate distance from user.
  Future<void> fetchNearbyRegions() async {
    if (_currentPosition == null) return;

    try {
      final client = Supabase.instance.client;

      // Try RPC first (returns clean lat/lng)
      List<dynamic> data;
      bool usedRpc = false;
      try {
        data = await client.rpc('get_regions_with_coords') as List<dynamic>;
        usedRpc = true;
      } catch (_) {
        // RPC not available, fall back to direct query
        data = await client
            .from('regions')
            .select('id, name, name_local, city, center')
            .order('name');
      }

      final regions = <Region>[];
      for (final row in data) {
        final map = row as Map<String, dynamic>;
        double lat = 0, lng = 0;

        if (usedRpc) {
          // RPC returns latitude/longitude directly
          lat = (map['latitude'] as num?)?.toDouble() ?? 0;
          lng = (map['longitude'] as num?)?.toDouble() ?? 0;
        } else {
          // Parse center point from geography column
          final center = map['center'];
          if (center is String) {
            final match = RegExp(r'POINT\(([\d.-]+)\s+([\d.-]+)\)').firstMatch(center);
            if (match != null) {
              lng = double.parse(match.group(1)!);
              lat = double.parse(match.group(2)!);
            }
          } else if (center is Map) {
            final coords = center['coordinates'] as List?;
            if (coords != null && coords.length >= 2) {
              lng = (coords[0] as num).toDouble();
              lat = (coords[1] as num).toDouble();
            }
          }
        }

        // Skip regions with invalid coordinates (0,0 means parsing failed)
        if (lat == 0 && lng == 0) continue;

        final region = Region(
          id: map['id'] as String,
          name: map['name'] as String,
          nameLocal: map['name_local'] as String?,
          latitude: lat,
          longitude: lng,
          city: map['city'] as String? ?? '',
        );

        // Calculate distance from user's actual GPS position
        region.distMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );

        regions.add(region);
      }

      // Sort by distance
      regions.sort((a, b) => a.distMeters.compareTo(b.distMeters));
      _nearbyRegions = regions;

      // If no region selected yet, auto-select the nearest one
      if (_selectedRegion == null && regions.isNotEmpty) {
        await selectRegion(regions.first);
      }
    } catch (e) {
      // Regions table might not exist yet
      _nearbyRegions = [];
    }
  }

  /// User manually selects a region (Karrot-style).
  Future<void> selectRegion(Region region) async {
    _selectedRegion = region;
    notifyListeners();

    // Persist selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedRegionId, region.id);
    await prefs.setString(_keySelectedRegionName, region.name);
    await prefs.setDouble(_keySelectedRegionLat, region.latitude);
    await prefs.setDouble(_keySelectedRegionLng, region.longitude);
    await prefs.setString(_keySelectedRegionCity, region.city);
  }

  /// Clear region selection (revert to GPS-based).
  Future<void> clearRegionSelection() async {
    _selectedRegion = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedRegionId);
    await prefs.remove(_keySelectedRegionName);
    await prefs.remove(_keySelectedRegionLat);
    await prefs.remove(_keySelectedRegionLng);
    await prefs.remove(_keySelectedRegionCity);
  }

  /// Reverse geocode current position to get neighborhood name.
  Future<void> _resolveRegionName() async {
    if (_currentPosition == null) return;

    try {
      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Use subLocality (neighborhood) > locality (city) > administrativeArea
        _subLocality = place.subLocality ?? '';
        _locality = place.locality ?? '';

        if (_subLocality.isNotEmpty) {
          _regionName = _subLocality;
        } else if (_locality.isNotEmpty) {
          _regionName = _locality;
        } else if (place.administrativeArea?.isNotEmpty == true) {
          _regionName = place.administrativeArea!;
        } else {
          _regionName = 'Your Area';
        }
      }
    } catch (e) {
      // Geocoding can fail on web or without network
      _regionName = 'Your Area';
    }
  }

  /// Cache location and region to SharedPreferences.
  Future<void> _cacheLocation() async {
    if (_currentPosition == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyCachedLat, _currentPosition!.latitude);
    await prefs.setDouble(_keyCachedLng, _currentPosition!.longitude);
    await prefs.setString(_keyCachedRegion, _regionName);
  }

  /// Change the search radius.
  Future<void> setRadius(int meters) async {
    if (_radiusMeters == meters) return;
    _radiusMeters = meters;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRadius, meters);
    notifyListeners();
  }

  /// Calculate distance (in meters) from current position to a point.
  double distanceTo(double lat, double lng) {
    if (_currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  /// Format distance for display: "0.3 km", "1.2 km", etc.
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
