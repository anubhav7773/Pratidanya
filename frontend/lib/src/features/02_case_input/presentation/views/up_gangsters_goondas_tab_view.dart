import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/regional_acts_repository.dart';
import '../../domain/regional_acts_models.dart';

class UpGangstersGoondasTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const UpGangstersGoondasTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<UpGangstersGoondasTabView> createState() => _UpGangstersGoondasTabViewState();
}

class _UpGangstersGoondasTabViewState extends ConsumerState<UpGangstersGoondasTabView> {
  String _statute = 'UP_GANGSTERS_ACT_1986';
  bool _jointMeetingRule5 = false;
  bool _dmIndependentMind = false;
  final _dmEndorsementController = TextEditingController(
    text: 'Approved as recommended (संस्तुति स्वीकृत - मोहर हस्ताक्षर)',
  );
  final List<BasePredicateCase> _baseCases = [
    BasePredicateCase(
      crimeNumber: 'मु.अ.सं. 112/2021',
      sections: '379/411 IPC',
      status: 'ACQUITTED_ON_MERITS',
      disposalDate: '2023-11-20',
    ),
  ];

  bool _noticeMaterialAllegations = false;
  bool _noticeOnlyFirs = true;

  bool _isLoading = false;
  RegionalActsAuditResult? _auditResult;

  @override
  void dispose() {
    _dmEndorsementController.dispose();
    super.dispose();
  }

  void _runAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(regionalActsRepositoryProvider);
      final res = await repo.auditUpSpecialActs(
        caseId: widget.caseId,
        statuteApplied: _statute,
        district: widget.district,
        policeStation: widget.policeStation,
        accusedName: widget.accusedName,
        jointMeetingRule5Documented: _jointMeetingRule5,
        dmIndependentMindApplied: _dmIndependentMind,
        dmEndorsementRawText: _dmEndorsementController.text.trim(),
        baseCases: _baseCases,
        noticeHasMaterialAllegations: _noticeMaterialAllegations,
        noticeOnlyListsFirs: _noticeOnlyFirs,
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

  void _showWritSheet(String draftText) {
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
                  'माननीय उच्च न्यायालय अनुच्छेद 226 रिट याचिका',
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
      children: [
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'regional_acts_title'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _statute,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'संबंधित प्रादेशिक अधिनियम'),
                items: const [
                  DropdownMenuItem(
                    value: 'UP_GANGSTERS_ACT_1986',
                    child: Text('उ.प्र. गिरोहबंद अधिनियम, 1986 व नियमावली 2021'),
                  ),
                  DropdownMenuItem(
                    value: 'UP_GOONDAS_ACT_1970',
                    child: Text('उ.प्र. गुंडा नियंत्रण अधिनियम, 1970 (जिला बदर)'),
                  ),
                ],
                onChanged: (val) => setState(() => _statute = val ?? _statute),
              ),
              const SizedBox(height: 12),

              if (_statute == 'UP_GANGSTERS_ACT_1986') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.tr(ref, 'rule_5_joint_meeting'), style: const TextStyle(fontSize: 12)),
                  subtitle: const Text('नियम 5: डीएम व एसएसपी की संयुक्त बैठक के मिनट्स के बिना अनुमोदन शून्य', style: TextStyle(fontSize: 10.5)),
                  value: _jointMeetingRule5,
                  activeThumbColor: LuxuryPalette.emeraldVerified,
                  onChanged: (val) => setState(() => _jointMeetingRule5 = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.tr(ref, 'rule_16_independent_mind'), style: const TextStyle(fontSize: 12)),
                  subtitle: const Text('राधा बनाम उ.प्र. राज्य: यांत्रिक रबर-स्टाम्प हस्ताक्षर अवैध', style: TextStyle(fontSize: 10.5)),
                  value: _dmIndependentMind,
                  activeThumbColor: LuxuryPalette.courtNavy,
                  onChanged: (val) => setState(() => _dmIndependentMind = val),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dmEndorsementController,
                  decoration: const InputDecoration(labelText: 'गैंग चार्ट पर DM का पृष्ठांकन / आदेश'),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('आधारभूत मुकदमे (Predicate Cases):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('केस जोड़ें', style: TextStyle(fontSize: 11.5)),
                      onPressed: () {
                        setState(() {
                          _baseCases.add(BasePredicateCase(
                            crimeNumber: 'मु.अ.सं. ${_baseCases.length + 101}/2023',
                            sections: '380 IPC',
                            status: 'ACQUITTED_ON_MERITS',
                          ));
                        });
                      },
                    ),
                  ],
                ),
                ..._baseCases.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gavel, size: 16, color: LuxuryPalette.courtNavy),
                            const SizedBox(width: 6),
                            Text('${c.crimeNumber} (${c.sections})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            LuxuryBadge(
                              label: c.status,
                              foregroundColor: LuxuryPalette.emeraldVerified,
                              backgroundColor: LuxuryPalette.emeraldBgLight,
                            ),
                          ],
                        ),
                      ),
                    )),
              ] else ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.tr(ref, 'goondas_sec_3_notice'), style: const TextStyle(fontSize: 12)),
                  subtitle: const Text('रामजी पांडेय पूर्ण पीठ: सामान्य विवरण के बिना नोटिस शून्य', style: TextStyle(fontSize: 10.5)),
                  value: _noticeMaterialAllegations,
                  activeThumbColor: LuxuryPalette.emeraldVerified,
                  onChanged: (val) => setState(() => _noticeMaterialAllegations = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('क्या नोटिस में मात्र मुकदमों की सूची दर्ज है?', style: TextStyle(fontSize: 12)),
                  value: _noticeOnlyFirs,
                  activeThumbColor: LuxuryPalette.courtNavy,
                  onChanged: (val) => setState(() => _noticeOnlyFirs = val),
                ),
              ],
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
                      : const Icon(Icons.security_rounded, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : 'प्रशासनिक वैधता जांचें व रिट बनाएं'),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_auditResult != null) ...[
          LuxuryCard(
            isAlert: _auditResult!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE',
            isVerified: _auditResult!.proceduralViability != 'FATALLY_DEFECTIVE_CHALLENGEABLE',
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditResult!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE'
                          ? 'गैंग चार्ट / नोटिस अधिकारिताविहीन (Void ab initio)'
                          : 'प्रशासनिक प्रक्रिया प्रथम दृष्टया नियमित',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                        color: _auditResult!.proceduralViability == 'FATALLY_DEFECTIVE_CHALLENGEABLE'
                            ? LuxuryPalette.rubyAlert
                            : LuxuryPalette.emeraldVerified,
                      ),
                    ),
                    LuxuryBadge(
                      label: _auditResult!.statuteApplied.split('_')[1],
                      foregroundColor: LuxuryPalette.champagneGold,
                      backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'फोरम: ${_auditResult!.recommendedForum}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 16),

                ..._auditResult!.groundsOfChallenge.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            g.severity.contains('FATALITY') ? Icons.dangerous : Icons.warning_amber,
                            size: 16,
                            color: g.severity.contains('FATALITY') ? LuxuryPalette.rubyAlert : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${g.ruleOrStatute}: ${g.argumentHindi}',
                              style: const TextStyle(fontSize: 11.5, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuxuryPalette.courtNavy,
                      foregroundColor: LuxuryPalette.lightSurface,
                    ),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: Text(AppStrings.tr(ref, 'generate_hc_writ_btn')),
                    onPressed: () => _showWritSheet(_auditResult!.draftPetitionHindi),
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
