import 'package:flutter/material.dart';
import '../../core/theme/stitch_colors.dart';

enum StatuteSystem { hybrid, bnsBnss, ipcCrpc }

class StatuteSelectorBar extends StatelessWidget {
  final StatuteSystem selectedSystem;
  final ValueChanged<StatuteSystem> onSystemChanged;

  const StatuteSelectorBar({
    super.key,
    required this.selectedSystem,
    required this.onSystemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: StitchColors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildOption(
            title: 'हाइब्रिड (दोनों)',
            system: StatuteSystem.hybrid,
            isSelected: selectedSystem == StatuteSystem.hybrid,
          ),
          _buildOption(
            title: 'BNS / BNSS',
            system: StatuteSystem.bnsBnss,
            isSelected: selectedSystem == StatuteSystem.bnsBnss,
          ),
          _buildOption(
            title: 'IPC / CrPC',
            system: StatuteSystem.ipcCrpc,
            isSelected: selectedSystem == StatuteSystem.ipcCrpc,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required StatuteSystem system,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onSystemChanged(system),
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? StitchColors.courtNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : StitchColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
