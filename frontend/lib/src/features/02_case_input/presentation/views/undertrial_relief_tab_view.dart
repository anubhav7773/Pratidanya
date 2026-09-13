import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/remand_repository.dart';
import '../../domain/undertrial_models.dart';

class UndertrialReliefTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const UndertrialReliefTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<UndertrialReliefTabView> createState() => _UndertrialReliefTabViewState();
}

class _UndertrialReliefTabViewState extends ConsumerState<UndertrialReliefTabView> {
  DateTime _custodyStartDate = DateTime.now().subtract(const Duration(days: 900));
  bool _isFirstTimeOffender = true;
  bool _multipleCasesPending = false;
  final int _maxSentenceMonths = 84; // 7 years

  bool _isLoading = false;
  UndertrialReliefAuditResult? _auditResult;

  void _runAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(remandRepositoryProvider);
      final res = await repo.auditUndertrialRelief(
        caseId: widget.caseId,
        accusedName: widget.accusedName,
        jailName: 'केंद्रीय कारागार / जिला कारागार लखनऊ',
        custodyStartDate: _custodyStartDate,
        isFirstTimeOffender: _isFirstTimeOffender,
        multipleCasesPending: _multipleCasesPending,
        charges: [
          {'act': 'BNS', 'section': '318(4)', 'max_term_months': _maxSentenceMonths, 'is_capital_or_life': false},
        ],
        firNumber: 'मु.अ.सं. 112/2023',
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

  void _showModalPleading(String title, String draftText) {
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
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
              const Text(
                'धारा 479 BNSS विचाराधीन बंदी गणना (1/3 नियम)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Custody Start Date Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('जेल निरुद्धि प्रारंभ दिनांक:', style: TextStyle(fontSize: 12)),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: Text(
                      '${_custodyStartDate.day}-${_custodyStartDate.month}-${_custodyStartDate.year}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _custodyStartDate,
                        firstDate: DateTime(2018),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _custodyStartDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या अभियुक्त प्रथम अपराधी (First-time Offender) है?', style: TextStyle(fontSize: 12)),
                subtitle: const Text('धारा 479(1) प्रथम परंतुक: 1/3 सजा पर अनिवार्य जमानत', style: TextStyle(fontSize: 10.5)),
                value: _isFirstTimeOffender,
                activeThumbColor: LuxuryPalette.emeraldVerified,
                onChanged: (val) => setState(() => _isFirstTimeOffender = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या अभियुक्त पर एक से अधिक मुकदमे लंबित हैं?', style: TextStyle(fontSize: 12)),
                subtitle: const Text('धारा 479(2): एक से अधिक मामलों में राहत पर सांविधिक रोक', style: TextStyle(fontSize: 10.5)),
                value: _multipleCasesPending,
                activeThumbColor: LuxuryPalette.rubyAlert,
                onChanged: (val) => setState(() => _multipleCasesPending = val),
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
                      : const Icon(Icons.hourglass_top_rounded, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : '1/3 सांविधिक अवधि व पात्रता जांचें'),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_auditResult != null) ...[
          LuxuryCard(
            isVerified: _auditResult!.isReliefApplicable,
            isAlert: _auditResult!.isDisqualified,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditResult!.isReliefApplicable
                          ? 'रिहाई हेतु पात्र (${_auditResult!.statutoryThresholdFraction} अवधि पूर्ण)'
                          : 'अपात्र / अवधि शेष',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _auditResult!.isReliefApplicable
                            ? LuxuryPalette.emeraldVerified
                            : LuxuryPalette.rubyAlert,
                      ),
                    ),
                    LuxuryBadge(
                      label: '${_auditResult!.actualDetentionServedMonths}/${_auditResult!.thresholdMonths} माह',
                      foregroundColor: LuxuryPalette.champagneGold,
                      backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? LuxuryPalette.midnightElevated : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _auditResult!.retrospectiveMandateTextHindi,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                      height: 1.35,
                    ),
                  ),
                ),
                if (_auditResult!.disqualificationReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? LuxuryPalette.rubyBgDark : LuxuryPalette.rubyBgLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _auditResult!.disqualificationReason!,
                      style: const TextStyle(fontSize: 11.5, color: LuxuryPalette.rubyAlert),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Dual Petitions Export
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LuxuryPalette.courtNavy,
                          foregroundColor: LuxuryPalette.lightSurface,
                        ),
                        icon: const Icon(Icons.gavel, size: 16),
                        label: const Text('न्यायालय जमानत अर्जी', style: TextStyle(fontSize: 11.5)),
                        onPressed: () => _showModalPleading(
                          'न्यायालय जमानत प्रार्थना पत्र (धारा 479 BNSS)',
                          _auditResult!.courtApplicationDraftHindi,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                        label: const Text('जेल अधीक्षक सूचना', style: TextStyle(fontSize: 11.5)),
                        onPressed: () => _showModalPleading(
                          'धारा 479(3) जेल अधीक्षक विधिक सूचना',
                          _auditResult!.jailSuperintendentNoticeDraftHindi,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
