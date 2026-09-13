import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/witness_impeachment_models.dart';
import '../domain/leading_question_models.dart';

final trialRepositoryProvider = Provider<TrialRepository>((ref) {

  return TrialRepository();
});

class TrialRepository {
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/trial/generate-contradiction-grid');

    final payload = jsonEncode({
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/trial/generate-cross-questions');

    final payload = jsonEncode({
      'case_id': caseId,
      'witness_name': witnessName,
      'witness_role': witnessRole,
      'defense_theory': defenseTheory,
      'case_facts': caseFacts,
      'accused_name': accusedName,
      'police_station': policeStation,
      'district': district,
      'court_name': 'न्यायालय अपर सत्र न्यायाधीश',
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
      return LeadingQuestionResult.fromJson(data);
    } else {
      throw Exception('सूचक जिरह प्रश्न निर्माण विफलता (${response.statusCode}): ${response.body}');
    }
  }
}

