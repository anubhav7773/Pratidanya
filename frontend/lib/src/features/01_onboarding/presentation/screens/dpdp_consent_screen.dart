import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../controllers/auth_controller.dart';

class DpdpConsentScreen extends ConsumerStatefulWidget {
  final VoidCallback? onConsentAccepted;

  const DpdpConsentScreen({super.key, this.onConsentAccepted});

  @override
  ConsumerState<DpdpConsentScreen> createState() => _DpdpConsentScreenState();
}

class _DpdpConsentScreenState extends ConsumerState<DpdpConsentScreen> {
  bool _isUnderstood = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('विधिक सूचना एवं सहमति (DPDP Act 2023)'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: StitchColors.borderSubtle),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'डिजिटल व्यक्तिगत डेटा संरक्षण अधिनियम, 2023 (धारा 5 एवं 6 के अंतर्गत सूचना)',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: StitchColors.courtNavy,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Divider(height: 24),
                        _buildSectionHeader('1. डेटा संग्रहण का विशिष्ट उद्देश्य (Purpose of Collection):'),
                        _buildBodyText(
                          'प्रतिज्ञा केवल जिला न्यायालय के आपराधिक मामलों में विधि अनुसंधान, आरोप-पत्र विश्लेषण '
                          'और जमानत प्रार्थना पत्र के तकनीकी प्रारूपण में सहायता हेतु वाद तथ्यों को संसाधित करती है।',
                        ),
                        const SizedBox(height: 12),
                        _buildSectionHeader('2. डेटा प्रक्रमण एवं संप्रभु भंडारण (Sovereign Storage):'),
                        _buildBodyText(
                          'हम आपके संवेदनशील वाद तथ्यों को सार्वजनिक AI प्रशिक्षण हेतु उपयोग नहीं करते हैं। '
                          'डेटा केवल भारतीय संप्रभु क्लाउड (AWS मुंबई ap-south-1) पर कड़ाई से एन्क्रिप्टेड संग्रहीत रहता है।',
                        ),
                        const SizedBox(height: 12),
                        _buildSectionHeader('3. सहमति वापसी एवं विलोपन का अधिकार (Right to Erasure - Sec 8(7)):'),
                        _buildBodyText(
                          'अधिवक्ता किसी भी समय अपनी सहमति वापस ले सकते हैं अथवा केस फाइल को स्थायी रूप से मिटा (Hard Delete) '
                          'सकते हैं। ऐसा करने पर समस्त संबंधित वेक्टर एम्बेडिंग्स स्वतः नष्ट हो जाएंगी।',
                        ),
                        const SizedBox(height: 12),
                        _buildSectionHeader('4. शिकायत निवारण (Data Protection Board of India):'),
                        _buildBodyText(
                          'किसी भी डेटा शिकायत हेतु आप हमारे डेटा संरक्षण अधिकारी से dpo@asiverticals.me पर संपर्क कर सकते हैं '
                          'अथवा DPBI के समक्ष विधिक शिकायत दर्ज कर सकते हैं।',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isUnderstood,
                    activeColor: StitchColors.verifiedGreen,
                    onChanged: (val) => setState(() => _isUnderstood = val ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'मैंने उपरोक्त विधिक सूचना को पढ़ लिया है और मैं अपने आपराधिक वाद अनुसंधान हेतु '
                      'डेटा प्रक्रमण के लिए स्पष्ट एवं सूचित सहमति (Informed Consent) प्रदान करता हूँ।',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: StitchColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StitchColors.courtNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                  ),
                  onPressed: _isUnderstood && !authState.isLoading
                      ? () async {
                          await ref.read(authControllerProvider.notifier).acceptDpdpConsent();
                          if (mounted && widget.onConsentAccepted != null) {
                            widget.onConsentAccepted!();
                          }
                        }
                      : null,
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('सहमति स्वीकार करें एवं आगे बढ़ें', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: StitchColors.chamberSlate),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.0, height: 1.45, color: StitchColors.textSecondary),
      ),
    );
  }
}
