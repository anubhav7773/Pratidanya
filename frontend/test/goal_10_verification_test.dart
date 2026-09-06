import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/core/config/app_environment.dart';
import 'package:pratidnya/src/core/utils/bar_council_validator.dart';

void main() {
  group('Goal 10: State Bar Council Validation Engine', () {
    test('Invalid prefix returns exact statutory failure message', () {
      final result = BarCouncilValidator.validateEnrollmentNumber(
        'MP/123/2018',
        'Uttar Pradesh',
      );
      expect(
        result,
        'Uttar Pradesh बार काउंसिल हेतु उपसर्ग UP होना चाहिए (प्राप्त: MP)।',
      );
    });

    test('Valid UP enrollment number passes validation', () {
      final result = BarCouncilValidator.validateEnrollmentNumber(
        'UP/1234/2018',
        'Uttar Pradesh',
      );
      expect(result, isNull);
    });

    test('Valid Delhi and Maharashtra enrollment numbers pass validation', () {
      expect(
        BarCouncilValidator.validateEnrollmentNumber('D/456/2015', 'Delhi'),
        isNull,
      );
      expect(
        BarCouncilValidator.validateEnrollmentNumber('MAH/7890/2022', 'Maharashtra & Goa'),
        isNull,
      );
    });

    test('Invalid formats and ranges are rejected', () {
      // Empty
      expect(
        BarCouncilValidator.validateEnrollmentNumber('', 'Uttar Pradesh'),
        'बार काउंसिल पंजीकरण संख्या अनिवार्य है।',
      );

      // Malformed format
      expect(
        BarCouncilValidator.validateEnrollmentNumber('UP-1234-2018', 'Uttar Pradesh'),
        'अमान्य प्रारूप। सही प्रारूप: राज्य/क्रमांक/वर्ष (उदा. UP/1234/2018)',
      );

      // Non-numeric or out-of-bounds sequence
      expect(
        BarCouncilValidator.validateEnrollmentNumber('UP/ABC/2018', 'Uttar Pradesh'),
        contains('अमान्य अनुक्रमांक'),
      );
      expect(
        BarCouncilValidator.validateEnrollmentNumber('UP/0/2018', 'Uttar Pradesh'),
        contains('अमान्य अनुक्रमांक'),
      );
      expect(
        BarCouncilValidator.validateEnrollmentNumber('UP/1234567/2018', 'Uttar Pradesh'),
        contains('अमान्य अनुक्रमांक'),
      );

      // Out of bounds year
      expect(
        BarCouncilValidator.validateEnrollmentNumber('UP/1234/1948', 'Uttar Pradesh'),
        contains('अमान्य नामांकन वर्ष'),
      );
      expect(
        BarCouncilValidator.validateEnrollmentNumber('UP/1234/2030', 'Uttar Pradesh'),
        contains('अमान्य नामांकन वर्ष'),
      );
    });

    test('All 19 State Bar Councils have registered prefixes', () {
      expect(BarCouncilValidator.statePrefixes.length, greaterThanOrEqualTo(19));
      expect(BarCouncilValidator.statePrefixes.containsKey('Uttar Pradesh'), isTrue);
      expect(BarCouncilValidator.statePrefixes.containsKey('Delhi'), isTrue);
      expect(BarCouncilValidator.statePrefixes.containsKey('Bihar'), isTrue);
      expect(BarCouncilValidator.statePrefixes.containsKey('Rajasthan'), isTrue);
      expect(BarCouncilValidator.statePrefixes.containsKey('Madhya Pradesh'), isTrue);
      expect(BarCouncilValidator.statePrefixes.containsKey('Gujarat'), isTrue);
      expect(BarCouncilValidator.statePrefixes.containsKey('West Bengal'), isTrue);
      expect(BarCouncilValidator.statePrefixes.containsKey('Karnataka'), isTrue);
    });
  });

  group('Goal 10: Cloud Endpoints & Security Environment', () {
    test('AppEnvironment production configuration is valid', () {
      expect(AppEnvironment.appEnv, 'PRODUCTION');
      expect(AppEnvironment.backendBaseUrl, 'https://pratidanya-backend.onrender.com');
      expect(AppEnvironment.supabaseUrl, startsWith('https://'));
      expect(AppEnvironment.supabaseUrl, contains('supabase.co'));
      expect(AppEnvironment.isGeminiPaidTier, isTrue);
      expect(AppEnvironment.enforceDummyData, isFalse);

      // Disengage localhost check
      expect(AppEnvironment.backendBaseUrl.contains('localhost'), isFalse);
      expect(AppEnvironment.backendBaseUrl.contains('10.0.2.2'), isFalse);

      // Must not throw in production
      expect(() => AppEnvironment.validateEnvironmentSecurity(), returnsNormally);
    });
  });

  group('Goal 10: Android TLS & Network Security Configuration', () {
    test('network_security_config.xml strictly disables cleartext traffic', () {
      final xmlFile = File('android/app/src/main/res/xml/network_security_config.xml');
      expect(xmlFile.existsSync(), isTrue);

      final xmlContent = xmlFile.readAsStringSync();
      expect(xmlContent, contains('cleartextTrafficPermitted="false"'));
      expect(xmlContent, contains('<certificates src="system" />'));
      expect(xmlContent, contains('onrender.com'));
      expect(xmlContent, contains('supabase.co'));
      expect(xmlContent, contains('googleapis.com'));
      expect(xmlContent, contains('kanoon.dev'));
      expect(xmlContent, contains('google.com'));
    });

    test('AndroidManifest.xml links networkSecurityConfig and permissions', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final manifestContent = manifestFile.readAsStringSync();
      expect(
        manifestContent,
        contains('android:networkSecurityConfig="@xml/network_security_config"'),
      );
      expect(
        manifestContent,
        contains('<uses-permission android:name="android.permission.INTERNET" />'),
      );
      expect(
        manifestContent,
        contains('<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />'),
      );
      expect(manifestContent, contains('package="me.asiverticals.pratidnya"'));
    });
  });
}
