import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/luxury_card.dart';
import '../../../../shared/components/executive_dock_navigation_bar.dart';
import '../../../../shared/components/executive_chamber_drawer.dart';
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
  int _selectedFilterIndex = 0;

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
                // 1. Executive Chamber Metrics
                _buildMetricsOverview(isDark),
                const SizedBox(height: 16),

                // 2. Tactical Defense Launchpad
                TacticalLaunchpadGrid(
                  onSelectSuite: (targetTab) {
                    ref.read(executiveNavIndexProvider.notifier).state = targetTab;
                  },
                ),
                const SizedBox(height: 18),

                // 3. Search & Filter Bar
                _buildFilterBar(isDark),
                const SizedBox(height: 12),

                // 4. Case Dockets Container
                _buildDocketsList(isDark),
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

  Widget _buildMetricsOverview(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              title: AppStrings.tr(ref, 'total_cases'),
              value: '12',
              accentColor: LuxuryPalette.champagneGold,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              title: AppStrings.tr(ref, 'today_hearings'),
              value: '03',
              accentColor: LuxuryPalette.emeraldVerified,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricTile(
              title: AppStrings.tr(ref, 'judicial_custody'),
              value: '05',
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

  Widget _buildFilterBar(bool isDark) {
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
            '3 ${AppStrings.tr(ref, "today_hearings")}',
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

  Widget _buildDocketsList(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        children: [
          _buildSampleCaseCard(
            isDark: isDark,
            crimeNumber: 'मु.अ.सं. 124/2026',
            policeStation: 'कोतवाली नगर, लखनऊ',
            accusedName: 'रामू उर्फ राम प्रकाश',
            courtName: 'CJM, लखनऊ (कक्ष संख्या 14)',
            sections: 'BNS 103(1) / 351(2)',
            custodyStatus: 'न्यायिक अभिरक्षा (42 दिन)',
            isUrgentDefaultBail: true,
          ),
          _buildSampleCaseCard(
            isDark: isDark,
            crimeNumber: 'मु.अ.सं. 89/2026',
            policeStation: 'हजरतगंज, लखनऊ',
            accusedName: 'दिनेश कुमार',
            courtName: 'विशेष न्यायाधीश (NDPS Act)',
            sections: 'NDPS Act Sec 20(b)(ii)(C)',
            custodyStatus: 'न्यायिक अभिरक्षा (185 दिन)',
            isUrgentDefaultBail: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCaseCard({
    required bool isDark,
    required String crimeNumber,
    required String policeStation,
    required String accusedName,
    required String courtName,
    required String sections,
    required String custodyStatus,
    required bool isUrgentDefaultBail,
  }) {
    return LuxuryCard(
      hasGoldAccent: isUrgentDefaultBail,
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                crimeNumber,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              if (isUrgentDefaultBail)
                const LuxuryBadge(
                  label: 'डिफ़ॉल्ट जमानत निकट',
                  foregroundColor: LuxuryPalette.rubyAlert,
                  backgroundColor: LuxuryPalette.rubyBgLight,
                  icon: Icons.alarm_on,
                )
              else
                LuxuryBadge(
                  label: custodyStatus.split(" ").first,
                  foregroundColor: LuxuryPalette.champagneGold,
                  backgroundColor: LuxuryPalette.champagneGold.withValues(alpha: 0.08),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            policeStation,
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
                accusedName,
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
                  sections,
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
                  courtName,
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
        ],
      ),
    );
  }
}
