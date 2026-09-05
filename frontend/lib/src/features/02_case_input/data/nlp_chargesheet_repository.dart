import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';

final nlpChargesheetRepositoryProvider = Provider<NlpChargesheetRepository>((ref) {
  return NlpChargesheetRepository();
});

class ChargesheetDeconstructResult {
  final String caseId;
  final List<String> factsExtracts;
  final List<String> prosecutionArguments;
  final List<String> statutesDetected;
  final List<String> provisionsDetected;
  final List<String> witnessesDetected;
  final List<String> personsDetected;
  final int totalSentencesProcessed;

  ChargesheetDeconstructResult({
    required this.caseId,
    required this.factsExtracts,
    required this.prosecutionArguments,
    required this.statutesDetected,
    required this.provisionsDetected,
    required this.witnessesDetected,
    required this.personsDetected,
    required this.totalSentencesProcessed,
  });

  factory ChargesheetDeconstructResult.fromJson(Map<String, dynamic> json) {
    return ChargesheetDeconstructResult(
      caseId: json['case_id'] as String,
      factsExtracts: List<String>.from(json['facts_extracts'] ?? []),
      prosecutionArguments: List<String>.from(json['prosecution_arguments'] ?? []),
      statutesDetected: List<String>.from(json['statutes_detected'] ?? []),
      provisionsDetected: List<String>.from(json['provisions_detected'] ?? []),
      witnessesDetected: List<String>.from(json['witnesses_detected'] ?? []),
      personsDetected: List<String>.from(json['persons_detected'] ?? []),
      totalSentencesProcessed: json['total_sentences_processed'] as int? ?? 0,
    );
  }
}

class NlpChargesheetRepository {
  Future<ChargesheetDeconstructResult> deconstructChargesheet({
    required String caseId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('उपयोगकर्ता प्रमाणीकृत नहीं है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/nlp/process-chargesheet');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'case_id': caseId,
        'chargesheet_text': text,
        'is_dummy_testing': AppEnvironment.enforceDummyData,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ChargesheetDeconstructResult.fromJson(data);
    } else {
      throw Exception('अभियोग पत्र विश्लेषण विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
