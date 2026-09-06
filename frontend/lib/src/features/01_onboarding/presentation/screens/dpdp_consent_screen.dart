import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../controllers/auth_controller.dart';

class DpdpConsentScreen extends ConsumerStatefulWidget {
  final VoidCallback? onConsentAccepted;

  const DpdpConsentScreen({super.key, this.onConsentAccepted});

  @override
  ConsumerState<DpdpConsentScreen> createState() => _DpdpConsentScreenState();
}

class _DpdpConsentScreenState extends ConsumerState<DpdpConsentScreen> {
  bool _isStatutoryChecked = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: StitchColors.alertCrimson,
          ),
        );
      } else if (previous?.isLoading == true && !next.isLoading && !next.hasError) {
        if (context.mounted) {
          context.go('/bar-enrollment');
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Statutory Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              color: const Color(0xFFFAF8FF),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E7FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.policy, size: 12, color: Color(0xFF44474D)),
                                SizedBox(width: 4),
                                Text(
                                  'DPDP अधिनियम 2023 | धारा 5 एवं 6',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF44474D)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'विधिक सूचना एवं सहमति',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA4F1B2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, size: 14, color: Color(0xFF1F6C3A)),
                        SizedBox(width: 4),
                        Text(
                          'प्रमाणित',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF24703E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Legal Privilege Notice Sub-Banner
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDAE2FD)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFF1F6C3A), size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'अधिवक्ता एवं मुवक्किल गोपनीयता सुरक्षा',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'यह मंच भारतीय साक्ष्य अधिनियम की धारा 126 तथा डिजिटल पर्सनल डेटा प्रोटेक्शन एक्ट 2023 की वैधानिक आवश्यकताओं के तहत डेटा गोपनीयता सुनिश्चित करता है।',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF44474D), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // खंड 1: डेटा संग्रहण का उद्देश्य
                    _buildClauseCard(
                      number: '01',
                      title: 'खंड 1: डेटा संग्रहण का उद्देश्य',
                      badgeText: 'Sec 5(1)',
                      badgeBg: const Color(0xFFEAEDFF),
                      badgeFg: const Color(0xFF44474D),
                      bodyText:
                          'केस फाइलिंग, ई-कोर्ट्स वाद सूची (Cause List) मिलान, विधिक अनुसंधान एवं आपराधिक अपील प्रारूपण हेतु आवश्यक अधिवक्ता एवं पक्षकार डेटा का सीमित प्रक्रमण। डेटा का उपयोग केवल न्यायिक प्रक्रियाओं तक सीमित रहेगा।',
                      bottomWidget: Row(
                        children: [
                          _buildChip(icon: Icons.gavel, text: 'ई-कोर्ट्स समन्वयन'),
                          const SizedBox(width: 8),
                          _buildChip(icon: Icons.history_edu, text: 'वाद सूची ऑटो-सिंक'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // खंड 2: स्थानीय क्लाउड डेटा संप्रभुता
                    _buildClauseCard(
                      number: '02',
                      title: 'खंड 2: स्थानीय क्लाउड डेटा संप्रभुता',
                      badgeText: 'AES-256',
                      badgeBg: const Color(0xFFA4F1B2),
                      badgeFg: const Color(0xFF1F6C3A),
                      badgeIcon: Icons.lock,
                      bodyText:
                          'समस्त केस रिकॉर्ड एवं डिजिटल साक्ष्य भारत की सीमा के भीतर AWS मुंबई (ap-south-1) टियर-4 डेटा केंद्र में 256-बिट एईएस एन्क्रिप्शन के साथ संप्रभुता पूर्वक सुरक्षित रखे जाते हैं। सीमा-पार डेटा हस्तांतरण पूर्णतः प्रतिबंधित है।',
                      bottomWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.pin_drop, size: 16, color: Color(0xFF1F6C3A)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'डेटा स्थान: मुंबई, भारत संप्रभु क्लस्टर (AWS ap-south-1)',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF131B2E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // खंड 3: डेटा विलोपन एवं सुधार का अधिकार
                    _buildClauseCard(
                      number: '03',
                      title: 'खंड 3: डेटा विलोपन एवं सुधार का अधिकार',
                      badgeText: 'Sec 8(7)',
                      badgeBg: const Color(0xFFEAEDFF),
                      badgeFg: const Color(0xFF44474D),
                      bodyText:
                          'DPDP अधिनियम 2023 की धारा 8(7) के अंतर्गत अधिवक्ता को किसी भी समय केस निस्तारण उपरांत अपनी प्रोफाइल एवं क्लाइंट डेटा को पूर्णतः मिटाने (Right to Erasure / विस्मृत होने का अधिकार) एवं संपादन का पूर्ण वैधानिक अधिकार प्राप्त है।',
                    ),
                    const SizedBox(height: 12),

                    // खंड 4: डेटा संरक्षण बोर्ड (DPB) शिकायत निवारण
                    _buildClauseCard(
                      number: '04',
                      title: 'खंड 4: डेटा संरक्षण बोर्ड (DPB) शिकायत निवारण',
                      badgeText: 'DPO सेल',
                      badgeBg: const Color(0xFFEAEDFF),
                      badgeFg: const Color(0xFF44474D),
                      bodyText:
                          'किसी भी डेटा सुरक्षा संबंधी आपत्ति या पूछताछ हेतु विधिक डेटा संरक्षण अधिकारी (DPO) से dpo@pratidanya.gov.in पर संपर्क करें। 48 घंटे के भीतर त्वरित समाधान अथवा भारतीय डेटा संरक्षण बोर्ड (DPBI) को वैधानिक प्रेषण।',
                      bottomWidget: const Row(
                        children: [
                          Icon(Icons.timer, size: 15, color: Color(0xFF1F6C3A)),
                          SizedBox(width: 6),
                          Text(
                            'निवारण समय-सीमा: 48 घंटे के भीतर वैधानिक संज्ञान',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF44474D)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Affirmation & Action Card
                    Card(
                      elevation: 1,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isStatutoryChecked = !_isStatutoryChecked),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _isStatutoryChecked,
                                    activeColor: const Color(0xFF0D1C32),
                                    onChanged: (val) => setState(() => _isStatutoryChecked = val ?? false),
                                  ),
                                  const Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'मैंने विधिक सूचना पढ़ ली है एवं केस डेटा प्रक्रमण हेतु धारा 5 एवं 6 के तहत सहर्ष सहमति प्रदान करता हूँ।',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isStatutoryChecked ? const Color(0xFF0D1C32) : const Color(0xFFDAE2FD),
                                  foregroundColor: _isStatutoryChecked ? Colors.white : const Color(0xFF44474D),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.verified, size: 18),
                                label: authState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        'सहमति स्वीकार करें एवं आगे बढ़ें',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                onPressed: _isStatutoryChecked && !authState.isLoading
                                    ? () async {
                                        await ref.read(authControllerProvider.notifier).acceptDpdpConsent();
                                        if (mounted && widget.onConsentAccepted != null) {
                                          widget.onConsentAccepted!();
                                        }
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text(
                                'अस्वीकार करें (Exit / Decline)',
                                style: TextStyle(color: StitchColors.alertCrimson, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Divider(height: 20),
                            const Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_outline, size: 13, color: Color(0xFF75777E)),
                                      SizedBox(width: 4),
                                      Text(
                                        'DPDP ACT, 2023 COMPLIANT INTERFACE',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF75777E), letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'वैधानिक प्रमाणीकरण आईडी: DPDP-DEL-2024-ADV-891',
                                    style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClauseCard({
    required String number,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    IconData? badgeIcon,
    required String bodyText,
    Widget? bottomWidget,
  }) {
    return Card(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDAE2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          number,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badgeIcon != null) ...[
                        Icon(badgeIcon, size: 12, color: badgeFg),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        badgeText,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeFg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              bodyText,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF44474D), height: 1.45),
            ),
            if (bottomWidget != null) ...[
              const SizedBox(height: 10),
              bottomWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF44474D)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF44474D), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
