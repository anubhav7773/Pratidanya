import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/regional_hud_studio_screen.dart';
import 'package:pratidnya/src/core/theme/stitch_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Goal 45: RegionalHudStudioScreen mounts and toggles between Regional Acts, Sureties & Live HUD', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: StitchTheme.lightTheme,
          home: const RegionalHudStudioScreen(
            caseId: 'TEST-REGIONAL-701',
            accusedName: 'अभियुक्त',
            policeStation: 'कोतवाली',
            district: 'लखनऊ',
          ),
        ),
      ),
    );

    // Initial View: Tab 1 (UP Gangsters & Goondas)
    expect(find.text('उ.प्र. प्रादेशिक विशेष अधिनियम परीक्षक'), findsOneWidget);
    expect(find.text('संबंधित प्रादेशिक अधिनियम'), findsOneWidget);

    // Switch to Tab 2 (Surety Scrutiny - Moti Ram)
    await tester.tap(find.text('जमानत प्रतिभू (Moti Ram)'));
    await tester.pumpAndSettle();

    // Verify Tab 2 rendered
    expect(find.text('जमानत बंधपत्र व प्रतिभू परीक्षण (मोती राम सिद्धांत)'), findsOneWidget);
    expect(find.text('अधिरोपित जमानत बंधपत्र धनराशि (₹)'), findsOneWidget);

    // Switch to Tab 3 (Live Courtroom HUD)
    await tester.tap(find.text('लाइव'));
    await tester.pumpAndSettle();

    // Verify Tab 3 rendered
    expect(find.text('लाइव कोर्टरूम ओरल प्रॉम्टर (Edge HUD)'), findsOneWidget);
    expect(find.text('< 450ms Edge Active'), findsOneWidget);
  });
}
