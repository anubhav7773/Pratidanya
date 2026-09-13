import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../data/evidence_repository.dart';
import '../../domain/electronic_evidence_models.dart';

class ElectronicEvidenceAuditScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const ElectronicEvidenceAuditScreen({
    super.key,
    required this.caseId,
    required this.accusedName,
    required this.policeStation,
    required this.district,
  });

  @override
  ConsumerState<ElectronicEvidenceAuditScreen> createState() =>
      _ElectronicEvidenceAuditScreenState();
}

class _ElectronicEvidenceAuditScreenState
    extends ConsumerState<ElectronicEvidenceAuditScreen> {
  final _exhibitController = TextEditingController(text: 'Ex. P-14 (CDR / WhatsApp)');
  final _hashValueController = TextEditingController();
  final _imeiController = TextEditingController();

  String _evidenceType = 'CALL_DETAIL_RECORD_CDR';
  String _hashAlgorithm = 'NONE';
  bool _scheduleMatched = false;
  bool _partAExecuted = true;
  bool _partBExecuted = false;
  final bool _contemporaneous = true;

  bool _isLoading = false;
  ElectronicEvidenceAuditResult? _result;

  final Map<String, String> _evidenceTypeLabels = const {
    'CALL_DETAIL_RECORD_CDR': 'कॉल डिटेल रिकॉर्ड (CDR)',
    'TOWER_DUMP': 'मोबाइल टावर डंप (Tower Dump)',
    'WHATSAPP_CHAT_EXPORT': 'व्हाट्सएप चैट स्क्रीनशॉट / एक्सपोर्ट',
    'CCTV_DVR_FOOTAGE': 'सी.सी.टी.वी. / डी.वी.आर. फुटेज',
    'MOBILE_FORENSIC_IMAGE': 'मोबाइल फोन फॉरेंसिक क्लोन',
    'AUDIO_VOICE_RECORDING': 'ऑडियो / कॉल रिकॉर्डिंग',
    'SERVER_SYSTEM_LOGS': 'सर्वर / सिस्टम लॉग्स',
  };

  @override
  void dispose() {
    _exhibitController.dispose();
    _hashValueController.dispose();
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
        hashAlgorithm: _hashAlgorithm,
        declaredHashValue: _hashValueController.text.trim().isEmpty
            ? null
            : _hashValueController.text.trim(),
        imeiNumber: _imeiController.text.trim().isEmpty
            ? null
            : _imeiController.text.trim(),
        contemporaneousAcquisition: _contemporaneous,
        accusedName: widget.accusedName,
        policeStation: widget.policeStation,
        district: widget.district,
      );

      setState(() {
        _result = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('मूल्यांकन त्रुटि: $e'), backgroundColor: StitchColors.alertCrimson),
        );
      }
    }
  }

  void _showObjectionSheet(String draftText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('लिखित साक्ष्य आपत्ति पत्र (Sec 63 BSA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: draftText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('आपत्ति पत्र कॉपी हो गया')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(draftText, style: const TextStyle(fontSize: 12.5, height: 1.45)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('इलेक्ट्रॉनिक साक्ष्य प्रमाण पत्र परीक्षक (Sec 63 BSA)'),
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'धारा 63(4)(c) बी.एस.ए. 2023 / 65B आई.ई.ए. अनुसूची अनुपालन',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: StitchColors.courtNavy,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'अभियोजन द्वारा दाखिल इलेक्ट्रॉनिक साक्ष्य (CDR/CCTV/WhatsApp) के प्रमाण पत्र का विधिक व फॉरेंसिक परीक्षण:',
                    style: TextStyle(fontSize: 12, color: StitchColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _exhibitController,
                    decoration: const InputDecoration(
                      labelText: 'प्रदर्श / मार्क (Exhibit Mark)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    initialValue: _evidenceType,
                    decoration: const InputDecoration(
                      labelText: 'डिजिटल साक्ष्य का प्रकार',
                      border: OutlineInputBorder(),
                    ),
                    items: _evidenceTypeLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setState(() => _evidenceType = val ?? _evidenceType),
                  ),
                  const Divider(height: 24),

                  const Text('सांविधिक अनुसूची (Schedule) सत्यापन:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StitchColors.courtNavy)),
                  CheckboxListTile(
                    title: const Text('क्या प्रमाण पत्र BSA 2023 की विहित अनुसूची प्रारूप में है?'),
                    subtitle: const Text('पुराने या बिना प्रारूप वाले अनौपचारिक पत्र अवैध हैं'),
                    value: _scheduleMatched,
                    activeColor: StitchColors.verifiedGreen,
                    onChanged: (val) => setState(() => _scheduleMatched = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('भाग क (Part A) प्रस्तुतकर्ता द्वारा हस्ताक्षरित है?'),
                    value: _partAExecuted,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _partAExecuted = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('भाग ख (Part B) साइबर / फॉरेंसिक विशेषज्ञ द्वारा निष्पादित है?'),
                    subtitle: const Text('विशेषज्ञ के हस्ताक्षर के बिना प्रमाण पत्र कानूनी रूप से अपूर्ण है'),
                    value: _partBExecuted,
                    activeColor: StitchColors.courtNavy,
                    onChanged: (val) => setState(() => _partBExecuted = val ?? false),
                  ),
                  const Divider(height: 20),

                  const Text('क्रिप्टोग्राफिक हैश व अखंडता (Cryptographic Hash):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: StitchColors.courtNavy)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _hashAlgorithm,
                          decoration: const InputDecoration(labelText: 'हैश एल्गोरिदम', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'NONE', child: Text('कोई नहीं (None)')),
                            DropdownMenuItem(value: 'SHA256', child: Text('SHA-256 (64 वर्ण)')),
                            DropdownMenuItem(value: 'SHA1', child: Text('SHA-1 (40 वर्ण)')),
                            DropdownMenuItem(value: 'MD5', child: Text('MD5 (32 वर्ण)')),
                          ],
                          onChanged: (val) => setState(() => _hashAlgorithm = val ?? _hashAlgorithm),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _hashValueController,
                          decoration: const InputDecoration(labelText: 'घोषित हैश मान', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _imeiController,
                    decoration: const InputDecoration(
                      labelText: 'उपकरण पहचान (IMEI / MAC एड्रेस)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StitchColors.courtNavy,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.security),
                      label: Text(_isLoading ? 'फॉरेंसिक समीक्षा जारी है...' : 'प्रमाण पत्र की विधिक वैधता जांचें'),
                      onPressed: _isLoading ? null : _runAudit,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: _result!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE'
                            ? StitchColors.alertCrimsonBg
                            : StitchColors.verifiedGreenBg,
                        border: Border.all(
                          color: _result!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE'
                              ? StitchColors.alertCrimson
                              : StitchColors.verifiedGreen,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _result!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE'
                                    ? Icons.cancel_rounded
                                    : Icons.check_circle_rounded,
                                color: _result!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE'
                                    ? StitchColors.alertCrimson
                                    : StitchColors.verifiedGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _result!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE'
                                      ? 'इलेक्ट्रॉनिक साक्ष्य अग्राह्य (Fatal Defect: Inadmissible)'
                                      : 'प्रमाण पत्र प्रथम दृष्टया वैध',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _result!.admissibilityStatus == 'FATAL_DEFECT_INADMISSIBLE'
                                        ? StitchColors.alertCrimson
                                        : StitchColors.verifiedGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _result!.actionableCourtroomObjection,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('पहचानी गई वैधानिक त्रुटियां (Statutory Defects):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 6),
                    ..._result!.statutoryDefects.map((d) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: Icon(
                              d.severity == 'FATAL' ? Icons.dangerous : Icons.warning_amber,
                              color: d.severity == 'FATAL' ? StitchColors.alertCrimson : Colors.orange,
                            ),
                            title: Text(d.statutoryClause, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            subtitle: Text('${d.defectDescriptionHindi}\nन्यायालयीन उपाय: ${d.trialCountermeasure}', style: const TextStyle(fontSize: 12, height: 1.35)),
                          ),
                        )),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: StitchColors.alertCrimson, foregroundColor: Colors.white),
                        icon: const Icon(Icons.description),
                        label: const Text('लिखित आपत्ति पत्र (Written Objection) देखें व प्रिंट करें'),
                        onPressed: () => _showObjectionSheet(_result!.writtenObjectionPetitionDraft),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
