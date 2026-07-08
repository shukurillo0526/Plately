// Plately — Active Cooking Screen (Enhanced)
// =============================================
// Distraction-free, step-by-step cooking tutorial.
// Features: persistent timer bar, auto-start timers, interactive countdown,
// attention flags, wakelock, swipeable step cards, and AI tips.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/features/cook/presentation/screens/cooking_reward_screen.dart';
import 'package:plately_app/features/cook/providers/cooking_session_provider.dart';
import 'package:plately_app/features/cook/presentation/widgets/step_timer_widget.dart';
import 'package:plately_app/features/cook/presentation/widgets/cook_portions_sheet.dart';

class CookingRunScreen extends StatefulWidget {
  final String recipeId;
  final String title;
  final List<Map<String, dynamic>> steps;
  final List<Map<String, dynamic>>? ingredients;
  final List<String>? prepNotes;
  final int matchedIngredientsCount;
  final double matchPct;
  final String userInventoryText;
  final int servingsCooked;
  final int originalServings;
  final Set<String> ownedIngredientIds;
  final int? calories;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final bool isBeginnerMode;
  final bool restoreFromSession;

  const CookingRunScreen({
    super.key,
    required this.recipeId,
    required this.title,
    required this.steps,
    this.ingredients,
    this.prepNotes,
    required this.matchedIngredientsCount,
    required this.matchPct,
    required this.userInventoryText,
    required this.servingsCooked,
    required this.originalServings,
    this.ownedIngredientIds = const {},
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.isBeginnerMode = false,
    this.restoreFromSession = false,
  });

  @override
  State<CookingRunScreen> createState() => _CookingRunScreenState();
}

class _CookingRunScreenState extends State<CookingRunScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showPrepNotes = true;

  // For modifiedRecipe state
  late List<Map<String, dynamic>> _modifiedSteps;
  late String _ingredientsListText;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WakelockPlus.enable();
    if (widget.prepNotes == null || widget.prepNotes!.isEmpty) {
      _showPrepNotes = false;
    }
    _modifiedSteps = List.of(widget.steps.map((s) => Map<String, dynamic>.from(s)));
    _ingredientsListText = widget.ingredients?.map((ing) {
      final name = ing['name'] ?? ing['name_en'] ?? 'Unknown';
      final qty = ing['quantity']?.toString() ?? '';
      final unit = ing['unit'] ?? '';
      return "$qty $unit $name";
    }).join(', ') ?? '';

    // Initialize cooking session via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  /// Create or restore a cooking session in the provider
  void _initSession() {
    if (!mounted) return;
    final container = ProviderScope.containerOf(context);
    final notifier = container.read(cookingSessionProvider.notifier);
    final existing = container.read(cookingSessionProvider);

    if (widget.restoreFromSession && existing != null) {
      // Restore step index from saved session
      final savedIndex = existing.currentStepIndex;
      if (savedIndex > 0 && savedIndex < widget.steps.length) {
        setState(() => _currentIndex = savedIndex);
        _pageController.jumpToPage(savedIndex);
      }
    } else {
      // Start a fresh session
      notifier.startSession(
        recipeId: widget.recipeId,
        title: widget.title,
        steps: widget.steps,
        ingredients: widget.ingredients,
        isBeginnerMode: widget.isBeginnerMode,
        servingsCooked: widget.servingsCooked,
        originalServings: widget.originalServings,
        matchPct: widget.matchPct,
        matchedIngredientsCount: widget.matchedIngredientsCount,
        userInventoryText: widget.userInventoryText,
        ownedIngredientIds: widget.ownedIngredientIds,
        calories: widget.calories,
        proteinG: widget.proteinG,
        carbsG: widget.carbsG,
        fatG: widget.fatG,
      );
    }
  }

  /// Sync step index to session provider
  void _syncStepToSession() {
    try {
      final container = ProviderScope.containerOf(context);
      container.read(cookingSessionProvider.notifier).goToStep(_currentIndex);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _nextStep() {
    if (_currentIndex < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      // Sync with session provider after page animates
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _syncStepToSession();
      });
    }
  }

  void _prevStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _syncStepToSession();
      });
    }
  }

  void _finishCooking() {
    _showDeductionDialog();
  }

  Future<void> _showDeductionDialog() async {
    final ingredients = widget.ingredients ?? [];
    if (ingredients.isEmpty) {
      _navigateToReward([]);
      return;
    }

    // Build checklist: only owned ingredients are pre-checked
    final checked = <int, bool>{};
    for (int i = 0; i < ingredients.length; i++) {
      final ing = ingredients[i];
      final ingId = ing['ingredient_id'] ?? ing['id'] ?? '';
      checked[i] = widget.ownedIngredientIds.contains(ingId);
    }

    final result = await showDialog<List<String>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Row(
                children: [
                  Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Deduct from shelf?',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Uncheck any ingredients you didn\'t use:',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                    SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: ingredients.length,
                        itemBuilder: (ctx, i) {
                          final ing = ingredients[i];
                          final name = ing['translated_name'] ?? ing['name'] ?? ing['display_name_en'] ?? 'Unknown';
                          final qty = ing['quantity']?.toString() ?? '';
                          final unit = ing['unit'] ?? '';
                          final ingId = ing['ingredient_id'] ?? ing['id'] ?? '';
                          final isOwned = widget.ownedIngredientIds.contains(ingId);

                          return CheckboxListTile(
                            value: checked[i] ?? false,
                            onChanged: isOwned ? (val) {
                              setDialogState(() => checked[i] = val ?? false);
                            } : null,
                            title: Text(name,
                              style: TextStyle(
                                color: isOwned
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                                fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: Text('$qty $unit${isOwned ? '' : ' (not in shelf)'}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 12)),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Skip button means SKIP EVERYTHING
                    final allOwned = widget.ownedIngredientIds.toList();
                    Navigator.pop(ctx, allOwned);
                  },
                  child: Text('Skip', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                ),
                FilledButton.icon(
                  onPressed: () {
                    // Collect skipped ingredient IDs (unchecked ones that are owned)
                    final skipped = <String>[];
                    for (int i = 0; i < ingredients.length; i++) {
                      if (checked[i] != true) {
                        final ingId = ingredients[i]['ingredient_id'] ?? ingredients[i]['id'] ?? '';
                        if (ingId.toString().isNotEmpty) skipped.add(ingId.toString());
                      }
                    }
                    Navigator.pop(ctx, skipped);
                  },
                  icon: Icon(Icons.check, size: 18),
                  label: Text('Deduct & Finish'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return; // dialog dismissed
    _navigateToReward(result);
  }

  void _navigateToReward(List<String> skippedIds) {
    // End the persistent cooking session
    try {
      final container = ProviderScope.containerOf(context);
      container.read(cookingSessionProvider.notifier).endSession();
    } catch (_) {}

    // Filter ingredients to exclude skipped ones
    final skippedIdsSet = Set<String>.from(skippedIds);
    final rawIngredients = widget.ingredients ?? [];
    
    // Scale ingredients per portion (recipe servings vs servingsCooked)
    final scale = 1.0 / (widget.originalServings > 0 ? widget.originalServings : 2);
    final List<Map<String, dynamic>> portionIngredients = rawIngredients
        .where((ing) {
          final id = ing['ingredient_id'] ?? ing['id'];
          return id != null && !skippedIdsSet.contains(id);
        })
        .map((ing) {
          return {
            'ingredient_id': ing['ingredient_id'] ?? ing['id'],
            'quantity_per_portion': ((ing['quantity'] as num?) ?? 1.0).toDouble() * scale,
            'unit': ing['unit'] ?? 'pcs',
          };
        })
        .toList();

    final calPerPortion = (widget.calories ?? 0).toDouble() / (widget.servingsCooked > 0 ? widget.servingsCooked : 1);
    final proteinPerPortion = (widget.proteinG ?? 0).toDouble() / (widget.servingsCooked > 0 ? widget.servingsCooked : 1);
    final carbsPerPortion = (widget.carbsG ?? 0).toDouble() / (widget.servingsCooked > 0 ? widget.servingsCooked : 1);
    final fatPerPortion = (widget.fatG ?? 0).toDouble() / (widget.servingsCooked > 0 ? widget.servingsCooked : 1);

    // Show portions sheet
    CookPortionsSheet.show(
      context: context,
      recipeId: widget.recipeId,
      recipeTitle: widget.title,
      initialServings: widget.servingsCooked,
      ingredients: portionIngredients,
      caloriesPerPortion: calPerPortion,
      proteinPerPortion: proteinPerPortion,
      carbsPerPortion: carbsPerPortion,
      fatPerPortion: fatPerPortion,
      onComplete: (prepResult) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CookingRewardScreen(
              recipeId: widget.recipeId,
              title: widget.title,
              matchedIngredientsCount: widget.matchedIngredientsCount,
              matchPct: widget.matchPct,
              servingsCooked: widget.servingsCooked,
              originalServings: widget.originalServings,
              skippedIngredientIds: skippedIds,
              ingredients: widget.ingredients,
              calories: widget.calories,
              proteinG: widget.proteinG,
              carbsG: widget.carbsG,
              fatG: widget.fatG,
              prepResult: prepResult,
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_modifiedSteps.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text('No steps available for this recipe.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        ),
      );
    }

    // Prep notes overlay
    if (_showPrepNotes) {
      return _buildPrepNotesScreen();
    }

    final totalSteps = _modifiedSteps.length;
    final progress = (_currentIndex + 1) / totalSteps;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress Bar ──────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Step ${_currentIndex + 1} of $totalSteps',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
              ),
            ),

            // ── Step Carousel ─────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemCount: totalSteps,
                itemBuilder: (context, index) {
                  return _CookingStepCard(
                    step: _modifiedSteps[index],
                    stepIndex: index,
                    totalSteps: totalSteps,
                    recipeTitle: widget.title,
                    ingredientsListText: _ingredientsListText,
                    userInventoryText: widget.userInventoryText,
                    onStepModified: (newText) {
                      setState(() {
                        _modifiedSteps[index]['human_text'] = newText;
                      });
                    },
                    isBeginnerMode: widget.isBeginnerMode,
                  );
                },
              ),
            ),

            // ── Navigation Controls ───────────────────────────
            Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentIndex > 0
                      ? TextButton.icon(
                          onPressed: _prevStep,
                          icon: Icon(Icons.arrow_back_ios, size: 16, color: Theme.of(context).colorScheme.onSurface),
                          label: Text('Back', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        )
                      : SizedBox(width: 80),
                  _currentIndex < totalSteps - 1
                      ? FilledButton.icon(
                          onPressed: _nextStep,
                          icon: Icon(Icons.arrow_forward_ios, size: 16),
                          label: Text('Next Step', style: TextStyle(fontSize: 16)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        )
                      : FilledButton.icon(
                          onPressed: _finishCooking,
                          icon: Icon(Icons.check_circle, size: 20),
                          label: Text('Finish Cooking',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepNotesScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Text('🔪', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prep Before You Start',
                            style: TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('Mise en place — prepare everything first!',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Ingredients overview
              if (widget.ingredients != null && widget.ingredients!.isNotEmpty) ...[
                Text('📋 Ingredients needed:',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                ...widget.ingredients!.take(8).map((ing) {
                  final name = ing['name'] ?? ing['name_en'] ?? ing['display_name_en'] ?? '';
                  final qty = ing['quantity']?.toString() ?? '';
                  final unit = ing['unit'] ?? '';
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('  • $qty $unit $name',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                  );
                }),
                if (widget.ingredients!.length > 8)
                  Text('  ... and ${widget.ingredients!.length - 8} more',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13)),
                SizedBox(height: 16),
              ],

              // Prep notes
              if (widget.prepNotes != null)
                ...widget.prepNotes!.map((note) => Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✓ ', style: TextStyle(color: Colors.orange, fontSize: 16)),
                      Expanded(
                        child: Text(note,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85), fontSize: 15, height: 1.5)),
                      ),
                    ],
                  ),
                )),

              Spacer(),

              // Start button
              FilledButton.icon(
                onPressed: () => setState(() => _showPrepNotes = false),
                icon: Icon(Icons.restaurant, size: 20),
                label: Text('Start Cooking →', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step Detail Card (Human-First Tutorial) ─────────────────────────

class _CookingStepCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> step;
  final int stepIndex;
  final int totalSteps;
  final String recipeTitle;
  final String ingredientsListText;
  final String userInventoryText;
  final void Function(String newText) onStepModified;
  final bool isBeginnerMode;

  const _CookingStepCard({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.recipeTitle,
    required this.ingredientsListText,
    required this.userInventoryText,
    required this.onStepModified,
    required this.isBeginnerMode,
  });

  @override
  ConsumerState<_CookingStepCard> createState() => _CookingStepCardState();
}

class _CookingStepCardState extends ConsumerState<_CookingStepCard> {
  final ApiService _api = ApiService();
  final List<Map<String, String>> _chatMessages = [];
  bool _aiLoading = false;
  bool _autoStartTriggered = false;
  final TextEditingController _chatController = TextEditingController();

  int? get _timerSeconds {
    // Prefer new timer_seconds field, fall back to estimated_seconds or robot_action
    final ts = widget.step['timer_seconds'];
    if (ts != null && ts is int && ts > 0) return ts;
    final est = widget.step['estimated_seconds'];
    if (est != null && est is int && est > 0) return est;
    // Try robot_action minutes
    final robot = widget.step['robot_action'];
    if (robot is Map && robot['minutes'] != null) {
      return ((robot['minutes'] as num) * 60).toInt();
    }
    return null;
  }

  bool get _isAutoStart {
    return widget.step['timer_auto_start'] == true;
  }

  @override
  void initState() {
    super.initState();
    // Auto-start timer if flagged
    if (_isAutoStart && _timerSeconds != null && !_autoStartTriggered) {
      _autoStartTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cookingSessionProvider.notifier).startTimer(_timerSeconds!);
      });
    }
  }


  IconData _pickIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('heat') || lower.contains('boil') || lower.contains('simmer')) {
      return Icons.local_fire_department;
    }
    if (lower.contains('cut') || lower.contains('chop') || lower.contains('dice') || lower.contains('slice')) {
      return Icons.content_cut;
    }
    if (lower.contains('mix') || lower.contains('stir') || lower.contains('whisk') || lower.contains('knead')) {
      return Icons.blender;
    }
    if (lower.contains('bake') || lower.contains('oven') || lower.contains('preheat')) {
      return Icons.microwave;
    }
    if (lower.contains('fry') || lower.contains('saute') || lower.contains('sear') || lower.contains('pan')) {
      return Icons.lunch_dining;
    }
    if (lower.contains('serve') || lower.contains('plate') || lower.contains('garnish')) {
      return Icons.room_service;
    }
    if (lower.contains('wash') || lower.contains('rinse') || lower.contains('soak') || lower.contains('drain')) {
      return Icons.water_drop;
    }
    if (lower.contains('season') || lower.contains('salt') || lower.contains('spice')) {
      return Icons.spa;
    }
    if (lower.contains('cool') || lower.contains('chill') || lower.contains('rest') || lower.contains('proof')) {
      return Icons.ac_unit;
    }
    if (lower.contains('shape') || lower.contains('roll') || lower.contains('fold') || lower.contains('press')) {
      return Icons.pan_tool;
    }
    if (lower.contains('steam')) return Icons.cloud;
    if (lower.contains('pour') || lower.contains('add water')) return Icons.local_drink;
    return Icons.restaurant;
  }

  void _editStep() {
    final c = TextEditingController(text: widget.step['translated_text'] ?? widget.step['human_text'] ?? widget.step['text'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Edit Step', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: c,
          maxLines: null,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          FilledButton(
            onPressed: () {
              widget.onStepModified(c.text.trim());
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final q = _chatController.text.trim();
    if (q.isEmpty || _aiLoading) return;

    _chatController.clear();
    setState(() {
      _chatMessages.add({'role': 'user', 'content': q});
      _aiLoading = true;
    });

    try {
      final userLanguage = Localizations.localeOf(context).languageCode;
      final langMap = {
        'en': 'English', 'ko': 'Korean', 'uz': "O'zbek (Uzbek)",
        'ru': 'Russian', 'ja': 'Japanese', 'zh': 'Chinese',
        'es': 'Spanish', 'tr': 'Turkish',
      };
      final langName = langMap[userLanguage] ?? 'English';
      final stepText = widget.step['translated_text'] ?? widget.step['human_text'] ?? widget.step['text'] ?? '';
      
      final prompt = '''
You are a helpful cooking assistant. The user is currently cooking.

**User's Inventory:**
${widget.userInventoryText}

**Current Recipe:**
Title: ${widget.recipeTitle}
Ingredients: ${widget.ingredientsListText}
Current Step (${widget.stepIndex + 1}/${widget.totalSteps}): $stepText

**User's Question:**
$q

**Cooking Mode:** ${widget.isBeginnerMode ? 'BEGINNER MODE — The user is a beginner cook. Explain steps in simple micro-actions, guide them through techniques, and include safety tips.' : 'Default mode — Keep answers concise and direct.'}

IMPORTANT: Respond entirely in $langName.
Be helpful, clear, and natural. 
If they ask for substitutions, suggest realistic alternatives based on what they have in their inventory.
Keep your answer short and easy to read while cooking.
''';

      // We only send the prompt as a single user message to follow the exact template
      final messagesToSend = [{'role': 'user', 'content': prompt}];

      final result = await _api.chatWithAssistant(messages: messagesToSend);
      final reply = result['data']?['message'] ?? 'No response.';

      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': reply});
          _aiLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AI cooking chat error: $e');
      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': 'AI is temporarily unavailable. Please try again later.'});
          _aiLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final humanText = widget.isBeginnerMode
        ? (widget.step['translated_beginner_text'] ?? widget.step['beginner_text'] ?? widget.step['translated_text'] ?? widget.step['human_text'] ?? widget.step['text'] ?? '')
        : (widget.step['translated_text'] ?? widget.step['human_text'] ?? widget.step['text'] ?? '');
    final requiresAttention = widget.step['requires_attention'] == true;
    final icon = _pickIcon(humanText);
    final tempC = widget.step['temperature_c'];
    final timerSec = _timerSeconds;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cooking Illustration Area
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 72,
                      color: (requiresAttention ? Colors.orange : Theme.of(context).colorScheme.primary)
                          .withValues(alpha: 0.3)),
                    if (requiresAttention) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('👀 Needs Your Attention',
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                    if (tempC != null && tempC is int) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('🌡️ $tempC°C',
                          style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

          // Core Instruction with Edit Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(humanText,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700, height: 1.5)),
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                onPressed: _editStep,
                tooltip: 'Modify Recipe Step',
              ),
            ],
          ),
          SizedBox(height: 16),

          // Interactive Timer Button
          if (timerSec != null && timerSec > 0)
            Center(
              child: StepTimerWidget(
                timerSeconds: timerSec,
              ),
            ),

          // AI Tip Section (Chat UI)
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 18),
                    SizedBox(width: 8),
                    Text('🤖 Assistant',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                if (_chatMessages.isNotEmpty) ...[
                  SizedBox(height: 10),
                  ..._chatMessages.map((msg) {
                    final isUser = msg['role'] == 'user';
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isUser ? 'You: ' : 'AI: ',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          Expanded(
                            child: Text(msg['content'] ?? '',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85), fontSize: 13, height: 1.5)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ask a question or request substitution...',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    _aiLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
                        : IconButton(
                            icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary, size: 20),
                            onPressed: _sendMessage,
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
