import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../data/specialized_acts_repository.dart';
import '../../domain/scst_ni_models.dart';

class NiActDefenseScreen extends ConsumerStatefulWidget {
  final String caseId;

  const NiActDefenseScreen({super.key, required this.caseId});

  @override
  ConsumerState<NiActDefenseScreen> createState() => _NiActDefenseScreenState();
}

class _NiActDefenseScreenState extends ConsumerState<NiActDefenseScreen> {
  final _chequeNumberController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _chequeDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _returnMemoDate = DateTime.now().subtract(const Duration(days: 60));
  DateTime _noticeDispatchDate = DateTime.now().subtract(const Duration(days: 40));
  DateTime _noticeDeliveryDate = DateTime.now().subtract(const Duration(days: 35));
  DateTime _complaintDate = DateTime.now().subtract(const Duration(days: 28));

  bool _isOmnibusDefective = false;
  String _defenseCategory = 'SECURITY_CHEQUE';
  bool _seeksCompounding = false;

  bool _isLoading = false;
  NiActComplianceResult? _result;

  @override
  void dispose() {
    _chequeNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _runEvaluation() async {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(specializedActsRepositoryProvider);
      final res = await repo.evaluateNiAct(
        caseId: widget.caseId,
        chequeNumber: _chequeNumberController.text.trim(),
        chequeAmount: amt,
        chequeDate: _chequeDate,
        returnMemoDate: _returnMemoDate,
        noticeDispatchDate: _noticeDispatchDate,
        noticeDeliveryDate: _noticeDeliveryDate,
        isOmnibusDefective: _isOmnibusDefective,
        complaintFilingDate: _complaintDate,
        defenseCategory: _defenseCategory,
        seeksCompounding: _seeksCompounding,
      );

      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('एन.आई. एक्ट मूल्यांकन त्रुटि: $e'), backgroundColor: StitchColors.alertCrimson),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('धारा 138 एन.आई. एक्ट नोटिस व मियाद परीक्षण', style: TextStyle(height: 1.42)),
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
                    'चेक विवरण एवं धनराशि',
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
                        child: TextField(
                          controller: _chequeNumberController,
                          decoration: InputDecoration(
                            labelText: 'चेक संख्या',
                            labelStyle: const TextStyle(height: 1.40),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(height: 1.40),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'चेक धनराशि (₹)',
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
                  const SizedBox(height: 8),
                  _buildDatePickerTile('चेक पर अंकित दिनांक', _chequeDate, (d) => setState(() => _chequeDate = d)),
                  const Divider(height: 28),

                  Text(
                    'सांविधिक मियाद शृंखला (Statutory 30 & 15-Day Timeline)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildDatePickerTile('1. बैंक वापसी मेमो दिनांक', _returnMemoDate, (d) => setState(() => _returnMemoDate = d)),
                  _buildDatePickerTile('2. विधिक मांग नोटिस भेजने का दिनांक (30 दिन)', _noticeDispatchDate, (d) => setState(() => _noticeDispatchDate = d)),
                  _buildDatePickerTile('3. विधिक नोटिस प्राप्त/तामील होने का दिनांक', _noticeDeliveryDate, (d) => setState(() => _noticeDeliveryDate = d)),
                  _buildDatePickerTile('4. न्यायालय में परिवाद दाखिल करने का दिनांक', _complaintDate, (d) => setState(() => _complaintDate = d)),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('दोषपूर्ण एकमुश्त मांग (Omnibus Demand)?', style: TextStyle(height: 1.42)),
                    subtitle: const Text('चेक राशि में ब्याज या क्षतिपूर्ति मिलाकर एकमुश्त मांग की गई (K.R. Indira Defect)', style: TextStyle(height: 1.40)),
                    value: _isOmnibusDefective,
                    activeColor: StitchColors.alertCrimson,
                    onChanged: (val) => setState(() => _isOmnibusDefective = val ?? false),
                  ),
                  const Divider(height: 28),

                  Text(
                    'धारा 139 उपधारणा खंडन एवं धारा 147 शमन',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _defenseCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'बचाव की मुख्य विधिक श्रेणी',
                      labelStyle: const TextStyle(height: 1.40),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SECURITY_CHEQUE', child: Text('सुरक्षा चेक (Security Cheque) का दुरुपयोग', overflow: TextOverflow.ellipsis, style: TextStyle(height: 1.40))),
                      DropdownMenuItem(value: 'FINANCIAL_INCAPACITY', child: Text('परिवादी की वित्तीय क्षमता का खंडन (ITR/Source)', overflow: TextOverflow.ellipsis, style: TextStyle(height: 1.40))),
                      DropdownMenuItem(value: 'NO_EXISTING_DEBT', child: Text('कोई विधिक देयता विद्यमान नहीं थी', overflow: TextOverflow.ellipsis, style: TextStyle(height: 1.40))),
                    ],
                    onChanged: (val) => setState(() => _defenseCategory = val ?? _defenseCategory),
                  ),
                  CheckboxListTile(
                    title: const Text('धारा 147 के तहत शमन (Compounding / Settlement)?', style: TextStyle(height: 1.42)),
                    subtitle: const Text('दामोदर एस. प्रभु मार्गदर्शिका के अनुसार समझौते की तत्परता', style: TextStyle(height: 1.40)),
                    value: _seeksCompounding,
                    activeColor: StitchColors.verifiedGreen,
                    onChanged: (val) => setState(() => _seeksCompounding = val ?? false),
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
                          : const Icon(Icons.rule),
                      label: Text(_isLoading ? 'विश्लेषण जारी है...' : 'नोटिस एवं परिवाद की विधिक वैधता जांचें', style: const TextStyle(height: 1.40)),
                      onPressed: _isLoading ? null : _runEvaluation,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_result != null) ...[
                    if (_result!.fatalDefectsDetected.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: StitchColors.alertCrimsonBg,
                          border: Border.all(color: StitchColors.alertCrimson),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.error_outline, color: StitchColors.alertCrimson),
                                SizedBox(width: 8),
                                Text(
                                  'परिवाद में गंभीर विधिक खामियां (Fatal Procedural Defects)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42, color: StitchColors.alertCrimson),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._result!.fatalDefectsDetected.map((d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text('• $d', style: const TextStyle(fontSize: 12.5, height: 1.42, color: StitchColors.textPrimary)),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text('बचाव एवं उपधारणा खंडन रणनीति:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42)),
                    const SizedBox(height: 6),
                    ..._result!.defenseRebuttalStrategy.map((s) => Card(
                          margin: const EdgeInsets.only(bottom: 6.0),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(s, style: const TextStyle(fontSize: 12.5, height: 1.42)),
                          ),
                        )),
                    const Divider(height: 24),

                    const Text('उन्मोचन (Discharge) अथवा याचिका के आधार:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.42)),
                    const SizedBox(height: 6),
                    ..._result!.statutoryDischargeOrQuashingGrounds.map((g) => Card(
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

  Widget _buildDatePickerTile(String title, DateTime selectedDate, ValueChanged<DateTime> onDatePicked) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 12.5, height: 1.40)),
      subtitle: Text(
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        style: const TextStyle(fontWeight: FontWeight.bold, height: 1.40, color: StitchColors.courtNavy),
      ),
      trailing: OutlinedButton(
        child: const Text('बदलें', style: TextStyle(fontSize: 11, height: 1.40)),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime.now().subtract(const Duration(days: 730)),
            lastDate: DateTime.now().add(const Duration(days: 30)),
          );
          if (picked != null) onDatePicked(picked);
        },
      ),
    );
  }
}
