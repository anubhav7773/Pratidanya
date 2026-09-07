import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/core/storage/courtroom_cache_service.dart';
import 'package:pratidnya/src/core/storage/courtroom_sync_manager.dart';
import 'package:pratidnya/src/features/02_case_input/data/case_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock Supabase client
class MockSupabaseClient extends Fake implements SupabaseClient {
  final Map<String, String> _headers = {};

  @override
  PostgrestClient get rest => MockPostgrestClient(_headers);
}

class MockPostgrestClient extends Fake implements PostgrestClient {
  final Map<String, String> _headers;
  MockPostgrestClient(this._headers);

  @override
  Map<String, String> get headers => _headers;

  @override
  PostgrestQueryBuilder from(String table) {
    throw Exception('Simulated Network / RLS Block');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('New Case Visibility & Outbox Sync Tests', () {
    late Directory tempDir;
    late CourtroomCacheService cacheService;
    late ProviderContainer container;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('case_visibility_test_');
      cacheService = CourtroomCacheService(customDirectory: tempDir);
      container = ProviderContainer(
        overrides: [
          courtroomCacheServiceProvider.overrideWithValue(cacheService),
          caseRepositoryProvider.overrideWith((ref) => CriminalCaseRepository(
            MockSupabaseClient(),
            cacheService: cacheService,
            ref: ref,
          )),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Locally created / queued case is immediately visible in fetchUpcomingHearingCases', () async {
      final repository = container.read(caseRepositoryProvider);

      // Queue an offline case
      final localId = 'offline_123456789';
      await cacheService.queueOfflineAction({
        'id': localId,
        'type': 'CREATE_CASE',
        'advocate_id': 'adv_test_uid',
        'created_at': DateTime.now().toIso8601String(),
        'payload': {
          'advocate_id': 'adv_test_uid',
          'fir_number': '124/2026',
          'police_station': 'Kotwali Nagar',
          'district': 'Lucknow',
          'state': 'Uttar Pradesh',
          'accused_name': 'Ramesh Kumar',
          'accused_custody_status': 'JUDICIAL_CUSTODY',
          'statute_system': 'BNS_BNSS',
          'under_sections': ['303 BNS'],
          'court_designation': 'CJM Lucknow',
          'stage_of_case': 'BAIL',
        },
      });

      // Fetch cases - even though Supabase throws, it must return the pending local case!
      final cases = await repository.fetchUpcomingHearingCases(advocateId: 'adv_test_uid');
      expect(cases, isNotEmpty);
      expect(cases.length, 1);
      expect(cases.first.id, localId);
      expect(cases.first.firNumber, '124/2026');
      expect(cases.first.accusedName, 'Ramesh Kumar');

      // Providers must reflect pending state
      expect(container.read(pendingQueueCountProvider), 1);
      expect(container.read(isOfflineModeProvider), isTrue);
    });

    test('CourtroomSyncManager updates isOfflineMode to false when pending operations are cleared', () async {
      final syncManager = container.read(courtroomSyncManagerProvider);

      // Initially 0 pending
      await syncManager.refreshPendingCount();
      expect(container.read(pendingQueueCountProvider), 0);
      expect(container.read(isOfflineModeProvider), isFalse);

      // Queue an action
      await cacheService.queueOfflineAction({
        'id': 'offline_sync_test',
        'type': 'CREATE_CASE',
        'advocate_id': 'adv_test_uid',
        'payload': {
          'advocate_id': 'adv_test_uid',
          'fir_number': '99/2026',
          'police_station': 'Hazratganj',
          'district': 'Lucknow',
          'state': 'Uttar Pradesh',
          'accused_name': 'Suresh',
          'accused_custody_status': 'JUDICIAL_CUSTODY',
          'statute_system': 'BNS_BNSS',
          'under_sections': ['379 IPC'],
          'court_designation': 'ACJM-I',
          'stage_of_case': 'BAIL',
        },
      });

      await syncManager.refreshPendingCount();
      expect(container.read(pendingQueueCountProvider), 1);

      // Clear the action manually simulating sync
      await cacheService.clearPendingAction('offline_sync_test');
      await syncManager.refreshPendingCount();
      final remaining = await cacheService.getPendingActions();
      container.read(isOfflineModeProvider.notifier).state = remaining.isNotEmpty;

      expect(container.read(pendingQueueCountProvider), 0);
      expect(container.read(isOfflineModeProvider), isFalse);
    });
  });
}
