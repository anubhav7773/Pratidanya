import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/forensic_evidence_vault_screen.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Goal 43: ForensicEvidenceVaultScreen renders and toggles between all 3 Pillar B tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: StitchTheme.lightTheme,
          home: const ForensicEvidenceVaultScreen(
            caseId: 'TEST-FORENSIC-902',
            accusedName: 'अभियुक्त',
            policeStation: 'कोतवाली',
            district: 'लखनऊ',
          ),
        ),
      ),
    );

    // Initial View: Tab 1 (Electronic Evidence Sec 63 BSA)
    expect(find.text('इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र परीक्षक (धारा 63 BSA)'), findsOneWidget);
    expect(find.text('प्रदर्श / मार्क (Exhibit Mark)'), findsOneWidget);

    // Switch to Tab 2 (Medico-Legal Conflict Matrix)
    await tester.tap(find.text('चिकित्सीय'));
    await tester.pumpAndSettle();

    // Verify Tab 2 rendered
    expect(find.text('चिकित्सीय बनाम प्रत्यक्षदर्शी साक्ष्य मैट्रिक्स'), findsOneWidget);
    expect(find.text('पोस्टमार्टम / MLC आख्या संख्या'), findsOneWidget);

    // Switch to Tab 3 (Malkhana Chain)
    await tester.tap(find.text('मालखाना'));
    await tester.pumpAndSettle();

    // Verify Tab 3 rendered
    expect(find.text('मालखाना रजिस्टर 19 व FSL अभिरक्षा शृंखला'), findsOneWidget);
    expect(find.text('मालखाना रजिस्टर संख्या 19 प्रविष्टि (Reg 19 Entry)'), findsOneWidget);
  });
}
