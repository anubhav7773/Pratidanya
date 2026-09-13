import 'package:flutter/material.dart';

class LuxuryPalette {
  // --- PRIMARY LEGAL ACCENTS (METALLIC GOLD & BRONZE) ---
  static const Color champagneGold = Color(0xFFC5A059);
  static const Color royalGold = Color(0xFFD4AF37);
  static const Color paleGold = Color(0xFFF3E5AB);
  static const Color antiqueBronze = Color(0xFF8C6D32);
  static const Color goldGlow = Color(0xFFFACC15);

  // --- LIGHT MODE PALETTE (EXECUTIVE CHAMBER) ---
  static const Color courtNavy = Color(0xFF0A192F);
  static const Color courtNavyElevated = Color(0xFF13233E);
  static const Color offWhiteCanvas = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderStrong = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // --- DARK MODE PALETTE (OLED MIDNIGHT HIGH COURT) ---
  static const Color midnightCanvas = Color(0xFF050811);
  static const Color midnightSurface = Color(0xFF0B132B);
  static const Color midnightElevated = Color(0xFF131D3B);
  static const Color midnightBorder = Color(0xFF1E293B);
  static const Color midnightBorderSubtle = Color(0xFF27354A);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // --- STATUTORY STATUS ACCENTS (CRIMINAL CODE INDICATORS) ---
  static const Color emeraldVerified = Color(0xFF10B981);
  static const Color emeraldBgLight = Color(0xFFECFDF5);
  static const Color emeraldBgDark = Color(0xFF064E3B);

  static const Color rubyAlert = Color(0xFFE11D48);
  static const Color rubyBgLight = Color(0xFFFFF1F2);
  static const Color rubyBgDark = Color(0xFF4C0519);

  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color amberBgLight = Color(0xFFFFFBEB);
  static const Color amberBgDark = Color(0xFF451A03);

  static const Color sapphireNotice = Color(0xFF2563EB);
  static const Color sapphireBgLight = Color(0xFFEFF6FF);
  static const Color sapphireBgDark = Color(0xFF1E3A8A);

  // --- LUXURY GRADIENTS ---
  static const LinearGradient goldShimmer = LinearGradient(
    colors: [Color(0xFFB8860B), Color(0xFFE6CA65), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient courtHeaderGradient = LinearGradient(
    colors: [Color(0xFF061122), Color(0xFF0F2342)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF0D1832), Color(0xFF080F21)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
