import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../01_onboarding/presentation/controllers/auth_controller.dart';
import '../controllers/high_court_controller.dart';
import '../../data/high_court_paper_book_builder.dart';
import '../../domain/high_court_models.dart';

class HighCourtStudioScreen extends ConsumerStatefulWidget {
  final String? initialPleadingId;

  const HighCourtStudioScreen({super.key, this.initialPleadingId});

  @override
  ConsumerState<HighCourtStudioScreen> createState() => _HighCourtStudioScreenState();
}

class _HighCourtStudioScreenState extends ConsumerState<HighCourtStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatuteSystem = 'IPC_CRPC';
  final String _selectedPleadingType = 'CRIMINAL_APPEAL';
  String? _activePleadingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _activePleadingId = widget.initialPleadingId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadJudgment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final pleadingId = await ref
            .read(highCourtSuiteProvider.notifier)
            .uploadTrialJudgment(file, _selectedPleadingType);

        setState(() => _activePleadingId = pleadingId);

        // Immediately trigger AI synthesis of High Court Pleading
        await ref.read(highCourtSuiteProvider.notifier).synthesizeHighCourtPleading(
              pleadingId: pleadingId,
              statuteSystem: _selectedStatuteSystem,
              isDelayed: false,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('अपलोड विफलता: $e'), backgroundColor: StitchColors.alertCrimson),
          );
        }
      }
    }
  }

  Future<void> _exportHighCourtPaperBook() async {
    final suite = ref.read(highCourtSuiteProvider).valueOrNull;
    final profile = ref.read(currentAdvocateProfileProvider).valueOrNull;

    if (suite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया पहले हाई कोर्ट ड्राफ्ट तैयार करें।')),
      );
      return;
    }

    final advocateName = profile?.fullName ?? 'अधिवक्ता';
    final barCouncilNumber = profile?.barCouncilNumber ?? 'UP/0000/2020';
    final chamberAddress = profile?.chamberAddress ?? 'इलाहाबाद उच्च न्यायालय परिसर';

    final pdfBytes = await HighCourtPaperBookBuilder.generateHighCourtPaperBook(
      suite: suite,
      advocateName: advocateName,
      barCouncilNumber: barCouncilNumber,
      chamberAddress: chamberAddress,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'HighCourt_PaperBook_${suite.pleadingType}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final suiteAsync = ref.watch(highCourtSuiteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('उच्च न्यायालय अपीलीय स्टूडियो (High Court Studio)'),
        actions: [
          // Statute System Toggle: IPC_CRPC vs BNS_BNSS
          DropdownButton<String>(
            value: _selectedStatuteSystem,
            dropdownColor: StitchColors.courtNavy,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'IPC_CRPC', child: Text('IPC / CrPC')),
              DropdownMenuItem(value: 'BNS_BNSS', child: Text('BNS / BNSS')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatuteSystem = val);
                if (_activePleadingId != null) {
                  ref.read(highCourtSuiteProvider.notifier).synthesizeHighCourtPleading(
                        pleadingId: _activePleadingId!,
                        statuteSystem: val,
                      );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'अवर न्यायालय निर्णय PDF अपलोड करें',
            onPressed: _pickAndUploadJudgment,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: StitchColors.courtNavy,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text(
              'पेपर-बुक निर्यात (1.75" Margin)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            onPressed: suiteAsync.valueOrNull != null ? _exportHighCourtPaperBook : null,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'अपील / पुनरीक्षण मेमो'),
            Tab(text: 'दंडादेश स्थगन (Sec 389)'),
            Tab(text: 'विलंब माफी (Sec 5 Delay)'),
            Tab(text: 'उद्धृत मिसालें (Precedents)'),
          ],
        ),
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Expanded(
            child: suiteAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('अवर न्यायालय के निर्णय का OCR एवं विधिक विश्लेषण जारी है...'),
                  ],
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'त्रुटि: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: StitchColors.alertCrimson),
                  ),
                ),
              ),
              data: (suite) {
                if (suite == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gavel_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'कोई उच्च न्यायालय वाद सक्रिय नहीं है',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: StitchColors.courtNavy,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'सत्र न्यायालय के निर्णय की PDF अपलोड करें। प्रणाली स्वतः दोषसिद्धि, सजा, साक्षियों के अंतर्विरोध और धारा 313 के दोषों का विश्लेषण करेगी।',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: StitchColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StitchColors.courtNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('निर्णय PDF अपलोड करें एवं विश्लेषण शुरू करें'),
                          onPressed: _pickAndUploadJudgment,
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Memo of Appeal / Revision
                    _buildMemoView(suite),

                    // Tab 2: Section 389 Sentence Suspension Suite
                    _buildSuspensionView(suite),

                    // Tab 3: Section 5 Limitation Delay Suite
                    _buildDelayView(suite),

                    // Tab 4: Cited High Court & Supreme Court Precedents
                    _buildPrecedentsView(suite),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoView(HighCourtAppealSuite suite) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: StitchColors.courtNavy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: StitchColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suite.memoTitleHindi,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.45, color: StitchColors.courtNavy),
              ),
              const SizedBox(height: 4),
              Text(suite.trialReferenceBlock, style: const TextStyle(fontSize: 11.5, height: 1.45, color: StitchColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'अपील / पुनरीक्षण के विधिक आधार (Grounds):',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, height: 1.45, color: StitchColors.courtNavy),
        ),
        const SizedBox(height: 8),
        ...suite.grounds.map((g) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: StitchColors.courtNavy,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'प्रस्तर ${g.groundNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          g.groundHeading,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    g.groundTextHindi,
                    style: const TextStyle(fontSize: 12.5, height: 1.45, color: StitchColors.textPrimary),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('अंतिम प्रार्थना (Final Relief):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.45)),
                const SizedBox(height: 4),
                Text(suite.finalReliefPrayer, style: const TextStyle(fontSize: 12.5, height: 1.45)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuspensionView(HighCourtAppealSuite suite) {
    if (suite.suspensionGrounds == null || suite.suspensionGrounds!.isEmpty) {
      return const Center(child: Text('सजा स्थगन का कोई प्रस्तर उपलब्ध नहीं है।', style: TextStyle(height: 1.45)));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'दंडादेश स्थगन एवं अंतरिम जमानत प्रार्थना पत्र:',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, height: 1.45, color: StitchColors.courtNavy),
        ),
        const SizedBox(height: 8),
        ...suite.suspensionGrounds!.asMap().entries.map((e) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                '${e.key + 1}. ${e.value}',
                style: const TextStyle(fontSize: 12.5, height: 1.45),
                textAlign: TextAlign.justify,
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          color: StitchColors.verifiedGreenBg,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'अंतरिम प्रार्थना (Interim Bail Prayer):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: StitchColors.verifiedGreen, fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 4),
                Text(suite.suspensionInterimPrayer ?? '', style: const TextStyle(fontSize: 12.5, height: 1.45)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDelayView(HighCourtAppealSuite suite) {
    if (suite.delayGrounds == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 54, color: StitchColors.verifiedGreen),
            SizedBox(height: 10),
            Text('यह अपील वैधानिक मियाद (60 दिन) के भीतर है।', style: TextStyle(fontWeight: FontWeight.bold, height: 1.45)),
            SizedBox(height: 4),
            Text('धारा 5 मियाद अधिनियम के अंतर्गत विलंब माफी की आवश्यकता नहीं है।', style: TextStyle(fontSize: 12, height: 1.45, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'धारा 5 मियाद अधिनियम प्रार्थना पत्र (विलंब माफी):',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, height: 1.45, color: StitchColors.courtNavy),
        ),
        const SizedBox(height: 8),
        ...suite.delayGrounds!.asMap().entries.map((e) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('${e.key + 1}. ${e.value}', style: const TextStyle(fontSize: 12.5, height: 1.45)),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(suite.delayPrayerText ?? '', style: const TextStyle(fontSize: 12.5, height: 1.45)),
          ),
        ),
      ],
    );
  }

  Widget _buildPrecedentsView(HighCourtAppealSuite suite) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: suite.citedPrecedents.length,
      itemBuilder: (ctx, i) {
        final p = suite.citedPrecedents[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.caseTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.45, color: StitchColors.courtNavy),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: StitchColors.verifiedGreenBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('सत्यापित', style: TextStyle(fontSize: 10, color: StitchColors.verifiedGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${p.courtName} | ${p.judgmentDate}', style: const TextStyle(fontSize: 11.5, height: 1.45, color: StitchColors.textSecondary)),
                const Divider(height: 16),
                Text('"${p.quotedPassage}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12.5, height: 1.45)),
              ],
            ),
          ),
        );
      },
    );
  }
}
