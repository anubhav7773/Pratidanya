import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../data/courtroom_repository.dart';
import '../../domain/courtroom_tactics_models.dart';

class LiveCourtroomHUDWidget extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String district;

  const LiveCourtroomHUDWidget({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.district,
  });

  @override
  ConsumerState<LiveCourtroomHUDWidget> createState() => _LiveCourtroomHUDWidgetState();
}

class _LiveCourtroomHUDWidgetState extends ConsumerState<LiveCourtroomHUDWidget> {
  final _argumentInputController = TextEditingController();
  bool _isLoading = false;
  EdgeOralPromptResult? _promptResult;

  void _triggerOralPrompt() async {
    final text = _argumentInputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(courtroomRepositoryProvider);
      final res = await repo.requestEdgeOralPrompt(
        caseId: widget.caseId,
        adversaryArgumentRawText: text,
      );

      setState(() {
        _promptResult = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('प्रत्युत्तर निर्माण त्रुटि: $e'), backgroundColor: StitchColors.alertCrimson),
        );
      }
    }
  }

  @override
  void dispose() {
    _argumentInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: StitchColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Real-Time HUD Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mic_none, color: StitchColors.courtNavy, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'लाइव कोर्टरूम ओरल प्रॉम्टर (Edge HUD)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: StitchColors.courtNavy),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.green, size: 14),
                      SizedBox(width: 2),
                      Text(
                        '< 450ms',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'अभियोजन पक्ष की बहस दर्ज करें या बोलें; सिस्टम तुरंत काउंटर-आर्गुमेंट व नजीर स्क्रीन पर प्रस्तुत करेगा:',
              style: TextStyle(fontSize: 11.5, color: StitchColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Input Field
            TextField(
              controller: _argumentInputController,
              decoration: InputDecoration(
                hintText: 'उदा. "अभियुक्त से कमर्शियल मात्रा बरामद हुई है, इसलिए धारा 37 में बेल नहीं मिल सकती..."',
                hintStyle: const TextStyle(fontSize: 12),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: StitchColors.courtNavy),
                  onPressed: _isLoading ? null : _triggerOralPrompt,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Display HUD Prompts
            if (_promptResult != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'पहचाना गया अभियोजन तर्क: ${_promptResult!.detectedAdversarialRatio}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 8),

              ..._promptResult!.immediateCounterRatios.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                item.statutoryLever,
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16, color: StitchColors.courtNavy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: item.promptTextHindi));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('तर्क क्लिपबोर्ड पर कॉपी हो गया')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'बोलने हेतु विधिक तर्क: "${item.promptTextHindi}"',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.35),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'उद्धृत नजीर: ${item.leadCitation}',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  )),

              // Latency footer
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'प्रतिक्रिया समय: ${_promptResult!.latencyMs["total_latency_ms"]} ms',
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
