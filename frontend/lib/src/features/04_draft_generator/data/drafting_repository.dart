import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/case_analysis_draft.dart';

final draftingRepositoryProvider = Provider<DraftingRepository>((ref) {
  return DraftingRepository();
});

class DraftingRepository {
  Future<CaseAnalysisDraft> generate360Draft({
    required String caseId,
    required String firNumber,
    required List<String> sections,
    required String policeStation,
    required String district,
    required String factualSummary,
    required String custodyStatus,
    List<String> extractedFacts = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/drafts/generate-360');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'case_id': caseId,
        'fir_number': firNumber,
        'sections': sections,
        'police_station': policeStation,
        'district': district,
        'factual_summary': factualSummary,
        'custody_status': custodyStatus,
        'extracted_facts': extractedFacts,
        'is_dummy_testing': AppEnvironment.enforceDummyData,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return CaseAnalysisDraft.fromJson(decoded);
    } else if (response.statusCode == 402) {
      throw Exception('दैनिक कोटा समाप्त: अतिरिक्त ड्राफ्ट के लिए विज्ञापन देखें या प्रो चैंबर में अपग्रेड करें।');
    } else {
      throw Exception('ड्राफ्ट निर्माण विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
