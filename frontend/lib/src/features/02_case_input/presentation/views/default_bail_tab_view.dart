import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/remand_repository.dart';
import '../../domain/default_bail_models.dart';

class DefaultBailTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const DefaultBailTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<DefaultBailTabView> createState() => _DefaultBailTabViewState();
}

class _DefaultBailTabViewState extends ConsumerState<DefaultBailTabView> {
  DateTime _firstRemandDate = DateTime.now().subtract(const Duration(days: 91));
  int _statutoryThreshold = 90;
  bool _chargesheetFiled = true;
  bool _fslChemicalAttached = false;
  bool _isLoading = false;
  DefaultBailAuditResult? _auditResult;

  void _runAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(remandRepositoryProvider);
      final annexures = <String>['SITE_PLAN', 'WITNESS_STATEMENTS'];
      if (_fslChemicalAttached) {
        annexures.add('FSL_CHEMICAL_EXAMINER_REPORT');
      }

      final result = await repo.auditDefaultBail(
        caseId: widget.caseId,
        firstRemandDate: _firstRemandDate,
        statutoryRegime: 'BNSS',
        offenseSections: [
          {'act': 'BNS', 'section': '103(1)', 'max_punishment_years': 99},
        ],
        chargesheetFiled: _chargesheetFiled,
        chargesheetFilingDate: _chargesheetFiled ? DateTime.now().subtract(const Duration(days: 2)) : null,
        chargesheetAnnexures: annexures,
        accusedName: widget.accusedName,
        policeStation: widget.policeStation,
        district: widget.district,
      );

      setState(() {
        _auditResult = result;
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

  void _showPetitionSheet(String draftText) {
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
                Text(
                  AppStrings.tr(ref, 'view_default_bail_draft'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
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
                child: SelectableText(
                  draftText,
                  style: const TextStyle(fontSize: 12.5, height: 1.5),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      children: [
        // Configuration Parameters Card
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'default_bail_title'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Remand Date Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'प्रथम रिमांड दिनांक (First Remand):',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: Text(
                      '${_firstRemandDate.day}-${_firstRemandDate.month}-${_firstRemandDate.year}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _firstRemandDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _firstRemandDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 16),

              // Threshold Selector
              Row(
                children: [
                  const Text('सांविधिक सीमा:', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('60 दिन'),
                    selected: _statutoryThreshold == 60,
                    onSelected: (val) => setState(() => _statutoryThreshold = 60),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('90 दिन (गंभीर)'),
                    selected: _statutoryThreshold == 90,
                    onSelected: (val) => setState(() => _statutoryThreshold = 90),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Incomplete Chargesheet Toggles
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या आरोप-पत्र (Chargesheet) दाखिल हो चुका है?', style: TextStyle(fontSize: 12)),
                value: _chargesheetFiled,
                activeThumbColor: LuxuryPalette.champagneGold,
                onChanged: (val) => setState(() => _chargesheetFiled = val),
              ),
              if (_chargesheetFiled)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('क्या FSL रासायनिक/फॉरेंसिक रिपोर्ट संलग्न है?', style: TextStyle(fontSize: 12)),
                  subtitle: const Text('कपिल वाधवान (2024): बिना मूल फॉरेंसिक के आरोप-पत्र अधूरा है', style: TextStyle(fontSize: 10.5)),
                  value: _fslChemicalAttached,
                  activeThumbColor: LuxuryPalette.emeraldVerified,
                  onChanged: (val) => setState(() => _fslChemicalAttached = val),
                ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuxuryPalette.courtNavy,
                    foregroundColor: LuxuryPalette.lightSurface,
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.analytics_outlined, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : 'डिफ़ॉल्ट जमानत प्रोद्भूतता जांचें'),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Audit Results
        if (_auditResult != null) ...[
          LuxuryCard(
            hasGoldAccent: _auditResult!.isDefaultBailCrystallized,
            isAlert: _auditResult!.isDefaultBailCrystallized,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditResult!.isDefaultBailCrystallized
                          ? AppStrings.tr(ref, 'status_eligible')
                          : AppStrings.tr(ref, 'status_in_progress'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _auditResult!.isDefaultBailCrystallized
                            ? LuxuryPalette.rubyAlert
                            : LuxuryPalette.emeraldVerified,
                      ),
                    ),
                    LuxuryBadge(
                      label: '${_auditResult!.daysElapsedInCustody}/${_auditResult!.statutoryThresholdDays} दिन',
                      foregroundColor: _auditResult!.isDefaultBailCrystallized
                          ? LuxuryPalette.rubyAlert
                          : LuxuryPalette.courtNavy,
                      backgroundColor: _auditResult!.isDefaultBailCrystallized
                          ? LuxuryPalette.rubyBgLight
                          : LuxuryPalette.lightSurfaceSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Custody progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_auditResult!.daysElapsedInCustody / _auditResult!.statutoryThresholdDays).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _auditResult!.isDefaultBailCrystallized
                          ? LuxuryPalette.rubyAlert
                          : LuxuryPalette.champagneGold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Section 187 Police Custody Alert
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? LuxuryPalette.midnightElevated : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _auditResult!.policeCustodyAlertHindi,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                      height: 1.35,
                    ),
                  ),
                ),

                // Incomplete Chargesheet Warning
                if (_auditResult!.isChargesheetIncomplete) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? LuxuryPalette.rubyBgDark : LuxuryPalette.rubyBgLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _auditResult!.chargesheetDefectSummaryHindi,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: LuxuryPalette.rubyAlert,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _auditResult!.isDefaultBailCrystallized
                          ? LuxuryPalette.rubyAlert
                          : LuxuryPalette.courtNavy,
                      foregroundColor: LuxuryPalette.lightSurface,
                    ),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: Text(AppStrings.tr(ref, 'view_default_bail_draft')),
                    onPressed: () => _showPetitionSheet(_auditResult!.statutoryPetitionDraftHindi),
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
