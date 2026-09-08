import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/03_precedent_search/domain/kanoon_case_record.dart';
import 'package:pratidnya/src/features/03_precedent_search/domain/precedent_citation.dart';
import 'package:pratidnya/src/features/03_precedent_search/presentation/controllers/precedent_controller.dart';
import 'package:pratidnya/src/features/03_precedent_search/presentation/widgets/precedent_abstain_widget.dart';
import 'package:pratidnya/src/features/03_precedent_search/presentation/widgets/precedent_citation_card.dart';
import 'package:pratidnya/src/features/03_precedent_search/data/precedent_repository.dart';

class MockPrecedentRepository extends PrecedentRepository {
  final List<PrecedentCitation> stubbedResults;
  MockPrecedentRepository({this.stubbedResults = const []});

  @override
  Future<List<PrecedentCitation>> searchSemanticPrecedents({
    required String queryText,
    required List<String> targetSections,
    String? filterMode,
    double threshold = 0.65,
    int limit = 5,
  }) async {
    return stubbedResults;
  }
}

void main() {
  group('Goal 5: Domain Models & Serialization', () {
    test('PrecedentCitation JSON roundtrip maintains verified attributes and accuracy', () {
      final citation = PrecedentCitation(
        id: 'prec_001',
        citationId: 'AIR 1980 SC 785',
        caseTitle: 'बाबू सिंह बनाम उत्तर प्रदेश राज्य',
        courtName: 'उच्चतम न्यायालय, भारत',
        judgmentDate: '1978-01-31',
        actName: 'दंड प्रक्रिया संहिता',
        sectionNumbers: ['437', '439'],
        headnoteHindi: 'जमानत एक सामान्य नियम है और जेल अपवाद।',
        verbatimText: 'Bail is the rule and committal to jail an exception.',
        paragraphNumber: 16,
        verifiedSourceUrl: 'https://judgments.ecourts.gov.in/dummy_785.pdf',
        similarityScore: 0.892,
        isManuallyVerified: false,
      );

      final json = citation.toJson();
      expect(json['citation_id'], 'AIR 1980 SC 785');
      expect(json['similarity_score'], 0.892);
      expect(json['verified_source_url'], startsWith('https://'));

      final reconstructed = PrecedentCitation.fromJson(json);
      expect(reconstructed.id, 'prec_001');
      expect(reconstructed.caseTitle, 'बाबू सिंह बनाम उत्तर प्रदेश राज्य');
      expect(reconstructed.paragraphNumber, 16);
      expect(reconstructed.isManuallyVerified, false);
    });

    test('KanoonCaseRecord fromJson maps court data accurately', () {
      final kanoonJson = {
        'id': 'kanoon_101',
        'court_id': 'APHC01',
        'case_number': 'Bail App 1244 of 2026',
        'cnr_number': 'UPHC010012442026',
        'filing_date': '2026-02-15',
        'status': 'DISPOSED',
        'petitioner': 'श्यामू',
        'respondent': 'राज्य',
        'police_station': 'कोतवाली',
        'fir_number': '124/2026',
        'under_sections': ['379', '411'],
        'presiding_judge': 'न्यायमूर्ति शर्मा'
      };

      final record = KanoonCaseRecord.fromJson(kanoonJson);
      expect(record.courtId, 'APHC01');
      expect(record.underSections, contains('379'));
      expect(record.underSections, contains('411'));
      expect(record.presidingJudge, 'न्यायमूर्ति शर्मा');
    });
  });

  group('Goal 5: State Controller & Manual Verification Propagation', () {
    test('Manual Verification: toggleVerification updates citation state', () async {
      final initialCitation = PrecedentCitation(
        id: 'prec_001',
        citationId: 'AIR 1980 SC 785',
        caseTitle: 'बाबू सिंह बनाम उत्तर प्रदेश राज्य',
        courtName: 'उच्चतम न्यायालय, भारत',
        judgmentDate: '1978-01-31',
        actName: 'CrPC',
        sectionNumbers: ['437'],
        headnoteHindi: 'जमानत नियम है',
        verbatimText: 'Bail is the rule',
        paragraphNumber: 12,
        verifiedSourceUrl: 'https://judgments.ecourts.gov.in/test.pdf',
        similarityScore: 0.88,
        isManuallyVerified: false,
      );

      final mockRepo = MockPrecedentRepository(stubbedResults: [initialCitation]);
      final controller = PrecedentSearchController(mockRepo);

      await controller.executeSearch(query: 'जमानत नियम', sections: ['437']);

      final stateBefore = controller.state.value!;
      expect(stateBefore.results.first.isManuallyVerified, isFalse);

      // Advocate ticks verification checkbox
      controller.toggleVerification('AIR 1980 SC 785', true);

      final stateAfter = controller.state.value!;
      expect(stateAfter.results.first.isManuallyVerified, isTrue);
    });
  });

  group('Goal 5: Rule 3 Abstain Engine & Rule 1 Grounded Citation Widgets', () {
    testWidgets('Rule 3 Abstain Widget renders statutory warning when no results found', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrecedentAbstainWidget(queryTerm: 'अज्ञात काल्पनिक धारा'),
          ),
        ),
      );

      expect(find.text('कोई पुष्ट कानूनी मिसाल (Precedent) नहीं मिली'), findsOneWidget);
      expect(find.textContaining('न्यूनतम 65% प्रासंगिक निर्णय उपलब्ध नहीं है'), findsOneWidget);
      expect(find.textContaining('BCI Rule 5'), findsOneWidget);
    });

    testWidgets('Rule 1 Grounding Card renders accuracy, legal ratio, and verified URL link', (WidgetTester tester) async {
      bool checkboxTapped = false;
      final testCitation = PrecedentCitation(
        id: 'c1',
        citationId: 'AIR 2024 SC 1234',
        caseTitle: 'सत्येंद्र कुमार अंतिल बनाम सी.बी.आई.',
        courtName: 'उच्चतम न्यायालय, भारत',
        judgmentDate: '2022-07-11',
        actName: 'CrPC 1973',
        sectionNumbers: ['41A', '436'],
        headnoteHindi: 'धारा 41ए दंड प्रक्रिया संहिता के नोटिस अनुपालन पर सामान्यतः गिरफ्तारी नहीं की जानी चाहिए।',
        verbatimText: 'Arrest should not be made when section 41A notice is complied with.',
        paragraphNumber: 22,
        verifiedSourceUrl: 'https://judgments.ecourts.gov.in/antil_2022.pdf',
        similarityScore: 0.942,
        isManuallyVerified: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrecedentCitationCard(
              citation: testCitation,
              onVerificationChanged: (val) {
                checkboxTapped = val ?? false;
              },
            ),
          ),
        ),
      );

      // Verify Rule 1 & UI components
      expect(find.text('सत्येंद्र कुमार अंतिल बनाम सी.बी.आई.'), findsOneWidget);
      expect(find.text('सटीकता: 94.2%'), findsOneWidget);
      expect(find.textContaining('धारा 41ए दंड प्रक्रिया संहिता'), findsOneWidget);
      expect(find.text('सत्यापित स्रोत रिकॉर्ड देखें ↗'), findsOneWidget);
      expect(find.text('सत्यापित किया'), findsOneWidget);

      // Tap checkbox to test interaction
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(checkboxTapped, isTrue);
    });
  });
}
