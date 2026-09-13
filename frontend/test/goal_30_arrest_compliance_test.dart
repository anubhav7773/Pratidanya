import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/arrest_compliance_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/screens/remand_compliance_checklist_screen.dart';

void main() {
  group('Goal 30: Arrest and Remand Procedural Compliance Auditor Tests', () {
    final mockAuditResultJson = {
      'case_id': 'TEST-ARREST-AUDIT-35',
      'antil_category': 'CATEGORY_A',
      'compliance_verdict': 'NON_COMPLIANT_VOID_ARREST',
      'hours_to_production': 18.5,
      'is_constitutionally_time_barred': false,
      'violations': [
        {
          'statutory_provision': 'धारा 35(3) बी.एन.एस.एस. / धारा 41A दं.प्र.सं.',
          'governing_doctrine': 'अर्नेश कुमार बनाम बिहार राज्य (2014)',
          'severity': 'FATAL',
          'finding_hindi': '7 वर्ष से कम दंडनीय अपराध में पुलिस द्वारा गिरफ्तारी से पूर्व धारा 35(3) बी.एन.एस.एस. का कोई वैधानिक नोटिस नहीं दिया गया।',
          'actionable_remedy': 'यांत्रिक गिरफ्तारी को अवैध घोषित करते हुए सतेन्द्र कुमार अंतिल दिशानिर्देश श्रेणी "क" के तहत व्यक्तिगत बंधपत्र पर रिहाई।'
        },
        {
          'statutory_provision': 'धारा 36 बी.एन.एस.एस. / धारा 41B दं.प्र.सं.',
          'governing_doctrine': 'डी.के. बासु गिरफ्तारी प्रक्रिया',
          'severity': 'MATERIAL',
          'finding_hindi': 'गिरफ्तारी मेमो पर किसी भी स्वतंत्र स्थानीय साक्षी अथवा अभियुक्त के परिजन के हस्ताक्षर मौजूद नहीं हैं।',
          'actionable_remedy': 'गिरफ्तारी पंचनामा के दोषपूर्ण होने के आधार पर रिमांड का विरोध।'
        }
      ],
      'magistrate_directive_recommendation': 'विद्वान मजिस्ट्रेट द्वारा पुलिस रिमांड आवेदन को निरस्त किया जाए तथा अभियुक्त को व्यक्तिगत बंधपत्र पर तत्काल रिहा किया जाए।',
      'instant_objection_petition_draft': 'न्यायालय श्रीमान मुख्य न्यायिक मजिस्ट्रेट...\nआपत्ति विरुद्ध पुलिस रिमांड प्रार्थना पत्र...',
      'cited_precedents': [
        {
          'case_title': 'अर्नेश कुमार बनाम बिहार राज्य (2014) 8 SCC 273',
          'citation': 'AIR 2014 SC 2756',
          'ratio_hindi': '7 वर्ष तक के कारावास वाले सभी मामलों में धारा 41A नोटिस अनिवार्य है।',
          'source_url': 'https://main.sci.gov.in/judgment/judis/41731.pdf'
        }
      ]
    };

    test('ArrestComplianceAuditResult deserializes JSON accurately', () {
      final result = ArrestComplianceAuditResult.fromJson(mockAuditResultJson);

      expect(result.caseId, 'TEST-ARREST-AUDIT-35');
      expect(result.antilCategory, 'CATEGORY_A');
      expect(result.complianceVerdict, 'NON_COMPLIANT_VOID_ARREST');
      expect(result.hoursToProduction, 18.5);
      expect(result.isConstitutionallyTimeBarred, isFalse);
      expect(result.violations.length, 2);

      final fatalViolation = result.violations.first;
      expect(fatalViolation.severity, 'FATAL');
      expect(fatalViolation.statutoryProvision, contains('35(3)'));
      expect(fatalViolation.governingDoctrine, contains('अर्नेश कुमार'));

      expect(result.citedPrecedents.length, 1);
      expect(result.citedPrecedents.first['citation'], 'AIR 2014 SC 2756');
    });

    testWidgets('RemandComplianceChecklistScreen renders checklist checkpoints and interacts', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RemandComplianceChecklistScreen(
              caseId: 'CASE-001',
              accusedName: 'रमेश कुमार',
              policeStation: 'हजरतगंज',
              district: 'लखनऊ',
            ),
          ),
        ),
      );

      // Verify Screen Header
      expect(find.text('गिरफ्तारी व रिमांड अनुपालन परीक्षक'), findsOneWidget);

      // Verify BCI Disclaimer
      expect(find.textContaining('विधिक अस्वीकरण (BCI नियम 5)'), findsOneWidget);

      // Verify Antil / Arnesh Checklist Title
      expect(find.textContaining('सतेन्द्र कुमार अंतिल व अर्नेश कुमार प्रक्रियात्मक चेकलिस्ट'), findsOneWidget);

      // Verify Checkpoints
      expect(find.textContaining('क्या धारा 35(3) BNSS / 41A CrPC का नोटिस दिया गया था?'), findsOneWidget);
      expect(find.textContaining('क्या केस डायरी में फरार होने/साक्ष्य मिटाने के ठोस कारण दर्ज हैं?'), findsOneWidget);
      expect(find.textContaining('गिरफ्तारी मेमो पर कम से कम एक स्वतंत्र स्थानीय साक्षी के हस्ताक्षर हैं?'), findsOneWidget);
      expect(find.textContaining('क्या परिजन/नामित व्यक्ति को गिरफ्तारी की लिखित सूचना दी गई?'), findsOneWidget);
      expect(find.textContaining('क्या अभियुक्त का विहित चिकित्सीय परीक्षण (Medical) कराया गया?'), findsOneWidget);
      expect(find.textContaining('क्या मजिस्ट्रेट ने स्वतंत्र संतुष्टि व कारण दर्ज किए हैं?'), findsOneWidget);

      // Verify Audit Button
      expect(find.text('प्रक्रियात्मक वैधता जांचें व आपत्ति बनाएं'), findsOneWidget);

      // Toggle first checkbox
      final checkboxFinder = find.byType(Checkbox).first;
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final checkboxWidget = tester.widget<Checkbox>(checkboxFinder);
      expect(checkboxWidget.value, isTrue);
    });
  });
}
