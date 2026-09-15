import 'package:flutter/material.dart';
import '../../core/theme/luxury_palette.dart';

class ChamberSnackBar {
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: LuxuryPalette.courtNavy,
      accentColor: LuxuryPalette.emeraldVerified,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFF2C0B12),
      accentColor: LuxuryPalette.rubyAlert,
      duration: duration,
    );
  }

  static void showNotice(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: LuxuryPalette.courtNavy,
      accentColor: LuxuryPalette.champagneGold,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color accentColor,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // Elevated above the 72dp floating dock navigation bar
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 88),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        duration: duration,
        elevation: 6.0,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentColor.withValues(alpha: 0.7), width: 1.2),
        ),
        content: Row(
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
