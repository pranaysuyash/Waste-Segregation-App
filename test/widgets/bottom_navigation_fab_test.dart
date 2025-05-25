import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/bottom_navigation/modern_bottom_nav.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_buttons.dart';

void main() {
  group('Bottom Navigation Tests', () {
    testWidgets('ModernBottomNavigation displays all items correctly', (WidgetTester tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: selectedIndex,
              onTap: (index) => selectedIndex = index,
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                BottomNavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'History',
                ),
                BottomNavItem(
                  icon: Icons.school_outlined,
                  selectedIcon: Icons.school,
                  label: 'Learn',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget); // Selected icon
      expect(find.byIcon(Icons.history_outlined), findsOneWidget); // Unselected icon
    });

    testWidgets('ModernBottomNavigation handles tap events correctly', (WidgetTester tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: const Text('Test'),
                bottomNavigationBar: ModernBottomNavigation(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  items: const [
                    BottomNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                    ),
                    BottomNavItem(
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history,
                      label: 'History',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Tap on History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history), findsOneWidget); // Should be selected now
      expect(find.byIcon(Icons.home_outlined), findsOneWidget); // Should be unselected
    });

    testWidgets('ModernBottomNavigation adapts to narrow screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: SizedBox(
              width: 300, // Narrow width
              child: ModernBottomNavigation(
                currentIndex: 0,
                onTap: (index) {},
                items: const [
                  BottomNavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                  ),
                  BottomNavItem(
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                    label: 'History',
                  ),
                  BottomNavItem(
                    icon: Icons.school_outlined,
                    selectedIcon: Icons.school,
                    label: 'Learn',
                  ),
                  BottomNavItem(
                    icon: Icons.emoji_events_outlined,
                    selectedIcon: Icons.emoji_events,
                    label: 'Rewards',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);
      // Should handle narrow width gracefully
      await tester.pumpAndSettle();
    });

    testWidgets('ModernBottomNavigation with notch layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              hasNotch: true,
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                BottomNavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'History',
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.camera_alt),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(BottomAppBar), findsOneWidget);
    });

    testWidgets('ModernBottomNavigation glassmorphism style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              style: ModernBottomNavStyle.glassmorphism(
                primaryColor: Colors.blue,
                isDark: false,
              ),
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                BottomNavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'History',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);
    });

    testWidgets('ModernBottomNavigation material3 style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              style: ModernBottomNavStyle.material3(
                primaryColor: Colors.green,
                isDark: false,
              ),
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                BottomNavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'History',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);
    });

    testWidgets('ModernBottomNavigation floating style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              style: ModernBottomNavStyle.floating(
                primaryColor: Colors.purple,
                isDark: false,
              ),
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                BottomNavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'History',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);
    });

    testWidgets('ModernBottomNavigation handles long labels gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: SizedBox(
              width: 300, // Narrow to test overflow
              child: ModernBottomNavigation(
                currentIndex: 0,
                onTap: (index) {},
                items: const [
                  BottomNavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Very Long Home Label',
                  ),
                  BottomNavItem(
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                    label: 'Extremely Long History Label',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);
      // Should handle long labels without overflow
      await tester.pumpAndSettle();
    });

    testWidgets('ModernBottomNavigation animation test', (WidgetTester tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: const Text('Test'),
                bottomNavigationBar: ModernBottomNavigation(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  animationDuration: const Duration(milliseconds: 100), // Fast for testing
                  items: const [
                    BottomNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'Home',
                    ),
                    BottomNavItem(
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history,
                      label: 'History',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Tap and wait for animation
      await tester.tap(find.text('History'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 50)); // Mid animation
      await tester.pumpAndSettle(); // Complete animation

      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('Modern FAB Tests', () {
    testWidgets('ModernFAB displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            floatingActionButton: ModernFAB(
              onPressed: () {},
              icon: Icons.camera_alt,
            ),
          ),
        ),
      );

      expect(find.byType(ModernFAB), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('ModernFAB extended version displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            floatingActionButton: ModernFAB(
              onPressed: () {},
              icon: Icons.camera_alt,
              label: 'Take Photo',
              isExtended: true,
            ),
          ),
        ),
      );

      expect(find.byType(ModernFAB), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
    });

    testWidgets('ModernFAB handles tap events correctly', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            floatingActionButton: ModernFAB(
              onPressed: () => tapped = true,
              icon: Icons.camera_alt,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ModernFAB));
      expect(tapped, isTrue);
    });

    testWidgets('ModernFAB with badge displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            floatingActionButton: ModernFAB(
              onPressed: () {},
              icon: Icons.camera_alt,
              showBadge: true,
              badgeText: '3',
            ),
          ),
        ),
      );

      expect(find.byType(ModernFAB), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('ModernFAB animation test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            floatingActionButton: ModernFAB(
              onPressed: () {},
              icon: Icons.camera_alt,
            ),
          ),
        ),
      );

      // Test tap down animation
      await tester.press(find.byType(ModernFAB));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Test tap up animation
      await tester.pumpAndSettle();

      expect(find.byType(ModernFAB), findsOneWidget);
    });

    testWidgets('ModernFAB custom colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            floatingActionButton: ModernFAB(
              onPressed: () {},
              icon: Icons.camera_alt,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );

      expect(find.byType(ModernFAB), findsOneWidget);
    });
  });

  group('Bottom Navigation Integration Tests', () {
    testWidgets('Bottom navigation with FAB integration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              hasNotch: true,
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                BottomNavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'History',
                ),
              ],
            ),
            floatingActionButton: ModernFAB(
              onPressed: () {},
              icon: Icons.camera_alt,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);
      expect(find.byType(ModernFAB), findsOneWidget);
      expect(find.byType(BottomAppBar), findsOneWidget);
    });

    testWidgets('Bottom navigation theme compatibility', (WidgetTester tester) async {
      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModernBottomNavigation), findsOneWidget);
    });

    testWidgets('Bottom navigation performance test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              items: List.generate(
                5,
                (index) => BottomNavItem(
                  icon: Icons.circle_outlined,
                  selectedIcon: Icons.circle,
                  label: 'Tab $index',
                ),
              ),
            ),
          ),
        ),
      );

      // Should handle multiple tabs efficiently
      expect(find.byType(ModernBottomNavigation), findsOneWidget);
      for (int i = 0; i < 5; i++) {
        expect(find.text('Tab $i'), findsOneWidget);
      }
    });

    testWidgets('Bottom navigation accessibility test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test'),
            bottomNavigationBar: ModernBottomNavigation(
              currentIndex: 0,
              onTap: (index) {},
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                BottomNavItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'History',
                ),
              ],
            ),
          ),
        ),
      );

      // Should be accessible by text
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      
      // Should be tappable
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
    });
  });
} 