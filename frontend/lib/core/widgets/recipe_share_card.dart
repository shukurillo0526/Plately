// Plately — Recipe Share Card & Dialog
// =======================================
// Generates a high-fidelity visual social sharing card for
// Instagram Stories, Telegram, WhatsApp, and social feeds.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipeShareDialog extends StatelessWidget {
  final String recipeId;
  final String title;
  final String? imageUrl;
  final String? cuisine;
  final int? prepTime;
  final int? cookTime;
  final int? calories;
  final String? chefName;

  const RecipeShareDialog({
    super.key,
    required this.recipeId,
    required this.title,
    this.imageUrl,
    this.cuisine,
    this.prepTime,
    this.cookTime,
    this.calories,
    this.chefName,
  });

  static Future<void> show(
    BuildContext context, {
    required String recipeId,
    required String title,
    String? imageUrl,
    String? cuisine,
    int? prepTime,
    int? cookTime,
    int? calories,
    String? chefName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeShareDialog(
        recipeId: recipeId,
        title: title,
        imageUrl: imageUrl,
        cuisine: cuisine,
        prepTime: prepTime,
        cookTime: cookTime,
        calories: calories,
        chefName: chefName,
      ),
    );
  }

  String get _shareText {
    final timeStr = (prepTime != null && cookTime != null)
        ? '⏱ ${(prepTime! + cookTime!)} mins'
        : '';
    final calStr = calories != null ? '🔥 $calories kcal' : '';
    final chefStr = chefName != null ? 'by Chef $chefName' : '';
    return '🍳 "$title" $chefStr\n$timeStr $calStr\nCook with zero-waste on Plately: https://theplately.com/recipes/$recipeId';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saffron = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
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

          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share Recipe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Visual Preview Card (Snapshot Card)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: saffron.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: saffron.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image or Banner
                Stack(
                  children: [
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: imageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _fallbackHeader(saffron),
                      )
                    else
                      _fallbackHeader(saffron),
                    // Plately Saffron Brand watermark tag
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xE60D1117),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: saffron.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF7861C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'PLATELY RECIPE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF7861C),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Card details
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (chefName != null)
                        Text(
                          'Crafted by Chef $chefName',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (prepTime != null || cookTime != null)
                            _badge(
                              '⏱ ${(prepTime ?? 0) + (cookTime ?? 0)}m',
                              const Color(0xFF4CAF50),
                            ),
                          if (calories != null) ...[
                            const SizedBox(width: 6),
                            _badge('🔥 $calories kcal', Colors.orange),
                          ],
                          if (cuisine != null) ...[
                            const SizedBox(width: 6),
                            _badge(cuisine!, Colors.blue),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              // Copy Link Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: 'https://theplately.com/recipes/$recipeId',
                    ));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('📋 Recipe link copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Share Button
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    SharePlus.instance.share(ShareParams(text: _shareText));
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: saffron,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackHeader(Color saffron) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF161B22),
            saffron.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant_menu, size: 40, color: saffron.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _badge(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }
}
