import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/stitch_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/navigation/presentation/executive_shell_scaffold.dart';

class PratidnyaApp extends ConsumerWidget {
  const PratidnyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeProvider);

    return MaterialApp(
      title: 'Pratidnya LegalTech',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: StitchTheme.lightTheme,
      darkTheme: StitchTheme.darkTheme,
      home: const ExecutiveShellScaffold(),
    );
  }
}

typedef PratidnyaApplication = PratidnyaApp;
