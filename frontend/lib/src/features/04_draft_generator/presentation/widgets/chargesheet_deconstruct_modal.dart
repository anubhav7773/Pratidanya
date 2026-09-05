import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../02_case_input/data/nlp_chargesheet_repository.dart';

class ChargesheetDeconstructModal extends ConsumerStatefulWidget {
  final String caseId;
  final ValueChanged<List<String>> onFactsExtracted;

  const ChargesheetDeconstructModal({
    super.key,
    required this.caseId,
    required this.onFactsExtracted,
  });

  @override
  ConsumerState<ChargesheetDeconstructModal> createState() => _ChargesheetDeconstructModalState();
}

class _ChargesheetDeconstructModalState extends ConsumerState<ChargesheetDeconstructModal> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  ChargesheetDeconstructResult? _result;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _deconstruct() async {
    final text = _textController.text.trim();
    if (text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('विश्लेषण हेतु न्यूनतम 50 अक्षर आवश्यक हैं।')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(nlpChargesheetRepositoryProvider);
      final res = await repo.deconstructChargesheet(caseId: widget.caseId, text: text);
      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NLP त्रुटि: $e'), backgroundColor: StitchColors.alertCrimson),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'अभियोग पत्र विश्लेषण (OpenNyAI)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: StitchColors.courtNavy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'पुलिस आरोप-पत्र / फर्द बरामदगी का पाठ चिपकाएं। सिस्टम स्वचालित रूप से तथ्य व धाराएं पृथक करेगा।',
            style: TextStyle(fontSize: 12.5, color: StitchColors.textSecondary),
          ),
          const Divider(height: 20),
          if (_result == null) ...[
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'आरोप पत्र का पाठ यहाँ चिपकाएं (Devanagari / English)...',
                  contentPadding: const EdgeInsets.all(14.0),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: StitchColors.borderSubtle),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: StitchColors.courtNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'विश्लेषण जारी है...' : 'तथ्य निष्कर्षित करें'),
                onPressed: _isLoading ? null : _deconstruct,
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: StitchColors.verifiedGreenBg,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'विश्लेषण संपन्न: ${_result!.totalSentencesProcessed} वाक्यों से ${_result!.factsExtracts.length} मुख्य तथ्य पाए गए।',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: StitchColors.verifiedGreen, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('पहचानी गई धाराएं एवं गवाह:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StitchColors.chamberSlate)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      ..._result!.provisionsDetected.map((p) => Chip(label: Text(p, style: const TextStyle(fontSize: 11)))),
                      ..._result!.witnessesDetected.map((w) => Chip(label: Text('साक्षी: $w', style: const TextStyle(fontSize: 11)))),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('निष्कर्षित प्रासंगिक तथ्य (Extracted Facts):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StitchColors.chamberSlate)),
                  const SizedBox(height: 8),
                  ..._result!.factsExtracts.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(f, style: const TextStyle(fontSize: 13, height: 1.45))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: StitchColors.verifiedGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                ),
                onPressed: () {
                  widget.onFactsExtracted(_result!.factsExtracts);
                  Navigator.pop(context);
                },
                child: const Text('इन तथ्यों को ड्राफ्ट स्टूडियो में जोड़ें', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
