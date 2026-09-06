import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pratidnya/src/core/config/admob_constants.dart';
import 'package:pratidnya/src/features/billing/data/admob_service.dart';
import 'package:pratidnya/src/features/billing/presentation/controllers/subscription_controller.dart';
import 'package:pratidnya/src/shared/components/court_inline_banner_ad.dart';

void main() {
  group('Goal 11: AdMob Production Configuration & Test Device Gating', () {
    test('Test device whitelisting contains 3 designated QA/workstation devices', () {
      expect(AdMobConstants.testDeviceIds.length, 3);
      expect(AdMobConstants.testDeviceIds, contains('B3EEABB8EE11C2BE770B684D95219ECB'));
      expect(AdMobConstants.testDeviceIds, contains('F5A9A7A6D889E4C2E3C0F5D5881C8E64'));
      expect(AdMobConstants.testDeviceIds, contains('2C9A1D8A3B4C5E6F7A8B9C0D1E2F3A4B'));
    });

    test('AdMob production app identifier is registered', () {
      expect(AdMobConstants.androidAppId, 'ca-app-pub-8451920384729104~9384720194');
    });

    test('Ad unit fallback and production getters return non-empty strings', () {
      expect(AdMobConstants.bannerAdUnitId, isNotEmpty);
      expect(AdMobConstants.rewardedAdUnitId, isNotEmpty);
      expect(AdMobService.androidBannerTestId, 'ca-app-pub-3940256099942544/6300978111');
      expect(AdMobService.androidRewardedTestId, 'ca-app-pub-3940256099942544/5224354917');
    });
  });

  group('Goal 11: Google Play Billing SKUs & Auto-Acknowledgement', () {
    test('Subscription SKUs match Indian payment rails and Play Console products', () {
      expect(SubscriptionController.monthlySku, 'pratidnya_chamber_pro_monthly');
      expect(SubscriptionController.yearlySku, 'pratidnya_chamber_pro_yearly');
      expect(SubscriptionController.kProductIds, contains('pratidnya_chamber_pro_monthly'));
      expect(SubscriptionController.kProductIds, contains('pratidnya_chamber_pro_yearly'));
    });
  });

  group('Goal 11: Pro-Tier Global Ad Suppression', () {
    testWidgets('CourtInlineBannerAd returns SizedBox.shrink when isProSubscriberProvider is true', (tester) async {
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
      // Verifies ad is completely suppressed and no AdWidget is in the tree
      expect(find.byType(AdWidget), findsNothing);
      expect(find.text('प्रायोजित विधिक सूचना (Sponsored)'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('CourtInlineBannerAd stays suppressed before ad load completes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isProSubscriberProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CourtInlineBannerAd(),
            ),
          ),
        ),
      );

      await tester.pump();
      // Since no mock ad was marked loaded, AdWidget should not render
      expect(find.byType(AdWidget), findsNothing);
    });
  });
}
