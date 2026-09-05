import 'package:flutter/material.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../domain/precedent_citation.dart';

class PrecedentCitationCard extends StatelessWidget {
  final PrecedentCitation citation;
  final ValueChanged<bool?> onVerificationChanged;

  const PrecedentCitationCard({
    super.key,
    required this.citation,
    required this.onVerificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accuracyPercent = (citation.similarityScore * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: StitchColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Case Title & Accuracy Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    citation.caseTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: StitchColors.verifiedGreenBg,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: StitchColors.verifiedGreen, width: 0.8),
                  ),
                  child: Text(
                    'सटीकता: $accuracyPercent%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: StitchColors.verifiedGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Row 2: Court & Date
            Text(
              '${citation.courtName} | निर्णय तिथि: ${citation.judgmentDate}',
              style: const TextStyle(fontSize: 12, color: StitchColors.textSecondary),
            ),
            const Divider(height: 18),

            // Row 3: Ratio / Headnote
            const Text(
              'विधिक निष्कर्ष (Legal Ratio):',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: StitchColors.chamberSlate),
            ),
            const SizedBox(height: 4),
            Text(
              citation.headnoteHindi,
              style: const TextStyle(fontSize: 13.5, height: 1.45, color: StitchColors.textPrimary),
            ),
            const SizedBox(height: 10),

            // Row 4: Verbatim paragraph quote
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'उद्धृत पैरा ${citation.paragraphNumber ?? "N/A"}: "${citation.verbatimText}"',
                style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, height: 1.4, color: StitchColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),

            // Row 5: Verified Source Link & Verification Gate Checkbox
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    // Opens verifiable official judgment in browser/PDF viewer
                  },
                  child: const Text(
                    'सत्यापित स्रोत रिकॉर्ड देखें ↗',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: citation.isManuallyVerified,
                      activeColor: StitchColors.verifiedGreen,
                      onChanged: onVerificationChanged,
                    ),
                    const Text('सत्यापित किया', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
