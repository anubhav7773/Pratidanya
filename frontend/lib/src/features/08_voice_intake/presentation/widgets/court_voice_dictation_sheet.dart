import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../controllers/voice_intake_controller.dart';
import '../../domain/voice_intake_result.dart';

class CourtVoiceDictationSheet extends ConsumerWidget {
  final String? caseId;
  final ValueChanged<VoiceDictationResult> onDictationTransferred;

  const CourtVoiceDictationSheet({
    super.key,
    this.caseId,
    required this.onDictationTransferred,
  });

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceIntakeControllerProvider);
    final controller = ref.read(voiceIntakeControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: StitchColors.courtNavy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.mic, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'न्यायालयीन हिंदी वॉयस डिक्टेशन',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: StitchColors.courtNavy,
                          height: 1.42,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.cancelRecording();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'केस के तथ्य, मु.अ.सं., थाना, धाराएं व घटनाक्रम बोलकर रिकॉर्ड करें। सिस्टम स्वतः विधिक इकाइयों को पहचान लेगा।',
            style: TextStyle(fontSize: 12.5, color: StitchColors.textSecondary, height: 1.40),
          ),
          const Divider(height: 24),

          // Center Animated Recording State
          if (voiceState.recordingState == VoiceRecordingState.idle) ...[
            const Icon(Icons.mic_none_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'डिक्टेशन शुरू करने के लिए नीचे दिए गए बटन को दबाएं',
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.40),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: StitchColors.courtNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.mic),
              label: const Text('डिक्टेशन प्रारंभ करें', style: TextStyle(fontWeight: FontWeight.bold, height: 1.40)),
              onPressed: () => controller.startRecording(),
            ),
          ] else if (voiceState.recordingState == VoiceRecordingState.recording) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.mic, color: Colors.red, size: 40),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatTimer(voiceState.durationSeconds),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red, height: 1.40),
            ),
            const SizedBox(height: 4),
            const Text('ऑडियो रिकॉर्ड हो रहा है... सुस्पष्ट बोलें', style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.40)),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: () => controller.cancelRecording(),
                  child: const Text('रद्द करें', style: TextStyle(height: 1.40)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StitchColors.verifiedGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.stop),
                  label: const Text('रिकॉर्डिंग समाप्त करें एवं विश्लेषण करें', style: TextStyle(height: 1.40)),
                  onPressed: () => controller.stopAndProcessRecording(caseId: caseId),
                ),
              ],
            ),
          ] else if (voiceState.recordingState == VoiceRecordingState.processing) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Gemini 1.5 Flash न्यायालयीन हिंदी प्रतिलेख एवं विधिक इकाइयां तैयार कर रहा है...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: StitchColors.courtNavy, height: 1.42),
            ),
            const SizedBox(height: 6),
            const Text(
              'धारा 8(7) DPDP अनुपालन: ऑडियो इन-मेमोरी प्रोसेस होने के बाद स्वतः नष्ट हो जाएगा।',
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.40),
            ),
          ] else if (voiceState.recordingState == VoiceRecordingState.completed && voiceState.result != null) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: StitchColors.borderSubtle),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'निष्कर्षित विधिक इकाइयां:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StitchColors.courtNavy, height: 1.42),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (voiceState.result!.extractedEntities.firNumber != null)
                          Chip(label: Text('मु.अ.सं.: ${voiceState.result!.extractedEntities.firNumber}', style: const TextStyle(height: 1.40))),
                        if (voiceState.result!.extractedEntities.policeStation != null)
                          Chip(label: Text('थाना: ${voiceState.result!.extractedEntities.policeStation}', style: const TextStyle(height: 1.40))),
                        ...voiceState.result!.extractedEntities.sections.map((s) => Chip(label: Text(s, style: const TextStyle(height: 1.40)))),
                      ],
                    ),
                    const Divider(height: 18),
                    const Text(
                      'अक्षरशः प्रतिलेख (Verbatim):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StitchColors.courtNavy, height: 1.42),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voiceState.result!.verbatimTranscriptHindi,
                      style: const TextStyle(fontSize: 12.5, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: StitchColors.verifiedGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('इन तथ्यों को केस फॉर्म में स्थानांतरित करें', style: TextStyle(fontWeight: FontWeight.bold, height: 1.40)),
                onPressed: () {
                  onDictationTransferred(voiceState.result!);
                  Navigator.pop(context);
                },
              ),
            ),
          ] else if (voiceState.recordingState == VoiceRecordingState.error) ...[
            const Icon(Icons.error_outline, size: 48, color: StitchColors.alertCrimson),
            const SizedBox(height: 8),
            Text(
              voiceState.errorMessage ?? 'अज्ञात वॉयस त्रुटि',
              textAlign: TextAlign.center,
              style: const TextStyle(color: StitchColors.alertCrimson, fontSize: 13, height: 1.40),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => controller.startRecording(),
              child: const Text('पुनः प्रयास करें', style: TextStyle(height: 1.40)),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
