import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/courtroom_repository.dart';
import '../../domain/courtroom_tactics_models.dart';

class SuretyScrutinyTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const SuretyScrutinyTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<SuretyScrutinyTabView> createState() => _SuretyScrutinyTabViewState();
}

class _SuretyScrutinyTabViewState extends ConsumerState<SuretyScrutinyTabView> {
  final _bondAmountController = TextEditingController(text: '100000');
  bool _isLocalSuretyDemanded = true;
  bool _isKhatauniDemanded = true;
  bool _outOfDistrictRejected = true;
  bool _accusedIndigence = true;

  bool _isLoading = false;
  SuretyAuditResult? _auditResult;

  @override
  void dispose() {
    _bondAmountController.dispose();
    super.dispose();
  }

  void _runAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(courtroomRepositoryProvider);
      final amount = double.tryParse(_bondAmountController.text.trim()) ?? 50000.0;
      final res = await repo.auditSuretyConditions(
        caseId: widget.caseId,
        imposedBondAmountInr: amount,
        isLocalSuretyDemanded: _isLocalSuretyDemanded,
        isRevenueRecordKhatauniDemanded: _isKhatauniDemanded,
        outOfDistrictSuretyRejected: _outOfDistrictRejected,
        accusedFinancialIndigence: _accusedIndigence,
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

  void _showModificationSheet(String draftText) {
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
                  'धारा 483(2) BNSS बंधपत्र शर्त संशोधन प्रार्थना पत्र',
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
              const Text(
                'जमानत बंधपत्र व प्रतिभू परीक्षण (मोती राम सिद्धांत)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const Text(
                'अधीनस्थ न्यायालयों द्वारा अधिरोपित कठोर व स्थानीय प्रतिभू की अवैध शर्तों का निराकरण',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _bondAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'अधिरोपित जमानत बंधपत्र धनराशि (₹)'),
              ),
              const Divider(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या केवल स्थानीय प्रतिभू (Local Surety) की मांग की गई?', style: TextStyle(fontSize: 12)),
                subtitle: const Text('मोती राम (1978): बाहरी निकट संबंधी को खारिज करना असंवैधानिक है', style: TextStyle(fontSize: 10.5)),
                value: _isLocalSuretyDemanded,
                activeThumbColor: LuxuryPalette.rubyAlert,
                onChanged: (val) => setState(() => _isLocalSuretyDemanded = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या मूल राजस्व खतौनी / कृषि भूमि अभिलेख मांगे गए?', style: TextStyle(fontSize: 12)),
                subtitle: const Text('राजस्व खतौनी की बाध्यता विधि विरुद्ध शर्त है', style: TextStyle(fontSize: 10.5)),
                value: _isKhatauniDemanded,
                activeThumbColor: LuxuryPalette.rubyAlert,
                onChanged: (val) => setState(() => _isKhatauniDemanded = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या अन्य जनपद के प्रतिभू को अस्वीकार कर दिया गया?', style: TextStyle(fontSize: 12)),
                value: _outOfDistrictRejected,
                activeThumbColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _outOfDistrictRejected = val),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या अभियुक्त निर्धन है व भारी बंधपत्र देने में असमर्थ है?', style: TextStyle(fontSize: 12)),
                value: _accusedIndigence,
                activeThumbColor: LuxuryPalette.emeraldVerified,
                onChanged: (val) => setState(() => _accusedIndigence = val),
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
                      : const Icon(Icons.handshake_outlined, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : 'शर्तों की वैधानिकता जांचें व संशोधन अर्जी बनाएं'),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_auditResult != null) ...[
          LuxuryCard(
            isAlert: _auditResult!.isConditionOnerous,
            isVerified: !_auditResult!.isConditionOnerous,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditResult!.isConditionOnerous
                          ? 'दमनकारी जमानत शर्तें चिन्हित (Onerous Conditions)'
                          : 'शर्तें प्रथम दृष्टया नियमित',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                        color: _auditResult!.isConditionOnerous
                            ? LuxuryPalette.rubyAlert
                            : LuxuryPalette.emeraldVerified,
                      ),
                    ),
                    LuxuryBadge(
                      label: 'Sec 483(2) BNSS',
                      foregroundColor: LuxuryPalette.champagneGold,
                      backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ..._auditResult!.motiRamViolationReasons.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.dangerous, size: 16, color: LuxuryPalette.rubyAlert),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(r, style: const TextStyle(fontSize: 11.5, height: 1.3)),
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
                    label: const Text('शर्त संशोधन प्रार्थना पत्र (Section 483(2) BNSS) देखें'),
                    onPressed: () => _showModificationSheet(_auditResult!.modificationPetitionDraftHindi),
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
