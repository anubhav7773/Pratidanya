import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/criminal_case.dart';

final caseRepositoryProvider = Provider<CriminalCaseRepository>((ref) {
  return CriminalCaseRepository(Supabase.instance.client);
});

class CriminalCaseRepository {
  final SupabaseClient _supabase;

  CriminalCaseRepository(this._supabase);

  Future<List<CriminalCase>> fetchUpcomingHearingCases({
    required String advocateId,
    String? searchQuery,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('cases')
          .select()
          .eq('advocate_id', advocateId)
          .eq('is_archived', false);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.or('fir_number.ilike.%${searchQuery.trim()}%,accused_name.ilike.%${searchQuery.trim()}%');
      }

      final response = await query
          .order('next_hearing_date', ascending: true, nullsFirst: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map((json) => CriminalCase.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('केस डायरी लोड करने में विफल: ${e.message} [Code: ${e.code}]');
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
    DateTime? nextHearingDate,
    String? lastCourtOrder,
  }) async {
    try {
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
        'stage_of_case': stageOfCase,
        'next_hearing_date': nextHearingDate?.toIso8601String().split('T').first,
        'last_court_order': lastCourtOrder?.trim(),
        'is_archived': false,
      };

      final response = await _supabase.from('cases').insert(payload).select().single();
      return CriminalCase.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('नया केस दर्ज करने में विफल: ${e.message}');
    }
  }

  Future<void> updateCaseProceedings({
    required String caseId,
    required String advocateId,
    required String stageOfCase,
    required DateTime nextHearingDate,
    required String businessRecorded,
    String? courtCoram,
  }) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    try {
      await _supabase.from('case_proceedings').insert({
        'case_id': caseId,
        'advocate_id': advocateId,
        'proceeding_date': DateTime.now().toIso8601String().split('T').first,
        'court_coram': courtCoram?.trim(),
        'business_recorded': businessRecorded.trim(),
        'next_date': nextHearingDate.toIso8601String().split('T').first,
        'purpose_of_next_date': stageOfCase,
      });

      await _supabase.from('cases').update({
        'stage_of_case': stageOfCase,
        'next_hearing_date': nextHearingDate.toIso8601String().split('T').first,
        'last_court_order': businessRecorded.trim(),
        'updated_at': nowUtc,
      }).eq('id', caseId);
    } on PostgrestException catch (e) {
      throw Exception('कार्यवाही अपडेट करने में विफल: ${e.message}');
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
      await _supabase.from('cases').delete().eq('id', caseId);
    } on PostgrestException catch (e) {
      throw Exception('केस विलोपन (Right to Erasure) विफल: ${e.message}');
    }
  }
}
