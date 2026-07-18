/// Plately — Meal Prep Config Panel
/// ===================================
/// Configuration widget for bulk cooking meal prep plans.
/// Shows days, meals/day, macro presets, and target sliders.
library;

import 'package:flutter/material.dart';

/// Data class for meal prep configuration values.
class MealPrepConfig {
  final int days;
  final int mealsPerDay;
  final int targetCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;

  const MealPrepConfig({
    this.days = 5,
    this.mealsPerDay = 3,
    this.targetCalories = 500,
    this.targetProteinG = 30,
    this.targetCarbsG = 40,
    this.targetFatG = 15,
  });
}

class MealPrepConfigPanel extends StatefulWidget {
  final ValueChanged<MealPrepConfig> onConfigChanged;
  final MealPrepConfig? initialConfig;

  const MealPrepConfigPanel({
    super.key,
    required this.onConfigChanged,
    this.initialConfig,
  });

  @override
  State<MealPrepConfigPanel> createState() => _MealPrepConfigPanelState();
}

class _MealPrepConfigPanelState extends State<MealPrepConfigPanel> {
  late int _days;
  late int _mealsPerDay;
  late int _targetCalories;
  late double _targetProteinG;
  late double _targetCarbsG;
  late double _targetFatG;
  int? _selectedPresetIndex;

  static const _presets = [
    {'label': 'High Protein', 'icon': Icons.fitness_center, 'cal': 500, 'p': 45.0, 'c': 30.0, 'f': 15.0},
    {'label': 'Balanced', 'icon': Icons.balance, 'cal': 500, 'p': 30.0, 'c': 50.0, 'f': 20.0},
    {'label': 'Low Carb', 'icon': Icons.trending_down, 'cal': 450, 'p': 35.0, 'c': 20.0, 'f': 25.0},
    {'label': 'Muscle Gain', 'icon': Icons.sports_gymnastics, 'cal': 600, 'p': 50.0, 'c': 55.0, 'f': 20.0},
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initialConfig ?? const MealPrepConfig();
    _days = c.days;
    _mealsPerDay = c.mealsPerDay;
    _targetCalories = c.targetCalories;
    _targetProteinG = c.targetProteinG;
    _targetCarbsG = c.targetCarbsG;
    _targetFatG = c.targetFatG;
  }

  void _notify() {
    widget.onConfigChanged(MealPrepConfig(
      days: _days,
      mealsPerDay: _mealsPerDay,
      targetCalories: _targetCalories,
      targetProteinG: _targetProteinG,
      targetCarbsG: _targetCarbsG,
      targetFatG: _targetFatG,
    ));
  }

  void _applyPreset(int index) {
    final p = _presets[index];
    setState(() {
      _selectedPresetIndex = index;
      _targetCalories = p['cal'] as int;
      _targetProteinG = p['p'] as double;
      _targetCarbsG = p['c'] as double;
      _targetFatG = p['f'] as double;
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Days selector ──
        _optionRow(
          'Days',
          Row(
            children: [3, 5, 7].map((d) {
              final selected = _days == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _days = d);
                    _notify();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? primary : surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '$d',
                      style: TextStyle(
                        color: selected ? Colors.black : theme.colorScheme.onSurface,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // ── Meals per day ──
        _optionRow(
          'Meals/Day',
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _mealsPerDay,
              dropdownColor: surface,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
              items: const [
                DropdownMenuItem(value: 2, child: Text('2 meals')),
                DropdownMenuItem(value: 3, child: Text('3 meals')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _mealsPerDay = v);
                  _notify();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Macro presets ──
        Text('Target Macros',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_presets.length, (i) {
              final p = _presets[i];
              final selected = _selectedPresetIndex == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _applyPreset(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? primary.withValues(alpha: 0.15) : surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(p['icon'] as IconData, size: 14,
                            color: selected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          p['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // ── Calories slider ──
        _sliderRow(
          Icons.local_fire_department,
          '$_targetCalories kcal/meal',
          Colors.deepOrange,
          _targetCalories.toDouble(),
          300,
          800,
          10,
          (v) {
            setState(() {
              _targetCalories = v.round();
              _selectedPresetIndex = null;
            });
            _notify();
          },
        ),

        // ── Protein slider ──
        _sliderRow(
          Icons.fitness_center,
          '${_targetProteinG.round()}g protein',
          Colors.blueAccent,
          _targetProteinG,
          10,
          60,
          10,
          (v) {
            setState(() {
              _targetProteinG = v;
              _selectedPresetIndex = null;
            });
            _notify();
          },
        ),

        // ── Carbs slider ──
        _sliderRow(
          Icons.bolt,
          '${_targetCarbsG.round()}g carbs',
          Colors.amber,
          _targetCarbsG,
          10,
          80,
          14,
          (v) {
            setState(() {
              _targetCarbsG = v;
              _selectedPresetIndex = null;
            });
            _notify();
          },
        ),

        // ── Fat slider ──
        _sliderRow(
          Icons.water_drop,
          '${_targetFatG.round()}g fat',
          Colors.orangeAccent,
          _targetFatG,
          5,
          40,
          7,
          (v) {
            setState(() {
              _targetFatG = v;
              _selectedPresetIndex = null;
            });
            _notify();
          },
        ),
      ],
    );
  }

  Widget _optionRow(String label, Widget child) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _sliderRow(
    IconData icon,
    String label,
    Color color,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.15),
                thumbColor: color,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
