import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/luxury_palette.dart';

final executiveNavIndexProvider = StateProvider<int>((ref) => 0);

class ExecutiveDockNavigationBar extends ConsumerWidget {
  final int activeAlertCount;

  const ExecutiveDockNavigationBar({
    super.key,
    this.activeAlertCount = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(executiveNavIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      _NavItemData(
        icon: Icons.folder_copy_outlined,
        activeIcon: Icons.folder_copy,
        labelKey: 'nav_dockets',
      ),
      _NavItemData(
        icon: Icons.gavel_outlined,
        activeIcon: Icons.gavel,
        labelKey: 'nav_remand_hub',
        hasBadge: activeAlertCount > 0,
      ),
      _NavItemData(
        icon: Icons.fingerprint,
        activeIcon: Icons.fingerprint,
        labelKey: 'nav_forensics',
      ),
      _NavItemData(
        icon: Icons.record_voice_over_outlined,
        activeIcon: Icons.record_voice_over,
        labelKey: 'nav_trial_studio',
      ),
      _NavItemData(
        icon: Icons.bolt_outlined,
        activeIcon: Icons.bolt,
        labelKey: 'nav_regional_hud',
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF091224).withValues(alpha: 0.95)
            : LuxuryPalette.courtNavy.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? LuxuryPalette.midnightBorder
              : LuxuryPalette.champagneGold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final isSelected = currentIndex == index;

          return Expanded(
            child: _buildDockItem(
              context: context,
              ref: ref,
              item: item,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(executiveNavIndexProvider.notifier).state = index;
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDockItem({
    required BuildContext context,
    required WidgetRef ref,
    required _NavItemData item,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final label = AppStrings.tr(ref, item.labelKey);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 6 : 4,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? LuxuryPalette.champagneGold.withValues(alpha: 0.18)
                  : LuxuryPalette.courtNavyElevated)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: LuxuryPalette.champagneGold.withValues(alpha: 0.6),
                  width: 1.0,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 20,
                  color: isSelected
                      ? LuxuryPalette.champagneGold
                      : (isDark ? Colors.white60 : Colors.white70),
                ),
                if (item.hasBadge)
                  Positioned(
                    right: -5,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: LuxuryPalette.rubyAlert,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? LuxuryPalette.champagneGold
                    : (isDark ? Colors.white60 : Colors.white70),
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  final bool hasBadge;

  _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    this.hasBadge = false,
  });
}
