import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../data/specialized_acts_repository.dart';
import '../../domain/specialized_act_models.dart';

class NdpsComplianceScreen extends ConsumerStatefulWidget {
  final String caseId;

  const NdpsComplianceScreen({super.key, required this.caseId});

  @override
  ConsumerState<NdpsComplianceScreen> createState() => _NdpsComplianceScreenState();
}

class _NdpsComplianceScreenState extends ConsumerState<NdpsComplianceScreen> {
  String _selectedSubstance = 'Ganja';
  final _quantityController = TextEditingController(text: '850');
  bool _isPersonalSearch = true;
  bool _section50NoticeGiven = true;
  final String _noticeType = 'THIRD_OPTION_DEFECT';
  bool _searchedBeforeGazetted = false;
  bool _searchedBeforeMagistrate = false;
  bool _thirdOptionDefect = true;
  bool _independentWitnesses = false;
  bool _sampleDrawnUnder52A = false;

  bool _isLoading = false;
  NdpsComplianceResult? _result;

  final List<String> _substances = ['Ganja', 'Charas', 'Heroin', 'Smack', 'Opium', 'Tramadol', 'Alprazolam'];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _runEvaluation() async {
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(specializedActsRepositoryProvider);
      final res = await repo.evaluateNdps(
        caseId: widget.caseId,
        substanceName: _selectedSubstance,
        quantityGrams: qty,
        isPersonalSearch: _isPersonalSearch,
        section50NoticeGiven: _section50NoticeGiven,
        noticeType: _noticeType == 'THIRD_OPTION_DEFECT' ? 'WRITTEN_INDEPENDENT' : _noticeType,
        wasSearchedBeforeGazettedOfficer: _searchedBeforeGazetted,
        wasSearchedBeforeMagistrate: _searchedBeforeMagistrate,
        thirdOptionDefect: _thirdOptionDefect,
        independentWitnesses: _independentWitnesses,
        sampleDrawnUnder52A: _sampleDrawnUnder52A,
      );

      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('मूल्यांकन त्रुटि: $e'), backgroundColor: StitchColors.alertCrimson),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('एन.डी.पी.एस. अनुपालन एवं धारा 50 परीक्षण', style: TextStyle(height: 1.42)),
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
                    'स्वापक पदार्थ एवं मात्रा वर्गीकरण',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSubstance,
                          decoration: InputDecoration(
                            labelText: 'मादक पदार्थ (Substance)',
                            labelStyle: const TextStyle(height: 1.40),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: _substances.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(height: 1.40)))).toList(),
                          onChanged: (val) => setState(() => _selectedSubstance = val ?? _selectedSubstance),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'कथित मात्रा (ग्राम में)',
                            labelStyle: const TextStyle(height: 1.40),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(height: 1.40),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  Text(
                    'धारा 50 आज्ञापक परीक्षण (व्यक्तिगत तलाशी)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('क्या तलाशी अभियुक्त के शरीर (व्यक्तिगत) से ली गई?', style: TextStyle(height: 1.42)),
                    subtitle: const Text('यदि बैग/वाहन/मकान से है तो धारा 50 लागू नहीं होती', style: TextStyle(height: 1.40)),
                    value: _isPersonalSearch,
                    activeThumbColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _isPersonalSearch = val),
                  ),
                  if (_isPersonalSearch) ...[
                    CheckboxListTile(
                      title: const Text('धारा 50 का विधिक नोटिस दिया गया था?', style: TextStyle(height: 1.42)),
                      value: _section50NoticeGiven,
                      activeColor: StitchColors.courtNavy,
                      onChanged: (val) => setState(() => _section50NoticeGiven = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('तीसरा अवैध विकल्प दिया गया? ("या आप हमारी तलाशी ले सकते हैं")', style: TextStyle(height: 1.42)),
                      subtitle: const Text('विजयासिंह जडेजा संविधान पीठ: तीसरा विकल्प संपूर्ण जब्ती दूषित करता है', style: TextStyle(height: 1.40)),
                      value: _thirdOptionDefect,
                      activeColor: StitchColors.alertCrimson,
                      onChanged: (val) => setState(() => _thirdOptionDefect = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('तलाशी राजपत्रित अधिकारी के समक्ष हुई?', style: TextStyle(height: 1.42)),
                      value: _searchedBeforeGazetted,
                      activeColor: StitchColors.verifiedGreen,
                      onChanged: (val) => setState(() => _searchedBeforeGazetted = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('तलाशी न्यायिक मजिस्ट्रेट के समक्ष हुई?', style: TextStyle(height: 1.42)),
                      value: _searchedBeforeMagistrate,
                      activeColor: StitchColors.verifiedGreen,
                      onChanged: (val) => setState(() => _searchedBeforeMagistrate = val ?? false),
                    ),
                  ],
                  const Divider(height: 28),

                  Text(
                    'धारा 52A एवं जब्ती साक्ष्य शृंखला (Link Evidence)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('स्वतंत्र गवाह मौके पर उपस्थित थे?', style: TextStyle(height: 1.42)),
                    value: _independentWitnesses,
                    onChanged: (val) => setState(() => _independentWitnesses = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('धारा 52A: नमूने मजिस्ट्रेट के समक्ष प्रमाणित कराए गए?', style: TextStyle(height: 1.42)),
                    subtitle: const Text('भारत संघ बनाम मोहनलाल: मजिस्ट्रेट प्रमाणीकरण अनिवार्य है', style: TextStyle(height: 1.40)),
                    value: _sampleDrawnUnder52A,
                    onChanged: (val) => setState(() => _sampleDrawnUnder52A = val ?? false),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StitchColors.courtNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.security),
                      label: Text(_isLoading ? 'विश्लेषण जारी है...' : 'विधिक अनुपालन एवं जमानत आधार जांचें', style: const TextStyle(height: 1.40)),
                      onPressed: _isLoading ? null : _runEvaluation,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: _result!.section50ComplianceStatus == 'FATAL_DEFECT'
                            ? StitchColors.alertCrimsonBg
                            : StitchColors.verifiedGreenBg,
                        border: Border.all(
                          color: _result!.section50ComplianceStatus == 'FATAL_DEFECT'
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
                                _result!.section50ComplianceStatus == 'FATAL_DEFECT'
                                    ? Icons.cancel_rounded
                                    : Icons.check_circle_rounded,
                                color: _result!.section50ComplianceStatus == 'FATAL_DEFECT'
                                    ? StitchColors.alertCrimson
                                    : StitchColors.verifiedGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _result!.section50ComplianceStatus == 'FATAL_DEFECT'
                                      ? 'धारा 50 का गंभीर उल्लंघन (Fatal Procedural Defect Detected)'
                                      : 'धारा 50 प्रक्रियात्मक रूप से वैध',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    height: 1.42,
                                    color: _result!.section50ComplianceStatus == 'FATAL_DEFECT'
                                        ? StitchColors.alertCrimson
                                        : StitchColors.verifiedGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'वर्गीकरण: ${_result!.quantityCategory} | धारा 37 प्रतिबंध: ${_result!.isSection37BarApplicable ? "लागू" : "लागू नहीं"}',
                            style: const TextStyle(height: 1.42),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('पहचानी गई प्रक्रियात्मक कमियां:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42)),
                    const SizedBox(height: 6),
                    ..._result!.detectedProceduralDefects.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right, size: 20, color: StitchColors.alertCrimson),
                              Expanded(child: Text(d, style: const TextStyle(fontSize: 13, height: 1.42))),
                            ],
                          ),
                        )),
                    const Divider(height: 24),

                    const Text('जमानत प्रार्थना पत्र हेतु तैयार विधिक आधार:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42)),
                    const SizedBox(height: 6),
                    ..._result!.tailoredBailGrounds.map((g) => Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(g, style: const TextStyle(fontSize: 12.5, height: 1.45)),
                          ),
                        )),
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
