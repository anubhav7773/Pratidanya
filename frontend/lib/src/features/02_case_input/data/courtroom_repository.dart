import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/courtroom_tactics_models.dart';

final courtroomRepositoryProvider = Provider<CourtroomRepository>((ref) {
  return CourtroomRepository();
});

class CourtroomRepository {
  Future<EdgeOralPromptResult> requestEdgeOralPrompt({
    required String caseId,
    required String adversaryArgumentRawText,
    String activeJudgeId = 'JUDGE-UP-LKO-04',
    String activeOffenseCategory = 'NDPS',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/courtroom/edge-oral-prompt');

    final payload = jsonEncode({
      'case_id': caseId,
      'adversary_argument_raw_text': adversaryArgumentRawText,
      'active_judge_id': activeJudgeId,
      'active_offense_category': activeOffenseCategory,
      'language': 'HINDI_KACHEHRI_SLANG',
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: payload,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return EdgeOralPromptResult.fromJson(data);
    } else {
      throw Exception('मौखिक प्रत्युत्तर निर्माण विफलता (${response.statusCode}): ${response.body}');
    }
  }

  Future<SuretyAuditResult> auditSuretyConditions({
    required String caseId,
    required double imposedBondAmountInr,
    required bool isLocalSuretyDemanded,
    required bool isRevenueRecordKhatauniDemanded,
    required bool outOfDistrictSuretyRejected,
    required bool accusedFinancialIndigence,
    required String accusedName,
    required String policeStation,
    required String district,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/courtroom/audit-surety-conditions');

    final payload = jsonEncode({
      'case_id': caseId,
      'imposed_bond_amount_inr': imposedBondAmountInr,
      'is_local_surety_demanded': isLocalSuretyDemanded,
      'is_revenue_record_khatauni_demanded': isRevenueRecordKhatauniDemanded,
      'out_of_district_surety_rejected': outOfDistrictSuretyRejected,
      'accused_financial_indigence': accusedFinancialIndigence,
      'accused_name': accusedName,
      'police_station': policeStation,
      'district': district,
      'court_name': 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट',
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: payload,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return SuretyAuditResult.fromJson(data);
    } else {
      throw Exception('प्रतिभू शर्त मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
