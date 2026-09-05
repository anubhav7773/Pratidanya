import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/precedent_citation.dart';
import '../../data/precedent_repository.dart';

class PrecedentSearchState {
  final bool hasSearched;
  final String lastQuery;
  final List<String> activeSections;
  final List<PrecedentCitation> results;

  PrecedentSearchState({
    required this.hasSearched,
    required this.lastQuery,
    required this.activeSections,
    required this.results,
  });

  factory PrecedentSearchState.initial() {
    return PrecedentSearchState(
      hasSearched: false,
      lastQuery: '',
      activeSections: [],
      results: [],
    );
  }

  PrecedentSearchState copyWith({
    bool? hasSearched,
    String? lastQuery,
    List<String>? activeSections,
    List<PrecedentCitation>? results,
  }) {
    return PrecedentSearchState(
      hasSearched: hasSearched ?? this.hasSearched,
      lastQuery: lastQuery ?? this.lastQuery,
      activeSections: activeSections ?? this.activeSections,
      results: results ?? this.results,
    );
  }
}

final precedentSearchControllerProvider =
    StateNotifierProvider<PrecedentSearchController, AsyncValue<PrecedentSearchState>>((ref) {
  return PrecedentSearchController(ref.watch(precedentRepositoryProvider));
});

class PrecedentSearchController extends StateNotifier<AsyncValue<PrecedentSearchState>> {
  final PrecedentRepository _repository;

  PrecedentSearchController(this._repository)
      : super(AsyncValue.data(PrecedentSearchState.initial()));

  Future<void> executeSearch({
    required String query,
    required List<String> sections,
  }) async {
    state = const AsyncValue.loading();
    try {
      final citations = await _repository.searchSemanticPrecedents(
        queryText: query,
        targetSections: sections,
      );

      state = AsyncValue.data(PrecedentSearchState(
        hasSearched: true,
        lastQuery: query,
        activeSections: sections,
        results: citations,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void toggleVerification(String citationId, bool isVerified) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updated = currentState.results.map((c) {
      if (c.citationId == citationId) {
        return c.copyWith(isManuallyVerified: isVerified);
      }
      return c;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(results: updated));
  }
}
