import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/case_registration_screen.dart';
import 'package:pratidnya/src/features/03_precedent_search/presentation/screens/precedent_search_screen.dart';
import 'package:pratidnya/src/features/06_high_court/presentation/screens/high_court_appellate_screen.dart';
import 'package:pratidnya/src/features/09_ecourts_cis/presentation/screens/daily_cause_list_screen.dart';
import 'package:pratidnya/src/features/10_compliance_audit/presentation/screens/dpdp_compliance_screen.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Goal 46: Core Screens Redesign Widget Tests', () {
    testWidgets('CaseRegistrationScreen renders with luxury statute selector and form fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const CaseRegistrationScreen(),
          ),
        ),
      );

      expect(find.text('लागू विधिक संहिता चयन (Substantive Code)'), findsOneWidget);
      expect(find.text('हाइब्रिड (समकालिक)'), findsOneWidget);
      expect(find.text('प्राथमिक वाद विवरण (FIR Identifiers)'), findsOneWidget);
    });

    testWidgets('PrecedentSearchScreen renders with bench filters and verified citation cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.darkTheme,
            home: const PrecedentSearchScreen(),
          ),
        ),
      );

      expect(find.text('उच्चतम न्यायालय (SC)'), findsOneWidget);
      expect(find.text('सतेन्द्र कुमार अंतिल बनाम सी.बी.आई. (2022) 10 SCC 51'), findsOneWidget);
    });

    testWidgets('HighCourtAppellateScreen renders tabs and Limitation Act Section 12 deduction card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const HighCourtAppellateScreen(),
          ),
        ),
      );

      expect(find.text('अपील / पुनरीक्षण मेमो'), findsOneWidget);
      expect(find.text('म्याद गणना (Limitation Calculator)'), findsOneWidget);
    });

    testWidgets('DailyCauseListScreen renders today/tomorrow chips and docket item cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.darkTheme,
            home: const DailyCauseListScreen(),
          ),
        ),
      );

      expect(find.text('आज की सूची (Today)'), findsOneWidget);
      expect(find.text('मु.अ.सं. 124/2026'), findsOneWidget);
    });

    testWidgets('DpdpComplianceScreen renders BCI Rule 36 card and DPDP Section 11 & 8(7) actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: StitchTheme.lightTheme,
            home: const DpdpComplianceScreen(),
          ),
        ),
      );

      expect(find.text('बार काउंसिल ऑफ इंडिया नियम 36 प्रमाणन'), findsOneWidget);
      expect(find.text('चैंबर डेटा बंडल डाउनलोड करें (Section 11)'), findsOneWidget);
      expect(find.text('स्थायी डेटा विलोपन (Right to Erasure - Sec 8(7))'), findsOneWidget);
    });
  });
}
