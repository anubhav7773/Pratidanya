import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/shared/components/custom_error_screen.dart';

void main() {
  group('Goal 4: Production Release Hardening & Play Store Readiness Tests', () {
    testWidgets('CustomErrorScreen renders graceful legal interface on framework exceptions', (tester) async {
      final errorDetails = FlutterErrorDetails(
        exception: Exception('Test UI Render Failure in Basement Courtroom'),
        stack: StackTrace.current,
        library: 'courtroom_render_library',
      );

      await tester.pumpWidget(
        CustomErrorScreen(errorDetails: errorDetails),
      );

      // Verify header and recovery notice
      expect(find.text('प्रतिज्ञा विधिक इंटरफ़ेस सूचना'), findsOneWidget);
      expect(find.textContaining('विधिक प्रपत्र रेंडरिंग में तकनीकी रुकावट आई है'), findsOneWidget);
      expect(find.textContaining('अधिवक्ता डेटा पूर्णतः सुरक्षित है'), findsOneWidget);

      // Verify Reload action
      expect(find.text('पुनः लोड करें (Reload)'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Verify DPDP & BCI trust seal
      expect(find.textContaining('DPDP Act 2023 एवं BCI Rule 36 अनुपालित'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    test('AndroidManifest contains mandatory production permissions including Google Play Billing', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final content = manifestFile.readAsStringSync();
      expect(content, contains('android.permission.INTERNET'));
      expect(content, contains('android.permission.ACCESS_NETWORK_STATE'));
      expect(content, contains('android.permission.RECORD_AUDIO'));
      expect(content, contains('com.android.vending.BILLING'));
      expect(content, contains('me.asiverticals.pratidnya'));
    });

    test('Pubspec YAML specifies production release version code 1.0.1+2', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = pubspecFile.readAsStringSync();
      expect(content, contains('version: 1.0.1+2'));
      expect(content, contains('name: pratidnya'));
    });

    test('Statutory Play Store compliance documents exist and contain required disclosures', () {
      final privacyPolicy = File('../docs/PRIVACY_POLICY.md');
      final termsOfService = File('../docs/TERMS_OF_SERVICE.md');
      final dataSafety = File('../docs/PLAY_STORE_DATA_SAFETY_AND_BCI_DECLARATION.md');

      expect(privacyPolicy.existsSync(), isTrue);
      expect(termsOfService.existsSync(), isTrue);
      expect(dataSafety.existsSync(), isTrue);

      final privacyContent = privacyPolicy.readAsStringSync();
      expect(privacyContent, contains('Digital Personal Data Protection Act, 2023'));
      expect(privacyContent, contains('Advocates Act, 1961'));
      expect(privacyContent, contains('Bar Council of India (BCI) Rules'));
      expect(privacyContent, contains('Right to Erasure'));
      expect(privacyContent, contains('dpo@asiverticals.me'));

      final termsContent = termsOfService.readAsStringSync();
      expect(termsContent, contains('Section 35 Gate: Mandatory Human Verification'));
      expect(termsContent, contains('Rule 36 Compliance'));
    });
  });
}
