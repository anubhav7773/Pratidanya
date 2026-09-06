import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../shared/components/statute_selector_bar.dart';
import '../controllers/case_controller.dart';
import '../../../08_voice_intake/presentation/widgets/court_voice_dictation_sheet.dart';
import '../../../08_voice_intake/domain/voice_intake_result.dart';
import '../../../08_ecourts_cis/domain/ecourts_models.dart';

class NewCaseFormScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCaseSaved;

  const NewCaseFormScreen({super.key, this.onCaseSaved});

  @override
  ConsumerState<NewCaseFormScreen> createState() => _NewCaseFormScreenState();
}

class _NewCaseFormScreenState extends ConsumerState<NewCaseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cnrNumberController = TextEditingController();
  final _firNumberController = TextEditingController();
  final _firYearController = TextEditingController(text: DateTime.now().year.toString());
  final _policeStationController = TextEditingController();
  final _districtController = TextEditingController();
  final _accusedNameController = TextEditingController();
  final _sectionInputController = TextEditingController();
  final _factualSummaryController = TextEditingController();


  StatuteSystem _selectedStatute = StatuteSystem.hybrid;
  String _custodyStatus = 'JUDICIAL_CUSTODY';
  String _courtDesignation = 'CJM (मुख्य न्यायिक मजिस्ट्रेट, लखनऊ)';

  final List<String> _sectionsList = [];

  final List<String> _courts = [
    'CJM (मुख्य न्यायिक मजिस्ट्रेट, लखनऊ)',
    'ACJM-I (अपर मुख्य न्यायिक मजिस्ट्रेट-I, लखनऊ)',
    'JMFC (न्यायिक मजिस्ट्रेट प्रथम श्रेणी)',
    'विशेष सत्र न्यायालय (Court of Sessions)',
    'विशेष न्यायाधीश (पॉक्सो / SC-ST कोर्ट)',
    'विशेष एनडीपीएस न्यायालय (NDPS Court)',
  ];

  @override
  void dispose() {
    _cnrNumberController.dispose();
    _firNumberController.dispose();
    _firYearController.dispose();
    _policeStationController.dispose();

    _districtController.dispose();
    _accusedNameController.dispose();
    _sectionInputController.dispose();
    _factualSummaryController.dispose();
    super.dispose();
  }

  void _addSection() {
    final text = _sectionInputController.text.trim();
    if (text.isNotEmpty && !_sectionsList.contains(text)) {
      setState(() {
        _sectionsList.add(text);
        _sectionInputController.clear();
      });
    }
  }

  void _removeSection(String sec) {
    setState(() {
      _sectionsList.remove(sec);
    });
  }

  String _mapCustodyToLabel(String key) {
    switch (key) {
      case 'JUDICIAL_CUSTODY':
        return 'जेल में (In Judicial Custody)';
      case 'POLICE_CUSTODY':
        return 'पुलिस रिमांड (Police Custody)';
      case 'ON_BAIL':
        return 'जमानत पर रिहा (On Bail)';
      case 'ANTICIPATORY':
        return 'अग्रिम जमानत (Anticipatory Bail)';
      default:
        return key;
    }
  }

  void _openVoiceDictationSheet() {
    ActivityService.logActivity(
      activityType: 'VOICE_DICTATION_OPENED',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CourtVoiceDictationSheet(
          onDictationTransferred: (VoiceDictationResult result) {
            setState(() {
              if (result.extractedEntities.firNumber != null &&
                  result.extractedEntities.firNumber!.isNotEmpty) {
                final parts = result.extractedEntities.firNumber!.split('/');
                _firNumberController.text = parts[0].trim();
                if (parts.length > 1) {
                  _firYearController.text = parts[1].trim();
                }
              }
              if (result.extractedEntities.policeStation != null &&
                  result.extractedEntities.policeStation!.isNotEmpty) {
                _policeStationController.text = result.extractedEntities.policeStation!;
              }
              if (result.extractedEntities.district != null &&
                  result.extractedEntities.district!.isNotEmpty) {
                _districtController.text = result.extractedEntities.district!;
              }
              if (result.extractedEntities.accusedNames.isNotEmpty) {
                _accusedNameController.text = result.extractedEntities.accusedNames.join(', ');
              }
              for (final sec in result.extractedEntities.sections) {
                if (!_sectionsList.contains(sec)) {
                  _sectionsList.add(sec);
                }
              }
              if (result.cleanedFactualMatrix.isNotEmpty) {
                _factualSummaryController.text = result.cleanedFactualMatrix;
              } else if (result.verbatimTranscriptHindi.isNotEmpty) {
                _factualSummaryController.text = result.verbatimTranscriptHindi;
              }
            });
          },
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_sectionsList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया कम से कम एक विधिक धारा जोड़ें।'),
            backgroundColor: StitchColors.alertCrimson,
          ),
        );
        return;
      }

      final fullFir = '${_firNumberController.text.trim()}/${_firYearController.text.trim()}';

      final success = await ref.read(caseFormControllerProvider.notifier).createCase(
            firNumber: fullFir,
            policeStation: _policeStationController.text.trim(),
            district: _districtController.text.trim(),
            stateJurisdiction: 'Uttar Pradesh',
            accusedName: _accusedNameController.text.trim(),
            accusedCustodyStatus: _custodyStatus,
            statuteSystem: _selectedStatute.name.toUpperCase(),
            underSections: _sectionsList,
            courtDesignation: _courtDesignation,
            stageOfCase: 'BAIL',
            cnrNumber: _cnrNumberController.text.trim().isNotEmpty ? _cnrNumberController.text.trim().toUpperCase() : null,
            lastCourtOrder: _factualSummaryController.text.trim(),
          );


      if (success && mounted) {
        ActivityService.logActivity(
          activityType: 'NEW_CASE_SAVED',
          details: {
            'fir_number': fullFir,
            'police_station': _policeStationController.text.trim(),
            'district': _districtController.text.trim(),
            'court': _courtDesignation,
            'sections': _sectionsList,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('आपराधिक केस सफलतापूर्वक दर्ज किया गया।'),
            backgroundColor: StitchColors.verifiedGreen,
          ),
        );
        if (widget.onCaseSaved != null) {
          widget.onCaseSaved!();
        } else {
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(caseFormControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar (Institutional Court Navy)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1C32),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'नया केस दर्ज करें',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'आपराधिक वाद डायरी • जिला एवं सत्र न्यायालय',
                                style: TextStyle(fontSize: 11, color: Color(0xFF76849F)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'वॉयस डिक्टेशन',
                        icon: const Icon(Icons.mic, color: Colors.amber),
                        onPressed: _openVoiceDictationSheet,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'प्रपत्र १/१',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Notice Sub-Banner
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDAE2FD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.gavel, color: Color(0xFF1F6C3A), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'आपराधिक वाद पंजीकरण (न्याय सेतु पोर्टल)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'सटीक प्रविष्टि से ई-सम्मन व केस डायरी स्वतः अद्यतित रहेगी',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF44474D)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Voice Dictation Quick Card
                      InkWell(
                        onTap: _openVoiceDictationSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D1C32), Color(0xFF1E3557)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.amber,
                                child: Icon(Icons.mic, color: Color(0xFF0D1C32), size: 18),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'बोलकर केस दर्ज करें (Court Voice Intake)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'मु.अ.सं., थाना, धाराएं व तथ्य बोलें • स्वतः फॉर्म भर जाएगा',
                                      style: TextStyle(fontSize: 11, color: Color(0xFFDAE2FD)),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Statute Selector Segmented Bar
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFEAEDFF)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'लागू विधिक संहिता चयन *',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.verified_user, size: 14, color: Color(0xFF1F6C3A)),
                                      SizedBox(width: 4),
                                      Text(
                                        'समकालिक अनुपालन',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              StatuteSelectorBar(
                                selectedSystem: _selectedStatute,
                                onSystemChanged: (sys) => setState(() => _selectedStatute = sys),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F3FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 14, color: Color(0xFF44474D)),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'नवीन भारतीय न्याय संहिता (BNS) एवं पूर्व भा.दं.वि. (IPC) दोनों धाराओं के मैपिंग हेतु सक्रिय।',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF44474D)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // e-Courts CNR Input Field (Institutional Bar)
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFEAEDFF)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(Icons.qr_code_2, size: 16, color: Color(0xFF1F6C3A)),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'ई-कोर्ट्स सी.एन.आर. संख्या (CNR Number)',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'ऐच्छिक (16 अक्षर)',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF75777E)),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _cnrNumberController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'उदा. UPHC010123452026',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.fingerprint, color: Color(0xFF0D1C32), size: 20),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                                    onPressed: () => _cnrNumberController.clear(),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC5C6CD))),
                                  filled: true,
                                  fillColor: const Color(0xFFFAF8FF),
                                ),
                                validator: CnrValidator.validate,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'सी.एन.आर. प्रविष्ट करने से केस डायरी स्वतः ई-कोर्ट्स सेवा (CIS 3.2) से सिंक्रोनाइज़ हो जाएगी।',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Row 1: FIR No & Year (2 Columns)
                      Row(

                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'मु.अ.सं. / एफ.आई.आर. *',
                              icon: Icons.tag,
                              controller: _firNumberController,
                              hint: 'उदा. 124',
                              validator: (val) => val == null || val.isEmpty ? 'अनिवार्य' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              label: 'दर्ज वर्ष (Year) *',
                              icon: Icons.calendar_today,
                              controller: _firYearController,
                              hint: '2026',
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || val.isEmpty ? 'अनिवार्य' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Police Station & District (2 Columns)
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'संबंधित थाना (P.S.) *',
                              icon: Icons.local_police_outlined,
                              controller: _policeStationController,
                              hint: 'कोतवाली नगर',
                              validator: (val) => val == null || val.isEmpty ? 'थाना अनिवार्य' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              label: 'जनपद (District) *',
                              icon: Icons.location_on_outlined,
                              controller: _districtController,
                              hint: 'लखनऊ',
                              validator: (val) => val == null || val.isEmpty ? 'जनपद अनिवार्य' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3: Accused Name
                      _buildInputField(
                        label: 'मुख्य अभियुक्त का नाम (Accused Name) *',
                        icon: Icons.person_outline,
                        controller: _accusedNameController,
                        hint: 'अभियुक्त का नाम दर्ज करें',
                        validator: (val) => val == null || val.isEmpty ? 'अभियुक्त का नाम अनिवार्य' : null,
                      ),
                      const SizedBox(height: 12),

                      // Row 4: Custody Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'वर्तमान अभिरक्षा स्थिति (Custody Status) *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDBD1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Color(0xFFD6603B)),
                                    SizedBox(width: 4),
                                    Text(
                                      'न्यायिक अभिरक्षा',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF842503)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _custodyStatus,
                            isExpanded: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_clock, color: Color(0xFFD6603B), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC5C6CD))),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              'JUDICIAL_CUSTODY',
                              'POLICE_CUSTODY',
                              'ON_BAIL',
                              'ANTICIPATORY',
                            ].map((opt) {
                              return DropdownMenuItem(
                                value: opt,
                                child: Text(_mapCustodyToLabel(opt), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _custodyStatus = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 5: Court Designation
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'संबंधित न्यायालय पदनाम (Court Designation) *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _courtDesignation,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF75777E), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC5C6CD))),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            isExpanded: true,
                            items: _courts.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _courtDesignation = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 6: Legal Sections Tag Box
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFEAEDFF)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'संबंधित विधिक धाराएं (Legal Sections) *',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_sectionsList.length} धाराएं संलग्न',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F6C3A)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _sectionsList.map((sec) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAEDFF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(sec, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF131B2E))),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _removeSection(sec),
                                          child: const Icon(Icons.close, size: 16, color: Color(0xFF75777E)),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _sectionInputController,
                                      decoration: InputDecoration(
                                        hintText: '+ धारा जोड़ें (उदा. 379 IPC / 303 BNS)...',
                                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF75777E)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC5C6CD))),
                                        filled: true,
                                        fillColor: const Color(0xFFF2F3FF),
                                      ),
                                      onSubmitted: (_) => _addSection(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D1C32),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('जोड़ें', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    onPressed: _addSection,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Row 7: Factual Summary Multiline
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'घटना एवं गिरफ्तारी का संक्षिप्त विवरण (Factual Summary)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ऐच्छिक पर अनुशंसित',
                                style: TextStyle(fontSize: 11, color: Color(0xFF75777E)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _factualSummaryController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'घटना का विवरण, घटना स्थल, गिरफ्तारी दिनांक व समय, बरामदगी पंचनामा विवरण दर्ज करें...',
                              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF75777E)),
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC5C6CD))),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Institutional Trust Notice
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEDFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.security, size: 20, color: Color(0xFF0D1C32)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ई-कोर्ट्स वाद प्रबंधन प्रणाली एवं भारतीय नागरिक सुरक्षा संहिता 2023 प्रक्रियानुसार सुरक्षित डाटा प्रविष्टि।',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF131B2E), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1C32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 20),
                      label: formState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'केस डायरी में सुरक्षित करें एवं विश्लेषण शुरू करें',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                      onPressed: formState.isLoading ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF1F6C3A)),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'स्वचालित केस स्टेटस ट्रैकिंग व एआई कानूनी ब्रीफ तैयार होगा',
                          style: TextStyle(fontSize: 11, color: Color(0xFF44474D)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF75777E), size: 18),
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF75777E)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFC5C6CD))),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
