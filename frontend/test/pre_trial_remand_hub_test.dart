import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/pre_trial_remand_hub_screen.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Goal 42: PreTrialRemandHubScreen mounts and toggles between all 3 Pillar A tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: StitchTheme.lightTheme,
          home: const PreTrialRemandHubScreen(
            caseId: 'TEST-CASE-104',
            accusedName: 'रामू',
            policeStation: 'कोतवाली',
            district: 'लखनऊ',
          ),
        ),
      ),
    );

    // Initial view: Tab 1 (Default Bail Tracker)
    expect(find.text('सांविधिक डिफ़ॉल्ट जमानत ट्रैकर (धारा 187 BNSS)'), findsOneWidget);
    expect(find.text('प्रथम रिमांड दिनांक (First Remand):'), findsOneWidget);

    // Switch to Tab 2 (Remand Compliance)
    await tester.tap(find.text('गिरफ्तारी'));
    await tester.pumpAndSettle();

    // Verify Tab 2 rendered
    expect(find.text('गिरफ्तारी व रिमांड विधिक अनुपालन चेकलिस्ट'), findsOneWidget);
    expect(find.text('अर्नेश कुमार व सतेन्द्र कुमार अंतिल दिशानिर्देश (श्रेणी क-घ)'), findsOneWidget);

    // Switch to Tab 3 (Undertrial Relief)
    await tester.tap(find.text('विचाराधीन'));
    await tester.pumpAndSettle();

    // Verify Tab 3 rendered
    expect(find.text('धारा 479 BNSS विचाराधीन बंदी गणना (1/3 नियम)'), findsOneWidget);
    expect(find.text('1/3 सांविधिक अवधि व पात्रता जांचें'), findsOneWidget);
  });
}
