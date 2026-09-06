import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/security/advocate_privilege_guard.dart';
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

class _DraftStudioScreenState extends ConsumerState<DraftStudioScreen> {
  int _selectedTabIndex = 0; // 0: grounds, 1: weakpoints, 2: procedural, 3: precedents
  final List<String> _injectedFacts = [];

  @override
  void initState() {
    super.initState();
    AdvocatePrivilegeGuard.enableConfidentialityProtection();
  }

  @override
  void dispose() {
    AdvocatePrivilegeGuard.disableConfidentialityProtection();
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
      const SnackBar(
        content: Text('विधिक बिंदु क्लिपबोर्ड में कॉपी किया गया'),
        backgroundColor: Color(0xFF0D1C32),
      ),
    );
  }

  void _editItemDialog({
    required BuildContext context,
    required String title,
    required String initialText,
    required ValueChanged<String> onSave,
  }) {
    final controller = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(fontSize: 13.5),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1C32), foregroundColor: Colors.white),
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('सुरक्षित करें'),
          ),
        ],
      ),
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
          backgroundColor: const Color(0xFFFAF8FF),
          body: SafeArea(
            child: Column(
              children: [
                // Top App Bar / Navigation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'जमानत प्रार्थना पत्र प्रारूप',
                                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                              ),
                              Text(
                                'सत्र न्यायालय एवं उच्च न्यायालय विधिक प्रपत्र',
                                style: TextStyle(fontSize: 11, color: Color(0xFF44474D)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.document_scanner_outlined, size: 20, color: Color(0xFF0D1C32)),
                            tooltip: 'आरोप पत्र विश्लेषण (OpenNyAI)',
                            onPressed: _openChargesheetParser,
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D1C32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.file_download, size: 16, color: Color(0xFFFFDBD1)),
                            label: const Text('निर्यात', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              context.push('/cases/${widget.caseId}/verify-gate');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Case Summary Header Card (शीर्ष वाद विवरण)
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'फौजदारी वाद शीर्षक',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF75777E), letterSpacing: 0.5),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${currentCase.accusedName} बनाम उत्तर प्रदेश राज्य',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFA4F1B2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.verified, size: 13, color: Color(0xFF1F6C3A)),
                                          SizedBox(width: 4),
                                          Text(
                                            'नियमित सत्र',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF24703E)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Parameters Grid (4 boxes)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F3FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('सी.एन.आर. (CNR No.)', style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E))),
                                                Text(currentCase.caseNumber ?? 'UPLK010045232026', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('मु.अ.सं. (FIR No.)', style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E))),
                                                Text('${currentCase.firNumber} (${currentCase.policeStation})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('आरोपित धाराएं', style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E))),
                                                Text(currentCase.underSections.join(', '), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: StitchColors.alertCrimson)),
                                              ],
                                            ),
                                          ),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('न्यायिक अभिरक्षा', style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E))),
                                                Text('42 दिन (निरोध में)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance, size: 14, color: Color(0xFF75777E)),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentCase.courtDesignation,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF44474D)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Horizontal Tab Selection Bar
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPillTab(index: 0, label: 'जमानत के विधिक आधार', icon: Icons.gavel),
                              const SizedBox(width: 8),
                              _buildPillTab(index: 1, label: 'अभियोजन की कमजोरियां', icon: Icons.rule),
                              const SizedBox(width: 8),
                              _buildPillTab(index: 2, label: 'प्रक्रियात्मक आपत्तियां', icon: Icons.fact_check),
                              const SizedBox(width: 8),
                              _buildPillTab(index: 3, label: 'न्यायिक नजीरें (Precedents)', icon: Icons.menu_book),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tab Content Body
                        draftAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text('न्यायालयीन हिंदी में 360° विधिक मसौदा तैयार हो रहा है...'),
                                ],
                              ),
                            ),
                          ),
                          error: (err, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline, size: 40, color: StitchColors.alertCrimson),
                                  const SizedBox(height: 8),
                                  Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: StitchColors.alertCrimson)),
                                  const SizedBox(height: 12),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.gavel_rounded, size: 48, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      Text(
                                        'मु.अ.सं. ${currentCase.firNumber} हेतु सक्रिय ड्राफ्ट तैयार करें',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D1C32),
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(Icons.auto_awesome),
                                        label: const Text('360° विधिक ड्राफ्ट तैयार करें'),
                                        onPressed: () => _triggerDraftGeneration(currentCase),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: [
                                if (_selectedTabIndex == 0)
                                  ...draft.statutoryGrounds.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final text = entry.value;
                                    return _buildDraftingCard(
                                      indexNumber: _toDevanagariNumber(idx + 1),
                                      title: idx == 0
                                          ? 'निर्दोषिता एवं मिथ्या फंसाया जाना'
                                          : idx == 1
                                              ? 'चोटों की प्रकृति एवं साक्ष्य का अभाव'
                                              : 'कोई पूर्व आपराधिक इतिहास नहीं',
                                      body: text,
                                      statutoryChip: idx == 0
                                          ? 'संविधान अनुच्छेद 21 / BNSS धारा 480'
                                          : idx == 1
                                              ? 'MLC संदर्भ संख्या 88/2026'
                                              : 'पूर्व स्वच्छ आचरण सत्यापित',
                                      tagText: idx == 0 ? 'मानक विधिक आधार' : 'संलग्नक विवरण',
                                      onCopy: () => _copyToClipboard(text),
                                      onEdit: () => _editItemDialog(
                                        context: context,
                                        title: 'विधिक आधार संपादित करें',
                                        initialText: text,
                                        onSave: (newVal) => ref.read(draftingControllerProvider.notifier).updateGround(idx, newVal),
                                      ),
                                    );
                                  }),
                                if (_selectedTabIndex == 1)
                                  ...draft.prosecutionWeaknesses.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final text = entry.value;
                                    return _buildDraftingCard(
                                      indexNumber: _toDevanagariNumber(idx + 1),
                                      title: 'अभियोजन पक्ष की कमजोरी #${idx + 1}',
                                      body: text,
                                      statutoryChip: 'साक्ष्य अभाव विश्लेषण',
                                      tagText: 'कमजोर बिंदु',
                                      onCopy: () => _copyToClipboard(text),
                                      onEdit: () => _editItemDialog(
                                        context: context,
                                        title: 'कमजोरी बिंदु संपादित करें',
                                        initialText: text,
                                        onSave: (newVal) => ref.read(draftingControllerProvider.notifier).updateWeakness(idx, newVal),
                                      ),
                                    );
                                  }),
                                if (_selectedTabIndex == 2)
                                  ...draft.proceduralObjections.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final text = entry.value;
                                    return _buildDraftingCard(
                                      indexNumber: _toDevanagariNumber(idx + 1),
                                      title: 'प्रक्रियात्मक आपत्ति #${idx + 1}',
                                      body: text,
                                      statutoryChip: 'धारा 41A CrPC / धारा 35 BNSS',
                                      tagText: 'विधिक आपत्ति',
                                      onCopy: () => _copyToClipboard(text),
                                      onEdit: null,
                                    );
                                  }),
                                if (_selectedTabIndex == 3)
                                  ...draft.citedPrecedents.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final prec = entry.value;
                                    return _buildDraftingCard(
                                      indexNumber: _toDevanagariNumber(idx + 1),
                                      title: prec.caseTitle,
                                      body: '"${prec.quotedPassage}"\n\nविधि निष्कर्ष: ${prec.courtName}',
                                      statutoryChip: prec.citationId,
                                      tagText: 'सुप्रीम कोर्ट नजीर',
                                      onCopy: () => _copyToClipboard('${prec.caseTitle}\n${prec.quotedPassage}'),
                                      onEdit: null,
                                    );
                                  }),

                                // Procedural Violation Snippet Preview Box
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F3FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: StitchColors.alertCrimson, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'प्रक्रियात्मक उल्लंघन (धारा 41A CrPC / धारा 35 BNSS)',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: StitchColors.alertCrimson),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'गिरफ्तारी पूर्व अनिवार्य विधिक नोटिस का पूर्ण अभाव। माननीय सर्वोच्च न्यायालय द्वारा अर्नेश कुमार बनाम बिहार राज्य मामले में प्रतिपादित दिशानिर्देशों का उल्लंघन।',
                                        style: TextStyle(fontSize: 11.5, color: Color(0xFF131B2E), height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Supreme Court Precedent Snippet
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFEAEDFF)),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.auto_stories, color: Color(0xFF1F6C3A), size: 16),
                                              SizedBox(width: 6),
                                              Text('सर्वोच्च न्यायालय नजीर संदर्भ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF131B2E))),
                                            ],
                                          ),
                                          Text('(2012) 1 SCC 40', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF75777E))),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        '"संजय चंद्र बनाम सी.बी.आई. — जमानत का प्रदान किया जाना ही सामान्य विधिक नियम है और कारावास केवल अपवाद (Bail is the rule, jail is the exception)।"',
                                        style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF131B2E), height: 1.35),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Action Bar (पूर्वावलोकन + ड्राफ्ट निर्यात करें)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F3FF),
                            side: const BorderSide(color: Color(0xFFDAE2FD)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.visibility, size: 18, color: Color(0xFF131B2E)),
                          label: const Text('पूर्वावलोकन', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E))),
                          onPressed: () {
                            context.push('/cases/${widget.caseId}/verify-gate');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1C32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.download_for_offline, size: 18, color: Color(0xFFA4F1B2)),
                          label: const Text('ड्राफ्ट निर्यात करें', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            context.push('/cases/${widget.caseId}/verify-gate');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillTab({required int index, required String label, required IconData icon}) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D1C32) : const Color(0xFFEAEDFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF44474D)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF44474D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftingCard({
    required String indexNumber,
    required String title,
    required String body,
    required String statutoryChip,
    required String tagText,
    required VoidCallback onCopy,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12.0),
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
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD6E3FF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          indexNumber,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D1C32)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 16, color: Color(0xFF75777E)),
                      onPressed: onCopy,
                      tooltip: 'कॉपी करें',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_note, size: 18, color: Color(0xFF75777E)),
                        onPressed: onEdit,
                        tooltip: 'संपादित करें',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(fontSize: 13, height: 1.55, color: Color(0xFF131B2E), letterSpacing: 0.1),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEDFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statutoryChip,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 13, color: Color(0xFF1F6C3A)),
                    const SizedBox(width: 4),
                    Text(tagText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _toDevanagariNumber(int n) {
    const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    return n.toString().split('').map((ch) => devanagariDigits[int.parse(ch)]).join('');
  }
}
