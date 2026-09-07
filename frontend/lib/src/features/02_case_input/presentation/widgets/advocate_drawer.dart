import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/activity_service.dart';
import '../../../01_onboarding/presentation/controllers/auth_controller.dart';

class AdvocateDrawer extends ConsumerWidget {
  const AdvocateDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentAdvocateProfileProvider).valueOrNull;
    final advocateName = profile?.fullName ?? 'अधिवक्ता चैंबर';
    final barNumber = profile?.barCouncilNumber ?? 'सत्यापन प्रक्रियाधीन';
    final stateBar = profile?.enrolledState ?? 'राज्य बार काउंसिल';

    return Drawer(
      backgroundColor: const Color(0xFFFAF8FF),
      child: Column(
        children: [
          // Drawer Header: Deep Court Navy with Scales of Justice & Advocate Profile
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1C32),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.balance,
                        color: Color(0xFFD4AF37),
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F6C3A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'सत्यापित अधिवक्ता',
                            style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  advocateName,
                  style: const TextStyle(
                    color: Color(0xFFFAF8FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'पंजीकरण संख्या: $barNumber',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  stateBar,
                  style: const TextStyle(
                    color: Color(0xFFB9C7E4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Drawer Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.folder_shared,
                  title: 'आपराधिक डॉकेट (Active Cases)',
                  subtitle: 'सत्र एवं जिला न्यायालय वाद सूची',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/cases');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.add_circle_outline,
                  title: 'नया वाद पंजीकरण',
                  subtitle: 'प्राथमिकी विवरण एवं धाराएं जोड़ें',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/cases/new');
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Divider(height: 1, color: Color(0xFFE2E7FF)),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.gavel,
                  title: 'उच्च न्यायालय स्टूडियो (High Court)',
                  subtitle: 'धारा 374 अपील, धारा 397 पुनरीक्षण, धारा 389 स्थगन',
                  badgeColor: const Color(0xFF842503),
                  badgeText: 'HC',
                  onTap: () {
                    Navigator.of(context).pop();
                    ActivityService.logActivity(activityType: 'DRAWER_HIGH_COURT_OPENED');
                    context.push('/high-court');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.find_in_page_outlined,
                  title: 'विधिक मिसाल खोज (Precedent Search)',
                  subtitle: 'उच्चतम न्यायालय एवं हाईकोर्ट नज़ीरें (Kanoon / AIR)',
                  badgeColor: const Color(0xFF1E3A5F),
                  badgeText: 'AIR',
                  onTap: () {
                    Navigator.of(context).pop();
                    ActivityService.logActivity(activityType: 'DRAWER_PRECEDENT_SEARCH_OPENED');
                    context.push('/precedent-search');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.workspace_premium,
                  title: 'अधिवक्ता कोटा एवं सदस्यता',
                  subtitle: 'दैनिक एआई ड्राफ्टिंग कोटा एवं प्रो चैंबर',
                  badgeColor: const Color(0xFFD4AF37),
                  badgeText: 'PRO',
                  onTap: () {
                    Navigator.of(context).pop();
                    ActivityService.logActivity(activityType: 'DRAWER_PAYWALL_OPENED');
                    context.push('/paywall');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.format_list_numbered_rtl,
                  title: 'दैनिक कॉज लिस्ट (e-Courts CIS 3.2)',
                  subtitle: 'आज एवं कल की पेशी सूची, न्यायकक्ष व पुकार स्थिति',
                  badgeColor: const Color(0xFF1F6C3A),
                  badgeText: 'CIS 3.2',
                  onTap: () {
                    Navigator.of(context).pop();
                    ActivityService.logActivity(activityType: 'DRAWER_CAUSE_LIST_OPENED');
                    context.push('/cause-list');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.shield_outlined,
                  title: 'विधिक गोपनीयता एवं DPDP ऑडिट',
                  subtitle: 'अधिवक्ता अधिनियम धारा 126 एवं DPDP सुरक्षा',
                  onTap: () {
                    Navigator.of(context).pop();
                    ActivityService.logActivity(activityType: 'DRAWER_PRIVACY_AUDIT_OPENED');
                    context.push('/chamber-privacy-audit');
                  },
                ),
              ],
            ),
          ),

          // Bottom Logout Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E7FF), width: 1)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Color(0xFFC00000), size: 20),
              ),
              title: const Text(
                'सत्र समाप्त (लॉगआउट)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFC00000)),
              ),
              subtitle: const Text(
                'अधिवक्ता प्रमाणीकरण सुरक्षित लॉगआउट',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF75777E)),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                ActivityService.logActivity(activityType: 'ADVOCATE_SIGNOUT');
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? badgeColor,
    String? badgeText,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEDFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0D1C32), size: 22),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF131B2E),
              ),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF44474D)),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF75777E)),
      onTap: onTap,
    );
  }
}
