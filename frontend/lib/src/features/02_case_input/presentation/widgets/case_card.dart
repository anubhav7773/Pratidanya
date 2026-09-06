import 'package:flutter/material.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/services/activity_service.dart';
import '../../domain/criminal_case.dart';

class CaseCard extends StatelessWidget {
  final CriminalCase criminalCase;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback? onNoteTap;
  final VoidCallback? onSyncTap;
  final VoidCallback? onDownloadTap;

  const CaseCard({
    super.key,
    required this.criminalCase,
    required this.onTap,
    required this.onArchive,
    this.onNoteTap,
    this.onSyncTap,
    this.onDownloadTap,
  });

  bool get _isJudicialCustody =>
      criminalCase.accusedCustodyStatus == 'JUDICIAL_CUSTODY';

  String _formatCustodyLabel() {
    switch (criminalCase.accusedCustodyStatus) {
      case 'JUDICIAL_CUSTODY':
        return 'न्यायिक अभिरक्षा';
      case 'POLICE_CUSTODY':
        return 'पुलिस रिमांड';
      case 'ON_BAIL':
        return 'जमानत पर रिहा';
      case 'ANTICIPATORY':
        return 'अंतरिम जमानत पर';
      default:
        return criminalCase.accusedCustodyStatus;
    }
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
                  Row(
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
                          ActivityService.logActivity(
                            activityType: 'ECOURTS_SYNC_TRIGGERED',
                            details: {
                              'fir_number': criminalCase.firNumber,
                              'district': criminalCase.district,
                              'court': criminalCase.courtDesignation,
                            },
                          );
                          if (onSyncTap != null) {
                            onSyncTap!();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('मु.अ.सं. ${criminalCase.firNumber} ई-कोर्ट्स से सिंक हो रहा है...')),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildActionIcon(
                        icon: Icons.download,
                        tooltip: 'वकालतनामा डाउनलोड करें',
                        onPressed: () {
                          ActivityService.logActivity(
                            activityType: 'VAKALATNAMA_DOWNLOAD_TRIGGERED',
                            details: {
                              'fir_number': criminalCase.firNumber,
                              'accused_name': criminalCase.accusedName,
                              'court': criminalCase.courtDesignation,
                            },
                          );
                          if (onDownloadTap != null) {
                            onDownloadTap!();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('वकालतनामा PDF तैयार हो रहा है...')),
                            );
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF75777E)),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'archive') onArchive();
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'archive', child: Text('पुरालेख (Archive) करें')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
