import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/luxury_palette.dart';

class BilingualExecutiveAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String titleKey;
  final String? subtitleKey;
  final List<Widget>? additionalActions;
  final bool showBackButton;
  final VoidCallback? onBackOverride;

  const BilingualExecutiveAppBar({
    super.key,
    required this.titleKey,
    this.subtitleKey,
    this.additionalActions,
    this.showBackButton = true,
    this.onBackOverride,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final currentTheme = ref.watch(appThemeProvider);
    final isDark = currentTheme == ThemeMode.dark;

    final titleText = AppStrings.tr(ref, titleKey);
    final subtitleText = subtitleKey != null ? AppStrings.tr(ref, subtitleKey!) : null;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1.5,
      leading: showBackButton && Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: currentLang == AppLanguage.hindi ? 'पीछे जाएं' : 'Back',
              onPressed: onBackOverride ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titleText,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitleText != null) ...[
            const SizedBox(height: 1.5),
            Text(
              subtitleText,
              style: TextStyle(
                fontSize: 11.0,
                color: isDark ? LuxuryPalette.darkTextSecondary : Colors.white70,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: [
        if (additionalActions != null) ...additionalActions!,

        // Dynamic Persistent Language Toggle Pill
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => ref.read(appLanguageProvider.notifier).toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162238) : const Color(0xFF132A4A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: LuxuryPalette.champagneGold.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentLang == AppLanguage.hindi ? 'हिन्दी' : 'EN',
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: LuxuryPalette.champagneGold,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Icon(
                    Icons.translate_rounded,
                    size: 13.0,
                    color: isDark ? Colors.white70 : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Day / Night Theme Toggle Button
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? LuxuryPalette.goldGlow : Colors.white,
            size: 19.0,
          ),
          tooltip: isDark
              ? (currentLang == AppLanguage.hindi ? 'डे मोड (दिन)' : 'Day Mode')
              : (currentLang == AppLanguage.hindi ? 'नाइट मोड (रात)' : 'Night Mode'),
          onPressed: () => ref.read(appThemeProvider.notifier).toggleTheme(),
        ),
        const SizedBox(width: 6.0),
      ],
    );
  }
}
