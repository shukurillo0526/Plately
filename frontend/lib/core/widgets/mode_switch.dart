// Plately — Mode Switch Widget
// ==============================
// A premium pill-shaped toggle for switching between Order and Cook modes.
// Features glassmorphic styling, sliding animation, and mode icons.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plately_app/core/services/app_settings.dart';

class ModeSwitch extends StatelessWidget {
  final AppMode currentMode;
  final ValueChanged<AppMode> onModeChanged;

  const ModeSwitch({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOrder = currentMode == AppMode.order;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            alignment: isOrder ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 80,
              height: 36,
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: isOrder
                      ? [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary]
                      : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isOrder
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              _ModeTab(
                label: 'ORDER',
                icon: Icons.delivery_dining,
                isActive: isOrder,
                onTap: () => onModeChanged(AppMode.order),
              ),
              _ModeTab(
                label: 'COOK',
                icon: Icons.restaurant,
                isActive: !isOrder,
                onTap: () => onModeChanged(AppMode.cook),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              letterSpacing: 1.2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 15,
                    color: isActive
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                SizedBox(width: 4),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
