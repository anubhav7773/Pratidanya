import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/core/security/advocate_privilege_guard.dart';
import 'package:pratidnya/src/features/10_compliance_audit/presentation/screens/chamber_privacy_audit_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goal 19: Advocate Privilege Guard & FLAG_SECURE MethodChannel Tests', () {
    final List<MethodCall> methodCalls = [];

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      methodCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('me.asiverticals.pratidnya/security'),
        (MethodCall call) async {
          methodCalls.add(call);
          if (call.method == 'enableSecureWindow' || call.method == 'disableSecureWindow') {
            return true;
          }
          return null;
        },
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('me.asiverticals.pratidnya/security'),
        null,
      );
    });

    test('AdvocatePrivilegeGuard executes enableSecureWindow method call', () async {
      await AdvocatePrivilegeGuard.enableConfidentialityProtection();
      expect(methodCalls.any((call) => call.method == 'enableSecureWindow'), isTrue);
    });

    test('AdvocatePrivilegeGuard executes disableSecureWindow method call', () async {
      await AdvocatePrivilegeGuard.disableConfidentialityProtection();
      expect(methodCalls.any((call) => call.method == 'disableSecureWindow'), isTrue);
    });
  });

  group('Goal 19: Chamber Privacy Audit Screen UI & Devanagari Typography Tests', () {
    testWidgets('ChamberPrivacyAuditScreen renders BCI banner, DPDP headers, and action tiles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChamberPrivacyAuditScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Screen Title & Sections
      expect(find.text('चैंबर विधिक ऑडिट एवं डेटा संरक्षण (DPDP)'), findsOneWidget);
      expect(find.text('सांविधिक विधिक अनुपालन स्थिति (DPDP Act 2023)'), findsOneWidget);
      expect(find.text('बार काउंसिल ऑफ इंडिया नियम 36 प्रमाणन'), findsOneWidget);
      expect(find.text('डेटा प्रदाता अधिकार (Data Principal Rights)'), findsOneWidget);

      // Verify Action Tiles
      expect(find.text('चैंबर डेटा बंडल डाउनलोड करें'), findsOneWidget);
      expect(find.text('स्थायी डेटा विलोपन (Right to Erasure)'), findsOneWidget);

      // Verify Devanagari line-height consistency (1.35 - 1.45)
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        if (text.style?.height != null) {
          expect(text.style!.height, greaterThanOrEqualTo(1.35));
          expect(text.style!.height, lessThanOrEqualTo(1.45));
        }
      }
    });

    testWidgets('Tapping Right to Erasure opens confirmation dialog with warning', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChamberPrivacyAuditScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Right to Erasure tile
      await tester.tap(find.text('स्थायी डेटा विलोपन (Right to Erasure)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify AlertDialog is displayed with statutory warning
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('चेतावनी: यह क्रिया अपरिवर्तनीय है। डीपीसपी अधिनियम 2023 की धारा 8(7) के अंतर्गत आपके सभी केस, ड्राफ्ट, वॉयस रिकॉर्ड्स एवं प्रोफाइल डेटा को डेटाबेस से स्थायी रूप से हटा दिया जाएगा।\n\nक्या आप विलोपन की पुष्टि करते हैं?'), findsOneWidget);
      expect(find.text('हाँ, सब कुछ स्थायी रूप से मिटाएं'), findsOneWidget);
      expect(find.text('रद्द करें'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('रद्द करें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
