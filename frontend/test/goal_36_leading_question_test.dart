import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/leading_question_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/cross_exam_card_deck_widget.dart';

void main() {
  group('Goal 36: Hostile Witness & Leading Question Tree Generator Tests', () {
    final mockQuestionResultJson = {
      'case_id': 'ARMS-ACT-CASE-101',
      'witness_name': 'राम लखन (जब्ती गवाह)',
      'defense_theory': 'PLANTED_RECOVERY_STOCK_WITNESS',
      'questionnaire_strategy_hindi': 'स्टॉक साक्षी का संबंध व अनन्य आधिपत्य का अभाव सिद्ध करना।',
      'question_trees': [
        {
          'step_number': 1,
          'objective_hindi': 'दूरी स्थापित करना',
          'leading_question_hindi': 'क्या यह सही है कि आपका स्थायी निवास बरामदगी स्थल से 14 किलोमीटर दूर है?',
          'expected_answer': 'YES',
          'trap_mitigation_hindi': 'यदि गवाह कहे कि निजी कार्य से आया था, तो बिल मांगें।',
          'pivot_tactic_hindi': 'आधार कार्ड से दूरी सिद्ध कराएं।',
          'statutory_basis': 'धारा 147 बी.एस.ए.'
        },
        {
          'step_number': 2,
          'objective_hindi': 'स्टॉक साक्षी सिद्ध करना',
          'leading_question_hindi': 'क्या यह सत्य है कि आप पहले भी पुलिस के गवाह रह चुके हैं?',
          'expected_answer': 'NO',
          'trap_mitigation_hindi': 'पुराने मुकदमों के अपराध संख्या दर्ज कराएं।',
          'pivot_tactic_hindi': 'पूर्व जब्ती पंचनामों की प्रमाणित प्रतियों (Ex. D-12) से सामना कराएं।',
          'statutory_basis': 'धारा 148 बी.एस.ए.'
        }
      ],
      'trial_tactics_summary_hindi': 'गवाह से केवल वही प्रश्न पूछें जिनका उत्तर हाँ या ना में बाध्यकारी हो।',
      'cited_precedents': [
        {
          'case_title': 'सत पाल बनाम दिल्ली प्रशासन (1976) 1 SCC 727',
          'citation': 'AIR 1976 SC 294',
          'ratio_hindi': 'पक्षद्रोही घोषित गवाह से निकाले गए अनुकूल कथन ग्राह्य हैं।',
          'source_url': 'https://main.sci.gov.in/judgment/judis/5412.pdf'
        }
      ]
    };

    test('LeadingQuestionResult deserializes JSON accurately', () {
      final result = LeadingQuestionResult.fromJson(mockQuestionResultJson);

      expect(result.caseId, 'ARMS-ACT-CASE-101');
      expect(result.witnessName, 'राम लखन (जब्ती गवाह)');
      expect(result.defenseTheory, 'PLANTED_RECOVERY_STOCK_WITNESS');
      expect(result.questionTrees.length, 2);

      final q1 = result.questionTrees[0];
      expect(q1.stepNumber, 1);
      expect(q1.expectedAnswer, 'YES');
      expect(q1.leadingQuestionHindi, contains('14 किलोमीटर'));

      final q2 = result.questionTrees[1];
      expect(q2.expectedAnswer, 'NO');
      expect(q2.pivotTacticHindi, contains('Ex. D-12'));
      expect(result.citedPrecedents.length, 1);
      expect(result.citedPrecedents.first['case_title'], contains('सत पाल'));
    });

    testWidgets('CrossExamCardDeckWidget renders step 1, navigates to step 2 and back', (tester) async {
      final result = LeadingQuestionResult.fromJson(mockQuestionResultJson);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrossExamCardDeckWidget(result: result),
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('साक्षी: राम लखन (जब्ती गवाह)'), findsOneWidget);
      expect(find.text('प्रश्न 1 / 2'), findsOneWidget);

      // Verify Step 1 Question Content
      expect(find.textContaining('14 किलोमीटर दूर है'), findsOneWidget);
      expect(find.text('YES'), findsOneWidget);
      expect(find.textContaining('यदि गवाह कहे कि निजी कार्य से आया था'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);

      // Navigate to Next Step
      final nextButton = find.text('अगला प्रश्न');
      expect(nextButton, findsOneWidget);

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Verify Step 2 Question Content
      expect(find.text('प्रश्न 2 / 2'), findsOneWidget);
      expect(find.textContaining('पहले भी पुलिस के गवाह रह चुके हैं'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);
      expect(find.textContaining('Ex. D-12'), findsOneWidget);

      // Navigate Back to Step 1
      final prevButton = find.text('पिछला प्रश्न');
      expect(prevButton, findsOneWidget);

      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      expect(find.text('प्रश्न 1 / 2'), findsOneWidget);
      expect(find.textContaining('14 किलोमीटर दूर है'), findsOneWidget);
    });
  });
}
