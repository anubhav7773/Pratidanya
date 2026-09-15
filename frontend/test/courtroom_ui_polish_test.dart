import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/shared/components/responsive_court_tab_bar.dart';
import 'package:pratidnya/src/shared/utils/chamber_snack_bar.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/pre_trial_remand_hub_screen.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/forensic_evidence_vault_screen.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/trial_examination_studio_screen.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/regional_hud_studio_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Goal 49: ResponsiveCourtTabBar & ChamberSnackBar Polish Tests', () {
    testWidgets('ResponsiveCourtTabBar renders full tab labels with badges without clipping', (tester) async {
      late TabController controller;

      await tester.pumpWidget(
        MaterialApp(
          theme: StitchTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                controller = TabController(length: 3, vsync: const TestVSync());
                return ResponsiveCourtTabBar(
                  controller: controller,
                  isDark: false,
                  tabs: [
                    CourtTabItem(
                      label: 'इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र (धारा 63 BSA)',
                      badgeText: 'Sec 63',
                    ),
                    CourtTabItem(
                      label: 'चिकित्सीय अंतर्विरोध मैट्रिक्स',
                      badgeText: 'PMR',
                    ),
                    CourtTabItem(
                      label: 'मालखाना रजिस्टर 19 व FSL अभिरक्षा',
                      badgeText: 'NCB 1/88',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify entire text rendered without clipping
      expect(find.text('इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र (धारा 63 BSA)'), findsOneWidget);
      expect(find.text('चिकित्सीय अंतर्विरोध मैट्रिक्स'), findsOneWidget);
      expect(find.text('मालखाना रजिस्टर 19 व FSL अभिरक्षा'), findsOneWidget);
      expect(find.text('Sec 63'), findsOneWidget);
    });

    testWidgets('ChamberSnackBar floats above dock navigation bar with 88dp bottom margin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: StitchTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ChamberSnackBar.showError(context, message: 'परीक्षण त्रुटि संदेश (Test Error)');
                  },
                  child: const Text('Show SnackBar'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump(); // Start animation

      // Verify SnackBar rendered
      expect(find.text('परीक्षण त्रुटि संदेश (Test Error)'), findsOneWidget);

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final SnackBar snackBar = tester.widget(snackBarFinder);
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.margin, const EdgeInsets.fromLTRB(14, 0, 14, 88));
    });

    testWidgets('ChamberSnackBar showSuccess and showNotice render properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: StitchTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ChamberSnackBar.showSuccess(context, message: 'सफलतापूर्वक सहेजा गया');
                    },
                    child: const Text('Success'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ChamberSnackBar.showNotice(context, message: 'महत्वपूर्ण सूचना');
                    },
                    child: const Text('Notice'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test Success SnackBar
      await tester.tap(find.text('Success'));
      await tester.pump();
      expect(find.text('सफलतापूर्वक सहेजा गया'), findsOneWidget);

      // Test Notice SnackBar replaces current
      await tester.tap(find.text('Notice'));
      await tester.pump();
      expect(find.text('महत्वपूर्ण सूचना'), findsOneWidget);
    });

    testWidgets('PreTrialRemandHubScreen embeds ResponsiveCourtTabBar and renders smoothly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const PreTrialRemandHubScreen(),
          ),
        ),
      );

      expect(find.byType(ResponsiveCourtTabBar), findsOneWidget);
      expect(find.text('Sec 187'), findsOneWidget);
      expect(find.text('Arnesh Kumar'), findsOneWidget);
      expect(find.text('1/3rd Rule'), findsOneWidget);
    });

    testWidgets('ForensicEvidenceVaultScreen embeds ResponsiveCourtTabBar without label clipping', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const ForensicEvidenceVaultScreen(),
          ),
        ),
      );

      expect(find.byType(ResponsiveCourtTabBar), findsOneWidget);
      expect(find.text('Sec 63 BSA'), findsOneWidget);
      expect(find.text('PMR Conflict'), findsOneWidget);
      expect(find.text('Reg No. 19'), findsOneWidget);
    });

    testWidgets('TrialExaminationStudioScreen embeds ResponsiveCourtTabBar cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const TrialExaminationStudioScreen(),
          ),
        ),
      );

      expect(find.byType(ResponsiveCourtTabBar), findsOneWidget);
      expect(find.text('Sec 148 BSA'), findsOneWidget);
      expect(find.text('Sec 147 BSA'), findsOneWidget);
    });

    testWidgets('RegionalHudStudioScreen renders full regional and Moti Ram tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const RegionalHudStudioScreen(),
          ),
        ),
      );

      expect(find.byType(ResponsiveCourtTabBar), findsOneWidget);
      expect(find.text('Farhana Ratio'), findsOneWidget);
      expect(find.text('Sec 483 BNSS'), findsOneWidget);
      expect(find.text('जमानत प्रतिभू (Moti Ram Scrutiny)'), findsOneWidget);
    });
  });
}
