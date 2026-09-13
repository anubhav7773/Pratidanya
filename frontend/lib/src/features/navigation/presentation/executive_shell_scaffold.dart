import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/components/executive_dock_navigation_bar.dart';
import '../../02_case_input/presentation/screens/dashboard_screen.dart';
import '../../02_case_input/presentation/screens/pre_trial_remand_hub_screen.dart';
import '../../02_case_input/presentation/screens/forensic_evidence_vault_screen.dart';
import '../../02_case_input/presentation/screens/trial_examination_studio_screen.dart';
import '../../02_case_input/presentation/screens/regional_acts_audit_screen.dart';

class ExecutiveShellScaffold extends ConsumerWidget {
  const ExecutiveShellScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTabIndex = ref.watch(executiveNavIndexProvider);

    final List<Widget> pages = [
      DashboardScreen(
        onAddNewCase: () {
          // Triggers case intake modal
        },
      ),
      // 1. Dedicated Pre-Trial & Remand Defense Hub (Pillar A)
      const PreTrialRemandHubScreen(),
      // 2. Dedicated Forensic & Evidence Vault Screen (Pillar B)
      const ForensicEvidenceVaultScreen(),
      // 3. Dedicated Trial Examination & Cross-Exam Studio (Pillar C)
      const TrialExaminationStudioScreen(),
      // 4. Regional Acts & Tactical Courtroom HUD (Pillars D & E)
      const RegionalActsAuditScreen(
        caseId: 'ACTIVE-REGIONAL-DOCKET',
        accusedName: 'अभियुक्त',
        policeStation: 'कोतवाली',
        district: 'लखनऊ',
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: activeTabIndex,
        children: pages,
      ),
      bottomNavigationBar: const ExecutiveDockNavigationBar(
        activeAlertCount: 2,
      ),
    );
  }
}
