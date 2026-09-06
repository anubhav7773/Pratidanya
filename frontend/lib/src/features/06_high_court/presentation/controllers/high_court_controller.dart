import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/high_court_repository.dart';
import '../../domain/high_court_models.dart';

final highCourtSuiteProvider =
    StateNotifierProvider<HighCourtSuiteController, AsyncValue<HighCourtAppealSuite?>>((ref) {
  return HighCourtSuiteController(ref.watch(highCourtRepositoryProvider));
});

class HighCourtSuiteController extends StateNotifier<AsyncValue<HighCourtAppealSuite?>> {
  final HighCourtRepository _repository;

  HighCourtSuiteController(this._repository) : super(const AsyncValue.data(null));

  Future<String> uploadTrialJudgment(File pdfFile, String pleadingType) async {
    state = const AsyncValue.loading();
    try {
      final pleadingId = await _repository.uploadAndParseJudgment(
        pdfFile: pdfFile,
        pleadingType: pleadingType,
      );
      return pleadingId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> synthesizeHighCourtPleading({
    required String pleadingId,
    required String statuteSystem,
    List<String> customAngles = const [],
    bool isInterlocutory = false,
    bool seeksAcquittalConversion = false,
    String pairokarName = 'सुरेश कुमार',
    String pairokarRelation = 'सगा भाई',
    int pairokarAge = 35,
    String pairokarAddress = 'लखनऊ, उत्तर प्रदेश',
    bool isDelayed = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Synthesize Main Memo of Appeal / Revision Grounds
      final suite = await _repository.generateHighCourtGrounds(
        pleadingId: pleadingId,
        statuteSystem: statuteSystem,
        customAngles: customAngles,
        isInterlocutory: isInterlocutory,
        seeksAcquittalConversion: seeksAcquittalConversion,
      );

      // 2. Attach Sec 389 Stay & Bail Application Suite
      await _repository.attachSuspensionBailSuite(
        suite: suite,
        pairokarName: pairokarName,
        pairokarRelation: pairokarRelation,
        pairokarAge: pairokarAge,
        pairokarAddress: pairokarAddress,
        statuteSystem: statuteSystem,
      );

      // 3. Attach Sec 5 Limitation Condonation Suite if flagged delayed
      if (isDelayed) {
        await _repository.attachSection5DelaySuite(
          suite: suite,
          pairokarName: pairokarName,
          pairokarRelation: pairokarRelation,
          pairokarAge: pairokarAge,
          pairokarAddress: pairokarAddress,
          delayReasonKey: 'POVERTY_AND_JAIL_COMMUNICATION',
        );
      }

      state = AsyncValue.data(suite);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void toggleCitationVerification(String citationId, bool isVerified) {
    final current = state.valueOrNull;
    if (current == null) return;

    for (final c in current.citedPrecedents) {
      if (c.citationId == citationId) {
        c.isManuallyVerified = isVerified;
      }
    }

    state = AsyncValue.data(current);
  }
}
