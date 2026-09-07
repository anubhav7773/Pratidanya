import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../data/ai_section_advisor_service.dart';
import '../../domain/ai_offense_analysis_result.dart';
import '../../../08_voice_intake/presentation/widgets/court_voice_dictation_sheet.dart';
import '../../../08_voice_intake/domain/voice_intake_result.dart';

class AiSectionAdvisorScreen extends ConsumerStatefulWidget {
  final String? initialFactualMatrix;

  const AiSectionAdvisorScreen({
    super.key,
    this.initialFactualMatrix,
  });

  @override
  ConsumerState<AiSectionAdvisorScreen> createState() => _AiSectionAdvisorScreenState();
}

class _AiSectionAdvisorScreenState extends ConsumerState<AiSectionAdvisorScreen> {
  late final TextEditingController _factController;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String? _errorMessage;
  AiOffenseAnalysisResult? _result;
  final Set<String> _selectedSections = {};

  final List<Map<String, String>> _sampleScenarios = [
    {
      'label': '🔫 अवैध तमंचा बरामदगी',
      'text': 'अभियुक्त के कब्जे से चेकिंग के दौरान 315 बोर का एक अवैध तमंचा व दो जिंदा कारतूस बरामद हुए। मौके पर कोई स्वतंत्र साक्षी मौजूद नहीं था।',
    },
    {
      'label': '⚔️ भूमि विवाद व मारपीट',
      'text': 'खेत की मेड़ को लेकर दो पक्षों में विवाद हुआ। लाठी-डंडों से मारपीट की गई जिसमें वादी के सिर में चोट आई तथा जान से मारने की धमकी दी गई।',
    },
    {
      'label': '💊 नशीला पदार्थ बरामदगी (NDPS)',
      'text': 'मुखबिर की सूचना पर पुलिस ने अभियुक्त को गिरफ्तार किया जिसके थैले से 120 ग्राम चरस बरामद हुई। तलाशी राजपत्रित अधिकारी के समक्ष नहीं ली गई।',
    },
    {
      'label': '📄 5 लाख का चेक बाउंस',
      'text': 'व्यावसायिक लेनदेन में अभियुक्त द्वारा 5 लाख का चेक दिया गया जो खाते में अपर्याप्त धनराशि के कारण अनादरित हो गया। विधिक नोटिस के बाद भी भुगतान नहीं हुआ।',
    },
  ];

  @override
  void initState() {
    super.initState();
    _factController = TextEditingController(text: widget.initialFactualMatrix ?? '');
    if (widget.initialFactualMatrix != null && widget.initialFactualMatrix!.trim().length > 15) {
      // Automatically trigger analysis if initial facts are provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAnalysis();
      });
    }
  }

  @override
  void dispose() {
    _factController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final text = _factController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया घटना या एफ.आई.आर. का विवरण दर्ज करें या बोलें।'),
          backgroundColor: StitchColors.alertCrimson,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(aiSectionAdvisorServiceProvider);
      final result = await service.analyzeOffense(factualMatrix: text);

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
          _selectedSections.clear();
          for (final sec in result.identifiedSections) {
            _selectedSections.add(sec.formattedKey);
          }
        });

        // Smooth scroll to results
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              320.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'विश्लेषण में त्रुटि: $e';
        });
      }
    }
  }

  void _openVoiceDictation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CourtVoiceDictationSheet(
          onDictationTransferred: (VoiceDictationResult res) {
            final spokenText = res.cleanedFactualMatrix.isNotEmpty
                ? res.cleanedFactualMatrix
                : res.verbatimTranscriptHindi;
            if (spokenText.isNotEmpty) {
              setState(() {
                if (_factController.text.trim().isEmpty) {
                  _factController.text = spokenText;
                } else {
                  _factController.text = '${_factController.text.trim()}\n$spokenText';
                }
              });
            }
          },
        ),
      ),
    );
  }

  void _applySelectedSections() {
    if (_selectedSections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया कम से कम एक धारा का चयन करें।'),
          backgroundColor: StitchColors.alertCrimson,
        ),
      );
      return;
    }
    Navigator.of(context).pop(_selectedSections.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: StitchColors.courtNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'एआई अपराध धारा विश्लेषक',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '360° विधिक विश्लेषण एवं बचाव/अभियोजन रणनीति',
              style: TextStyle(fontSize: 11, color: Color(0xFFDAE2FD)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'वॉयस इनपुट',
            icon: const Icon(Icons.mic, color: Colors.amber),
            onPressed: _openVoiceDictation,
          ),
        ],
      ),
      bottomNavigationBar: _result != null && _result!.identifiedSections.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedSections.length} धाराएं चयनित',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: StitchColors.courtNavy,
                            ),
                          ),
                          const Text(
                            'केस डायरी में सीधे ट्रांसफर करें',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StitchColors.courtNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'केस में धाराएं जोड़ें',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _applySelectedSections,
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1C32), Color(0xFF1E3A68)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'तथ्यों से 100% प्रामाणिक धाराएं एवं रणनीति',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'FIR का विवरण, बरामदगी, या घटनाक्रम लिखें या बोलें। एआई BNS, IPC एवं सभी विशेष अधिनियमों (Special Acts) का परीक्षण करेगा।',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFFDAE2FD), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Text Input Box
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'घटना / प्रथम सूचना विवरण (Incident Narrative)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF131B2E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _openVoiceDictation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.mic, size: 14, color: Color(0xFF946200)),
                                SizedBox(width: 4),
                                Text(
                                  'बोलें (Dictate)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF946200),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _factController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 13, height: 1.45),
                      decoration: InputDecoration(
                        hintText:
                            'उदा. दिनांक 12/03/2026 को चेकिंग के दौरान अभियुक्त की मोटरसाइकिल से एक अवैध देशी तमंचा 315 बोर मय 2 कारतूस बरामद किया गया। वादी ने आरोप लगाया कि अभियुक्त ने पुरानी रंजिश में फायरिंग की...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: StitchColors.courtNavy, width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Scenario Chips
                    const Text(
                      'त्वरित उदाहरण (Quick Templates):',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _sampleScenarios.map((sc) {
                        return ActionChip(
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          label: Text(
                            sc['label']!,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                          ),
                          onPressed: () {
                            setState(() {
                              _factController.text = sc['text']!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Run Analysis Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StitchColors.courtNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 20, color: Colors.amber),
                        label: Text(
                          _isLoading
                              ? 'विधिक विश्लेषण प्रगति पर है...'
                              : '360° विधिक विश्लेषण एवं धाराएं निकालें',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading ? null : _runAnalysis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error Display
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB4A9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: StitchColors.alertCrimson),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12.5, color: StitchColors.alertCrimson),
                      ),
                    ),
                  ],
                ),
              ),

            // Analysis Results
            if (_result != null) ...[
              // Summary Badge
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.summarize_outlined, color: StitchColors.courtNavy, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'घटना का विधिक निष्कर्ष (Legal Analysis Summary)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: StitchColors.courtNavy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_result!.identifiedSections.length} धाराएं चिन्हित',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.analysisSummary,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Identified Sections Header
              const Row(
                children: [
                  Icon(Icons.gavel, color: StitchColors.courtNavy, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'पहचानी गई विधिक धाराएं (Identified Sections)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Section Cards
              ..._result!.identifiedSections.map((sec) {
                final isSelected = _selectedSections.contains(sec.formattedKey);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSections.remove(sec.formattedKey);
                        } else {
                          _selectedSections.add(sec.formattedKey);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF2563EB),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedSections.add(sec.formattedKey);
                                    } else {
                                      _selectedSections.remove(sec.formattedKey);
                                    }
                                  });
                                },
                              ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: StitchColors.courtNavy,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sec.actName,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'धारा ${sec.sectionNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sec.isBailable ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  sec.isBailable ? 'जमानतीय' : 'गैर-जमानतीय',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: sec.isBailable ? const Color(0xFF166534) : const Color(0xFF9F1239),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 44.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sec.titleHindi,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sec.descriptionHindi,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'अधिकतम सजा: ${sec.maxPunishment}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sec.isCognizable ? 'संज्ञेय' : 'असंज्ञेय',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // 360° Defense Strategies
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFF15803D), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '360° बचाव रणनीति (Defense Strategy & Court Loopholes)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._result!.defendingStrategies.map((strat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  strat,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Attacking / Prosecution Points
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.policy_outlined, color: Color(0xFFB91C1C), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'अभियोजन / वादी आक्रमण बिंदु (Prosecution Checklist)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._result!.attackingStrategies.map((atk) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right_rounded, color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  atk,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Landmark Precedents
              if (_result!.landmarkPrecedents.isNotEmpty)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.menu_book_outlined, color: Color(0xFF4338CA), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'संबद्ध सर्वोच्च एवं उच्च न्यायालय की नजीरें (Landmark Precedents)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._result!.landmarkPrecedents.map((prec) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        prec.caseTitle,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF312E81),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFC7D2FE)),
                                      ),
                                      child: Text(
                                        prec.citation,
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  prec.legalPrincipleHindi,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF374151), height: 1.3),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}
