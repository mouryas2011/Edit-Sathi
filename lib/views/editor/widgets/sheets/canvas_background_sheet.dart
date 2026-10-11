import 'package:flutter/material.dart';
import '../../../../models/project.dart';
import '../../../../theme/app_colors.dart';

class CanvasBackgroundSheet extends StatefulWidget {
  final CanvasBgType currentBgType;
  final int currentColorValue;
  final int currentGradientIndex;
  final double currentBlurSigma;
  final Function({
    required CanvasBgType bgType,
    int? colorValue,
    int? gradientIndex,
    double? blurSigma,
  }) onSave;

  const CanvasBackgroundSheet({
    super.key,
    required this.currentBgType,
    required this.currentColorValue,
    required this.currentGradientIndex,
    required this.currentBlurSigma,
    required this.onSave,
  });

  static void show({
    required BuildContext context,
    required ProjectModel project,
    required Function({
      required CanvasBgType bgType,
      int? colorValue,
      int? gradientIndex,
      double? blurSigma,
    }) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CanvasBackgroundSheet(
        currentBgType: project.canvasBgType,
        currentColorValue: project.canvasColorValue,
        currentGradientIndex: project.canvasGradientIndex,
        currentBlurSigma: project.canvasBlurSigma,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CanvasBackgroundSheet> createState() => _CanvasBackgroundSheetState();
}

class _CanvasBackgroundSheetState extends State<CanvasBackgroundSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CanvasBgType _bgType;
  late int _colorValue;
  late int _gradientIndex;
  late double _blurSigma;

  static const List<int> _colorPalette = [
    0xFF000000, // Black
    0xFF0F172A, // Slate dark
    0xFF1E293B, // Charcoal
    0xFF1E1B4B, // Dark Indigo
    0xFF31103F, // Dark Purple
    0xFF064E3B, // Deep Emerald
    0xFF7F1D1D, // Deep Crimson
    0xFF3B82F6, // Blue
    0xFFFFFFFF, // Pure White
  ];

  static const List<List<Color>> _gradientPresets = [
    [Color(0xFF0F172A), Color(0xFF1E293B)],
    [Color(0xFF31103F), Color(0xFF701A75)],
    [Color(0xFF1E1B4B), Color(0xFF3B82F6)],
    [Color(0xFF064E3B), Color(0xFF10B981)],
    [Color(0xFF7F1D1D), Color(0xFFF97316)],
    [Color(0xFF111827), Color(0xFF6366F1)],
  ];

  @override
  void initState() {
    super.initState();
    _bgType = widget.currentBgType;
    _colorValue = widget.currentColorValue;
    _gradientIndex = widget.currentGradientIndex;
    _blurSigma = widget.currentBlurSigma;

    int initialIndex = 0;
    if (_bgType == CanvasBgType.color) initialIndex = 1;
    if (_bgType == CanvasBgType.gradient) initialIndex = 2;

    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.52,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_rounded, color: Color(0xFFA855F7), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Canvas Background (CapCut / VN)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
          const SizedBox(height: 10),

          // Tabs
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2433),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              onTap: (idx) {
                setState(() {
                  if (idx == 0) _bgType = CanvasBgType.blur;
                  if (idx == 1) _bgType = CanvasBgType.color;
                  if (idx == 2) _bgType = CanvasBgType.gradient;
                });
              },
              tabs: const [
                Tab(text: 'Blur Fill'),
                Tab(text: 'Solid Color'),
                Tab(text: 'Gradient'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBlurTab(),
                _buildColorTab(),
                _buildGradientTab(),
              ],
            ),
          ),

          // Save Button
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
                widget.onSave(
                  bgType: _bgType,
                  colorValue: _colorValue,
                  gradientIndex: _gradientIndex,
                  blurSigma: _blurSigma,
                );
                Navigator.of(context).pop();
              },
              child: const Text(
                'Apply Background',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurTab() {
    final blurLevels = [
      {'label': 'Soft', 'sigma': 8.0},
      {'label': 'Medium', 'sigma': 16.0},
      {'label': 'Heavy', 'sigma': 28.0},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Fills canvas margins with a soft blurred copy of the video',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: blurLevels.map((b) {
            final sigma = b['sigma'] as double;
            final isSelected = (_blurSigma - sigma).abs() < 1.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(b['label'] as String),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFF1E2433),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _blurSigma = sigma;
                      _bgType = CanvasBgType.blur;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorTab() {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _colorPalette.map((c) {
          final isSelected = _colorValue == c;

          return InkWell(
            onTap: () {
              setState(() {
                _colorValue = c;
                _bgType = CanvasBgType.color;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white24,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: c == 0xFFFFFFFF ? Colors.black : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGradientTab() {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(_gradientPresets.length, (idx) {
          final isSelected = _gradientIndex == idx;
          final grad = _gradientPresets[idx];

          return InkWell(
            onTap: () {
              setState(() {
                _gradientIndex = idx;
                _bgType = CanvasBgType.gradient;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white24,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 22),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
