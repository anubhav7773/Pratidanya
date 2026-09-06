import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_environment.dart';
import '../../../../core/services/activity_service.dart';

final isProSubscriberProvider = StateProvider<bool>((ref) => false);


final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, AsyncValue<bool>>((ref) {
  return SubscriptionController(ref);
});

class SubscriptionController extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscriptionStream;

  static const String monthlySku = 'pratidnya_chamber_pro_monthly';
  static const String yearlySku = 'pratidnya_chamber_pro_yearly';
  static const Set<String> kProductIds = {monthlySku, yearlySku};

  List<ProductDetails> availableProducts = [];

  SubscriptionController(this._ref) : super(const AsyncValue.data(false)) {
    _initializeBilling();
  }

  Future<void> _initializeBilling() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("[Google Play Billing] Store unavailable on current device/environment.");
      return;
    }

    _subscriptionStream = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscriptionStream?.cancel(),
      onError: (error) => debugPrint("[Google Play Billing] Stream error: $error"),
    );

    // Fetch official product metadata from Google Play Console
    final ProductDetailsResponse response = await _iap.queryProductDetails(kProductIds);
    if (response.error == null) {
      availableProducts = response.productDetails;
      debugPrint("[Google Play Billing] ${availableProducts.length} SKUs loaded from Play Store.");
    } else {
      debugPrint("[Google Play Billing] SKU Query Error: ${response.error!.message}");
    }

    // Check initial status from backend
    await checkActiveSubscription();
  }

  Future<void> checkActiveSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final idToken = await user.getIdToken();
      final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/billing/status');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final isPro = data['is_pro'] == true;
        _ref.read(isProSubscriberProvider.notifier).state = isPro;
        state = AsyncValue.data(isPro);
      }
    } catch (e) {
      debugPrint("[Google Play Billing] Status sync exception: $e");
    }
  }

  Future<void> buySubscription(ProductDetails product) async {
    state = const AsyncValue.loading();
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e, st) {
      state = AsyncValue.error('खरीद आरंभ विफल: $e', st);
    }
  }

  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      await _iap.restorePurchases();
    } catch (e, st) {
      state = AsyncValue.error('सदस्यता पुनर्भरण विफल: $e', st);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Handles Indian UPI payment processing & NetBanking asynchronous approvals
          debugPrint("[Google Play Billing] Transaction Pending: ${purchase.purchaseID}");
          state = const AsyncValue.loading();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final bool valid = await _verifyWithBackend(purchase);
          if (valid) {
            // CRITICAL: Acknowledge purchase with Google Play to prevent automatic refund after 3 days
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
              debugPrint("[Google Play Billing] Purchase acknowledged: ${purchase.purchaseID}");
            }
            _ref.read(isProSubscriberProvider.notifier).state = true;
            state = const AsyncValue.data(true);
          } else {
            state = AsyncValue.error('सर्वर रसीद सत्यापन विफल हुआ।', StackTrace.current);
          }
          break;

        case PurchaseStatus.error:
          state = AsyncValue.error(
            purchase.error?.message ?? 'लेन-देन रद्द अथवा विफल हुआ।',
            StackTrace.current,
          );
          break;

        case PurchaseStatus.canceled:
          state = const AsyncValue.data(false);
          break;
      }
    }
  }

  Future<bool> _verifyWithBackend(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/billing/verify-subscription');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'product_id': purchase.productID,
          'purchase_token': purchase.verificationData.serverVerificationData,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("[Google Play Billing] Backend Verification Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> createRazorpayOrder(String planType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/billing/razorpay/create-order');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'plan_type': planType}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("[Razorpay] Order creation failed: $e");
    }
    return null;
  }

  Future<bool> verifyRazorpayPayment({
    required String planType,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    state = const AsyncValue.loading();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = AsyncValue.error('उपयोगकर्ता प्रमाणीकृत नहीं है।', StackTrace.current);
      return false;
    }

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/billing/razorpay/verify-payment');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'plan_type': planType,
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );

      if (response.statusCode == 200) {
        _ref.read(isProSubscriberProvider.notifier).state = true;
        state = const AsyncValue.data(true);

        ActivityService.logActivity(
          activityType: 'PRO_SUBSCRIPTION_ACTIVATED_RAZORPAY',
          details: {
            'plan_type': planType,
            'order_id': orderId,
            'payment_id': paymentId,
          },
        );
        return true;
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        state = AsyncValue.error(errorData['detail'] ?? 'भुगतान सत्यापन विफल हुआ।', StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error('भुगतान सत्यापन नेटवर्क त्रुटि: $e', st);
      return false;
    }
  }

  Future<bool> claimAdReward() async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final idToken = await user.getIdToken();
    final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/billing/claim-ad-reward');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
