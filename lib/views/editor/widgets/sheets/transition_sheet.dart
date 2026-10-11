import 'package:flutter/material.dart';
import '../../../../models/video_clip.dart';
import '../../../../theme/app_colors.dart';

class TransitionSheet extends StatefulWidget {
  final TransitionType currentTransition;
  final Duration currentDuration;
  final Function(TransitionType, Duration, bool applyToAll) onApply;

  const TransitionSheet({
    super.key,
    required this.currentTransition,
    required this.currentDuration,
    required this.onApply,
  });

  static void show({
    required BuildContext context,
    required TransitionType currentTransition,
    required Duration currentDuration,
    required Function(TransitionType, Duration, bool applyToAll) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransitionSheet(
        currentTransition: currentTransition,
        currentDuration: currentDuration,
        onApply: onApply,
      ),
    );
  }

  @override
  State<TransitionSheet> createState() => _TransitionSheetState();
}

class _TransitionSheetState extends State<TransitionSheet> {
  late TransitionType _selectedTransition;
  late double _durationSeconds;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _selectedTransition = widget.currentTransition;
    _durationSeconds = (widget.currentDuration.inMilliseconds / 1000.0).clamp(0.2, 2.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Transitions (Premiere / CapCut)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Transition Selector Grid
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemCount: TransitionType.values.length,
              itemBuilder: (context, index) {
                final trans = TransitionType.values[index];
                final isSelected = _selectedTransition == trans;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTransition = trans;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : const Color(0xFF1E2433),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          trans.icon,
                          size: 26,
                          color: isSelected ? AppColors.primary : Colors.white70,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          trans.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Duration Slider
          if (_selectedTransition != TransitionType.none) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transition Duration',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22283A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_durationSeconds.toStringAsFixed(1)}s',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                thumbColor: AppColors.primary,
                inactiveTrackColor: Colors.white12,
                trackHeight: 3,
              ),
              child: Slider(
                value: _durationSeconds,
                min: 0.2,
                max: 2.0,
                divisions: 18,
                onChanged: (val) {
                  setState(() {
                    _durationSeconds = val;
                  });
                },
              ),
            ),
          ],

          // Apply to all clips checkbox
          InkWell(
            onTap: () {
              setState(() {
                _applyToAll = !_applyToAll;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  value: _applyToAll,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() {
                      _applyToAll = v ?? false;
                    });
                  },
                ),
                const Text(
                  'Apply to all clips on timeline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final dur = Duration(milliseconds: (_durationSeconds * 1000).round());
                widget.onApply(_selectedTransition, dur, _applyToAll);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Apply Transition',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
