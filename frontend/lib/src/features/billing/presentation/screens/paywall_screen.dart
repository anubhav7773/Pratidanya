import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../controllers/subscription_controller.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(subscriptionControllerProvider);
    final billingController = ref.read(subscriptionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('प्रतिज्ञा चैंबर प्रो (Chamber Pro)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'आपराधिक विधि अभ्यास हेतु असीमित शक्ति',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: StitchColors.courtNavy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'दैनिक AI ड्राफ्ट सीमाओं एवं विज्ञापनों से मुक्त होकर कार्य करें।',
                style: TextStyle(color: StitchColors.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 20),
              _buildFeatureRow('असीमित 360° जमानत प्रार्थना पत्र एवं बहस के बिंदु'),
              _buildFeatureRow('उच्च न्यायालय व उच्चतम न्यायालय के मूल PDF आदेशों तक पहुंच'),
              _buildFeatureRow('न्यायालयीन फाइलिंग हेतु वॉटरमार्क-मुक्त PDF एक्सपोर्ट'),
              _buildFeatureRow('100% विज्ञापन-मुक्त निर्बाध चैंबर अनुभव'),
              const SizedBox(height: 24),
              if (billingState.isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _buildCard(
                  title: 'मासिक चैंबर प्रो',
                  price: '₹499 / माह',
                  desc: 'मासिक नवीनीकरण, कभी भी रद्द करें',
                  isPro: false,
                  onTap: () {
                    final products = billingController.availableProducts;
                    if (products.isNotEmpty) {
                      final p = products.firstWhere(
                        (prod) => prod.id == SubscriptionController.monthlySku,
                        orElse: () => products.first,
                      );
                      billingController.buySubscription(p);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('सदस्यता उत्पाद लोड हो रहे हैं...')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildCard(
                  title: 'वार्षिक चैंबर प्रो',
                  price: '₹4,999 / वर्ष',
                  desc: '2 माह निःशुल्क (₹1,000 की बचत) + प्राथमिकता सपोर्ट',
                  isPro: true,
                  onTap: () {
                    final products = billingController.availableProducts;
                    if (products.isNotEmpty) {
                      final p = products.firstWhere(
                        (prod) => prod.id == SubscriptionController.yearlySku,
                        orElse: () => products.last,
                      );
                      billingController.buySubscription(p);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('सदस्यता उत्पाद लोड हो रहे हैं...')),
                      );
                    }
                  },
                ),
              ],
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'सुरक्षित भुगतान Google Play UPI / Cards द्वारा संचालित है।',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          const Icon(Icons.verified, color: StitchColors.verifiedGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String price,
    required String desc,
    required bool isPro,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isPro ? StitchColors.courtNavy : Colors.white,
          border: Border.all(color: isPro ? StitchColors.courtNavy : StitchColors.borderSubtle, width: 1.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isPro ? Colors.white : StitchColors.courtNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 11, color: isPro ? Colors.grey.shade300 : StitchColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPro ? Colors.amber : StitchColors.courtNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
