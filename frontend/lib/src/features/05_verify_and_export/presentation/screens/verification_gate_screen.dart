import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/utils/citation_formatter.dart';
import '../../../01_onboarding/presentation/controllers/auth_controller.dart';
import '../../../02_case_input/presentation/controllers/case_controller.dart';
import '../../../04_draft_generator/presentation/controllers/drafting_controller.dart';
import '../../../04_draft_generator/domain/case_analysis_draft.dart';
import '../../domain/verified_export_payload.dart';
import '../../data/court_pdf_builder.dart';
import '../controllers/verification_controller.dart';

final verificationNotifierProvider = StateNotifierProvider.autoDispose<VerificationNotifier, VerificationGateState>((ref) {
  final draft = ref.watch(draftingControllerProvider).valueOrNull;
  final citationIds = draft?.citedPrecedents.map((c) => c.citationId).toList() ?? [];

  // Verification Gate unlocks upon verifying all cited precedents and accepting statutory declaration
  return VerificationNotifier(
    citationIds: citationIds,
    groundsCount: 0,
  );
});

class VerificationGateScreen extends ConsumerWidget {
  final String caseId;

  const VerificationGateScreen({super.key, required this.caseId});

  String _toDevanagari(int n) {
    const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return n.toString().split('').map((ch) => devanagariDigits[int.parse(ch)]).join('');
  }

  Future<void> _openPrecedentSource(BuildContext context, CitedPrecedentItem prec) async {
    final cleanCitation = CitationFormatter.format(prec.citationId);
    final targetUrl = CitationFormatter.getOfficialPortalUrl(prec.citationId, prec.verifiedSourceUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEDFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance, size: 20, color: Color(0xFF0D1C32)),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ई-कोर्ट्स / डिजिटल SCR अभिलेख',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                        ),
                        Text(
                          'माननीय न्यायालय प्रामाणिक न्यायिक नजीर',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              prec.caseTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 14, color: Color(0xFF1F6C3A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'प्रामाणिक नजीर संदर्भ: $cleanCitation',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.gavel, size: 14, color: Color(0xFF44474D)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${prec.courtName} • निर्णय तिथि: ${prec.judgmentDate}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF44474D)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'माननीय न्यायालय द्वारा निर्धारित विधिक सिद्धांत (Ratio Decidendi):',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8FF),
                    border: Border.all(color: const Color(0xFFEAEDFF)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '"${prec.quotedPassage}"',
                    style: const TextStyle(fontSize: 12, height: 1.4, fontStyle: FontStyle.italic, color: Color(0xFF131B2E)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6C3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text(
                  'आधिकारिक पोर्टल पर मूल निर्णय खोलें',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final uri = Uri.parse(targetUrl);
                  try {
                    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                    if (!launched) {
                      await launchUrl(uri, mode: LaunchMode.inAppWebView);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('पोर्टल लिंक: $targetUrl')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateState = ref.watch(verificationNotifierProvider);
    final gateNotifier = ref.read(verificationNotifierProvider.notifier);
    final draft = ref.watch(draftingControllerProvider).valueOrNull;
    final cases = ref.watch(caseListProvider).valueOrNull;
    final profile = ref.watch(currentAdvocateProfileProvider).valueOrNull;

    if (draft == null || cases == null || profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF8FF),
        appBar: AppBar(
          title: const Text('अधिवक्ता विधिक सत्यापन', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF131B2E),
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAEDFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_outlined, size: 48, color: Color(0xFF0D1C32)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'सक्रिय ड्राफ्ट उपलब्ध नहीं है',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'विधिक सत्यापन एवं निर्यात के लिए कृपया पहले ड्राफ्टिंग स्टूडियो में "ड्राफ्ट तैयार करें" दबाएं।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF44474D), height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1C32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('ड्राफ्टिंग स्टूडियो पर वापस जाएं'),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentCase = cases.firstWhere((c) => c.id == caseId, orElse: () => cases.first);
    final totalCitations = draft.citedPrecedents.length;
    final verifiedCitationsCount = gateState.verifiedCitations.values.where((v) => v).length;
    final isFullyVerified = gateState.isReadyForExport;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF131B2E)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEAEDFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'अधिवक्ता विधिक सत्यापन',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'अधिवक्ता अधिनियम, 1961 (धारा 35)',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF44474D)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E7FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, size: 13, color: Color(0xFF1F6C3A)),
                        SizedBox(width: 4),
                        Text(
                          'सुरक्षा द्वार',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Stepper Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0D1C32),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$verifiedCitationsCount',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'सत्यापित नजीरें: $verifiedCitationsCount/$totalCitations',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isFullyVerified ? const Color(0xFFA4F1B2) : const Color(0xFFDAE2FD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isFullyVerified ? 'सत्यापन पूर्ण' : 'अपूर्ण सत्यापन ($verifiedCitationsCount/$totalCitations)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isFullyVerified ? const Color(0xFF1F6C3A) : const Color(0xFF44474D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amber Alert Warning Banner (Strict Section 35 Compliance)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDBD1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A0A00),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.warning, color: Color(0xFFFFDBD1), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3A0A00),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'सांविधिक चेतावनी',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFDBD1)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'धारा 35 - विधिक कदाचार निवारण',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF842503), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'अधिवक्ता सत्यापन अनिवार्य है: न्यायालय में असत्य साक्ष्य या अप्रमाणित नजीर प्रस्तुत करना विधिक कदाचार है।',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3A0A00), height: 1.3),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'एआई द्वारा उद्धृत प्रत्येक न्यायिक नजीर एवं उद्धरण का अधिवक्ता द्वारा व्यक्तिगत विधि परीक्षण आवश्यक है। डिजिटल रिकॉर्ड न्यायमित्र प्रोटोकॉल द्वारा संरक्षित है।',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF842503), height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Case & Draft Docket Brief Card
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFEAEDFF)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.gavel, size: 16, color: Color(0xFF0D1C32)),
                                    SizedBox(width: 6),
                                    Text(
                                      'संबद्ध वाद एवं मसौदा विवरण',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF75777E), letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4F1B2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'सत्र न्यायालय',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF24703E)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${currentCase.accusedName} बनाम उ.प्र. राज्य',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'वाद: मु.अ.सं. ${currentCase.firNumber}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF44474D)),
                                ),
                                const SizedBox(width: 8),
                                const Text('•', style: TextStyle(color: Color(0xFF75777E))),
                                const SizedBox(width: 8),
                                const Text(
                                  'प्रारूप: नियमित जमानत प्रार्थना पत्र',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF44474D)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Central Citation Checklist Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fact_check, size: 18, color: Color(0xFF131B2E)),
                            const SizedBox(width: 6),
                            Text(
                              'नजीर विधिक परीक्षण चेकलिस्ट ($totalCitations)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Icon(Icons.circle, size: 7, color: StitchColors.alertCrimson),
                            SizedBox(width: 4),
                            Text(
                              'अनिवार्य सत्यापन',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: StitchColors.alertCrimson),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Checklist Cards
                    ...draft.citedPrecedents.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final prec = entry.value;
                      final isChecked = gateState.verifiedCitations[prec.citationId] ?? false;

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isChecked ? const Color(0xFF1F6C3A) : const Color(0xFFEAEDFF),
                            width: isChecked ? 1.5 : 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E7FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _toDevanagari(idx + 1),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prec.caseTitle,
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${CitationFormatter.format(prec.citationId)} • ${prec.courtName}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF75777E)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAEDFF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'जमानत सिद्धांत',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF44474D), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Ratio Quote Box
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F3FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.format_quote, size: 16, color: Color(0xFF0D1C32)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '"${prec.quotedPassage}"',
                                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF131B2E), height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Verified Source Link & Clean Legal Citation
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _openPrecedentSource(context, prec),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'मूल निर्णय ई-कोर्ट्स / SCR देखें',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F6C3A),
                                                decoration: TextDecoration.underline,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.open_in_new, size: 13, color: Color(0xFF1F6C3A)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'SCR: ${CitationFormatter.format(prec.citationId)}',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF75777E), fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Color(0xFFEAEDFF)),
                              const SizedBox(height: 6),

                              // Mandatory Verification Checkbox
                              InkWell(
                                onTap: () => gateNotifier.toggleCitation(prec.citationId, !isChecked),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isChecked,
                                      activeColor: const Color(0xFF1F6C3A),
                                      onChanged: (val) => gateNotifier.toggleCitation(prec.citationId, val ?? false),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'मैंने इस निर्णय एवं उद्धरण का स्वयं परीक्षण कर लिया है।',
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    // Mandatory Advocate Statutory Declaration Card
                    Card(
                      elevation: 2,
                      color: const Color(0xFF0D1C32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.account_balance, color: Color(0xFFD6E3FF), size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'अधिवक्ता सांविधिक घोषणा',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'बार काउंसिल मुद्रा',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => gateNotifier.setStatutoryDeclaration(!gateState.statutoryDeclarationAccepted),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: gateState.statutoryDeclarationAccepted,
                                    activeColor: const Color(0xFFA4F1B2),
                                    checkColor: const Color(0xFF0D1C32),
                                    onChanged: (val) => gateNotifier.setStatutoryDeclaration(val ?? false),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'मैं प्रमाणित करता हूँ कि यह मसौदा मेरे स्वतंत्र विधिक परीक्षण के उपरांत तैयार है।',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'बार काउंसिल पंजीकरण संख्या: ${profile.barCouncilNumber} (सत्यापित डिजिटल हस्ताक्षर संलग्न होगा)।',
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFB9C7E4)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Footer Action Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFullyVerified ? const Color(0xFF0D1C32) : const Color(0xFFDAE2FD),
                        foregroundColor: isFullyVerified ? Colors.white : const Color(0xFF75777E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(isFullyVerified ? Icons.file_download : Icons.lock, size: 20),
                      label: Text(
                        'न्यायालयीन PDF प्रारूप डाउनलोड करें (1.5" Margin)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isFullyVerified ? Colors.white : const Color(0xFF75777E),
                        ),
                      ),
                      onPressed: isFullyVerified
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
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFullyVerified ? Icons.verified : Icons.info_outline,
                        size: 14,
                        color: isFullyVerified ? const Color(0xFF1F6C3A) : const Color(0xFFD6603B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFullyVerified
                            ? 'द्वार अनलॉक है • सांविधिक डिजिटल रिकॉर्ड तैयार है'
                            : 'सभी नजीरों एवं विधिक घोषणा का सत्यापन करने के पश्चात ही यह बटन अनलॉक होगा।',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isFullyVerified ? const Color(0xFF1F6C3A) : const Color(0xFFD6603B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
