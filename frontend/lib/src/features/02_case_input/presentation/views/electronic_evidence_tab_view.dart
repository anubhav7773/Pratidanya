import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../data/evidence_repository.dart';
import '../../domain/electronic_evidence_models.dart';

class ElectronicEvidenceTabView extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const ElectronicEvidenceTabView({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<ElectronicEvidenceTabView> createState() => _ElectronicEvidenceTabViewState();
}

class _ElectronicEvidenceTabViewState extends ConsumerState<ElectronicEvidenceTabView> {
  final _exhibitController = TextEditingController(text: 'Ex. P-14 (CDR / CCTV)');
  final _hashController = TextEditingController();
  final _imeiController = TextEditingController();

  String _evidenceType = 'CALL_DETAIL_RECORD_CDR';
  String _hashAlgo = 'NONE';
  bool _scheduleMatched = false;
  bool _partAExecuted = true;
  bool _partBExecuted = false;
  final bool _contemporaneous = true;

  bool _isLoading = false;
  ElectronicEvidenceAuditResult? _auditResult;

  final Map<String, String> _evidenceTypeLabels = {
    'CALL_DETAIL_RECORD_CDR': 'कॉल डिटेल रिकॉर्ड (CDR)',
    'TOWER_DUMP': 'मोबाइल टावर डंप (Tower Dump)',
    'WHATSAPP_CHAT_EXPORT': 'व्हाट्सएप चैट / सोशल मीडिया एक्सपोर्ट',
    'CCTV_DVR_FOOTAGE': 'सी.सी.टी.वी. / डी.वी.आर. फुटेज',
    'MOBILE_FORENSIC_IMAGE': 'मोबाइल फोन फॉरेंसिक इमेज',
    'AUDIO_VOICE_RECORDING': 'ऑडियो / कॉल रिकॉर्डिंग',
  };

  @override
  void dispose() {
    _exhibitController.dispose();
    _hashController.dispose();
    _imeiController.dispose();
    super.dispose();
  }

  void _runAudit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(evidenceRepositoryProvider);
      final res = await repo.auditBsaCertificate(
        caseId: widget.caseId,
        exhibitMark: _exhibitController.text.trim(),
        evidenceType: _evidenceType,
        scheduleFormatMatched: _scheduleMatched,
        partAExecuted: _partAExecuted,
        partBExecuted: _partBExecuted,
        hashAlgorithm: _hashAlgo,
        declaredHashValue: _hashController.text.trim().isEmpty ? null : _hashController.text.trim(),
        imeiNumber: _imeiController.text.trim().isEmpty ? null : _imeiController.text.trim(),
        contemporaneousAcquisition: _contemporaneous,
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
                  'लिखित साक्ष्य आपत्ति पत्र (धारा 63 BSA / 65B IEA)',
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      children: [
        LuxuryCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'bsa_cert_title'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _exhibitController,
                decoration: InputDecoration(labelText: AppStrings.tr(ref, 'exhibit_mark_label')),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _evidenceType,
                decoration: InputDecoration(labelText: AppStrings.tr(ref, 'evidence_type_label')),
                items: _evidenceTypeLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12.5))))
                    .toList(),
                onChanged: (val) => setState(() => _evidenceType = val ?? _evidenceType),
              ),
              const Divider(height: 18),

              const Text('सांविधिक अनुसूची (Schedule) सत्यापन:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('क्या प्रमाण पत्र BSA की विहित अनुसूची प्रारूप में है?', style: TextStyle(fontSize: 12)),
                value: _scheduleMatched,
                activeThumbColor: LuxuryPalette.champagneGold,
                onChanged: (val) => setState(() => _scheduleMatched = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('भाग क (प्रस्तुतकर्ता) हस्ताक्षरित है?', style: TextStyle(fontSize: 12)),
                value: _partAExecuted,
                activeThumbColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _partAExecuted = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('भाग ख (साइबर/फॉरेंसिक विशेषज्ञ) हस्ताक्षरित है?', style: TextStyle(fontSize: 12)),
                subtitle: const Text('विशेषज्ञ के अभाव में प्रमाण पत्र अपूर्ण है', style: TextStyle(fontSize: 10.5)),
                value: _partBExecuted,
                activeThumbColor: LuxuryPalette.courtNavy,
                onChanged: (val) => setState(() => _partBExecuted = val),
              ),
              const Divider(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _hashAlgo,
                      decoration: InputDecoration(labelText: AppStrings.tr(ref, 'hash_algorithm_label')),
                      items: const [
                        DropdownMenuItem(value: 'NONE', child: Text('कोई नहीं (None)')),
                        DropdownMenuItem(value: 'SHA256', child: Text('SHA-256')),
                        DropdownMenuItem(value: 'SHA1', child: Text('SHA-1')),
                        DropdownMenuItem(value: 'MD5', child: Text('MD5')),
                      ],
                      onChanged: (val) => setState(() => _hashAlgo = val ?? _hashAlgo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hashController,
                      decoration: InputDecoration(labelText: AppStrings.tr(ref, 'declared_hash_label')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _imeiController,
                decoration: InputDecoration(labelText: AppStrings.tr(ref, 'hardware_id_label')),
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
                      : const Icon(Icons.fingerprint, size: 18),
                  label: Text(_isLoading ? AppStrings.tr(ref, 'loading_text') : AppStrings.tr(ref, 'audit_bsa_cert_btn')),
                  onPressed: _isLoading ? null : _runAudit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_auditResult != null) ...[
          LuxuryCard(
            isAlert: _auditResult!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE',
            isVerified: _auditResult!.admissibilityStatus == 'PRIMA_FACIE_ADMISSIBLE',
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _auditResult!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE'
                          ? 'इलेक्ट्रॉनिक साक्ष्य अग्राह्य (Inadmissible)'
                          : 'प्रमाण पत्र प्रथम दृष्टया वैध',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _auditResult!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE'
                            ? LuxuryPalette.rubyAlert
                            : LuxuryPalette.emeraldVerified,
                      ),
                    ),
                    LuxuryBadge(
                      label: _auditResult!.exhibitMark,
                      foregroundColor: LuxuryPalette.champagneGold,
                      backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _auditResult!.actionableCourtroomObjection,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
                ),
                const Divider(height: 16),

                ..._auditResult!.statutoryDefects.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            d.severity == 'FATAL' ? Icons.dangerous : Icons.warning_amber,
                            size: 16,
                            color: d.severity == 'FATAL' ? LuxuryPalette.rubyAlert : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${d.statutoryClause}: ${d.defectDescriptionHindi}',
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
                    label: const Text('धारा 63 लिखित आपत्ति पत्र देखें व प्रिंट करें'),
                    onPressed: () => _showObjectionSheet(_auditResult!.writtenObjectionPetitionDraft),
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
