import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/text_overlay.dart';
import '../../../../theme/app_colors.dart';

class TextEditSheet extends StatefulWidget {
  final TextOverlayModel? initialText;
  final Duration currentPosition;
  final Function(TextOverlayModel) onSave;
  final VoidCallback? onDelete;

  const TextEditSheet({
    super.key,
    this.initialText,
    required this.currentPosition,
    required this.onSave,
    this.onDelete,
  });

  static void show({
    required BuildContext context,
    TextOverlayModel? initialText,
    required Duration currentPosition,
    required Function(TextOverlayModel) onSave,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TextEditSheet(
        initialText: initialText,
        currentPosition: currentPosition,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends State<TextEditSheet> {
  late TextEditingController _controller;
  late double _fontSize;
  late int _fontColor;
  late int? _bgColor;
  late TextAnimationType _animation;

  final List<int> _fontColors = [
    0xFFFFFFFF, // White
    0xFFFFE600, // Bright Yellow
    0xFF38BDF8, // Sky Blue
    0xFFF43F5E, // Rose Pink
    0xFF34D399, // Mint Green
    0xFF0F172A, // Black
  ];

  final List<int?> _bgColors = [
    0xCC7C3AED, // Purple pill
    0xCC0F172A, // Dark slate
    0xCCDC2626, // Red
    0xCC059669, // Emerald
    null, // Transparent
  ];

  @override
  void initState() {
    super.initState();
    final text = widget.initialText;
    _controller = TextEditingController(text: text?.text ?? 'A Beautiful Day ✨');
    _fontSize = text?.fontSize ?? 22.0;
    _fontColor = text?.fontColorValue ?? 0xFFFFFFFF;
    _bgColor = text?.backgroundColorValue ?? 0xCC7C3AED;
    _animation = text?.animation ?? TextAnimationType.popIn;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final result = widget.initialText != null
        ? widget.initialText!.copyWith(
            text: text,
            fontSize: _fontSize,
            fontColorValue: _fontColor,
            backgroundColorValue: _bgColor,
            animation: _animation,
          )
        : TextOverlayModel(
            id: const Uuid().v4(),
            text: text,
            startTime: widget.currentPosition,
            duration: const Duration(seconds: 5),
            fontSize: _fontSize,
            fontColorValue: _fontColor,
            backgroundColorValue: _bgColor,
            animation: _animation,
          );

    widget.onSave(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161924),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialText != null ? 'Edit Text' : 'Add Text',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    widget.onDelete?.call();
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Text input
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(
              color: Color(_fontColor),
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _bgColor != null
                  ? Color(_bgColor!)
                  : Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              hintText: 'Type something...',
              hintStyle: const TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),

          // Font size slider
          Row(
            children: [
              const Text(
                'Size',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 14,
                  max: 42,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _fontSize = val),
                ),
              ),
              Text(
                '${_fontSize.round()}px',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),

          // Text Color
          const Text(
            'Text Color',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: _fontColors.map((colorVal) {
              final isSelected = _fontColor == colorVal;
              return GestureDetector(
                onTap: () => setState(() => _fontColor = colorVal),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Color(colorVal),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Background Color
          const Text(
            'Background Pill',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: _bgColors.map((colorVal) {
              final isSelected = _bgColor == colorVal;
              return GestureDetector(
                onTap: () => setState(() => _bgColor = colorVal),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: colorVal != null ? Color(colorVal) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white38,
                      width: 2.5,
                    ),
                  ),
                  child: colorVal == null
                      ? const Center(
                          child: Icon(Icons.block, size: 16, color: Colors.white54),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Animation type
          const Text(
            'Animation',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TextAnimationType.values.map((anim) {
                final isSelected = _animation == anim;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(anim.name),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFF22283A),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _animation = anim);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _save,
              child: const Text(
                'Apply Text',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
