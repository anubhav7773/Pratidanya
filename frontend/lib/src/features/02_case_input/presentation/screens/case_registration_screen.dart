import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/luxury_card.dart';

class CaseRegistrationScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCaseSaved;

  const CaseRegistrationScreen({super.key, this.onCaseSaved});

  @override
  ConsumerState<CaseRegistrationScreen> createState() => _CaseRegistrationScreenState();
}

class _CaseRegistrationScreenState extends ConsumerState<CaseRegistrationScreen> {
  String _selectedStatute = 'HYBRID'; // 'HYBRID', 'BNS', 'IPC'
  final _firController = TextEditingController(text: '124');
  final _yearController = TextEditingController(text: '2026');
  final _policeStationController = TextEditingController(text: 'कोतवाली नगर');
  final _districtController = TextEditingController(text: 'लखनऊ');
  final _accusedNameController = TextEditingController();
  final _courtDesignationController = TextEditingController(text: 'CJM (मुख्य न्यायिक मजिस्ट्रेट, लखनऊ)');
  final _cnrController = TextEditingController(text: 'UPHC010123452026');
  final _sectionsController = TextEditingController(text: 'BNS 103(1), BNS 351(2)');
  final _factsController = TextEditingController();

  String _custodyStatus = 'JUDICIAL_CUSTODY';
  DateTime _custodyDate = DateTime.now();
  bool _isVoiceRecording = false;
  bool _isSaving = false;

  final Map<String, String> _custodyOptions = {
    'JUDICIAL_CUSTODY': 'जेल में (न्यायिक अभिरक्षा / Judicial Custody)',
    'POLICE_CUSTODY': 'पुलिस कस्टडी रिमांड (Police Custody Remand)',
    'ANTICIPATORY_BAIL': 'अग्रिम जमानत / गिरफ्तारी पूर्व (Pre-arrest / Anticipatory)',
    'SUSPENSION_OF_SENTENCE': 'दंडादेश स्थगन (Suspension of Sentence)',
  };

  @override
  void dispose() {
    _firController.dispose();
    _yearController.dispose();
    _policeStationController.dispose();
    _districtController.dispose();
    _accusedNameController.dispose();
    _courtDesignationController.dispose();
    _cnrController.dispose();
    _sectionsController.dispose();
    _factsController.dispose();
    super.dispose();
  }

  void _saveCaseDocket() async {
    if (_accusedNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया मुख्य अभियुक्त का नाम दर्ज करें।'),
          backgroundColor: LuxuryPalette.rubyAlert,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 650));
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('आपराधिक वाद केस डायरी में सफलतापूर्वक सुरक्षित कर लिया गया।'),
          backgroundColor: LuxuryPalette.emeraldVerified,
        ),
      );
      widget.onCaseSaved?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BilingualExecutiveAppBar(
        titleKey: 'new_case_title',
        subtitleKey: 'court_jurisdiction',
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
              children: [
                // 1. Statute Selection Segment (BNS vs IPC vs Hybrid)
                _buildStatuteSelector(isDark),
                const SizedBox(height: 12),

                // 2. Court Voice Intake Card
                _buildVoiceIntakeBanner(isDark),
                const SizedBox(height: 12),

                // 3. Primary FIR & Case Identifiers
                _buildFirDetailsCard(isDark),
                const SizedBox(height: 12),

                // 4. Custody & Remand Status Card
                _buildCustodyStatusCard(isDark),
                const SizedBox(height: 12),

                // 5. eCourts CIS 3.2 CNR Sync Card
                _buildCnrCard(isDark),
                const SizedBox(height: 12),

                // 6. Charged Sections & Factual Narrative
                _buildSectionsAndFactsCard(isDark),
                const SizedBox(height: 16),

                // 7. Save & Launch 360° Defense Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
                      foregroundColor: isDark ? LuxuryPalette.courtNavy : LuxuryPalette.lightSurface,
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.security_outlined, size: 20),
                    label: Text(
                      _isSaving ? AppStrings.tr(ref, 'loading_text') : AppStrings.tr(ref, 'save_case_btn'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _isSaving ? null : _saveCaseDocket,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatuteSelector(bool isDark) {
    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.tr(ref, 'statute_selection'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              const LuxuryBadge(
                label: 'समकालिक अनुपालन (Transitional)',
                foregroundColor: LuxuryPalette.emeraldVerified,
                backgroundColor: LuxuryPalette.emeraldBgLight,
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: isDark ? LuxuryPalette.midnightElevated : LuxuryPalette.lightSurfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? LuxuryPalette.midnightBorder : LuxuryPalette.lightBorder),
            ),
            child: Row(
              children: [
                _statuteOption('HYBRID', AppStrings.tr(ref, 'statute_hybrid'), isDark),
                _statuteOption('BNS', AppStrings.tr(ref, 'statute_bns'), isDark),
                _statuteOption('IPC', AppStrings.tr(ref, 'statute_ipc'), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statuteOption(String code, String label, bool isDark) {
    final isSelected = _selectedStatute == code;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() => _selectedStatute = code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? LuxuryPalette.midnightSurface : LuxuryPalette.courtNavy)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: LuxuryPalette.champagneGold, width: 1.0) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? LuxuryPalette.champagneGold
                  : (isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceIntakeBanner(bool isDark) {
    return LuxuryCard(
      hasGoldAccent: _isVoiceRecording,
      padding: const EdgeInsets.all(12),
      onTap: () {
        setState(() => _isVoiceRecording = !_isVoiceRecording);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isVoiceRecording ? LuxuryPalette.rubyAlert : LuxuryPalette.champagneGold,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isVoiceRecording ? Icons.mic : Icons.mic_none_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isVoiceRecording ? 'ध्वनि दर्ज हो रही है (Listening Live...)' : 'बोलकर केस दर्ज करें (Court Voice Intake)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'मु.अ.सं., थाना, धाराएं व घटना संक्षेप में बोलें • Groq Whisper द्वारा स्वतः निष्कर्षण',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ],
      ),
    );
  }

  Widget _buildFirDetailsCard(bool isDark) {
    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('प्राथमिक वाद विवरण (FIR Identifiers)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _firController,
                  decoration: InputDecoration(labelText: AppStrings.tr(ref, 'fir_number_label')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _yearController,
                  decoration: InputDecoration(labelText: AppStrings.tr(ref, 'fir_year_label')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _policeStationController,
                  decoration: InputDecoration(labelText: AppStrings.tr(ref, 'police_station_label')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _districtController,
                  decoration: InputDecoration(labelText: AppStrings.tr(ref, 'district_label')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _accusedNameController,
            decoration: InputDecoration(
              labelText: AppStrings.tr(ref, 'accused_name_label'),
              prefixIcon: const Icon(Icons.person_outline, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustodyStatusCard(bool isDark) {
    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr(ref, 'custody_status_label'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: _custodyStatus,
            isExpanded: true,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: _custodyOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12))))
                .toList(),
            onChanged: (val) => setState(() => _custodyStatus = val ?? _custodyStatus),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('अभिरक्षा / प्रथम रिमांड दिनांक:', style: TextStyle(fontSize: 12)),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month, size: 16),
                label: Text(
                  '${_custodyDate.day}-${_custodyDate.month}-${_custodyDate.year}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _custodyDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _custodyDate = picked);
                },
              ),
            ],
          ),
          const Divider(height: 16),

          TextField(
            controller: _courtDesignationController,
            decoration: InputDecoration(labelText: AppStrings.tr(ref, 'court_designation_label')),
          ),
        ],
      ),
    );
  }

  Widget _buildCnrCard(bool isDark) {
    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, size: 16, color: LuxuryPalette.champagneGold),
              SizedBox(width: 6),
              Text('ई-कोर्ट्स सी.एन.आर. संख्या (16-Digit CNR Number)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _cnrController,
            maxLength: 16,
            decoration: const InputDecoration(
              hintText: 'उदा. UPHC010123452026',
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsAndFactsCard(bool isDark) {
    return LuxuryCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr(ref, 'legal_sections_label'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          TextField(
            controller: _sectionsController,
            decoration: const InputDecoration(hintText: 'उदा. 103(1) BNS, 351(2) BNS, 25 Arms Act'),
          ),
          const SizedBox(height: 12),

          Text(AppStrings.tr(ref, 'factual_summary_label'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          TextField(
            controller: _factsController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'घटना का समय, स्थान, जब्ती फर्द विवरण, गिरफ्तारी परिस्थिति व एफ.आई.आर. का संक्षिप्त सार दर्ज करें...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
