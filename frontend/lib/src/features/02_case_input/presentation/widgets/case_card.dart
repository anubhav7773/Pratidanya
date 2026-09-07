import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/constants/custody_status_registry.dart';
import '../../domain/criminal_case.dart';
import '../../../01_onboarding/presentation/controllers/auth_controller.dart';
import '../../../05_verify_and_export/data/court_pdf_builder.dart';
import '../../../09_ecourts_cis/presentation/widgets/ecourts_sync_dialog.dart';
import '../controllers/case_controller.dart';

class CaseCard extends StatelessWidget {
  final CriminalCase criminalCase;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onNoteTap;
  final VoidCallback? onSyncTap;
  final VoidCallback? onDownloadTap;

  const CaseCard({
    super.key,
    required this.criminalCase,
    required this.onTap,
    required this.onArchive,
    this.onDelete,
    this.onNoteTap,
    this.onSyncTap,
    this.onDownloadTap,
  });

  bool get _isJudicialCustody =>
      CustodyStatusRegistry.isPhysicalDetention(criminalCase.accusedCustodyStatus);

  String _formatCustodyLabel() {
    return CustodyStatusRegistry.getShortLabel(criminalCase.accusedCustodyStatus);
  }

  String _formatHearingDate(DateTime? date) {
    if (date == null) return 'तारीख नियत नहीं';
    final months = [
      'जनवरी',
      'फ़रवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितंबर',
      'अक्टूबर',
      'नवंबर',
      'दिसंबर'
    ];
    final monthName = date.month >= 1 && date.month <= 12 ? months[date.month - 1] : '${date.month}';
    return '${date.day} $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = criminalCase.nextHearingDate != null &&
        criminalCase.nextHearingDate!.year == now.year &&
        criminalCase.nextHearingDate!.month == now.month &&
        criminalCase.nextHearingDate!.day == now.day;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color(0xFFEAEDFF)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: FIR No + Case Number Badge + Court Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'मु.अ.सं. ${criminalCase.firNumber}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D1C32),
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (criminalCase.caseNumber != null && criminalCase.caseNumber!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E7FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  criminalCase.caseNumber!,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF131B2E)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_police_outlined, size: 14, color: Color(0xFF75777E)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'थाना ${criminalCase.policeStation}, जिला ${criminalCase.district}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF44474D)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEDFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      criminalCase.courtDesignation,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF44474D)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle Row: Accused + Custody Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'अभियुक्त (पैरवी)',
                            style: TextStyle(fontSize: 11, color: Color(0xFF44474D)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            criminalCase.accusedName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF131B2E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isJudicialCustody ? const Color(0xFFFFDBD1) : const Color(0xFFA4F1B2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isJudicialCustody ? Icons.lock : Icons.verified,
                            size: 13,
                            color: _isJudicialCustody ? const Color(0xFF842503) : const Color(0xFF1F6C3A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCustodyLabel(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isJudicialCustody ? const Color(0xFF842503) : const Color(0xFF24703E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Legal Section Tags
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: criminalCase.underSections.map((sec) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEDFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sec,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF131B2E)),
                    ),
                  );
                }).toList(),
              ),

              // Specialized Act Action Chips (NDPS, POCSO, SC/ST, NI Act)
              Builder(
                builder: (ctx) {
                  final sectionsCombined = criminalCase.underSections.join(' ').toUpperCase();
                  final hasNdps = sectionsCombined.contains('NDPS') || sectionsCombined.contains('स्वापक') || sectionsCombined.contains('8/') || sectionsCombined.contains('20/') || sectionsCombined.contains('21/');
                  final hasPocso = sectionsCombined.contains('POCSO') || sectionsCombined.contains('पॉक्सो') || sectionsCombined.contains('376');
                  final hasScst = sectionsCombined.contains('SC/ST') || sectionsCombined.contains('एससी') || sectionsCombined.contains('POA');
                  final hasNiAct = sectionsCombined.contains('138') || sectionsCombined.contains('NI') || sectionsCombined.contains('एनआई');

                  if (!hasNdps && !hasPocso && !hasScst && !hasNiAct) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: [
                        if (hasNdps)
                          _buildSpecializedBadge(
                            context: ctx,
                            label: 'NDPS धारा 50 ऑडिट',
                            icon: Icons.local_pharmacy,
                            color: const Color(0xFF842503),
                            bgColor: const Color(0xFFFFECE5),
                            route: '/cases/${criminalCase.id}/ndps-compliance',
                          ),
                        if (hasPocso)
                          _buildSpecializedBadge(
                            context: ctx,
                            label: 'पॉक्सो आयु निर्धारण (JJ 94)',
                            icon: Icons.child_care,
                            color: const Color(0xFF1E3A5F),
                            bgColor: const Color(0xFFE6F0FF),
                            route: '/cases/${criminalCase.id}/pocso-age-audit',
                          ),
                        if (hasScst)
                          _buildSpecializedBadge(
                            context: ctx,
                            label: 'SC/ST 14A विशेष अपील',
                            icon: Icons.policy,
                            color: const Color(0xFF1F6C3A),
                            bgColor: const Color(0xFFEAF8EE),
                            route: '/cases/${criminalCase.id}/scst-appeal',
                          ),
                        if (hasNiAct)
                          _buildSpecializedBadge(
                            context: ctx,
                            label: '138 चेक नोटिस बचाव',
                            icon: Icons.payments,
                            color: const Color(0xFF8A5100),
                            bgColor: const Color(0xFFFFF4E0),
                            route: '/cases/${criminalCase.id}/ni-act-defense',
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEAEDFF)),
              const SizedBox(height: 10),

              // Bottom Row: Hearing Date, Stage, and Action Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isToday ? Icons.event : Icons.calendar_month,
                              size: 15,
                              color: isToday ? StitchColors.alertCrimson : const Color(0xFF131B2E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isToday
                                  ? 'आज की तारीख: ${_formatHearingDate(criminalCase.nextHearingDate)}'
                                  : 'अगली तारीख: ${_formatHearingDate(criminalCase.nextHearingDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isToday ? StitchColors.alertCrimson : const Color(0xFF131B2E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'कार्यवाही चरण: ${criminalCase.stageOfCase == 'BAIL' ? 'जमानत अर्जी सुनवाई (Bail)' : criminalCase.stageOfCase}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isToday ? const Color(0xFFD6603B) : const Color(0xFF44474D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer(
                    builder: (ctx, ref, _) {
                      return Row(
                        children: [
                          _buildActionIcon(
                            icon: Icons.edit_note,
                            tooltip: 'केस डायरी नोट',
                            onPressed: onNoteTap ?? onTap,
                          ),
                          const SizedBox(width: 4),
                          _buildActionIcon(
                            icon: Icons.sync,
                            tooltip: 'ई-कोर्ट स्थिति सिंक्रनाइज़',
                            color: const Color(0xFF1F6C3A),
                            onPressed: () {
                              if (onSyncTap != null) {
                                onSyncTap!();
                              } else {
                                _handleEcourtsSync(context);
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          _buildActionIcon(
                            icon: Icons.download,
                            tooltip: 'वकालतनामा डाउनलोड करें',
                            onPressed: () {
                              if (onDownloadTap != null) {
                                onDownloadTap!();
                              } else {
                                _handleVakalatnamaDownload(context, ref);
                              }
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF75777E)),
                            padding: EdgeInsets.zero,
                            onSelected: (val) {
                              if (val == 'draft_studio') {
                                ActivityService.logActivity(activityType: 'DRAFT_STUDIO_NAVIGATED', details: {'case_id': criminalCase.id});
                                context.push('/cases/${criminalCase.id}/draft-studio');
                              } else if (val == 'ndps') {
                                ActivityService.logActivity(activityType: 'MENU_NDPS_OPENED', details: {'case_id': criminalCase.id});
                                context.push('/cases/${criminalCase.id}/ndps-compliance');
                              } else if (val == 'pocso') {
                                ActivityService.logActivity(activityType: 'MENU_POCSO_OPENED', details: {'case_id': criminalCase.id});
                                context.push('/cases/${criminalCase.id}/pocso-age-audit');
                              } else if (val == 'scst') {
                                ActivityService.logActivity(activityType: 'MENU_SCST_OPENED', details: {'case_id': criminalCase.id});
                                context.push('/cases/${criminalCase.id}/scst-appeal');
                              } else if (val == 'ni_act') {
                                ActivityService.logActivity(activityType: 'MENU_NI_ACT_OPENED', details: {'case_id': criminalCase.id});
                                context.push('/cases/${criminalCase.id}/ni-act-defense');
                              } else if (val == 'vakalatnama') {
                                _handleVakalatnamaDownload(context, ref);
                              } else if (val == 'archive') {
                                onArchive();
                              } else if (val == 'delete') {
                                if (onDelete != null) {
                                  onDelete!();
                                } else {
                                  _confirmDelete(context, ref, criminalCase);
                                }
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'draft_studio',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_document, size: 16, color: Color(0xFF0D1C32)),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('जमानत ड्राफ्टिंग स्टूडियो')),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'ndps',
                                child: Row(
                                  children: [
                                    Icon(Icons.local_pharmacy, size: 16, color: Color(0xFF842503)),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('NDPS धारा 50 अनुपालन')),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'pocso',
                                child: Row(
                                  children: [
                                    Icon(Icons.child_care, size: 16, color: Color(0xFF1E3A5F)),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('POCSO आयु निर्धारण (Sec 94)')),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'scst',
                                child: Row(
                                  children: [
                                    Icon(Icons.policy, size: 16, color: Color(0xFF1F6C3A)),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('SC/ST Act धारा 14A अपील')),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'ni_act',
                                child: Row(
                                  children: [
                                    Icon(Icons.payments, size: 16, color: Color(0xFF8A5100)),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('NI Act 138 चेक बचाव')),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'vakalatnama',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFC00000)),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('वकालतनामा (Vakalatnama) PDF')),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive, size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('पुरालेख (Archive) करें')),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_forever, size: 16, color: StitchColors.alertCrimson),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'केस हटाएं (Delete Case)',
                                        style: TextStyle(color: StitchColors.alertCrimson, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecializedBadge({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        ActivityService.logActivity(activityType: 'SPECIALIZED_BADGE_TAPPED', details: {'route': route, 'case_id': criminalCase.id});
        context.push(route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVakalatnamaDownload(BuildContext context, WidgetRef ref) async {
    ActivityService.logActivity(
      activityType: 'VAKALATNAMA_DOWNLOAD_TRIGGERED',
      details: {
        'fir_number': criminalCase.firNumber,
        'accused_name': criminalCase.accusedName,
        'court': criminalCase.courtDesignation,
      },
    );

    final profile = ref.read(currentAdvocateProfileProvider).valueOrNull;
    final advocateName = profile?.fullName ?? 'अधिवक्ता';
    final barNumber = profile?.barCouncilNumber ?? 'UP/1234/2026';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('वकालतनामा PDF तैयार हो रहा है...'), duration: Duration(seconds: 1)),
    );

    try {
      final pdfBytes = await CourtPdfBuilder.generateVakalatnamaPdf(
        courtName: criminalCase.courtDesignation,
        firNumber: criminalCase.firNumber,
        policeStation: criminalCase.policeStation,
        district: criminalCase.district,
        accusedName: criminalCase.accusedName,
        underSections: criminalCase.underSections,
        advocateName: advocateName,
        barCouncilNumber: barNumber,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Vakalatnama_${criminalCase.firNumber.replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('वकालतनामा निर्माण त्रुटि: $e')),
        );
      }
    }
  }

  void _handleEcourtsSync(BuildContext context) {
    ActivityService.logActivity(
      activityType: 'ECOURTS_SYNC_TRIGGERED',
      details: {
        'fir_number': criminalCase.firNumber,
        'district': criminalCase.district,
        'court': criminalCase.courtDesignation,
      },
    );

    EcourtsSyncDialog.show(context, criminalCase);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, CriminalCase criminalCase) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: StitchColors.alertCrimson),
            SizedBox(width: 8),
            Text('केस हटाएं (Delete Case)?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'क्या आप मु.अ.सं. ${criminalCase.firNumber} (अभियुक्त: ${criminalCase.accusedName}) को स्थायी रूप से हटाना चाहते हैं?\n\nड्राफ्ट और नजीर तैयार होने के बाद यदि आप चाहें तो यह केस हमेशा के लिए हटाया जा सकता है। यह प्रक्रिया अपरिवर्तनीय है।',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('रद्द करें', style: TextStyle(color: Color(0xFF44474D))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: StitchColors.alertCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('हां, केस हटाएं'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      try {
        await ref.read(caseFormControllerProvider.notifier).deleteCase(criminalCase.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('मु.अ.सं. ${criminalCase.firNumber} सफलतापूर्वक हटा दिया गया।'),
              backgroundColor: const Color(0xFF0D1C32),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('केस हटाने में त्रुटि: $e'),
              backgroundColor: StitchColors.alertCrimson,
            ),
          );
        }
      }
    }
  }


  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEDFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color ?? const Color(0xFF131B2E)),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

