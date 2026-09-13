import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/stitch_theme.dart';
import 'core/theme/theme_controller.dart';

class PratidnyaApplication extends ConsumerWidget {
  const PratidnyaApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'Pratidanya',
      theme: StitchTheme.lightTheme,
      darkTheme: StitchTheme.chamberDarkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

typedef PratidnyaApp = PratidnyaApplication;
