import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/advocate_profile.dart';

final profileRepositoryProvider = Provider<AdvocateProfileRepository>((ref) {
  return AdvocateProfileRepository(Supabase.instance.client);
});

class AdvocateProfileRepository {
  final SupabaseClient _supabase;

  AdvocateProfileRepository(this._supabase);

  Future<AdvocateProfile?> getProfile(String firebaseUid) async {
    try {
      final data = await _supabase
          .from('advocate_profiles')
          .select()
          .eq('id', firebaseUid)
          .maybeSingle();

      if (data == null) return null;
      return AdvocateProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw Exception('प्रोफाइल डेटा लोड विफल: ${e.message} [Code: ${e.code}]');
    }
  }

  Future<void> recordStatutoryConsent(String firebaseUid) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    try {
      // 1. Update Advocate Profile Consent Flag
      await _supabase.from('advocate_profiles').update({
        'dpdp_consent_accepted': true,
        'dpdp_consent_timestamp': nowUtc,
      }).eq('id', firebaseUid);

      // 2. Insert Immutable DPDP Audit Log
      await _supabase.from('dpdp_audit_logs').insert({
        'advocate_id': firebaseUid,
        'action_type': 'CONSENT_GRANTED',
        'metadata': {
          'consent_version': 'DPDP_2023_V1.0',
          'statutory_basis': 'Sections 5 and 6',
          'recorded_at': nowUtc,
        },
      });
    } on PostgrestException catch (e) {
      throw Exception('सहमति रिकॉर्ड सहेजने में विफल: ${e.message}');
    }
  }

  Future<void> saveAdvocateBarProfile({
    required String firebaseUid,
    required String email,
    required String fullName,
    required String barCouncilNumber,
    required String primaryCourtName,
    required String enrolledState,
    String? chamberAddress,
  }) async {
    final nowUtc = DateTime.now().toUtc().toIso8601String();
    try {
      await _supabase.from('advocate_profiles').upsert({
        'id': firebaseUid,
        'email': email.trim().toLowerCase(),
        'full_name': fullName.trim(),
        'bar_council_number': barCouncilNumber.trim().toUpperCase(),
        'enrolled_state': enrolledState.trim(),
        'primary_court_name': primaryCourtName.trim(),
        'chamber_address': chamberAddress?.trim(),
        'updated_at': nowUtc,
      });

      // Initialize AI Quota for Free Tier
      await _supabase.from('advocate_ai_quotas').upsert({
        'advocate_id': firebaseUid,
        'subscription_tier': 'FREE',
        'daily_drafts_remaining': 3,
        'ad_rewarded_drafts': 0,
      });
    } on PostgrestException catch (e) {
      throw Exception('बार पंजीकरण विवरण सहेजने में विफल: ${e.message}');
    }
  }
}
