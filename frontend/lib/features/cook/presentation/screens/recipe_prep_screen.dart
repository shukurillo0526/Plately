// Plately — Recipe Prep Screen
// ===============================
// Intermediate screen between recipe detail and cooking.
// Shows ingredient checklist with have/missing status,
// AI substitution suggestions, manual ingredient swaps,
// and serving size scaler with proper math.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/l10n/app_localizations.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/core/utils/unit_converter.dart';
import 'package:plately_app/core/utils/l10n_helper.dart';
import 'package:plately_app/core/utils/ingredient_icons.dart';
import 'package:plately_app/features/cook/presentation/screens/cooking_run_screen.dart';

class RecipePrepScreen extends StatefulWidget {
  final String recipeId;
  final String title;
  final int originalServings;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> steps;
  final List<String>? prepNotes;
  final Set<String> ownedIngredientIds;
  final double matchPct;
  final Color tierColor;
  final int? caloriesPerServing;

  const RecipePrepScreen({
    super.key,
    required this.recipeId,
    required this.title,
    required this.originalServings,
    required this.ingredients,
    required this.steps,
    this.prepNotes,
    required this.ownedIngredientIds,
    required this.matchPct,
    required this.tierColor,
    this.caloriesPerServing,
  });

  @override
  State<RecipePrepScreen> createState() => _RecipePrepScreenState();
}

class _RecipePrepScreenState extends State<RecipePrepScreen> {
  late int _servings;
  final ApiService _api = ApiService();

  // Substitution state: ingredient index → substitution text
  final Map<int, String> _substitutions = {};
  final Map<int, bool> _loadingSub = {};

  // AI chat
  String _aiQuestion = '';
  String? _aiResponse;
  bool _aiLoading = false;
  bool _isBeginnerMode = false;

  @override
  void initState() {
    super.initState();
    _servings = widget.originalServings;
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  double _scaleQuantity(dynamic original) {
    final qty = (original is num) ? original.toDouble() : (double.tryParse('$original') ?? 0);
    return UnitConverter.scale(qty, widget.originalServings, _servings);
  }

  void _incrementServings() => setState(() => _servings = (_servings + 1).clamp(1, 20));
  void _decrementServings() => setState(() => _servings = (_servings - 1).clamp(1, 20));

  Future<void> _editIngredient(int index) async {
    final ing = widget.ingredients[index];
    final nameC = TextEditingController(text: ing['name'] ?? '');
    final qtyC = TextEditingController(text: '${ing['quantity'] ?? ''}');
    final unitC = TextEditingController(text: ing['unit'] ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppLocalizations.of(context)?.editIngredient ?? 'Edit Ingredient', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC, autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)?.nameLabel ?? 'Name', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(
                  controller: qtyC, keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.qtyLabel ?? 'Qty', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: unitC,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.unitLabel ?? 'Unit', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'name': nameC.text.trim(),
              'qty': double.tryParse(qtyC.text) ?? ing['quantity'],
              'unit': unitC.text.trim(),
            }),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: Text('Save')),
        ],
      ),
    );
    if (result == null) return;
    setState(() {
      ing['name'] = result['name'];
      ing['quantity'] = result['qty'];
      ing['unit'] = result['unit'];
    });
  }

  Future<void> _askSubstitute(int index) async {
    final ing = widget.ingredients[index];
    final name = ing['translated_name'] ?? ing['name'] ?? 'Unknown';
    final locale = Localizations.localeOf(context).languageCode;

    setState(() => _loadingSub[index] = true);

    // Build full inventory context so AI knows what user has available
    String fullInventoryText = 'User has: ';
    try {
      final rows = await Supabase.instance.client
          .from('inventory_items')
          .select('quantity, unit, ingredients(display_name_en)')
          .eq('user_id', currentUserId());
          
      final items = (rows as List).map((r) {
        final name = r['ingredients']?['display_name_en'] ?? 'item';
        final qty = r['quantity'] ?? '';
        final unit = r['unit'] ?? '';
        return '$qty $unit $name'.trim();
      }).where((s) => s.isNotEmpty).toList();
      
      fullInventoryText += items.isNotEmpty ? items.join(', ') : 'nothing else';
    } catch (e) {
      debugPrint('Failed to load full inventory for AI context: $e');
      fullInventoryText += 'unknown items';
    }

    final inventoryHint = '${widget.title}. $fullInventoryText';

    try {
      final result = await _api.suggestSubstitute(
        ingredient: name,
        recipeContext: inventoryHint,
        locale: locale,
      );
      final data = result['data'];
      if (data != null && data['substitutes'] != null) {
        final subs = data['substitutes'] as List;
        final text = subs.map((s) => '• ${s['name']} (${s['ratio']}) — ${s['notes']}').join('\n');
        setState(() {
          _substitutions[index] = text;
          _loadingSub[index] = false;
        });
      } else {
        setState(() {
          _substitutions[index] = 'No substitutions found.';
          _loadingSub[index] = false;
        });
      }
    } catch (e) {
      setState(() {
        _substitutions[index] = 'Error: Could not reach AI.';
        _loadingSub[index] = false;
      });
    }
  }

  Future<void> _askAiChat() async {
    if (_aiQuestion.trim().isEmpty || _aiLoading) return;
    setState(() => _aiLoading = true);

    try {
      final locale = Localizations.localeOf(context).languageCode;

      // Build rich context: recipe + ingredients with have/missing + substitutions
      final ingLines = widget.ingredients.asMap().entries.map((entry) {
        final i = entry.key;
        final ing = entry.value;
        final name = ing['translated_name'] ?? ing['name'] ?? 'Unknown';
        final rawQty = ing['quantity'];
        final unit = ing['unit'] ?? '';
        final ingId = ing['ingredient_id'] ?? ing['id'] ?? ing['name'] ?? '';
        final hasIt = widget.ownedIngredientIds.contains(ingId);
        final scaledQty = _scaleQuantity(rawQty);
        final qtyStr = UnitConverter.simplifyMetric(scaledQty, unit);
        final status = hasIt ? '✓ HAVE' : '✗ MISSING';
        final subNote = _substitutions.containsKey(i) ? ' [Substituted]' : '';
        return '- $name $qtyStr ($status)$subNote';
      }).join('\n');

      // Also fetch full inventory so the AI can answer general substitute questions
      String fullInventoryText = '';
      try {
        final rows = await Supabase.instance.client
            .from('inventory_items')
            .select('quantity, unit, ingredients(display_name_en)')
            .eq('user_id', currentUserId());
            
        final items = (rows as List).map((r) {
          final name = r['ingredients']?['display_name_en'] ?? 'item';
          final qty = r['quantity'] ?? '';
          final unit = r['unit'] ?? '';
          return '$qty $unit $name'.trim();
        }).where((s) => s.isNotEmpty).toList();
        
        fullInventoryText = items.isNotEmpty ? '\n\nUSER ENTIRE INVENTORY:\n${items.join(', ')}' : '';
      } catch (e) {
        debugPrint('Failed to load full inventory for AI chat context: $e');
      }

      final contextText = 'Recipe: ${widget.title} (${_servings} servings)\n'
          'Ingredients:\n$ingLines$fullInventoryText';

      final result = await _api.getCookingTip(
        stepText: contextText,
        question: _aiQuestion,
        locale: locale,
      );
      setState(() {
        _aiResponse = result['data']?['tip'] ?? 'No response.';
        _aiLoading = false;
      });
    } catch (e) {
      debugPrint('AI cooking tip error: $e');
      setState(() {
        _aiResponse = 'AI is temporarily unavailable. Please try again later.';
        _aiLoading = false;
      });
    }
  }

  Future<String> _buildUserInventoryText() async {
    final recipeIngs = widget.ingredients.map((ing) {
      final name = ing['translated_name'] ?? ing['name'] ?? 'Unknown';
      final ingId = ing['ingredient_id'] ?? ing['id'] ?? ing['name'] ?? '';
      final rawQty = ing['quantity'];
      final unit = ing['unit'] ?? '';
      final hasIt = widget.ownedIngredientIds.contains(ingId);
      
      final scaledQty = _scaleQuantity(rawQty);
      final qtyStr = UnitConverter.simplifyMetric(scaledQty, unit);
      
      return hasIt ? "$name $qtyStr" : "No $name";
    }).join(', ');

    String fullInventory = '';
    try {
      final rows = await Supabase.instance.client
          .from('inventory_items')
          .select('quantity, unit, ingredients(display_name_en)')
          .eq('user_id', currentUserId());
          
      final items = (rows as List).map((r) {
        final name = r['ingredients']?['display_name_en'] ?? 'item';
        final qty = r['quantity'] ?? '';
        final unit = r['unit'] ?? '';
        return '$qty $unit $name'.trim();
      }).where((s) => s.isNotEmpty).toList();
      
      if (items.isNotEmpty) {
        fullInventory = '\n\nENTIRE INVENTORY: ' + items.join(', ');
      }
    } catch (e) {
      debugPrint('Error getting full inventory for run screen: $e');
    }

    return 'Recipe ingredients context: $recipeIngs$fullInventory';
  }

  Future<void> _startCooking() async {
    final inventoryText = await _buildUserInventoryText();
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CookingRunScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          steps: widget.steps,
          isBeginnerMode: _isBeginnerMode,
          ingredients: widget.ingredients,
          prepNotes: widget.prepNotes,
          matchedIngredientsCount: widget.ownedIngredientIds.length,
          matchPct: widget.matchPct,
          userInventoryText: inventoryText,
          servingsCooked: _servings,
          originalServings: widget.originalServings,
          ownedIngredientIds: widget.ownedIngredientIds,
          calories: widget.caloriesPerServing != null ? (widget.caloriesPerServing! * _servings) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final haveCount = widget.ingredients.where((ing) {
      final id = ing['ingredient_id'] ?? ing['id'] ?? ing['name'];
      return widget.ownedIngredientIds.contains(id);
    }).length;
    final missingCount = widget.ingredients.length - haveCount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(widget.title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // ── Serving Scaler ───────────────────────────
                  Container(
                    margin: EdgeInsets.only(top: 8, bottom: 16),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 20),
                        SizedBox(width: 12),
                        Text(AppLocalizations.of(context)?.servingsLabel ?? 'Servings', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                        Spacer(),
                        IconButton(
                          onPressed: _decrementServings,
                          icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                          iconSize: 28,
                        ),
                        Text('$_servings',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 22, fontWeight: FontWeight.w800)),
                        IconButton(
                          onPressed: _incrementServings,
                          icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                          iconSize: 28,
                        ),
                      ],
                    ),
                  ),

                  // ── Beginner Mode Toggle ───────────────────────
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isBeginnerMode
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
                    ),
                    child: SwitchListTile(
                      value: _isBeginnerMode,
                      onChanged: (v) => setState(() => _isBeginnerMode = v),
                      title: Text(
                        '👨‍🍳 Beginner Mode',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _isBeginnerMode
                            ? 'Detailed step-by-step guidance with tips'
                            : 'Standard cooking instructions',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                      secondary: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isBeginnerMode
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isBeginnerMode ? Icons.school : Icons.restaurant_menu,
                          color: _isBeginnerMode
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  // Scaled calorie info
                  if (widget.caloriesPerServing != null && widget.caloriesPerServing! > 0)
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.withValues(alpha: 0.12), Theme.of(context).colorScheme.surface],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${widget.caloriesPerServing! * _servings} ${L10nHelper.translateNutritionLabel('cal', Localizations.localeOf(context).languageCode)} ${AppLocalizations.of(context)?.auto_total ?? 'total'}',
                                style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.w800)),
                              Text('${widget.caloriesPerServing} ${L10nHelper.translateNutritionLabel('cal', Localizations.localeOf(context).languageCode)} × $_servings ${AppLocalizations.of(context)?.servings_tag ?? 'servings'}',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // ── Ingredient Status Summary ────────────────
                  Row(
                    children: [
                      _StatusChip(
                        icon: Icons.check_circle, color: Theme.of(context).colorScheme.tertiary,
                        label: AppLocalizations.of(context)?.nHave(haveCount.toString()) ?? '$haveCount have'),
                      SizedBox(width: 8),
                      if (missingCount > 0)
                        _StatusChip(
                          icon: Icons.warning_amber, color: Colors.orange,
                          label: AppLocalizations.of(context)?.nMissing(missingCount.toString()) ?? '$missingCount missing'),
                    ],
                  ),
                  SizedBox(height: 12),

                  // ── Ingredients List ──────────────────────────
                  Text('📋 ${AppLocalizations.of(context)?.ingredientsHeader ?? 'Ingredients'}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),

                  ...List.generate(widget.ingredients.length, (i) {
                    final ing = widget.ingredients[i];
                    final name = ing['translated_name'] ?? ing['name'] ?? 'Unknown';
                    final ingId = ing['ingredient_id'] ?? ing['id'] ?? '';
                    final rawQty = ing['quantity'];
                    final unit = ing['unit'] ?? '';
                    final translatedUnit = L10nHelper.translateUnit(unit, Localizations.localeOf(context).languageCode);
                    final isOwned = widget.ownedIngredientIds.contains(ingId);
                    final scaledQty = _scaleQuantity(rawQty);
                    final emoji = IngredientIcons.getEmoji(name, category: ing['category']);

                    return Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 6),
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOwned
                                  ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.15)),
                          ),
                          child: GestureDetector(
                            onTap: () => _editIngredient(i),
                            child: Row(
                            children: [
                              Text(emoji, style: TextStyle(fontSize: 22)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                                    Builder(builder: (context) {
                                      final displayQty = UnitConverter.simplifyMetric(scaledQty, unit);
                                      final parts = displayQty.split(' ');
                                      if (parts.length > 1) {
                                        parts.last = L10nHelper.translateUnit(parts.last, Localizations.localeOf(context).languageCode);
                                      }
                                      return Text(parts.join(' '),
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12));
                                    }),
                                  ],
                                ),
                              ),
                              if (isOwned)
                                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.tertiary, size: 20)
                              else
                                GestureDetector(
                                  onTap: () => _askSubstitute(i),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _loadingSub[i] == true
                                        ? SizedBox(width: 14, height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                                        : Text(AppLocalizations.of(context)?.swapButton ?? 'Swap →',
                                            style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                          ),
                        ),
                        // Substitution suggestions
                        if (_substitutions[i] != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 8, left: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(_substitutions[i]!,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 13, height: 1.5)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),

                  // ── AI Assistant ─────────────────────────────
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 18),
                            SizedBox(width: 8),
                            Text('🤖 ${AppLocalizations.of(context)?.aiAssistant ?? 'AI Assistant'}',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        SizedBox(height: 10),
                        TextField(
                          onChanged: (v) => _aiQuestion = v,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)?.aiHint ?? 'e.g. "I don\'t have lamb, suggest alternatives"',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: _aiLoading
                                ? Padding(padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)))
                                : IconButton(
                                    onPressed: _askAiChat,
                                    icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary, size: 20)),
                          ),
                        ),
                        if (_aiResponse != null) ...[
                          SizedBox(height: 10),
                          Text(_aiResponse!,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85), fontSize: 13, height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),

            // ── Start Cooking Button ─────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startCooking,
                  icon: Icon(Icons.restaurant, size: 22),
                  label: Text('🍳 ${AppLocalizations.of(context)?.startCooking ?? 'Start Cooking'}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _StatusChip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
