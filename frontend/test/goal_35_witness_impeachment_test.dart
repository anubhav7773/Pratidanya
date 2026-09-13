import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/witness_impeachment_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/witness_impeachment_grid_widget.dart';

void main() {
  group('Goal 35: Witness Contradiction & Omission Grid Tests', () {
    final mockContradictionJson = {
      'case_id': 'MURDER-TRIAL-PW2',
      'witness_code': 'PW-2',
      'witness_name': 'चंदन सिंह',
      'has_fatal_contradictions': true,
      'grid_analysis': [
        {
          'statement_segment': 'मैंने अभियुक्त रमेश को हाथ में पिस्तौल तानकर मृतक की छाती पर दो फायर करते देखा था',
          'statement_161': '[पूर्ण लोप / ABSENT IN 161 STATEMENT]',
          'statement_164': 'रमेश और सुरेश मोटरसाइकिल पर थे',
          'chief_deposition': 'मैंने अभियुक्त रमेश को हाथ में पिस्तौल तानकर मृतक की छाती पर दो फायर करते देखा था',
          'classification': 'MATERIAL_IMPROVEMENT_AMOUNTING_TO_CONTRADICTION',
          'severity': 'FATAL',
          'tahsildar_singh_applicability_hindi': 'तहसीलदार सिंह (1959): धारा 161 में यह तथ्य पूर्णतः लुप्त था।',
          'statutory_confrontation_script_hindi': 'गवाह से जिरह प्रश्न: क्या आपने पुलिस को यह महत्वपूर्ण बात बताई थी?',
          'marked_exhibit_identifier': 'Ex. D-1'
        }
      ],
      'marked_exhibits_summary': [
        {
          'exhibit_id': 'Ex. D-1',
          'passage': 'मैंने अभियुक्त रमेश को हाथ में पिस्तौल तानकर मृतक की छाती पर दो फायर करते देखा था',
          'type': 'OMISSION_IMPROVEMENT'
        }
      ],
      'io_cross_examination_reminders': [
        'अन्वेषण अधिकारी (I.O.) से: PW-2 ने धारा 161 के बयान में गोली चलाने का कथन दर्ज कराया था या नहीं?'
      ],
      'confrontation_master_script_hindi': 'न्यायालय श्रीमान अपर सत्र न्यायाधीश, लखनऊ...\nसाक्षी जिरह व अंतर्विरोध खंडन विधिक स्क्रिप्ट (Witness Impeachment Protocol)...',
      'cited_precedents': [
        {
          'case_title': 'तहसीलदार सिंह बनाम उत्तर प्रदेश राज्य (1959) Supp (2) SCR 875',
          'citation': 'AIR 1959 SC 1012',
          'ratio_hindi': 'साक्ष्य अधिनियम की धारा 145 के तहत पूर्व बयान का विशिष्ट अंश गवाह को पढ़कर सुनाना अनिवार्य है।',
          'source_url': 'https://main.sci.gov.in/judgment/judis/154.pdf'
        }
      ]
    };

    test('WitnessImpeachmentAuditResult deserializes JSON accurately', () {
      final audit = WitnessImpeachmentAuditResult.fromJson(mockContradictionJson);

      expect(audit.caseId, 'MURDER-TRIAL-PW2');
      expect(audit.witnessCode, 'PW-2');
      expect(audit.witnessName, 'चंदन सिंह');
      expect(audit.hasFatalContradictions, isTrue);
      expect(audit.gridAnalysis.length, 1);

      final item = audit.gridAnalysis.first;
      expect(item.classification, 'MATERIAL_IMPROVEMENT_AMOUNTING_TO_CONTRADICTION');
      expect(item.severity, 'FATAL');
      expect(item.markedExhibitIdentifier, 'Ex. D-1');
      expect(item.statement164, 'रमेश और सुरेश मोटरसाइकिल पर थे');

      expect(audit.ioCrossExaminationReminders.length, 1);
      expect(audit.ioCrossExaminationReminders.first, contains('अन्वेषण अधिकारी'));
      expect(audit.citedPrecedents.length, 1);
      expect(audit.citedPrecedents.first['case_title'], contains('तहसीलदार सिंह'));
    });

    testWidgets('WitnessImpeachmentGridWidget renders material improvement warnings and opens script modal', (tester) async {
      final audit = WitnessImpeachmentAuditResult.fromJson(mockContradictionJson);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WitnessImpeachmentGridWidget(audit: audit),
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('साक्षी अंतर्विरोध ग्रिड: PW-2 (चंदन सिंह)'), findsOneWidget);
      expect(find.text('गंभीर सुधार / अंतर्विरोध'), findsOneWidget);

      // Verify Exhibit ID and Classification
      expect(find.text('Ex. D-1'), findsOneWidget);
      expect(find.text('महत्वपूर्ण सुधार (Material Improvement)'), findsOneWidget);

      // Verify 161 Omission Text
      expect(find.textContaining('[पूर्ण लोप / ABSENT IN 161 STATEMENT]'), findsOneWidget);
      expect(find.textContaining('मजिस्ट्रेट बयान (164 CrPC): "रमेश और सुरेश मोटरसाइकिल पर थे"'), findsOneWidget);

      // Verify IO Reminders Box
      expect(find.textContaining('विवेचक (I.O.) से पूछने हेतु प्रदर्श साबित करने के प्रश्न:'), findsOneWidget);

      // Verify Action Button & Modal
      final scriptButton = find.text('संपूर्ण जिरह स्क्रिप्ट व प्रदर्श सूची देखें');
      expect(scriptButton, findsOneWidget);

      await tester.tap(scriptButton);
      await tester.pumpAndSettle();

      // Verify Modal Content
      expect(find.text('तहसीलदार सिंह विधिक जिरह स्क्रिप्ट'), findsOneWidget);
      expect(find.textContaining('न्यायालय श्रीमान अपर सत्र न्यायाधीश'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('WitnessImpeachmentGridWidget renders corroborating consistency state', (tester) async {
      final consistentAudit = WitnessImpeachmentAuditResult(
        caseId: 'CONSISTENT-01',
        witnessCode: 'PW-1',
        witnessName: 'रामू',
        hasFatalContradictions: false,
        gridAnalysis: [
          ContradictionGridItemModel(
            statementSegment: 'दुकान का ताला टूटा था',
            statement161: 'दुकान का ताला टूटा था',
            chiefDeposition: 'दुकान का ताला टूटा था',
            classification: 'CORROBORATING_PASSAGE',
            severity: 'TRIVIAL',
            tahsildarSinghApplicabilityHindi: 'कोई विधिक सुधार नहीं।',
            statutoryConfrontationScriptHindi: 'बयान सुसंगत हैं।',
            markedExhibitIdentifier: 'N/A',
          ),
        ],
        markedExhibitsSummary: [],
        ioCrossExaminationReminders: [],
        confrontationMasterScriptHindi: 'बयान सुसंगत हैं।',
        citedPrecedents: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WitnessImpeachmentGridWidget(audit: consistentAudit),
            ),
          ),
        ),
      );

      // Verify Consistent Badge
      expect(find.text('सुसंगत बयान'), findsOneWidget);
      expect(find.text('बयानों में कोई गंभीर सुधार अथवा अंतर्विरोध नहीं मिला।'), findsOneWidget);
    });
  });
}
