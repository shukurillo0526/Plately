// Plately — Flavor Profile Deep Page
// =====================================
// Full-screen view of the user's flavor preferences.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/theme/app_theme.dart';
import 'package:plately_app/core/services/auth_helper.dart';

class FlavorProfilePage extends StatefulWidget {
  const FlavorProfilePage({super.key});
  @override
  State<FlavorProfilePage> createState() => _FlavorProfilePageState();
}

class _FlavorProfilePageState extends State<FlavorProfilePage> {
  Map<String, double> _flavors = {};
  bool _loading = true;

  final _flavorMeta = {
    'sweet': {'emoji': '🍯', 'color': Colors.amber},
    'salty': {'emoji': '🧂', 'color': Colors.blue},
    'spicy': {'emoji': '🌶️', 'color': Colors.red},
    'sour': {'emoji': '🍋', 'color': Colors.lime},
    'umami': {'emoji': '🍖', 'color': Colors.deepOrange},
    'bitter': {'emoji': '🍵', 'color': Colors.teal},
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final uid = currentUserId();
      final row = await Supabase.instance.client
          .from('user_flavor_profile').select().eq('user_id', uid).maybeSingle();
      if (row != null) {
        _flavors = {
          'sweet': (row['sweet'] ?? 0).toDouble(),
          'salty': (row['salty'] ?? 0).toDouble(),
          'spicy': (row['spicy'] ?? 0).toDouble(),
          'sour': (row['sour'] ?? 0).toDouble(),
          'umami': (row['umami'] ?? 0).toDouble(),
          'bitter': (row['bitter'] ?? 0).toDouble(),
        };
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Flavor Profile', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _flavors.isEmpty
              ? Center(child: Text('Cook more recipes to build your flavor profile!',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))))
              : ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                    // Radar chart placeholder
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06))),
                      child: CustomPaint(
                        painter: _RadarPainter(
                          _flavors,
                          gridColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          textColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          accentColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: Center(child: Text('🍳', style: TextStyle(fontSize: 32))),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Detailed bars
                    ..._flavors.entries.map((e) {
                      final meta = _flavorMeta[e.key];
                      final color = (meta?['color'] as Color?) ?? Theme.of(context).colorScheme.onSurface;
                      final emoji = (meta?['emoji'] as String?) ?? '❓';
                      final pct = (e.value / 100).clamp(0.0, 1.0);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('$emoji  ${e.key.isEmpty ? '' : e.key[0].toUpperCase() + e.key.substring(1)}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                                Spacer(),
                                Text('${e.value.toInt()}%',
                                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct, minHeight: 10,
                                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation(color)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> data;
  final Color gridColor;
  final Color textColor;
  final Color accentColor;

  _RadarPainter(this.data, {
    required this.gridColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2.5; // Radius of the radar
    final keys = data.keys.toList();
    final values = data.values.toList();
    final n = values.length;
    if (n == 0) return;

    // Grid
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 3; ring++) {
      final rr = r * ring / 3;
      final path = Path();
      for (int i = 0; i <= n; i++) {
        final a = -math.pi / 2 + 2 * math.pi * (i % n) / n;
        final pt = Offset(center.dx + rr * math.cos(a), center.dy + rr * math.sin(a));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, gridPaint);
    }

    // Axes
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final pt = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      canvas.drawLine(center, pt, gridPaint);
    }

    // Data polygon
    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dataPath = Path();
    for (int i = 0; i <= n; i++) {
      final v = (values[i % n] / 100).clamp(0.0, 1.0);
      final a = -math.pi / 2 + 2 * math.pi * (i % n) / n;
      final pt = Offset(center.dx + r * v * math.cos(a), center.dy + r * v * math.sin(a));
      i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final labelRadius = r + 20; // push label outside the grid
      final pt = Offset(center.dx + labelRadius * math.cos(a), center.dy + labelRadius * math.sin(a));
      
      final label = keys[i];
      final capitalized = label.isEmpty ? '' : label[0].toUpperCase() + label.substring(1);
      
      textPainter.text = TextSpan(
        text: capitalized,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pt.dx - textPainter.width / 2, pt.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
