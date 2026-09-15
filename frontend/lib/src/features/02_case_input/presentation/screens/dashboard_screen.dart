import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../../../shared/components/executive_dock_navigation_bar.dart';
import '../../../../shared/components/executive_chamber_drawer.dart';
import '../../data/case_docket_repository.dart';
import '../../domain/case_docket_model.dart';
import '../widgets/court_ticker_banner.dart';
import '../widgets/tactical_launchpad_grid.dart';
import 'case_registration_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAddNewCase;

  const DashboardScreen({
    super.key,
    this.onAddNewCase,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedFilterIndex = 0; // 0: By Date, 1: By Court, 2: In Custody

  void _openCaseRegistration() {
    if (widget.onAddNewCase != null) {
      widget.onAddNewCase!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CaseRegistrationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockets = ref.watch(caseDocketListProvider);

    // Compute live metrics
    final totalCases = dockets.length;
    final today = DateTime.now();
    final todayHearings = dockets.where((d) =>
        d.nextHearingDate.year == today.year &&
        d.nextHearingDate.month == today.month &&
        d.nextHearingDate.day == today.day).length;
    final inCustodyCount = dockets.where((d) => d.custodyStatus == 'JUDICIAL_CUSTODY' || d.custodyStatus == 'POLICE_CUSTODY').length;

    // Apply Filter Chips
    List<CaseDocketModel> filteredDockets = dockets;
    if (_selectedFilterIndex == 0) {
      // By Date: Sort soonest hearing first
      filteredDockets = List.from(dockets)..sort((a, b) => a.nextHearingDate.compareTo(b.nextHearingDate));
    } else if (_selectedFilterIndex == 1) {
      // By Court: Group by court name
      filteredDockets = List.from(dockets)..sort((a, b) => a.courtName.compareTo(b.courtName));
    } else if (_selectedFilterIndex == 2) {
      // In Custody only
      filteredDockets = dockets.where((d) => d.custodyStatus == 'JUDICIAL_CUSTODY').toList();
    }

    return Scaffold(
      drawer: const ExecutiveChamberDrawer(),
      appBar: const BilingualExecutiveAppBar(
        titleKey: 'active_dockets',
        subtitleKey: 'court_jurisdiction',
        showBackButton: false,
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),
          const CourtTickerBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 110.0, top: 4.0),
              children: [
                // 1. Dynamic Chamber Metrics
                _buildMetricsOverview(
                  isDark: isDark,
                  totalCases: totalCases,
                  todayHearings: todayHearings,
                  inCustody: inCustodyCount,
                ),
                const SizedBox(height: 16),

                // 2. Tactical Defense Launchpad (All 10 Breakthrough Modules)
                TacticalLaunchpadGrid(
                  onSelectSuite: (targetTab) {
                    ref.read(executiveNavIndexProvider.notifier).state = targetTab;
                  },
                ),
                const SizedBox(height: 18),

                // 3. Search & Filter Bar
                _buildFilterBar(isDark, filteredDockets.length),
                const SizedBox(height: 12),

                // 4. Filtered Case Dockets List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    children: filteredDockets.map((docket) {
                      return _buildCaseDocketCard(context, ref, docket, isDark);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74.0),
        child: FloatingActionButton.extended(
          backgroundColor: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
          foregroundColor: isDark ? LuxuryPalette.courtNavy : LuxuryPalette.lightSurface,
          elevation: 4.0,
          icon: const Icon(Icons.add_task_rounded, size: 18),
          label: Text(
            AppStrings.tr(ref, 'new_case_btn'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: _openCaseRegistration,
        ),
      ),
    );
  }

  Widget _buildMetricsOverview({
    required bool isDark,
    required int totalCases,
    required int todayHearings,
    required int inCustody,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              title: AppStrings.tr(ref, 'total_cases'),
              value: totalCases.toString().padLeft(2, '0'),
              accentColor: LuxuryPalette.champagneGold,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              title: AppStrings.tr(ref, 'today_hearings'),
              value: todayHearings.toString().padLeft(2, '0'),
              accentColor: LuxuryPalette.emeraldVerified,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              title: AppStrings.tr(ref, 'judicial_custody'),
              value: inCustody.toString().padLeft(2, '0'),
              accentColor: LuxuryPalette.rubyAlert,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: isDark ? LuxuryPalette.midnightSurface : LuxuryPalette.lightSurface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isDark ? LuxuryPalette.midnightBorder : LuxuryPalette.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? LuxuryPalette.darkTextPrimary : LuxuryPalette.courtNavy,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark, int count) {
    final filters = [
      AppStrings.tr(ref, 'filter_by_date'),
      AppStrings.tr(ref, 'filter_by_court'),
      AppStrings.tr(ref, 'filter_custody'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        children: [
          for (int i = 0; i < filters.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(filters[i]),
                selected: _selectedFilterIndex == i,
                selectedColor: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _selectedFilterIndex == i
                      ? (isDark ? LuxuryPalette.courtNavy : LuxuryPalette.lightSurface)
                      : (isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary),
                ),
                onSelected: (val) => setState(() => _selectedFilterIndex = i),
              ),
            ),
          const Spacer(),
          Text(
            '$count वाद',
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: isDark ? LuxuryPalette.darkTextMuted : LuxuryPalette.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseDocketCard(
    BuildContext context,
    WidgetRef ref,
    CaseDocketModel docket,
    bool isDark,
  ) {
    return LuxuryCard(
      hasGoldAccent: docket.isDefaultBailUrgent || docket.hasForensicTamperingAlert,
      isAlert: docket.isDefaultBailUrgent,
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(14.0),
      onTap: () {
        // Direct tap routing: Jump to relevant studio suite
        if (docket.isDefaultBailUrgent || docket.isUnderTrialReliefEligible) {
          ref.read(executiveNavIndexProvider.notifier).state = 1; // Remand Suite
        } else if (docket.hasForensicTamperingAlert) {
          ref.read(executiveNavIndexProvider.notifier).state = 2; // Forensics Suite
        } else {
          ref.read(executiveNavIndexProvider.notifier).state = 3; // Trial Studio
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                docket.crimeNumber,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              if (docket.isDefaultBailUrgent)
                const LuxuryBadge(
                  label: 'डिफ़ॉल्ट जमानत प्रोद्भूत (Sec 187)',
                  foregroundColor: LuxuryPalette.rubyAlert,
                  backgroundColor: LuxuryPalette.rubyBgLight,
                  icon: Icons.alarm_on,
                )
              else if (docket.isUnderTrialReliefEligible)
                const LuxuryBadge(
                  label: '1/3 सजा पूर्ण (Sec 479)',
                  foregroundColor: LuxuryPalette.emeraldVerified,
                  backgroundColor: LuxuryPalette.emeraldBgLight,
                  icon: Icons.lock_clock,
                )
              else if (docket.hasForensicTamperingAlert)
                const LuxuryBadge(
                  label: 'FSL / सील दोष (Reg 19)',
                  foregroundColor: LuxuryPalette.amberWarning,
                  backgroundColor: LuxuryPalette.amberBgLight,
                  icon: Icons.fingerprint,
                )
              else
                LuxuryBadge(
                  label: docket.substantiveRegime,
                  foregroundColor: LuxuryPalette.champagneGold,
                  backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${docket.policeStation}, ${docket.district}',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Icon(Icons.person_outline, size: 15, color: isDark ? Colors.white60 : Colors.black54),
              const SizedBox(width: 4),
              Text(
                docket.accusedName,
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? LuxuryPalette.midnightElevated : LuxuryPalette.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  docket.substantiveSections,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.gavel_outlined, size: 14, color: isDark ? Colors.white60 : Colors.black54),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  docket.courtName,
                  style: TextStyle(
                    fontSize: 11.0,
                    color: isDark ? LuxuryPalette.darkTextMuted : LuxuryPalette.lightTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131F37) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? LuxuryPalette.midnightBorderSubtle : LuxuryPalette.lightBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_note, size: 14, color: LuxuryPalette.champagneGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'पेशी: ${docket.hearingPurpose}',
                    style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${docket.custodyDaysElapsed} दिन जेल',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: docket.custodyDaysElapsed >= docket.statutoryThresholdDays
                        ? LuxuryPalette.rubyAlert
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
