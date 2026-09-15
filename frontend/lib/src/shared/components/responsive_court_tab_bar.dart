import 'package:flutter/material.dart';
import '../../core/theme/luxury_palette.dart';

class ResponsiveCourtTabBar extends StatelessWidget {
  final TabController controller;
  final List<CourtTabItem> tabs;
  final bool isDark;

  const ResponsiveCourtTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? LuxuryPalette.midnightElevated : LuxuryPalette.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? LuxuryPalette.midnightBorder : LuxuryPalette.lightBorder,
          width: 1.0,
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: isDark ? LuxuryPalette.midnightSurface : LuxuryPalette.courtNavy,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: LuxuryPalette.champagneGold.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: LuxuryPalette.champagneGold,
        unselectedLabelColor: isDark ? LuxuryPalette.darkTextSecondary : LuxuryPalette.lightTextSecondary,
        labelStyle: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14.0),
        tabs: tabs.map((tabItem) {
          return Tab(
            height: 38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tabItem.icon != null) ...[
                  Icon(tabItem.icon, size: 15),
                  const SizedBox(width: 6),
                ],
                Text(tabItem.label),
                if (tabItem.badgeText != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: tabItem.badgeColor ?? LuxuryPalette.champagneGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tabItem.badgeText!,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: tabItem.badgeTextColor ?? LuxuryPalette.courtNavy,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CourtTabItem {
  final String label;
  final IconData? icon;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;

  CourtTabItem({
    required this.label,
    this.icon,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
  });
}
