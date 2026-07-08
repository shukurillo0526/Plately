// Plately — Inventory Item Card Widget
// A single item on the Living Shelf, with freshness overlay,
// expiry badge, and swipe-to-action gestures.

import 'package:flutter/material.dart';
import 'package:plately_app/core/utils/ingredient_icons.dart';
import 'package:plately_app/features/shelf/domain/inventory_item.dart';
import 'package:plately_app/features/shelf/presentation/widgets/freshness_overlay.dart';
import 'package:plately_app/l10n/app_localizations.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onMarkOpened;
  final VoidCallback? onRemove;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMarkOpened,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = item.freshnessState == FreshnessState.expired;
    final isUrgent = item.freshnessState == FreshnessState.critical ||
        item.freshnessState == FreshnessState.urgent;

    return UrgencyPulse(
      isUrgent: isUrgent,
      child: GestureDetector(
        onTap: onTap,
        child: Dismissible(
          key: Key(item.id),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 20),
            child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onSurface, size: 30),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onSurface, size: 30),
          ),
          confirmDismiss: (direction) async {
            final isTutorial = item.id.startsWith('tutorial');

            if (direction == DismissDirection.startToEnd) {
              final selectedQty = await _showConsumeDialog(context);
              if (selectedQty == null || selectedQty <= 0) return false;

              if (isTutorial) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logged ${selectedQty.round()} portion(s) for tutorial item: ${item.name}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                return false; // snap back
              }

              // Use selectedQty / Eat Leftover portions via RPC
              try {
                if (item.isCookedLeftover) {
                  for (int i = 0; i < selectedQty.round(); i++) {
                    await Supabase.instance.client.rpc('eat_leftover_portion', params: {
                      'p_user_id': Supabase.instance.client.auth.currentUser?.id,
                      'p_inventory_id': item.id,
                    });
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged ${selectedQty.round()} leftover portion(s) for: ${item.name}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  await Supabase.instance.client.rpc('consume_inventory_item', params: {
                    'p_inventory_id': item.id,
                    'p_qty_to_consume': selectedQty,
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged consumption of ${selectedQty.toStringAsFixed(selectedQty == selectedQty.roundToDouble() ? 0 : 1)} ${item.unit} ${item.name}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
                return false; // Snap back, UI updates from realtime stream
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error consuming item: $e')),
                  );
                }
                return false;
              }
            } else {
              // Discard Dialog
              final selectedQty = await _showDiscardDialog(context);
              if (selectedQty == null || selectedQty <= 0) return false;

              if (isTutorial) {
                final maxQty = item.isCookedLeftover ? item.portionsCount.toDouble() : item.quantity;
                return selectedQty >= maxQty; // slide away if fully discarded, else snap back
              }

              try {
                if (item.isCookedLeftover) {
                  final newPortions = item.portionsCount - selectedQty.round();
                  if (newPortions <= 0) {
                    await Supabase.instance.client
                        .from('inventory_items')
                        .delete()
                        .eq('id', item.id);
                    return true; // slide away
                  } else {
                    await Supabase.instance.client
                        .from('inventory_items')
                        .update({'portions_count': newPortions})
                        .eq('id', item.id);
                    return false; // snap back and update quantity
                  }
                } else {
                  final newQty = item.quantity - selectedQty;
                  if (newQty <= 0) {
                    await Supabase.instance.client
                        .from('inventory_items')
                        .delete()
                        .eq('id', item.id);
                    return true; // slide away
                  } else {
                    await Supabase.instance.client
                        .from('inventory_items')
                        .update({'quantity': newQty})
                        .eq('id', item.id);
                    return false; // snap back and update quantity
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error discarding item: $e')),
                  );
                }
                return false;
              }
            }
          },
          child: Stack(
            children: [
              // --- Card Body ---
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Icon / Image Area ---
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.isCookedLeftover
                                ? '🍽️'
                                : IngredientIcons.getEmoji(
                                    item.name,
                                    category: item.category,
                                  ),
                            style: TextStyle(
                              fontSize: 44,
                              color: isExpired
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- Info Area ---
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.localizedName(context),
                              style: TextStyle(
                                color: isExpired
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                                    : Theme.of(context).colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: isExpired
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 3),
                            Text(
                              _expiryLabel(context),
                              style: TextStyle(
                                color: _expiryLabelColor(context),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Freshness Overlay ---
              Positioned.fill(
                child: FreshnessOverlay(freshnessRatio: item.freshnessRatio),
              ),

              // --- Quantity Badge ---
              if (item.quantity > 0) 
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isCookedLeftover
                          ? '${item.portionsCount} portion${item.portionsCount > 1 ? 's' : ''}'
                          : '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} ${item.unit}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // --- State Badge (opened / frozen / leftover) ---
              if (item.isCookedLeftover || item.itemState != 'sealed')
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (item.isCookedLeftover
                              ? (item.daysUntilExpiry < 0 ? Colors.red : Colors.green)
                              : _stateBadgeColor(context))
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.isCookedLeftover
                          ? (item.daysUntilExpiry < 0 ? 'SPOILED' : 'LEFTOVER')
                          : _stateBadgeLabel(context),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _expiryLabel(BuildContext context) {
    final days = item.daysUntilExpiry;
    final l10n = AppLocalizations.of(context);
    if (days < 0) return l10n?.expired ?? 'Expired';
    if (days == 0) return l10n?.expiringSoon ?? 'Use today!';
    if (days == 1) return '1d';
    if (days <= 7) return '${days}d';
    return '${(days / 7).floor()}w';
  }

  Color _expiryLabelColor(BuildContext context) {
    switch (item.freshnessState) {
      case FreshnessState.fresh:
        return Theme.of(context).colorScheme.tertiary;
      case FreshnessState.aging:
        return Theme.of(context).colorScheme.secondary;
      case FreshnessState.urgent:
        return Theme.of(context).colorScheme.primary;
      case FreshnessState.critical:
        return Theme.of(context).colorScheme.error;
      case FreshnessState.expired:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }

  String _stateBadgeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (item.itemState) {
      case 'opened':
        return l10n?.inv_stateOpened ?? 'OPENED';
      case 'partially_used':
        return l10n?.inv_statePartial ?? 'PARTIAL';
      case 'frozen':
        return l10n?.inv_stateFrozen ?? 'FROZEN';
      case 'thawed':
        return l10n?.inv_stateThawed ?? 'THAWED';
      default:
        return '';
    }
  }

  Color _stateBadgeColor(BuildContext context) {
    switch (item.itemState) {
      case 'opened':
        return Theme.of(context).colorScheme.secondary;
      case 'frozen':
        return Theme.of(context).colorScheme.secondary;
      case 'thawed':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    }
  }

  Future<double?> _showConsumeDialog(BuildContext context) async {
    double selectedQty = item.isCookedLeftover ? 1.0 : 1.0;
    if (!item.isCookedLeftover && item.quantity < 1.0) {
      selectedQty = item.quantity;
    }
    final maxQty = item.isCookedLeftover ? item.portionsCount.toDouble() : item.quantity;
    final step = item.isCookedLeftover ? 1.0 : (item.unit == 'pcs' ? 1.0 : 0.1);

    return showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                item.isCookedLeftover ? 'Eat Leftover Portions' : 'Consume ${item.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How much are you consuming? (Max: ${item.isCookedLeftover ? "${item.portionsCount} portions" : "${item.quantity.toStringAsFixed(1)} ${item.unit}"})',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedQty <= step
                            ? null
                            : () => setDialogState(() => selectedQty -= step),
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.isCookedLeftover
                              ? '${selectedQty.round()} portion${selectedQty.round() > 1 ? "s" : ""}'
                              : '${selectedQty.toStringAsFixed(selectedQty == selectedQty.roundToDouble() ? 0 : 1)} ${item.unit}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: selectedQty + step > maxQty
                            ? null
                            : () => setDialogState(() => selectedQty += step),
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, selectedQty),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<double?> _showDiscardDialog(BuildContext context) async {
    double selectedQty = item.isCookedLeftover ? 1.0 : 1.0;
    if (!item.isCookedLeftover && item.quantity < 1.0) {
      selectedQty = item.quantity;
    }
    final maxQty = item.isCookedLeftover ? item.portionsCount.toDouble() : item.quantity;
    final step = item.isCookedLeftover ? 1.0 : (item.unit == 'pcs' ? 1.0 : 0.1);

    return showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Discard Ingredient',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Are you sure you want to throw away this item? How much are you throwing away?',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedQty <= step
                            ? null
                            : () => setDialogState(() => selectedQty -= step),
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.isCookedLeftover
                              ? '${selectedQty.round()} portion${selectedQty.round() > 1 ? "s" : ""}'
                              : '${selectedQty.toStringAsFixed(selectedQty == selectedQty.roundToDouble() ? 0 : 1)} ${item.unit}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: selectedQty + step > maxQty
                            ? null
                            : () => setDialogState(() => selectedQty += step),
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, selectedQty),
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('Discard'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
