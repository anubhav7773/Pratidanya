import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/regional_acts_models.dart';

final regionalActsRepositoryProvider = Provider<RegionalActsRepository>((ref) {
  return RegionalActsRepository();
});

class RegionalActsRepository {
  Future<RegionalActsAuditResult> auditUpSpecialActs({
    required String caseId,
    required String statuteApplied,
    required String district,
    required String policeStation,
    required String accusedName,
    String? gangChartNumber,
    bool jointMeetingRule5Documented = false,
    bool dmIndependentMindApplied = false,
    String? dmEndorsementRawText,
    List<BasePredicateCase> baseCases = const [],
    bool noticeHasMaterialAllegations = false,
    bool noticeOnlyListsFirs = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/regional/audit-up-special-acts');

    final payload = jsonEncode({
      'case_id': caseId,
      'statute_applied': statuteApplied,
      'district': district,
      'police_station': policeStation,
      'accused_name': accusedName,
      'gang_chart_number': gangChartNumber,
      'joint_meeting_rule_5_documented': jointMeetingRule5Documented,
      'dm_independent_mind_applied': dmIndependentMindApplied,
      'dm_endorsement_raw_text': dmEndorsementRawText,
      'base_cases': baseCases.map((c) => c.toJson()).toList(),
      'notice_has_material_allegations': noticeHasMaterialAllegations,
      'notice_only_lists_firs': noticeOnlyListsFirs,
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
      return RegionalActsAuditResult.fromJson(data);
    } else {
      throw Exception('विशेष अधिनियम मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
