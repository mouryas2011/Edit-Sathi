import 'package:flutter/material.dart';
import '../../../../models/adjustment_layer.dart';
import '../../../../models/video_clip.dart';

class AdjustmentLayerSheet extends StatefulWidget {
  final AdjustmentLayerModel? initialLayer;
  final Duration currentPosition;
  final Duration totalProjectDuration;
  final Function(AdjustmentLayerModel layer) onSave;
  final VoidCallback? onDelete;

  const AdjustmentLayerSheet({
    super.key,
    this.initialLayer,
    required this.currentPosition,
    required this.totalProjectDuration,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    AdjustmentLayerModel? initialLayer,
    required Duration currentPosition,
    required Duration totalProjectDuration,
    required Function(AdjustmentLayerModel layer) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdjustmentLayerSheet(
        initialLayer: initialLayer,
        currentPosition: currentPosition,
        totalProjectDuration: totalProjectDuration,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<AdjustmentLayerSheet> createState() => _AdjustmentLayerSheetState();
}

class _AdjustmentLayerSheetState extends State<AdjustmentLayerSheet> {
  late String _title;
  late VideoFilterPreset _filter;
  late double _brightness;
  late double _contrast;
  late double _saturation;
  late double _opacity;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    final layer = widget.initialLayer;
    _title = layer?.title ?? 'Cinematic Grade';
    _filter = layer?.filter ?? VideoFilterPreset.cinematic;
    _brightness = layer?.brightness ?? 0.05;
    _contrast = layer?.contrast ?? 1.15;
    _saturation = layer?.saturation ?? 1.2;
    _opacity = layer?.opacity ?? 1.0;
    _duration = layer?.duration ?? const Duration(seconds: 8);
  }

  void _save() {
    final layer = AdjustmentLayerModel(
      id: widget.initialLayer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title,
      startTime: widget.initialLayer?.startTime ?? widget.currentPosition,
      duration: _duration,
      filter: _filter,
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      opacity: _opacity,
    );
    widget.onSave(layer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialLayer != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF141724),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Edit Adjustment Layer' : 'Add Adjustment Layer (Effect)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isEditing && widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDelete!();
                  },
                ),
            ],
          ),

          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              children: [
                // Preset Filter Cards
                const Text('Effect / LUT Preset', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: VideoFilterPreset.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final p = VideoFilterPreset.values[i];
                      final isSel = _filter == p;
                      final name = p.name[0].toUpperCase() + p.name.substring(1);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _filter = p;
                            _title = '$name Grade';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFF59E0B) : const Color(0xFF1E2436),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isSel ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // Brightness
                _buildSliderRow(
                  label: 'Brightness',
                  valueStr: '${(_brightness * 100).round()}%',
                  value: _brightness,
                  min: -0.4,
                  max: 0.4,
                  color: const Color(0xFFFBBF24),
                  onChanged: (v) => setState(() => _brightness = v),
                ),

                // Contrast
                _buildSliderRow(
                  label: 'Contrast',
                  valueStr: '${(_contrast * 100).round()}%',
                  value: _contrast,
                  min: 0.5,
                  max: 1.8,
                  color: const Color(0xFF06B6D4),
                  onChanged: (v) => setState(() => _contrast = v),
                ),

                // Saturation
                _buildSliderRow(
                  label: 'Saturation',
                  valueStr: '${(_saturation * 100).round()}%',
                  value: _saturation,
                  min: 0.0,
                  max: 2.0,
                  color: const Color(0xFFEC4899),
                  onChanged: (v) => setState(() => _saturation = v),
                ),

                // Layer Opacity / Intensity
                _buildSliderRow(
                  label: 'Effect Opacity / Mix',
                  valueStr: '${(_opacity * 100).round()}%',
                  value: _opacity,
                  min: 0.1,
                  max: 1.0,
                  color: const Color(0xFF8B5CF6),
                  onChanged: (v) => setState(() => _opacity = v),
                ),

                const SizedBox(height: 14),

                // Duration Options
                const Text('Duration on Timeline', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...[5, 10, 15].map((sec) {
                      final isSel = _duration.inSeconds == sec;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _duration = Duration(seconds: sec)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFF59E0B) : const Color(0xFF1E2436),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${sec}s',
                              style: TextStyle(
                                color: isSel ? Colors.black : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () => setState(() => _duration = widget.totalProjectDuration),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _duration == widget.totalProjectDuration ? const Color(0xFFF59E0B) : const Color(0xFF1E2436),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Full Video',
                          style: TextStyle(
                            color: _duration == widget.totalProjectDuration ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(
                isEditing ? 'Save Changes' : 'Apply Adjustment Layer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueStr,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(valueStr, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
