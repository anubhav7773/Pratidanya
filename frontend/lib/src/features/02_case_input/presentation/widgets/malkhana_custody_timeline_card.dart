import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../domain/malkhana_models.dart';

class MalkhanaCustodyTimelineCard extends StatelessWidget {
  final MalkhanaAuditResult audit;

  const MalkhanaCustodyTimelineCard({super.key, required this.audit});

  void _showApplicationModal(BuildContext context, String draftText) {
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
                    'धारा 254 BNSS साक्ष्य तलब प्रार्थना पत्र',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
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
                child: SelectableText(
                  draftText,
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
    final hasBreak = audit.hasFatalTamperingRisk;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: hasBreak ? StitchColors.alertCrimson : StitchColors.borderSubtle,
          width: hasBreak ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Chain Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        hasBreak ? Icons.link_off : Icons.link,
                        color: hasBreak ? StitchColors.alertCrimson : StitchColors.verifiedGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'मालखाना रजिस्टर 19 व FSL अभिरक्षा शृंखला',
                          style: TextStyle(
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
                    color: hasBreak ? StitchColors.alertCrimsonBg : StitchColors.verifiedGreenBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasBreak ? 'कड़ी खंडित (Chain Broken)' : 'अभिरक्षा सुरक्षित',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: hasBreak ? StitchColors.alertCrimson : StitchColors.verifiedGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Delay metric badge
            Text(
              'FSL प्रेषण विलंब: ${audit.fslDispatchDelayDays} दिन (NCB स्थायी आदेश 1/88: अधिकतम 72 घंटे)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: audit.fslDispatchDelayDays > 3 ? FontWeight.bold : FontWeight.normal,
                color: audit.fslDispatchDelayDays > 3 ? StitchColors.alertCrimson : StitchColors.textSecondary,
              ),
            ),
            const Divider(height: 18),

            // Vulnerabilities List
            const Text(
              'पहचानी गई अभिरक्षा विधिक खामियां:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            ...audit.fatalVulnerabilities.map(
              (v) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.statutoryViolationHindi,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      v.impactAnalysisHindi,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Strategy recommendation
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                audit.actionableDefenseStrategyHindi,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Button: View Sec 254 BNSS Summoning Application
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasBreak ? StitchColors.alertCrimson : StitchColors.courtNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.description, size: 18),
                label: const Text(
                  'धारा 254 BNSS साक्ष्य तलब प्रार्थना पत्र देखें',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showApplicationModal(context, audit.applicationSec254BnssDraftHindi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
