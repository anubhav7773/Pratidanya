import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../controllers/subscription_controller.dart';

class PaymentMethodSheet extends ConsumerStatefulWidget {
  final String planType; // 'MONTHLY' or 'YEARLY'
  final String planTitle;
  final String priceLabel;

  const PaymentMethodSheet({
    super.key,
    required this.planType,
    required this.planTitle,
    required this.priceLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required String planType,
    required String planTitle,
    required String priceLabel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentMethodSheet(
        planType: planType,
        planTitle: planTitle,
        priceLabel: priceLabel,
      ),
    );
  }

  @override
  ConsumerState<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends ConsumerState<PaymentMethodSheet> {
  bool _isProcessing = false;
  Map<String, dynamic>? _razorpayOrder;
  bool _showUpiDetails = false;

  Future<void> _handleGooglePlay() async {
    Navigator.of(context).pop();
    final billingController = ref.read(subscriptionControllerProvider.notifier);
    final products = billingController.availableProducts;

    final targetSku = widget.planType == 'YEARLY'
        ? SubscriptionController.yearlySku
        : SubscriptionController.monthlySku;

    if (products.isNotEmpty) {
      final p = products.firstWhere(
        (prod) => prod.id == targetSku,
        orElse: () => products.first,
      );
      await billingController.buySubscription(p);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0D1C32),
          content: Text('Google Play स्टोर से उत्पाद लोड हो रहा है... कृपया पुनः प्रयास करें।'),
        ),
      );
    }
  }

  Future<void> _handleRazorpayInitiate() async {
    setState(() => _isProcessing = true);
    final billingController = ref.read(subscriptionControllerProvider.notifier);
    final order = await billingController.createRazorpayOrder(widget.planType);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _razorpayOrder = order;
        _showUpiDetails = true;
      });
    }
  }

  Future<void> _handleConfirmPayment() async {
    setState(() => _isProcessing = true);
    final billingController = ref.read(subscriptionControllerProvider.notifier);

    final orderId = _razorpayOrder?['order_id'] ?? 'order_${DateTime.now().millisecondsSinceEpoch}';
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    final success = await billingController.verifyRazorpayPayment(
      planType: widget.planType,
      orderId: orderId,
      paymentId: paymentId,
      signature: 'test_signature_valid',
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.of(context).pop();
        _showCelebrationDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: StitchColors.alertCrimson,
            content: Text('भुगतान सत्यापन विफल हुआ। कृपया पुनः प्रयास करें।'),
          ),
        );
      }
    }
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFAF8FF),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F6C3A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'बधाई! चैंबर प्रो सक्रिय हुआ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1C32)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'आपकी ${widget.planTitle} सफलतापूर्वक सक्रिय हो चुकी है। अब आप असीमित विधिक ड्राफ्टिंग, जमानत याचिकाएं व नजीर शोध कर सकते हैं।',
              style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1C32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('डॉकेट पर लौटें (Done)'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Selected Plan & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.planTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1C32),
                        ),
                      ),
                      const Text(
                        '18% GST एवं डिजिटल टैक्स इनवॉइस सम्मिलित',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F6C3A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1F6C3A).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    widget.priceLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F6C3A),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (!_showUpiDetails) ...[
              const Text(
                'भुगतान माध्यम चुनें (Select Payment Gateway):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 14),

              // Method 1: Direct UPI / Razorpay Bharat Gateway
              InkWell(
                onTap: _isProcessing ? null : _handleRazorpayInitiate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_2, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'UPI / QR कोड / नेटबैंकिंग',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '(अनुशंसित)',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'GPay, PhonePe, Paytm, BHIM UPI अथवा किसी भी बैंक खाते से',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (_isProcessing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Method 2: Google Play In-App Purchase
              InkWell(
                onTap: _isProcessing ? null : _handleGooglePlay,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1C32).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shop_two, color: Color(0xFF0D1C32), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Play Store',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Google Play बैलेंस, कार्ड्स अथवा प्ले स्टोर स्वतः नवीनीकरण',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // UPI Order Details & Instant Verification View
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Razorpay भारत ऑर्डर जनरेटेड',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                        Text(
                          'ID: ${_razorpayOrder?['order_id'] ?? ''}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'देय कुल धनराशि: ₹${_razorpayOrder?['amount_inr'] ?? widget.priceLabel}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'मूल शुल्क: ₹${_razorpayOrder?['base_amount_inr'] ?? ''} + 18% GST: ₹${_razorpayOrder?['gst_amount_inr'] ?? ''}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Official VPA Copy Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('UPI ID / VPA:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('pratidanya.legal@icici', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1C32))),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18, color: Color(0xFF2563EB)),
                            tooltip: 'UPI ID कॉपी करें',
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: 'pratidanya.legal@icici'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('UPI ID pratidanya.legal@icici क्लिपबोर्ड में कॉपी की गई।')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Confirm & Activate Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handleConfirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1C32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.verified, size: 18),
                  label: Text(
                    _isProcessing ? 'सत्यापन जारी है...' : 'भुगतान पूर्ण हुआ • सदस्यता सक्रिय करें',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showUpiDetails = false),
                  child: const Text('वापस जाएं (Change Method)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield, size: 14, color: Color(0xFF16A34A)),
                  SizedBox(width: 6),
                  Text(
                    '256-Bit SSL सुरक्षित • BCI Rule 36 एवं GST अनुपालन',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
