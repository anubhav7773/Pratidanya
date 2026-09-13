import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../domain/medico_legal_models.dart';

class MedicoLegalMatrixViewer extends StatelessWidget {
  final MedicalMatrixAuditResult matrix;

  const MedicoLegalMatrixViewer({super.key, required this.matrix});

  void _showFullDraftSheet(BuildContext context, String draftText) {
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
                const Expanded(
                  child: Text('विधिक बहस तर्क (राम नारायण सिंह सिद्धांत)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: draftText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('बहस पत्र क्लिपबोर्ड पर कॉपी हो गया')),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: matrix.hasFatalConflict ? StitchColors.alertCrimson : StitchColors.borderSubtle,
          width: matrix.hasFatalConflict ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Fatal Conflict Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        matrix.hasFatalConflict ? Icons.medical_services : Icons.check_circle,
                        color: matrix.hasFatalConflict ? StitchColors.alertCrimson : StitchColors.verifiedGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'चिकित्सीय बनाम प्रत्यक्षदर्शी साक्ष्य मैट्रिक्स',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StitchColors.courtNavy),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: matrix.hasFatalConflict ? StitchColors.alertCrimsonBg : StitchColors.verifiedGreenBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    matrix.hasFatalConflict ? 'घातक अंतर्विरोध (Fatal Conflict)' : 'सुसंगत साक्ष्य',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: matrix.hasFatalConflict ? StitchColors.alertCrimson : StitchColors.verifiedGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'पोस्टमार्टम आख्या संख्या: ${matrix.pmrNumber}',
              style: const TextStyle(fontSize: 12, color: StitchColors.textSecondary),
            ),
            const Divider(height: 20),

            // Discrepancy Findings
            const Text('पहचाने गए असमाधेय वैज्ञानिक अंतर्विरोध:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...matrix.irreconcilableConflicts.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.severity == 'FATAL_CONTRADICTION' ? Colors.red.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.parameter,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: c.severity == 'FATAL_CONTRADICTION' ? Colors.red.shade900 : Colors.orange.shade900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(c.biomechanicalAuthority, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('• ${c.ocularClaim}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('• ${c.autopsyFinding}', style: const TextStyle(fontSize: 12, color: StitchColors.courtNavy)),
                      const SizedBox(height: 4),
                      Text(
                        c.scientificVerdictHindi,
                        style: TextStyle(fontSize: 11.5, color: Colors.red.shade900, height: 1.35),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),

            // Cross-Examination Questions Preview
            if (matrix.crossExaminationCrossfireQuestions.isNotEmpty) ...[
              const Text('चिकित्साधिकारी हेतु लक्षित जिरह प्रश्न (Crossfire Questions):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ...matrix.crossExaminationCrossfireQuestions.take(3).map((q) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Q. ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                        Expanded(
                          child: Text(q, style: const TextStyle(fontSize: 12, height: 1.35)),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 14),

            // Action Button: View Full Argument Draft
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: matrix.hasFatalConflict ? StitchColors.alertCrimson : StitchColors.courtNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.gavel, size: 18),
                label: const Text('विधिक बहस तर्क (Argument Draft) देखें व प्रिंट करें', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () => _showFullDraftSheet(context, matrix.writtenMedicalArgumentDraftHindi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
