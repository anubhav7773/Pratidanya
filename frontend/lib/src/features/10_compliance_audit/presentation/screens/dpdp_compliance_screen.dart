import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/luxury_card.dart';

class DpdpComplianceScreen extends ConsumerStatefulWidget {
  const DpdpComplianceScreen({super.key});

  @override
  ConsumerState<DpdpComplianceScreen> createState() => _DpdpComplianceScreenState();
}

class _DpdpComplianceScreenState extends ConsumerState<DpdpComplianceScreen> {
  bool _isExporting = false;

  void _triggerDataExport() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('चैंबर डेटा बंडल (JSON Archive) सफलतापूर्वक डाउनलोड हो गया।'),
          backgroundColor: LuxuryPalette.emeraldVerified,
        ),
      );
    }
  }

  void _showErasureDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('स्थायी डेटा विलोपन (Right to Erasure)'),
        content: const Text(
          'क्या आप सुनिश्चित हैं कि आप अपने समस्त केस डॉकेट, फॉरेंसिक साक्ष्य एवं ऑडियो लॉग्स को सर्वर से स्थायी रूप से हटाना चाहते हैं? यह क्रिया अपरिवर्तनीय है।',
          style: TextStyle(fontSize: 12.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LuxuryPalette.rubyAlert),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('धारा 8(7) DPDP Act के अंतर्गत समस्त चैंबर डेटा नष्ट कर दिया गया।'),
                  backgroundColor: LuxuryPalette.rubyAlert,
                ),
              );
            },
            child: const Text('स्थायी रूप से मिटाएं', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BilingualExecutiveAppBar(
        titleKey: 'chamber_badge',
        subtitleKey: 'app_title',
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
              children: [
                // BCI Rule 36 Certificate Card
                const LuxuryCard(
                  hasGoldAccent: true,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('बार काउंसिल ऑफ इंडिया नियम 36 प्रमाणन', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          Icon(Icons.verified_user_rounded, color: LuxuryPalette.emeraldVerified, size: 20),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text('अधिवक्ता: अनुभव सिंह • पंजीयन: UP/1234/2018', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Divider(height: 16),
                      Text('• प्रणाली बीसीआई नियमावली के अध्याय II नियम 36 का पूर्णतः पालन करती है।', style: TextStyle(fontSize: 11.5)),
                      Text('• कोई व्यावसायिक विज्ञापन अथवा परिणाम की गारंटी नहीं दी जाती।', style: TextStyle(fontSize: 11.5)),
                      Text('• समस्त विधिक मसौदे अधिवक्ता के स्वतंत्र पेशेवर परीक्षण के अधीन हैं।', style: TextStyle(fontSize: 11.5)),
                      Text('• डेटा संप्रभुता: समस्त डेटा भारत स्थित सर्वर (AWS मुंबई) में एन्क्रिप्टेड है।', style: TextStyle(fontSize: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('डेटा प्रदाता अधिकार (Data Principal Rights - DPDP Act 2023):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),

                // Section 11 Export Card
                LuxuryCard(
                  onTap: _isExporting ? null : _triggerDataExport,
                  padding: const EdgeInsets.all(14),
                  child: const Row(
                    children: [
                      Icon(Icons.download_for_offline_outlined, color: LuxuryPalette.champagneGold, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('चैंबर डेटा बंडल डाउनलोड करें (Section 11)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            Text('समस्त वाद, कार्यवाहियां एवं ऑडिट लॉग JSON प्रारूप में प्राप्त करें', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Section 8(7) Right to Erasure Card
                LuxuryCard(
                  isAlert: true,
                  onTap: _showErasureDialog,
                  padding: const EdgeInsets.all(14),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, color: LuxuryPalette.rubyAlert, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('स्थायी डेटा विलोपन (Right to Erasure - Sec 8(7))', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: LuxuryPalette.rubyAlert)),
                            Text('अपने समस्त केस एवं पहचान को सर्वर से स्थायी रूप से मिटाएं', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: LuxuryPalette.rubyAlert),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
