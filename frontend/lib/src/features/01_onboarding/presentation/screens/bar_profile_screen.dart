import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/utils/bar_council_validator.dart';
import '../../../../shared/components/stitch_hindi_text_field.dart';
import '../controllers/auth_controller.dart';

class BarProfileScreen extends ConsumerStatefulWidget {
  const BarProfileScreen({super.key});

  @override
  ConsumerState<BarProfileScreen> createState() => _BarProfileScreenState();
}

class _BarProfileScreenState extends ConsumerState<BarProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _barNumberController = TextEditingController();
  final _courtNameController = TextEditingController(text: 'जिला एवं सत्र न्यायालय, लखनऊ');
  final _chamberController = TextEditingController();
  String _selectedState = 'Uttar Pradesh';

  @override
  void dispose() {
    _fullNameController.dispose();
    _barNumberController.dispose();
    _courtNameController.dispose();
    _chamberController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).saveBarProfile(
            fullName: _fullNameController.text.trim(),
            barCouncilNumber: _barNumberController.text.trim().toUpperCase(),
            primaryCourtName: _courtNameController.text.trim(),
            enrolledState: _selectedState,
            chamberAddress: _chamberController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final availableStates = BarCouncilValidator.statePrefixes.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('अधिवक्ता बार काउंसिल सत्यापन'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'व्यावसायिक पहचान सत्यापन',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: StitchColors.courtNavy,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'अधिवक्ता अधिनियम 1961 की धारा 30 के अनुपालन हेतु राज्य बार काउंसिल पंजीकरण आवश्यक है।',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: StitchColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),

                StitchHindiTextField(
                  controller: _fullNameController,
                  label: 'अधिवक्ता का पूर्ण नाम (यथा बार नामांकन)',
                  hint: 'उदा. राजेश कुमार त्रिपाठी',
                  validator: (val) => val == null || val.trim().isEmpty ? 'कृपया पूर्ण नाम दर्ज करें' : null,
                ),
                const SizedBox(height: 14),

                const Text(
                  'संबद्ध राज्य बार काउंसिल (State Bar Council)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: StitchColors.courtNavy),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: const BorderSide(color: StitchColors.borderSubtle),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: availableStates
                      .map((stateName) => DropdownMenuItem(value: stateName, child: Text(stateName)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedState = val);
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                const SizedBox(height: 14),

                StitchHindiTextField(
                  controller: _barNumberController,
                  label: 'बार काउंसिल पंजीकरण संख्या (Bar Enrollment No.)',
                  hint: 'उदा. UP/1234/2018',
                  validator: (val) => BarCouncilValidator.validateEnrollmentNumber(val, _selectedState),
                ),
                const SizedBox(height: 14),

                StitchHindiTextField(
                  controller: _courtNameController,
                  label: 'प्राथमिक जिला/अधीनस्थ न्यायालय',
                  hint: 'उदा. जिला एवं सत्र न्यायालय, लखनऊ',
                  validator: (val) => val == null || val.trim().isEmpty ? 'न्यायालय का नाम दर्ज करें' : null,
                ),
                const SizedBox(height: 14),

                StitchHindiTextField(
                  controller: _chamberController,
                  label: 'चैंबर कार्यालय का पता (वैकल्पिक)',
                  hint: 'उदा. चैंबर संख्या 42, दीवानी कचहरी परिसर',
                ),
                const SizedBox(height: 28),

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
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('सत्यापन पूर्ण करें एवं केस डायरी खोलें',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
