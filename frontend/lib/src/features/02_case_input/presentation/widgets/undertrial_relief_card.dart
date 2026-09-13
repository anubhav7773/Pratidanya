import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../domain/undertrial_models.dart';

class UndertrialReliefCard extends StatelessWidget {
  final UndertrialReliefAuditResult result;

  const UndertrialReliefCard({super.key, required this.result});

  void _showDraftModal(BuildContext context, String title, String draftText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: draftText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('प्रार्थना पत्र क्लिपबोर्ड पर कॉपी हो गया')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(draftText, style: const TextStyle(fontSize: 12.5, height: 1.45)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thresholdSafe = result.thresholdMonths <= 0 ? 1.0 : result.thresholdMonths;
    final progress = (result.actualDetentionServedMonths / thresholdSafe).clamp(0.0, 1.0);
    final isEligible = result.isReliefApplicable;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: isEligible ? StitchColors.verifiedGreen : StitchColors.borderSubtle,
          width: isEligible ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and Eligibility Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEligible ? Icons.verified : Icons.lock_clock,
                      color: isEligible ? StitchColors.verifiedGreen : StitchColors.courtNavy,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'धारा 479 BNSS विचाराधीन राहत',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isEligible ? StitchColors.verifiedGreen : StitchColors.courtNavy,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEligible
                        ? StitchColors.verifiedGreenBg
                        : result.isDisqualified
                            ? StitchColors.alertCrimsonBg
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isEligible
                        ? 'रिहाई योग्य (${result.statutoryThresholdFraction} पूर्ण)'
                        : result.isDisqualified
                            ? 'अपात्र (Disqualified)'
                            : '${result.actualDetentionServedMonths}/${result.thresholdMonths} माह',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isEligible
                          ? StitchColors.verifiedGreen
                          : result.isDisqualified
                              ? StitchColors.alertCrimson
                              : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isEligible
                      ? StitchColors.verifiedGreen
                      : result.isDisqualified
                          ? StitchColors.alertCrimson
                          : StitchColors.courtNavy,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Stats breakdown
            Text(
              'वास्तविक अभिरक्षा: ${result.actualDetentionServedMonths} माह | सांविधिक आवश्यकता: ${result.thresholdMonths} माह (${result.statutoryThresholdFraction} भाग)',
              style: const TextStyle(fontSize: 12, color: StitchColors.textSecondary),
            ),
            if (result.overstayMonths > 0) ...[
              const SizedBox(height: 4),
              Text(
                'सांविधिक सीमा से अधिक निरुद्धि (Overstay): ${result.overstayMonths} माह',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: StitchColors.alertCrimson),
              ),
            ],
            const SizedBox(height: 10),

            // Retrospective Supreme Court Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                result.retrospectiveMandateTextHindi,
                style: TextStyle(fontSize: 11.5, color: Colors.blue.shade900, height: 1.3),
              ),
            ),

            if (result.disqualificationReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StitchColors.alertCrimsonBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.disqualificationReason!,
                  style: const TextStyle(fontSize: 11.5, color: StitchColors.alertCrimson),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Dual Action Buttons: Court Application & Section 479(3) Jail Notice
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEligible ? StitchColors.verifiedGreen : StitchColors.courtNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('न्यायालय प्रार्थना पत्र', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showDraftModal(
                      context,
                      'न्यायालय जमानत प्रार्थना पत्र (धारा 479 BNSS)',
                      result.courtApplicationDraftHindi,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.mark_email_read, size: 16),
                    label: const Text('जेल अधीक्षक नोटिस', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showDraftModal(
                      context,
                      'धारा 479(3) जेल अधीक्षक विधिक सूचना',
                      result.jailSuperintendentNoticeDraftHindi,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
