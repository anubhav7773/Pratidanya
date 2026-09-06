import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecordingService {
  final AudioRecorder _audioRecorder;
  String? _currentRecordingPath;
  bool _isRecording = false;

  VoiceRecordingService({AudioRecorder? audioRecorder})
      : _audioRecorder = audioRecorder ?? AudioRecorder();

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/dictation_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: filePath);
      _currentRecordingPath = filePath;
      _isRecording = true;
      debugPrint("[Voice Service] Recording started at: $filePath");
    } else {
      throw Exception('माइक्रोफोन उपयोग की अनुमति अस्वीकृत है।');
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _audioRecorder.stop();
    _isRecording = false;
    debugPrint("[Voice Service] Recording stopped. File saved: $path");
    return path;
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      _isRecording = false;
    }
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentRecordingPath = null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
