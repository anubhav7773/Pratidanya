import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pratidnya/src/core/network/chamber_http_client.dart';
import 'package:pratidnya/src/core/telemetry/activity_logger.dart';
import 'package:pratidnya/src/features/02_case_input/data/remand_repository.dart';
import 'package:pratidnya/src/features/02_case_input/data/evidence_repository.dart';
import 'package:pratidnya/src/features/02_case_input/data/forensics_repository.dart';
import 'package:pratidnya/src/features/02_case_input/data/trial_repository.dart';
import 'package:pratidnya/src/features/02_case_input/data/regional_acts_repository.dart';
import 'package:pratidnya/src/features/02_case_input/data/courtroom_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChamberHttpClient & Token Recovery Tests', () {
    test('getSafeAuthToken returns default fallback token when Firebase uninitialized', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(chamberHttpClientProvider);
      final token = await client.getSafeAuthToken();

      expect(token, equals('chamber_advocate_up_1234_anubhav'));

      // Check SharedPreferences was updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chamber_advocate_token'), equals('chamber_advocate_up_1234_anubhav'));
    });

    test('getSafeAuthToken respects existing stored token in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'chamber_advocate_token': 'chamber_advocate_custom_advocate_99',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(chamberHttpClientProvider);
      final token = await client.getSafeAuthToken();

      expect(token, equals('chamber_advocate_custom_advocate_99'));
    });
  });

  group('ActivityLogger Telemetry Tests', () {
    test('ActivityLogger initializes and does not throw on offline dispatch failure', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final logger = container.read(activityLoggerProvider);
      expect(logger, isNotNull);

      // Should complete without throwing exception
      await expectLater(
        logger.logEvent(
          eventType: 'APP_LAUNCH',
          moduleName: 'DASHBOARD_INITIALIZE',
          details: {'test': true},
        ),
        completes,
      );
    });
  });

  group('Repositories ChamberHttpClient Wire-up Tests', () {
    test('All 6 domain repositories resolve with ChamberHttpClient via Riverpod', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final remandRepo = container.read(remandRepositoryProvider);
      final evidenceRepo = container.read(evidenceRepositoryProvider);
      final forensicsRepo = container.read(forensicsRepositoryProvider);
      final trialRepo = container.read(trialRepositoryProvider);
      final regionalRepo = container.read(regionalActsRepositoryProvider);
      final courtroomRepo = container.read(courtroomRepositoryProvider);

      expect(remandRepo, isNotNull);
      expect(evidenceRepo, isNotNull);
      expect(forensicsRepo, isNotNull);
      expect(trialRepo, isNotNull);
      expect(regionalRepo, isNotNull);
      expect(courtroomRepo, isNotNull);
    });
  });
}
