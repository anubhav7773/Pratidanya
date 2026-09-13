import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/trial_examination_studio_screen.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Goal 44: TrialExaminationStudioScreen renders and toggles between Impeachment and Cross-Exam Deck', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: StitchTheme.lightTheme,
          home: const TrialExaminationStudioScreen(
            caseId: 'TEST-TRIAL-101',
            accusedName: 'अभियुक्त',
            policeStation: 'कोतवाली',
            district: 'लखनऊ',
          ),
        ),
      ),
    );

    // Initial View: Tab 1 (Witness Impeachment Grid)
    expect(find.text('साक्षी अंतर्विरोध ग्रिड (तहसीलदार सिंह सिद्धांत)'), findsOneWidget);
    expect(find.text('साक्षी कोड (उदा. PW-1, PW-2)'), findsOneWidget);

    // Switch to Tab 2 (Leading Question Deck)
    await tester.tap(find.text('सूचक जिरह प्रश्न डेक'));
    await tester.pumpAndSettle();

    // Verify Tab 2 rendered
    expect(find.text('सूचक जिरह प्रश्न डेक (धारा 147 BSA)'), findsOneWidget);
    expect(find.text('बचाव पक्ष का सिद्धांत (Defense Theory)'), findsOneWidget);
  });
}
