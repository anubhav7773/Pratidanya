import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/forensics_repository.dart';
import '../../domain/malkhana_models.dart';

class MalkhanaChainTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const MalkhanaChainTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<MalkhanaChainTabView> createState() => _MalkhanaChainTabViewState();
}

class _MalkhanaChainTabViewState extends ConsumerState<MalkhanaChainTabView> {
  final _registerNoController = TextEditingController(text: 'Reg-19/Item-402');
  final _seizureSealController = TextEditingController(text: 'POLICE THANA HAZRATGANJ_A1');
  final _fslReceiptSealController = TextEditingController(text: 'POLICE_SEAL_ILLEGIBLE');

  final DateTime _seizureDate = DateTime.now().subtract(const Duration(days: 35));
  final DateTime _fslDispatchDate = DateTime.now().subtract(const Duration(days: 2));

  bool _specimenSealDeposited = false;
  bool _roadCertificateAnnexed = false;

  bool _isLoading = false;
  MalkhanaAuditResult? _auditResult;

  @override
  void dispose() {
    _registerNoController.dispose();
    _seizureSealController.dispose();
    _fslReceiptSealController.dispose();
    super.dispose();
  }

  void _runAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(forensicsRepositoryProvider);
      final res = await repo.auditMalkhanaChain(
        caseId: widget.caseId,
        actType: 'NDPS',
        seizureDate: _seizureDate,
        seizureSealImpression: _seizureSealController.text.trim(),
        malkhanaDepositDate: _seizureDate.add(const Duration(days: 1)),
        malkhanaRegisterNumber: _registerNoController.text.trim(),
        specimenSealDeposited: _specimenSealDeposited,
        fslDispatchDate: _fslDispatchDate,
        fslReceivedDate: _fslDispatchDate.add(const Duration(days: 1)),
        fslReceiptSealImpression: _fslReceiptSealController.text.trim(),
        roadCertificateAnnexed: _roadCertificateAnnexed,
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

  void _showSummoningModal(String draftText) {
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
                  'धारा 254 BNSS साक्ष्य तलब प्रार्थना पत्र',
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
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      children: [
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'malkhana_title'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _registerNoController,
                decoration: const InputDecoration(labelText: 'मालखाना रजिस्टर संख्या 19 प्रविष्टि (Reg 19 Entry)'),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _seizureSealController,
                decoration: const InputDecoration(labelText: 'जब्ती फर्द पर सील विवरण (Seizure Seal)'),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _fslReceiptSealController,
                decoration: const InputDecoration(labelText: 'FSL रसीद पर दर्ज सील स्थिति (Receipt Seal)'),
              ),
              const Divider(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या नमूना मुहर (Specimen Seal) रजिस्टर में चिपकाई गई?', style: TextStyle(fontSize: 12)),
                subtitle: const Text('गुरमैल सिंह (2005): नमूना मुहर का अभाव अभिरक्षा भंग करता है', style: TextStyle(fontSize: 10.5)),
                value: _specimenSealDeposited,
                activeThumbColor: LuxuryPalette.emeraldVerified,
                onChanged: (val) => setState(() => _specimenSealDeposited = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या मार्ग प्रमाण पत्र (Road Certificate / RC) संलग्न है?', style: TextStyle(fontSize: 12)),
                value: _roadCertificateAnnexed,
                activeThumbColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _roadCertificateAnnexed = val),
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
                      : const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : 'अभिरक्षा शृंखला (Chain of Custody) जांचें'),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_auditResult != null) ...[
          LuxuryCard(
            isAlert: _auditResult!.hasFatalTamperingRisk,
            isVerified: !_auditResult!.hasFatalTamperingRisk,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditResult!.hasFatalTamperingRisk
                          ? 'अभिरक्षा शृंखला खंडित (Chain Broken)'
                          : 'अभिरक्षा शृंखला नियमित',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _auditResult!.hasFatalTamperingRisk
                            ? LuxuryPalette.rubyAlert
                            : LuxuryPalette.emeraldVerified,
                      ),
                    ),
                    LuxuryBadge(
                      label: '${_auditResult!.fslDispatchDelayDays} दिन विलंब',
                      foregroundColor: LuxuryPalette.rubyAlert,
                      backgroundColor: LuxuryPalette.rubyBgLight,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ..._auditResult!.fatalVulnerabilities.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.dangerous, size: 16, color: LuxuryPalette.rubyAlert),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${v.statutoryViolationHindi} (${v.precedentAuthority})',
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
                      backgroundColor: LuxuryPalette.rubyAlert,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: Text(AppStrings.tr(ref, 'sec_254_petition_btn')),
                    onPressed: () => _showSummoningModal(_auditResult!.applicationSec254BnssDraftHindi),
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
