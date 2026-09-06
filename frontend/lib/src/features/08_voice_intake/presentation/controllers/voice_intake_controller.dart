import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/voice_recording_service.dart';
import '../../data/voice_repository.dart';
import '../../domain/voice_intake_result.dart';

enum VoiceRecordingState { idle, recording, processing, completed, error }

class VoiceIntakeState {
  final VoiceRecordingState recordingState;
  final int durationSeconds;
  final String? audioFilePath;
  final VoiceDictationResult? result;
  final String? errorMessage;

  VoiceIntakeState({
    required this.recordingState,
    this.durationSeconds = 0,
    this.audioFilePath,
    this.result,
    this.errorMessage,
  });

  VoiceIntakeState copyWith({
    VoiceRecordingState? recordingState,
    int? durationSeconds,
    String? audioFilePath,
    VoiceDictationResult? result,
    String? errorMessage,
  }) {
    return VoiceIntakeState(
      recordingState: recordingState ?? this.recordingState,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final voiceRecordingServiceProvider = Provider<VoiceRecordingService>((ref) {
  final service = VoiceRecordingService();
  ref.onDispose(() => service.dispose());
  return service;
});

final voiceIntakeControllerProvider =
    StateNotifierProvider.autoDispose<VoiceIntakeController, VoiceIntakeState>((ref) {
  return VoiceIntakeController(
    recordingService: ref.watch(voiceRecordingServiceProvider),
    repository: ref.watch(voiceRepositoryProvider),
  );
});

class VoiceIntakeController extends StateNotifier<VoiceIntakeState> {
  final VoiceRecordingService _recordingService;
  final VoiceRepository _repository;
  Timer? _timer;

  VoiceIntakeController({
    required VoiceRecordingService recordingService,
    required VoiceRepository repository,
  })  : _recordingService = recordingService,
        _repository = repository,
        super(VoiceIntakeState(recordingState: VoiceRecordingState.idle));

  Future<void> startRecording() async {
    try {
      await _recordingService.startRecording();
      state = state.copyWith(
        recordingState: VoiceRecordingState.recording,
        durationSeconds: 0,
        errorMessage: null,
      );

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      });
    } catch (e) {
      state = state.copyWith(
        recordingState: VoiceRecordingState.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopAndProcessRecording({String? caseId}) async {
    _timer?.cancel();
    try {
      final path = await _recordingService.stopRecording();
      if (path == null) {
        state = state.copyWith(recordingState: VoiceRecordingState.idle);
        return;
      }

      state = state.copyWith(
        recordingState: VoiceRecordingState.processing,
        audioFilePath: path,
      );

      final audioFile = File(path);
      final result = await _repository.transcribeAndStructureAudio(
        audioFile: audioFile,
        durationSeconds: state.durationSeconds,
        caseId: caseId,
      );

      // Delete local temporary audio file immediately after successful upload
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      state = state.copyWith(
        recordingState: VoiceRecordingState.completed,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        recordingState: VoiceRecordingState.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cancelRecording() async {
    _timer?.cancel();
    await _recordingService.cancelRecording();
    state = VoiceIntakeState(recordingState: VoiceRecordingState.idle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
