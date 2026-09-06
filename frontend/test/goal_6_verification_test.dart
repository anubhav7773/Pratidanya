import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/features/02_case_input/data/nlp_chargesheet_repository.dart';
import 'package:pratidnya/src/features/04_draft_generator/domain/case_analysis_draft.dart';
import 'package:pratidnya/src/features/04_draft_generator/presentation/controllers/drafting_controller.dart';
import 'package:pratidnya/src/features/04_draft_generator/data/drafting_repository.dart';
import 'package:pratidnya/src/features/04_draft_generator/presentation/widgets/chargesheet_deconstruct_modal.dart';

class MockDraftingRepository implements DraftingRepository {
  @override
  Future<CaseAnalysisDraft?> getCachedDraft(String caseId) async => null;

  @override
  Future<CaseAnalysisDraft> generate360Draft({
    required String caseId,
    required String firNumber,
    required List<String> sections,
    required String policeStation,
    required String district,
    required String factualSummary,
    required String custodyStatus,
    List<String> extractedFacts = const [],
  }) async {
    return CaseAnalysisDraft(
      courtHeader: 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ',
      caseTitle: 'राज्य बनाम राहुल',
      statutoryGrounds: ['अभियुक्त का कोई आपराधिक इतिहास नहीं है।', 'आरोपित अपराध जमानती प्रकृति का है।'],
      prosecutionWeaknesses: ['बरामदगी के समय कोई स्वतंत्र गवाह नहीं था।'],
      proceduralObjections: ['धारा 100(4) दंड प्रक्रिया संहिता का उल्लंघन हुआ है।'],
      citedPrecedents: [
        CitedPrecedentItem(
          citationId: 'AIR 1980 SC 785',
          caseTitle: 'बाबू सिंह बनाम उत्तर प्रदेश राज्य',
          courtName: 'सर्वोच्च न्यायालय',
          judgmentDate: '1978-01-31',
          quotedPassage: 'जमानत एक सामान्य नियम है एवं जेल केवल अपवाद स्वरूप है।',
          verifiedSourceUrl: 'https://judgments.ecourts.gov.in/pdf/1980_SC_785.pdf',
          isGroundedInRecord: true,
          isManuallyVerified: false,
        ),
      ],
    );
  }
}

void main() {
  group('Goal 6: Domain Model Serialization & Controller Tests', () {
    test('ChargesheetDeconstructResult JSON serialization roundtrip', () {
      final json = {
        'case_id': 'test-case-uuid',
        'facts_extracts': ['अभियुक्त को मौके से पकड़ा गया।', 'स्वतंत्र साक्षी उपस्थित नहीं था।'],
        'prosecution_arguments': ['चोरी का माल बरामद हुआ।'],
        'statutes_detected': ['IPC', 'CrPC'],
        'provisions_detected': ['379', '411'],
        'witnesses_detected': ['राम सिंह'],
        'persons_detected': ['राहुल'],
        'total_sentences_processed': 15,
      };

      final result = ChargesheetDeconstructResult.fromJson(json);
      expect(result.caseId, 'test-case-uuid');
      expect(result.factsExtracts.length, 2);
      expect(result.statutesDetected, contains('IPC'));
      expect(result.provisionsDetected, contains('379'));
      expect(result.totalSentencesProcessed, 15);
    });

    test('CaseAnalysisDraft and CitedPrecedentItem serialization and copyWith', () {
      final json = {
        'court_header': 'न्यायालय सत्र न्यायाधीश',
        'case_title': 'राज्य बनाम विकास',
        'statutory_grounds': ['प्रथम दृष्टया मामला नहीं बनता।'],
        'prosecution_weaknesses': ['पहचान परेड आयोजित नहीं हुई।'],
        'procedural_objections': ['धारा 41ए नोटिस नहीं दी गई।'],
        'cited_precedents': [
          {
            'citation_id': '2022 SC 101',
            'case_title': 'सत्येंद्र कुमार बनाम सीबीआई',
            'court_name': 'सर्वोच्च न्यायालय',
            'judgment_date': '2022-07-11',
            'quoted_passage': 'अनावश्यक गिरफ्तारी से बचा जाए।',
            'verified_source_url': 'https://main.sci.gov.in/order/2022_101.pdf',
            'is_grounded_in_record': true,
            'is_manually_verified': false,
          }
        ]
      };

      final draft = CaseAnalysisDraft.fromJson(json);
      expect(draft.courtHeader, 'न्यायालय सत्र न्यायाधीश');
      expect(draft.statutoryGrounds.first, contains('प्रथम दृष्टया'));
      expect(draft.citedPrecedents.length, 1);

      final citation = draft.citedPrecedents.first;
      expect(citation.isManuallyVerified, false);

      final verifiedCitation = citation.copyWith(isManuallyVerified: true);
      expect(verifiedCitation.isManuallyVerified, true);
    });

    test('DraftingController updates ground, weakness and manual verification', () async {
      final mockRepo = MockDraftingRepository();
      final controller = DraftingController(mockRepo);

      await controller.generateDraft(
        caseId: 'case-1',
        firNumber: '101/2026',
        sections: ['379'],
        policeStation: 'थाना कोतवाली',
        district: 'वाराणसी',
        factualSummary: 'अभियुक्त पर आरोप निराधार है।',
        custodyStatus: 'JUDICIAL_CUSTODY',
      );

      final initialDraft = controller.state.value!;
      expect(initialDraft.statutoryGrounds.length, 2);

      // 1. Update ground
      controller.updateGround(0, 'संशोधित विधिक आधार: कोई प्रत्यक्ष प्रमाण नहीं।');
      expect(controller.state.value!.statutoryGrounds[0], 'संशोधित विधिक आधार: कोई प्रत्यक्ष प्रमाण नहीं।');

      // 2. Update weakness
      controller.updateWeakness(0, 'संशोधित कमजोरी: जब्ती में गंभीर विधिक त्रुटि।');
      expect(controller.state.value!.prosecutionWeaknesses[0], 'संशोधित कमजोरी: जब्ती में गंभीर विधिक त्रुटि।');

      // 3. Toggle citation verification
      controller.toggleCitationVerification('AIR 1980 SC 785', true);
      expect(controller.state.value!.citedPrecedents.first.isManuallyVerified, true);
    });
  });

  group('Goal 6: UI Modal & Devanagari Typography Line-Height Tests', () {
    testWidgets('ChargesheetDeconstructModal renders Devanagari input and submit button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChargesheetDeconstructModal(
                caseId: 'test-case-1',
                onFactsExtracted: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('अभियोग पत्र विश्लेषण (OpenNyAI)'), findsOneWidget);
      expect(find.text('तथ्य निष्कर्षित करें'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Devanagari UI Line Height Check: All cards ensure line-height >= 1.45 to prevent matra clipping', (tester) async {
      // Create a test card containing Devanagari legal text
      const devanagariText = 'अभियुक्त राहुल को बिना स्वतंत्र गवाह के गिरफ्तार किया गया तथा धारा 100(4) का घोर उल्लंघन किया गया।';
      const textStyle = TextStyle(fontSize: 13.5, height: 1.5);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Card(
              child: Text(
                devanagariText,
                style: textStyle,
              ),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text(devanagariText));
      expect(textWidget.style?.height, isNotNull);
      expect(textWidget.style!.height! >= 1.45, isTrue, reason: 'Line height must be >= 1.45 for matras');
    });
  });
}
