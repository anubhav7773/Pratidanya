import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_environment.dart';

class ActivityService {
  /// Fire-and-forget activity logger to stream user actions into Render backend logs
  static void logActivity({
    required String activityType,
    String? advocateId,
    Map<String, dynamic>? details,
  }) {
    unawaited(_sendActivity(
      activityType: activityType,
      advocateId: advocateId,
      details: details,
    ));
  }

  static Future<void> _sendActivity({
    required String activityType,
    String? advocateId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      String? uid = advocateId ?? user?.uid;

      if (user != null) {
        try {
          final idToken = await user.getIdToken();
          headers['Authorization'] = 'Bearer $idToken';
        } catch (_) {}
      }

      final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/activity/log');
      final body = jsonEncode({
        'activity_type': activityType,
        'advocate_id': uid,
        'details': details ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });

      await http.post(url, headers: headers, body: body).timeout(
        const Duration(seconds: 4),
        onTimeout: () => http.Response('timeout', 408),
      );
    } catch (e) {
      debugPrint('[ActivityService] Log telemetry note: $e');
    }
  }
}
