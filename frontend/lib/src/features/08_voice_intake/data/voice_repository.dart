import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../domain/voice_intake_result.dart';

final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  return VoiceRepository();
});

class VoiceRepository {
  final http.Client? _client;

  VoiceRepository({http.Client? client}) : _client = client;

  Future<VoiceDictationResult> transcribeAndStructureAudio({
    required File audioFile,
    required int durationSeconds,
    String? caseId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('प्रमाणीकरण आवश्यक है।');

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/voice/transcribe-and-structure');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $idToken'
      ..fields['duration_seconds'] = durationSeconds.toString();

    if (caseId != null) {
      request.fields['case_id'] = caseId;
    }

    request.files.add(await http.MultipartFile.fromPath(
      'audio_file',
      audioFile.path,
    ));

    final streamedResponse = _client != null 
        ? await _client.send(request).timeout(const Duration(seconds: 60))
        : await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return VoiceDictationResult.fromJson(data);
    } else {
      String errorMessage;
      if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
        errorMessage = 'सर्वर पर उच्च भार या नेटवर्क पुनःप्रारंभ (त्रुटि ${response.statusCode})। कृपया 5 सेकंड बाद पुनः बोलकर प्रयास करें।';
      } else {
        try {
          final errJson = jsonDecode(utf8.decode(response.bodyBytes));
          errorMessage = errJson['detail']?.toString() ?? 'वॉयस प्रोसेसिंग विफलता (${response.statusCode})';
        } catch (_) {
          errorMessage = 'वॉयस प्रोसेसिंग विफलता (${response.statusCode})। कृपया स्पष्ट आवाज में पुनः बोलें।';
        }
      }
      throw Exception(errorMessage);
    }
  }
}
