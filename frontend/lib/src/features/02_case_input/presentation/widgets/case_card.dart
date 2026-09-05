import 'package:flutter/material.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../domain/criminal_case.dart';

class CaseCard extends StatelessWidget {
  final CriminalCase criminalCase;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const CaseCard({
    super.key,
    required this.criminalCase,
    required this.onTap,
    required this.onArchive,
  });

  String _formatCustodyStatus(String status) {
    switch (status) {
      case 'JUDICIAL_CUSTODY':
        return 'न्यायिक अभिरक्षा (जेल में)';
      case 'POLICE_CUSTODY':
        return 'पुलिस रिमांड';
      case 'ON_BAIL':
        return 'जमानत पर रिहा';
      case 'ANTICIPATORY':
        return 'अग्रिम जमानत प्राप्त';
      default:
        return status;
    }
  }

  String _formatHearingDate(DateTime? date) {
    if (date == null) return 'तारीख नियत नहीं';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isHearingSoon = criminalCase.nextHearingDate != null &&
        criminalCase.nextHearingDate!.difference(DateTime.now()).inDays <= 3;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: StitchColors.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: FIR details & Custody pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'मु.अ.सं. ${criminalCase.firNumber}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: StitchColors.courtNavy,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: criminalCase.accusedCustodyStatus == 'JUDICIAL_CUSTODY'
                          ? StitchColors.unverifiedAmberBg
                          : StitchColors.verifiedGreenBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: criminalCase.accusedCustodyStatus == 'JUDICIAL_CUSTODY'
                            ? StitchColors.unverifiedAmber
                            : StitchColors.verifiedGreen,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _formatCustodyStatus(criminalCase.accusedCustodyStatus),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: criminalCase.accusedCustodyStatus == 'JUDICIAL_CUSTODY'
                            ? StitchColors.unverifiedAmber
                            : StitchColors.verifiedGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Row 2: Location & Court
              Text(
                'थाना: ${criminalCase.policeStation}, ${criminalCase.district} | ${criminalCase.courtDesignation}',
                style: const TextStyle(fontSize: 12.5, color: StitchColors.textSecondary),
              ),
              const SizedBox(height: 8),

              // Row 3: Accused name
              Row(
                children: [
                  const Text('अभियुक्त: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: StitchColors.chamberSlate)),
                  Expanded(
                    child: Text(
                      criminalCase.accusedName,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: StitchColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 4: Section tags wrap
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: criminalCase.underSections.map((sec) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      sec,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: StitchColors.textPrimary),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 20),

              // Row 5: Hearing date & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: isHearingSoon ? StitchColors.alertCrimson : StitchColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'अगली तारीख: ${_formatHearingDate(criminalCase.nextHearingDate)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isHearingSoon ? FontWeight.bold : FontWeight.w500,
                          color: isHearingSoon ? StitchColors.alertCrimson : StitchColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: StitchColors.courtNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          criminalCase.stageOfCase == 'BAIL' ? 'जमानत सुनवाई' : criminalCase.stageOfCase,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: StitchColors.courtNavy),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
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
}
