import 'package:flutter/material.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../domain/default_bail_models.dart';

class DefaultBailTrackerCard extends StatelessWidget {
  final DefaultBailAuditResult audit;
  final VoidCallback onOpenPetitionViewer;

  const DefaultBailTrackerCard({
    super.key,
    required this.audit,
    required this.onOpenPetitionViewer,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (audit.daysElapsedInCustody / audit.statutoryThresholdDays).clamp(0.0, 1.0);
    final isReady = audit.isDefaultBailCrystallized;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: isReady ? StitchColors.alertCrimson : StitchColors.borderSubtle,
          width: isReady ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status Badge and Threshold
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isReady ? Icons.alarm_on : Icons.hourglass_bottom,
                        color: isReady ? StitchColors.alertCrimson : StitchColors.courtNavy,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'सांविधिक डिफ़ॉल्ट जमानत ट्रैकर',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isReady ? StitchColors.alertCrimson : StitchColors.courtNavy,
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
                    color: isReady ? StitchColors.alertCrimsonBg : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isReady ? 'अधिकार प्रोद्भूत (Eligible)' : '${audit.daysElapsedInCustody}/${audit.statutoryThresholdDays} दिन',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isReady ? StitchColors.alertCrimson : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isReady
                      ? StitchColors.alertCrimson
                      : progress > 0.8
                          ? Colors.orange
                          : StitchColors.courtNavy,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Section 187 Police Custody Alert
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: audit.policeCustodyWindowExpired ? Colors.amber.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    audit.policeCustodyWindowExpired ? Icons.info_outline : Icons.security,
                    size: 16,
                    color: audit.policeCustodyWindowExpired ? Colors.amber.shade900 : StitchColors.courtNavy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      audit.policeCustodyAlertHindi,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: audit.policeCustodyWindowExpired ? Colors.amber.shade900 : StitchColors.courtNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Incomplete Chargesheet Alert
            if (audit.isChargesheetIncomplete) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StitchColors.alertCrimsonBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: StitchColors.alertCrimson),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        audit.chargesheetDefectSummaryHindi,
                        style: const TextStyle(fontSize: 11.5, color: StitchColors.alertCrimson, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady ? StitchColors.alertCrimson : StitchColors.courtNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.description, size: 18),
                label: Text(
                  isReady ? 'डिफ़ॉल्ट जमानत प्रार्थना पत्र देखें व प्रिंट करें' : 'सांविधिक विधिक ड्राफ्ट का पूर्वावलोकन',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: onOpenPetitionViewer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
