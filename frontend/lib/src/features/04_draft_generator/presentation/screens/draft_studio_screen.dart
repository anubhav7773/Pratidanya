import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/security/advocate_privilege_guard.dart';
import '../../../../core/services/activity_service.dart';
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
    AppEnvironment.warmupBackend();
    ActivityService.logActivity(
      activityType: 'DRAFT_STUDIO_OPENED',
      details: {'case_id': widget.caseId},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(draftingControllerProvider.notifier).loadCachedDraft(widget.caseId);
    });
  }

  @override
  void dispose() {
    AdvocatePrivilegeGuard.disableConfidentialityProtection();
    super.dispose();
  }

  void _triggerDraftGeneration(CriminalCase criminalCase) {
    final factualSummary = (criminalCase.lastCourtOrder != null && criminalCase.lastCourtOrder!.trim().isNotEmpty)
        ? criminalCase.lastCourtOrder!
        : 'अभियुक्त ${criminalCase.accusedName} को थाना ${criminalCase.policeStation}, जनपद ${criminalCase.district} के मु.अ.सं. ${criminalCase.firNumber} अंतर्गत धारा ${criminalCase.underSections.join(', ')} में निरुद्ध किया गया है। आवेदक पूर्णतः निर्दोष है एवं उसे विद्वेषवश झूठा फंसाया गया है। कथित घटना या बरामदगी के समय कोई निष्पक्ष स्वतंत्र साक्षी उपस्थित नहीं था।';

    ref.read(draftingControllerProvider.notifier).generateDraft(
          caseId: criminalCase.id,
          firNumber: criminalCase.firNumber,
          sections: criminalCase.underSections,
          policeStation: criminalCase.policeStation,
          district: criminalCase.district,
          factualSummary: factualSummary,
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

  Future<void> _confirmDeleteCase(BuildContext context, CriminalCase criminalCase) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: StitchColors.alertCrimson),
            SizedBox(width: 8),
            Text('केस हटाएं (Delete Case)?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'क्या आप मु.अ.सं. ${criminalCase.firNumber} (अभियुक्त: ${criminalCase.accusedName}) को स्थायी रूप से हटाना चाहते हैं?\n\nड्राफ्ट और नजीर प्राप्त होने के बाद आप इसे अपनी इच्छानुसार हटा सकते हैं। यह कार्यवाही पूर्ववत (Undo) नहीं की जा सकेगी।',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('रद्द करें', style: TextStyle(color: Color(0xFF44474D))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: StitchColors.alertCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('हां, केस हटाएं'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      try {
        await ref.read(caseFormControllerProvider.notifier).deleteCase(criminalCase.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('मु.अ.सं. ${criminalCase.firNumber} सफलतापूर्वक हटा दिया गया।'),
              backgroundColor: const Color(0xFF0D1C32),
            ),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/cases');
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('केस हटाने में त्रुटि: $e'),
              backgroundColor: StitchColors.alertCrimson,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseListAsync = ref.watch(caseListProvider);
    final draftAsync = ref.watch(draftingControllerProvider);

    return caseListAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('केस त्रुटि: $e'))),
      data: (cases) {
        if (cases.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('ड्राफ्टिंग स्टूडियो')),
            body: const Center(child: Text('कोई केस उपलब्ध नहीं है')),
          );
        }
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
                      Expanded(
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
                                    'जमानत प्रार्थना पत्र प्रारूप',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'सत्र न्यायालय एवं उच्च न्यायालय विधिक प्रपत्र',
                                    style: TextStyle(fontSize: 10.5, color: Color(0xFF44474D)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: StitchColors.alertCrimson),
                            tooltip: 'केस हटाएं (Delete Case)',
                            onPressed: () => _confirmDeleteCase(context, currentCase),
                          ),
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
                              if (draftAsync.valueOrNull == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('कृपया पहले "360° विधिक ड्राफ्ट तैयार करें" दबाकर मसौदा बनाएं।'),
                                    backgroundColor: Color(0xFF0D1C32),
                                  ),
                                );
                                return;
                              }
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
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('न्यायिक अभिरक्षा', style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E))),
                                                Builder(
                                                  builder: (context) {
                                                    final refDate = currentCase.arrestDate ?? currentCase.createdAt;
                                                    final daysInCustody = DateTime.now().difference(refDate).inDays;
                                                    final custodyDays = daysInCustody <= 0 ? 1 : daysInCustody;
                                                    final isDetained = currentCase.accusedCustodyStatus == 'JUDICIAL_CUSTODY' ||
                                                        currentCase.accusedCustodyStatus == 'POLICE_CUSTODY' ||
                                                        currentCase.accusedCustodyStatus == 'HOSPITAL_CUSTODY' ||
                                                        currentCase.accusedCustodyStatus == 'JJB_OBSERVATION_HOME';
                                                    final custodyLabel = isDetained
                                                        ? '$custodyDays दिन (${currentCase.accusedCustodyStatus == 'POLICE_CUSTODY' ? 'पुलिस रिमांड' : 'निरोध में'})'
                                                        : 'निरोध मुक्त / जमानत पर';
                                                    return Text(
                                                      custodyLabel,
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A)),
                                                    );
                                                  },
                                                ),
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

                            final sectionsStr = currentCase.underSections.join(' ').toLowerCase();
                            final isNdps = sectionsStr.contains('ndps') || sectionsStr.contains('8/20') || sectionsStr.contains('8/') || sectionsStr.contains('21/') || sectionsStr.contains('एनडीपीएस');
                            final isPocso = sectionsStr.contains('pocso') || sectionsStr.contains('पॉक्सो') || sectionsStr.contains('376') || sectionsStr.contains('64') || sectionsStr.contains('65');
                            final isArms = sectionsStr.contains('arms') || sectionsStr.contains('आयुध') || sectionsStr.contains('25') || sectionsStr.contains('27');
                            final isGangsters = sectionsStr.contains('gangster') || sectionsStr.contains('गैंगस्टर') || sectionsStr.contains('2/3');
                            final isScSt = sectionsStr.contains('sc/st') || sectionsStr.contains('अत्याचार') || sectionsStr.contains('scst') || sectionsStr.contains('3(1)') || sectionsStr.contains('3(2)');
                            final isExcise = sectionsStr.contains('excise') || sectionsStr.contains('आबकारी') || sectionsStr.contains('60');
                            final isCyber = sectionsStr.contains('it act') || sectionsStr.contains('cyber') || sectionsStr.contains('साइबर') || sectionsStr.contains('66');
                            final isPmla = sectionsStr.contains('pmla') || sectionsStr.contains('धन शोधन') || sectionsStr.contains('money laundering');
                            final isNiAct = sectionsStr.contains('138') || sectionsStr.contains('ni act') || sectionsStr.contains('चेक');
                            final isHomicide = sectionsStr.contains('302') || sectionsStr.contains('103') || sectionsStr.contains('307') || sectionsStr.contains('109');
                            final isTheft = sectionsStr.contains('379') || sectionsStr.contains('303') || sectionsStr.contains('chori') || sectionsStr.contains('चोरी');

                            String proceduralChipText() {
                              if (isNdps) return 'धारा 50 / 42 NDPS';
                              if (isPocso) return 'धारा 94 JJ Act / POCSO';
                              if (isArms) return 'धारा 100 CrPC / 105 BNSS';
                              if (isGangsters) return 'धारा 19(4) UP Gangsters Act';
                              if (isScSt) return 'धारा 14A SC/ST Act';
                              if (isExcise) return 'धारा 60 UP Excise Act';
                              if (isCyber) return 'धारा 66D IT Act / 63 BSA';
                              if (isPmla) return 'धारा 45 PMLA';
                              if (isNiAct) return 'धारा 138 NI Act';
                              return 'धारा 41A CrPC / धारा 35 BNSS';
                            }

                            String proceduralHeaderTitle() {
                              if (isNdps) return 'प्रक्रियात्मक उल्लंघन (धारा 50 / 42 NDPS एक्ट)';
                              if (isPocso) return 'प्रक्रियात्मक उल्लंघन (JJ Act धारा 94 आयु निर्धारण प्रक्रिया)';
                              if (isArms) return 'प्रक्रियात्मक उल्लंघन (धारा 25 Arms Act / धारा 105 BNSS जब्ती)';
                              if (isGangsters) return 'प्रक्रियात्मक उल्लंघन (UP Gangsters Act धारा 2/3 नियम विरुद्ध गैंगचार्ट)';
                              if (isScSt) return 'प्रक्रियात्मक उल्लंघन (SC/ST Act धारा 14A / डीएसपी स्तर जांच का अभाव)';
                              if (isExcise) return 'प्रक्रियात्मक उल्लंघन (UP Excise Act धारा 60 स्वतंत्र साक्षी का अभाव)';
                              if (isCyber) return 'प्रक्रियात्मक उल्लंघन (IT Act 66D / BSA धारा 63 डिजिटल साक्ष्य अभाव)';
                              if (isPmla) return 'प्रक्रियात्मक उल्लंघन (PMLA धारा 45 / ECIR आधार अभाव)';
                              if (isNiAct) return 'प्रक्रियात्मक उल्लंघन (NI Act 138(b) कानूनी नोटिस तामील अभाव)';
                              return 'प्रक्रियात्मक उल्लंघन (धारा 41A CrPC / धारा 35 BNSS)';
                            }

                            String proceduralDefaultText() {
                              if (isNdps) return 'तलाशी पूर्व मजिस्ट्रेट या राजपत्रित अधिकारी के समक्ष पेश किए जाने के विधिक अधिकार (धारा 50 NDPS) का पूर्ण उल्लंघन। स्टेट ऑफ राजस्थान बनाम परमानंद (2014) 5 SCC 345 का स्पष्ट उल्लंघन।';
                              if (isPocso) return 'पीड़िता की आयु निर्धारण में धारा 94 जुवेनाइल जस्टिस एक्ट के अनिवार्य विधिक क्रम (जन्म प्रमाण पत्र/स्कूल रिकॉर्ड) का अनुपालन नहीं किया गया। पी. युवराज बनाम स्टेट (2024) नजीर का उल्लंघन।';
                              if (isArms) return 'कथित हथियार बरामदगी के समय स्वतंत्र स्थानीय साक्षियों (धारा 100 CrPC / 105 BNSS) का पूर्ण अभाव एवं सील मुहर की कड़ी में विधिक त्रुटि।';
                              if (isGangsters) return 'एकल मामले के आधार पर बिना पुलिस अधीक्षक के स्वतंत्र विवेक प्रयोग के अवैध रूप से गैंग-चार्ट अनुमोदित किया गया।';
                              if (isScSt) return 'कथित घटना किसी सार्वजनिक दृष्टिगोचर स्थान पर घटित नहीं हुई। हितेश वर्मा बनाम उत्तराखंड राज्य (2020) 10 SCC 710 के अनुसार अपराध नहीं बनता।';
                              if (isExcise) return 'कथित अवैध मदिरा जब्ती में धारा 105 BNSS के तहत स्वतंत्र स्थानीय गवाह उपस्थित नहीं थे और न ही मौके पर कोई निष्पक्ष वीडियोग्राफी की गई।';
                              if (isCyber) return 'डिजिटल उपकरणों एवं इलेक्ट्रॉनिक रिकॉर्ड के साथ धारा 63 भारतीय साक्ष्य अधिनियम / 65B प्रमाण पत्र का पूर्ण अभाव है।';
                              if (isPmla) return 'मूल अपराध (Predicate Offence) में कोई आपराधिक आय सिद्ध नहीं हुई है। विजय मदनलाल चौधरी (2022) नजीर के तहत PMLA कार्यवाही टिक नहीं सकती।';
                              if (isNiAct) return 'परिवादी द्वारा धारा 138(b) के अनिवार्य 15-दिवसीय मांग नोटिस की विधिवत तामीली का कोई साक्ष्य प्रस्तुत नहीं किया गया।';
                              return 'गिरफ्तारी पूर्व अनिवार्य विधिक नोटिस का पूर्ण अभाव। माननीय सर्वोच्च न्यायालय द्वारा अर्नेश कुमार बनाम बिहार राज्य मामले में प्रतिपादित दिशानिर्देशों का उल्लंघन।';
                            }

                            String precedentCitationDefault() {
                              if (isNdps) return '(2014) 5 SCC 345';
                              if (isPocso) return '(2024) 6 SCC 345';
                              if (isArms) return '(2008) 16 SCC 417';
                              if (isGangsters) return '2023 SCC OnLine All 123';
                              if (isScSt) return '(2020) 10 SCC 710';
                              if (isExcise) return '2019 SCC OnLine All 2541';
                              if (isCyber) return '(2020) 7 SCC 1';
                              if (isPmla) return '(2022) SCC OnLine SC 929';
                              if (isNiAct) return '(2014) 16 SCC 260';
                              if (isHomicide) return '(2012) 1 SCC 40';
                              return '(2014) 8 SCC 273';
                            }

                            String precedentQuoteDefault() {
                              if (isNdps) return '"स्टेट ऑफ राजस्थान बनाम परमानंद — धारा 50 NDPS एक्ट के तहत व्यक्तिगत तलाशी के अधिकार की सूचना अनिवार्य है। धारा 50 की विफलता पर सम्पूर्ण तलाशी व जब्ती अवैध हो जाती है, जो जमानत का निर्विवाद आधार है।"';
                              if (isPocso) return '"पी. युवराज बनाम स्टेट — पीड़िता की आयु निर्धारण हेतु धारा 94 जुवेनाइल जस्टिस एक्ट के निर्धारित वैधानिक क्रम का पालन न होने पर संदेह का लाभ अभियुक्त को जमानत के रूप में मिलना चाहिए।"';
                              if (isArms) return '"संजय दत्त बनाम स्टेट — आयुध अधिनियम अंतर्गत अनधिकृत हथियार बरामदगी के मामले में तलाशी एवं जब्ती की कड़ी में किसी भी संशय का लाभ अभियुक्त को प्राप्त होता है।"';
                              if (isGangsters) return '"कपिल कटारिया बनाम यूपी राज्य — मात्र एक आपराधिक मामले के आधार पर बिना संगठित गिरोह संचालन के साक्ष्य के गैंगस्टर्स एक्ट लागू नहीं किया जा सकता।"';
                              if (isScSt) return '"हितेश वर्मा बनाम उत्तराखंड राज्य — जब तक कथित जातिगत अपमान सार्वजनिक दृष्टिगोचर स्थान (Public View) में न हुआ हो, तब तक एससी/एसटी अधिनियम की धारा 3(1)(r)(s) का अपराध नहीं बनता।"';
                              return '"संजय चंद्र बनाम सी.बी.आई. — जमानत का प्रदान किया जाना ही सामान्य विधिक नियम है और कारावास केवल अपवाद (Bail is the rule, jail is the exception)।"';
                            }

                            return Column(
                              children: [
                                if (_selectedTabIndex == 0)
                                  ...draft.statutoryGrounds.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final rawText = entry.value;
                                    final text = rawText
                                        .replaceAll(RegExp(r'^(?:विधिक\s*आधार\s*\d+\s*[\(\:\-–\.]?\s*|\d+[\.\)]\s*)'), '')
                                        .replaceAll(RegExp(r'\)$'), '')
                                        .trim();

                                    String cardTitle;
                                    String statutoryChip;
                                    String tagText = idx == 0 ? 'मानक विधिक आधार' : 'संलग्नक विवरण';

                                    if (isNdps) {
                                      if (idx == 0) {
                                        cardTitle = 'निर्दोषिता एवं विधिसम्मत जब्ती का अभाव';
                                        statutoryChip = 'संविधान अनु. 21 / निर्दोषिता की उपधारणा / NDPS धारा 37';
                                      } else if (idx == 1) {
                                        cardTitle = 'तलाशी एवं जब्ती में धारा 50 NDPS का उल्लंघन';
                                        statutoryChip = 'धारा 50 / 42 NDPS एक्ट';
                                        tagText = 'कानूनी सुरक्षा उल्लंघन';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'NDPS विधिक आधार';
                                      }
                                    } else if (isPocso) {
                                      if (idx == 0) {
                                        cardTitle = 'निर्दोषिता एवं सहमति / आयु विवाद';
                                        statutoryChip = 'धारा 94 JJ Act / निर्दोषिता की उपधारणा';
                                      } else if (idx == 1) {
                                        cardTitle = 'आयु निर्धारण एवं मेडिकल साक्ष्य में गंभीर विसंगति';
                                        statutoryChip = 'धारा 35 POCSO / धारा 94 JJ Act';
                                        tagText = 'आयु निर्धारण संशय';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'POCSO विधिक आधार';
                                      }
                                    } else if (isArms) {
                                      if (idx == 0) {
                                        cardTitle = 'निर्दोषिता एवं स्वतंत्र साक्षी का पूर्ण अभाव';
                                        statutoryChip = 'धारा 100 CrPC / 105 BNSS / निर्दोषिता की उपधारणा';
                                      } else if (idx == 1) {
                                        cardTitle = 'कथित बरामदगी फर्द में कानूनी त्रुटियां';
                                        statutoryChip = 'धारा 25/27 Arms Act / धारा 105 BNSS';
                                        tagText = 'बरामदगी फर्द संशय';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'Arms Act विधिक आधार';
                                      }
                                    } else if (isGangsters) {
                                      if (idx == 0) {
                                        cardTitle = 'एकल मामले पर नियम-विरुद्ध गैंग-चार्ट';
                                        statutoryChip = 'UP Gangsters Act धारा 2/3 / निर्दोषिता की उपधारणा';
                                      } else if (idx == 1) {
                                        cardTitle = 'मूल मामलों में जमानत प्राप्त, गिरोह संचालन का अभाव';
                                        statutoryChip = 'धारा 19(4) UP Gangsters Act';
                                        tagText = 'गैंगचार्ट विसंगति';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई असामाजिक गिरोह सदस्यता नहीं';
                                        statutoryChip = 'स्वच्छ सामाजिक पृष्ठभूमि';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'Gangsters Act विधिक आधार';
                                      }
                                    } else if (isScSt) {
                                      if (idx == 0) {
                                        cardTitle = 'सार्वजनिक दृष्टिगोचर स्थान पर अपमान का अभाव';
                                        statutoryChip = 'धारा 3(1)(r)(s) SC/ST Act / हितेश वर्मा नजीर';
                                      } else if (idx == 1) {
                                        cardTitle = 'निजी विवाद को जातिगत रूप देकर मिथ्या अभियोग';
                                        statutoryChip = 'धारा 14A SC/ST Act / दुर्भावनापूर्ण मिथ्या नामजदगी';
                                        tagText = 'जातिगत साक्ष्य अभाव';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'SC/ST Act विधिक आधार';
                                      }
                                    } else if (isExcise) {
                                      if (idx == 0) {
                                        cardTitle = 'कथित आबकारी बरामदगी में स्वतंत्र पंच साक्षियों का अभाव';
                                        statutoryChip = 'धारा 60 UP Excise Act / धारा 105 BNSS';
                                      } else if (idx == 1) {
                                        cardTitle = 'रासायनिक विश्लेषण (FSL) रिपोर्ट का अभाव';
                                        statutoryChip = 'आबकारी नियम / साक्ष्य का पूर्ण अभाव';
                                        tagText = 'रासायनिक साक्ष्य अभाव';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'Excise Act विधिक आधार';
                                      }
                                    } else if (isCyber) {
                                      if (idx == 0) {
                                        cardTitle = 'डिजिटल साक्ष्य में धारा 65B/63 प्रमाण पत्र का अभाव';
                                        statutoryChip = 'धारा 66D IT Act / धारा 63 BSA';
                                      } else if (idx == 1) {
                                        cardTitle = 'आईपी एड्रेस एवं डिजिटल उपकरण जब्ती में हैश विसंगति';
                                        statutoryChip = 'धारा 66 IT Act / विधिक तत्वों का अभाव';
                                        tagText = 'डिजिटल साक्ष्य संशय';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'Cyber Law विधिक आधार';
                                      }
                                    } else if (isPmla) {
                                      if (idx == 0) {
                                        cardTitle = 'मूल अपराध में कोई अपराध की आय (Proceeds of Crime) नहीं';
                                        statutoryChip = 'धारा 3/4/45 PMLA / विजय मदनलाल नजीर';
                                      } else if (idx == 1) {
                                        cardTitle = 'धारा 45 PMLA दोहरी विधिक शर्तों की संतुष्टि';
                                        statutoryChip = 'अनुच्छेद 21 / धारा 45 PMLA';
                                        tagText = 'दोहरी शर्तें संतुष्टि';
                                      } else if (idx == 2) {
                                        cardTitle = 'जांच में पूर्ण सहयोग एवं कोई उड़ान का जोखिम नहीं';
                                        statutoryChip = 'सत्यापित साख';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'PMLA विधिक आधार';
                                      }
                                    } else if (isNiAct) {
                                      if (idx == 0) {
                                        cardTitle = 'सुरक्षा चेक का दुरुपयोग एवं कोई वैध ऋण दायित्व नहीं';
                                        statutoryChip = 'धारा 138/139 NI Act / विधिक ऋण दायित्व का अभाव';
                                      } else if (idx == 1) {
                                        cardTitle = 'वैध मांग नोटिस की प्राप्ति का अभाव';
                                        statutoryChip = 'धारा 138(b) NI Act';
                                        tagText = 'नोटिस तामील अभाव';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'NI Act विधिक आधार';
                                      }
                                    } else if (isHomicide) {
                                      if (idx == 0) {
                                        cardTitle = 'निर्दोषिता एवं मिथ्या फंसाया जाना';
                                        statutoryChip = 'संविधान अनुच्छेद 21 / निर्दोषिता की उपधारणा';
                                      } else if (idx == 1) {
                                        cardTitle = 'चोटों की प्रकृति एवं साक्ष्य का अभाव';
                                        statutoryChip = 'केस डायरी संदर्भ मु.अ.सं. ${currentCase.firNumber}';
                                        tagText = 'साक्ष्य अभाव';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'अभियोग विश्लेषण';
                                      }
                                    } else if (isTheft) {
                                      if (idx == 0) {
                                        cardTitle = 'निर्दोषिता एवं मिथ्या फंसाया जाना';
                                        statutoryChip = 'संविधान अनुच्छेद 21 / निर्दोषिता की उपधारणा';
                                      } else if (idx == 1) {
                                        cardTitle = 'बरामदगी की विधिक वैधता पर संदेह';
                                        statutoryChip = 'धारा 379 IPC / 303 BNS';
                                        tagText = 'बरामदगी संशय';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'सम्पत्ति साक्ष्य';
                                      }
                                    } else {
                                      if (idx == 0) {
                                        cardTitle = 'निर्दोषिता एवं मिथ्या फंसाया जाना';
                                        statutoryChip = 'संविधान अनुच्छेद 21 / निर्दोषिता की उपधारणा';
                                      } else if (idx == 1) {
                                        cardTitle = 'तथ्यों एवं प्रत्यक्ष साक्ष्यों का अभाव';
                                        statutoryChip = 'मु.अ.सं. ${currentCase.firNumber} रिकॉर्ड';
                                      } else if (idx == 2) {
                                        cardTitle = 'कोई पूर्व आपराधिक इतिहास नहीं';
                                        statutoryChip = 'पूर्व स्वच्छ आचरण सत्यापित';
                                      } else {
                                        cardTitle = 'विधिक आधार #${idx + 1}';
                                        statutoryChip = 'विधिक विश्लेषण';
                                      }
                                    }

                                    return _buildDraftingCard(
                                      indexNumber: _toDevanagariNumber(idx + 1),
                                      title: cardTitle,
                                      body: text,
                                      statutoryChip: statutoryChip,
                                      tagText: tagText,
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
                                      statutoryChip: proceduralChipText(),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: StitchColors.alertCrimson, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            proceduralHeaderTitle(),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: StitchColors.alertCrimson),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        draft.proceduralObjections.isNotEmpty
                                            ? draft.proceduralObjections.first
                                            : proceduralDefaultText(),
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF131B2E), height: 1.35),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.auto_stories, color: Color(0xFF1F6C3A), size: 16),
                                              SizedBox(width: 6),
                                              Text('सर्वोच्च न्यायालय नजीर संदर्भ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF131B2E))),
                                            ],
                                          ),
                                          Text(
                                            draft.citedPrecedents.isNotEmpty
                                                ? draft.citedPrecedents.first.citationId
                                                : precedentCitationDefault(),
                                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF75777E)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        draft.citedPrecedents.isNotEmpty
                                            ? '"${draft.citedPrecedents.first.caseTitle} — ${draft.citedPrecedents.first.quotedPassage}"'
                                            : precedentQuoteDefault(),
                                        style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF131B2E), height: 1.35),
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
                            if (draftAsync.valueOrNull == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('कृपया पहले "360° विधिक ड्राफ्ट तैयार करें" दबाकर मसौदा बनाएं।'),
                                  backgroundColor: Color(0xFF0D1C32),
                                ),
                              );
                              return;
                            }
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
                            if (draftAsync.valueOrNull == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('कृपया पहले "360° विधिक ड्राफ्ट तैयार करें" दबाकर मसौदा बनाएं।'),
                                  backgroundColor: Color(0xFF0D1C32),
                                ),
                              );
                              return;
                            }
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
