import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'advocate@barcouncil.in');
  final _passwordController = TextEditingController(text: 'CriminalCourt@2024');
  final _enrollmentController = TextEditingController(text: 'UP/1234/2018');

  String _selectedStateBar = 'UP';
  bool _rememberSession = true;
  bool _obscurePassword = true;
  bool _isSignUpMode = false;

  final Map<String, String> _stateBarCouncils = {
    'UP': 'उत्तर प्रदेश बार काउंसिल (Bar Council of Uttar Pradesh)',
    'DL': 'दिल्ली बार काउंसिल (Bar Council of Delhi)',
    'BR': 'बिहार राज्य बार काउंसिल (Bihar State Bar Council)',
    'MP': 'मध्य प्रदेश राज्य बार काउंसिल (MP State Bar Council)',
    'RJ': 'राजस्थान बार काउंसिल (Bar Council of Rajasthan)',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _enrollmentController.dispose();
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
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Brand Header Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDAE2FD), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.balance,
                              size: 40,
                              color: StitchColors.courtNavy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'प्रतिदान्या (Pratidanya)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF131B2E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'जिला न्यायालय आपराधिक विधिक सहायक',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF44474D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA4F1B2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 16, color: Color(0xFF1F6C3A)),
                            SizedBox(width: 4),
                            Text(
                              'सत्यापित विधिक प्रवेश द्वार',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF24703E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Card 1: Advocate Enrollment Card
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFEAEDFF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user, size: 20, color: Color(0xFF131B2E)),
                              SizedBox(width: 8),
                              Text(
                                'अधिवक्ता सनद एवं सत्यापन',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF131B2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'राज्य विधिज्ञ परिषद (State Bar Council)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStateBar,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF75777E), size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFC5C6CD)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF2F3FF),
                          ),
                          isExpanded: true,
                          items: _stateBarCouncils.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF131B2E)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStateBar = val);
                          },
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'बार काउंसिल पंजीकरण संख्या (Enrollment No.)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF131B2E),
                              ),
                            ),
                            Text(
                              'प्रारूप: UP/1234/2018',
                              style: TextStyle(fontSize: 11, color: Color(0xFF75777E)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _enrollmentController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF75777E), size: 20),
                            suffixIcon: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4F1B2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Color(0xFF1F6C3A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'सत्यापित',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF24703E)),
                                  ),
                                ],
                              ),
                            ),
                            hintText: 'उदा. UP/1234/2018',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFC5C6CD)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF2F3FF),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'पंजीकरण संख्या अनिवार्य है' : null,
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 15, color: Color(0xFF75777E)),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'सनद प्रमाण-पत्र के अनुसार अपनी आधिकारिक पंजीकरण संख्या दर्ज करें।',
                                style: TextStyle(fontSize: 12, color: Color(0xFF75777E)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Card 2: Authentication Form Card
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFEAEDFF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.vpn_key, size: 20, color: Color(0xFF0D1C32)),
                                SizedBox(width: 8),
                                Text(
                                  'अधिवक्ता अभिगम खाता (Login Portal)',
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E7FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'चरण 2/2',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF44474D)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'पंजीकृत ईमेल आईडी (Registered Email ID)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF75777E), size: 20),
                            hintText: 'advocate@barcouncil.in',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFC5C6CD)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF2F3FF),
                          ),
                          validator: (val) => val == null || !val.contains('@') ? 'कृपया मान्य ईमेल दर्ज करें' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'पासवर्ड / सुरक्षा पिन (Security PIN)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF131B2E)),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('पासवर्ड रीसेट लिंक आपके ईमेल पर भेजा गया है।')),
                                );
                              },
                              child: const Text(
                                'पासवर्ड भूल गए?',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: StitchColors.courtNavy),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF75777E), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF75777E),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            hintText: '••••••••',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFC5C6CD)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF2F3FF),
                          ),
                          validator: (val) => val == null || val.length < 6 ? 'न्यूनतम 6 अक्षर आवश्यक हैं' : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberSession,
                                  activeColor: StitchColors.courtNavy,
                                  onChanged: (val) => setState(() => _rememberSession = val ?? false),
                                ),
                                const Text('सत्र सुरक्षित याद रखें', style: TextStyle(fontSize: 13, color: Color(0xFF131B2E))),
                              ],
                            ),
                            const Row(
                              children: [
                                Icon(Icons.fingerprint, size: 18, color: Color(0xFF1F6C3A)),
                                SizedBox(width: 4),
                                Text(
                                  'बायोमेट्रिक सक्षम',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F6C3A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D1C32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: authState.isLoading ? null : _submit,
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isSignUpMode ? 'पंजीकरण करें (Register)' : 'अधिवक्ता प्रवेश करें (Login as Advocate)',
                                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.login, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                            child: Text(
                              _isSignUpMode ? 'पहले से खाता है? लॉगिन करें' : 'नया चैंबर खाता बनाएं (पंजीकरण)',
                              style: const TextStyle(color: StitchColors.courtNavy, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text('अथवा (OR)', style: TextStyle(fontSize: 12, color: Color(0xFF75777E))),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFC5C6CD)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.blueAccent),
                            label: const Text(
                              'Google One-Tap से लॉगिन करें',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF131B2E),
                              ),
                            ),
                            onPressed: authState.isLoading
                                ? null
                                : () => ref.read(authControllerProvider.notifier).loginWithGoogle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Card 3: Statutory Gate Notice Card
                Card(
                  elevation: 0,
                  color: const Color(0xFFE2E7FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gavel, size: 20, color: Color(0xFFD6603B)),
                            SizedBox(width: 8),
                            Text(
                              'वैधानिक चेतावनी एवं सूचना (Statutory Gate)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'यह प्रणाली केवल अधिवक्ता अधिनियम, 1961 की धारा 30 (Section 30 of the Advocates Act 1961) के तहत राज्य विधिज्ञ परिषद में नामांकित एवं आपराधिक विधि व्यवसाय के लिए अधिकृत वकीलों के उपयोग हेतु पूर्णतः आरक्षित है। अनधिकृत प्रवेश, गलत सनद विवरण अथवा न्यायिक पोर्टल डेटा का दुरुपयोग भारतीय न्याय संहिता (BNS) एवं आईटी अधिनियम, 2000 के अंतर्गत संज्ञेय एवं दंडनीय अपराध है।',
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 12, color: Color(0xFF44474D), height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lock, size: 16, color: Color(0xFF1F6C3A)),
                                  SizedBox(width: 6),
                                  Text(
                                    '256-bit e-Courts SSL एन्क्रिप्टेड',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF131B2E)),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.verified, size: 16, color: Color(0xFF1F6C3A)),
                                  SizedBox(width: 6),
                                  Text(
                                    'विधिक सेवा पोर्टल 2026',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF131B2E)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
