import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../domain/witness_impeachment_models.dart';

class WitnessImpeachmentGridWidget extends StatelessWidget {
  final WitnessImpeachmentAuditResult audit;

  const WitnessImpeachmentGridWidget({super.key, required this.audit});

  void _showScriptModal(BuildContext context, String scriptText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'तहसीलदार सिंह विधिक जिरह स्क्रिप्ट',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: scriptText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('जिरह स्क्रिप्ट कॉपी हो गई')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  scriptText,
                  style: const TextStyle(fontSize: 12.5, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: audit.hasFatalContradictions ? StitchColors.alertCrimson : StitchColors.borderSubtle,
          width: audit.hasFatalContradictions ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Witness Code & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        audit.hasFatalContradictions ? Icons.warning_amber_rounded : Icons.fact_check,
                        color: audit.hasFatalContradictions ? StitchColors.alertCrimson : StitchColors.courtNavy,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'साक्षी अंतर्विरोध ग्रिड: ${audit.witnessCode} (${audit.witnessName})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: StitchColors.courtNavy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: audit.hasFatalContradictions ? StitchColors.alertCrimsonBg : StitchColors.verifiedGreenBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    audit.hasFatalContradictions ? 'गंभीर सुधार / अंतर्विरोध' : 'सुसंगत बयान',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: audit.hasFatalContradictions ? StitchColors.alertCrimson : StitchColors.verifiedGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'धारा 148 BSA / धारा 145 IEA सपठित तहसीलदार सिंह (1959) सिद्धांत',
              style: TextStyle(fontSize: 11.5, color: StitchColors.textSecondary),
            ),
            const Divider(height: 18),

            // Contradiction Items
            ...audit.gridAnalysis.map((item) {
              if (item.classification == 'CORROBORATING_PASSAGE') {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'बयानों में कोई गंभीर सुधार अथवा अंतर्विरोध नहीं मिला।',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.markedExhibitIdentifier,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.classification == 'MATERIAL_IMPROVEMENT_AMOUNTING_TO_CONTRADICTION'
                                ? 'महत्वपूर्ण सुधार (Material Improvement)'
                                : 'प्रत्यक्ष अंतर्विरोध (Contradiction)',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• न्यायालय में कथन: "${item.chiefDeposition}"',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '• पुलिस बयान (161 CrPC): "${item.statement161}"',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    if (item.statement164 != null) ...[
                      Text(
                        '• मजिस्ट्रेट बयान (164 CrPC): "${item.statement164}"',
                        style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'जिरह प्रश्न: ${item.statutoryConfrontationScriptHindi}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.brown.shade900,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // IO Reminders Block
            if (audit.ioCrossExaminationReminders.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'विवेचक (I.O.) से पूछने हेतु प्रदर्श साबित करने के प्रश्न:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...audit.ioCrossExaminationReminders
                        .take(2)
                        .map((rem) => Text('• $rem', style: const TextStyle(fontSize: 11.5, height: 1.3))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Action Button: View Master Confrontation Script
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: audit.hasFatalContradictions ? StitchColors.alertCrimson : StitchColors.courtNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.record_voice_over, size: 18),
                label: const Text(
                  'संपूर्ण जिरह स्क्रिप्ट व प्रदर्श सूची देखें',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showScriptModal(context, audit.confrontationMasterScriptHindi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
