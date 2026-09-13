import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/luxury_palette.dart';
import '../../../../shared/components/luxury_card.dart';

class TacticalLaunchpadGrid extends ConsumerWidget {
  final Function(int targetTab) onSelectSuite;

  const TacticalLaunchpadGrid({
    super.key,
    required this.onSelectSuite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      _LaunchCategory(
        tabTargetIndex: 1, // Remand Hub
        titleKey: 'nav_remand_hub',
        subtitleKey: 'mod_default_bail_sub',
        icon: Icons.shield_outlined,
        accentColor: LuxuryPalette.champagneGold,
        badgeText: 'Sec 187 & 479',
        modules: [
          'mod_default_bail',
          'mod_remand_audit',
          'mod_undertrial_relief',
        ],
      ),
      _LaunchCategory(
        tabTargetIndex: 2, // Forensics Vault
        titleKey: 'nav_forensics',
        subtitleKey: 'mod_bsa_cert_sub',
        icon: Icons.fingerprint,
        accentColor: LuxuryPalette.sapphireNotice,
        badgeText: 'BSA 2023',
        modules: [
          'mod_bsa_cert',
          'mod_medico_legal',
          'mod_malkhana',
        ],
      ),
      _LaunchCategory(
        tabTargetIndex: 3, // Trial Studio
        titleKey: 'nav_trial_studio',
        subtitleKey: 'mod_cross_exam_sub',
        icon: Icons.record_voice_over_outlined,
        accentColor: LuxuryPalette.emeraldVerified,
        badgeText: 'Sec 147 & 148',
        modules: [
          'mod_witness_grid',
          'mod_cross_exam',
        ],
      ),
      _LaunchCategory(
        tabTargetIndex: 4, // Regional & HUD
        titleKey: 'nav_regional_hud',
        subtitleKey: 'mod_live_hud_sub',
        icon: Icons.bolt,
        accentColor: LuxuryPalette.amberWarning,
        badgeText: '< 450ms Realtime',
        modules: [
          'mod_regional_acts',
          'mod_live_hud',
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr(ref, 'defense_hub_title'),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.tr(ref, 'defense_hub_sub'),
                      style: TextStyle(
                        fontSize: 11.0,
                        color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.tune_rounded, size: 18, color: LuxuryPalette.champagneGold),
            ],
          ),
        ),
        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 1.35,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _buildCategoryCard(context, ref, cat, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref,
    _LaunchCategory cat,
    bool isDark,
  ) {
    return LuxuryCard(
      hasGoldAccent: cat.tabTargetIndex == 1,
      padding: const EdgeInsets.all(12.0),
      onTap: () => onSelectSuite(cat.tabTargetIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cat.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(cat.icon, size: 18, color: cat.accentColor),
              ),
              LuxuryBadge(
                label: cat.badgeText,
                foregroundColor: cat.accentColor,
                backgroundColor: cat.accentColor.withValues(alpha: 0.08),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, cat.titleKey),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? LuxuryPalette.darkTextPrimary : LuxuryPalette.courtNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.tr(ref, cat.subtitleKey),
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${cat.modules.length} ${AppStrings.tr(ref, "chamber_badge").split(" ").first}',
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.antiqueBronze,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: isDark ? LuxuryPalette.champagneGold : LuxuryPalette.courtNavy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaunchCategory {
  final int tabTargetIndex;
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color accentColor;
  final String badgeText;
  final List<String> modules;

  _LaunchCategory({
    required this.tabTargetIndex,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.accentColor,
    required this.badgeText,
    required this.modules,
  });
}
