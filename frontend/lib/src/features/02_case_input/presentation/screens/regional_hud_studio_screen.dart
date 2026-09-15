import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/components/bilingual_executive_app_bar.dart';
import '../../../../shared/components/bci_disclaimer_banner.dart';
import '../../../../shared/components/responsive_court_tab_bar.dart';
import '../views/up_gangsters_goondas_tab_view.dart';
import '../views/surety_scrutiny_tab_view.dart';
import '../views/live_courtroom_hud_tab_view.dart';

class RegionalHudStudioScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String accusedName;
  final String policeStation;
  final String district;

  const RegionalHudStudioScreen({
    super.key,
    this.caseId = 'UP-REG-2026-701',
    this.accusedName = 'अभियुक्त (Accused)',
    this.policeStation = 'कोतवाली नगर',
    this.district = 'लखनऊ',
  });

  @override
  ConsumerState<RegionalHudStudioScreen> createState() => _RegionalHudStudioScreenState();
}

class _RegionalHudStudioScreenState extends ConsumerState<RegionalHudStudioScreen>
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
        titleKey: 'nav_regional_hud',
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
                label: AppStrings.tr(ref, 'mod_regional_acts'),
                icon: Icons.security_rounded,
                badgeText: 'Farhana Ratio',
              ),
              CourtTabItem(
                label: 'जमानत प्रतिभू (Moti Ram Scrutiny)',
                icon: Icons.handshake_outlined,
                badgeText: 'Sec 483 BNSS',
              ),
              CourtTabItem(
                label: AppStrings.tr(ref, 'mod_live_hud'),
                icon: Icons.bolt_rounded,
                badgeText: '< 450ms Realtime',
              ),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                UpGangstersGoondasTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
                SuretyScrutinyTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
                  policeStation: widget.policeStation,
                  district: widget.district,
                ),
                LiveCourtroomHudTabView(
                  caseId: widget.caseId,
                  accusedName: widget.accusedName,
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

