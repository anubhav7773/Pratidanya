import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/language_provider.dart';

class OnboardingLanguageToggle extends ConsumerWidget {
  const OnboardingLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(onboardingLanguageProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCAD7EB)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(
            context: context,
            label: 'हिन्दी',
            isSelected: currentLang == AppLanguage.hindi,
            onTap: () => ref.read(onboardingLanguageProvider.notifier).state = AppLanguage.hindi,
          ),
          _buildPill(
            context: context,
            label: 'English',
            isSelected: currentLang == AppLanguage.english,
            onTap: () => ref.read(onboardingLanguageProvider.notifier).state = AppLanguage.english,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D1C32) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }
}
