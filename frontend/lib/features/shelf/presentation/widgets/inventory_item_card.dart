// Plately — Inventory Item Card Widget
// A single item on the Living Shelf, with freshness overlay,
// expiry badge, and swipe-to-action gestures.

import 'package:flutter/material.dart';
import 'package:plately_app/core/utils/ingredient_icons.dart';
import 'package:plately_app/features/shelf/domain/inventory_item.dart';
import 'package:plately_app/features/shelf/presentation/widgets/freshness_overlay.dart';
import 'package:plately_app/features/shelf/domain/inventory_analytics_service.dart';
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
                return false;
              }

              if (item.daysUntilExpiry < 0) {
                final action = await _showExpiredHumorDialog(context);
                if (action == 'throw_out') {
                  await InventoryAnalyticsService.logEvent(
                    itemId: item.id,
                    itemName: item.name,
                    quantity: selectedQty,
                    unit: item.unit,
                    isExpired: true,
                    thrownOut: true,
                  );
                  await _performDiscard(selectedQty);
                  return true;
                } else if (action != 'eat_anyway') {
                  return false;
                }
              }

              await InventoryAnalyticsService.logEvent(
                itemId: item.id,
                itemName: item.name,
                quantity: selectedQty,
                unit: item.unit,
                isExpired: item.daysUntilExpiry < 0,
                thrownOut: false,
              );

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
                return false;
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error consuming item: $e')),
                  );
                }
                return false;
              }
            } else {
              final selectedQty = await _showDiscardDialog(context);
              if (selectedQty == null || selectedQty <= 0) return false;

              if (isTutorial) {
                final maxQty = item.isCookedLeftover ? item.portionsCount.toDouble() : item.quantity;
                return selectedQty >= maxQty;
              }

              await InventoryAnalyticsService.logEvent(
                itemId: item.id,
                itemName: item.name,
                quantity: selectedQty,
                unit: item.unit,
                isExpired: item.daysUntilExpiry < 0,
                thrownOut: true,
              );

              return await _performDiscard(selectedQty);
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

  Future<bool> _performDiscard(double selectedQty) async {
    try {
      if (item.isCookedLeftover) {
        final newPortions = item.portionsCount - selectedQty.round();
        if (newPortions <= 0) {
          await Supabase.instance.client
              .from('inventory_items')
              .delete()
              .eq('id', item.id);
          return true;
        } else {
          await Supabase.instance.client
              .from('inventory_items')
              .update({'portions_count': newPortions})
              .eq('id', item.id);
          return false;
        }
      } else {
        final newQty = item.quantity - selectedQty;
        if (newQty <= 0) {
          await Supabase.instance.client
              .from('inventory_items')
              .delete()
              .eq('id', item.id);
          return true;
        } else {
          await Supabase.instance.client
              .from('inventory_items')
              .update({'quantity': newQty})
              .eq('id', item.id);
          return false;
        }
      }
    } catch (_) {
      return false;
    }
  }

  static const List<Map<String, String>> _expiredQuotes = [
    {
      'uz': 'Tushlik qilmoqchimisiz yoki yangi pandemiya boshlamoqchimisiz? 🦠',
      'en': 'Are you trying to eat lunch, or start a new pandemic? 🦠',
    },
    {
      'uz': 'Bu mahsulot ba\'zi munosabatlaringizdan ham qadimiyroq. Yaxshisi tashlab yuboring! 🦖',
      'en': 'That food is older than some of your relationships. Throw it out. 🦖',
    },
    {
      'uz': 'Oddiy ovqat yeyapmizmi yoki biologik tajriba o\'tkazyapmizmi? 🧪',
      'en': 'Are we eating leftovers, or are we conducting a biology experiment? 🧪',
    },
    {
      'uz': 'Buni yegan odamga temir oshqozon kerak. Oshqozoningizga rahmingiz kelsin! ☣️',
      'en': 'You need a stomach of steel for this. Pity your poor tummy! ☣️',
    },
  ];

  Future<String?> _showExpiredHumorDialog(BuildContext context) async {
    final uz = Localizations.localeOf(context).languageCode == 'uz';
    final quote = _expiredQuotes[DateTime.now().millisecondsSinceEpoch % _expiredQuotes.length][uz ? 'uz' : 'en']!;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🧪', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                uz ? 'Biologik tajriba?' : 'Expired Food Alert!',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      uz
                          ? 'Ushbu qaror "Oshqozon og\'rig\'i xavfi" yoki "Oziq-ovqat isrofi" analitikasiga yoziladi.'
                          : 'Logged to "Tummy Hurt Risk" or "Food Waste" metrics.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, 'throw_out'),
            icon: const Icon(Icons.delete_outline, color: Colors.green),
            label: Text(
              uz ? 'Tashlab yuborish (Oqilona!)' : 'Throw Out (Wise Choice)',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, 'eat_anyway'),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(Icons.warning_amber_rounded, size: 18),
            label: Text(
              uz ? 'Bari bir yeyman (Tavakkal!)' : 'Eat Anyway (Risk it!)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  double get _stepSize {
    final u = item.unit.toLowerCase();
    if (u == 'g' || u == 'ml') return 10.0;
    if (u == 'kg' || u == 'l') return 0.1;
    return 1.0;
  }

  void _showQuantityEditDialog(BuildContext context, double currentVal, String unit, Function(double) onSaved) {
    final ctrl = TextEditingController(
      text: currentVal == currentVal.roundToDouble()
          ? currentVal.round().toString()
          : currentVal.toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          Localizations.localeOf(context).languageCode == 'uz' ? 'Miqdorni kiritish' : 'Enter Quantity',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: unit,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)?.auto_cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (val != null && val > 0) {
                onSaved(val);
              }
              Navigator.pop(ctx);
            },
            child: Text(Localizations.localeOf(context).languageCode == 'uz' ? 'Saqlash' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<double?> _showConsumeDialog(BuildContext context) async {
    double selectedQty = item.isCookedLeftover ? 1.0 : 1.0;
    if (!item.isCookedLeftover && item.quantity < 1.0) {
      selectedQty = item.quantity;
    }
    final maxQty = item.isCookedLeftover ? item.portionsCount.toDouble() : item.quantity;
    final step = item.isCookedLeftover ? 1.0 : _stepSize;

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
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedQty <= step
                            ? null
                            : () => setDialogState(
                                () => selectedQty = (selectedQty - step).clamp(0.1, maxQty)),
                        icon: const Icon(Icons.remove_circle_outline, size: 34),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showQuantityEditDialog(
                            context,
                            selectedQty,
                            item.isCookedLeftover ? 'portions' : item.unit,
                            (val) => setDialogState(() => selectedQty = val.clamp(0.1, maxQty)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.isCookedLeftover
                                    ? '${selectedQty.round()} portion${selectedQty.round() > 1 ? "s" : ""}'
                                    : '${selectedQty.toStringAsFixed(selectedQty == selectedQty.roundToDouble() ? 0 : 1)} ${item.unit}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.edit_outlined,
                                  size: 16, color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: selectedQty + step > maxQty
                            ? null
                            : () => setDialogState(
                                () => selectedQty = (selectedQty + step).clamp(0.1, maxQty)),
                        icon: const Icon(Icons.add_circle_outline, size: 34),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _dialogPortionChip(context, '25%', maxQty * 0.25, (v) => setDialogState(() => selectedQty = v)),
                      const SizedBox(width: 6),
                      _dialogPortionChip(context, '50%', maxQty * 0.50, (v) => setDialogState(() => selectedQty = v)),
                      const SizedBox(width: 6),
                      _dialogPortionChip(context, '75%', maxQty * 0.75, (v) => setDialogState(() => selectedQty = v)),
                      const SizedBox(width: 6),
                      _dialogPortionChip(context, '100%', maxQty, (v) => setDialogState(() => selectedQty = v)),
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
    final step = item.isCookedLeftover ? 1.0 : _stepSize;

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
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedQty <= step
                            ? null
                            : () => setDialogState(
                                () => selectedQty = (selectedQty - step).clamp(0.1, maxQty)),
                        icon: const Icon(Icons.remove_circle_outline, size: 34),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showQuantityEditDialog(
                            context,
                            selectedQty,
                            item.isCookedLeftover ? 'portions' : item.unit,
                            (val) => setDialogState(() => selectedQty = val.clamp(0.1, maxQty)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.redAccent.withValues(alpha: 0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.isCookedLeftover
                                    ? '${selectedQty.round()} portion${selectedQty.round() > 1 ? "s" : ""}'
                                    : '${selectedQty.toStringAsFixed(selectedQty == selectedQty.roundToDouble() ? 0 : 1)} ${item.unit}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_outlined, size: 16, color: Colors.redAccent),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: selectedQty + step > maxQty
                            ? null
                            : () => setDialogState(
                                () => selectedQty = (selectedQty + step).clamp(0.1, maxQty)),
                        icon: const Icon(Icons.add_circle_outline, size: 34),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _dialogPortionChip(context, '25%', maxQty * 0.25, (v) => setDialogState(() => selectedQty = v)),
                      const SizedBox(width: 6),
                      _dialogPortionChip(context, '50%', maxQty * 0.50, (v) => setDialogState(() => selectedQty = v)),
                      const SizedBox(width: 6),
                      _dialogPortionChip(context, '75%', maxQty * 0.75, (v) => setDialogState(() => selectedQty = v)),
                      const SizedBox(width: 6),
                      _dialogPortionChip(context, '100%', maxQty, (v) => setDialogState(() => selectedQty = v)),
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

  Widget _dialogPortionChip(BuildContext context, String label, double targetVal, Function(double) onSelected) {
    return Expanded(
      child: InkWell(
        onTap: () {
          final rounded = targetVal < 1 ? double.parse(targetVal.toStringAsFixed(1)) : targetVal.roundToDouble();
          onSelected(rounded.clamp(0.1, double.infinity));
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
