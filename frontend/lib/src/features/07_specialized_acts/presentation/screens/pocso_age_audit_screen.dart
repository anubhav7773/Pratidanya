import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../data/specialized_acts_repository.dart';
import '../../domain/specialized_act_models.dart';

class PocsoAgeAuditScreen extends ConsumerStatefulWidget {
  final String caseId;

  const PocsoAgeAuditScreen({super.key, required this.caseId});

  @override
  ConsumerState<PocsoAgeAuditScreen> createState() => _PocsoAgeAuditScreenState();
}

class _PocsoAgeAuditScreenState extends ConsumerState<PocsoAgeAuditScreen> {
  DateTime _incidentDate = DateTime.now().subtract(const Duration(days: 60));
  final _firAgeController = TextEditingController();

  bool _hasMatriculation = false;
  final DateTime? _matriculationDob = null;

  bool _hasSchoolCert = false;
  final DateTime? _schoolDob = null;

  bool _hasMunicipal = false;
  final DateTime? _municipalDob = null;

  bool _ossificationConducted = false;
  final _lowerAgeController = TextEditingController();
  final _upperAgeController = TextEditingController();

  bool _priorRelationship = false;
  final _delayDaysController = TextEditingController();
  bool _noInjuries = false;

  bool _isLoading = false;
  PocsoAgeEvaluationResult? _result;

  @override
  void dispose() {
    _firAgeController.dispose();
    _lowerAgeController.dispose();
    _upperAgeController.dispose();
    _delayDaysController.dispose();
    super.dispose();
  }

  void _runEvaluation() async {
    final firAge = int.tryParse(_firAgeController.text.trim()) ?? 15;
    final lower = double.tryParse(_lowerAgeController.text.trim());
    final upper = double.tryParse(_upperAgeController.text.trim());
    final delay = int.tryParse(_delayDaysController.text.trim()) ?? 0;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(specializedActsRepositoryProvider);
      final res = await repo.evaluatePocsoAge(
        caseId: widget.caseId,
        incidentDate: _incidentDate,
        firAge: firAge,
        hasMatriculation: _hasMatriculation,
        matriculationDob: _matriculationDob,
        hasSchoolCert: _hasSchoolCert,
        schoolDob: _schoolDob,
        hasMunicipalCert: _hasMunicipal,
        municipalDob: _municipalDob,
        ossificationConducted: _ossificationConducted,
        lowerAge: lower,
        upperAge: upper,
        priorRelationship: _priorRelationship,
        delayDays: delay,
        noInjuries: _noInjuries,
      );

      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('आयु मूल्यांकन त्रुटि: $e'), backgroundColor: StitchColors.alertCrimson),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('पॉक्सो आयु निर्धारण (Sec 94 JJ Act Audit)', style: TextStyle(height: 1.42)),
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
                    'घटना दिनांक एवं प्राथमिक सूचना',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('घटना दिनांक', style: TextStyle(fontSize: 12.5, height: 1.40)),
                          subtitle: Text(
                            '${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, height: 1.40),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _incidentDate,
                                firstDate: DateTime(2015),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _incidentDate = picked);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _firAgeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'FIR में कथित आयु (वर्ष)',
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
                    'धारा 94 किशोर न्याय अधिनियम: सांविधिक वरीयता क्रम',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('प्रथम वरीयता: मैट्रिकुलेशन प्रमाण पत्र उपलब्ध है?', style: TextStyle(height: 1.42)),
                    value: _hasMatriculation,
                    onChanged: (val) => setState(() => _hasMatriculation = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('प्रथम वरीयता: प्रथम प्रवेश विद्यालय रजिस्टर उपलब्ध है?', style: TextStyle(height: 1.42)),
                    value: _hasSchoolCert,
                    onChanged: (val) => setState(() => _hasSchoolCert = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('द्वितीय वरीयता: नगर निगम द्वारा जारी जन्म प्रमाण पत्र?', style: TextStyle(height: 1.42)),
                    value: _hasMunicipal,
                    onChanged: (val) => setState(() => _hasMunicipal = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('तृतीय वरीयता: मेडिकल बोर्ड द्वारा अस्थि परीक्षण (Ossification)?', style: TextStyle(height: 1.42)),
                    value: _ossificationConducted,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _ossificationConducted = val ?? false),
                  ),
                  if (_ossificationConducted) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lowerAgeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'रेडियोलॉजिकल न्यूनतम आयु',
                                labelStyle: TextStyle(height: 1.40),
                              ),
                              style: const TextStyle(height: 1.40),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _upperAgeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'रेडियोलॉजिकल अधिकतम आयु',
                                labelStyle: TextStyle(height: 1.40),
                              ),
                              style: const TextStyle(height: 1.40),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 28),

                  Text(
                    'धारा 29/30 सांविधिक उपधारणा खंडन (Defense Angles)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('पूर्व से प्रेम प्रसंग / आपसी सहमति का साक्ष्य विद्यमान है?', style: TextStyle(height: 1.42)),
                    value: _priorRelationship,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _priorRelationship = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('चिकित्सीय परीक्षण में किसी चोट का अभाव?', style: TextStyle(height: 1.42)),
                    value: _noInjuries,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _noInjuries = val ?? false),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: TextField(
                      controller: _delayDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'FIR दर्ज कराने में अकारण विलंब (दिनों में)',
                        labelStyle: TextStyle(height: 1.40),
                      ),
                      style: const TextStyle(height: 1.40),
                    ),
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
                          : const Icon(Icons.how_to_reg),
                      label: Text(_isLoading ? 'विश्लेषण जारी है...' : 'आयु निर्धारण एवं जमानत आधार निकालें', style: const TextStyle(height: 1.40)),
                      onPressed: _isLoading ? null : _runEvaluation,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: _result!.isMajorityProbable ? StitchColors.verifiedGreenBg : StitchColors.unverifiedAmberBg,
                        border: Border.all(color: _result!.isMajorityProbable ? StitchColors.verifiedGreen : StitchColors.unverifiedAmber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _result!.isMajorityProbable
                                ? 'वयस्कता संभावित (Majority Probable - Benefit to Accused)'
                                : 'अवयस्कता का अनुमान (Minority Assumed)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.42,
                              color: _result!.isMajorityProbable ? StitchColors.verifiedGreen : StitchColors.unverifiedAmber,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _result!.ageDeterminationAnalysisHindi,
                            style: const TextStyle(fontSize: 12.5, height: 1.42),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'उपधारणा खंडन विधिक रणनीति (Rebuttal Strategy):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42),
                    ),
                    const SizedBox(height: 6),
                    ..._result!.presumptionRebuttalStrategy.map((s) => Card(
                          margin: const EdgeInsets.only(bottom: 6.0),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(s, style: const TextStyle(fontSize: 12.5, height: 1.42)),
                          ),
                        )),
                    const Divider(height: 24),

                    const Text(
                      'जमानत प्रार्थना पत्र हेतु तैयार आधार:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42),
                    ),
                    const SizedBox(height: 6),
                    ..._result!.bailGroundsPocso.map((g) => Card(
                          margin: const EdgeInsets.only(bottom: 6.0),
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
