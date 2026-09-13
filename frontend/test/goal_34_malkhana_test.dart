import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/malkhana_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/malkhana_custody_timeline_card.dart';

void main() {
  group('Goal 34: Malkhana Chain of Custody & Register No. 19 Integrity Tests', () {
    final mockBrokenCustodyJson = {
      'case_id': 'NDPS-LKO-2024-44',
      'is_chain_of_custody_intact': false,
      'has_fatal_tampering_risk': true,
      'fsl_dispatch_delay_days': 34,
      'fatal_vulnerabilities': [
        {
          'issue_code': 'DELAYED_FSL_DISPATCH',
          'severity': 'FATAL_CHAIN_BREAK',
          'statutory_violation_hindi': 'एन.सी.बी. स्थायी आदेश संख्या 1/88 का घोर उल्लंघन: जब्ती के 72 घंटे के भीतर भेजना अनिवार्य था।',
          'impact_analysis_hindi': 'मालखाने में अकारण दीर्घकालिक निरुद्धि से नमूने में छेड़छाड़ की प्रबल आशंका।',
          'precedent_authority': 'NCB Standing Order 1/88 read with Noor Aga (2008)'
        },
        {
          'issue_code': 'SPECIMEN_SEAL_ABSENT',
          'severity': 'FATAL_CHAIN_BREAK',
          'statutory_violation_hindi': 'मालखाना रजिस्टर संख्या 19 में नमूना मुहर (Namuna Mohar) जमा नहीं की गई।',
          'impact_analysis_hindi': 'प्रयोगशाला में मूल सील का मिलान असंभव (गुरमैल सिंह सिद्धांत)।',
          'precedent_authority': 'State of Rajasthan v. Gurmail Singh (2005) 3 SCC 59'
        }
      ],
      'actionable_defense_strategy_hindi': 'अभिरक्षा की सुरक्षित कड़ी पूर्णतः खंडित हो चुकी है। धारा 254 BNSS के तहत तलब कराएं।',
      'application_sec_254_bnss_draft_hindi': 'न्यायालय श्रीमान विशेष न्यायाधीश (एन.डी.पी.एस. एक्ट), लखनऊ...\nप्रार्थना पत्र अंतर्गत धारा 254(2) भारतीय नागरिक सुरक्षा संहिता, 2023 बाबत तलब किए जाने मालखाना रजिस्टर संख्या 19...',
      'cross_examination_carrier_questions': [
        'मालखाना मोहर्रिर से: क्या रजिस्टर संख्या 19 में जब्ती के समय प्रयुक्त मुहर का नमूना चिपकाया गया था?',
        'कांस्टेबल वाहक से: क्या आपके पास मूल रोड सर्टिफिकेट मौजूद है?'
      ],
      'cited_precedents': [
        {
          'case_title': 'राजस्थान राज्य बनाम गुरमैल सिंह (2005) 3 SCC 59',
          'citation': 'AIR 2005 SC 1578',
          'ratio_hindi': 'यदि मालखाना रजिस्टर संख्या 19 में प्रविष्टियां अधूरी हैं, तो अभियुक्त दोषमुक्ति का अधिकारी है।',
          'source_url': 'https://main.sci.gov.in/judgment/judis/26812.pdf'
        }
      ]
    };

    test('MalkhanaAuditResult deserializes JSON accurately', () {
      final audit = MalkhanaAuditResult.fromJson(mockBrokenCustodyJson);

      expect(audit.caseId, 'NDPS-LKO-2024-44');
      expect(audit.isChainOfCustodyIntact, isFalse);
      expect(audit.hasFatalTamperingRisk, isTrue);
      expect(audit.fslDispatchDelayDays, 34);
      expect(audit.fatalVulnerabilities.length, 2);

      final v1 = audit.fatalVulnerabilities.first;
      expect(v1.issueCode, 'DELAYED_FSL_DISPATCH');
      expect(v1.severity, 'FATAL_CHAIN_BREAK');
      expect(v1.precedentAuthority, contains('Noor Aga'));

      expect(audit.crossExaminationCarrierQuestions.length, 2);
      expect(audit.citedPrecedents.length, 1);
      expect(audit.citedPrecedents.first['case_title'], contains('गुरमैल सिंह'));
    });

    testWidgets('MalkhanaCustodyTimelineCard renders broken chain warnings and opens Sec 254 modal', (tester) async {
      final audit = MalkhanaAuditResult.fromJson(mockBrokenCustodyJson);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MalkhanaCustodyTimelineCard(audit: audit),
            ),
          ),
        ),
      );

      // Verify Header Badge
      expect(find.text('मालखाना रजिस्टर 19 व FSL अभिरक्षा शृंखला'), findsOneWidget);
      expect(find.text('कड़ी खंडित (Chain Broken)'), findsOneWidget);

      // Verify Delay Metric
      expect(find.textContaining('FSL प्रेषण विलंब: 34 दिन'), findsOneWidget);

      // Verify Vulnerabilities
      expect(find.textContaining('एन.सी.बी. स्थायी आदेश संख्या 1/88'), findsOneWidget);
      expect(find.textContaining('नमूना मुहर (Namuna Mohar) जमा नहीं की गई'), findsOneWidget);

      // Verify Defense Strategy
      expect(find.textContaining('अभिरक्षा की सुरक्षित कड़ी पूर्णतः खंडित'), findsOneWidget);

      // Verify Sec 254 BNSS Action Button
      final buttonFinder = find.text('धारा 254 BNSS साक्ष्य तलब प्रार्थना पत्र देखें');
      expect(buttonFinder, findsOneWidget);

      // Tap button to open Modal
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify Modal content
      expect(find.text('धारा 254 BNSS साक्ष्य तलब प्रार्थना पत्र'), findsOneWidget);
      expect(find.textContaining('न्यायालय श्रीमान विशेष न्यायाधीश'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('MalkhanaCustodyTimelineCard renders intact custody chain badge', (tester) async {
      final intactAudit = MalkhanaAuditResult(
        caseId: 'NDPS-VALID-01',
        isChainOfCustodyIntact: true,
        hasFatalTamperingRisk: false,
        fslDispatchDelayDays: 2,
        fatalVulnerabilities: [],
        actionableDefenseStrategyHindi: 'अभिरक्षा की विधिक कड़ी प्रथम दृष्टया नियमित प्रतीत होती है।',
        applicationSec254BnssDraftHindi: '',
        crossExaminationCarrierQuestions: [],
        citedPrecedents: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MalkhanaCustodyTimelineCard(audit: intactAudit),
            ),
          ),
        ),
      );

      // Verify Intact Badge
      expect(find.text('अभिरक्षा सुरक्षित'), findsOneWidget);
      expect(find.textContaining('FSL प्रेषण विलंब: 2 दिन'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
    });
  });
}
