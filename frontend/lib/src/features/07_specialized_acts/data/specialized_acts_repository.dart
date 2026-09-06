import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/specialized_act_models.dart';
import '../domain/scst_ni_models.dart';

final specializedActsRepositoryProvider = Provider<SpecializedActsRepository>((ref) {
  return SpecializedActsRepository();
});

class SpecializedActsRepository {
  final http.Client _client;

  SpecializedActsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<NdpsComplianceResult> evaluateNdps({
    required String caseId,
    required String substanceName,
    required double quantityGrams,
    required bool isPersonalSearch,
    required bool section50NoticeGiven,
    required String noticeType,
    required bool wasSearchedBeforeGazettedOfficer,
    required bool wasSearchedBeforeMagistrate,
    required bool thirdOptionDefect,
    required bool independentWitnesses,
    required bool sampleDrawnUnder52A,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/specialized-acts/ndps/evaluate');

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'case_id': caseId,
        'substance_name': substanceName,
        'recovered_quantity_grams': quantityGrams,
        'is_personal_search': isPersonalSearch,
        'section_50_notice_given': section50NoticeGiven,
        'section_50_notice_type': noticeType,
        'was_searched_before_gazetted_officer': wasSearchedBeforeGazettedOfficer,
        'was_searched_before_magistrate': wasSearchedBeforeMagistrate,
        'third_option_defect_present': thirdOptionDefect,
        'information_recorded_in_writing': true,
        'information_sent_to_superior_within_72h': true,
        'independent_public_witnesses_present': independentWitnesses,
        'sample_drawn_before_magistrate_sec_52a': sampleDrawnUnder52A,
        'malkhana_entry_delay_days': 0,
        'fsl_dispatch_delay_days': 0,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return NdpsComplianceResult.fromJson(data);
    } else {
      throw Exception('एन.डी.पी.एस. मूल्यांकन विफल: ${response.body}');
    }
  }

  Future<PocsoAgeEvaluationResult> evaluatePocsoAge({
    required String caseId,
    required DateTime incidentDate,
    required int firAge,
    required bool hasMatriculation,
    DateTime? matriculationDob,
    required bool hasSchoolCert,
    DateTime? schoolDob,
    required bool hasMunicipalCert,
    DateTime? municipalDob,
    required bool ossificationConducted,
    double? lowerAge,
    double? upperAge,
    required bool priorRelationship,
    required int delayDays,
    required bool noInjuries,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/specialized-acts/pocso/evaluate-age');

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'case_id': caseId,
        'alleged_incident_date': incidentDate.toIso8601String().split('T').first,
        'fir_stated_age_years': firAge,
        'has_first_attended_school_certificate': hasSchoolCert,
        'school_dob': schoolDob?.toIso8601String().split('T').first,
        'has_matriculation_certificate': hasMatriculation,
        'matriculation_dob': matriculationDob?.toIso8601String().split('T').first,
        'has_municipal_birth_certificate': hasMunicipalCert,
        'municipal_dob': municipalDob?.toIso8601String().split('T').first,
        'ossification_test_conducted': ossificationConducted,
        'radiological_age_lower': lowerAge,
        'radiological_age_upper': upperAge,
        'two_year_margin_benefit_applied': true,
        'evidence_of_prior_romantic_relationship': priorRelationship,
        'unexplained_delay_in_fir_days': delayDays,
        'no_injuries_found': noInjuries,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return PocsoAgeEvaluationResult.fromJson(data);
    } else {
      throw Exception('पॉक्सो आयु निर्धारण विफल: ${response.body}');
    }
  }

  Future<ScstComplianceResult> evaluateScst({
    required String caseId,
    required String incidentPlaceType,
    required bool independentWitnesses,
    required bool casteNameAlleged,
    required bool priorCivilDispute,
    DateTime? specialCourtOrderDate,
    required bool victimNoticeServed,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/specialized-acts/scst/evaluate');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
      body: jsonEncode({
        'case_id': caseId,
        'atrocity_sections': ['3(1)(r)', '3(1)(s)'],
        'incident_place_type': incidentPlaceType,
        'independent_public_witnesses_present': independentWitnesses,
        'allegation_of_caste_name_used': casteNameAlleged,
        'prior_land_or_civil_dispute_existing': priorCivilDispute,
        'special_court_order_date': specialCourtOrderDate?.toIso8601String().split('T').first,
        'proposed_appeal_filing_date': DateTime.now().toIso8601String().split('T').first,
        'victim_notice_served': victimNoticeServed,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ScstComplianceResult.fromJson(data);
    } else {
      throw Exception('एस.सी./एस.टी. मूल्यांकन विफलता: ${response.body}');
    }
  }

  Future<NiActComplianceResult> evaluateNiAct({
    required String caseId,
    required String chequeNumber,
    required double chequeAmount,
    required DateTime chequeDate,
    required DateTime returnMemoDate,
    required DateTime noticeDispatchDate,
    required DateTime noticeDeliveryDate,
    required bool isOmnibusDefective,
    required DateTime complaintFilingDate,
    required String defenseCategory,
    required bool seeksCompounding,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/specialized-acts/ni-act/evaluate');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
      body: jsonEncode({
        'case_id': caseId,
        'cheque_number': chequeNumber,
        'cheque_amount': chequeAmount,
        'cheque_date': chequeDate.toIso8601String().split('T').first,
        'bank_return_memo_date': returnMemoDate.toIso8601String().split('T').first,
        'dishonour_reason': 'FUNDS_INSUFFICIENT',
        'demand_notice_dispatch_date': noticeDispatchDate.toIso8601String().split('T').first,
        'demand_notice_delivery_date': noticeDeliveryDate.toIso8601String().split('T').first,
        'is_omnibus_demand_defective': isOmnibusDefective,
        'complaint_filing_date': complaintFilingDate.toIso8601String().split('T').first,
        'defense_category': defenseCategory,
        'seeks_compounding': seeksCompounding,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return NiActComplianceResult.fromJson(data);
    } else {
      throw Exception('एन.आई. एक्ट 138 मूल्यांकन विफलता: ${response.body}');
    }
  }
}
