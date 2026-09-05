import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_environment.dart';

final isProSubscriberProvider = StateProvider<bool>((ref) => false);

final subscriptionControllerProvider = StateNotifierProvider<SubscriptionController, AsyncValue<bool>>((ref) {
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
    try {
      final bool available = await _iap.isAvailable();
      if (!available) return;

      _subscriptionStream = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscriptionStream?.cancel(),
        onError: (error) => debugPrint("Billing Stream Error: $error"),
      );

      final ProductDetailsResponse response = await _iap.queryProductDetails(kProductIds);
      if (response.error == null) {
        availableProducts = response.productDetails;
      }
    } catch (e) {
      debugPrint("Billing init error: $e");
    }
  }

  Future<void> buySubscription(ProductDetails product) async {
    state = const AsyncValue.loading();
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e, st) {
      state = AsyncValue.error('खरीद प्रक्रिया आरंभ विफल: $e', st);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = const AsyncValue.loading();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final bool valid = await _verifyWithBackend(purchase);
          if (valid) {
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            _ref.read(isProSubscriberProvider.notifier).state = true;
            state = const AsyncValue.data(true);
          } else {
            state = AsyncValue.error('सर्वर रसीद सत्यापन विफल हुआ।', StackTrace.current);
          }
          break;

        case PurchaseStatus.error:
          state = AsyncValue.error(purchase.error?.message ?? 'लेन-देन विफल हुआ।', StackTrace.current);
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
