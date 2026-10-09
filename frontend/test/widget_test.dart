import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plately_app/core/services/app_settings.dart';
import 'package:plately_app/core/widgets/dual_mode_nav_bar.dart';

void main() {
  testWidgets('DualModeNavBar renders cook navigation items', (WidgetTester tester) async {
    int tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: DualModeNavBar(
            currentIndex: 0,
            mode: AppMode.cook,
            onTap: (index) => tappedIndex = index,
            items: const [
              NavItem(
                icon: Icons.restaurant_outlined,
                activeIcon: Icons.restaurant,
                label: 'Cook',
              ),
              NavItem(
                icon: Icons.camera_alt_outlined,
                activeIcon: Icons.camera_alt,
                label: 'Scan',
                isCenter: true,
              ),
              NavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: 'Shelf',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Cook'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Shelf'), findsOneWidget);

    await tester.tap(find.text('Shelf'));
    expect(tappedIndex, 2);
  });

  testWidgets('DualModeNavBar renders order mode navigation items', (WidgetTester tester) async {
    int tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: DualModeNavBar(
            currentIndex: 0,
            mode: AppMode.order,
            onTap: (index) => tappedIndex = index,
            items: const [
              NavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront,
                label: 'Order',
              ),
              NavItem(
                icon: Icons.play_circle_outline,
                activeIcon: Icons.play_circle_filled,
                label: 'Feeds',
                isCenter: true,
              ),
              NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Explore',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Feeds'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);

    await tester.tap(find.text('Feeds'));
    expect(tappedIndex, 1);
  });
}
