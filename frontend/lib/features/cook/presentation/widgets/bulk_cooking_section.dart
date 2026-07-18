/// Plately — Bulk Cooking Section
/// ==================================
/// Widget shown in RecipePrepScreen when servings > 3 or manually toggled.
/// Provides container labeling, storage zone selection, and portions split.
library;

import 'package:flutter/material.dart';

class BulkCookingSection extends StatefulWidget {
  final int servings;
  final ValueChanged<String> onContainerLabelChanged;
  final ValueChanged<String> onStorageZoneChanged;
  final ValueChanged<int> onPortionsToEatNowChanged;
  final String initialContainerLabel;
  final String initialStorageZone;
  final int initialPortionsToEatNow;

  const BulkCookingSection({
    super.key,
    required this.servings,
    required this.onContainerLabelChanged,
    required this.onStorageZoneChanged,
    required this.onPortionsToEatNowChanged,
    this.initialContainerLabel = '',
    this.initialStorageZone = 'fridge',
    this.initialPortionsToEatNow = 1,
  });

  @override
  State<BulkCookingSection> createState() => _BulkCookingSectionState();
}

class _BulkCookingSectionState extends State<BulkCookingSection> {
  late TextEditingController _labelController;
  late String _storageZone;
  late int _eatNow;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialContainerLabel);
    _storageZone = widget.initialStorageZone;
    _eatNow = widget.initialPortionsToEatNow.clamp(1, widget.servings);
  }

  @override
  void didUpdateWidget(covariant BulkCookingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_eatNow >= widget.servings) {
      _eatNow = (widget.servings - 1).clamp(1, widget.servings);
      widget.onPortionsToEatNowChanged(_eatNow);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  int get _toStore => (widget.servings - _eatNow).clamp(0, widget.servings);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ── Info banner ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.12),
                  primary.withValues(alpha: 0.04),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bulk mode activated! We\'ll help you store portions.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Container label ──
          TextField(
            controller: _labelController,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Label containers (e.g., "Blue box — Mon lunch")',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                fontSize: 13,
              ),
              prefixIcon: Icon(Icons.label_outline,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
              filled: true,
              fillColor: surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
            ),
            onChanged: widget.onContainerLabelChanged,
          ),
          const SizedBox(height: 14),

          // ── Storage zone ──
          Row(
            children: [
              _zoneButton(
                icon: Icons.ac_unit,
                label: 'Fridge',
                zone: 'fridge',
                color: Colors.lightBlue,
              ),
              const SizedBox(width: 10),
              _zoneButton(
                icon: Icons.severe_cold,
                label: 'Freezer',
                zone: 'freezer',
                color: Colors.indigo,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Portions split ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                // Eat now
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.restaurant, color: Colors.green, size: 20),
                      const SizedBox(height: 4),
                      Text('Eat now',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _miniButton(Icons.remove, () {
                            if (_eatNow > 1) {
                              setState(() => _eatNow--);
                              widget.onPortionsToEatNowChanged(_eatNow);
                            }
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$_eatNow',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          _miniButton(Icons.add, () {
                            if (_eatNow < widget.servings - 1) {
                              setState(() => _eatNow++);
                              widget.onPortionsToEatNowChanged(_eatNow);
                            }
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 60,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),

                // Store
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.kitchen, color: primary, size: 20),
                      const SizedBox(height: 4),
                      Text('Store',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 6),
                      Text(
                        '$_toStore',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _zoneButton({
    required IconData icon,
    required String label,
    required String zone,
    required Color color,
  }) {
    final selected = _storageZone == zone;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _storageZone = zone);
          widget.onStorageZoneChanged(zone);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}
