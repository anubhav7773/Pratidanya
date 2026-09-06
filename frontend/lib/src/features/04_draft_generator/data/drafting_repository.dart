import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/storage/courtroom_cache_service.dart';
import '../../../core/storage/courtroom_sync_manager.dart';
import '../domain/case_analysis_draft.dart';

final draftingRepositoryProvider = Provider<DraftingRepository>((ref) {
  final cacheService = ref.watch(courtroomCacheServiceProvider);
  return DraftingRepository(cacheService: cacheService);
});

class DraftingRepository {
  final CourtroomCacheService? _cacheService;

  DraftingRepository({CourtroomCacheService? cacheService})
      : _cacheService = cacheService;

  Future<CaseAnalysisDraft?> getCachedDraft(String caseId) async {
    try {
      final json = await _cacheService?.getCachedDraft(caseId);
      if (json != null) {
        return CaseAnalysisDraft.fromJson(json);
      }
    } catch (e) {
      debugPrint('[DraftingRepository] Error loading cached draft: $e');
    }
    return null;
  }

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

    try {
      // Force refresh token so no expired or stale token triggers 401
      final idToken = await user.getIdToken(true);
      final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/drafts/generate-360');

      final payload = jsonEncode({
        'case_id': caseId,
        'fir_number': firNumber,
        'sections': sections,
        'police_station': policeStation,
        'district': district,
        'factual_summary': factualSummary,
        'custody_status': custodyStatus,
        'extracted_facts': extractedFacts,
        'is_dummy_testing': AppEnvironment.enforceDummyData,
      });

      http.Response response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: payload,
      ).timeout(const Duration(seconds: 60));

      // Automatic 1-time retry on 502/503/504 (recovering from Render container cold start)
      if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
        debugPrint('[DraftingRepository] Server returned ${response.statusCode}, retrying once in 3 seconds...');
        await Future.delayed(const Duration(milliseconds: 3000));
        try {
          final refreshedToken = await user.getIdToken(true);
          response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $refreshedToken',
            },
            body: payload,
          ).timeout(const Duration(seconds: 60));
        } catch (retryErr) {
          debugPrint('[DraftingRepository] Retry attempt error: $retryErr');
        }
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        
        // Save to courtroom offline cache for basement courtroom access
        await _cacheService?.saveDraft(caseId, decoded);

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

        // Check if we have an existing cached draft for this case
        final cached = await getCachedDraft(caseId);
        if (cached != null) {
          debugPrint('[DraftingRepository] Server returned ${response.statusCode}, falling back to offline cached draft');
          return cached;
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      // Offline fallback
      final cached = await getCachedDraft(caseId);
      if (cached != null) {
        debugPrint('[DraftingRepository] Network error ($e), loaded draft from local courtroom cache');
        ActivityService.logActivity(
          activityType: 'OFFLINE_DRAFT_LOADED_FROM_CACHE',
          details: {'case_id': caseId},
        );
        return cached;
      }
      rethrow;
    }
  }
}
