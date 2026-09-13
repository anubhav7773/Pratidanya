import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../domain/leading_question_models.dart';

class CrossExamCardDeckWidget extends StatefulWidget {
  final LeadingQuestionResult result;

  const CrossExamCardDeckWidget({super.key, required this.result});

  @override
  State<CrossExamCardDeckWidget> createState() => _CrossExamCardDeckWidgetState();
}

class _CrossExamCardDeckWidgetState extends State<CrossExamCardDeckWidget> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.result.questionTrees.length;
    if (totalSteps == 0) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.result.questionTrees[_currentIndex];

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
            // Header: Theory, Witness & Step Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'साक्षी: ${widget.result.witnessName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: StitchColors.courtNavy,
                        ),
                      ),
                      Text(
                        widget.result.defenseTheory.replaceAll('_', ' '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.brown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: StitchColors.courtNavy,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'प्रश्न ${_currentIndex + 1} / $totalSteps',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Card Body: Question Box with Target Objective
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'उद्देश्य: ${currentStep.objectiveHindi}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.brown),
                        tooltip: 'प्रश्न कॉपी करें',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: currentStep.leadingQuestionHindi));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('जिरह प्रश्न कॉपी हो गया')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // The Leading Question
                  Text(
                    'Q. "${currentStep.leadingQuestionHindi}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Expected Answer Tag
                  Row(
                    children: [
                      const Text(
                        'अपेक्षित विधिक उत्तर: ',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: currentStep.expectedAnswer == 'YES' ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentStep.expectedAnswer,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            color: currentStep.expectedAnswer == 'YES' ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Trap Mitigation Follow-up
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'जाल शमन (Trap Mitigation):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.red),
                  ),
                  const SizedBox(height: 2),
                  Text(currentStep.trapMitigationHindi, style: const TextStyle(fontSize: 11.5, height: 1.3)),
                  const SizedBox(height: 6),
                  const Text(
                    'दस्तावेजी प्रहार (Pivot Tactic):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: StitchColors.courtNavy),
                  ),
                  const SizedBox(height: 2),
                  Text(currentStep.pivotTacticHindi, style: const TextStyle(fontSize: 11.5, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Deck Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('पिछला प्रश्न'),
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StitchColors.courtNavy,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(_currentIndex < totalSteps - 1 ? 'अगला प्रश्न' : 'समाप्त'),
                  onPressed: _currentIndex < totalSteps - 1
                      ? () => setState(() => _currentIndex++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
