import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/trial_repository.dart';
import '../../domain/witness_impeachment_models.dart';

class WitnessImpeachmentTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const WitnessImpeachmentTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<WitnessImpeachmentTabView> createState() => _WitnessImpeachmentTabViewState();
}

class _WitnessImpeachmentTabViewState extends ConsumerState<WitnessImpeachmentTabView> {
  final _witnessCodeController = TextEditingController(text: 'PW-2');
  final _witnessNameController = TextEditingController(text: 'चंदन सिंह (चश्मदीद साक्षी)');
  final _chiefDepositionController = TextEditingController(
    text: 'मैंने अभियुक्त रमेश को हाथ में पिस्तौल तानकर मृतक की छाती पर दो फायर करते प्रत्यक्ष देखा था।',
  );
  final _sec161Controller = TextEditingController(
    text: 'चीख सुनकर मैं मौके पर पहुंचा। पीड़ित बेहोश पड़ा था। गोली किसने चलाई यह मैं नहीं देख सका था।',
  );
  final _sec164Controller = TextEditingController(
    text: 'रमेश और सुरेश मोटरसाइकिल पर तेजी से भाग रहे थे।',
  );

  bool _isLoading = false;
  WitnessImpeachmentAuditResult? _auditResult;

  @override
  void dispose() {
    _witnessCodeController.dispose();
    _witnessNameController.dispose();
    _chiefDepositionController.dispose();
    _sec161Controller.dispose();
    _sec164Controller.dispose();
    super.dispose();
  }

  void _runAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(trialRepositoryProvider);
      final res = await repo.generateContradictionGrid(
        caseId: widget.caseId,
        witnessCode: _witnessCodeController.text.trim(),
        witnessName: _witnessNameController.text.trim(),
        witnessRole: 'EYEWITNESS',
        sec161CrpcStatement: _sec161Controller.text.trim(),
        sec164CrpcStatement: _sec164Controller.text.trim().isEmpty ? null : _sec164Controller.text.trim(),
        courtDepositionChief: _chiefDepositionController.text.trim(),
        defenseTheory: 'FALSE_IMPLICATION_AND_SUBSTANTIAL_IMPROVEMENT',
        accusedName: widget.accusedName,
        policeStation: widget.policeStation,
        district: widget.district,
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

  void _showConfrontationModal(String draftText) {
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
                  'तहसीलदार सिंह जिरह स्क्रिप्ट व प्रदर्श सूची',
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
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      children: [
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'impeachment_grid_title'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _witnessCodeController,
                      decoration: InputDecoration(labelText: AppStrings.tr(ref, 'witness_code_label')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _witnessNameController,
                      decoration: const InputDecoration(labelText: 'साक्षी का नाम (Witness Name)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _chiefDepositionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(ref, 'court_chief_label'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _sec161Controller,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(ref, 'police_161_label'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _sec164Controller,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppStrings.tr(ref, 'magistrate_164_label'),
                  alignLabelWithHint: true,
                ),
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
                      : const Icon(Icons.compare_arrows_rounded, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : AppStrings.tr(ref, 'audit_testimony_btn')),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_auditResult != null) ...[
          LuxuryCard(
            isAlert: _auditResult!.hasFatalContradictions,
            isVerified: !_auditResult!.hasFatalContradictions,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditResult!.hasFatalContradictions
                          ? 'गंभीर सुधार व अंतर्विरोध चिन्हित (Fatal Contradictions)'
                          : 'बयानों में विधिक संगति (Consistent Statements)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                        color: _auditResult!.hasFatalContradictions
                            ? LuxuryPalette.rubyAlert
                            : LuxuryPalette.emeraldVerified,
                      ),
                    ),
                    LuxuryBadge(
                      label: _auditResult!.witnessCode,
                      foregroundColor: LuxuryPalette.champagneGold,
                      backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ..._auditResult!.gridAnalysis.map((item) {
                  if (item.classification == 'CORROBORATING_PASSAGE') {
                    return const Text('बयानों में कोई गंभीर सुधार नहीं पाया गया।', style: TextStyle(fontSize: 12));
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? LuxuryPalette.rubyBgDark : LuxuryPalette.rubyBgLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.markedExhibitIdentifier,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: LuxuryPalette.rubyAlert),
                            ),
                            Text(
                              item.classification == 'MATERIAL_IMPROVEMENT_AMOUNTING_TO_CONTRADICTION'
                                  ? 'महत्वपूर्ण सुधार (Omission)'
                                  : 'प्रत्यक्ष अंतर्विरोध',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: LuxuryPalette.rubyAlert),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('• कोर्ट में कथन: "${item.chiefDeposition}"', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        Text('• पुलिस 161 बयान: "${item.statement161}"', style: const TextStyle(fontSize: 11.5)),
                        const SizedBox(height: 4),
                        Text(
                          'जिरह प्रश्न: ${item.statutoryConfrontationScriptHindi}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.orange.shade200 : Colors.brown.shade900, height: 1.3),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),

                if (_auditResult!.ioCrossExaminationReminders.isNotEmpty) ...[
                  const Text('विवेचक (I.O.) से प्रदर्श साबित कराने के प्रश्न:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ..._auditResult!.ioCrossExaminationReminders.take(2).map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text('• $r', style: const TextStyle(fontSize: 11.5)),
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
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('संपूर्ण तहसीलदार सिंह जिरह स्क्रिप्ट देखें'),
                    onPressed: () => _showConfrontationModal(_auditResult!.confrontationMasterScriptHindi),
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
