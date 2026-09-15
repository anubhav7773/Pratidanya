import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/case_docket_model.dart';

final caseDocketRepositoryProvider = Provider<CaseDocketRepository>((ref) {
  return CaseDocketRepository();
});

final caseDocketListProvider = StateNotifierProvider<CaseDocketNotifier, List<CaseDocketModel>>((ref) {
  final repo = ref.read(caseDocketRepositoryProvider);
  return CaseDocketNotifier(repo);
});

class CaseDocketNotifier extends StateNotifier<List<CaseDocketModel>> {
  final CaseDocketRepository _repository;

  CaseDocketNotifier(this._repository) : super([]) {
    loadDockets();
  }

  void loadDockets() {
    state = _repository.getRealisticChamberDockets();
  }

  void addDocket(CaseDocketModel docket) {
    state = [docket, ...state];
  }
}

class CaseDocketRepository {
  List<CaseDocketModel> getRealisticChamberDockets() {
    final now = DateTime.now();

    return [
      // Case 1: Default Bail Crystallized (91 days elapsed on 90-day bar)
      CaseDocketModel(
        id: 'LKO-CR-2026-101',
        crimeNumber: 'मु.अ.सं. 124/2026',
        firYear: 2026,
        policeStation: 'कोतवाली नगर',
        district: 'लखनऊ',
        accusedName: 'रामू उर्फ राम प्रकाश',
        courtName: 'CJM, लखनऊ (कक्ष संख्या 14)',
        substantiveSections: 'BNS 103(1) / 351(2)',
        substantiveRegime: 'BNS',
        custodyStatus: 'JUDICIAL_CUSTODY',
        custodyDaysElapsed: 91,
        statutoryThresholdDays: 90,
        nextHearingDate: now,
        hearingPurpose: 'जमानत प्रार्थना पत्र सुनवाई (Sec 187 BNSS Default Bail)',
        isDefaultBailUrgent: true,
      ),

      // Case 2: Commercial NDPS with Section 52A & Malkhana break
      CaseDocketModel(
        id: 'LKO-CR-2026-102',
        crimeNumber: 'मु.अ.सं. 89/2026',
        firYear: 2026,
        policeStation: 'हजरतगंज',
        district: 'लखनऊ',
        accusedName: 'दिनेश कुमार',
        courtName: 'विशेष न्यायाधीश (NDPS Act, कोर्ट संख्या 3)',
        substantiveSections: 'NDPS Act Sec 20(b)(ii)(C) / Sec 8',
        substantiveRegime: 'HYBRID',
        custodyStatus: 'JUDICIAL_CUSTODY',
        custodyDaysElapsed: 185,
        statutoryThresholdDays: 180,
        nextHearingDate: now,
        hearingPurpose: 'आरोप विरचन व साक्ष्य जब्ती फर्द (Plea of Defense)',
        hasForensicTamperingAlert: true,
      ),

      // Case 3: Rape / BNS 69 Trial with PW-2 Cross-examination
      CaseDocketModel(
        id: 'LKO-CR-2025-412',
        crimeNumber: 'मु.अ.सं. 412/2025',
        firYear: 2025,
        policeStation: 'गोमती नगर',
        district: 'लखनऊ',
        accusedName: 'अमन वर्मा',
        courtName: 'अपर सत्र न्यायाधीश (विशेष पॉक्सो / महिला अपराध)',
        substantiveSections: 'BNS 69 / BNS 351(3)',
        substantiveRegime: 'BNS',
        custodyStatus: 'BAIL_GRANTED',
        custodyDaysElapsed: 45,
        statutoryThresholdDays: 90,
        nextHearingDate: now.add(const Duration(days: 1)),
        hearingPurpose: 'साक्षी प्रतिपरीक्षा (PW-2 Cross-examination under Sec 147 BSA)',
      ),

      // Case 4: UP Gangsters Act Predicate Acquittal Collapse
      CaseDocketModel(
        id: 'LKO-CR-2026-001',
        crimeNumber: 'मु.अ.सं. 01/2026',
        firYear: 2026,
        policeStation: 'अलीगंज',
        district: 'लखनऊ',
        accusedName: 'रवि प्रकाश',
        courtName: 'विशेष न्यायाधीश (गैंगस्टर्स एक्ट, कोर्ट संख्या 5)',
        substantiveSections: 'उ.प्र. गिरोहबंद अधिनियम धारा 2/3',
        substantiveRegime: 'HYBRID',
        custodyStatus: 'JUDICIAL_CUSTODY',
        custodyDaysElapsed: 62,
        statutoryThresholdDays: 90,
        nextHearingDate: now.add(const Duration(days: 3)),
        hearingPurpose: 'गैंग चार्ट वैधता व डिस्चार्ज प्रार्थना पत्र (Farhana Doctrine)',
      ),

      // Case 5: Undertrial Relief under Section 479 BNSS (1/3rd Sentence completed)
      CaseDocketModel(
        id: 'LKO-CR-2024-302',
        crimeNumber: 'मु.अ.सं. 302/2024',
        firYear: 2024,
        policeStation: 'चौक',
        district: 'लखनऊ',
        accusedName: 'मोहम्मद असलम',
        courtName: 'ACJM (कक्ष संख्या 8)',
        substantiveSections: 'भा.दं.वि. 379 / 411',
        substantiveRegime: 'IPC',
        custodyStatus: 'JUDICIAL_CUSTODY',
        custodyDaysElapsed: 420,
        statutoryThresholdDays: 365,
        nextHearingDate: now.add(const Duration(days: 2)),
        hearingPurpose: 'धारा 479 BNSS विचाराधीन बंदी रिहाई आवेदन',
        isUnderTrialReliefEligible: true,
      ),
    ];
  }
}
