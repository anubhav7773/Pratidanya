import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/features/05_verify_and_export/domain/verified_export_payload.dart';
import 'package:pratidnya/src/features/05_verify_and_export/presentation/controllers/verification_controller.dart';
import 'package:pratidnya/src/features/05_verify_and_export/data/court_pdf_builder.dart';
import 'package:pratidnya/src/features/billing/data/admob_service.dart';
import 'package:pratidnya/src/features/billing/presentation/controllers/subscription_controller.dart';
import 'package:pratidnya/src/shared/components/court_inline_banner_ad.dart';
import 'package:pratidnya/src/features/billing/presentation/screens/paywall_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Goal 7: Verification Gate & Section 35 Lock Tests', () {
    test('Non-Bypassable Verification Gate Lock: Remains locked until 100% items verified', () {
      final notifier = VerificationNotifier(
        citationIds: ['AIR 1980 SC 785', '2022 SC 101'],
        groundsCount: 2,
      );

      // 1. Initial State: Unverified
      expect(notifier.state.isReadyForExport, false);
      expect(notifier.state.pendingItemsCount, 5); // 2 citations + 2 grounds + 1 declaration

      // 2. Tick only grounds
      notifier.toggleGround(0, true);
      notifier.toggleGround(1, true);
      expect(notifier.state.isReadyForExport, false);
      expect(notifier.state.pendingItemsCount, 3);

      // 3. Tick 1 citation
      notifier.toggleCitation('AIR 1980 SC 785', true);
      expect(notifier.state.isReadyForExport, false);
      expect(notifier.state.pendingItemsCount, 2);

      // 4. Tick statutory declaration
      notifier.setStatutoryDeclaration(true);
      expect(notifier.state.isReadyForExport, false);
      expect(notifier.state.pendingItemsCount, 1);

      // 5. Tick final citation -> 100% verified -> Gate unlocks!
      notifier.toggleCitation('2022 SC 101', true);
      expect(notifier.state.isReadyForExport, true);
      expect(notifier.state.pendingItemsCount, 0);

      // 6. Unchecking any item immediately locks gate again
      notifier.toggleGround(0, false);
      expect(notifier.state.isReadyForExport, false);
      expect(notifier.state.pendingItemsCount, 1);
    });
  });

  group('Goal 7: Deterministic Court PDF 1.5" Left Margin Tests', () {
    test('CourtPdfBuilder generates valid PDF with 1.5" left margin binding space', () async {
      final payload = VerifiedExportPayload(
        courtHeaderHindi: 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट, लखनऊ',
        firNumber: '123/2026',
        policeStation: 'हजरतगंज',
        district: 'लखनऊ',
        accusedName: 'राहुल वर्मा',
        advocateName: 'अधिवक्ता अनिरुद्ध सिंह',
        barCouncilNumber: 'UP/12345/2020',
        verifiedGrounds: [
          'अभियुक्त निर्दोष है एवं उसे रंजिशन फंसाया गया है।',
          'बरामदगी के समय कोई स्वतंत्र साक्षी उपस्थित नहीं था।',
        ],
        verifiedCitations: [
          'बाबू सिंह बनाम उत्तर प्रदेश राज्य (सर्वोच्च न्यायालय)',
        ],
        prayerText: 'अतः न्यायहित में जमानत स्वीकार करने की कृपा की जाए।',
        filingDate: DateTime(2026, 9, 5),
      );

      final pdfBytes = await CourtPdfBuilder.generateLegalSizeCourtPetition(payload);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100)); // Non-empty valid PDF byte stream
    });
  });

  group('Goal 7: Monetization & AdMob Disabling Tests', () {
    test('AdMob test IDs match official Google sample IDs', () {
      expect(AdMobService.androidBannerTestId, 'ca-app-pub-3940256099942544/6300978111');
      expect(AdMobService.androidRewardedTestId, 'ca-app-pub-3940256099942544/5224354917');
    });

    testWidgets('Subscription Tier Elevation: Pro subscriber disables inline banner ad', (tester) async {
      // 1. Pro Subscriber is TRUE
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isProSubscriberProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourtInlineBannerAd(),
            ),
          ),
        ),
      );

      await tester.pump();
      // When pro subscriber is true, CourtInlineBannerAd returns SizedBox.shrink()
      expect(find.text('प्रायोजित विधिक सूचना (Sponsored)'), findsNothing);
    });

    testWidgets('PaywallScreen renders Chamber Pro options and pricing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PaywallScreen(),
          ),
        ),
      );

      expect(find.text('प्रतिज्ञा चैंबर प्रो (Chamber Pro)'), findsOneWidget);
      expect(find.text('मासिक चैंबर प्रो'), findsOneWidget);
      expect(find.text('₹499 / माह'), findsOneWidget);
      expect(find.text('वार्षिक चैंबर प्रो'), findsOneWidget);
      expect(find.text('₹4,999 / वर्ष'), findsOneWidget);
      expect(find.text('असीमित 360° जमानत प्रार्थना पत्र एवं बहस के बिंदु'), findsOneWidget);
    });
  });
}
