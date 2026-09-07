import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/criminal_case.dart';
import '../../../core/storage/courtroom_cache_service.dart';
import '../../../core/storage/courtroom_sync_manager.dart';

final caseRepositoryProvider = Provider<CriminalCaseRepository>((ref) {
  final cacheService = ref.watch(courtroomCacheServiceProvider);
  return CriminalCaseRepository(
    Supabase.instance.client,
    cacheService: cacheService,
    ref: ref,
  );
});

typedef CaseRepository = CriminalCaseRepository;

class CriminalCaseRepository {
  final SupabaseClient _supabase;
  final CourtroomCacheService? _cacheService;
  final Ref? _ref;

  CriminalCaseRepository(
    this._supabase, {
    CourtroomCacheService? cacheService,
    Ref? ref,
  })  : _cacheService = cacheService,
        _ref = ref;

  /// Fixes CAS-01: Strips control characters that break PostgREST .or() URL filter syntax.
  /// Characters like commas (,), parentheses (), colons (:), and raw percent (%) signs
  /// disrupt URI parsing and trigger 400 Bad Request.
  static String sanitizeSearchQuery(String rawInput) {
    if (rawInput.isEmpty) return '';
    // Strip characters that disrupt PostgREST query grammar
    return rawInput
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'[:"\\%\[\]()]'), '')
        .trim();
  }

  Future<List<CriminalCase>> fetchUpcomingHearingCases({
    required String advocateId,
    String? searchQuery,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      if (advocateId.isNotEmpty) {
        _supabase.rest.headers['x-advocate-id'] = advocateId;
      }

      var query = _supabase
          .from('cases')
          .select()
          .eq('advocate_id', advocateId)
          .eq('is_archived', false);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final sanitized = sanitizeSearchQuery(searchQuery);
        if (sanitized.isNotEmpty) {
          query = query.or('fir_number.ilike.%$sanitized%,accused_name.ilike.%$sanitized%');
        }
      }

      final response = await query
          .order('next_hearing_date', ascending: true, nullsFirst: false)
          .range(offset, offset + limit - 1);

      final remoteCases = (response as List<dynamic>)
          .map((json) => CriminalCase.fromJson(json as Map<String, dynamic>))
          .toList();

      // Retrieve any pending offline CREATE_CASE operations to guarantee newly added cases are visible
      final pendingActions = await _cacheService?.getPendingActions() ?? [];
      final pendingLocalCases = <CriminalCase>[];
      for (final action in pendingActions) {
        if (action['type'] == 'CREATE_CASE' && action['advocate_id'] == advocateId) {
          final payload = action['payload'] as Map<String, dynamic>;
          final localId = action['id'] as String;
          final alreadyInRemote = remoteCases.any((c) =>
              c.firNumber.toLowerCase() == (payload['fir_number'] as String).toLowerCase() &&
              c.policeStation.toLowerCase() == (payload['police_station'] as String).toLowerCase());
          if (!alreadyInRemote) {
            pendingLocalCases.add(CriminalCase(
              id: localId,
              advocateId: advocateId,
              firNumber: (payload['fir_number'] as String).trim(),
              policeStation: (payload['police_station'] as String).trim(),
              district: (payload['district'] as String).trim(),
              state: (payload['state'] as String? ?? 'Uttar Pradesh').trim(),
              accusedName: (payload['accused_name'] as String).trim(),
              accusedCustodyStatus: payload['accused_custody_status'] as String,
              complainantName: (payload['complainant_name'] as String?)?.trim(),
              statuteSystem: payload['statute_system'] as String,
              underSections: List<String>.from(payload['under_sections'] as List),
              courtDesignation: (payload['court_designation'] as String).trim(),
              caseNumber: (payload['case_number'] as String?)?.trim(),
              cnrNumber: (payload['cnr_number'] as String?)?.trim(),
              stageOfCase: payload['stage_of_case'] as String,
              nextHearingDate: payload['next_hearing_date'] != null
                  ? DateTime.tryParse(payload['next_hearing_date'] as String)
                  : null,
              lastCourtOrder: (payload['last_court_order'] as String?)?.trim(),
              isArchived: false,
              createdAt: DateTime.tryParse(action['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }
        }
      }

      final combinedCases = [...pendingLocalCases, ...remoteCases];

      if (_ref != null) {
        _ref.read(pendingQueueCountProvider.notifier).state = pendingActions.length;
        _ref.read(isOfflineModeProvider.notifier).state = pendingActions.isNotEmpty;
      }

      // Only cache full queries (not search filtered queries) to preserve complete offline docket
      if (searchQuery == null || searchQuery.trim().isEmpty) {
        await _cacheService?.saveCases(advocateId, combinedCases);
      }
      return combinedCases;
    } catch (e) {
      // Offline fallback: try reading from local courtroom cache
      debugPrint('[CriminalCaseRepository] Supabase fetch failed ($e). Attempting local courtroom cache fallback...');
      final cached = await _cacheService?.getCachedCases(advocateId) ?? [];
      final pendingActions = await _cacheService?.getPendingActions() ?? [];

      final pendingLocalCases = <CriminalCase>[];
      for (final action in pendingActions) {
        if (action['type'] == 'CREATE_CASE' && action['advocate_id'] == advocateId) {
          final payload = action['payload'] as Map<String, dynamic>;
          final localId = action['id'] as String;
          final alreadyInCached = cached.any((c) =>
              c.id == localId ||
              (c.firNumber.toLowerCase() == (payload['fir_number'] as String).toLowerCase() &&
               c.policeStation.toLowerCase() == (payload['police_station'] as String).toLowerCase()));
          if (!alreadyInCached) {
            pendingLocalCases.add(CriminalCase(
              id: localId,
              advocateId: advocateId,
              firNumber: (payload['fir_number'] as String).trim(),
              policeStation: (payload['police_station'] as String).trim(),
              district: (payload['district'] as String).trim(),
              state: (payload['state'] as String? ?? 'Uttar Pradesh').trim(),
              accusedName: (payload['accused_name'] as String).trim(),
              accusedCustodyStatus: payload['accused_custody_status'] as String,
              complainantName: (payload['complainant_name'] as String?)?.trim(),
              statuteSystem: payload['statute_system'] as String,
              underSections: List<String>.from(payload['under_sections'] as List),
              courtDesignation: (payload['court_designation'] as String).trim(),
              caseNumber: (payload['case_number'] as String?)?.trim(),
              cnrNumber: (payload['cnr_number'] as String?)?.trim(),
              stageOfCase: payload['stage_of_case'] as String,
              nextHearingDate: payload['next_hearing_date'] != null
                  ? DateTime.tryParse(payload['next_hearing_date'] as String)
                  : null,
              lastCourtOrder: (payload['last_court_order'] as String?)?.trim(),
              isArchived: false,
              createdAt: DateTime.tryParse(action['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }
        }
      }

      final allCached = [...pendingLocalCases, ...cached];
      if (allCached.isNotEmpty) {
        _ref?.read(isOfflineModeProvider.notifier).state = true;
        _ref?.read(pendingQueueCountProvider.notifier).state = pendingActions.length;
        var filtered = allCached.where((c) => !c.isArchived).toList();
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          filtered = filtered.where((c) =>
            c.firNumber.toLowerCase().contains(q) ||
            c.accusedName.toLowerCase().contains(q) ||
            c.policeStation.toLowerCase().contains(q)
          ).toList();
        }
        filtered.sort((a, b) {
          if (a.nextHearingDate == null && b.nextHearingDate == null) return 0;
          if (a.nextHearingDate == null) return 1;
          if (b.nextHearingDate == null) return -1;
          return a.nextHearingDate!.compareTo(b.nextHearingDate!);
        });
        return filtered;
      }
      // If no local cache exists, throw original error
      throw Exception('केस डायरी लोड करने में विफल: इंटरनेट कनेक्शन उपलब्ध नहीं है और कोई ऑफ़लाइन डेटा मौजूद नहीं है।');
    }
  }

  Future<CriminalCase> createCriminalCase({
    required String advocateId,
    required String firNumber,
    required String policeStation,
    required String district,
    required String state,
    required String accusedName,
    required String accusedCustodyStatus,
    required String statuteSystem,
    required List<String> underSections,
    required String courtDesignation,
    required String stageOfCase,
    String? complainantName,
    String? caseNumber,
    String? cnrNumber,
    DateTime? nextHearingDate,
    DateTime? arrestDate,
    String? lastCourtOrder,
    bool skipOfflineQueue = false,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = {
      'advocate_id': advocateId,
      'fir_number': firNumber.trim(),
      'police_station': policeStation.trim(),
      'district': district.trim(),
      'state': state.trim(),
      'accused_name': accusedName.trim(),
      'accused_custody_status': accusedCustodyStatus,
      'complainant_name': complainantName?.trim(),
      'statute_system': statuteSystem,
      'under_sections': underSections,
      'court_designation': courtDesignation.trim(),
      'case_number': caseNumber?.trim(),
      'cnr_number': (cnrNumber != null && cnrNumber.trim().isNotEmpty) ? cnrNumber.trim() : null,
      'stage_of_case': stageOfCase,
      'next_hearing_date': nextHearingDate?.toIso8601String().split('T').first,
      'arrest_date': arrestDate?.toIso8601String().split('T').first,
      'last_court_order': lastCourtOrder?.trim(),
      'is_archived': false,
    };

    try {
      if (advocateId.isNotEmpty) {
        _supabase.rest.headers['x-advocate-id'] = advocateId;
      }
      final response = await _supabase.from('cases').insert(payload).select().single();
      final createdCase = CriminalCase.fromJson(response);

      // Update local cache with newly created case
      final cached = await _cacheService?.getCachedCases(advocateId) ?? [];
      cached.insert(0, createdCase);
      await _cacheService?.saveCases(advocateId, cached);

      return createdCase;
    } catch (e) {
      if (skipOfflineQueue) rethrow;

      // Offline mode: generate local case, save to cache, and queue for sync
      debugPrint('[CriminalCaseRepository] Supabase insert failed ($e). Queuing offline case creation...');
      final localId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final localCase = CriminalCase(
        id: localId,
        advocateId: advocateId,
        firNumber: firNumber.trim(),
        policeStation: policeStation.trim(),
        district: district.trim(),
        state: state.trim(),
        accusedName: accusedName.trim(),
        accusedCustodyStatus: accusedCustodyStatus,
        complainantName: complainantName?.trim(),
        statuteSystem: statuteSystem,
        underSections: underSections,
        courtDesignation: courtDesignation.trim(),
        caseNumber: caseNumber?.trim(),
        cnrNumber: cnrNumber?.trim(),
        stageOfCase: stageOfCase,
        nextHearingDate: nextHearingDate,
        arrestDate: arrestDate,
        lastCourtOrder: lastCourtOrder?.trim(),
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

      // Save to local cache
      final cached = await _cacheService?.getCachedCases(advocateId) ?? [];
      cached.insert(0, localCase);
      await _cacheService?.saveCases(advocateId, cached);

      // Queue in outbox
      await _cacheService?.queueOfflineAction({
        'id': localId,
        'type': 'CREATE_CASE',
        'advocate_id': advocateId,
        'created_at': now.toIso8601String(),
        'payload': payload,
      });

      _ref?.read(isOfflineModeProvider.notifier).state = true;
      final currentQueueCount = _ref?.read(pendingQueueCountProvider) ?? 0;
      _ref?.read(pendingQueueCountProvider.notifier).state = currentQueueCount + 1;

      return localCase;
    }
  }

  Future<void> updateCaseProceedings({
    required String caseId,
    required String advocateId,
    required String stageOfCase,
    required DateTime nextHearingDate,
    required String businessRecorded,
    String? courtCoram,
    bool skipOfflineQueue = false,
  }) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final dateStr = nextHearingDate.toIso8601String().split('T').first;

    try {
      if (advocateId.isNotEmpty) {
        _supabase.rest.headers['x-advocate-id'] = advocateId;
      }
      await _supabase.from('case_proceedings').insert({
        'case_id': caseId,
        'advocate_id': advocateId,
        'proceeding_date': DateTime.now().toIso8601String().split('T').first,
        'court_coram': courtCoram?.trim(),
        'business_recorded': businessRecorded.trim(),
        'next_date': dateStr,
        'purpose_of_next_date': stageOfCase,
      });

      await _supabase.from('cases').update({
        'stage_of_case': stageOfCase,
        'next_hearing_date': dateStr,
        'last_court_order': businessRecorded.trim(),
        'updated_at': nowUtc,
      }).eq('id', caseId);

      // Update local cache
      final cached = await _cacheService?.getCachedCases(advocateId) ?? [];
      final index = cached.indexWhere((c) => c.id == caseId);
      if (index != -1) {
        final existing = cached[index];
        cached[index] = CriminalCase(
          id: existing.id,
          advocateId: existing.advocateId,
          firNumber: existing.firNumber,
          policeStation: existing.policeStation,
          district: existing.district,
          state: existing.state,
          accusedName: existing.accusedName,
          accusedCustodyStatus: existing.accusedCustodyStatus,
          complainantName: existing.complainantName,
          statuteSystem: existing.statuteSystem,
          underSections: existing.underSections,
          courtDesignation: existing.courtDesignation,
          caseNumber: existing.caseNumber,
          cnrNumber: existing.cnrNumber,
          stageOfCase: stageOfCase,
          nextHearingDate: nextHearingDate,
          lastCourtOrder: businessRecorded.trim(),
          isArchived: existing.isArchived,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
        await _cacheService?.saveCases(advocateId, cached);
      }
    } catch (e) {
      if (skipOfflineQueue) rethrow;

      // Offline mode: update local cache and queue in outbox
      debugPrint('[CriminalCaseRepository] Supabase update proceedings failed ($e). Queuing offline...');
      final cached = await _cacheService?.getCachedCases(advocateId) ?? [];
      final index = cached.indexWhere((c) => c.id == caseId);
      if (index != -1) {
        final existing = cached[index];
        cached[index] = CriminalCase(
          id: existing.id,
          advocateId: existing.advocateId,
          firNumber: existing.firNumber,
          policeStation: existing.policeStation,
          district: existing.district,
          state: existing.state,
          accusedName: existing.accusedName,
          accusedCustodyStatus: existing.accusedCustodyStatus,
          complainantName: existing.complainantName,
          statuteSystem: existing.statuteSystem,
          underSections: existing.underSections,
          courtDesignation: existing.courtDesignation,
          caseNumber: existing.caseNumber,
          cnrNumber: existing.cnrNumber,
          stageOfCase: stageOfCase,
          nextHearingDate: nextHearingDate,
          lastCourtOrder: businessRecorded.trim(),
          isArchived: existing.isArchived,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now().toUtc(),
        );
        await _cacheService?.saveCases(advocateId, cached);
      }

      await _cacheService?.queueOfflineAction({
        'id': 'proc_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'UPDATE_PROCEEDINGS',
        'advocate_id': advocateId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'payload': {
          'case_id': caseId,
          'advocate_id': advocateId,
          'stage_of_case': stageOfCase,
          'next_hearing_date': dateStr,
          'business_recorded': businessRecorded.trim(),
          'court_coram': courtCoram?.trim(),
        },
      });

      _ref?.read(isOfflineModeProvider.notifier).state = true;
      final currentQueueCount = _ref?.read(pendingQueueCountProvider) ?? 0;
      _ref?.read(pendingQueueCountProvider.notifier).state = currentQueueCount + 1;
    }
  }

  Future<void> archiveCase(String caseId) async {
    try {
      await _supabase.from('cases').update({
        'is_archived': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', caseId);
    } on PostgrestException catch (e) {
      throw Exception('केस पुरालेख (Archive) विफल: ${e.message}');
    }
  }

  Future<void> hardDeleteCase({
    required String caseId,
    required String advocateId,
  }) async {
    try {
      if (advocateId.isNotEmpty) {
        _supabase.rest.headers['x-advocate-id'] = advocateId;
      }
      await _supabase.from('cases').delete().eq('id', caseId);
      final cached = await _cacheService?.getCachedCases(advocateId) ?? [];
      cached.removeWhere((c) => c.id == caseId);
      await _cacheService?.saveCases(advocateId, cached);
    } on PostgrestException catch (e) {
      throw Exception('केस विलोपन (Right to Erasure) विफल: ${e.message}');
    }
  }
}
