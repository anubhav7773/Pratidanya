import 'package:flutter/material.dart';
import '../../core/theme/stitch_colors.dart';

class CriminalStageStepper extends StatelessWidget {
  final String currentStage; // 'REMAND', 'BAIL', 'CHARGESHEET', 'CHARGES_FRAMED', 'EVIDENCE'

  static const List<Map<String, String>> stages = [
    {'key': 'REMAND', 'label': 'रिमांड'},
    {'key': 'BAIL', 'label': 'जमानत'},
    {'key': 'CHARGESHEET', 'label': 'आरोप पत्र'},
    {'key': 'CHARGES_FRAMED', 'label': 'आरोप तय'},
    {'key': 'EVIDENCE', 'label': 'साक्ष्य'},
  ];

  const CriminalStageStepper({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final currentIndex = stages.indexWhere((s) => s['key'] == currentStage);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: StitchColors.borderSubtle),
      ),
      child: Row(
        children: List.generate(stages.length * 2 - 1, (index) {
          if (index.isOdd) {
            final prevStageIndex = index ~/ 2;
            final isPassed = prevStageIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 2.0,
                color: isPassed ? StitchColors.courtNavy : StitchColors.borderSubtle,
              ),
            );
          }

          final stageIndex = index ~/ 2;
          final isCompleted = stageIndex < currentIndex;
          final isCurrent = stageIndex == currentIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? StitchColors.courtNavy
                      : (isCompleted ? StitchColors.verifiedGreen : Colors.white),
                  border: Border.all(
                    color: isCurrent || isCompleted
                        ? StitchColors.courtNavy
                        : StitchColors.borderSubtle,
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : Text(
                          '${stageIndex + 1}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : StitchColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stages[stageIndex]['label']!,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? StitchColors.courtNavy : StitchColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
