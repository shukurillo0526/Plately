// Plately — Nutrition Tracker Deep Page
// ========================================
// Daily calorie ring, macro bars, and meal log history.

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionTrackerPage extends StatefulWidget {
  const NutritionTrackerPage({super.key});
  @override
  State<NutritionTrackerPage> createState() => _NutritionTrackerPageState();
}

class _NutritionTrackerPageState extends State<NutritionTrackerPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _daily;
  List<dynamic> _history = [];
  bool _loading = true;

  // Progressive profiling: age & weight prompt
  bool _showProfilePrompt = false;
  bool _profilePromptDismissed = false;
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  bool _savingProfile = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final uid = currentUserId();
      final result = await _api.getDailyNutrition(uid);
      
      final supabase = Supabase.instance.client;

      // Check if age/weight are set
      final userData = await supabase
          .from('users')
          .select('age, weight_kg')
          .eq('id', uid)
          .maybeSingle();

      final historyData = await supabase
          .from('user_recipe_history')
          .select('cooked_at, recipes(id, title, image_url, calories_per_serving)')
          .eq('user_id', uid)
          .order('cooked_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() { 
          _daily = result; 
          _history = historyData as List<dynamic>;
          _loading = false;
          // Show prompt if age or weight is missing
          _showProfilePrompt = (userData?['age'] == null || userData?['weight_kg'] == null);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfileData() async {
    final age = int.tryParse(_ageController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (age == null || weight == null || age < 10 || age > 120 || weight < 20 || weight > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid age (10-120) and weight (20-300 kg)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _savingProfile = true);
    try {
      await Supabase.instance.client.from('users').update({
        'age': age,
        'weight_kg': weight,
      }).eq('id', currentUserId());

      if (mounted) {
        setState(() {
          _showProfilePrompt = false;
          _savingProfile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated! Nutrition goals personalized.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingProfile = false);
        debugPrint('[NutritionTracker] Failed to save profile: $e');
      }
    }
  }

  @override
  void dispose() { 
    _api.dispose(); 
    _ageController.dispose();
    _weightController.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Nutrition Tracker', style: TextStyle(fontWeight: FontWeight.w700))),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.all(20),
                children: [
                  // Progressive profiling: age/weight prompt
                  if (_showProfilePrompt && !_profilePromptDismissed)
                    _buildProfilePrompt(),

                  // Calorie Ring
                  _buildCalorieRing(),
                  SizedBox(height: 24),

                  // Macro Bars
                  _buildMacroBars(),
                  SizedBox(height: 24),

                  // Meal Log
                  Text('Today\'s Meals',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 12),
                  _buildMealLog(),
                  SizedBox(height: 32),

                  // Cooking History
                  Text('Cooking History',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 12),
                  _buildCookingHistory(),
                  SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfilePrompt() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Theme.of(context).colorScheme.primary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Personalize Your Nutrition Goals',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _profilePromptDismissed = true),
                child: Icon(Icons.close, size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'For accurate calorie and macro goals, tell us a bit about yourself.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    hintText: 'e.g. 25',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 70',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _savingProfile ? null : _saveProfileData,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: _savingProfile
                  ? SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRing() {
    final totals = _daily?['totals'] as Map<String, dynamic>? ?? {};
    final consumed = (totals['calories'] ?? 0).toDouble();
    final goal = (_daily?['goal'] ?? 2000).toDouble();
    final pct = (consumed / goal).clamp(0.0, 1.5);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06))),
      child: Column(
        children: [
          SizedBox(
            width: 180, height: 180,
            child: CustomPaint(
              painter: _RingPainter(pct, pct > 1.0 ? Colors.red : Colors.orange),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${consumed.toInt()}',
                      style: TextStyle(color: Colors.orange, fontSize: 36, fontWeight: FontWeight.w800)),
                    Text('/ ${goal.toInt()} cal',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(pct > 1.0 ? '⚠️ Over goal!' : '${((1.0 - pct) * goal).toInt()} cal remaining',
            style: TextStyle(
              color: pct > 1.0 ? Colors.red : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMacroBars() {
    final totals = _daily?['totals'] as Map<String, dynamic>? ?? {};
    final macros = [
      {'label': 'Protein', 'value': totals['protein_g'] ?? 0, 'color': Colors.blue, 'goal': 120},
      {'label': 'Carbs', 'value': totals['carbs_g'] ?? 0, 'color': Colors.amber, 'goal': 250},
      {'label': 'Fat', 'value': totals['fat_g'] ?? 0, 'color': Colors.red, 'goal': 65},
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06))),
      child: Column(
        children: macros.map((m) {
          final pct = ((m['value'] as int) / (m['goal'] as int)).clamp(0.0, 1.0);
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text(m['label'] as String,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 8,
                      backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(m['color'] as Color)),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(width: 70, child: Text('${m['value']}/${m['goal']}g',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: (m['color'] as Color), fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealLog() {
    final meals = (_daily?['meals'] as List?) ?? [];
    if (meals.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('No meals logged today.\nUse Scan Calories to log your food!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)))),
      );
    }
    return Column(
      children: meals.map<Widget>((meal) {
        final type = meal['meal_type'] ?? 'snack';
        final cal = meal['total_calories'] ?? 0;
        final emoji = {'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍿'}[type] ?? '🍽️';
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06))),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Expanded(child: Text('${type[0].toUpperCase()}${type.substring(1)}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600))),
              Text('$cal cal', style: TextStyle(color: Colors.orange, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }
  Widget _buildCookingHistory() {
    if (_history.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('No cooking history yet.\nCook a recipe to start your flavor journey!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)))),
      );
    }
    return Column(
      children: _history.map((h) {
        final r = h['recipes'] as Map<String, dynamic>? ?? {};
        final dateStr = h['cooked_at']?.toString() ?? '';
        final title = r['title'] ?? 'Unknown Recipe';
        final imageUrl = r['image_url'];
        final cal = r['calories_per_serving'] ?? 0;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl.toString().startsWith('http')
                  ? Image.network(imageUrl.toString(), width: 64, height: 64, fit: BoxFit.cover)
                  : Container(
                      width: 64, height: 64, 
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.restaurant, color: Theme.of(context).colorScheme.primary),
                    ),
              ),
              SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text(dateStr.split('T').first, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
              // Calorie chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$cal cal', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 12;
    canvas.drawCircle(center, r, Paint()..color = Colors.white.withValues(alpha: 0.06)..style = PaintingStyle.stroke..strokeWidth = 12);
    final arc = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
