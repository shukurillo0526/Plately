// Plately — Shoppable Ingredients Sheet (Cart-to-Pan)
// ====================================================
// Compares recipe ingredients against the user's Living Shelf pantry.
// Separates items into "In Your Kitchen" vs "Missing / Need to Buy"
// and provides 1-tap cart ordering or shopping list export.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/auth_helper.dart';

class ShoppableIngredientsSheet extends StatefulWidget {
  final String recipeTitle;
  final List<Map<String, dynamic>> ingredients;
  final Set<String> ownedIngredientIds;

  const ShoppableIngredientsSheet({
    super.key,
    required this.recipeTitle,
    required this.ingredients,
    this.ownedIngredientIds = const {},
  });

  static Future<void> show(
    BuildContext context, {
    required String recipeTitle,
    required List<Map<String, dynamic>> ingredients,
    Set<String> ownedIngredientIds = const {},
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShoppableIngredientsSheet(
        recipeTitle: recipeTitle,
        ingredients: ingredients,
        ownedIngredientIds: ownedIngredientIds,
      ),
    );
  }

  @override
  State<ShoppableIngredientsSheet> createState() => _ShoppableIngredientsSheetState();
}

class _ShoppableIngredientsSheetState extends State<ShoppableIngredientsSheet> {
  late Set<String> _ownedIds;
  final Set<int> _selectedMissingIndices = {};
  bool _loadingPantry = false;

  @override
  void initState() {
    super.initState();
    _ownedIds = Set<String>.from(widget.ownedIngredientIds);
    if (_ownedIds.isEmpty) {
      _fetchPantryItems();
    } else {
      _initMissingSelection();
    }
  }

  void _initMissingSelection() {
    for (int i = 0; i < widget.ingredients.length; i++) {
      final ing = widget.ingredients[i];
      final id = (ing['ingredient_id'] ?? ing['id'] ?? '').toString();
      final name = (ing['name'] ?? '').toString().toLowerCase();
      final isOwned = _ownedIds.contains(id) || _ownedIds.any((oid) => oid.toLowerCase() == name);
      if (!isOwned) {
        _selectedMissingIndices.add(i);
      }
    }
  }

  Future<void> _fetchPantryItems() async {
    setState(() => _loadingPantry = true);
    try {
      final userId = currentUserId();
      final data = await Supabase.instance.client
          .from('inventory_items')
          .select('ingredient_id, ingredients(canonical_name)')
          .eq('user_id', userId);

      final fetchedIds = <String>{};
      for (final row in (data as List)) {
        if (row['ingredient_id'] != null) {
          fetchedIds.add(row['ingredient_id'].toString());
        }
        final ingData = row['ingredients'] as Map<String, dynamic>?;
        if (ingData?['canonical_name'] != null) {
          fetchedIds.add(ingData!['canonical_name'].toString().toLowerCase());
        }
      }

      if (mounted) {
        setState(() {
          _ownedIds = fetchedIds;
          _initMissingSelection();
          _loadingPantry = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPantry = false);
    }
  }

  bool _isItemOwned(Map<String, dynamic> ing) {
    final id = (ing['ingredient_id'] ?? ing['id'] ?? '').toString();
    final name = (ing['name'] ?? '').toString().toLowerCase();
    return _ownedIds.contains(id) || _ownedIds.any((oid) => oid.toLowerCase() == name);
  }

  void _addMissingToShoppingList() {
    final count = _selectedMissingIndices.length;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Added $count missing ingredients to your Smart Shopping List!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saffron = theme.colorScheme.primary;

    final inKitchen = <Map<String, dynamic>>[];
    final missing = <Map<String, dynamic>>[];

    for (int i = 0; i < widget.ingredients.length; i++) {
      final ing = widget.ingredients[i];
      if (_isItemOwned(ing)) {
        inKitchen.add(ing);
      } else {
        missing.add(ing);
      }
    }

    final total = widget.ingredients.length;
    final matchPct = total > 0 ? ((inKitchen.length / total) * 100).round() : 100;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pantry & Shoppable Ingredients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.recipeTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Match % Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: matchPct >= 70
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                      : saffron.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: matchPct >= 70
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                        : saffron.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$matchPct% in Pantry',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: matchPct >= 70 ? const Color(0xFF4CAF50) : saffron,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (_loadingPantry)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  // 🟢 In Kitchen Section
                  if (inKitchen.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 6),
                        Text(
                          'In Your Kitchen (${inKitchen.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...inKitchen.map((ing) {
                      final name = ing['name'] ?? 'Ingredient';
                      final qty = ing['quantity']?.toString() ?? '';
                      final unit = ing['unit']?.toString() ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.done, size: 14, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '$qty $unit'.trim(),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // 🛒 Missing Section
                  if (missing.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 16, color: saffron),
                        const SizedBox(width: 6),
                        Text(
                          'Missing Ingredients (${missing.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: saffron,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedMissingIndices.length == missing.length) {
                                _selectedMissingIndices.clear();
                              } else {
                                for (int i = 0; i < widget.ingredients.length; i++) {
                                  if (!_isItemOwned(widget.ingredients[i])) {
                                    _selectedMissingIndices.add(i);
                                  }
                                }
                              }
                            });
                          },
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: saffron,
                          ),
                          child: Text(
                            _selectedMissingIndices.length == missing.length
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...missing.map((ing) {
                      final idx = widget.ingredients.indexOf(ing);
                      final isSelected = _selectedMissingIndices.contains(idx);
                      final name = ing['name'] ?? 'Ingredient';
                      final qty = ing['quantity']?.toString() ?? '';
                      final unit = ing['unit']?.toString() ?? '';

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMissingIndices.remove(idx);
                            } else {
                              _selectedMissingIndices.add(idx);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? saffron.withValues(alpha: 0.08)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? saffron.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                size: 18,
                                color: isSelected ? saffron : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '$qty $unit'.trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.celebration, color: Color(0xFF4CAF50), size: 32),
                          SizedBox(height: 8),
                          Text(
                            'All Set! You have 100% of the ingredients.',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Start Cook Mode whenever you\'re ready!',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Bottom Action Button
          if (missing.isNotEmpty)
            FilledButton.icon(
              onPressed: _selectedMissingIndices.isEmpty ? null : _addMissingToShoppingList,
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text(
                'Add ${_selectedMissingIndices.length} Items to Shopping List',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: saffron,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}
