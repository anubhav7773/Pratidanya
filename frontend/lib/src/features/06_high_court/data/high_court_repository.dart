import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/high_court_models.dart';

final highCourtRepositoryProvider = Provider<HighCourtRepository>((ref) {
  return HighCourtRepository();
});

class HighCourtRepository {
  Future<String> uploadAndParseJudgment({
    required File pdfFile,
    required String pleadingType,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/high-court/parse-trial-judgment');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $idToken'
      ..fields['pleading_type'] = pleadingType
      ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data['pleading_id'] as String;
    } else {
      throw Exception('निर्णय पार्सिंग विफलता (${response.statusCode}): ${response.body}');
    }
  }

  Future<HighCourtAppealSuite> generateHighCourtGrounds({
    required String pleadingId,
    required String statuteSystem,
    List<String> customAngles = const [],
    bool isInterlocutory = false,
    bool seeksAcquittalConversion = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/high-court/generate-grounds');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'pleading_id': pleadingId,
        'statute_system': statuteSystem,
        'custom_defense_angles': customAngles,
        'is_interlocutory_order': isInterlocutory,
        'seeks_acquittal_conversion': seeksAcquittalConversion,
        'include_section_389_bail_grounds': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return HighCourtAppealSuite.fromJson(data);
    } else {
      throw Exception('आधार निर्माण विफलता (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> attachSuspensionBailSuite({
    required HighCourtAppealSuite suite,
    required String pairokarName,
    required String pairokarRelation,
    required int pairokarAge,
    required String pairokarAddress,
    required String statuteSystem,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/high-court/interlocutory/generate-suspension-bail');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'pleading_id': suite.pleadingId,
        'statute_system': statuteSystem,
        'trial_bail_status': 'ON_BAIL_NEVER_MISUSED',
        'fine_deposit_status': 'READY_TO_DEPOSIT',
        'pairokar_name': pairokarName,
        'pairokar_relation': pairokarRelation,
        'pairokar_age': pairokarAge,
        'pairokar_address': pairokarAddress,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      suite.suspensionGrounds = List<String>.from(data['grounds_for_suspension'] ?? []);
      suite.suspensionInterimPrayer = data['interim_bail_prayer'] as String?;
      suite.suspensionAffidavitText = data['affidavit_text_hindi'] as String?;
    }
  }

  Future<void> attachSection5DelaySuite({
    required HighCourtAppealSuite suite,
    required String pairokarName,
    required String pairokarRelation,
    required int pairokarAge,
    required String pairokarAddress,
    required String delayReasonKey,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/high-court/interlocutory/generate-section-5-delay');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'pleading_id': suite.pleadingId,
        'pairokar_name': pairokarName,
        'pairokar_relation': pairokarRelation,
        'pairokar_age': pairokarAge,
        'pairokar_address': pairokarAddress,
        'primary_delay_reason': delayReasonKey,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      suite.delayGrounds = List<String>.from(data['delay_grounds'] ?? []);
      suite.delayPrayerText = data['prayer_text_hindi'] as String?;
      suite.delayAffidavitDeponent = data['affidavit_deponent_block'] as String?;
      suite.delayAffidavitParagraphs = List<String>.from(data['affidavit_paragraphs'] ?? []);
      suite.delayAffidavitVerification = data['affidavit_verification_clause'] as String?;
    }
  }
}
