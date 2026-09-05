import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/shared/components/bci_disclaimer_banner.dart';
import 'package:pratidnya/src/shared/components/statute_selector_bar.dart';

void main() {
  testWidgets('Pratidnya core widgets smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const BciDisclaimerBanner(),
              StatuteSelectorBar(
                selectedSystem: StatuteSystem.hybrid,
                onSystemChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('विधिक अस्वीकरण (BCI नियम 5)'), findsOneWidget);
    expect(find.text('हाइब्रिड (दोनों)'), findsOneWidget);
  });
}
