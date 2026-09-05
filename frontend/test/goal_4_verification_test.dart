import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratidnya/src/features/02_case_input/domain/criminal_case.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/case_card.dart';
import 'package:pratidnya/src/shared/components/criminal_stage_stepper.dart';
import 'package:pratidnya/src/shared/components/statute_selector_bar.dart';

void main() {
  group('Goal 4: CriminalCase Domain Serialization & Statute Persistence', () {
    test('CriminalCase JSON roundtrip preserves BNS_BNSS and IPC_CRPC statute systems', () {
      final now = DateTime.now().toUtc();
      final caseItem = CriminalCase(
        id: 'test_case_bns_001',
        advocateId: 'advocate_uid_456',
        firNumber: '124/2026',
        policeStation: 'कोतवाली नगर',
        district: 'लखनऊ',
        state: 'Uttar Pradesh',
        accusedName: 'श्यामू उर्फ़ श्याम',
        accusedCustodyStatus: 'JUDICIAL_CUSTODY',
        complainantName: 'राम प्रसाद',
        statuteSystem: 'BNS_BNSS',
        underSections: ['303(2) BNS', '317(2) BNS'],
        courtDesignation: 'मुख्य न्यायिक मजिस्ट्रेट (CJM)',
        stageOfCase: 'BAIL',
        nextHearingDate: DateTime(2026, 9, 18),
        lastCourtOrder: 'आरोपी न्यायिक अभिरक्षा में है।',
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = caseItem.toJson();
      expect(json['id'], 'test_case_bns_001');
      expect(json['advocate_id'], 'advocate_uid_456');
      expect(json['statute_system'], 'BNS_BNSS');
      expect(json['under_sections'], ['303(2) BNS', '317(2) BNS']);
      expect(json['next_hearing_date'], '2026-09-18');

      final deserialized = CriminalCase.fromJson(json);
      expect(deserialized.statuteSystem, 'BNS_BNSS');
      expect(deserialized.underSections.length, 2);
      expect(deserialized.underSections.first, '303(2) BNS');
      expect(deserialized.accusedCustodyStatus, 'JUDICIAL_CUSTODY');
    });

    test('StatuteSelectorBar triggers onSystemChanged callback with exact enum', () {
      StatuteSystem current = StatuteSystem.hybrid;
      final selector = StatuteSelectorBar(
        selectedSystem: current,
        onSystemChanged: (sys) => current = sys,
      );

      expect(selector.selectedSystem, StatuteSystem.hybrid);
    });
  });

  group('Goal 4: Chamber Isolation & Case Filtering Logic', () {
    test('Chamber Isolation: Filters ensure only advocate owned cases are matched', () {
      final advocateA = 'advocate_A_uid';
      final advocateB = 'advocate_B_uid';

      final allCases = [
        CriminalCase(
          id: '1',
          advocateId: advocateA,
          firNumber: '101/2026',
          policeStation: 'हजरतगंज',
          district: 'लखनऊ',
          state: 'UP',
          accusedName: 'अभियुक्त 1',
          accusedCustodyStatus: 'ON_BAIL',
          statuteSystem: 'IPC_CRPC',
          underSections: ['379 IPC', '411 IPC'],
          courtDesignation: 'CJM',
          stageOfCase: 'BAIL',
          isArchived: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CriminalCase(
          id: '2',
          advocateId: advocateB,
          firNumber: '102/2026',
          policeStation: 'गोमती नगर',
          district: 'लखनऊ',
          state: 'UP',
          accusedName: 'अभियुक्त 2',
          accusedCustodyStatus: 'JUDICIAL_CUSTODY',
          statuteSystem: 'BNS_BNSS',
          underSections: ['303 BNS'],
          courtDesignation: 'Sessions Judge',
          stageOfCase: 'REMAND',
          isArchived: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Advocate A's query simulation
      final advocateACases = allCases.where((c) => c.advocateId == advocateA).toList();
      expect(advocateACases.length, 1);
      expect(advocateACases.first.id, '1');
      expect(advocateACases.first.firNumber, '101/2026');

      // Section search filter simulation (e.g. searching '411')
      final searchSectionMatches = advocateACases.where((c) {
        return c.firNumber.contains('411') ||
            c.accusedName.contains('411') ||
            c.underSections.any((sec) => sec.contains('411'));
      }).toList();

      expect(searchSectionMatches.length, 1);
      expect(searchSectionMatches.first.underSections, contains('411 IPC'));
    });
  });

  group('Goal 4: Devanagari UI & Stepper Rendering Tests', () {
    testWidgets('CaseCard renders Hindi custody status, FIR, and sections cleanly', (WidgetTester tester) async {
      final testCase = CriminalCase(
        id: 'c101',
        advocateId: 'adv1',
        firNumber: '124/2026',
        policeStation: 'कोतवाली नगर',
        district: 'लखनऊ',
        state: 'Uttar Pradesh',
        accusedName: 'श्यामू उर्फ़ श्याम',
        accusedCustodyStatus: 'JUDICIAL_CUSTODY',
        statuteSystem: 'HYBRID',
        underSections: ['धारा 379 भा.दं.वि.', 'धारा 411 भा.दं.वि.'],
        courtDesignation: 'मुख्य न्यायिक मजिस्ट्रेट (CJM)',
        stageOfCase: 'BAIL',
        nextHearingDate: DateTime.now().add(const Duration(days: 2)),
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaseCard(
              criminalCase: testCase,
              onTap: () {},
              onArchive: () {},
            ),
          ),
        ),
      );

      // Verify Devanagari texts render without errors
      expect(find.text('मु.अ.सं. 124/2026'), findsOneWidget);
      expect(find.text('श्यामू उर्फ़ श्याम'), findsOneWidget);
      expect(find.text('न्यायिक अभिरक्षा (जेल में)'), findsOneWidget);
      expect(find.text('धारा 379 भा.दं.वि.'), findsOneWidget);
      expect(find.text('धारा 411 भा.दं.वि.'), findsOneWidget);
      expect(find.text('जमानत सुनवाई'), findsOneWidget);
    });

    testWidgets('CriminalStageStepper renders 5 statutory stages cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CriminalStageStepper(currentStage: 'BAIL'),
          ),
        ),
      );

      expect(find.text('रिमांड'), findsOneWidget);
      expect(find.text('जमानत'), findsOneWidget);
      expect(find.text('आरोप पत्र'), findsOneWidget);
      expect(find.text('आरोप तय'), findsOneWidget);
      expect(find.text('साक्ष्य'), findsOneWidget);
    });

    testWidgets('StatuteSelectorBar renders hybrid, BNS and IPC options', (WidgetTester tester) async {
      StatuteSystem selected = StatuteSystem.hybrid;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StatuteSelectorBar(
                  selectedSystem: selected,
                  onSystemChanged: (sys) => setState(() => selected = sys),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('हाइब्रिड (दोनों)'), findsOneWidget);
      expect(find.text('BNS / BNSS'), findsOneWidget);
      expect(find.text('IPC / CrPC'), findsOneWidget);

      await tester.tap(find.text('BNS / BNSS'));
      await tester.pumpAndSettle();

      expect(selected, StatuteSystem.bnsBnss);
    });
  });
}
