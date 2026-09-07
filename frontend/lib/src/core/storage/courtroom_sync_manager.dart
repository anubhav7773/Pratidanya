import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'courtroom_cache_service.dart';
import '../../features/02_case_input/data/case_repository.dart';

final courtroomCacheServiceProvider = Provider<CourtroomCacheService>((ref) {
  return CourtroomCacheService();
});

/// Tracks whether the app is currently operating in offline courtroom mode
final isOfflineModeProvider = StateProvider<bool>((ref) => false);

/// Tracks whether background/manual synchronization is currently active
final isSyncingProvider = StateProvider<bool>((ref) => false);

/// Number of pending mutations awaiting network restoration
final pendingQueueCountProvider = StateProvider<int>((ref) => 0);

class CourtroomSyncManager {
  final CourtroomCacheService _cacheService;
  final Ref _ref;

  CourtroomSyncManager(this._cacheService, this._ref);

  Future<void> refreshPendingCount() async {
    final list = await _cacheService.getPendingActions();
    _ref.read(pendingQueueCountProvider.notifier).state = list.length;
  }

  /// Replays pending outbox operations to Supabase when connectivity is active
  Future<int> syncPendingOperations(CriminalCaseRepository repository) async {
    final pending = await _cacheService.getPendingActions();
    if (pending.isEmpty) {
      _ref.read(pendingQueueCountProvider.notifier).state = 0;
      _ref.read(isOfflineModeProvider.notifier).state = false;
      return 0;
    }

    _ref.read(isSyncingProvider.notifier).state = true;
    int syncedCount = 0;

    for (final action in pending) {
      final actionId = action['id'] as String;
      final type = action['type'] as String;
      final payload = action['payload'] as Map<String, dynamic>;

      try {
        if (type == 'CREATE_CASE') {
          await repository.createCriminalCase(
            advocateId: payload['advocate_id'] as String,
            firNumber: payload['fir_number'] as String,
            policeStation: payload['police_station'] as String,
            district: payload['district'] as String,
            state: payload['state'] as String? ?? 'Uttar Pradesh',
            accusedName: payload['accused_name'] as String,
            accusedCustodyStatus: payload['accused_custody_status'] as String,
            statuteSystem: payload['statute_system'] as String,
            underSections: List<String>.from(payload['under_sections'] as List),
            courtDesignation: payload['court_designation'] as String,
            stageOfCase: payload['stage_of_case'] as String,
            complainantName: payload['complainant_name'] as String?,
            caseNumber: payload['case_number'] as String?,
            cnrNumber: payload['cnr_number'] as String?,
            nextHearingDate: payload['next_hearing_date'] != null
                ? DateTime.tryParse(payload['next_hearing_date'] as String)
                : null,
            lastCourtOrder: payload['last_court_order'] as String?,
            skipOfflineQueue: true, // Prevent re-queuing
          );
          await _cacheService.clearPendingAction(actionId);
          syncedCount++;
        } else if (type == 'UPDATE_PROCEEDINGS') {
          await repository.updateCaseProceedings(
            caseId: payload['case_id'] as String,
            advocateId: payload['advocate_id'] as String,
            stageOfCase: payload['stage_of_case'] as String,
            nextHearingDate: DateTime.parse(payload['next_hearing_date'] as String),
            businessRecorded: payload['business_recorded'] as String,
            courtCoram: payload['court_coram'] as String?,
            skipOfflineQueue: true,
          );
          await _cacheService.clearPendingAction(actionId);
          syncedCount++;
        }
      } catch (e) {
        debugPrint('[CourtroomSyncManager] Error syncing action $actionId ($type): $e');
        // Stop syncing further if network dropped again
        break;
      }
    }

    await refreshPendingCount();
    final remaining = await _cacheService.getPendingActions();
    _ref.read(isOfflineModeProvider.notifier).state = remaining.isNotEmpty;
    _ref.read(isSyncingProvider.notifier).state = false;
    return syncedCount;
  }
}

final courtroomSyncManagerProvider = Provider<CourtroomSyncManager>((ref) {
  final cache = ref.watch(courtroomCacheServiceProvider);
  return CourtroomSyncManager(cache, ref);
});
