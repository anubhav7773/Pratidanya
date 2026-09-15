import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/chamber_http_client.dart';
import '../domain/witness_impeachment_models.dart';
import '../domain/leading_question_models.dart';

final trialRepositoryProvider = Provider<TrialRepository>((ref) {
  return TrialRepository(ref.read(chamberHttpClientProvider));
});

class TrialRepository {
  final ChamberHttpClient _client;

  TrialRepository(this._client);

  Future<WitnessImpeachmentAuditResult> generateContradictionGrid({
    required String caseId,
    required String witnessCode,
    required String witnessName,
    String witnessRole = 'EYEWITNESS',
    String? firNarrative,
    required String sec161CrpcStatement,
    String? sec164CrpcStatement,
    required String courtDepositionChief,
    String? defenseTheory,
    required String accusedName,
    required String policeStation,
    required String district,
  }) async {
    final response = await _client.post(
      path: '/api/v1/trial/generate-contradiction-grid',
      actionName: 'AUDIT_WITNESS_IMPEACHMENT_GRID',
      caseId: caseId,
      body: {
        'case_id': caseId,
        'witness_code': witnessCode,
        'witness_name': witnessName,
        'witness_role': witnessRole,
        'fir_narrative': firNarrative,
        'sec_161_crpc_statement': sec161CrpcStatement,
        'sec_164_crpc_statement': sec164CrpcStatement,
        'court_deposition_chief': courtDepositionChief,
        'defense_theory': defenseTheory,
        'accused_name': accusedName,
        'police_station': policeStation,
        'district': district,
        'court_name': 'न्यायालय अपर सत्र न्यायाधीश',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return WitnessImpeachmentAuditResult.fromJson(data);
    } else {
      throw Exception('साक्षी अंतर्विरोध मूल्यांकन विफलता (${response.statusCode}): ${response.body}');
    }
  }

  Future<LeadingQuestionResult> generateCrossQuestions({
    required String caseId,
    required String witnessName,
    String witnessRole = 'PANCH_WITNESS_SEIZURE',
    required String defenseTheory,
    Map<String, dynamic> caseFacts = const {},
    required String accusedName,
    required String policeStation,
    required String district,
  }) async {
    final response = await _client.post(
      path: '/api/v1/trial/generate-cross-questions',
      actionName: 'GENERATE_LEADING_QUESTION_DECK',
      caseId: caseId,
      body: {
        'case_id': caseId,
        'witness_name': witnessName,
        'witness_role': witnessRole,
        'defense_theory': defenseTheory,
        'case_facts': caseFacts,
        'accused_name': accusedName,
        'police_station': policeStation,
        'district': district,
        'court_name': 'न्यायालय अपर सत्र न्यायाधीश',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return LeadingQuestionResult.fromJson(data);
    } else {
      throw Exception('सूचक जिरह प्रश्न निर्माण विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
