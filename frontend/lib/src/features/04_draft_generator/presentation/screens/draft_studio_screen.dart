import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../02_case_input/domain/criminal_case.dart';
import '../../../02_case_input/presentation/controllers/case_controller.dart';
import '../controllers/drafting_controller.dart';
import '../widgets/chargesheet_deconstruct_modal.dart';

class DraftStudioScreen extends ConsumerStatefulWidget {
  final String caseId;

  const DraftStudioScreen({super.key, required this.caseId});

  @override
  ConsumerState<DraftStudioScreen> createState() => _DraftStudioScreenState();
}

class _DraftStudioScreenState extends ConsumerState<DraftStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _injectedFacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerDraftGeneration(CriminalCase criminalCase) {
    ref.read(draftingControllerProvider.notifier).generateDraft(
          caseId: criminalCase.id,
          firNumber: criminalCase.firNumber,
          sections: criminalCase.underSections,
          policeStation: criminalCase.policeStation,
          district: criminalCase.district,
          factualSummary: criminalCase.lastCourtOrder ?? 'बरामदगी के समय कोई स्वतंत्र साक्षी उपस्थित नहीं था।',
          custodyStatus: criminalCase.accusedCustodyStatus,
          extractedFacts: _injectedFacts,
        );
  }

  void _openChargesheetParser() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ChargesheetDeconstructModal(
        caseId: widget.caseId,
        onFactsExtracted: (facts) {
          setState(() => _injectedFacts.addAll(facts));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${facts.length} तथ्य ड्राफ्ट संदर्भ में जोड़े गए।')),
          );
        },
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('पाठ क्लिपबोर्ड पर कॉपी किया गया।')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseListAsync = ref.watch(caseListProvider);
    final draftAsync = ref.watch(draftingControllerProvider);

    return caseListAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('केस त्रुटि: $e'))),
      data: (cases) {
        final currentCase = cases.firstWhere(
          (c) => c.id == widget.caseId,
          orElse: () => cases.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('ड्राफ्टिंग स्टूडियो: मु.अ.सं. ${currentCase.firNumber}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.document_scanner_outlined),
                tooltip: 'आरोप पत्र विश्लेषण (OpenNyAI)',
                onPressed: _openChargesheetParser,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: StitchColors.courtNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                icon: const Icon(Icons.verified_outlined, size: 16),
                label: const Text('सत्यापन एवं निर्यात', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  final draft = draftAsync.valueOrNull;
                  if (draft == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('कृपया पहले 360° विधिक ड्राफ्ट तैयार करें।')),
                    );
                    return;
                  }
                  context.push('/cases/${widget.caseId}/verify-gate');
                },
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
                Tab(text: 'जमानत के आधार'),
                Tab(text: 'अभियोजन कमजोरियां'),
                Tab(text: 'प्रक्रियात्मक आपत्तियां'),
                Tab(text: 'उद्धृत मिसालें'),
              ],
            ),
          ),
          body: Column(
            children: [
              const BciDisclaimerBanner(),
              if (_injectedFacts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                  color: StitchColors.verifiedGreenBg,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: StitchColors.verifiedGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_injectedFacts.length} आरोप-पत्र तथ्य ड्राफ्टिंग पाइपलाइन में सक्रिय हैं।',
                          style: const TextStyle(fontSize: 12, color: StitchColors.verifiedGreen, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: draftAsync.when(
                  loading: () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('न्यायालयीन हिंदी में 360° विधिक मसौदा तैयार हो रहा है...'),
                      ],
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: StitchColors.alertCrimson),
                          const SizedBox(height: 12),
                          Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: StitchColors.alertCrimson)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _triggerDraftGeneration(currentCase),
                            child: const Text('पुनः प्रयास करें'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (draft) {
                    if (draft == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'मु.अ.सं. ${currentCase.firNumber} हेतु कोई सक्रिय ड्राफ्ट नहीं है',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: StitchColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'केस डायरी व तथ्यों के आधार पर 360° जमानत प्रार्थना पत्र तैयार करें।',
                              style: TextStyle(fontSize: 13, color: StitchColors.textMuted),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: StitchColors.courtNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('360° विधिक ड्राफ्ट तैयार करें', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _triggerDraftGeneration(currentCase),
                            ),
                          ],
                        ),
                      );
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Statutory Grounds for Bail
                        _buildDraftSectionList(
                          items: draft.statutoryGrounds,
                          title: 'जमानत के विधिक आधार (Grounds for Bail)',
                          onEdit: (idx, val) =>
                              ref.read(draftingControllerProvider.notifier).updateGround(idx, val),
                        ),

                        // Tab 2: Prosecution Weaknesses
                        _buildDraftSectionList(
                          items: draft.prosecutionWeaknesses,
                          title: 'अभियोजन की कमजोरियां (Weak Points)',
                          onEdit: (idx, val) =>
                              ref.read(draftingControllerProvider.notifier).updateWeakness(idx, val),
                        ),

                        // Tab 3: Procedural Objections
                        _buildDraftSectionList(
                          items: draft.proceduralObjections,
                          title: 'प्रक्रियात्मक आपत्तियां (धारा 100(4) CrPC / BNSS)',
                          onEdit: null,
                        ),

                        // Tab 4: Cited Precedents
                        ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: draft.citedPrecedents.length,
                          itemBuilder: (ctx, i) {
                            final prec = draft.citedPrecedents[i];
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
                                            prec.caseTitle,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: StitchColors.courtNavy),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: StitchColors.verifiedGreenBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('सत्यापित स्रोत', style: TextStyle(color: StitchColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${prec.courtName} | ${prec.judgmentDate}', style: const TextStyle(fontSize: 12, color: StitchColors.textSecondary)),
                                    const Divider(height: 16),
                                    Text('"${prec.quotedPassage}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, height: 1.45)),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          prec.verifiedSourceUrl,
                                          style: const TextStyle(fontSize: 11, color: Colors.blueAccent, decoration: TextDecoration.underline),
                                        ),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: prec.isManuallyVerified,
                                              activeColor: StitchColors.verifiedGreen,
                                              onChanged: (val) {
                                                ref.read(draftingControllerProvider.notifier).toggleCitationVerification(
                                                      prec.citationId,
                                                      val ?? false,
                                                    );
                                              },
                                            ),
                                            const Text('सत्यापित', style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraftSectionList({
    required List<String> items,
    required String title,
    required Function(int, String)? onEdit,
  }) {
    if (items.isEmpty) {
      return const Center(child: Text('कोई बिंदु उपलब्ध नहीं है।'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final text = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: StitchColors.courtNavy)),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 13.5, height: 1.5, color: StitchColors.textPrimary),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('कॉपी', style: TextStyle(fontSize: 12)),
                      onPressed: () => _copyToClipboard(text),
                    ),
                    if (onEdit != null)
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note, size: 16),
                        label: const Text('संशोधन', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          final editCtrl = TextEditingController(text: text);
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('बिंदु संशोधित करें'),
                              content: TextField(
                                controller: editCtrl,
                                maxLines: 5,
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('रद्द करें')),
                                ElevatedButton(
                                  onPressed: () {
                                    onEdit(i, editCtrl.text.trim());
                                    Navigator.pop(dCtx);
                                  },
                                  child: const Text('सुरक्षित करें'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
