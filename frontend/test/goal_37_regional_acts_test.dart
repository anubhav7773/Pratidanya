import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/features/02_case_input/domain/regional_acts_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/regional_acts_audit_screen.dart';

void main() {
  group('Goal 37: UP Gangsters Rules 2021 & Goondas Act Defense Suite Tests', () {
    final mockGangstersResultJson = {
      'case_id': 'GANG-LKO-2024-01',
      'statute_applied': 'UP_GANGSTERS_ACT_1986',
      'procedural_viability': 'FATALLY_DEFECTIVE_CHALLENGEABLE',
      'is_farhana_collapse_triggered': true,
      'is_ramji_pandey_defect_triggered': false,
      'grounds_of_challenge': [
        {
          'doctrine': 'नियम 5(3)(a) उत्तर प्रदेश गिरोहबंद नियमावली 2021',
          'rule_or_statute': 'Rule 5(3)(a) UP Gangsters Rules 2021',
          'severity': 'JURISDICTIONAL_FATALITY',
          'argument_hindi': 'गैंग चार्ट के अनुमोदन से पूर्व DM व SSP की संयुक्त बैठक दर्ज नहीं है।',
          'statutory_remedy': 'अनुच्छेद 226 के तहत रिट याचिका में चुनौती देना।'
        },
        {
          'doctrine': 'फरहाना बनाम उत्तर प्रदेश राज्य (2024) सिद्धांत',
          'rule_or_statute': 'Section 2/3 UP Gangsters Act 1986',
          'severity': 'SUBSTANTIVE_FATALITY',
          'argument_hindi': 'सभी आधारभूत मुकदमों में अभियुक्त बरी हो चुका है।',
          'statutory_remedy': 'उच्च न्यायालय से एफ.आई.आर. निरस्त कराना।'
        }
      ],
      'recommended_forum': 'माननीय उच्च न्यायालय, इलाहाबाद (लखनऊ खंडपीठ)',
      'draft_petition_type': 'WRIT_CRIMINAL_ARTICLE_226_QUASHING_GANG_CHART',
      'draft_petition_hindi': 'माननीय उच्च न्यायालय, इलाहाबाद, लखनऊ खंडपीठ...\nदांडिक प्रकीर्ण रिट याचिका (अंतर्गत अनुच्छेद 226)...',
      'cited_precedents': [
        {
          'case_title': 'फरहाना बनाम उत्तर प्रदेश राज्य (2024) 4 SCC 685',
          'citation': '2024 INSC 121',
          'ratio_hindi': 'आधारभूत मुकदमों के अभाव में गैंगस्टर एक्ट की कार्यवाही शून्य है।',
          'source_url': 'https://main.sci.gov.in/judgment/judis/50412.pdf'
        }
      ]
    };

    test('RegionalActsAuditResult deserializes JSON accurately', () {
      final result = RegionalActsAuditResult.fromJson(mockGangstersResultJson);

      expect(result.caseId, 'GANG-LKO-2024-01');
      expect(result.statuteApplied, 'UP_GANGSTERS_ACT_1986');
      expect(result.proceduralViability, 'FATALLY_DEFECTIVE_CHALLENGEABLE');
      expect(result.isFarhanaCollapseTriggered, isTrue);
      expect(result.isRamjiPandeyDefectTriggered, isFalse);
      expect(result.groundsOfChallenge.length, 2);

      final g1 = result.groundsOfChallenge.first;
      expect(g1.ruleOrStatute, contains('Rule 5(3)(a)'));
      expect(g1.severity, 'JURISDICTIONAL_FATALITY');

      final g2 = result.groundsOfChallenge[1];
      expect(g2.doctrine, contains('फरहाना'));
      expect(g2.severity, 'SUBSTANTIVE_FATALITY');

      expect(result.citedPrecedents.length, 1);
      expect(result.citedPrecedents.first['case_title'], contains('फरहाना'));
    });

    testWidgets('RegionalActsAuditScreen renders inputs, checkboxes, and adds predicate case', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegionalActsAuditScreen(
              caseId: 'CASE-REGIONAL-001',
              accusedName: 'सुनील यादव',
              policeStation: 'हजरतगंज',
              district: 'लखनऊ',
            ),
          ),
        ),
      );

      // Verify Header & BCI banner
      expect(find.text('उ.प्र. प्रादेशिक विशेष अधिनियम परीक्षक'), findsOneWidget);
      expect(find.textContaining('विधिक अस्वीकरण (BCI नियम 5)'), findsOneWidget);

      // Verify Gangsters Act Form controls
      expect(find.text('क्या नियम 5(3)(a) की संयुक्त बैठक (DM & SSP) दर्ज है?'), findsOneWidget);
      expect(find.text('क्या जिला मजिस्ट्रेट ने स्वतंत्र संतुष्टि दर्ज की है?'), findsOneWidget);
      expect(find.text('आधारभूत मुकदमे (Predicate Base Cases):'), findsOneWidget);
      expect(find.textContaining('मु.अ.सं. 112/2021'), findsOneWidget);

      // Add Predicate Case Button
      final addCaseButton = find.text('मुकदमा जोड़ें');
      expect(addCaseButton, findsOneWidget);

      await tester.ensureVisible(addCaseButton);
      await tester.tap(addCaseButton);
      await tester.pumpAndSettle();

      // Verify new case added
      expect(find.textContaining('मु.अ.सं. 101/2022'), findsOneWidget);

      // Verify Audit Button
      expect(find.text('प्रशासनिक वैधता जांचें व रिट तैयार करें'), findsOneWidget);
    });
  });
}
