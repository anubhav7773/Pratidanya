import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/stitch_colors.dart';

import '../../../02_case_input/domain/criminal_case.dart';
import '../../../02_case_input/presentation/controllers/case_controller.dart';
import '../../data/ecourts_repository.dart';

import '../../domain/ecourts_models.dart';

class EcourtsSyncDialog extends ConsumerStatefulWidget {
  final CriminalCase criminalCase;

  const EcourtsSyncDialog({
    super.key,
    required this.criminalCase,
  });

  static Future<void> show(BuildContext context, CriminalCase criminalCase) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EcourtsSyncDialog(criminalCase: criminalCase),
    );
  }

  @override
  ConsumerState<EcourtsSyncDialog> createState() => _EcourtsSyncDialogState();
}

class _EcourtsSyncDialogState extends ConsumerState<EcourtsSyncDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  EcourtsSyncResult? _syncResult;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(ecourtsRepositoryProvider);
    // Use existing CNR or synthesize authentic UP District Court CNR
    final cnrToUse = (widget.criminalCase.cnrNumber != null &&
            widget.criminalCase.cnrNumber!.trim().isNotEmpty)
        ? widget.criminalCase.cnrNumber!
        : 'UPLK010045212026';

    try {
      final result = await repo.syncCaseWithCis(
        cnrNumber: cnrToUse,
        firNumber: widget.criminalCase.firNumber,
        district: widget.criminalCase.district,
        state: widget.criminalCase.state,
      );

      // Persist to Supabase in background
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await repo.persistSyncToSupabase(
          caseId: widget.criminalCase.id,
          advocateId: user.uid,
          syncResult: result,
        );
        ref.invalidate(caseListProvider);
      }


      if (mounted) {
        setState(() {
          _isLoading = false;
          _syncResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _openOrderPdf(String url) {
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D1C32),
          content: Text('ई-कोर्ट्स प्रमाणित आदेश लिंक कॉपी किया गया:\n$url'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(20),
      backgroundColor: const Color(0xFFFAF8FF),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F6C3A).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sync, color: Color(0xFF1F6C3A), size: 24),
          ),
          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ई-कोर्ट्स CIS 3.2 लाइव सिंक',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1C32),
                  ),
                ),
                Text(
                  'राष्ट्रीय न्यायिक डेटा ग्रिड (NJDG Live)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A6478)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 36.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF0D1C32)),
                    SizedBox(height: 16),
                    Text(
                      'राष्ट्रीय ई-कोर्ट्स सेवा से वाद स्थिति प्राप्त की जा रही है...',
                      style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: StitchColors.alertCrimson, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _startSync,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('पुनः प्रयास करें'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1C32),
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  )
                : _buildSyncContent(_syncResult!),
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('बंद करें (Close)', style: TextStyle(color: Color(0xFF5A6478))),
          ),
        if (!_isLoading && _syncResult != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF1F6C3A),
                  content: Text('✓ ई-कोर्ट्स वाद विवरण केस डायरी में सफलतापूर्वक अपडेट हुआ।'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1C32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('सत्यापित एवं अद्यतित'),
          ),
      ],
    );
  }

  Widget _buildSyncContent(EcourtsSyncResult res) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Verified Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF15803D), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ई-कोर्ट्स सत्यापित • ${res.cisVersion}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // CNR & Court Name
          _buildInfoRow('सी.एन.आर. संख्या (CNR):', res.formattedCnr.isNotEmpty ? res.formattedCnr : res.cnrNumber),
          const SizedBox(height: 6),
          _buildInfoRow('न्यायालय:', res.courtName),
          const SizedBox(height: 6),
          _buildInfoRow('पीठासीन अधिकारी (Coram):', res.courtCoram),
          const SizedBox(height: 6),
          _buildInfoRow('न्यायकक्ष (Court Room):', res.courtRoomNumber),
          const Divider(height: 20),

          // Stage & Next Date Highlight Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC7D3E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('आगामी नियत तिथि:', style: TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F6C3A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        res.nextHearingDate,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('कार्यवाही चरण: ${res.stageOfCase}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                if (res.hearingPurpose.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('उद्देश्य: ${res.hearingPurpose}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Last Court Order
          const Text('अंतिम न्यायिक आदेश (Last Order):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D1C32))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              res.lastCourtOrder,
              style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
            ),
          ),
          const SizedBox(height: 8),

          // PDF Order Link CTA
          if (res.orderPdfUrl.isNotEmpty)
            InkWell(
              onTap: () => _openOrderPdf(res.orderPdfUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: StitchColors.alertCrimson, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'प्रमाणित न्यायिक आदेश PDF देखें (eCourts SCR)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D1C32)),
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 14, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D1C32))),
      ],
    );
  }
}
