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

    final streamedResponse = _client != null ? await _client.send(request) : await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return VoiceDictationResult.fromJson(data);
    } else {
      throw Exception('वॉयस प्रोसेसिंग विफलता (${response.statusCode}): ${response.body}');
    }
  }
}
