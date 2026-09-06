import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pratidnya/src/features/billing/presentation/controllers/subscription_controller.dart';
import 'package:pratidnya/src/features/billing/presentation/widgets/payment_method_sheet.dart';

void main() {
  group('Goal 2: Dual Monetization (Google Play & Razorpay Bharat Gateway)', () {
    test('SubscriptionController defines correct Play Store SKUs', () {
      expect(SubscriptionController.monthlySku, 'pratidnya_chamber_pro_monthly');
      expect(SubscriptionController.yearlySku, 'pratidnya_chamber_pro_yearly');
      expect(SubscriptionController.kProductIds, contains('pratidnya_chamber_pro_monthly'));
      expect(SubscriptionController.kProductIds, contains('pratidnya_chamber_pro_yearly'));
    });

    test('isProSubscriberProvider initializes to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isPro = container.read(isProSubscriberProvider);
      expect(isPro, isFalse);

      container.read(isProSubscriberProvider.notifier).state = true;
      expect(container.read(isProSubscriberProvider), isTrue);
    });

    testWidgets('PaymentMethodSheet renders dual checkout options (UPI/QR & Play Store)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentMethodSheet(
                planType: 'MONTHLY',
                planTitle: 'मासिक चैंबर प्रो (Monthly Pro)',
                priceLabel: '₹499/माह',
              ),
            ),
          ),
        ),
      );

      // Verify header and plan title
      expect(find.textContaining('भुगतान माध्यम चुनें'), findsOneWidget);
      expect(find.text('मासिक चैंबर प्रो (Monthly Pro)'), findsOneWidget);
      expect(find.text('₹499/माह'), findsOneWidget);

      // Verify Method 1: Razorpay UPI / QR / NetBanking
      expect(find.textContaining('UPI / QR कोड / नेटबैंकिंग'), findsOneWidget);
      expect(find.textContaining('GPay, PhonePe, Paytm, BHIM UPI'), findsOneWidget);

      // Verify Method 2: Google Play Store
      expect(find.text('Google Play Store'), findsOneWidget);
      expect(find.textContaining('Google Play बैलेंस'), findsOneWidget);

      // Verify Compliance Footer
      expect(find.textContaining('256-Bit SSL सुरक्षित'), findsOneWidget);
      expect(find.textContaining('BCI Rule 36 एवं GST अनुपालन'), findsOneWidget);
    });

    testWidgets('PaymentMethodSheet renders yearly plan details accurately', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentMethodSheet(
                planType: 'YEARLY',
                planTitle: 'वार्षिक चैंबर प्रो (Annual Pro)',
                priceLabel: '₹4,999/वर्ष',
              ),
            ),
          ),
        ),
      );

      expect(find.text('वार्षिक चैंबर प्रो (Annual Pro)'), findsOneWidget);
      expect(find.text('₹4,999/वर्ष'), findsOneWidget);
      expect(find.textContaining('UPI / QR कोड / नेटबैंकिंग'), findsOneWidget);
      expect(find.text('Google Play Store'), findsOneWidget);
      expect(find.textContaining('18% GST एवं डिजिटल टैक्स इनवॉइस'), findsOneWidget);
    });
  });
}
