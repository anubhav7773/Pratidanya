import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../data/specialized_acts_repository.dart';
import '../../domain/scst_ni_models.dart';

class ScstAppealScreen extends ConsumerStatefulWidget {
  final String caseId;

  const ScstAppealScreen({super.key, required this.caseId});

  @override
  ConsumerState<ScstAppealScreen> createState() => _ScstAppealScreenState();
}

class _ScstAppealScreenState extends ConsumerState<ScstAppealScreen> {
  String _placeType = 'PRIVATE_HOUSE_ROOM';
  bool _independentWitnesses = false;
  final bool _casteNameAlleged = true;
  bool _priorCivilDispute = true;
  DateTime? _specialCourtOrderDate;
  bool _victimNoticeServed = false;

  bool _isLoading = false;
  ScstComplianceResult? _result;

  final Map<String, String> _placeOptions = {
    'PRIVATE_HOUSE_ROOM': 'निजी मकान / चारदीवारी के अंदर',
    'ENCLOSED_CHAMBER': 'निजी कार्यालय / चैंबर',
    'PUBLIC_ROAD': 'सार्वजनिक मार्ग / सड़क',
    'PUBLIC_GROUND': 'सार्वजनिक मैदान / बाजार',
    'VILLAGE_CHAUPAL': 'ग्राम चौपाल',
  };

  void _runEvaluation() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(specializedActsRepositoryProvider);
      final res = await repo.evaluateScst(
        caseId: widget.caseId,
        incidentPlaceType: _placeType,
        independentWitnesses: _independentWitnesses,
        casteNameAlleged: _casteNameAlleged,
        priorCivilDispute: _priorCivilDispute,
        specialCourtOrderDate: _specialCourtOrderDate,
        victimNoticeServed: _victimNoticeServed,
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
        title: const Text('एस.सी./एस.टी. एक्ट धारा 18 एवं 14A अपील परीक्षण', style: TextStyle(height: 1.42)),
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
                    'सार्वजनिक दृष्टिगोचर स्थान परीक्षण (Hitesh Verma Test)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _placeType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'कथित घटना स्थल की प्रकृति',
                      labelStyle: const TextStyle(height: 1.40),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _placeOptions.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.40))))
                        .toList(),
                    onChanged: (val) => setState(() => _placeType = val ?? _placeType),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('क्या घटना के समय जनता के स्वतंत्र साक्षी उपस्थित थे?', style: TextStyle(height: 1.42)),
                    value: _independentWitnesses,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _independentWitnesses = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('क्या दोनों पक्षों के मध्य पूर्व से भूमि / दीवानी विवाद लंबित है?', style: TextStyle(height: 1.42)),
                    subtitle: const Text('भूमि विवाद के चलते दर्ज मामलों में धारा 18 का प्रतिबंध निष्प्रभावी होता है', style: TextStyle(height: 1.40)),
                    value: _priorCivilDispute,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _priorCivilDispute = val ?? false),
                  ),
                  const Divider(height: 28),

                  Text(
                    'धारा 14A उच्च न्यायालय सांविधिक अपील (Appeal against Bail Rejection)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('विशेष न्यायालय द्वारा जमानत निरस्त करने का दिनांक', style: TextStyle(fontSize: 13, height: 1.40)),
                    subtitle: Text(
                      _specialCourtOrderDate != null
                          ? '${_specialCourtOrderDate!.day}/${_specialCourtOrderDate!.month}/${_specialCourtOrderDate!.year}'
                          : 'दिनांक चुनें (अपील मियाद 90-180 दिन)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1.40,
                        color: _specialCourtOrderDate != null ? StitchColors.courtNavy : Colors.grey,
                      ),
                    ),
                    trailing: OutlinedButton(
                      child: const Text('चुनें', style: TextStyle(height: 1.40)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _specialCourtOrderDate = picked);
                      },
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('धारा 15A(3): क्या पीड़ित/वादी को विधिक सूचना तामील हो चुकी है?', style: TextStyle(height: 1.42)),
                    subtitle: const Text('बिना तामील सूचना के जमानत आदेश अवैध घोषित हो सकता है', style: TextStyle(height: 1.40)),
                    value: _victimNoticeServed,
                    activeColor: StitchColors.verifiedGreen,
                    onChanged: (val) => setState(() => _victimNoticeServed = val ?? false),
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
                          : const Icon(Icons.gavel),
                      label: Text(_isLoading ? 'विश्लेषण जारी है...' : 'धारा 18 अग्रिम जमानत व अपील पोषणीयता जांचें', style: const TextStyle(height: 1.40)),
                      onPressed: _isLoading ? null : _runEvaluation,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: _result!.isAnticipatoryBailMaintainable
                            ? StitchColors.verifiedGreenBg
                            : StitchColors.unverifiedAmberBg,
                        border: Border.all(
                          color: _result!.isAnticipatoryBailMaintainable
                              ? StitchColors.verifiedGreen
                              : StitchColors.unverifiedAmber,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _result!.isAnticipatoryBailMaintainable ? Icons.verified : Icons.warning_amber,
                                color: _result!.isAnticipatoryBailMaintainable
                                    ? StitchColors.verifiedGreen
                                    : StitchColors.unverifiedAmber,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _result!.isAnticipatoryBailMaintainable
                                      ? 'अग्रिम जमानत पोषणीय (Sec 18 Bar Successfully Bypassed)'
                                      : 'धारा 18/18A प्रतिबंध लागू: नियमित जमानत / 14A अपील अनिवार्य',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    height: 1.42,
                                    color: _result!.isAnticipatoryBailMaintainable
                                        ? StitchColors.verifiedGreen
                                        : StitchColors.unverifiedAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_result!.section18BarBypassRatio, style: const TextStyle(fontSize: 12.5, height: 1.42)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Text(
                        _result!.mandatoryVictimNoticeWarning,
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.40),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('जमानत / अपील हेतु तैयार विधिक आधार:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42)),
                    const SizedBox(height: 6),
                    ..._result!.tailoredGrounds.map((g) => Card(
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
