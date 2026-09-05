import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/stitch_hindi_text_field.dart';
import '../../../../shared/components/statute_selector_bar.dart';
import '../controllers/case_controller.dart';

class NewCaseFormScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCaseSaved;

  const NewCaseFormScreen({super.key, this.onCaseSaved});

  @override
  ConsumerState<NewCaseFormScreen> createState() => _NewCaseFormScreenState();
}

class _NewCaseFormScreenState extends ConsumerState<NewCaseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firNumberController = TextEditingController();
  final _policeStationController = TextEditingController();
  final _districtController = TextEditingController(text: 'लखनऊ');
  final _accusedNameController = TextEditingController();
  final _complainantController = TextEditingController();
  final _sectionsController = TextEditingController();
  final _caseNumberController = TextEditingController();
  final _factualSummaryController = TextEditingController();

  StatuteSystem _selectedStatute = StatuteSystem.hybrid;
  String _custodyStatus = 'JUDICIAL_CUSTODY';
  String _courtDesignation = 'मुख्य न्यायिक मजिस्ट्रेट (CJM)';
  final String _stageOfCase = 'BAIL';
  DateTime? _selectedHearingDate;

  final List<String> _custodyOptions = [
    'JUDICIAL_CUSTODY',
    'POLICE_CUSTODY',
    'ON_BAIL',
    'ANTICIPATORY',
  ];

  final List<String> _courts = [
    'मुख्य न्यायिक मजिस्ट्रेट (CJM)',
    'अपर मुख्य न्यायिक मजिस्ट्रेट (ACJM-I)',
    'न्यायिक मजिस्ट्रेट प्रथम श्रेणी (JMFC)',
    'सत्र न्यायाधीश (Sessions Judge)',
    'विशेष न्यायाधीश (POCSO/SC-ST)',
  ];

  @override
  void dispose() {
    _firNumberController.dispose();
    _policeStationController.dispose();
    _districtController.dispose();
    _accusedNameController.dispose();
    _complainantController.dispose();
    _sectionsController.dispose();
    _caseNumberController.dispose();
    _factualSummaryController.dispose();
    super.dispose();
  }

  String _mapCustodyToLabel(String key) {
    switch (key) {
      case 'JUDICIAL_CUSTODY':
        return 'न्यायिक अभिरक्षा (जेल में)';
      case 'POLICE_CUSTODY':
        return 'पुलिस रिमांड';
      case 'ON_BAIL':
        return 'जमानत पर रिहा';
      case 'ANTICIPATORY':
        return 'अग्रिम जमानत';
      default:
        return key;
    }
  }

  Future<void> _pickHearingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedHearingDate = picked);
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final sectionsList = _sectionsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final success = await ref.read(caseFormControllerProvider.notifier).createCase(
            firNumber: _firNumberController.text.trim(),
            policeStation: _policeStationController.text.trim(),
            district: _districtController.text.trim(),
            stateJurisdiction: 'Uttar Pradesh',
            accusedName: _accusedNameController.text.trim(),
            accusedCustodyStatus: _custodyStatus,
            statuteSystem: _selectedStatute.name.toUpperCase(),
            underSections: sectionsList,
            courtDesignation: _courtDesignation,
            stageOfCase: _stageOfCase,
            complainantName: _complainantController.text.trim(),
            caseNumber: _caseNumberController.text.trim(),
            nextHearingDate: _selectedHearingDate,
            lastCourtOrder: _factualSummaryController.text.trim(),
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('आपराधिक केस सफलतापूर्वक दर्ज किया गया।'),
            backgroundColor: StitchColors.verifiedGreen,
          ),
        );
        if (widget.onCaseSaved != null) {
          widget.onCaseSaved!();
        } else {
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(caseFormControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('नया आपराधिक केस दर्ज करें'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Statute System Segmented Switcher
                const Text('लागू विधिक प्रणाली', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: StitchColors.courtNavy)),
                const SizedBox(height: 6),
                StatuteSelectorBar(
                  selectedSystem: _selectedStatute,
                  onSystemChanged: (sys) => setState(() => _selectedStatute = sys),
                ),
                const SizedBox(height: 16),

                // 2. FIR & Police Details
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: StitchHindiTextField(
                        controller: _firNumberController,
                        label: 'मु.अ.सं. (FIR No.)',
                        hint: '124/2026',
                        validator: (val) => val == null || val.isEmpty ? 'अनिवार्य है' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: StitchHindiTextField(
                        controller: _policeStationController,
                        label: 'संबंधित थाना',
                        hint: 'कोतवाली नगर',
                        validator: (val) => val == null || val.isEmpty ? 'थाना अनिवार्य है' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                StitchHindiTextField(
                  controller: _districtController,
                  label: 'जनपद (District)',
                  hint: 'लखनऊ',
                  validator: (val) => val == null || val.isEmpty ? 'जनपद अनिवार्य है' : null,
                ),
                const SizedBox(height: 14),

                // 3. Accused & Custody
                StitchHindiTextField(
                  controller: _accusedNameController,
                  label: 'अभियुक्त / प्रार्थी का नाम',
                  hint: 'उदा. श्यामू उर्फ़ श्याम',
                  validator: (val) => val == null || val.isEmpty ? 'अभियुक्त का नाम दर्ज करें' : null,
                ),
                const SizedBox(height: 14),

                const Text('अभिरक्षा स्थिति (Custody Status)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: StitchColors.courtNavy)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _custodyStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0), borderSide: const BorderSide(color: StitchColors.borderSubtle)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _custodyOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(_mapCustodyToLabel(opt)))).toList(),
                  onChanged: (val) => setState(() => _custodyStatus = val ?? _custodyStatus),
                ),
                const SizedBox(height: 14),

                // 4. Sections & Court
                StitchHindiTextField(
                  controller: _sectionsController,
                  label: 'संबंधित धाराएं (अल्पविराम , द्वारा अलग करें)',
                  hint: 'उदा. 379 IPC, 411 IPC (या 303 BNS)',
                  validator: (val) => val == null || val.isEmpty ? 'कम से कम एक धारा दर्ज करें' : null,
                ),
                const SizedBox(height: 14),

                const Text('विचारणीय न्यायालय (Court Designation)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: StitchColors.courtNavy)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _courtDesignation,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0), borderSide: const BorderSide(color: StitchColors.borderSubtle)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _courts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _courtDesignation = val ?? _courtDesignation),
                ),
                const SizedBox(height: 14),

                // 5. Hearing Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('अगली सुनवाई तारीख', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: StitchColors.courtNavy)),
                  subtitle: Text(
                    _selectedHearingDate != null
                        ? '${_selectedHearingDate!.day}/${_selectedHearingDate!.month}/${_selectedHearingDate!.year}'
                        : 'दिनांक चुनें (वैकल्पिक)',
                    style: TextStyle(color: _selectedHearingDate != null ? StitchColors.textPrimary : Colors.grey),
                  ),
                  trailing: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('चुनें'),
                    onPressed: _pickHearingDate,
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Factual Summary / Accusation
                StitchHindiTextField(
                  controller: _factualSummaryController,
                  label: 'घटना एवं अभियोजन आरोप का संक्षिप्त विवरण',
                  hint: 'वादी की तहरीर व बरामदगी का विवरण दर्ज करें...',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StitchColors.courtNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                    ),
                    onPressed: formState.isLoading ? null : _submit,
                    child: formState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('केस डायरी में सुरक्षित करें', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
