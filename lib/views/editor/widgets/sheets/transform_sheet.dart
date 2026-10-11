import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../models/video_clip.dart';
import '../../../../theme/app_colors.dart';

class TransformSheet extends StatefulWidget {
  final VideoClipModel clip;
  final Function(VideoClipModel updated) onSave;

  const TransformSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required VideoClipModel clip,
    required Function(VideoClipModel updated) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransformSheet(
        clip: clip,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TransformSheet> createState() => _TransformSheetState();
}

class _TransformSheetState extends State<TransformSheet> {
  late double _scale;
  late double _rotationDeg;
  late double _posX;
  late double _posY;
  late bool _flipH;
  late bool _flipV;

  @override
  void initState() {
    super.initState();
    _scale = widget.clip.scale;
    _rotationDeg = (widget.clip.rotation * 180.0 / math.pi) % 360.0;
    if (_rotationDeg > 180.0) _rotationDeg -= 360.0;
    _posX = widget.clip.positionX;
    _posY = widget.clip.positionY;
    _flipH = widget.clip.flipHorizontal;
    _flipV = widget.clip.flipVertical;
  }

  void _applyChanges() {
    final rad = _rotationDeg * math.pi / 180.0;
    final updated = widget.clip.copyWith(
      scale: _scale,
      rotation: rad,
      positionX: _posX,
      positionY: _posY,
      flipHorizontal: _flipH,
      flipVertical: _flipV,
    );
    widget.onSave(updated);
  }

  void _reset() {
    setState(() {
      _scale = 1.0;
      _rotationDeg = 0.0;
      _posX = 0.0;
      _posY = 0.0;
      _flipH = false;
      _flipV = false;
    });
    _applyChanges();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
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
              const Icon(Icons.transform_rounded, color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transform: ${widget.clip.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
                label: const Text('Reset', style: TextStyle(color: Colors.white70, fontSize: 12)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 30),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                // 1. Zoom / Scale Control
                _buildSectionHeader('Scale / Zoom', '${(_scale * 100).round()}%'),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF06B6D4),
                    thumbColor: const Color(0xFF38BDF8),
                  ),
                  child: Slider(
                    value: _scale.clamp(0.2, 3.5),
                    min: 0.2,
                    max: 3.5,
                    divisions: 66,
                    onChanged: (val) {
                      setState(() => _scale = val);
                      _applyChanges();
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PresetButton(
                      label: 'Fit (1.0x)',
                      isSelected: (_scale - 1.0).abs() < 0.05,
                      onTap: () {
                        setState(() => _scale = 1.0);
                        _applyChanges();
                      },
                    ),
                    _PresetButton(
                      label: 'Fill (1.35x)',
                      isSelected: (_scale - 1.35).abs() < 0.05,
                      onTap: () {
                        setState(() => _scale = 1.35);
                        _applyChanges();
                      },
                    ),
                    _PresetButton(
                      label: 'Zoom 2x',
                      isSelected: (_scale - 2.0).abs() < 0.05,
                      onTap: () {
                        setState(() => _scale = 2.0);
                        _applyChanges();
                      },
                    ),
                    _PresetButton(
                      label: 'Mini 0.5x',
                      isSelected: (_scale - 0.5).abs() < 0.05,
                      onTap: () {
                        setState(() => _scale = 0.5);
                        _applyChanges();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Rotation Control
                _buildSectionHeader('Rotation', '${_rotationDeg.round()}°'),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF8B5CF6),
                    thumbColor: const Color(0xFFA78BFA),
                  ),
                  child: Slider(
                    value: _rotationDeg.clamp(-180.0, 180.0),
                    min: -180.0,
                    max: 180.0,
                    divisions: 72,
                    onChanged: (val) {
                      setState(() => _rotationDeg = val);
                      _applyChanges();
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PresetButton(
                      label: '-90°',
                      onTap: () {
                        setState(() => _rotationDeg = (_rotationDeg - 90) % 360);
                        if (_rotationDeg > 180) _rotationDeg -= 360;
                        _applyChanges();
                      },
                    ),
                    _PresetButton(
                      label: '0° Level',
                      isSelected: _rotationDeg.abs() < 1,
                      onTap: () {
                        setState(() => _rotationDeg = 0.0);
                        _applyChanges();
                      },
                    ),
                    _PresetButton(
                      label: '+90°',
                      onTap: () {
                        setState(() => _rotationDeg = (_rotationDeg + 90) % 360);
                        if (_rotationDeg > 180) _rotationDeg -= 360;
                        _applyChanges();
                      },
                    ),
                    _PresetButton(
                      label: '180° Flip',
                      onTap: () {
                        setState(() => _rotationDeg = 180.0);
                        _applyChanges();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Flip & Mirror
                _buildSectionHeader('Flip & Mirror', ''),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _flipH ? const Color(0xFF06B6D4).withValues(alpha: 0.2) : const Color(0xFF1E2436),
                          side: BorderSide(color: _flipH ? const Color(0xFF06B6D4) : Colors.white12),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.flip_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _flipH ? 'Flip Horiz: ON' : 'Flip Horiz: OFF',
                          style: TextStyle(color: _flipH ? const Color(0xFF38BDF8) : Colors.white70, fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() => _flipH = !_flipH);
                          _applyChanges();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _flipV ? const Color(0xFF8B5CF6).withValues(alpha: 0.2) : const Color(0xFF1E2436),
                          side: BorderSide(color: _flipV ? const Color(0xFF8B5CF6) : Colors.white12),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.flip_camera_android_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _flipV ? 'Flip Vert: ON' : 'Flip Vert: OFF',
                          style: TextStyle(color: _flipV ? const Color(0xFFA78BFA) : Colors.white70, fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() => _flipV = !_flipV);
                          _applyChanges();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Position Offset (X / Y)
                _buildSectionHeader('Position Offset', '(${_posX.round()}px, ${_posY.round()}px)'),
                Row(
                  children: [
                    const Text('X: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Expanded(
                      child: Slider(
                        value: _posX.clamp(-300.0, 300.0),
                        min: -300.0,
                        max: 300.0,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          setState(() => _posX = val);
                          _applyChanges();
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Y: ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Expanded(
                      child: Slider(
                        value: _posY.clamp(-300.0, 300.0),
                        min: -300.0,
                        max: 300.0,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          setState(() => _posY = val);
                          _applyChanges();
                        },
                      ),
                    ),
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _posX = 0.0;
                        _posY = 0.0;
                      });
                      _applyChanges();
                    },
                    child: const Text('Center Position (0, 0)', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          // Done Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        if (value.isNotEmpty)
          Text(value, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF1E2436),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white12,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
