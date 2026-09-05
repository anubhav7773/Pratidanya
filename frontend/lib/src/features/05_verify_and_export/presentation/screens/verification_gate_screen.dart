import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../01_onboarding/presentation/controllers/auth_controller.dart';
import '../../../02_case_input/presentation/controllers/case_controller.dart';
import '../../../04_draft_generator/presentation/controllers/drafting_controller.dart';
import '../../domain/verified_export_payload.dart';
import '../../data/court_pdf_builder.dart';
import '../controllers/verification_controller.dart';

final verificationNotifierProvider = StateNotifierProvider.autoDispose<VerificationNotifier, VerificationGateState>((ref) {
  final draft = ref.watch(draftingControllerProvider).valueOrNull;
  final citationIds = draft?.citedPrecedents.map((c) => c.citationId).toList() ?? [];
  final groundsCount = draft?.statutoryGrounds.length ?? 0;

  return VerificationNotifier(
    citationIds: citationIds,
    groundsCount: groundsCount,
  );
});

class VerificationGateScreen extends ConsumerWidget {
  final String caseId;

  const VerificationGateScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateState = ref.watch(verificationNotifierProvider);
    final gateNotifier = ref.read(verificationNotifierProvider.notifier);
    final draft = ref.watch(draftingControllerProvider).valueOrNull;
    final cases = ref.watch(caseListProvider).valueOrNull;
    final profile = ref.watch(currentAdvocateProfileProvider).valueOrNull;

    if (draft == null || cases == null || profile == null) {
      return const Scaffold(body: Center(child: Text('डेटा लोड करने में असमर्थ।')));
    }

    final currentCase = cases.firstWhere((c) => c.id == caseId, orElse: () => cases.first);

    return Scaffold(
      appBar: AppBar(
        title: const Text('विधिक सत्यापन गेट (Section 35 Gate)'),
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: StitchColors.unverifiedAmberBg,
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: StitchColors.unverifiedAmber, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'अधिवक्ता आचार संहिता: न्यायालय में प्रस्तुत करने से पूर्व प्रत्येक आधार एवं विधिक मिसाल का स्वतंत्र परीक्षण अनिवार्य है।',
                    style: TextStyle(fontSize: 12, color: StitchColors.unverifiedAmber, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  '1. विधिक आधारों का सत्यापन (${draft.statutoryGrounds.length} आधार)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: StitchColors.courtNavy),
                ),
                const SizedBox(height: 8),
                ...draft.statutoryGrounds.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final text = entry.value;
                  final isChecked = gateState.verifiedGrounds[idx] ?? false;

                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: StitchColors.verifiedGreen,
                    contentPadding: EdgeInsets.zero,
                    title: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.45)),
                    subtitle: Text('आधार #${idx + 1}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    onChanged: (val) => gateNotifier.toggleGround(idx, val ?? false),
                  );
                }),
                const Divider(height: 24),
                Text(
                  '2. उद्धृत निर्णयों का सत्यापन (${draft.citedPrecedents.length} मिसालें)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: StitchColors.courtNavy),
                ),
                const SizedBox(height: 8),
                if (draft.citedPrecedents.isEmpty)
                  const Text('इस ड्राफ्ट में कोई केस-लॉ उद्धृत नहीं है।', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...draft.citedPrecedents.map((prec) {
                    final isChecked = gateState.verifiedCitations[prec.citationId] ?? false;
                    return CheckboxListTile(
                      value: isChecked,
                      activeColor: StitchColors.verifiedGreen,
                      contentPadding: EdgeInsets.zero,
                      title: Text(prec.caseTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('"${prec.quotedPassage}"', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
                      onChanged: (val) => gateNotifier.toggleCitation(prec.citationId, val ?? false),
                    );
                  }),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: StitchColors.borderSubtle),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: CheckboxListTile(
                    value: gateState.statutoryDeclarationAccepted,
                    activeColor: StitchColors.courtNavy,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'मैं प्रमाणित करता हूँ कि मैंने सभी तथ्यों व निर्णयों का व्यक्तिगत रूप से परीक्षण किया है और यह ड्राफ्ट मेरे स्वतंत्र विधिक विवेक के अधीन तैयार है।',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: StitchColors.courtNavy),
                    ),
                    onChanged: (val) => gateNotifier.setStatutoryDeclaration(val ?? false),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: gateState.isReadyForExport ? StitchColors.verifiedGreen : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                ),
                icon: Icon(gateState.isReadyForExport ? Icons.print_rounded : Icons.lock_outline_rounded),
                label: Text(
                  gateState.isReadyForExport
                      ? 'न्यायालयीन PDF प्रारूप डाउनलोड करें (1.5" Left Margin)'
                      : 'सत्यापन अधूरा है (${gateState.pendingItemsCount} शेष)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onPressed: gateState.isReadyForExport
                    ? () async {
                        final payload = VerifiedExportPayload(
                          courtHeaderHindi: draft.courtHeader,
                          firNumber: currentCase.firNumber,
                          policeStation: currentCase.policeStation,
                          district: currentCase.district,
                          accusedName: currentCase.accusedName,
                          advocateName: profile.fullName,
                          barCouncilNumber: profile.barCouncilNumber,
                          verifiedGrounds: draft.statutoryGrounds,
                          verifiedCitations: draft.citedPrecedents.map((c) => '${c.caseTitle} (${c.courtName})').toList(),
                          prayerText: 'अतः माननीय न्यायालय से सादर प्रार्थना है कि न्यायहित में आवेदक/अभियुक्त को विचारण के दौरान जमानत पर रिहा करने की कृपा की जाए।',
                          filingDate: DateTime.now(),
                        );

                        final pdfBytes = await CourtPdfBuilder.generateLegalSizeCourtPetition(payload);
                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => pdfBytes,
                          name: 'Bail_Petition_${currentCase.firNumber.replaceAll('/', '_')}.pdf',
                        );
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
