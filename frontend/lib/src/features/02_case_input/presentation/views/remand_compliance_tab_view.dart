import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/remand_repository.dart';
import '../../domain/arrest_compliance_models.dart';

class RemandComplianceTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const RemandComplianceTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<RemandComplianceTabView> createState() => _RemandComplianceTabViewState();
}

class _RemandComplianceTabViewState extends ConsumerState<RemandComplianceTabView> {
  final DateTime _arrestTime = DateTime.now().subtract(const Duration(hours: 14));
  final DateTime _productionTime = DateTime.now();

  bool _noticeIssuedSec35 = false;
  bool _flightRiskRecorded = false;
  int _witnessCount = 0;
  bool _familyIntimation = false;
  bool _medicalConducted = true;
  bool _magistrateReasons = false;

  bool _isLoading = false;
  ArrestComplianceAuditResult? _auditResult;

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
        _auditResult = res;
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

  void _showObjectionSheet(String draftText) {
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
                  'आपत्ति पत्र विरुद्ध पुलिस रिमांड (Draft)',
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
                AppStrings.tr(ref, 'remand_checklist_title'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.tr(ref, 'remand_checklist_sub'),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
                ),
              ),
              const Divider(height: 16),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.tr(ref, 'sec_35_notice_question'), style: const TextStyle(fontSize: 12)),
                subtitle: const Text('7 वर्ष तक के मामलों में गिरफ्तारी से पूर्व अनिवार्य', style: TextStyle(fontSize: 10.5)),
                value: _noticeIssuedSec35,
                activeColor: LuxuryPalette.emeraldVerified,
                onChanged: (val) => setState(() => _noticeIssuedSec35 = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.tr(ref, 'flight_risk_question'), style: const TextStyle(fontSize: 12)),
                value: _flightRiskRecorded,
                activeColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _flightRiskRecorded = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.tr(ref, 'witness_memo_question'), style: const TextStyle(fontSize: 12)),
                value: _witnessCount > 0,
                activeColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _witnessCount = (val ?? false) ? 1 : 0),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या परिजन को गिरफ्तारी की सूचना दी गई? (D.K. Basu)', style: TextStyle(fontSize: 12)),
                value: _familyIntimation,
                activeColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _familyIntimation = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.tr(ref, 'medical_conducted_question'), style: const TextStyle(fontSize: 12)),
                value: _medicalConducted,
                activeColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _medicalConducted = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या मजिस्ट्रेट ने स्वतंत्र संतुष्टि दर्ज की है?', style: TextStyle(fontSize: 12)),
                value: _magistrateReasons,
                activeColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _magistrateReasons = val ?? false),
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
                      : const Icon(Icons.shield_outlined, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : AppStrings.tr(ref, 'evaluate_remand_btn')),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_auditResult != null) ...[
          LuxuryCard(
            isAlert: _auditResult!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST',
            isVerified: _auditResult!.complianceVerdict != 'NON_COMPLIANT_VOID_ARREST',
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditResult!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST'
                          ? 'अवैध गिरफ्तारी दोष (Void Arrest)'
                          : 'प्रक्रियात्मक अनुपालन वैध',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _auditResult!.complianceVerdict == 'NON_COMPLIANT_VOID_ARREST'
                            ? LuxuryPalette.rubyAlert
                            : LuxuryPalette.emeraldVerified,
                      ),
                    ),
                    LuxuryBadge(
                      label: _auditResult!.antilCategory,
                      foregroundColor: LuxuryPalette.champagneGold,
                      backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _auditResult!.magistrateDirectiveRecommendation,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
                ),
                const Divider(height: 16),

                ..._auditResult!.violations.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            v.severity == 'FATAL' ? Icons.dangerous : Icons.warning_amber,
                            size: 16,
                            color: v.severity == 'FATAL' ? LuxuryPalette.rubyAlert : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${v.statutoryProvision}: ${v.findingHindi}',
                              style: const TextStyle(fontSize: 11.5, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('रिमांड आपत्ति प्रार्थना पत्र देखें'),
                    onPressed: () => _showObjectionSheet(_auditResult!.instantObjectionPetitionDraft),
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
