import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/services/activity_service.dart';
import '../domain/ecourts_models.dart';

final ecourtsRepositoryProvider = Provider<EcourtsRepository>((ref) {
  return EcourtsRepository(
    client: http.Client(),
    supabase: Supabase.instance.client,
  );
});

class EcourtsRepository {
  final http.Client _client;
  final SupabaseClient _supabase;

  EcourtsRepository({
    required http.Client client,
    required SupabaseClient supabase,
  })  : _client = client,
        _supabase = supabase;

  String get _baseUrl => AppEnvironment.backendBaseUrl;

  /// Synchronize a case against e-Courts CIS 3.2 backend
  Future<EcourtsSyncResult> syncCaseWithCis({
    required String cnrNumber,
    String? firNumber,
    String? district,
    String? state,
  }) async {
    final cleanedCnr = CnrValidator.cleanCnr(cnrNumber);
    final url = Uri.parse('$_baseUrl/api/v1/ecourts/sync');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'cnr_number': cleanedCnr,
          'fir_number': firNumber,
          'district': district,
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final result = EcourtsSyncResult.fromJson(data);

        ActivityService.logActivity(
          activityType: 'ECOURTS_SYNC_SUCCESS',
          details: {
            'cnr_number': cleanedCnr,
            'next_hearing_date': result.nextHearingDate,
            'court_room': result.courtRoomNumber,
            'coram': result.courtCoram,
          },
        );

        return result;
      } else {
        String errorMsg = 'ई-कोर्ट्स सिंक विफल (${response.statusCode})';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['detail'] != null) errorMsg = errorData['detail'].toString();
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      ActivityService.logActivity(
        activityType: 'ECOURTS_SYNC_FAILED',
        details: {'cnr_number': cleanedCnr, 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Persist synced e-Courts details into Supabase cases & case_proceedings
  Future<void> persistSyncToSupabase({
    required String caseId,
    required String advocateId,
    required EcourtsSyncResult syncResult,
  }) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    try {
      // 1. Update cases docket
      await _supabase.from('cases').update({
        'cnr_number': syncResult.cnrNumber,
        'next_hearing_date': syncResult.nextHearingDate,
        'court_designation': syncResult.courtCoram.isNotEmpty ? syncResult.courtCoram : null,
        'last_court_order': syncResult.lastCourtOrder,
        'updated_at': nowUtc,
      }).eq('id', caseId);

      // 2. Record daily proceeding in case_proceedings
      await _supabase.from('case_proceedings').insert({
        'case_id': caseId,
        'advocate_id': advocateId,
        'proceeding_date': syncResult.lastHearingDate.isNotEmpty
            ? syncResult.lastHearingDate
            : DateTime.now().toIso8601String().split('T').first,
        'court_coram': syncResult.courtCoram,
        'business_recorded': syncResult.lastCourtOrder,
        'next_date': syncResult.nextHearingDate,
        'purpose_of_next_date': syncResult.hearingPurpose.isNotEmpty
            ? syncResult.hearingPurpose
            : syncResult.stageOfCase,
      });
    } on PostgrestException catch (_) {
      // Supabase case sync update warning caught safely
    }
  }


  /// Fetch Daily Cause List for a given district & date
  Future<DailyCauseList> fetchDailyCauseList({
    String district = 'Lucknow',
    String? courtDesignation,
    String? targetDate,
    String? advocateBarNumber,
  }) async {
    final queryParams = {
      'district': district,
      if (courtDesignation != null) 'court_designation': courtDesignation,
      if (targetDate != null) 'target_date': targetDate,
      if (advocateBarNumber != null) 'advocate_bar_number': advocateBarNumber,
    };

    final url = Uri.parse('$_baseUrl/api/v1/ecourts/cause-list').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        ActivityService.logActivity(
          activityType: 'CAUSE_LIST_ACCESSED',
          details: {'district': district, 'date': targetDate},
        );
        return DailyCauseList.fromJson(data);
      } else {
        throw Exception('कॉज लिस्ट लोड करने में असमर्थ (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }
}
