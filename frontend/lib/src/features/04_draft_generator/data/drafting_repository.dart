import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/services/activity_service.dart';
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

    ActivityService.logActivity(
      activityType: 'DRAFT_GENERATE_360_REQUESTED',
      details: {
        'case_id': caseId,
        'fir_number': firNumber,
        'sections': sections,
        'district': district,
      },
    );

    // Force refresh token so no expired or stale token triggers 401
    final idToken = await user.getIdToken(true);
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
      ActivityService.logActivity(
        activityType: 'DRAFT_GENERATE_360_SUCCESS',
        details: {
          'case_id': caseId,
          'grounds_count': (decoded['statutory_grounds'] as List?)?.length ?? 0,
          'precedents_count': (decoded['cited_precedents'] as List?)?.length ?? 0,
        },
      );
      return CaseAnalysisDraft.fromJson(decoded);
    } else {
      String errorMessage;
      if (response.statusCode == 402) {
        errorMessage = 'दैनिक कोटा समाप्त: अतिरिक्त ड्राफ्ट के लिए विज्ञापन देखें या प्रो चैंबर में अपग्रेड करें।';
      } else if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
        errorMessage = 'सर्वर पर उच्च भार या नेटवर्क रीस्टार्ट (त्रुटि ${response.statusCode})। कृपया 5-10 सेकंड बाद पुनः "ड्राफ्ट तैयार करें" दबाएं।';
      } else {
        // Try parsing JSON detail if available, avoid dumping raw HTML
        try {
          final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
          errorMessage = errorJson['detail']?.toString() ?? 'ड्राफ्ट निर्माण विफल (${response.statusCode})';
        } catch (_) {
          errorMessage = 'ड्राफ्ट निर्माण विफलता (${response.statusCode})। कृपया पुनः प्रयास करें।';
        }
      }

      ActivityService.logActivity(
        activityType: 'DRAFT_GENERATION_FAILED',
        details: {
          'case_id': caseId,
          'fir_number': firNumber,
          'status_code': response.statusCode,
          'error_message': errorMessage,
        },
      );

      throw Exception(errorMessage);
    }
  }
}
