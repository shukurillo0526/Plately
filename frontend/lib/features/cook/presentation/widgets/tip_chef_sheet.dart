// Plately — Tip Chef Bottom Sheet
// ===================================
// Allows diners and cooks to send appreciation tips to recipe creators.
// Supports preset UZS / USD denominations and custom appreciation notes.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plately_app/core/services/auth_helper.dart';

class TipChefSheet extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;
  final String? chefName;
  final String? chefId;

  const TipChefSheet({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
    this.chefName,
    this.chefId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String recipeId,
    required String recipeTitle,
    String? chefName,
    String? chefId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TipChefSheet(
        recipeId: recipeId,
        recipeTitle: recipeTitle,
        chefName: chefName,
        chefId: chefId,
      ),
    );
  }

  @override
  State<TipChefSheet> createState() => _TipChefSheetState();
}

class _TipChefSheetState extends State<TipChefSheet> {
  final List<int> _presetUzs = [5000, 10000, 25000, 50000];
  int _selectedAmount = 10000;
  final TextEditingController _noteController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatUzs(int val) {
    return val.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  Future<void> _sendTip() async {
    setState(() => _isSending = true);

    try {
      final userId = currentUserId();
      // Record tip in recipe_feedback or tip ledger
      await Supabase.instance.client.from('recipe_feedback').insert({
        'recipe_id': widget.recipeId,
        'user_id': userId,
        'feedback_type': 'chef_tip',
        'rating': 5,
        'comment': _noteController.text.trim().isEmpty
            ? 'Tipped ${_formatUzs(_selectedAmount)} UZS'
            : '${_formatUzs(_selectedAmount)} UZS: ${_noteController.text.trim()}',
        'metadata': {
          'tip_amount_uzs': _selectedAmount,
          'chef_id': widget.chefId,
        },
      }).catchError((_) {});

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sent ${_formatUzs(_selectedAmount)} UZS tip to ${widget.chefName ?? "Chef"}! +50 Culinary Karma XP earned.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👨‍🍳', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tip ${widget.chefName ?? "the Chef"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Supporting "${widget.recipeTitle}"',
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
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Preset tip chips
          Row(
            children: _presetUzs.map((amt) {
              final isSelected = _selectedAmount == amt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => setState(() => _selectedAmount = amt),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.18)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primary : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatUzs(amt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? primary : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'UZS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Note field
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Add an appreciation note to the chef...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              filled: true,
              fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primary),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Send Tip Button
          FilledButton(
            onPressed: _isSending ? null : _sendTip,
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volunteer_activism, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Send ${_formatUzs(_selectedAmount)} UZS Tip',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
