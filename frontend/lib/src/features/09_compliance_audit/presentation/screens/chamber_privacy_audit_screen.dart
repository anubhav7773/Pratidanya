import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../01_onboarding/presentation/controllers/auth_controller.dart';

class ChamberPrivacyAuditScreen extends ConsumerStatefulWidget {
  const ChamberPrivacyAuditScreen({super.key});

  @override
  ConsumerState<ChamberPrivacyAuditScreen> createState() => _ChamberPrivacyAuditScreenState();
}

class _ChamberPrivacyAuditScreenState extends ConsumerState<ChamberPrivacyAuditScreen> {
  bool _isExporting = false;
  bool _isErasing = false;
  Map<String, dynamic>? _bciStatement;

  @override
  void initState() {
    super.initState();
    _loadBciStatement();
  }

  Future<void> _loadBciStatement() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken();
      final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/compliance/dpdp/bci-audit-statement');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (res.statusCode == 200 && mounted) {
        setState(() {
          _bciStatement = jsonDecode(utf8.decode(res.bodyBytes));
        });
      }
    } catch (_) {}
  }

  Future<void> _exportDataBundle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isExporting = true);
      final idToken = await user.getIdToken();
      final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/compliance/dpdp/export-chamber-bundle');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $idToken'});

      if (mounted) setState(() => _isExporting = false);

      if (res.statusCode == 200 && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('डेटा बंडल सफलतापूर्वक तैयार', style: TextStyle(height: 1.42)),
            content: const Text(
              'डीपीसपी अधिनियम 2023 की धारा 11 के तहत आपका पूर्ण चैंबर डेटा बंडल तैयार हो गया है। '
              'इसमें आपके समस्त केस, कार्यवाहियां एवं विधिक ऑडिट लॉग्स शामिल हैं।',
              style: TextStyle(height: 1.42),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ठीक है', style: TextStyle(height: 1.40))),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('निर्यात त्रुटि: $e', style: const TextStyle(height: 1.40)), backgroundColor: StitchColors.alertCrimson),
        );
      }
    }
  }

  void _confirmCompleteErasure() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('स्थायी डेटा विलोपन (Right to Erasure)', style: TextStyle(height: 1.42)),
        content: const Text(
          'चेतावनी: यह क्रिया अपरिवर्तनीय है। डीपीसपी अधिनियम 2023 की धारा 8(7) के अंतर्गत आपके सभी केस, '
          'ड्राफ्ट, वॉयस रिकॉर्ड्स एवं प्रोफाइल डेटा को डेटाबेस से स्थायी रूप से हटा दिया जाएगा।\n\n'
          'क्या आप विलोपन की पुष्टि करते हैं?',
          style: TextStyle(height: 1.42),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें', style: TextStyle(height: 1.40))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: StitchColors.alertCrimson),
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeErasure();
            },
            child: const Text('हाँ, सब कुछ स्थायी रूप से मिटाएं', style: TextStyle(color: Colors.white, height: 1.40)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeErasure() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isErasing = true);
      final idToken = await user.getIdToken();
      final url = Uri.parse('${AppEnvironment.backendBaseUrl}/api/v1/compliance/dpdp/execute-erasure');
      final res = await http.delete(url, headers: {'Authorization': 'Bearer $idToken'});

      if (mounted) setState(() => _isErasing = false);

      if (res.statusCode == 200 && mounted) {
        await ref.read(authControllerProvider.notifier).logout();
      }
    } catch (e) {
      if (mounted) setState(() => _isErasing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('विलोपन विफलता: $e', style: const TextStyle(height: 1.40)), backgroundColor: StitchColors.alertCrimson),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'चैंबर विधिक ऑडिट एवं डेटा संरक्षण (DPDP)',
          style: TextStyle(height: 1.42, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18.0),
              children: [
                Text(
                  'सांविधिक विधिक अनुपालन स्थिति (DPDP Act 2023)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: StitchColors.courtNavy,
                        fontWeight: FontWeight.bold,
                        height: 1.42,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'आपकी चैंबर गोपनीयता एवं मुवक्किल के अधिकारों की सुरक्षा भारत सरकार के डीपीसपी अधिनियम 2023 के तहत प्रबंधित है।',
                  style: TextStyle(fontSize: 13, color: StitchColors.textSecondary, height: 1.42),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: StitchColors.verifiedGreen),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'बार काउंसिल ऑफ इंडिया नियम 36 प्रमाणन',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (_bciStatement != null) ...[
                          Text(
                            'अधिवक्ता: ${_bciStatement!["advocate_name"]}',
                            style: const TextStyle(fontWeight: FontWeight.bold, height: 1.42),
                          ),
                          Text(
                            'पंजीकरण संख्या: ${_bciStatement!["bar_council_number"]} (${_bciStatement!["enrolled_state"]})',
                            style: const TextStyle(height: 1.40),
                          ),
                          const SizedBox(height: 10),
                          ...(_bciStatement!["statutory_certifications"] as List<dynamic>).map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('✓ ', style: TextStyle(color: StitchColors.verifiedGreen, fontWeight: FontWeight.bold, height: 1.40)),
                                  Expanded(child: Text(c, style: const TextStyle(fontSize: 12.5, height: 1.42))),
                                ],
                              ),
                            ),
                          ),
                        ] else
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'डेटा प्रदाता अधिकार (Data Principal Rights)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: StitchColors.courtNavy,
                        fontWeight: FontWeight.bold,
                        height: 1.42,
                      ),
                ),
                const SizedBox(height: 10),

                // Right to Access & Export Data Bundle
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: StitchColors.borderSubtle),
                  ),
                  tileColor: Colors.white,
                  leading: const Icon(Icons.download_rounded, color: StitchColors.courtNavy),
                  title: const Text('चैंबर डेटा बंडल डाउनलोड करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42)),
                  subtitle: const Text('धारा 11: समस्त केस, कार्यवाहियां एवं ऑडिट लॉग JSON प्रारूप में प्राप्त करें', style: TextStyle(fontSize: 11.5, height: 1.40)),
                  trailing: _isExporting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _isExporting ? null : _exportDataBundle,
                ),
                const SizedBox(height: 12),

                // Right to Erasure / Hard Delete
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  tileColor: Colors.red.shade50,
                  leading: const Icon(Icons.delete_forever_rounded, color: StitchColors.alertCrimson),
                  title: const Text(
                    'स्थायी डेटा विलोपन (Right to Erasure)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: StitchColors.alertCrimson, height: 1.42),
                  ),
                  subtitle: const Text('धारा 8(7): अपने सभी केस एवं पहचान को सर्वर से स्थायी रूप से मिटाएं', style: TextStyle(fontSize: 11.5, height: 1.40)),
                  trailing: _isErasing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_ios, size: 16, color: StitchColors.alertCrimson),
                  onTap: _isErasing ? null : _confirmCompleteErasure,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
