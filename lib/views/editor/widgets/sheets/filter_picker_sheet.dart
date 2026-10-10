import 'package:flutter/material.dart';
import '../../../../models/video_clip.dart';
import '../../../../theme/app_colors.dart';

class FilterPickerSheet extends StatelessWidget {
  final VideoFilterPreset currentFilter;
  final Function(VideoFilterPreset) onFilterSelected;

  const FilterPickerSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterSelected,
  });

  static void show({
    required BuildContext context,
    required VideoFilterPreset currentFilter,
    required Function(VideoFilterPreset) onFilterSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterPickerSheet(
        currentFilter: currentFilter,
        onFilterSelected: onFilterSelected,
      ),
    );
  }

  LinearGradient _getFilterGradient(VideoFilterPreset filter) {
    switch (filter) {
      case VideoFilterPreset.none:
        return const LinearGradient(colors: [Colors.grey, Colors.black45]);
      case VideoFilterPreset.warmSunset:
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEF4444), Color(0xFF7C2D12)],
        );
      case VideoFilterPreset.cinematic:
        return const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0F172A), Color(0xFF334155)],
        );
      case VideoFilterPreset.coolBlue:
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF1E3A8A)],
        );
      case VideoFilterPreset.retroVintage:
        return const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFF78350F), Color(0xFF451A03)],
        );
      case VideoFilterPreset.blackAndWhite:
        return const LinearGradient(
          colors: [Colors.white70, Colors.grey, Colors.black],
        );
      case VideoFilterPreset.vividPop:
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
        );
    }
  }

  String _getFilterName(VideoFilterPreset filter) {
    switch (filter) {
      case VideoFilterPreset.none:
        return 'Original';
      case VideoFilterPreset.warmSunset:
        return 'Warm Sunset';
      case VideoFilterPreset.cinematic:
        return 'Cinematic';
      case VideoFilterPreset.coolBlue:
        return 'Cool Blue';
      case VideoFilterPreset.retroVintage:
        return 'Retro 90s';
      case VideoFilterPreset.blackAndWhite:
        return 'Noir B&W';
      case VideoFilterPreset.vividPop:
        return 'Vivid Pop';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Color Grading & Presets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: VideoFilterPreset.values.length,
              itemBuilder: (context, index) {
                final filter = VideoFilterPreset.values[index];
                final isSelected = currentFilter == filter;

                return GestureDetector(
                  onTap: () {
                    onFilterSelected(filter);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 82,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          height: 82,
                          width: 82,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: _getFilterGradient(filter),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getFilterName(filter),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
