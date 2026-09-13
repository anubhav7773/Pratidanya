import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../data/regional_acts_repository.dart';
import '../../domain/regional_acts_models.dart';

class RegionalActsAuditScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const RegionalActsAuditScreen({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<RegionalActsAuditScreen> createState() => _RegionalActsAuditScreenState();
}

class _RegionalActsAuditScreenState extends ConsumerState<RegionalActsAuditScreen> {
  String _selectedStatute = 'UP_GANGSTERS_ACT_1986';

  // Gangsters Act parameters
  bool _jointMeetingRule5 = false;
  bool _dmIndependentMind = false;
  final _dmEndorsementController = TextEditingController(
    text: 'Approved as recommended (संस्तुति स्वीकृत - मोहर हस्ताक्षर)',
  );
  final List<BasePredicateCase> _baseCases = [
    BasePredicateCase(
      crimeNumber: 'मु.अ.सं. 112/2021',
      sections: '379/411 IPC',
      status: 'ACQUITTED_ON_MERITS',
      disposalDate: '2023-11-20',
    )
  ];

  // Goondas Act parameters
  bool _noticeMaterialAllegations = false;
  bool _noticeOnlyFirs = true;

  bool _isLoading = false;
  RegionalActsAuditResult? _result;

  @override
  void dispose() {
    _dmEndorsementController.dispose();
    super.dispose();
  }

  void _runAudit() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(regionalActsRepositoryProvider);
      final res = await repo.auditUpSpecialActs(
        caseId: widget.caseId,
        statuteApplied: _selectedStatute,
        district: widget.district,
        policeStation: widget.policeStation,
        accusedName: widget.accusedName,
        jointMeetingRule5Documented: _jointMeetingRule5,
        dmIndependentMindApplied: _dmIndependentMind,
        dmEndorsementRawText: _dmEndorsementController.text.trim(),
        baseCases: _baseCases,
        noticeHasMaterialAllegations: _noticeMaterialAllegations,
        noticeOnlyListsFirs: _noticeOnlyFirs,
      );

      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('मूल्यांकन त्रुटि: $e'),
            backgroundColor: StitchColors.alertCrimson,
          ),
        );
      }
    }
  }

  void _showPetitionSheet(String draftText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'माननीय उच्च न्यायालय रिट याचिका (Art. 226)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: draftText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('रिट याचिका क्लिपबोर्ड पर कॉपी हो गई')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  draftText,
                  style: const TextStyle(fontSize: 12.5, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('उ.प्र. प्रादेशिक विशेष अधिनियम परीक्षक'),
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'गैंगस्टर्स रूल्स 2021 व गुंडा एक्ट धारा 3 नोटिस ऑडिट',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'फरहाना (2024), राधा (2022) व रामजी पांडेय पूर्ण पीठ (1981) के आलोक में प्रशासनिक अवैधताओं का परीक्षण:',
                    style: TextStyle(fontSize: 12, color: StitchColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedStatute,
                    decoration: const InputDecoration(
                      labelText: 'संबंधित प्रादेशिक अधिनियम',
                      border: OutlineInputBorder(),
                    ),

                    items: const [
                      DropdownMenuItem(
                        value: 'UP_GANGSTERS_ACT_1986',
                        child: Text('उ.प्र. गिरोहबंद अधिनियम, 1986 व नियमावली 2021'),
                      ),
                      DropdownMenuItem(
                        value: 'UP_GOONDAS_ACT_1970',
                        child: Text('उ.प्र. गुंडा नियंत्रण अधिनियम, 1970 (जिला बदर)'),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedStatute = val ?? _selectedStatute),
                  ),
                  const SizedBox(height: 14),

                  if (_selectedStatute == 'UP_GANGSTERS_ACT_1986') ...[
                    CheckboxListTile(
                      title: const Text('क्या नियम 5(3)(a) की संयुक्त बैठक (DM & SSP) दर्ज है?'),
                      subtitle: const Text('नियम 5: डीएम और एसएसपी की बैठक के मिनट्स के बिना अनुमोदन शून्य है'),
                      value: _jointMeetingRule5,
                      activeColor: StitchColors.courtNavy,
                      onChanged: (val) => setState(() => _jointMeetingRule5 = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('क्या जिला मजिस्ट्रेट ने स्वतंत्र संतुष्टि दर्ज की है?'),
                      subtitle: const Text('नियम 16: केवल मोहर या यांत्रिक हस्ताक्षर अनुमोदन को अवैध बनाते हैं'),
                      value: _dmIndependentMind,
                      activeColor: StitchColors.courtNavy,
                      onChanged: (val) => setState(() => _dmIndependentMind = val ?? false),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dmEndorsementController,
                      decoration: const InputDecoration(
                        labelText: 'गैंग चार्ट पर DM का पृष्ठांकन / आदेश',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'आधारभूत मुकदमे (Predicate Base Cases):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('मुकदमा जोड़ें'),
                          onPressed: () {
                            setState(() {
                              _baseCases.add(BasePredicateCase(
                                crimeNumber: 'मु.अ.सं. ${_baseCases.length + 100}/2022',
                                sections: '380 IPC',
                                status: 'ACQUITTED_ON_MERITS',
                              ));
                            });
                          },
                        ),
                      ],
                    ),
                    ..._baseCases.map((c) => ListTile(
                          tileColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          leading: const Icon(Icons.gavel, size: 20, color: StitchColors.courtNavy),
                          title: Text('${c.crimeNumber} (${c.sections})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('स्थिति: ${c.status}', style: const TextStyle(fontSize: 11.5, color: Colors.green)),
                        )),
                  ] else ...[
                    CheckboxListTile(
                      title: const Text('क्या नोटिस में भौतिक आरोपों का सामान्य स्वरूप दर्ज है?'),
                      subtitle: const Text('रामजी पांडेय पूर्ण पीठ: केवल मुकदमों की संख्या लिखना नोटिस को शून्य बनाता है'),
                      value: _noticeMaterialAllegations,
                      activeColor: StitchColors.courtNavy,
                      onChanged: (val) => setState(() => _noticeMaterialAllegations = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('क्या नोटिस में मात्र मुकदमों की सूची दी गई है?'),
                      value: _noticeOnlyFirs,
                      activeColor: StitchColors.courtNavy,
                      onChanged: (val) => setState(() => _noticeOnlyFirs = val ?? false),
                    ),
                  ],
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: StitchColors.courtNavy, foregroundColor: Colors.white),
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.verified),
                      label: Text(_isLoading ? 'समीक्षा जारी है...' : 'प्रशासनिक वैधता जांचें व रिट तैयार करें'),
                      onPressed: _isLoading ? null : _runAudit,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: _result!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE'
                            ? StitchColors.alertCrimsonBg
                            : StitchColors.verifiedGreenBg,
                        border: Border.all(
                          color: _result!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE'
                              ? StitchColors.alertCrimson
                              : StitchColors.verifiedGreen,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _result!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE'
                                    ? Icons.cancel_rounded
                                    : Icons.check_circle_rounded,
                                color: _result!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE'
                                    ? StitchColors.alertCrimson
                                    : StitchColors.verifiedGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _result!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE'
                                      ? 'गैंग चार्ट / नोटिस अधिकारिताविहीन (Fatal Defect Detected)'
                                      : 'प्रशासनिक प्रक्रिया नियमित',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _result!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE'
                                        ? StitchColors.alertCrimson
                                        : StitchColors.verifiedGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('उपयुक्त न्यायालय: ${_result!.recommendedForum}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('पहचाने गए विधिक आधार (Grounds of Challenge):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 6),
                    ..._result!.groundsOfChallenge.map((g) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: Icon(
                              g.severity == 'JURISDICTIONAL_FATALITY' || g.severity == 'SUBSTANTIVE_FATALITY'
                                  ? Icons.dangerous
                                  : Icons.warning_amber,
                              color: StitchColors.alertCrimson,
                            ),
                            title: Text(g.ruleOrStatute, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            subtitle: Text('${g.argumentHindi}\nउपाय: ${g.statutoryRemedy}', style: const TextStyle(fontSize: 12, height: 1.35)),
                          ),
                        )),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: StitchColors.courtNavy, foregroundColor: Colors.white),
                        icon: const Icon(Icons.description),
                        label: const Text('उच्च न्यायालय अनुच्छेद 226 रिट याचिका देखें'),
                        onPressed: () => _showPetitionSheet(_result!.draftPetitionHindi),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
