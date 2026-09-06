import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/case_analysis_draft.dart';
import '../../data/drafting_repository.dart';

final draftingControllerProvider =
    StateNotifierProvider<DraftingController, AsyncValue<CaseAnalysisDraft?>>((ref) {
  return DraftingController(ref.watch(draftingRepositoryProvider));
});

class DraftingController extends StateNotifier<AsyncValue<CaseAnalysisDraft?>> {
  final DraftingRepository _repository;

  DraftingController(this._repository) : super(const AsyncValue.data(null));

  Future<void> generateDraft({
    required String caseId,
    required String firNumber,
    required List<String> sections,
    required String policeStation,
    required String district,
    required String factualSummary,
    required String custodyStatus,
    List<String> extractedFacts = const [],
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.generate360Draft(
        caseId: caseId,
        firNumber: firNumber,
        sections: sections,
        policeStation: policeStation,
        district: district,
        factualSummary: factualSummary,
        custodyStatus: custodyStatus,
        extractedFacts: extractedFacts,
      );
    });
  }

  Future<bool> loadCachedDraft(String caseId) async {
    final cached = await _repository.getCachedDraft(caseId);
    if (cached != null) {
      state = AsyncValue.data(cached);
      return true;
    }
    return false;
  }

  void updateGround(int index, String newText) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = List<String>.from(current.statutoryGrounds);
    updated[index] = newText;
    state = AsyncValue.data(current.copyWith(statutoryGrounds: updated));
  }

  void updateWeakness(int index, String newText) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = List<String>.from(current.prosecutionWeaknesses);
    updated[index] = newText;
    state = AsyncValue.data(current.copyWith(prosecutionWeaknesses: updated));
  }

  void toggleCitationVerification(String citationId, bool isVerified) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedCitations = current.citedPrecedents.map((c) {
      if (c.citationId == citationId) {
        return c.copyWith(isManuallyVerified: isVerified);
      }
      return c;
    }).toList();

    state = AsyncValue.data(current.copyWith(citedPrecedents: updatedCitations));
  }
}
