import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/features/navigation/presentation/executive_shell_scaffold.dart';
import 'package:pratidnya/src/shared/components/executive_dock_navigation_bar.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Goal 41: ExecutiveDockNavigationBar renders tabs and updates state on tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: StitchTheme.lightTheme,
          home: const ExecutiveShellScaffold(),
        ),
      ),
    );

    // Initial load: Tab 0 (Dashboard / Dockets)
    expect(find.byType(ExecutiveDockNavigationBar), findsOneWidget);
    expect(find.text('सक्रिय आपराधिक डॉकेट'), findsOneWidget);

    // Tap on Remand Defense (Tab 1)
    final remandTabFinder = find.byIcon(Icons.gavel_outlined);
    expect(remandTabFinder, findsOneWidget);
    await tester.tap(remandTabFinder);
    await tester.pumpAndSettle();

    // Verify Tab 1 screen content rendered
    expect(find.text('सांविधिक डिफ़ॉल्ट जमानत ट्रैकर (धारा 187 BNSS)'), findsOneWidget);

    // Tap on Forensics (Tab 2)
    final forensicsTabFinder = find.byIcon(Icons.fingerprint);
    expect(forensicsTabFinder, findsOneWidget);
    await tester.tap(forensicsTabFinder);
    await tester.pumpAndSettle();

    // Verify Tab 2 screen content rendered
    expect(find.text('इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र परीक्षक (धारा 63 BSA)'), findsOneWidget);

    // Tap on Trial Studio (Tab 3)
    final trialStudioTabFinder = find.byIcon(Icons.record_voice_over_outlined);
    expect(trialStudioTabFinder, findsOneWidget);
    await tester.tap(trialStudioTabFinder);
    await tester.pumpAndSettle();

    // Verify Tab 3 screen content rendered
    expect(find.text('साक्षी अंतर्विरोध ग्रिड (तहसीलदार सिंह सिद्धांत)'), findsOneWidget);
  });
}
