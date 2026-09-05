import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../shared/components/stitch_hindi_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final controller = ref.read(authControllerProvider.notifier);

      if (_isSignUpMode) {
        controller.signupWithEmail(email, password);
      } else {
        controller.loginWithEmail(email, password);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error.toString()),
            backgroundColor: StitchColors.alertCrimson,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: StitchColors.courtNavy,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: const Center(
                      child: Text(
                        'प्र',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'प्रतिज्ञा (Pratidnya)',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: StitchColors.courtNavy,
                        ),
                  ),
                ),
                Center(
                  child: Text(
                    'जिला न्यायालय आपराधिक विधिक सहायक',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: StitchColors.textSecondary,
                        ),
                  ),
                ),
                const SizedBox(height: 32),

                // Google One-Tap Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: StitchColors.borderSubtle, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                      backgroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.account_circle, color: Colors.blueAccent),
                    label: const Text(
                      'Google खाते से लॉगिन करें',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: StitchColors.textPrimary,
                      ),
                    ),
                    onPressed: authState.isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).loginWithGoogle(),
                  ),
                ),

                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('अथवा चैंबर ईमेल से', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                StitchHindiTextField(
                  controller: _emailController,
                  label: 'अधिवक्ता ईमेल पता',
                  hint: 'advocate@chamber.in',
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) =>
                      val == null || !val.contains('@') ? 'कृपया मान्य ईमेल दर्ज करें' : null,
                ),
                const SizedBox(height: 14),

                StitchHindiTextField(
                  controller: _passwordController,
                  label: 'पासवर्ड',
                  obscureText: true,
                  validator: (val) =>
                      val == null || val.length < 6 ? 'न्यूनतम 6 अक्षर आवश्यक हैं' : null,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StitchColors.courtNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                    ),
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isSignUpMode ? 'पंजीकरण करें' : 'लॉगिन करें',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                    child: Text(
                      _isSignUpMode
                          ? 'पहले से खाता है? लॉगिन करें'
                          : 'नया चैंबर खाता बनाएं (पंजीकरण)',
                      style: const TextStyle(color: StitchColors.courtNavy, fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, size: 20, color: StitchColors.unverifiedAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'अधिवक्ता अधिनियम 1961 की धारा 30 के अनुसार यह मंच केवल पंजीकृत विधिक पेशेवरों हेतु प्रतिबंधित है।',
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
