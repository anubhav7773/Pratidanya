import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/precedent_citation.dart';

final precedentRepositoryProvider = Provider<PrecedentRepository>((ref) {
  return PrecedentRepository();
});

class PrecedentRepository {
  Future<List<PrecedentCitation>> searchSemanticPrecedents({
    required String queryText,
    required List<String> targetSections,
    String? filterMode,
    double threshold = 0.65,
    int limit = 5,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है: सत्र अमान्य।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/precedents/search');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'query_text': queryText.trim(),
        'target_sections': targetSections,
        if (filterMode != null) 'filter_mode': filterMode,
        'similarity_threshold': threshold,
        'limit': limit,
        'is_dummy_testing': AppEnvironment.enforceDummyData,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((item) => PrecedentCitation.fromJson(item)).toList();
    } else if (response.statusCode == 403) {
      throw Exception('गोपनीयता अवरोध: पेड-टियर सक्रिय किए बिना वास्तविक केस तथ्यों की खोज प्रतिबंधित है।');
    } else {
      throw Exception('मिसाल खोज विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
