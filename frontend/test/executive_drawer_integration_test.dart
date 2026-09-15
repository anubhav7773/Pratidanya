import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/dashboard_screen.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/case_registration_screen.dart';
import 'package:pratidnya/src/features/03_precedent_search/presentation/screens/precedent_search_screen.dart';
import 'package:pratidnya/src/features/06_high_court/presentation/screens/high_court_appellate_studio_screen.dart';
import 'package:pratidnya/src/features/09_ecourts_cis/presentation/screens/daily_cause_list_screen.dart';
import 'package:pratidnya/src/features/billing/presentation/screens/executive_billing_screen.dart';
import 'package:pratidnya/src/features/10_compliance_audit/presentation/screens/dpdp_compliance_screen.dart';
import 'package:pratidnya/src/shared/components/executive_chamber_drawer.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Goal 48: Master Chamber Drawer & Screen Re-integration Tests', () {
    void setupLargeViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('Dashboard hamburger menu opens ExecutiveChamberDrawer with all recovered modules and routes to Precedents', (tester) async {
      setupLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      // Initial check: Dashboard AppBar loaded
      expect(find.text('सक्रिय आपराधिक डॉकेट'), findsOneWidget);

      // Find and tap the hamburger menu icon
      final menuIconFinder = find.byIcon(Icons.menu_rounded);
      expect(menuIconFinder, findsOneWidget);
      await tester.tap(menuIconFinder);
      await tester.pumpAndSettle();

      // Verify ExecutiveChamberDrawer opened with advocate profile
      expect(find.byType(ExecutiveChamberDrawer), findsOneWidget);
      expect(find.text('Adv. Anubhav Singh'), findsOneWidget);
      expect(find.text('UP/1234/2018 • Lucknow Bench'), findsOneWidget);

      // Verify all recovered core screens exist in drawer list
      expect(find.text('नया केस दर्ज करें (Voice Intake)'), findsOneWidget);
      expect(find.text('कानूनी मिसाल खोज (Precedents)'), findsOneWidget);
      expect(find.text('दैनिक कॉज लिस्ट (CIS 3.2)'), findsOneWidget);
      expect(find.text('अपील / पुनरीक्षण मेमो'), findsOneWidget);
      expect(find.text('अधिवक्ता कोटा एवं सदस्यता'), findsOneWidget);
      expect(find.text('चैंबर विधिक ऑडिट (DPDP)'), findsOneWidget);

      // Tap Precedent Search and verify navigation
      await tester.tap(find.text('कानूनी मिसाल खोज (Precedents)'));
      await tester.pumpAndSettle();

      // Verify PrecedentSearchScreen rendered
      expect(find.byType(PrecedentSearchScreen), findsOneWidget);
    });

    testWidgets('Drawer navigates cleanly to CaseRegistrationScreen', (tester) async {
      setupLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('नया केस दर्ज करें (Voice Intake)'));
      await tester.pumpAndSettle();

      expect(find.byType(CaseRegistrationScreen), findsOneWidget);
    });

    testWidgets('Drawer navigates cleanly to DailyCauseListScreen', (tester) async {
      setupLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('दैनिक कॉज लिस्ट (CIS 3.2)'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyCauseListScreen), findsOneWidget);
    });

    testWidgets('Drawer navigates cleanly to HighCourtAppellateStudioScreen', (tester) async {
      setupLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('अपील / पुनरीक्षण मेमो'));
      await tester.pumpAndSettle();

      expect(find.byType(HighCourtAppellateStudioScreen), findsOneWidget);
    });

    testWidgets('Drawer navigates cleanly to ExecutiveBillingScreen', (tester) async {
      setupLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('अधिवक्ता कोटा एवं सदस्यता'));
      await tester.pumpAndSettle();

      expect(find.byType(ExecutiveBillingScreen), findsOneWidget);
    });

    testWidgets('Drawer navigates cleanly to DpdpComplianceScreen', (tester) async {
      setupLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('चैंबर विधिक ऑडिट (DPDP)'));
      await tester.pumpAndSettle();

      expect(find.byType(DpdpComplianceScreen), findsOneWidget);
    });

    testWidgets('Dashboard FloatingActionButton opens CaseRegistrationScreen directly', (tester) async {
      setupLargeViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(find.byType(CaseRegistrationScreen), findsOneWidget);
    });
  });
}
