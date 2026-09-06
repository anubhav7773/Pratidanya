import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { hindi, english }

final onboardingLanguageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.hindi);
