import 'package:flutter/material.dart';
import '../../../../models/shape_overlay.dart';

class ShapePickerSheet extends StatefulWidget {
  final Duration currentPosition;
  final Function(ShapeOverlayModel shape) onShapeSelected;

  const ShapePickerSheet({
    super.key,
    required this.currentPosition,
    required this.onShapeSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required Duration currentPosition,
    required Function(ShapeOverlayModel shape) onShapeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShapePickerSheet(
        currentPosition: currentPosition,
        onShapeSelected: onShapeSelected,
      ),
    );
  }

  @override
  State<ShapePickerSheet> createState() => _ShapePickerSheetState();
}

class _ShapePickerSheetState extends State<ShapePickerSheet> {
  ShapeType _selectedType = ShapeType.roundedRect;
  int _selectedColor = 0xFF06B6D4; // Cyan
  final int _selectedStrokeColor = 0xFFFFFFFF; // White
  double _strokeWidth = 2.0;
  double _opacity = 0.9;
  final double _cornerRadius = 14.0;
  Duration _duration = const Duration(seconds: 4);

  final List<int> _palette = const [
    0xFF06B6D4, // Neon Cyan
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink / Magenta
    0xFF10B981, // Emerald Green
    0xFFF59E0B, // Amber Gold
    0xFFEF4444, // Bright Red
    0xFF3B82F6, // Vibrant Blue
    0xFFFFFFFF, // Pure White
    0xFF1E293B, // Slate Dark
    0xFFFF6B6B, // Coral
    0xFFFFD93D, // Bright Yellow
  ];

  Widget _buildShapeIcon(ShapeType type, {double size = 32, Color color = Colors.white}) {
    switch (type) {
      case ShapeType.rectangle:
        return Icon(Icons.crop_square_rounded, size: size, color: color);
      case ShapeType.roundedRect:
        return Icon(Icons.rectangle_rounded, size: size, color: color);
      case ShapeType.circle:
        return Icon(Icons.circle_outlined, size: size, color: color);
      case ShapeType.arrow:
        return Icon(Icons.arrow_forward_rounded, size: size, color: color);
      case ShapeType.star:
        return Icon(Icons.star_rounded, size: size, color: color);
      case ShapeType.heart:
        return Icon(Icons.favorite_rounded, size: size, color: color);
      case ShapeType.callout:
        return Icon(Icons.chat_bubble_rounded, size: size, color: color);
      case ShapeType.line:
        return Icon(Icons.horizontal_rule_rounded, size: size, color: color);
    }
  }

  String _getShapeName(ShapeType type) {
    switch (type) {
      case ShapeType.rectangle:
        return 'Rectangle';
      case ShapeType.roundedRect:
        return 'Rounded Box';
      case ShapeType.circle:
        return 'Circle';
      case ShapeType.arrow:
        return 'Arrow';
      case ShapeType.star:
        return 'Star Badge';
      case ShapeType.heart:
        return 'Heart';
      case ShapeType.callout:
        return 'Callout Bubble';
      case ShapeType.line:
        return 'Divider Line';
    }
  }

  void _createAndAddShape() {
    final shape = ShapeOverlayModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      color: _selectedColor,
      strokeColor: _selectedStrokeColor,
      strokeWidth: _strokeWidth,
      opacity: _opacity,
      cornerRadius: _cornerRadius,
      width: _selectedType == ShapeType.line ? 180.0 : 110.0,
      height: _selectedType == ShapeType.line ? 12.0 : 110.0,
      startTime: widget.currentPosition,
      duration: _duration,
    );

    widget.onShapeSelected(shape);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF141724),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Drag Handle
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

          // Title
          const Row(
            children: [
              Icon(Icons.category_rounded, color: Color(0xFF06B6D4), size: 22),
              SizedBox(width: 8),
              Text(
                'Add Graphic & Geometric Shape',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Shape Type Grid
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ShapeType.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final type = ShapeType.values[i];
                final isSelected = _selectedType == type;

                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF06B6D4).withValues(alpha: 0.18) : const Color(0xFF1E2436),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF06B6D4) : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildShapeIcon(
                          type,
                          size: 26,
                          color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getShapeName(type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Color Palette
          const Text('Fill Color', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _palette.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final c = _palette[i];
                final isSelected = _selectedColor == c;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.black26,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(c).withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Opacity & Border Sliders
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Opacity (${(_opacity * 100).round()}%)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Slider(
                      value: _opacity,
                      min: 0.1,
                      max: 1.0,
                      activeColor: const Color(0xFF06B6D4),
                      onChanged: (v) => setState(() => _opacity = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Border (${_strokeWidth.round()}px)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Slider(
                      value: _strokeWidth,
                      min: 0.0,
                      max: 10.0,
                      activeColor: const Color(0xFF8B5CF6),
                      onChanged: (v) => setState(() => _strokeWidth = v),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Duration Selector
          Row(
            children: [
              const Text('Duration: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 6),
              ...[2, 4, 6, 10].map((s) {
                final isSel = _duration.inSeconds == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _duration = Duration(seconds: s)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF06B6D4) : const Color(0xFF1E2436),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${s}s',
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),

          const Spacer(),

          // Add Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Add ${_getShapeName(_selectedType)} to Video',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _createAndAddShape,
            ),
          ),
        ],
      ),
    );
  }
}
