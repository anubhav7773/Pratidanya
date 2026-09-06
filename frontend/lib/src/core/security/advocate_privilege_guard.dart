import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AdvocatePrivilegeGuard {
  static const MethodChannel _channel = MethodChannel('me.asiverticals.pratidnya/security');

  /// Enforces Advocate-Client Privilege under Section 132 of the Bharatiya Sakshya Adhiniyam, 2023
  /// (equivalent to Section 126 of the Indian Evidence Act, 1872).
  /// Dynamically engages Android WindowManager FLAG_SECURE to block unauthorized screenshots,
  /// background screen recording, and system recents window cache leakage.
  static Future<void> enableConfidentialityProtection() async {
    if (kIsWeb) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android || (!kIsWeb && Platform.isAndroid)) {
        await _channel.invokeMethod('enableSecureWindow');
      }
    } catch (e) {
      debugPrint("[Privilege Guard] Secure window engagement note: $e");
    }
  }

  /// Disengages screen capture protection on public non-sensitive screens (e.g., Paywall, Login)
  static Future<void> disableConfidentialityProtection() async {
    if (kIsWeb) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android || (!kIsWeb && Platform.isAndroid)) {
        await _channel.invokeMethod('disableSecureWindow');
      }
    } catch (e) {
      debugPrint("[Privilege Guard] Secure window disengagement note: $e");
    }
  }
}
