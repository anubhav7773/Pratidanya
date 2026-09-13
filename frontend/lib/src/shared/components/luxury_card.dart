import 'package:flutter/material.dart';
import '../../core/theme/luxury_palette.dart';

class LuxuryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool hasGoldAccent;
  final bool isAlert;
  final bool isVerified;

  const LuxuryCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.hasGoldAccent = false,
    this.isAlert = false,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor;
    if (isAlert) {
      borderColor = LuxuryPalette.rubyAlert;
    } else if (isVerified) {
      borderColor = LuxuryPalette.emeraldVerified;
    } else if (hasGoldAccent) {
      borderColor = isDark ? LuxuryPalette.royalGold : LuxuryPalette.champagneGold;
    } else {
      borderColor = isDark ? LuxuryPalette.midnightBorder : LuxuryPalette.lightBorder;
    }

    final cardBg = isDark
        ? (hasGoldAccent ? const Color(0xFF0F1A33) : LuxuryPalette.midnightSurface)
        : LuxuryPalette.lightSurface;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: borderColor, width: hasGoldAccent || isAlert || isVerified ? 1.4 : 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(14.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class LuxuryBadge extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final IconData? icon;

  const LuxuryBadge({
    super.key,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.0, color: foregroundColor),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
