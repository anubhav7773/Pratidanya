import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/core/utils/citation_formatter.dart';
import 'package:pratidnya/src/features/04_draft_generator/data/drafting_repository.dart';
import 'package:pratidnya/src/features/04_draft_generator/domain/case_analysis_draft.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Six Critical Production Bugs Root-Cause Verification', () {
    test('Bug #2 & #3: Precedent URLs must be 100% accurate without 404 or misdirection', () {
      // Satender Kumar Antil v. CBI (2022 10 SCC 51)
      final antilFromCitation = CitationFormatter.getOfficialPortalUrl('2022 10 SCC 51');
      final antilFromKey = CitationFormatter.getOfficialPortalUrl('SC-SATENDER-ANTIL-2022');
      final antilFromText = CitationFormatter.getOfficialPortalUrl('सत्येंद्र कुमार अंतिल बनाम सीबीआई 2022');

      expect(antilFromCitation, equals('https://indiankanoon.org/doc/7148380/'),
          reason: 'Antil Kanoon Doc ID must be 7148380 and never 171587391');
      expect(antilFromKey, equals('https://indiankanoon.org/doc/7148380/'));
      expect(antilFromText, equals('https://indiankanoon.org/doc/7148380/'));

      // Babu Singh v. State of UP (AIR 1978 SC 527)
      final babuFromCitation = CitationFormatter.getOfficialPortalUrl('AIR 1978 SC 527');
      final babuFromKey = CitationFormatter.getOfficialPortalUrl('SC-BABU-SINGH-1978');
      final babuFromText = CitationFormatter.getOfficialPortalUrl('बाबू सिंह बनाम उत्तर प्रदेश राज्य');

      expect(babuFromCitation, equals('https://indiankanoon.org/doc/1515744/'),
          reason: 'Babu Singh Kanoon Doc ID must be 1515744 and never 1841394');
      expect(babuFromKey, equals('https://indiankanoon.org/doc/1515744/'));
      expect(babuFromText, equals('https://indiankanoon.org/doc/1515744/'));

      // Ensure deprecated hallucinated/misdirected URLs are blocked and never returned
      expect(antilFromCitation.contains('171587391'), isFalse);
      expect(babuFromCitation.contains('1841394'), isFalse);
    });

    test('Bug #1: Spot checking/arrest must eliminate FIR delay from prosecution weaknesses', () {
      // Mock emergency synthesis when checking/spot arrest is present
      final repo = DraftingRepository();
      
      const spotArrestFact = 'पुलिस द्वारा चेकिंग के दौरान मौके पर ही प्रार्थी की तत्काल गिरफ्तारी दर्शित की गई है। कोई स्वतंत्र साक्षी नहीं बुलाया गया।';
      
      final draft = repo.synthesizeEmergencyLocalDraft(
        caseId: 'test-case-1',
        firNumber: '101/2026',
        district: 'Lucknow',
        accusedName: 'रामू',
        sections: ['307 IPC'],
        factualSummary: spotArrestFact,
      );

      // Check prosecution weaknesses: FIR delay must be 100% absent
      for (final weakness in draft.prosecutionWeaknesses) {
        expect(
          weakness.contains('एफ.आई.आर. दर्ज कराने में अकारण') ||
          weakness.contains('एफ.आई.आर. में अकारण विलंब') ||
          weakness.contains('विलंब का कोई संतोषजनक स्पष्टीकरण'),
          isFalse,
          reason: 'Spot arrest must never allege FIR delay contradiction: "$weakness"',
        );
      }

      // Check that spot checking procedural defects were added instead
      final hasIndependentWitnessDefect = draft.prosecutionWeaknesses.any(
        (w) => w.contains('स्वतंत्र') || w.contains('चेकिंग') || w.contains('जीडी') || w.contains('साक्षी'),
      );
      if (!hasIndependentWitnessDefect) {
        print('ACTUAL WEAKNESSES: ${draft.prosecutionWeaknesses}');
      }
      expect(hasIndependentWitnessDefect, isTrue,
          reason: 'Spot arrest should challenge search/seizure and independent witness procedure');

      // Check citations inside draft: Antil and Babu Singh must have exact IDs
      final antilCitation = draft.citedPrecedents.firstWhere(
        (p) => p.citationId.toUpperCase().contains('SATENDER'),
      );
      expect(antilCitation.verifiedSourceUrl, equals('https://indiankanoon.org/doc/7148380/'));

      final babuCitation = draft.citedPrecedents.firstWhere(
        (p) => p.citationId.toUpperCase().contains('BABU-SINGH'),
      );
      expect(babuCitation.verifiedSourceUrl, equals('https://indiankanoon.org/doc/1515744/'));
    });

    test('Bug #4: CaseAnalysisDraft citedPrecedents must enable unblocked 3/3 verification', () {
      final repo = DraftingRepository();
      final draft = repo.synthesizeEmergencyLocalDraft(
        caseId: 'test-case-2',
        firNumber: '102/2026',
        district: 'Lucknow',
        accusedName: 'श्यामू',
        sections: ['420 IPC'],
        factualSummary: 'मामला सामान्य है',
      );

      expect(draft.citedPrecedents.length, greaterThanOrEqualTo(3));
      for (final p in draft.citedPrecedents) {
        expect(p.verifiedSourceUrl, isNotNull);
        expect(p.verifiedSourceUrl.startsWith('https://indiankanoon.org/doc/'), isTrue);
        expect(p.quotedPassage.isNotEmpty, isTrue);
      }
    });
  });
}
