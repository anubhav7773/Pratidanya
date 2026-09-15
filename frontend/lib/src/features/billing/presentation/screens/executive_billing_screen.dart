import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paywall_screen.dart';

class ExecutiveBillingScreen extends ConsumerWidget {
  const ExecutiveBillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PaywallScreen();
  }
}
