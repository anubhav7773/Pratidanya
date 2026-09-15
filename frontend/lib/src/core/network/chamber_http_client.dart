import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_environment.dart';
import '../localization/app_language.dart';

final chamberHttpClientProvider = Provider<ChamberHttpClient>((ref) {
  return ChamberHttpClient(ref);
});

class ChamberHttpClient {
  final Ref _ref;
  final http.Client _client = http.Client();

  ChamberHttpClient(this._ref);

  /// Retrieves an authentication token without throwing client-side exceptions.
  /// Falls back to the chamber's verified offline/dev token if Firebase has not initialized.
  Future<String> getSafeAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          return idToken;
        }
      }
    } catch (e) {
      dev.log('[AUTH] Firebase Auth token retrieval fallback: $e');
    }

    // Fallback: Persistent Chamber Advocate Session token
    final prefs = await SharedPreferences.getInstance();
    String? localToken = prefs.getString('chamber_advocate_token');
    if (localToken == null) {
      localToken = 'chamber_advocate_up_1234_anubhav';
      await prefs.setString('chamber_advocate_token', localToken);
    }
    return localToken;
  }

  /// Sends an authenticated POST request with telemetry headers attached.
  Future<http.Response> post({
    required String path,
    required Map<String, dynamic> body,
    required String actionName,
    String? caseId,
  }) async {
    final token = await getSafeAuthToken();
    final lang = _ref.read(appLanguageProvider).code;
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}$path');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Advocate-ID': 'adv_up_1234_anubhav',
      'X-Action-Name': actionName,
      'X-Case-ID': caseId ?? 'UNSPECIFIED',
      'X-Session-ID': 'SESSION_${DateTime.now().millisecondsSinceEpoch}',
      'X-Client-Language': lang,
      'X-Client-Platform': 'Flutter_Android_iOS',
    };

    dev.log('🚀 [HTTP DISPATCH] -> $actionName to $url');

    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    dev.log('📥 [HTTP RESPONSE] <- Status ${response.statusCode} for $actionName');
    return response;
  }

  /// Sends an authenticated GET request with telemetry headers attached.
  Future<http.Response> get({
    required String path,
    required String actionName,
  }) async {
    final token = await getSafeAuthToken();
    final lang = _ref.read(appLanguageProvider).code;
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}$path');

    final headers = {
      'Authorization': 'Bearer $token',
      'X-Advocate-ID': 'adv_up_1234_anubhav',
      'X-Action-Name': actionName,
      'X-Client-Language': lang,
    };

    return await _client.get(url, headers: headers);
  }
}
