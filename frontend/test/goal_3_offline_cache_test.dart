import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/core/storage/courtroom_cache_service.dart';
import 'package:pratidnya/src/core/storage/courtroom_sync_manager.dart';
import 'package:pratidnya/src/features/02_case_input/domain/criminal_case.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/controllers/case_controller.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/case_list_screen.dart';

void main() {
  group('Goal 3: Courtroom Offline Cache & Storage Engine Tests', () {
    late Directory tempDir;
    late CourtroomCacheService cacheService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('courtroom_cache_test_');
      cacheService = CourtroomCacheService(customDirectory: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('CourtroomCacheService caches and retrieves criminal cases atomically', () async {
      final now = DateTime.now().toUtc();
      final mockCase = CriminalCase(
        id: 'case_test_001',
        advocateId: 'adv_lucknow_123',
        firNumber: '124/2026',
        policeStation: 'कोतवाली नगर',
        district: 'लखनऊ',
        state: 'Uttar Pradesh',
        accusedName: 'राजू वर्मा',
        accusedCustodyStatus: 'JUDICIAL_CUSTODY',
        statuteSystem: 'BNS_BNSS',
        underSections: ['303 BNS', '317(2) BNS'],
        courtDesignation: 'ACJM-I, Lucknow',
        stageOfCase: 'BAIL',
        nextHearingDate: DateTime(2026, 9, 15),
        lastCourtOrder: 'केस डायरी तलब',
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

      // Initially empty
      final initial = await cacheService.getCachedCases('adv_lucknow_123');
      expect(initial, isEmpty);

      // Save cases
      await cacheService.saveCases('adv_lucknow_123', [mockCase]);

      // Read back
      final cached = await cacheService.getCachedCases('adv_lucknow_123');
      expect(cached.length, 1);
      expect(cached.first.id, 'case_test_001');
      expect(cached.first.firNumber, '124/2026');
      expect(cached.first.accusedName, 'राजू वर्मा');
      expect(cached.first.underSections, contains('303 BNS'));
      expect(cached.first.accusedCustodyStatus, 'JUDICIAL_CUSTODY');

      // Verify sync timestamp is recorded
      final syncTime = await cacheService.getLastSyncTime('adv_lucknow_123');
      expect(syncTime, isNotNull);
    });

    test('CourtroomCacheService stores and retrieves 360 bail draft payloads', () async {
      final draftPayload = {
        'statutory_grounds': [
          'अभियुक्त के विरुद्ध धारा 303 बीएनएस का कोई प्रत्यक्ष साक्ष्य नहीं है।',
          'बरामदगी के समय कोई स्वतंत्र पंच साक्षी उपस्थित नहीं था।'
        ],
        'prosecution_weaknesses': [
          'प्रथम सूचना रिपोर्ट में 48 घंटे का अकारण विलंब।'
        ],
        'cited_precedents': [
          {
            'citation_id': 'cit_1',
            'case_name': 'Satender Kumar Antil v. CBI',
            'legal_ratio': 'Arrest should not be routine without section 41A/35 compliance.',
          }
        ]
      };

      await cacheService.saveDraft('case_test_001', draftPayload);

      final retrieved = await cacheService.getCachedDraft('case_test_001');
      expect(retrieved, isNotNull);
      expect(retrieved!['statutory_grounds'].length, 2);
      expect(retrieved['cited_precedents'].length, 1);
      expect(retrieved['cited_precedents'][0]['case_name'], contains('Satender Kumar Antil'));
    });

    test('CourtroomCacheService manages pending outbox mutations queue', () async {
      final action1 = {
        'id': 'offline_act_1',
        'type': 'CREATE_CASE',
        'advocate_id': 'adv_123',
        'payload': {'fir_number': '45/2026'},
      };
      final action2 = {
        'id': 'offline_act_2',
        'type': 'UPDATE_PROCEEDINGS',
        'advocate_id': 'adv_123',
        'payload': {'case_id': 'case_1', 'stage_of_case': 'CHARGESHEET'},
      };

      await cacheService.queueOfflineAction(action1);
      await cacheService.queueOfflineAction(action2);

      final queue = await cacheService.getPendingActions();
      expect(queue.length, 2);
      expect(queue[0]['id'], 'offline_act_1');
      expect(queue[1]['id'], 'offline_act_2');

      // Clear one action
      await cacheService.clearPendingAction('offline_act_1');
      final updatedQueue = await cacheService.getPendingActions();
      expect(updatedQueue.length, 1);
      expect(updatedQueue[0]['id'], 'offline_act_2');
    });

    testWidgets('Courtroom Offline Mode Banner renders when isOfflineModeProvider is true', (tester) async {
      final now = DateTime.now().toUtc();
      final mockCases = [
        CriminalCase(
          id: 'case_offline_test',
          advocateId: 'adv_test',
          firNumber: '99/2026',
          policeStation: 'हजरतगंज',
          district: 'लखनऊ',
          state: 'Uttar Pradesh',
          accusedName: 'सुनील कुमार',
          accusedCustodyStatus: 'JUDICIAL_CUSTODY',
          statuteSystem: 'BNS_BNSS',
          underSections: ['303 BNS'],
          courtDesignation: 'CJM, Lucknow',
          stageOfCase: 'BAIL',
          nextHearingDate: DateTime(2026, 9, 20),
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOfflineModeProvider.overrideWith((ref) => true),
            pendingQueueCountProvider.overrideWith((ref) => 2),
            caseListProvider.overrideWith((ref) => Future.value(mockCases)),
          ],
          child: const MaterialApp(
            home: CaseListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that case is visible
      expect(find.textContaining('99/2026'), findsWidgets);
      expect(find.textContaining('सुनील कुमार'), findsWidgets);

      // Check that offline courtroom mode banner is rendered
      expect(find.textContaining('ऑफलाइन कोर्टरूम मोड'), findsOneWidget);
      expect(find.textContaining('2 केस/कार्यवाही सिंक हेतु कतारबद्ध'), findsOneWidget);
      expect(find.text('सिंक करें'), findsOneWidget);
    });
  });
}
