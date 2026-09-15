import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/responsive_court_tab_bar.dart';
import '../views/default_bail_tab_view.dart';
import '../views/remand_compliance_tab_view.dart';
import '../views/undertrial_relief_tab_view.dart';

class PreTrialRemandHubScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const PreTrialRemandHubScreen({
    super.key,
    this.caseId = 'UP-CR-2026-104',
    this.accusedName = 'अभियुक्त (Accused)',
    this.policeStation = 'कोतवाली नगर',
    this.district = 'लखनऊ',
  });

  @override
  ConsumerState<PreTrialRemandHubScreen> createState() => _PreTrialRemandHubScreenState();
}

class _PreTrialRemandHubScreenState extends ConsumerState<PreTrialRemandHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BilingualExecutiveAppBar(
        titleKey: 'nav_remand_hub',
        subtitleKey: 'defense_hub_sub',
        showBackButton: false,
      ),
      body: Column(
        children: [
          const BciDisclaimerBanner(),

          // Responsive Scrollable Tab Bar
          ResponsiveCourtTabBar(
            controller: _tabController,
            isDark: isDark,
            tabs: [
              CourtTabItem(
                label: AppStrings.tr(ref, 'mod_default_bail'),
                icon: Icons.alarm_on_rounded,
                badgeText: 'Sec 187',
              ),
              CourtTabItem(
                label: AppStrings.tr(ref, 'mod_remand_audit'),
                icon: Icons.gavel_rounded,
                badgeText: 'Arnesh Kumar',
              ),
              CourtTabItem(
                label: AppStrings.tr(ref, 'mod_undertrial_relief'),
                icon: Icons.lock_clock_rounded,
                badgeText: '1/3rd Rule',
              ),
            ],
          ),

          // Tab Content Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DefaultBailTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
                RemandComplianceTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
                UndertrialReliefTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

