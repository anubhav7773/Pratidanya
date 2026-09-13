import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/medico_legal_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/medico_legal_matrix_viewer.dart';

void main() {
  group('Goal 33: Medico-Legal Autopsy vs. Ocular Conflict Matrix Tests', () {
    final mockConflictMatrixJson = {
      'case_id': 'TEST-MLC-MURDER-01',
      'pmr_number': 'PMR-2024-892',
      'has_fatal_conflict': true,
      'irreconcilable_conflicts': [
        {
          'parameter': 'WEAPON_MECHANISM',
          'ocular_claim': 'PW-1 का कथन: धारदार हथियार (तलवार) द्वारा प्रहार किया गया।',
          'autopsy_finding': 'शव विच्छेदन आख्या (PMR): Lacerated wound जिसके किनारे "Irregular and contused" पाए गए।',
          'scientific_verdict_hindi': 'पूर्ण वैज्ञानिक असंभावना: तलवार से हमेशा साफ कटे किनारे आते हैं। कुचले किनारे केवल कुंद वस्तु से संभव हैं।',
          'biomechanical_authority': "Modi's Medical Jurisprudence (Mechanical Injuries)",
          'impact_on_prosecution': 'गवाह द्वारा आरोपित हथियार का झूठा होना सिद्ध करता है (राम नारायण सिंह सिद्धांत)।',
          'severity': 'FATAL_CONTRADICTION'
        }
      ],
      'cross_examination_crossfire_questions': [
        "डॉक्टर साहब, क्या यह सत्य है कि तलवार से कारित घाव के किनारे हमेशा 'Clean-cut' होते हैं?",
        "डॉक्टर साहब, चोट संख्या 1 में आपने किनारे 'Irregular and contused' दर्ज किए हैं; क्या यह केवल लाठी या कुंद वस्तु से ही आ सकते हैं?"
      ],
      'written_medical_argument_draft_hindi': 'न्यायालय श्रीमान सत्र न्यायाधीश, लखनऊ...\nबहस / विधिक तर्क बाबत प्रत्यक्षदर्शी साक्ष्य व चिकित्सकीय साक्ष्य में असमाधेय अंतर्विरोध...',
      'cited_precedents': [
        {
          'case_title': 'राम नारायण सिंह बनाम पंजाब राज्य (1975) 4 SCC 34',
          'citation': 'AIR 1975 SC 1727',
          'ratio_hindi': 'जहां चश्मदीद साक्षियों की गवाही और चिकित्सकीय साक्ष्य में पूर्ण अंतर्विरोध हो, वहां संपूर्ण अभियोजन अविश्वसनीय हो जाता है।',
          'source_url': 'https://main.sci.gov.in/judgment/judis/5231.pdf'
        }
      ]
    };

    test('MedicalMatrixAuditResult deserializes JSON accurately', () {
      final matrix = MedicalMatrixAuditResult.fromJson(mockConflictMatrixJson);

      expect(matrix.caseId, 'TEST-MLC-MURDER-01');
      expect(matrix.pmrNumber, 'PMR-2024-892');
      expect(matrix.hasFatalConflict, isTrue);
      expect(matrix.irreconcilableConflicts.length, 1);

      final conflict = matrix.irreconcilableConflicts.first;
      expect(conflict.parameter, 'WEAPON_MECHANISM');
      expect(conflict.severity, 'FATAL_CONTRADICTION');
      expect(conflict.biomechanicalAuthority, contains("Modi's"));

      expect(matrix.crossExaminationCrossfireQuestions.length, 2);
      expect(matrix.crossExaminationCrossfireQuestions.first, contains('Clean-cut'));
      expect(matrix.citedPrecedents.length, 1);
      expect(matrix.citedPrecedents.first['case_title'], contains('राम नारायण सिंह'));
    });

    testWidgets('MedicoLegalMatrixViewer renders conflict findings, questions, and opens argument modal', (tester) async {
      final matrix = MedicalMatrixAuditResult.fromJson(mockConflictMatrixJson);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MedicoLegalMatrixViewer(matrix: matrix),
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('चिकित्सीय बनाम प्रत्यक्षदर्शी साक्ष्य मैट्रिक्स'), findsOneWidget);
      expect(find.text('घातक अंतर्विरोध (Fatal Conflict)'), findsOneWidget);
      expect(find.text('पोस्टमार्टम आख्या संख्या: PMR-2024-892'), findsOneWidget);

      // Verify Conflict Parameter Chip
      expect(find.text('WEAPON_MECHANISM'), findsOneWidget);
      expect(find.textContaining('धारदार हथियार (तलवार)'), findsOneWidget);
      expect(find.textContaining('Lacerated wound'), findsOneWidget);
      expect(find.textContaining('Irregular and contused'), findsNWidgets(2));

      // Verify Crossfire Question Preview
      expect(find.textContaining('चिकित्साधिकारी हेतु लक्षित जिरह प्रश्न'), findsOneWidget);
      expect(find.textContaining('Clean-cut'), findsOneWidget);

      // Verify Action Button
      final draftButton = find.text('विधिक बहस तर्क (Argument Draft) देखें व प्रिंट करें');
      expect(draftButton, findsOneWidget);

      // Tap Button and verify bottom sheet modal
      await tester.tap(draftButton);
      await tester.pumpAndSettle();

      expect(find.text('विधिक बहस तर्क (राम नारायण सिंह सिद्धांत)'), findsOneWidget);
      expect(find.textContaining('बहस / विधिक तर्क बाबत प्रत्यक्षदर्शी साक्ष्य'), findsOneWidget);
    });
  });
}
