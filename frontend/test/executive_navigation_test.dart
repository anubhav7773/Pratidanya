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
    expect(find.text('गिरफ्तारी व रिमांड अनुपालन परीक्षक'), findsOneWidget);

    // Tap on Forensics (Tab 2)
    final forensicsTabFinder = find.byIcon(Icons.fingerprint);
    expect(forensicsTabFinder, findsOneWidget);
    await tester.tap(forensicsTabFinder);
    await tester.pumpAndSettle();

    // Verify Tab 2 screen content rendered
    expect(find.text('इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र परीक्षक (Sec 63 BSA)'), findsOneWidget);
  });
}
