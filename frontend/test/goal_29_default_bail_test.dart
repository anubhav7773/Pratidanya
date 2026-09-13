import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/default_bail_models.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/default_bail_tracker_card.dart';

void main() {
  group('Goal 29: Section 167(2) CrPC / Section 187 BNSS Default Bail Tracker Tests', () {
    final mockAuditJson = {
      'case_id': 'TEST-CR-101/2026',
      'statutory_threshold_days': 90,
      'days_elapsed_in_custody': 92,
      'is_default_bail_crystallized': true,
      'default_bail_accrual_timestamp': '2026-09-10T12:00:00Z',
      'hours_until_default_bail': 0.0,
      'police_custody_days_used': 10,
      'police_custody_days_remaining': 5,
      'police_custody_window_expired': true,
      'police_custody_alert_hindi': 'धारा 187(3) बी.एन.एस.एस. पुलिस कस्टडी की वैधानिक समय-सीमा समाप्त: प्रथम 60 दिन बीत चुके हैं।',
      'is_chargesheet_incomplete': true,
      'defect_type': 'SUBTERFUGE_INCOMPLETE_CHARGESHEET',
      'missing_mandatory_reports': ['FSL_CHEMICAL_EXAMINER_REPORT'],
      'chargesheet_defect_summary_hindi': 'आरोप-पत्र में अनिवार्य वैज्ञानिक साक्ष्य (FSL_CHEMICAL_EXAMINER_REPORT) नदारद हैं।',
      'statutory_petition_draft_hindi': 'न्यायालय श्रीमान मुख्य न्यायिक मजिस्ट्रेट, लखनऊ\nप्रार्थना पत्र अंतर्गत धारा 187(3)...',
      'cited_precedents': [
        {
          'case_title': 'बिक्रमजीत सिंह बनाम पंजाब राज्य (2020) 10 SCC 616',
          'citation': 'AIR 2020 SC 4924',
          'legal_ratio_hindi': 'सांविधिक डिफ़ॉल्ट जमानत का अधिकार अनुच्छेद 21 के तहत मौलिक अधिकार है।',
          'verified_url': 'https://main.sci.gov.in/judgment/judis/47746.pdf',
        },
      ],
    };

    test('DefaultBailAuditResult deserializes JSON accurately', () {
      final audit = DefaultBailAuditResult.fromJson(mockAuditJson);

      expect(audit.caseId, 'TEST-CR-101/2026');
      expect(audit.statutoryThresholdDays, 90);
      expect(audit.daysElapsedInCustody, 92);
      expect(audit.isDefaultBailCrystallized, isTrue);
      expect(audit.policeCustodyWindowExpired, isTrue);
      expect(audit.isChargesheetIncomplete, isTrue);
      expect(audit.defectType, 'SUBTERFUGE_INCOMPLETE_CHARGESHEET');
      expect(audit.missingMandatoryReports, contains('FSL_CHEMICAL_EXAMINER_REPORT'));
      expect(audit.citedPrecedents.length, 1);
      expect(audit.citedPrecedents.first.caseTitle, contains('बिक्रमजीत सिंह'));
    });

    testWidgets('DefaultBailTrackerCard renders crystallized state and triggers callback', (tester) async {
      final audit = DefaultBailAuditResult.fromJson(mockAuditJson);
      bool callbackFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultBailTrackerCard(
              audit: audit,
              onOpenPetitionViewer: () {
                callbackFired = true;
              },
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('सांविधिक डिफ़ॉल्ट जमानत ट्रैकर'), findsOneWidget);
      expect(find.text('अधिकार प्रोद्भूत (Eligible)'), findsOneWidget);

      // Verify Section 187 PC Alert
      expect(find.textContaining('धारा 187(3) बी.एन.एस.एस.'), findsOneWidget);

      // Verify Incomplete Chargesheet alert
      expect(find.textContaining('FSL_CHEMICAL_EXAMINER_REPORT'), findsOneWidget);

      // Verify button label
      final actionButton = find.text('डिफ़ॉल्ट जमानत प्रार्थना पत्र देखें व प्रिंट करें');
      expect(actionButton, findsOneWidget);

      // Tap action button and verify callback
      await tester.tap(actionButton);
      await tester.pump();
      expect(callbackFired, isTrue);
    });

    testWidgets('DefaultBailTrackerCard renders ongoing non-crystallized state', (tester) async {
      final ongoingJson = Map<String, dynamic>.from(mockAuditJson);
      ongoingJson['days_elapsed_in_custody'] = 45;
      ongoingJson['is_default_bail_crystallized'] = false;
      ongoingJson['is_chargesheet_incomplete'] = false;
      ongoingJson['police_custody_window_expired'] = false;
      ongoingJson['police_custody_alert_hindi'] = 'धारा 187 बी.एन.एस.एस.: पुलिस कस्टडी के 5 दिन शेष हैं।';

      final audit = DefaultBailAuditResult.fromJson(ongoingJson);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultBailTrackerCard(
              audit: audit,
              onOpenPetitionViewer: () {},
            ),
          ),
        ),
      );

      expect(find.text('45/90 दिन'), findsOneWidget);
      expect(find.text('सांविधिक विधिक ड्राफ्ट का पूर्वावलोकन'), findsOneWidget);
      expect(find.textContaining('5 दिन शेष हैं'), findsOneWidget);
    });
  });
}
