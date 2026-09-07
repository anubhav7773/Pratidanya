import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/criminal_case.dart';
import '../../data/case_repository.dart';

final caseSearchQueryProvider = StateProvider<String>((ref) => '');

final caseListProvider = FutureProvider<List<CriminalCase>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final searchQuery = ref.watch(caseSearchQueryProvider);
  final repository = ref.watch(caseRepositoryProvider);

  return await repository.fetchUpcomingHearingCases(
    advocateId: user.uid,
    searchQuery: searchQuery,
  );
});

final caseFormControllerProvider = StateNotifierProvider<CaseFormController, AsyncValue<CriminalCase?>>((ref) {
  return CaseFormController(
    repository: ref.watch(caseRepositoryProvider),
    ref: ref,
  );
});

class CaseFormController extends StateNotifier<AsyncValue<CriminalCase?>> {
  final CriminalCaseRepository _repository;
  final Ref _ref;

  CaseFormController({
    required CriminalCaseRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> createCase({
    required String firNumber,
    required String policeStation,
    required String district,
    required String stateJurisdiction,
    required String accusedName,
    required String accusedCustodyStatus,
    required String statuteSystem,
    required List<String> underSections,
    required String courtDesignation,
    required String stageOfCase,
    String? complainantName,
    String? caseNumber,
    String? cnrNumber,
    DateTime? nextHearingDate,
    DateTime? arrestDate,
    String? lastCourtOrder,
  }) async {
    state = const AsyncValue.loading();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = AsyncValue.error('उपयोगकर्ता प्रमाणीकृत नहीं है।', StackTrace.current);
      return false;
    }

    try {
      final newCase = await _repository.createCriminalCase(
        advocateId: user.uid,
        firNumber: firNumber,
        policeStation: policeStation,
        district: district,
        state: stateJurisdiction,
        accusedName: accusedName,
        accusedCustodyStatus: accusedCustodyStatus,
        statuteSystem: statuteSystem,
        underSections: underSections,
        courtDesignation: courtDesignation,
        stageOfCase: stageOfCase,
        complainantName: complainantName,
        caseNumber: caseNumber,
        cnrNumber: cnrNumber,
        nextHearingDate: nextHearingDate,
        arrestDate: arrestDate,
        lastCourtOrder: lastCourtOrder,
      );

      state = AsyncValue.data(newCase);
      _ref.invalidate(caseListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      return false;
    }
  }

  Future<void> archiveCase(String caseId) async {
    try {
      await _repository.archiveCase(caseId);
      _ref.invalidate(caseListProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCase(String caseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _repository.hardDeleteCase(caseId: caseId, advocateId: user.uid);
      _ref.invalidate(caseListProvider);
    } catch (e) {
      rethrow;
    }
  }
}
