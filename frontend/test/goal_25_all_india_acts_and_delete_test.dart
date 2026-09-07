import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/core/utils/citation_formatter.dart';
import 'package:pratidnya/src/features/02_case_input/domain/criminal_case.dart';
import 'package:pratidnya/src/features/02_case_input/presentation/widgets/case_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goal 25: All-India Acts Precedents & Delete Verification', () {
    test('CitationFormatter maps all major Indian Acts landmark citations to live official URLs', () {
      final rawCitationsToTest = [
        // Arms Act
        '1972_2_SCC_194_GUNWANTLAL',
        // UP Gangsters Act
        '2022_INSC_514_SHRADDHA_GUPTA',
        // UP Excise Act
        '1967_3_SCR_281_BOOSENNA',
        // SC/ST Act
        '2020_10_SCC_710_HITESH_VERMA',
        // IT Act / Cyber Crime
        '2020_7_SCC_1_ARJUN_KHOTKAR',
        // PMLA
        '2022_INSC_929_VIJAY_MADANLAL',
        // NDPS Act
        '2014_5_SCC_345_PARMANAND',
        // UAPA
        '2021_3_SCC_713_KA_NAJEEB',
        // PC Act (Anti-Corruption)
        '2023_4_SCC_731_NEERAJ_DUTTA',
        // NI Act Sec 138
        '2019_5_SCC_418_BASALINGAPPA',
        // Cow Slaughter Act
        '2021_ALLHC_RAHIM',
        // General landmark
        '2014_AIR_SC_2756_ARNESH_KUMAR',
      ];

      for (final rawCit in rawCitationsToTest) {
        final formatted = CitationFormatter.format(rawCit);
        expect(formatted, isNotEmpty);

        final url = CitationFormatter.getOfficialPortalUrl(rawCit, null);
        expect(url, isNotNull, reason: 'URL must not be null for $rawCit');
        expect(url.startsWith('https://'), isTrue, reason: 'URL must be secure HTTPS for $rawCit');
        expect(
          url.contains('indiankanoon.org') || url.contains('digiscr.sci.gov.in') || url.contains('sci.gov.in'),
          isTrue,
          reason: 'URL must point to legitimate Indian legal portal for $rawCit: $url',
        );
      }
    });

    testWidgets('CaseCard renders properly and exposes delete menu item', (WidgetTester tester) async {
      final mockCase = CriminalCase(
        id: 'case-test-all-india-101',
        advocateId: 'adv-123',
        firNumber: '101/2026',
        policeStation: 'हजरतगंज',
        district: 'लखनऊ',
        state: 'उत्तर प्रदेश',
        courtDesignation: 'विशेष न्यायाधीश (पॉक्सो / गैंगस्टर)',
        accusedName: 'विक्रम सिंह',
        accusedCustodyStatus: 'JUDICIAL_CUSTODY',
        statuteSystem: 'BNS_BNSS',
        underSections: ['धारा 3(1) UP Gangsters Act', 'धारा 25 Arms Act', 'धारा 8/20 NDPS'],
        isArchived: false,
        createdAt: DateTime(2026, 1, 16),
        updatedAt: DateTime(2026, 1, 16),
        nextHearingDate: DateTime.now().add(const Duration(days: 3)),
        stageOfCase: 'BAIL',
      );

      bool deletedTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CaseCard(
                criminalCase: mockCase,
                onTap: () {},
                onArchive: () {},
                onDelete: () {
                  deletedTriggered = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify case details displayed
      expect(find.text('मु.अ.सं. 101/2026'), findsOneWidget);
      expect(find.text('विक्रम सिंह'), findsOneWidget);

      // Open the 3-dots popup menu
      final moreButton = find.byIcon(Icons.more_vert);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Verify the Delete Case menu item is visible
      final deleteMenuItem = find.text('केस हटाएं (Delete Case)');
      expect(deleteMenuItem, findsOneWidget);

      // Tap the delete item
      await tester.tap(deleteMenuItem);
      await tester.pumpAndSettle();

      // Verify custom onDelete callback was invoked
      expect(deletedTriggered, isTrue);
    });
  });
}
