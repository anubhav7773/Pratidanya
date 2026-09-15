import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/dashboard_screen.dart';
import 'package:pratidnya/src/shared/components/executive_dock_navigation_bar.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Goal 50: Live Docket Seeding & End-to-End Integration Tests', () {
    testWidgets('Dashboard loads realistic seeded dockets and renders dynamic chamber metrics', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      // Verify Dashboard rendered with seeded cases
      expect(find.text('सक्रिय आपराधिक डॉकेट'), findsOneWidget);

      // Verify dynamic metrics (5 total cases loaded from seeded repository)
      expect(find.text('05'), findsWidgets); // 5 Total Cases & In Custody count

      // Verify seeded realistic Lucknow case numbers
      expect(find.text('मु.अ.सं. 124/2026'), findsOneWidget);
      expect(find.text('रामू उर्फ राम प्रकाश'), findsOneWidget);
      expect(find.text('डिफ़ॉल्ट जमानत प्रोद्भूत (Sec 187)'), findsOneWidget);

      expect(find.text('मु.अ.सं. 89/2026'), findsOneWidget);
      expect(find.text('दिनेश कुमार'), findsOneWidget);
      expect(find.text('FSL / सील दोष (Reg 19)'), findsOneWidget);

      expect(find.text('मु.अ.सं. 302/2024'), findsOneWidget);
      expect(find.text('मोहम्मद असलम'), findsOneWidget);
      expect(find.text('1/3 सजा पूर्ण (Sec 479)'), findsOneWidget);

      // Test Filter Chips: Switch to "In Custody"
      final inCustodyChipFinder = find.text('जेल अभिरक्षा');
      expect(inCustodyChipFinder, findsOneWidget);
      await tester.tap(inCustodyChipFinder);
      await tester.pumpAndSettle();

      // Verify filtered count badge updated
      expect(find.text('4 वाद'), findsOneWidget);
    });

    testWidgets('Docket card tap routes directly to corresponding defense suite', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      // Initial tab index is 0
      expect(container.read(executiveNavIndexProvider), 0);

      // Tap Default Bail urgent card -> jumps to Remand Suite (index 1)
      final defaultBailCard = find.text('मु.अ.सं. 124/2026');
      expect(defaultBailCard, findsOneWidget);
      await tester.tap(defaultBailCard);
      await tester.pumpAndSettle();

      expect(container.read(executiveNavIndexProvider), 1);

      // Tap Forensic Tampering card -> jumps to Forensics Suite (index 2)
      final forensicsCard = find.text('मु.अ.सं. 89/2026');
      expect(forensicsCard, findsOneWidget);
      await tester.tap(forensicsCard);
      await tester.pumpAndSettle();

      expect(container.read(executiveNavIndexProvider), 2);
    });
  });
}
