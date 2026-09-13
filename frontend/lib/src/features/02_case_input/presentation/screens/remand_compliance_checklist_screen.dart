import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../data/remand_repository.dart';
import '../../domain/arrest_compliance_models.dart';

class RemandComplianceChecklistScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const RemandComplianceChecklistScreen({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<RemandComplianceChecklistScreen> createState() =>
      _RemandComplianceChecklistScreenState();
}

class _RemandComplianceChecklistScreenState
    extends ConsumerState<RemandComplianceChecklistScreen> {
  final DateTime _arrestTime = DateTime.now().subtract(const Duration(hours: 18));
  final DateTime _productionTime = DateTime.now();

  bool _noticeIssuedSec35 = false;
  bool _flightRiskRecorded = false;
  int _witnessCount = 0;
  bool _familyIntimation = false;
  bool _medicalConducted = true;
  bool _magistrateReasons = false;

  bool _isLoading = false;
  ArrestComplianceAuditResult? _result;

  void _runAudit() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(remandRepositoryProvider);
      final res = await repo.auditArrestCompliance(
        caseId: widget.caseId,
        accusedName: widget.accusedName,
        policeStation: widget.policeStation,
        district: widget.district,
        courtName: 'न्यायालय मुख्य न्यायिक मजिस्ट्रेट',
        charges: [
          {'act': 'BNS', 'section': '115(2)', 'max_punishment_years': 1, 'is_special_act': false},
          {'act': 'BNS', 'section': '352', 'max_punishment_years': 2, 'is_special_act': false},
          {'act': 'BNS', 'section': '351(2)', 'max_punishment_years': 3, 'is_special_act': false},
        ],
        arrestTimestamp: _arrestTime,
        remandProductionTimestamp: _productionTime,
        noticeIssuedSec35Bnss: _noticeIssuedSec35,
        flightOrTamperingRiskRecorded: _flightRiskRecorded,
        arrestMemoWitnessCount: _witnessCount,
        familyIntimationRecorded: _familyIntimation,
        medicalExaminationConducted: _medicalConducted,
        magistrateIndependentReasonsRecorded: _magistrateReasons,
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

  void _showPetitionSheet(String draftText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('रिमांड आपत्ति प्रार्थना पत्र (Draft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: draftText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('प्रार्थना पत्र कॉपी हो गया')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(draftText, style: const TextStyle(fontSize: 12.5, height: 1.45)),
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
        title: const Text('गिरफ्तारी व रिमांड अनुपालन परीक्षक'),
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
                    'सतेन्द्र कुमार अंतिल व अर्नेश कुमार प्रक्रियात्मक चेकलिस्ट',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'केस डायरी व रिमांड प्रपत्र के आधार पर विवरण दर्ज करें (7 वर्ष तक के मामलों में यांत्रिक रिमांड का विधिक विरोध):',
                    style: TextStyle(fontSize: 12, color: StitchColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  CheckboxListTile(
                    title: const Text('क्या धारा 35(3) BNSS / 41A CrPC का नोटिस दिया गया था?'),
                    subtitle: const Text('7 वर्ष तक दंडनीय अपराध में गिरफ्तारी से पूर्व लिखित नोटिस अनिवार्य है'),
                    value: _noticeIssuedSec35,
                    activeColor: StitchColors.verifiedGreen,
                    onChanged: (val) => setState(() => _noticeIssuedSec35 = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('क्या केस डायरी में फरार होने/साक्ष्य मिटाने के ठोस कारण दर्ज हैं?'),
                    subtitle: const Text('अर्नेश कुमार: सामान्य व यांत्रिक कारण गिरफ्तारी को शून्य बनाते हैं'),
                    value: _flightRiskRecorded,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _flightRiskRecorded = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('गिरफ्तारी मेमो पर कम से कम एक स्वतंत्र स्थानीय साक्षी के हस्ताक्षर हैं?'),
                    subtitle: const Text('डी.के. बासु निर्देश: स्थानीय स्वतंत्र साक्षी या परिजन अनिवार्य'),
                    value: _witnessCount > 0,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _witnessCount = (val ?? false) ? 1 : 0),
                  ),
                  CheckboxListTile(
                    title: const Text('क्या परिजन/नामित व्यक्ति को गिरफ्तारी की लिखित सूचना दी गई?'),
                    value: _familyIntimation,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _familyIntimation = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('क्या अभियुक्त का विहित चिकित्सीय परीक्षण (Medical) कराया गया?'),
                    value: _medicalConducted,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _medicalConducted = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('क्या मजिस्ट्रेट ने स्वतंत्र संतुष्टि व कारण दर्ज किए हैं?'),
                    subtitle: const Text('अंतिल दिशानिर्देश: यांत्रिक रिमांड पर मजिस्ट्रेट अनुशासनात्मक कार्रवाई के उत्तरदायी हैं'),
                    value: _magistrateReasons,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _magistrateReasons = val ?? false),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StitchColors.courtNavy,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.gavel),
                      label: Text(_isLoading ? 'समीक्षा जारी है...' : 'प्रक्रियात्मक वैधता जांचें व आपत्ति बनाएं'),
                      onPressed: _isLoading ? null : _runAudit,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: _result!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST'
                            ? StitchColors.alertCrimsonBg
                            : StitchColors.verifiedGreenBg,
                        border: Border.all(
                          color: _result!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST'
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
                                _result!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST'
                                    ? Icons.error_rounded
                                    : Icons.check_circle_rounded,
                                color: _result!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST'
                                    ? StitchColors.alertCrimson
                                    : StitchColors.verifiedGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _result!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST'
                                      ? 'गिरफ्तारी अवैध / यांत्रिक रिमांड दोष (Void Arrest Detected)'
                                      : 'प्रक्रियात्मक अनुपालन वैध',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _result!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST'
                                        ? StitchColors.alertCrimson
                                        : StitchColors.verifiedGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'वर्गीकरण: ${_result!.antilCategory} (सतेन्द्र कुमार अंतिल) | 24 घंटे की सीमा: ${_result!.isConstitutionallyTimeBarred ? "उल्लंघन" : "वैध"} (${_result!.hoursToProduction} घंटे)',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _result!.magistrateDirectiveRecommendation,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('पहचाने गए वैधानिक उल्लंघन:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 6),
                    ..._result!.violations.map((v) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: Icon(
                              v.severity == 'FATAL' ? Icons.dangerous : Icons.warning_amber,
                              color: v.severity == 'FATAL' ? StitchColors.alertCrimson : Colors.orange,
                            ),
                            title: Text(v.statutoryProvision, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${v.findingHindi}\nउपाय: ${v.actionableRemedy}', style: const TextStyle(fontSize: 12, height: 1.35)),
                          ),
                        )),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.description),
                        label: const Text('रिमांड आपत्ति प्रार्थना पत्र देखें व प्रिंट करें'),
                        onPressed: () => _showPetitionSheet(_result!.instantObjectionPetitionDraft),
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
