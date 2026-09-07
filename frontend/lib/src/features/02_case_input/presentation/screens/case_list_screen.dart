import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/stitch_colors.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/storage/courtroom_sync_manager.dart';
import '../../data/case_repository.dart';
import '../controllers/case_controller.dart';
import '../widgets/case_card.dart';
import '../widgets/advocate_drawer.dart';

class CaseListScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNewCasePressed;

  const CaseListScreen({super.key, this.onNewCasePressed});

  @override
  ConsumerState<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends ConsumerState<CaseListScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _selectedFilter = 'date'; // 'date', 'court', 'custody'
  bool _showSearchInput = false;

  @override
  void initState() {
    super.initState();
    AppEnvironment.warmupBackend();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(caseListProvider);
    final isOfflineMode = ref.watch(isOfflineModeProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final pendingCount = ref.watch(pendingQueueCountProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdvocateDrawer(),
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: casesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.signal_cellular_connected_no_internet_4_bar, size: 48, color: Colors.orange),
                  const SizedBox(height: 12),
                  const Text(
                    'कोर्टरूम नेटवर्क अनुपलब्ध',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1C32)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1C32), foregroundColor: Colors.white),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('पुनः प्रयास करें'),
                    onPressed: () => ref.invalidate(caseListProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (cases) {
            final now = DateTime.now();
            final todayHearingsCount = cases.where((c) {
              if (c.nextHearingDate == null) return false;
              final d = c.nextHearingDate!;
              return d.year == now.year && d.month == now.month && d.day == now.day;
            }).length;

            final judicialCustodyCount = cases
                .where((c) => c.accusedCustodyStatus == 'JUDICIAL_CUSTODY')
                .length;

            final totalCases = cases.length;

            ActivityService.logActivity(
              activityType: 'DOCKET_VIEWED',
              details: {
                'total_cases': totalCases,
                'today_hearings': todayHearingsCount,
                'judicial_custody': judicialCustodyCount,
              },
            );

            return Column(
              children: [
                // Top App Header: Court Navy with Action Bar & Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1C32),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.menu_open, color: Color(0xFFD6E3FF)),
                                tooltip: 'चैंबर मेनू',
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                              const SizedBox(width: 4),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'सक्रिय आपराधिक डॉकेट',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFAF8FF),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Text(
                                    'जिला एवं सत्र न्यायालय (District & Sessions Court)',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB9C7E4)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search, color: Color(0xFFD6E3FF)),
                                tooltip: 'केस खोजें',
                                onPressed: () {
                                  setState(() => _showSearchInput = !_showSearchInput);
                                },
                              ),
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFFD6E3FF)),
                                    tooltip: 'दैनिक कॉज लिस्ट (e-Courts CIS 3.2)',
                                    onPressed: () {
                                      ActivityService.logActivity(activityType: 'NOTIFICATION_BELL_CAUSE_LIST_OPENED');
                                      context.push('/cause-list');
                                    },
                                  ),

                                  Positioned(
                                    right: 12,
                                    top: 12,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: StitchColors.alertCrimson,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune, color: Color(0xFFD6E3FF)),
                                tooltip: 'फ़िल्टर एवं सॉर्टिंग',
                                onPressed: () {
                                  setState(() {
                                    if (_selectedFilter == 'date') {
                                      _selectedFilter = 'court';
                                    } else if (_selectedFilter == 'court') {
                                      _selectedFilter = 'custody';
                                    } else {
                                      _selectedFilter = 'date';
                                    }
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('फ़िल्टर बदला गया: ${_selectedFilter == 'date' ? 'तारीख वार' : _selectedFilter == 'court' ? 'न्यायालय वार' : 'जेल अभिरक्षा'}'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_showSearchInput) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => ref.read(caseSearchQueryProvider.notifier).state = val,
                                style: const TextStyle(color: Colors.black, fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: 'मु.अ.सं. या अभियुक्त का नाम खोजें...',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(caseSearchQueryProvider.notifier).state = '';
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                ActivityService.logActivity(activityType: 'HEADER_PRECEDENT_SEARCH_TAPPED');
                                context.push('/precedent-search');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.find_in_page, size: 16, color: Color(0xFF0D1C32)),
                                    SizedBox(width: 4),
                                    Text(
                                      'मिसाल (AIR)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D1C32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Quick Stats Pill Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'कुल सक्रिय वाद',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB9C7E4)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalCases',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA4F1B2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'आज की पेशी',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF24703E)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    todayHearingsCount.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F6C3A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDBD1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'न्यायिक अभिरक्षा',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF842503)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    judicialCustodyCount.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3A0A00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Courtroom Offline Mode Indicator Banner
                if (isOfflineMode || pendingCount > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, size: 20, color: Color(0xFFD97706)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ऑफलाइन कोर्टरूम मोड (Courtroom Offline)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                              ),
                              Text(
                                pendingCount > 0
                                    ? '$pendingCount केस/कार्यवाही सिंक हेतु कतारबद्ध • स्थानीय सुरक्षित'
                                    : 'स्थानीय सुरक्षित केस डायरी सक्रिय • इंटरनेट पर स्वतः सिंक होगा',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: isSyncing
                              ? null
                              : () async {
                                  final count = await ref.read(courtroomSyncManagerProvider).syncPendingOperations(
                                        ref.read(caseRepositoryProvider),
                                      );
                                  ref.invalidate(caseListProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(count > 0 ? '$count केस सफलतापूर्वक सिंक हुए!' : 'कोर्ट डायरी अद्यतन है।'),
                                      ),
                                    );
                                  }
                                },
                          icon: isSyncing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.sync, size: 16, color: Color(0xFFD97706)),
                          label: Text(
                            isSyncing ? 'सिंक...' : 'सिंक करें',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Filter & Sort Quick Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildFilterTab(
                            id: 'date',
                            label: 'तारीख वार',
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterTab(
                            id: 'court',
                            label: 'न्यायालय वार',
                            icon: Icons.gavel,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterTab(
                            id: 'custody',
                            label: 'जेल अभिरक्षा',
                            icon: Icons.lock_outline,
                          ),
                        ],
                      ),
                      Text(
                        '$totalCases परिणाम',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF75777E), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // Case List & Sponsored Banner
                Expanded(
                  child: cases.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'कोई सक्रिय केस नहीं मिला',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: StitchColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'निचले बटन से नया आपराधिक केस जोड़ें।',
                                style: TextStyle(fontSize: 13, color: StitchColors.textMuted),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => ref.invalidate(caseListProvider),
                          child: ListView.builder(
                            itemCount: cases.length,
                            padding: const EdgeInsets.only(bottom: 80.0),
                            itemBuilder: (context, index) {
                              final c = cases[index];
                              return CaseCard(
                                criminalCase: c,
                                onTap: () {
                                  ActivityService.logActivity(
                                    activityType: 'DRAFT_STUDIO_NAVIGATED',
                                    details: {
                                      'case_id': c.id,
                                      'fir_number': c.firNumber,
                                      'district': c.district,
                                    },
                                  );
                                  context.push('/cases/${c.id}/draft-studio');
                                },
                                onArchive: () async {
                                  await ref.read(caseFormControllerProvider.notifier).archiveCase(c.id);
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D1C32),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('+ नया केस दर्ज करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        onPressed: () {
          if (widget.onNewCasePressed != null) {
            widget.onNewCasePressed!();
          } else {
            context.push('/cases/new');
          }
        },
      ),
    );
  }

  Widget _buildFilterTab({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D1C32) : const Color(0xFFEAEDFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF44474D)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF44474D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
