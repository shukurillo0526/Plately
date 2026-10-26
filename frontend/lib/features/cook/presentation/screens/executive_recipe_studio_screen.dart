// Plately — Executive Recipe Studio
// =====================================
// High-grade culinary studio for home chefs and creators.
// 4-Step Studio:
// 1. Identity & Hero (Title, cuisine, difficulty, times, hero photo)
// 2. Pantry Ingredients (Manual entry + 1-tap import from Living Shelf)
// 3. Steps & Timers (Markdown steps, countdown timer_seconds, Chef's Secret tips)
// 4. Monetization & Macros (Free/Masterclass, price in UZS/USD, calories & macros)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/auth_helper.dart';
import 'package:plately_app/core/services/recipe_monetization_service.dart';
import 'package:plately_app/features/cook/presentation/screens/recipe_detail_screen.dart';

class ExecutiveRecipeStudioScreen extends StatefulWidget {
  const ExecutiveRecipeStudioScreen({super.key});

  @override
  State<ExecutiveRecipeStudioScreen> createState() => _ExecutiveRecipeStudioScreenState();
}

class _ExecutiveRecipeStudioScreenState extends State<ExecutiveRecipeStudioScreen> {
  int _currentStep = 0;
  bool _isPublishing = false;

  // ── Step 1: Identity & Hero Controllers ──
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCuisine = 'Uzbek';
  int _difficulty = 2; // 1 = Easy, 2 = Medium, 3 = Executive
  int _servings = 4;
  int _prepTime = 20;
  int _cookTime = 30;
  String _imageUrl = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80';

  final List<String> _cuisineOptions = [
    'Uzbek',
    'Italian',
    'Japanese',
    'French',
    'Korean',
    'American',
    'Mediterranean',
    'Mexican',
    'Fusion',
  ];

  final List<String> _presetHeroImages = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80', // Salad Bowl
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80', // BBQ Steak
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80', // Pizza
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80', // Pancakes
    'https://images.unsplash.com/photo-1603105037880-880cd4edfb0d?w=800&q=80', // Stir Fry
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80', // Fresh Pasta
  ];

  // ── Step 2: Ingredients ──
  final List<Map<String, dynamic>> _ingredients = [
    {'name': 'Beef Tenderloin', 'quantity': '400', 'unit': 'g', 'prep_note': 'diced into cubes'},
    {'name': 'Yellow Onion', 'quantity': '2', 'unit': 'pieces', 'prep_note': 'thinly sliced'},
    {'name': 'Carrots', 'quantity': '300', 'unit': 'g', 'prep_note': 'julienned'},
    {'name': 'Cumin Seeds', 'quantity': '1', 'unit': 'tbsp', 'prep_note': 'toasted'},
  ];

  // ── Step 3: Steps & Timers ──
  final List<Map<String, dynamic>> _steps = [
    {
      'text': 'Heat cottonseed oil or vegetable oil in a heavy cast-iron cauldron (kazan) until light smoke appears.',
      'seconds': 180,
      'is_secret': true,
      'secret_tip': 'High initial heat seals in juices and renders maximum savory umami.',
    },
    {
      'text': 'Add cubed meat and sear on high heat until deeply browned and caramelized on all sides.',
      'seconds': 420,
      'is_secret': false,
      'secret_tip': '',
    },
    {
      'text': 'Stir in sliced onions and sauté until golden bronze, then add carrots and toasted cumin.',
      'seconds': 360,
      'is_secret': false,
      'secret_tip': '',
    },
    {
      'text': 'Pour in hot water, reduce heat to low, cover and let simmer into a fragrant zirvak broth.',
      'seconds': 1200,
      'is_secret': true,
      'secret_tip': 'Never let the zirvak boil violently; gentle bubbling keeps the broth crystal clear.',
    },
  ];

  // ── Step 4: Monetization & Nutrition ──
  bool _isPremium = false;
  int _priceCents = 199; // $1.99 or ~25,000 UZS
  final _uzsPriceController = TextEditingController(text: '25 000');
  int _calories = 520;
  double _protein = 38;
  double _carbs = 45;
  double _fat = 22;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _uzsPriceController.dispose();
    super.dispose();
  }

  // ── Import from Living Shelf modal ──
  Future<void> _importFromLivingShelf() async {
    final userId = currentUserId();
    List<Map<String, dynamic>> shelfItems = [];

    try {
      final res = await Supabase.instance.client
          .from('inventory_items')
          .select('id, name, quantity, unit, location, ingredients(display_name_en, canonical_name)')
          .eq('user_id', userId);
      shelfItems = List<Map<String, dynamic>>.from(res as List);
    } catch (_) {}

    if (!mounted) return;

    if (shelfItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pantry items found in your Living Shelf.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selected = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Import from Living Shelf',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select ingredients from your pantry to add to this recipe:',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: shelfItems.length,
                    itemBuilder: (c, idx) {
                      final item = shelfItems[idx];
                      final name = item['name'] ?? item['ingredients']?['display_name_en'] ?? 'Item';
                      final id = item['id'].toString();
                      final isChecked = selected.contains(id);

                      return CheckboxListTile(
                        value: isChecked,
                        title: Text(name, style: TextStyle(color: theme.colorScheme.onSurface)),
                        subtitle: Text('${item['quantity'] ?? 1} ${item['unit'] ?? ''} • ${item['location'] ?? 'pantry'}',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          for (final item in shelfItems) {
                            if (selected.contains(item['id'].toString())) {
                              final name = item['name'] ?? item['ingredients']?['display_name_en'] ?? 'Item';
                              _ingredients.add({
                                'name': name,
                                'quantity': (item['quantity'] ?? 1).toString(),
                                'unit': item['unit'] ?? 'piece',
                                'prep_note': '',
                              });
                            }
                          }
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Add ${selected.length} Ingredients to Recipe'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Publish Action ──
  Future<void> _publishRecipe() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a recipe title in Step 1.')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final formattedIngredients = _ingredients.map((ing) {
        final qty = double.tryParse(ing['quantity']?.toString() ?? '1') ?? 1.0;
        return {
          'name': ing['name'] ?? 'Ingredient',
          'quantity': qty,
          'unit': ing['unit'] ?? 'piece',
          'prep_note': ing['prep_note'] ?? '',
        };
      }).toList();

      final formattedSteps = _steps.asMap().entries.map((e) {
        final s = e.value;
        return {
          'step_number': e.key + 1,
          'text': s['text'] ?? '',
          'seconds': s['seconds'] ?? 0,
          'is_secret': s['is_secret'] ?? false,
          'secret_tip': s['secret_tip'] ?? '',
        };
      }).toList();

      final recipe = await RecipeMonetizationService.createRecipe(
        title: title,
        description: _descController.text.trim(),
        cuisine: _selectedCuisine,
        difficulty: _difficulty,
        prepTime: _prepTime,
        cookTime: _cookTime,
        servings: _servings,
        imageUrl: _imageUrl,
        isPremium: _isPremium,
        priceCents: _isPremium ? _priceCents : 0,
        caloriesPerServing: _calories,
        tags: [_selectedCuisine.toLowerCase(), 'executive', _isPremium ? 'masterclass' : 'community'],
        ingredients: formattedIngredients,
        steps: formattedSteps,
      );

      if (!mounted) return;

      setState(() => _isPublishing = false);

      if (recipe != null) {
        _showSuccessDialog(recipe);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish recipe. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing recipe: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(RecipeModel recipe) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🏆', style: TextStyle(fontSize: 28)),
            SizedBox(width: 10),
            Text('Masterpiece Published!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${recipe.title}" is now published to the Plately culinary ecosystem.',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(recipe.isPremium ? Icons.workspace_premium : Icons.people_outline,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    recipe.isPremium
                        ? 'Masterclass: ${recipe.priceDisplay}'
                        : 'Free Community Recipe',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context, true); // studio
            },
            child: const Text('Back to Portfolio'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context, true); // studio
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(
                    recipeId: recipe.id,
                    title: recipe.title,
                    description: recipe.description,
                    cuisine: recipe.cuisine,
                    difficulty: recipe.difficulty,
                    prepTime: recipe.prepTime,
                    cookTime: recipe.cookTime,
                    servings: recipe.servings,
                    tierColor: theme.colorScheme.primary,
                    ownedIngredientIds: const {},
                    caloriesPerServing: recipe.caloriesPerServing,
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary),
            child: const Text('View Recipe'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saffron = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('👨‍🍳', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Executive Recipe Studio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildStepperHeader(saffron),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(theme, saffron),
              ),
            ),
            _buildBottomNav(theme, saffron),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(Color saffron) {
    final steps = ['Identity', 'Ingredients', 'Steps & Timers', 'Publish'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final idx = e.key;
          final title = e.value;
          final isActive = idx == _currentStep;
          final isPast = idx < _currentStep;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentStep = idx),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: isPast || isActive ? saffron : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? saffron
                          : isPast
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepContent(ThemeData theme, Color saffron) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Identity(theme, saffron);
      case 1:
        return _buildStep2Ingredients(theme, saffron);
      case 2:
        return _buildStep3StepsAndTimers(theme, saffron);
      case 3:
      default:
        return _buildStep4MonetizationAndNutrition(theme, saffron);
    }
  }

  // ── Step 1 Widget: Identity & Hero ──
  Widget _buildStep1Identity(ThemeData theme, Color saffron) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Recipe Identity & Origin', 'Give your culinary creation a name and story.'),
        const SizedBox(height: 16),

        _inputField(
          controller: _titleController,
          label: 'Recipe Title',
          hint: 'e.g. Samarkand Wedding Plov (Osh)',
          icon: Icons.restaurant,
        ),

        const SizedBox(height: 14),

        _inputField(
          controller: _descController,
          label: 'Culinary Heritage & Story',
          hint: 'Describe the heritage, texture, or why this recipe is special...',
          maxLines: 3,
          icon: Icons.menu_book,
        ),

        const SizedBox(height: 16),

        // Cuisine & Difficulty Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cuisine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCuisine,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF161B22),
                        items: _cuisineOptions
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCuisine = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Difficulty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _difficulty,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF161B22),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('🟢 Beginner', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 2, child: Text('🟡 Intermediate', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 3, child: Text('🟣 Executive Chef', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _difficulty = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Times & Servings Row
        Row(
          children: [
            Expanded(
              child: _numberCounter(
                label: 'Prep (mins)',
                value: _prepTime,
                onChanged: (v) => setState(() => _prepTime = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _numberCounter(
                label: 'Cook (mins)',
                value: _cookTime,
                onChanged: (v) => setState(() => _cookTime = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _numberCounter(
                label: 'Servings',
                value: _servings,
                onChanged: (v) => setState(() => _servings = v),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Hero Image Picker
        _sectionTitle('Hero Showcase Photo', 'Select a high-resolution food photo or enter custom URL.'),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _presetHeroImages.length,
            itemBuilder: (ctx, i) {
              final img = _presetHeroImages[i];
              final isSel = img == _imageUrl;
              return GestureDetector(
                onTap: () => setState(() => _imageUrl = img),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? saffron : Colors.white.withValues(alpha: 0.1),
                      width: isSel ? 2.5 : 1,
                    ),
                    image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
                  ),
                  child: isSel
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFFF7861C), shape: BoxShape.circle),
                            child: const Icon(Icons.check, size: 14, color: Colors.white),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 2 Widget: Ingredients ──
  Widget _buildStep2Ingredients(ThemeData theme, Color saffron) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _sectionTitle('Recipe Ingredients', 'List all pantry and fresh components.'),
            ),
            OutlinedButton.icon(
              onPressed: _importFromLivingShelf,
              icon: const Icon(Icons.kitchen, size: 16),
              label: const Text('Living Shelf'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: saffron.withValues(alpha: 0.5)),
                foregroundColor: saffron,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._ingredients.asMap().entries.map((e) {
          final idx = e.key;
          final ing = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: ing['name'],
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Ingredient',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => ing['name'] = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: ing['quantity']?.toString(),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => ing['quantity'] = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: ing['unit'],
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Unit (g/ml/pc)',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => ing['unit'] = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  onPressed: () {
                    setState(() => _ingredients.removeAt(idx));
                  },
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        FilledButton.tonalIcon(
          onPressed: () {
            setState(() {
              _ingredients.add({'name': '', 'quantity': '1', 'unit': 'piece', 'prep_note': ''});
            });
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Ingredient'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }

  // ── Step 3 Widget: Steps & Timers ──
  Widget _buildStep3StepsAndTimers(ThemeData theme, Color saffron) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cooking Instructions & Timers', 'Provide step-by-step guidance with auto countdowns.'),
        const SizedBox(height: 12),

        ..._steps.asMap().entries.map((e) {
          final idx = e.key;
          final step = e.value;
          final isSecret = step['is_secret'] as bool? ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSecret ? const Color(0xFFFFB300).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: saffron.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(color: saffron, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Step ${idx + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    // Timer Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: saffron.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: saffron),
                          const SizedBox(width: 4),
                          Text(
                            '${(step['seconds'] as int? ?? 0) ~/ 60}m',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: saffron),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      onPressed: () {
                        setState(() => _steps.removeAt(idx));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: step['text'],
                  maxLines: 2,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Describe this cooking action...',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => step['text'] = v,
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          const Text('Timer (seconds):', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: (step['seconds'] ?? 0).toString(),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true),
                              onChanged: (v) => step['seconds'] = int.tryParse(v) ?? 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chef's secret toggle
                    InkWell(
                      onTap: () {
                        setState(() => step['is_secret'] = !isSecret);
                      },
                      child: Row(
                        children: [
                          Icon(
                            isSecret ? Icons.star : Icons.star_border,
                            size: 16,
                            color: isSecret ? const Color(0xFFFFB300) : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Chef's Secret",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSecret ? const Color(0xFFFFB300) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSecret) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: step['secret_tip'],
                    style: const TextStyle(fontSize: 12, color: Color(0xFFFFB300)),
                    decoration: const InputDecoration(
                      labelText: "Chef's Pro Tip (Exclusive Insight)",
                      isDense: true,
                    ),
                    onChanged: (v) => step['secret_tip'] = v,
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        FilledButton.tonalIcon(
          onPressed: () {
            setState(() {
              _steps.add({
                'text': '',
                'seconds': 300,
                'is_secret': false,
                'secret_tip': '',
              });
            });
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Step & Timer'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }

  // ── Step 4 Widget: Monetization & Nutrition ──
  Widget _buildStep4MonetizationAndNutrition(ThemeData theme, Color saffron) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Access Tier & Monetization', 'Decide if this recipe is a free gift or paid masterclass.'),
        const SizedBox(height: 14),

        // Tier Switcher Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPremium ? const Color(0xFFFFB300).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isPremium = false),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(
                        !_isPremium ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: !_isPremium ? saffron : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Free Community Recipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              'Accessible to everyone. Users can tip you culinary karma & funds.',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 16),
              InkWell(
                onTap: () => setState(() => _isPremium = true),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(
                        _isPremium ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _isPremium ? const Color(0xFFFFB300) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('Executive Masterclass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                SizedBox(width: 6),
                                Icon(Icons.workspace_premium, size: 16, color: Color(0xFFFFB300)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Paid recipe unlock. Secret techniques remain blurred until purchased.',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_isPremium) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unlock Price (UZS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _uzsPriceController,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: '25 000',
                          suffixText: 'UZS',
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final clean = v.replaceAll(' ', '');
                          final val = int.tryParse(clean) ?? 25000;
                          _priceCents = (val / 128).round();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('USD Equivalent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        '\$${(_priceCents / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 22),

        // Nutritional Macros
        _sectionTitle('Nutritional Macros (Per Serving)', 'Automated or customized dietary profile.'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _macroInput(
                      label: 'Calories (kcal)',
                      value: _calories.toString(),
                      onChanged: (v) => _calories = int.tryParse(v) ?? _calories,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _macroInput(
                      label: 'Protein (g)',
                      value: _protein.toStringAsFixed(0),
                      onChanged: (v) => _protein = double.tryParse(v) ?? _protein,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _macroInput(
                      label: 'Carbs (g)',
                      value: _carbs.toStringAsFixed(0),
                      onChanged: (v) => _carbs = double.tryParse(v) ?? _carbs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _macroInput(
                      label: 'Fat (g)',
                      value: _fat.toStringAsFixed(0),
                      onChanged: (v) => _fat = double.tryParse(v) ?? _fat,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Navigation Controls ──
  Widget _buildBottomNav(ThemeData theme, Color saffron) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back'),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isPublishing
                  ? null
                  : () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        _publishRecipe();
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: saffron,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 3 ? 'Publish Recipe to Plately' : 'Continue to Next Step',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Icon(_currentStep == 3 ? Icons.rocket_launch : Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper UI Components ──
  Widget _sectionTitle(String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }

  Widget _numberCounter({required String label, required int value, required ValueChanged<int> onChanged}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  if (value > 1) onChanged(value - 1);
                },
                child: const Icon(Icons.remove, size: 18),
              ),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              InkWell(
                onTap: () => onChanged(value + 1),
                child: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroInput({required String label, required String value, required ValueChanged<String> onChanged}) {
    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: onChanged,
    );
  }
}
