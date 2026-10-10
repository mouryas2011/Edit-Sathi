import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class SpeedSheet extends StatelessWidget {
  final double currentSpeed;
  final Function(double) onSpeedSelected;

  const SpeedSheet({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  static void show({
    required BuildContext context,
    required double currentSpeed,
    required Function(double) onSpeedSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SpeedSheet(
        currentSpeed: currentSpeed,
        onSpeedSelected: onSpeedSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF161924),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clip Playback Speed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: speeds.map((s) {
              final isSelected = (currentSpeed - s).abs() < 0.05;
              return ChoiceChip(
                label: Text('${s}x'),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFF22283A),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) {
                  if (val) {
                    onSpeedSelected(s);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
