import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/kanoon_case_record.dart';

final kanoonRepositoryProvider = Provider<KanoonRepository>((ref) {
  return KanoonRepository();
});

class KanoonRepository {
  Future<List<KanoonCaseRecord>> searchCases({
    required String courtId,
    required String query,
    int? year,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('उपयोगकर्ता प्रमाणीकृत नहीं है।');

    final idToken = await user.getIdToken();
    final uri = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/kanoon/search-cases').replace(
      queryParameters: {
        'court_id': courtId,
        'query': query.trim(),
        if (year != null) 'year': year.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => KanoonCaseRecord.fromJson(json)).toList();
    } else {
      throw Exception('न्यायालयीन केस खोज विफल (${response.statusCode})');
    }
  }

  Future<List<VerifiedCaseOrder>> fetchOrders({
    required String courtId,
    required String caseId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('उपयोगकर्ता प्रमाणीकृत नहीं है।');

    final idToken = await user.getIdToken();
    final uri = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/kanoon/cases/$caseId/orders').replace(
      queryParameters: {'court_id': courtId},
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => VerifiedCaseOrder.fromJson(json)).toList();
    } else {
      throw Exception('आदेश लोड विफल (${response.statusCode})');
    }
  }
}
