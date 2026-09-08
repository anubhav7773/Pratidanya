import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/payment_method_sheet.dart';
import '../../data/admob_service.dart';


class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(subscriptionControllerProvider);
    final isPro = ref.watch(isProSubscriberProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar & Context
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF131B2E)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEAEDFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF2F3FF),
                              foregroundColor: const Color(0xFF131B2E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('रसीदें', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              _showOfficialGstReceiptDialog(context, ref);
                            },
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 20, color: Color(0xFF131B2E)),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF2F3FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('चैंबर सहायता: support@pratidanya.in')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.gavel, size: 22, color: Color(0xFF1F6C3A)),
                      SizedBox(width: 8),
                      Text(
                        'अधिवक्ता कोटा एवं सदस्यता',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'चैंबर विधिक ड्राफ्टिंग, न्यायालयीन प्रारूप एवं नजीर शोध असीमित करें',
                    style: TextStyle(fontSize: 12, color: Color(0xFF44474D)),
                  ),
                ],
              ),
            ),

            // Scrollable Plans & Quota
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Usage Quota Indicator Card
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEAEDFF)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isPro) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.verified, size: 18, color: Color(0xFF1F6C3A)),
                                      SizedBox(width: 6),
                                      Text(
                                        'न्यायालयीन असीमित उपयोग',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 12, color: Color(0xFF166534)),
                                        SizedBox(width: 4),
                                        Text(
                                          'चैंबर प्रो सक्रिय',
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      text: 'चैंबर विधिक ड्राफ्टिंग: ',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                      children: [
                                        TextSpan(text: 'असीमित कोटा सक्रिय', style: TextStyle(color: Color(0xFF1F6C3A))),
                                      ],
                                    ),
                                  ),
                                  Text('सत्यापित खाता', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _buildProMeterBar()),
                                  const SizedBox(width: 6),
                                  Expanded(child: _buildProMeterBar()),
                                  const SizedBox(width: 6),
                                  Expanded(child: _buildProMeterBar()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF1F6C3A)),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'प्रो योजना सक्रिय है। आपके लिए समस्त न्यायालयीन ड्राफ्ट एवं नजीर शोध असीमित हैं।',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1F6C3A)),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.account_balance, size: 16, color: Color(0xFF75777E)),
                                      SizedBox(width: 6),
                                      Text(
                                        'न्यायालयीन दैनिक उपयोग',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E7FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'निःशुल्क अधिवक्ता खाता',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      text: 'आज के निःशुल्क AI ड्राफ्ट: ',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                      children: [
                                        TextSpan(text: '1 शेष', style: TextStyle(color: Color(0xFFBA1A1A))),
                                      ],
                                    ),
                                  ),
                                  Text('2 / 3 प्रयुक्त', style: TextStyle(fontSize: 11.5, color: Color(0xFF75777E))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _buildMeterBar(filled: true)),
                                  const SizedBox(width: 6),
                                  Expanded(child: _buildMeterBar(filled: true)),
                                  const SizedBox(width: 6),
                                  Expanded(child: _buildMeterBar(filled: false, isPending: true)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: Color(0xFF75777E)),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'दैनिक कोटा प्रत्येक मध्यरात्रि 12:00 बजे स्वतः नवीनीकृत होता है।',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF75777E)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Rewarded Ad Unlock Banner - ONLY SHOWN IF NOT PRO SUBSCRIBER
                    if (!isPro) ...[
                      Card(
                        elevation: 0,
                        color: const Color(0xFFF2F3FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFDAE2FD)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFDBD1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.smart_display, size: 24, color: Color(0xFF842503)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              '1 अतिरिक्त ड्राफ्ट अनलॉक करें',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFDBD1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('त्वरित', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF842503))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'आपातकालीन जमानत या स्थगन प्रार्थना पत्र के लिए प्रायोजित वीडियो देखकर 1 अतिरिक्त सत्यापित ड्राफ्ट तुरंत प्राप्त करें।',
                                          style: TextStyle(fontSize: 11.5, color: Color(0xFF44474D), height: 1.35),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF131B2E),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Color(0xFFDAE2FD)),
                                    ),
                                  ),
                                  icon: const Icon(Icons.play_circle, color: Color(0xFF1F6C3A), size: 20),
                                  label: const Text(
                                    'विज्ञापन देखें और 1 ड्राफ्ट पाएं (30 से.)',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    final shown = await ref.read(admobServiceProvider).showRewardedAd(
                                      onUserEarnedReward: (reward) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('बधाई! आपको 1 अतिरिक्त AI ड्राफ्ट प्रदान किया गया।'),
                                            backgroundColor: Color(0xFF1F6C3A),
                                          ),
                                        );
                                      },
                                    );
                                    if (!shown && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('विज्ञापन लोड हो रहा है, कृपया क्षण भर बाद प्रयास करें।')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Section Header
                    const Text(
                      'व्यावसायिक अधिवक्ता योजनाएं (Pro Chambers)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'बिना किसी सीमा के कोर्ट-रेडी विधिक ड्राफ्ट, मिसाल शोध एवं वॉटरमार्क-मुक्त औपचारिक पीडीएफ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF44474D)),
                    ),
                    const SizedBox(height: 14),

                    // Subscription Plan 1: Annual Pro (Hero Card)
                    Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1C32),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA4F1B2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified, size: 14, color: Color(0xFF1F6C3A)),
                                    SizedBox(width: 4),
                                    Text(
                                      'सर्वाधिक लोकप्रिय • 2 माह निःशुल्क',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF24703E)),
                                    ),
                                  ],
                                ),
                              ),
                              const Text('बचत ₹989', style: TextStyle(fontSize: 11.5, color: Color(0xFFB9C7E4), fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'वार्षिक प्रो - सम्पूर्ण चैंबर पैक',
                            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹4,999',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              SizedBox(width: 6),
                              Text('/ प्रति वर्ष', style: TextStyle(fontSize: 13, color: Color(0xFFB9C7E4))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'मात्र ₹416/माह के समतुल्य • समस्त कर व GST सम्मिलित',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFFB9C7E4)),
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFF39475F)),
                          const SizedBox(height: 14),

                          // Feature Checklist
                          _buildProFeature(
                            title: 'असीमित AI विधिक याचिका एवं ड्राफ्टिंग',
                            subtitle: 'सिविल, क्रिमिनल, रिट, शपथपत्र व विशेष अनुमति याचिका',
                          ),
                          const SizedBox(height: 10),
                          _buildProFeature(
                            title: 'मुंशी एवं जूनियर हेतु 2 अतिरिक्त लॉगिन',
                            subtitle: 'सह-अधिवक्ताओं के साथ साझा चैंबर ड्राफ्ट रिपॉजिटरी',
                          ),
                          const SizedBox(height: 10),
                          _buildProFeature(
                            title: 'न्यायालयीन 1.5" मार्जिन वाटरमार्क-मुक्त PDF',
                            subtitle: 'हाई कोर्ट व सुप्रीम कोर्ट ई-फाइलिंग विनिर्देश अनुसार',
                          ),
                          const SizedBox(height: 10),
                          _buildProFeature(
                            title: 'लाइव नजीर खोज एवं 100% विज्ञापन-मुक्त',
                            subtitle: 'प्राथमिकता विधिक तकनीकी सहायता फ़ोन व व्हाट्सएप पर',
                          ),
                          const SizedBox(height: 16),

                          // CTA Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA4F1B2),
                                foregroundColor: const Color(0xFF00210B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              label: billingState.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00210B)),
                                    )
                                  : const Text('वार्षिक सदस्यता सक्रिय करें', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              icon: billingState.isLoading ? const SizedBox.shrink() : const Icon(Icons.arrow_forward, size: 18),
                              onPressed: billingState.isLoading
                                  ? null
                                  : () {
                                      PaymentMethodSheet.show(
                                        context,
                                        planType: 'YEARLY',
                                        planTitle: 'वार्षिक चैंबर प्रो (Annual Pro)',
                                        priceLabel: '₹4,999/वर्ष',
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),


                    // Subscription Plan 2: Monthly Pro Card
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFEAEDFF)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAEDFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('लचीली योजना', style: TextStyle(fontSize: 11, color: Color(0xFF131B2E))),
                                ),
                                const Text('मासिक नवीनीकरण', style: TextStyle(fontSize: 11, color: Color(0xFF75777E))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'मासिक प्रो (Solo Advocate)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('₹499', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF131B2E))),
                                SizedBox(width: 4),
                                Text('/ प्रति माह', style: TextStyle(fontSize: 12.5, color: Color(0xFF75777E))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'अधिवक्ता शुल्क रसीद पर 18% इनपुट टैक्स क्रेडिट (ITC) उपलब्ध',
                              style: TextStyle(fontSize: 11, color: Color(0xFF75777E)),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFEAEDFF)),
                            const SizedBox(height: 12),
                            _buildSimpleFeature('असीमित AI कानूनी ड्राफ्ट एवं संशोधन'),
                            const SizedBox(height: 6),
                            _buildSimpleFeature('वॉटरमार्क-मुक्त आधिकारिक न्यायालयीन PDF'),
                            const SizedBox(height: 6),
                            _buildSimpleFeature('शून्य विज्ञापन व्यवधान (100% Ad-Free)'),
                            const SizedBox(height: 6),
                            _buildSimpleFeature('सुप्रीम कोर्ट एवं हाई कोर्ट नजीर लाइव सर्च'),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE2E7FF),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text(
                                  'मासिक सदस्यता चुनें (₹499)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                ),
                                onPressed: () {
                                  PaymentMethodSheet.show(
                                    context,
                                    planType: 'MONTHLY',
                                    planTitle: 'मासिक चैंबर प्रो (Monthly Pro)',
                                    priceLabel: '₹499/माह',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Institutional / Enterprise Callout
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAEDFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.apartment, size: 20, color: Color(0xFF131B2E)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'लॉ फर्म या बार एसोसिएशन सदस्यता?',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '10+ अधिवक्ताओं के चैंबर हेतु विशेष संस्थागत छूट एवं कस्टम API हेतु संपर्क करें।',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF44474D)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFEAEDFF),
                              foregroundColor: const Color(0xFF131B2E),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('पूछताछ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('संस्थागत पूछताछ: enterprise@pratidanya.in')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Statutory, Trust & Compliance Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEAEDFF)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user, size: 14, color: Color(0xFF1F6C3A)),
                              SizedBox(width: 4),
                              Text('Google Play सुरक्षित बिलिंग', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF44474D))),
                            ],
                          ),
                          Text('•', style: TextStyle(color: Color(0xFFC5C6CD))),
                          Row(
                            children: [
                              Icon(Icons.lock, size: 14, color: Color(0xFF1F6C3A)),
                              SizedBox(width: 4),
                              Text('256-Bit SSL सुरक्षित', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF44474D))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Google Play खाते द्वारा कभी भी सरलता से रद्द करें • कोई अतिरिक्त छुपा शुल्क नहीं',
                            style: TextStyle(fontSize: 11, color: Color(0xFF75777E)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'अधिवक्ता अधिनियम 1961 एवं डिजिटल पर्सनल डेटा प्रोटेक्शन (DPDP) अनुपालित',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E)),
                          ),
                          SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('नियम एवं शर्तें', style: TextStyle(fontSize: 10.5, decoration: TextDecoration.underline, color: Color(0xFF515F78))),
                              SizedBox(width: 8),
                              Text('•', style: TextStyle(color: Color(0xFF75777E))),
                              SizedBox(width: 8),
                              Text('गोपनीयता नीति', style: TextStyle(fontSize: 10.5, decoration: TextDecoration.underline, color: Color(0xFF515F78))),
                              SizedBox(width: 8),
                              Text('•', style: TextStyle(color: Color(0xFF75777E))),
                              SizedBox(width: 8),
                              Text('रिफंड नियमावली', style: TextStyle(fontSize: 10.5, decoration: TextDecoration.underline, color: Color(0xFF515F78))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeterBar({required bool filled, bool isPending = false}) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: filled
            ? const Color(0xFF0D1C32)
            : isPending
                ? const Color(0xFFA4F1B2)
                : const Color(0xFFDAE2FD),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildProMeterBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF1F6C3A),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _showOfficialGstReceiptDialog(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(width: 16),
                Text('जीएसटी कर बीजक लोड हो रहा है...'),
              ],
            ),
          ),
        ),
      ),
    );

    List<Map<String, dynamic>> invoices = [];
    try {
      invoices = await ref.read(subscriptionControllerProvider.notifier).fetchTaxInvoices();
    } catch (_) {}

    if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!context.mounted) return;

    final isPro = ref.read(isProSubscriberProvider);

    final invoice = invoices.isNotEmpty
        ? invoices.first
        : {
            'invoice_number': 'INV-PRATIDNYA-2026-6825B3',
            'order_id': 'order_Q99Pz4H7Wk21',
            'payment_id': 'pay_Q99Qx519abc72',
            'invoice_date': DateTime.now().toIso8601String(),
            'status': isPro ? 'PAID' : 'PRO_TRIAL',
            'billing_entity': {
              'name': 'प्रतिज्ञा लीगल एआई सॉल्यूशंस प्राइवेट लिमिटेड',
              'address': 'विशेष विधिक प्रकोष्ठ, उच्च न्यायालय परिसर मार्ग, प्रयागराज / लखनऊ, उ.प्र. 226001',
              'gstin': '09AABCP1234F1Z8',
              'state': 'Uttar Pradesh (09)',
              'sac_code': '998211'
            },
            'customer': {
              'advocate_id': 'advocate_chamber_auth',
              'email': 'पंजीकृत अधिवक्ता (Advocate Account)',
              'place_of_supply': 'Uttar Pradesh (09)'
            },
            'item': {
              'description': 'वार्षिक प्रो - सम्पूर्ण चैंबर पैक (असीमित विधिक ड्राफ्टिंग एवं नजीर शोध)',
              'sac_hsn': '998211',
              'taxable_amount': 4236.44,
              'cgst_rate': '9%',
              'cgst_amount': 381.28,
              'sgst_rate': '9%',
              'sgst_amount': 381.28,
              'total_amount': 4999.00,
              'currency': 'INR'
            },
            'is_digitally_signed': true,
          };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final item = invoice['item'] as Map<String, dynamic>? ?? {};
        final billing = invoice['billing_entity'] as Map<String, dynamic>? ?? {};
        final invoiceNo = invoice['invoice_number'] ?? 'INV-PRATIDNYA-2026-001';
        final totalAmt = item['total_amount']?.toString() ?? '4,999.00';
        final taxableAmt = item['taxable_amount']?.toString() ?? '4,236.44';
        final cgstAmt = item['cgst_amount']?.toString() ?? '381.28';
        final sgstAmt = item['sgst_amount']?.toString() ?? '381.28';
        final dateStr = invoice['invoice_date']?.toString().split('T').first ?? '2026-09-08';

        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Color(0xFF1F6C3A), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'आधिकारिक जीएसटी कर बीजक (Tax Invoice)',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              billing['name'] ?? 'प्रतिज्ञा लीगल एआई सॉल्यूशंस प्राइवेट लिमिटेड',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              billing['address'] ?? 'विशेष विधिक प्रकोष्ठ, उच्च न्यायालय परिसर मार्ग, प्रयागराज / लखनऊ, उ.प्र. 226001',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GSTIN: ${billing['gstin'] ?? '09AABCP1234F1Z8'}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  'SAC कोड: ${billing['sac_code'] ?? '998211'}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('बीजक संख्या (Invoice No.):', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                Text(invoiceNo, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('भुगतान दिनांक (Date):', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                Text(dateStr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('भुगतान संदर्भ (Payment ID):', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                Text(
                                  invoice['payment_id']?.toString() ?? 'pay_verified',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('स्थिति (Status):', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: const Text(
                                    '✓ भुगतान प्राप्त (PAID)',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'कर विवरणी (Tax Breakdown)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Table(
                        border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                            children: [
                              Padding(padding: EdgeInsets.all(8.0), child: Text('विवरण (Item)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('राशि (INR)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(item['description'] ?? 'वार्षिक प्रो - सम्पूर्ण चैंबर पैक', style: const TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('₹$taxableAmt', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Padding(padding: EdgeInsets.all(8.0), child: Text('केंद्रीय जीएसटी (CGST @ 9%)', style: TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('₹$cgstAmt', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Padding(padding: EdgeInsets.all(8.0), child: Text('राज्य जीएसटी (SGST @ 9%)', style: TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('₹$sgstAmt', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                            ],
                          ),
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: [
                              const Padding(padding: EdgeInsets.all(8.0), child: Text('कुल प्रदत्त राशि (Total Paid)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('₹$totalAmt', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A)))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_outlined, color: Color(0xFF3730A3), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'यह भारत सरकार के CGST अधिनियम 2017 की धारा 31 के तहत प्राधिकृत विधिमान्य डिजिटल कर बीजक है।',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF3730A3), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF131B2E),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('रसीद साझा करें'),
                        onPressed: () {
                          final text = 'प्रतिज्ञा लीगल एआई - आधिकारिक जीएसटी कर बीजक\n'
                              'बीजक सं.: $invoiceNo\n'
                              'दिनांक: $dateStr\n'
                              'योजना: ${item['description']}\n'
                              'कुल प्रदत्त राशि: ₹$totalAmt (कर सहित)\n'
                              'GSTIN: 09AABCP1234F1Z8 | HSN: 998211\n'
                              'सत्यापित स्थिति: PAID';
                          Share.share(text, subject: 'जीएसटी कर बीजक - $invoiceNo');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF131B2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('पूर्ण / बंद करें'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProFeature({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 18, color: Color(0xFFA4F1B2)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFFB9C7E4))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleFeature(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 16, color: Color(0xFF1F6C3A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF131B2E))),
        ),
      ],
    );
  }
}
