import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/forensics_repository.dart';
import '../../domain/medico_legal_models.dart';

class MedicoLegalMatrixTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const MedicoLegalMatrixTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<MedicoLegalMatrixTabView> createState() => _MedicoLegalMatrixTabViewState();
}

class _MedicoLegalMatrixTabViewState extends ConsumerState<MedicoLegalMatrixTabView> {
  final _pmrNumberController = TextEditingController(text: 'PMR-892/2026');
  String _allegedWeapon = 'तलवार (Sword - sharp weapon)';
  String _woundTypeFound = 'Lacerated wound (कुंद चोट)';
  String _marginsFound = 'Irregular, contused and abraded (अनियमित व कुचले)';
  final String _stomachContents = 'Semi-digested rice and vegetables (अर्ध-पचा)';

  bool _isLoading = false;
  MedicalMatrixAuditResult? _matrixResult;

  @override
  void dispose() {
    _pmrNumberController.dispose();
    super.dispose();
  }

  void _runAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(forensicsRepositoryProvider);
      final now = DateTime.now();
      final res = await repo.generateMedicalMatrix(
        caseId: widget.caseId,
        ocularAllegations: [
          {
            'witness_id': 'PW-1 (वादी)',
            'witness_name': 'चश्मदीद साक्षी',
            'weapon_alleged': _allegedWeapon,
            'incident_timestamp': now.subtract(const Duration(hours: 14)).toIso8601String(),
            'alleged_distance_meters': 1.0,
            'strike_location': 'सिर (Occipital region)',
          }
        ],
        postMortemData: {
          'pmr_number': _pmrNumberController.text.trim(),
          'autopsy_doctor_name': 'डॉ. एस.के. वर्मा',
          'hospital_name': 'जिला मोर्चरी लखनऊ',
          'autopsy_timestamp': now.toIso8601String(),
          'external_injuries': [
            {
              'injury_number': 1,
              'injury_type': _woundTypeFound,
              'dimensions': '5cm x 2cm x bone deep',
              'margins': _marginsFound,
              'anatomical_location': 'Occipital region of skull',
            }
          ],
          'stomach_contents': _stomachContents,
          'rigor_mortis_state': 'Present all over body',
          'estimated_time_since_death_hours_min': 12.0,
          'estimated_time_since_death_hours_max': 16.0,
        },
        accusedName: widget.accusedName,
        policeStation: widget.policeStation,
        district: widget.district,
      );

      setState(() {
        _matrixResult = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.tr(ref, "error_prefix")}$e'),
            backgroundColor: LuxuryPalette.rubyAlert,
          ),
        );
      }
    }
  }

  void _showArgumentSheet(String draftText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                const Text(
                  'चिकित्सीय बहस पत्र (राम नारायण सिंह सिद्धांत)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_all_rounded, color: LuxuryPalette.champagneGold),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: draftText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.tr(ref, 'copied_snackbar'))),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(draftText, style: const TextStyle(fontSize: 12.5, height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
      children: [
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'medico_legal_title'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _pmrNumberController,
                decoration: InputDecoration(labelText: AppStrings.tr(ref, 'pmr_number_label')),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _allegedWeapon,
                decoration: const InputDecoration(labelText: 'चश्मदीद द्वारा कथित हथियार (Ocular Claim)'),
                items: const [
                  DropdownMenuItem(value: 'तलवार (Sword - sharp weapon)', child: Text('तलवार / चाकू (Sharp Cutting)')),
                  DropdownMenuItem(value: 'लाठी (Lathi / Blunt)', child: Text('लाठी / डंडा (Blunt Weapon)')),
                  DropdownMenuItem(value: 'पिस्तौल (Firearm)', child: Text('आग्नेयास्त्र / पिस्तौल (Firearm)')),
                ],
                onChanged: (val) => setState(() => _allegedWeapon = val ?? _allegedWeapon),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _woundTypeFound,
                decoration: const InputDecoration(labelText: 'पोस्टमार्टम में पाई गई चोट (Injury in PMR)'),
                items: const [
                  DropdownMenuItem(value: 'Lacerated wound (कुंद चोट)', child: Text('Lacerated Wound (फटा हुआ घाव)')),
                  DropdownMenuItem(value: 'Incised wound (कटा हुआ घाव)', child: Text('Incised Wound (साफ कटा हुआ)')),
                  DropdownMenuItem(value: 'Firearm entry wound', child: Text('गोली का प्रवेश घाव (Firearm)')),
                ],
                onChanged: (val) => setState(() => _woundTypeFound = val ?? _woundTypeFound),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _marginsFound,
                decoration: const InputDecoration(labelText: 'घाव के किनारे (Wound Margins)'),
                items: const [
                  DropdownMenuItem(value: 'Irregular, contused and abraded (अनियमित व कुचले)', child: Text('अनियमित, कुचले व खरोंचदार (Contused)')),
                  DropdownMenuItem(value: 'Clean-cut, linear and sharp', child: Text('साफ-सुथरे कटे हुए (Clean-cut)')),
                  DropdownMenuItem(value: 'Inverted, charred and tattooed', child: Text('जलने व बारूद के निशान युक्त (Charred)')),
                ],
                onChanged: (val) => setState(() => _marginsFound = val ?? _marginsFound),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuxuryPalette.courtNavy,
                    foregroundColor: LuxuryPalette.lightSurface,
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.medical_services_outlined, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : 'बायोमैकेनिकल अंतर्विरोध जांचें'),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_matrixResult != null) ...[
          LuxuryCard(
            isAlert: _matrixResult!.hasFatalConflict,
            isVerified: !_matrixResult!.hasFatalConflict,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _matrixResult!.hasFatalConflict
                          ? AppStrings.tr(ref, 'fatal_conflict_badge')
                          : AppStrings.tr(ref, 'consistent_evidence_badge'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _matrixResult!.hasFatalConflict
                            ? LuxuryPalette.rubyAlert
                            : LuxuryPalette.emeraldVerified,
                      ),
                    ),
                    LuxuryBadge(
                      label: _matrixResult!.pmrNumber,
                      foregroundColor: LuxuryPalette.champagneGold,
                      backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ..._matrixResult!.irreconcilableConflicts.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? LuxuryPalette.rubyBgDark : LuxuryPalette.rubyBgLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${c.ocularClaim}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          Text('• ${c.autopsyFinding}', style: const TextStyle(fontSize: 11.5)),
                          const SizedBox(height: 4),
                          Text(
                            c.scientificVerdictHindi,
                            style: const TextStyle(fontSize: 11.5, color: LuxuryPalette.rubyAlert, height: 1.3),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),

                if (_matrixResult!.crossExaminationCrossfireQuestions.isNotEmpty) ...[
                  const Text('चिकित्साधिकारी हेतु जिरह प्रश्न (Crossfire Questions):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ..._matrixResult!.crossExaminationCrossfireQuestions.take(2).map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text('Q. $q', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
                      )),
                ],
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuxuryPalette.courtNavy,
                      foregroundColor: LuxuryPalette.lightSurface,
                    ),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('विधिक बहस तर्क (Argument Draft) देखें'),
                    onPressed: () => _showArgumentSheet(_matrixResult!.writtenMedicalArgumentDraftHindi),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
