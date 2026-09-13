import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/undertrial_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/undertrial_relief_card.dart';

void main() {
  group('Goal 31: Section 479 BNSS / 436A CrPC Undertrial Relief Suite Tests', () {
    final mockEligibleResultJson = {
      'case_id': 'TEST-UT-479-1',
      'is_relief_applicable': true,
      'governing_statute': 'धारा 479(1) प्रथम परंतुक, भारतीय नागरिक सुरक्षा संहिता, 2023 (प्रथम अपराधी 1/3 नियम)',
      'statutory_threshold_fraction': '1/3',
      'max_prescribed_term_months': 84,
      'threshold_months': 28.0,
      'actual_detention_served_months': 29.5,
      'overstay_months': 1.5,
      'is_disqualified': false,
      'disqualification_reason': null,
      'retrospective_mandate_text_hindi': 'उच्चतम न्यायालय आदेश दि. 23.08.2024 (Re: Inhuman Conditions in 1382 Prisons): धारा 479 बी.एन.एस.एस. पूर्व प्रभाव से सभी विचाराधीन बंदियों पर लागू है।',
      'jail_superintendent_mandate_sec_479_3': 'धारा 479(3) बी.एन.एस.एस. आज्ञापक दायित्व: 1/3 अवधि पूर्ण होते ही जेल अधीक्षक का यह वैधानिक कर्तव्य है कि वह बंदी की रिहाई हेतु संबंधित न्यायालय में स्वतः लिखित आवेदन प्रस्तुत करे।',
      'court_application_draft_hindi': 'न्यायालय श्रीमान मुख्य न्यायिक मजिस्ट्रेट...\nप्रार्थना पत्र अंतर्गत धारा 479(1)...',
      'jail_superintendent_notice_draft_hindi': 'सेवा में, वरिष्ठ जेल अधीक्षक महोदय...\nविषय: धारा 479(3) बी.एन.एस.एस....',
      'cited_precedents': [
        {
          'case_title': 'इन री: 1382 जेलों में अमानवीय स्थितियां (सुप्रीम कोर्ट आदेश दि. 23.08.2024)',
          'citation': '2024 INSC 628',
          'ratio_hindi': 'धारा 479 के उदार उपबंध देश के सभी लंबित मामलों पर भूतलक्षी प्रभाव से लागू होंगे।',
          'source_url': 'https://main.sci.gov.in/judgment/judis/50891.pdf'
        }
      ]
    };

    test('UndertrialReliefAuditResult deserializes JSON accurately', () {
      final result = UndertrialReliefAuditResult.fromJson(mockEligibleResultJson);

      expect(result.caseId, 'TEST-UT-479-1');
      expect(result.isReliefApplicable, isTrue);
      expect(result.statutoryThresholdFraction, '1/3');
      expect(result.maxPrescribedTermMonths, 84);
      expect(result.thresholdMonths, 28.0);
      expect(result.actualDetentionServedMonths, 29.5);
      expect(result.overstayMonths, 1.5);
      expect(result.isDisqualified, isFalse);
      expect(result.retrospectiveMandateTextHindi, contains('23.08.2024'));
      expect(result.citedPrecedents.length, 1);
    });

    testWidgets('UndertrialReliefCard renders eligible state with dual petition buttons', (tester) async {
      final result = UndertrialReliefAuditResult.fromJson(mockEligibleResultJson);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UndertrialReliefCard(result: result),
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('धारा 479 BNSS विचाराधीन राहत'), findsOneWidget);

      // Verify Badge
      expect(find.text('रिहाई योग्य (1/3 पूर्ण)'), findsOneWidget);

      // Verify Stats & Overstay
      expect(find.textContaining('वास्तविक अभिरक्षा: 29.5 माह'), findsOneWidget);
      expect(find.textContaining('सांविधिक सीमा से अधिक निरुद्धि (Overstay): 1.5 माह'), findsOneWidget);

      // Verify Retrospective Supreme Court Badge
      expect(find.textContaining('23.08.2024'), findsOneWidget);

      // Verify Buttons
      final courtBtn = find.text('न्यायालय प्रार्थना पत्र');
      final jailBtn = find.text('जेल अधीक्षक नोटिस');
      expect(courtBtn, findsOneWidget);
      expect(jailBtn, findsOneWidget);

      // Tap Court Application Button and verify Modal
      await tester.tap(courtBtn);
      await tester.pumpAndSettle();

      expect(find.text('न्यायालय जमानत प्रार्थना पत्र (धारा 479 BNSS)'), findsOneWidget);
      expect(find.textContaining('प्रार्थना पत्र अंतर्गत धारा 479(1)'), findsOneWidget);
    });

    testWidgets('UndertrialReliefCard renders disqualified state with reason', (tester) async {
      final disqualifiedJson = Map<String, dynamic>.from(mockEligibleResultJson);
      disqualifiedJson['is_relief_applicable'] = false;
      disqualifiedJson['is_disqualified'] = true;
      disqualifiedJson['disqualification_reason'] = 'धारा 479(2) सांविधिक रोक: बंदी के विरुद्ध एक से अधिक मामलों में विचारण लंबित है।';
      disqualifiedJson['overstay_months'] = 0.0;

      final result = UndertrialReliefAuditResult.fromJson(disqualifiedJson);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UndertrialReliefCard(result: result),
            ),
          ),
        ),
      );

      expect(find.text('अपात्र (Disqualified)'), findsOneWidget);
      expect(find.textContaining('धारा 479(2) सांविधिक रोक'), findsOneWidget);
    });
  });
}
