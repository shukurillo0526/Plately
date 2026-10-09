// Plately — Dual Mode Navigation Bar
// =====================================
// A distinctive bottom nav with:
// - A single thin line running across the bottom
// - A raised circular center button sitting on that line
// - Dynamic item count: 3 for Order mode, 5 for Cook mode
// - Smooth animations when switching between modes

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plately_app/core/services/app_settings.dart';

/// Describes a single navigation item.
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });
}

class DualModeNavBar extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;
  final AppMode mode;

  const DualModeNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    final bottomPad = MediaQuery.of(context).padding.bottom;
    final totalHeight = 88.0 + bottomPad;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── The line + bar area ────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 68 + bottomPad,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Column(
                children: [
                  // Thin line across the top
                  Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          accentColor.withValues(alpha: 0.4),
                          accentColor.withValues(alpha: 0.6),
                          accentColor.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                  // Bar background
                  Expanded(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Navigation items ──────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPad,
            height: 88,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isActive = i == currentIndex;

                Widget child;
                if (item.isCenter) {
                  child = _CenterButton(
                    icon: isActive ? item.activeIcon : item.icon,
                    label: item.label,
                    isActive: isActive,
                    accentColor: accentColor,
                    onTap: () => onTap(i),
                  );
                } else {
                  child = _NavButton(
                    icon: isActive ? item.activeIcon : item.icon,
                    label: item.label,
                    isActive: isActive,
                    accentColor: accentColor,
                    onTap: () => onTap(i),
                  );
                }

                return Expanded(child: child);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// The raised circular center button.
class _CenterButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _CenterButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Raised circle
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final glowIntensity = widget.isActive
                    ? 0.3 + (_pulseController.value * 0.2)
                    : 0.15;
                return Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isActive
                          ? [
                              widget.accentColor,
                              widget.accentColor.withValues(alpha: 0.8),
                            ]
                          : [
                              widget.accentColor.withValues(alpha: 0.6),
                              widget.accentColor.withValues(alpha: 0.4),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            widget.accentColor.withValues(alpha: glowIntensity),
                        blurRadius: widget.isActive ? 20 : 12,
                        spreadRadius: widget.isActive ? 2 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 26,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                );
              },
            ),
            SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isActive
                    ? widget.accentColor
                    : Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Regular (non-center) nav button.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(bottom: 8, top: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: isActive
                    ? accentColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            SizedBox(height: 4),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
            ),
            SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? accentColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
