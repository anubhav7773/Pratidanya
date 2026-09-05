import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/core/config/app_environment.dart';
import 'package:pratidnya/src/features/01_onboarding/domain/advocate_profile.dart';
import 'package:pratidnya/src/shared/components/bci_disclaimer_banner.dart';
import 'package:pratidnya/src/shared/components/stitch_hindi_text_field.dart';

void main() {
  group('Goal 3: AppEnvironment Security Validation', () {
    test('Development environment passes validation with defaults', () {
      expect(() => AppEnvironment.validateEnvironmentSecurity(), returnsNormally);
    });
  });

  group('Goal 3: AdvocateProfile Domain Serialization', () {
    test('JSON serialization and deserialization roundtrip works correctly', () {
      final now = DateTime.now().toUtc();
      final profile = AdvocateProfile(
        id: 'firebase_uid_test_123',
        email: 'advocate.sharma@lucknowcourt.in',
        fullName: 'अधिवक्ता आलोक शर्मा',
        barCouncilNumber: 'UP/9876/2015',
        enrolledState: 'Uttar Pradesh',
        primaryCourtName: 'जिला एवं सत्र न्यायालय, लखनऊ',
        courtType: 'DISTRICT_SUBORDINATE',
        chamberAddress: 'चैंबर नं 12, बार एसोसिएशन भवन',
        dpdpConsentAccepted: true,
        dpdpConsentTimestamp: now,
      );

      final json = profile.toJson();
      expect(json['id'], 'firebase_uid_test_123');
      expect(json['full_name'], 'अधिवक्ता आलोक शर्मा');
      expect(json['bar_council_number'], 'UP/9876/2015');
      expect(json['dpdp_consent_accepted'], true);

      final reconstructed = AdvocateProfile.fromJson(json);
      expect(reconstructed.id, profile.id);
      expect(reconstructed.email, profile.email);
      expect(reconstructed.fullName, profile.fullName);
      expect(reconstructed.barCouncilNumber, profile.barCouncilNumber);
      expect(reconstructed.dpdpConsentAccepted, isTrue);
    });
  });

  group('Goal 3: Statutory Routing Gate Decision Logic', () {
    // Simulates redirect logic defined in app_router.dart
    String? simulateGateRedirect({
      required bool isAuthenticated,
      required String currentPath,
      required bool hasConsented,
      required String? barNumber,
    }) {
      final isLoggingIn = currentPath == '/login';
      final isConsentScreen = currentPath == '/dpdp-consent';
      final isBarEnrollmentScreen = currentPath == '/bar-enrollment';

      // Gate 1: Check Authentication
      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // Gate 2: Mandatory DPDP Statutory Consent
      if (!hasConsented) {
        return isConsentScreen ? null : '/dpdp-consent';
      }

      // Gate 3: Advocates Act Enrolled Verification Gate
      if (barNumber == null || barNumber.trim().isEmpty) {
        return isBarEnrollmentScreen ? null : '/bar-enrollment';
      }

      if (isLoggingIn || isConsentScreen || isBarEnrollmentScreen) {
        return '/cases';
      }

      return null;
    }

    test('Gate 1: Unauthenticated user is redirected to /login', () {
      final redirect = simulateGateRedirect(
        isAuthenticated: false,
        currentPath: '/cases',
        hasConsented: false,
        barNumber: null,
      );
      expect(redirect, '/login');
    });

    test('Gate 1: Unauthenticated user on /login stays on /login', () {
      final redirect = simulateGateRedirect(
        isAuthenticated: false,
        currentPath: '/login',
        hasConsented: false,
        barNumber: null,
      );
      expect(redirect, isNull);
    });

    test('Gate 2: Authenticated user without DPDP consent is redirected to /dpdp-consent', () {
      final redirect = simulateGateRedirect(
        isAuthenticated: true,
        currentPath: '/cases',
        hasConsented: false,
        barNumber: null,
      );
      expect(redirect, '/dpdp-consent');
    });

    test('Gate 3: Authenticated with DPDP consent but missing Bar Number is redirected to /bar-enrollment', () {
      final redirect = simulateGateRedirect(
        isAuthenticated: true,
        currentPath: '/cases',
        hasConsented: true,
        barNumber: '',
      );
      expect(redirect, '/bar-enrollment');
    });

    test('Full Verification: Fully enrolled advocate on /login is redirected to /cases', () {
      final redirect = simulateGateRedirect(
        isAuthenticated: true,
        currentPath: '/login',
        hasConsented: true,
        barNumber: 'UP/1234/2018',
      );
      expect(redirect, '/cases');
    });
  });

  group('Goal 3: Devanagari Font Rendering & Shared Components', () {
    testWidgets('StitchHindiTextField renders complex Hindi phrases without error', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'प्रत्यक्षदर्शी साक्षी एवं दांडिक पुनरीक्षण');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StitchHindiTextField(
              controller: controller,
              label: 'अभियोग पत्र विवरण (धारा 302/34 भा.दं.वि.)',
              hint: 'विधिक तथ्य दर्ज करें',
            ),
          ),
        ),
      );

      expect(find.text('प्रत्यक्षदर्शी साक्षी एवं दांडिक पुनरीक्षण'), findsOneWidget);
      expect(find.text('अभियोग पत्र विवरण (धारा 302/34 भा.दं.वि.)'), findsOneWidget);
    });

    testWidgets('BciDisclaimerBanner renders statutory BCI Rule 5 notice', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BciDisclaimerBanner(),
          ),
        ),
      );

      expect(find.textContaining('विधिक अस्वीकरण (BCI नियम 5)'), findsOneWidget);
      expect(find.textContaining('स्वतंत्र पेशेवर विवेक का प्रयोग अनिवार्य है'), findsOneWidget);
    });
  });
}
