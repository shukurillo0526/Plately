/// Plately — Inventory Item Domain Model
/// ========================================
library;

import 'package:flutter/material.dart';

class InventoryItem {
  final String id;
  final String ingredientId;
  final String name;
  final String? imageUrl;
  final double quantity;
  final String unit;
  final String itemState;       // sealed, opened, partially_used, frozen, thawed
  final DateTime? purchaseDate;
  final DateTime? computedExpiry;
  final String location;        // fridge, freezer, pantry
  final String source;          // manual, camera, barcode
  final double? confidenceScore;
  final String category;        // fruit, dairy, protein, etc.
  final Map<String, String> localizedNames; // {en, ko, uz, uz_cyrl, ru}

  // Leftover tracking fields
  final bool isCookedLeftover;
  final String? parentRecipeId;
  final String? parentRecipeTitle;
  final int portionsCount;
  final double? caloriesPerPortion;
  final double? proteinPerPortion;
  final double? carbsPerPortion;
  final double? fatPerPortion;
  final DateTime? dateCooked;

  InventoryItem({
    required this.id,
    required this.ingredientId,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.unit,
    required this.itemState,
    this.purchaseDate,
    this.computedExpiry,
    this.location = 'fridge',
    this.source = 'manual',
    this.confidenceScore,
    this.category = 'other',
    this.localizedNames = const {},
    this.isCookedLeftover = false,
    this.parentRecipeId,
    this.parentRecipeTitle,
    this.portionsCount = 1,
    this.caloriesPerPortion,
    this.proteinPerPortion,
    this.carbsPerPortion,
    this.fatPerPortion,
    this.dateCooked,
  });

  /// Days until this item expires. Negative = already expired.
  int get daysUntilExpiry {
    if (computedExpiry == null) return 999;
    return computedExpiry!.difference(DateTime.now()).inDays;
  }

  /// Freshness ratio: 1.0 = perfectly fresh, 0.0 = expired.
  double get freshnessRatio {
    if (computedExpiry == null || purchaseDate == null) return 1.0;
    final totalLife = computedExpiry!.difference(purchaseDate!).inDays;
    if (totalLife <= 0) return 0.0;
    final remaining = computedExpiry!.difference(DateTime.now()).inDays;
    return (remaining / totalLife).clamp(0.0, 1.0);
  }

  /// Freshness state for visual rendering.
  FreshnessState get freshnessState {
    final ratio = freshnessRatio;
    if (ratio > 0.6) return FreshnessState.fresh;
    if (ratio > 0.3) return FreshnessState.aging;
    if (ratio > 0.1) return FreshnessState.urgent;
    if (ratio > 0.0) return FreshnessState.critical;
    return FreshnessState.expired;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      ingredientId: json['ingredient_id'] as String,
      name: json['name'] ?? json['display_name_en'] ?? 'Unknown',
      imageUrl: json['image_url'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'piece',
      itemState: json['item_state'] as String? ?? 'sealed',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'])
          : null,
      computedExpiry: json['computed_expiry'] != null
          ? DateTime.tryParse(json['computed_expiry'])
          : null,
      location: json['location'] as String? ?? 'fridge',
      source: json['source'] as String? ?? 'manual',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      category: json['category'] as String? ?? 'other',
      localizedNames: _extractNames(json),
      isCookedLeftover: json['is_cooked_leftover'] as bool? ?? false,
      parentRecipeId: json['parent_recipe_id'] as String?,
      parentRecipeTitle: json['parent_recipe_title'] as String?,
      portionsCount: json['portions_count'] as int? ?? 1,
      caloriesPerPortion: (json['calories_per_portion'] as num?)?.toDouble(),
      proteinPerPortion: (json['protein_per_portion'] as num?)?.toDouble(),
      carbsPerPortion: (json['carbs_per_portion'] as num?)?.toDouble(),
      fatPerPortion: (json['fat_per_portion'] as num?)?.toDouble(),
      dateCooked: json['date_cooked'] != null
          ? DateTime.tryParse(json['date_cooked'])
          : null,
    );
  }

  /// Factory for Supabase rows with joined `ingredients` table.
  /// Expects: `inventory_items.select('*, ingredients(display_name_en, category)')`.
  factory InventoryItem.fromSupabase(Map<String, dynamic> row) {
    final ingredient = row['ingredients'] as Map<String, dynamic>?;
    return InventoryItem(
      id: row['id'] as String,
      ingredientId: row['ingredient_id'] as String,
      name: row['is_cooked_leftover'] == true
          ? (row['parent_recipe_title'] ?? 'Cooked Meal')
          : (ingredient?['display_name_en'] ?? 'Unknown'),
      imageUrl: null,
      quantity: (row['quantity'] as num).toDouble(),
      unit: row['unit'] as String? ?? 'piece',
      itemState: row['item_state'] as String? ?? 'sealed',
      purchaseDate: row['purchase_date'] != null
          ? DateTime.tryParse(row['purchase_date'].toString())
          : null,
      computedExpiry: row['computed_expiry'] != null
          ? DateTime.tryParse(row['computed_expiry'].toString())
          : null,
      location: (row['location'] as String? ?? 'fridge').toLowerCase(),
      source: row['source'] as String? ?? 'manual',
      confidenceScore: (row['confidence_score'] as num?)?.toDouble(),
      category: row['is_cooked_leftover'] == true ? 'prepared' : (ingredient?['category'] as String? ?? 'other'),
      localizedNames: row['is_cooked_leftover'] == true
          ? {'en': row['parent_recipe_title'] ?? 'Cooked Meal'}
          : _extractNames(ingredient ?? {}),
      isCookedLeftover: row['is_cooked_leftover'] as bool? ?? false,
      parentRecipeId: row['parent_recipe_id'] as String?,
      parentRecipeTitle: row['parent_recipe_title'] as String?,
      portionsCount: row['portions_count'] as int? ?? 1,
      caloriesPerPortion: (row['calories_per_portion'] as num?)?.toDouble(),
      proteinPerPortion: (row['protein_per_portion'] as num?)?.toDouble(),
      carbsPerPortion: (row['carbs_per_portion'] as num?)?.toDouble(),
      fatPerPortion: (row['fat_per_portion'] as num?)?.toDouble(),
      dateCooked: row['date_cooked'] != null
          ? DateTime.tryParse(row['date_cooked'].toString())
          : null,
    );
  }

  /// Extract all display_name_* columns into a map.
  static Map<String, String> _extractNames(Map<String, dynamic> data) {
    final names = <String, String>{};
    if (data['display_name_en'] != null) names['en'] = data['display_name_en'];
    if (data['display_name_ko'] != null) names['ko'] = data['display_name_ko'];
    if (data['display_name_uz'] != null) names['uz'] = data['display_name_uz'];
    if (data['display_name_uz_cyrl'] != null) names['uz_cyrl'] = data['display_name_uz_cyrl'];
    if (data['display_name_ru'] != null) names['ru'] = data['display_name_ru'];
    return names;
  }

  /// Resolve the display name for the given BuildContext locale.
  String localizedName(BuildContext context) {
    if (localizedNames.isEmpty) return name;
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    final isUzCyrillic = lang == 'uz' && locale.scriptCode == 'Cyrl';

    if (isUzCyrillic) {
      return localizedNames['uz_cyrl'] ?? localizedNames['uz'] ?? localizedNames['en'] ?? name;
    }
    switch (lang) {
      case 'ko': return localizedNames['ko'] ?? localizedNames['en'] ?? name;
      case 'uz': return localizedNames['uz'] ?? localizedNames['en'] ?? name;
      case 'ru': return localizedNames['ru'] ?? localizedNames['en'] ?? name;
      default:  return localizedNames['en'] ?? name;
    }
  }
}

enum FreshnessState { fresh, aging, urgent, critical, expired }
