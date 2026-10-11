import 'package:flutter/material.dart';
import '../../../../models/video_clip.dart';
import '../../../../theme/app_colors.dart';

class SpeedSheet extends StatefulWidget {
  final double currentSpeed;
  final SpeedCurveType currentCurve;
  final Function(double speed, SpeedCurveType curve) onSpeedSelected;

  const SpeedSheet({
    super.key,
    required this.currentSpeed,
    this.currentCurve = SpeedCurveType.none,
    required this.onSpeedSelected,
  });

  static void show({
    required BuildContext context,
    required double currentSpeed,
    SpeedCurveType currentCurve = SpeedCurveType.none,
    required Function(double speed, SpeedCurveType curve) onSpeedSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SpeedSheet(
        currentSpeed: currentSpeed,
        currentCurve: currentCurve,
        onSpeedSelected: onSpeedSelected,
      ),
    );
  }

  @override
  State<SpeedSheet> createState() => _SpeedSheetState();
}

class _SpeedSheetState extends State<SpeedSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late double _speed;
  late SpeedCurveType _curve;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.currentCurve != SpeedCurveType.none ? 1 : 0,
    );
    _speed = widget.currentSpeed;
    _curve = widget.currentCurve;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
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
                  Icon(Icons.speed_rounded, color: Color(0xFFFBBF24), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Speed Ramping & Curve (CapCut / VN)',
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
          const SizedBox(height: 8),

          // Segmented Tab Bar
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
              tabs: const [
                Tab(text: 'Standard (0.1x - 10x)'),
                Tab(text: 'Curve Presets'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStandardTab(),
                _buildCurveTab(),
              ],
            ),
          ),

          // Bottom Action
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
                if (_tabController.index == 0) {
                  widget.onSpeedSelected(_speed, SpeedCurveType.none);
                } else {
                  widget.onSpeedSelected(_speed, _curve);
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Apply Speed',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardTab() {
    final standardPresets = [0.2, 0.5, 1.0, 1.5, 2.0, 4.0, 8.0];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Live Speed Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2433),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
          ),
          child: Text(
            '${_speed.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFBBF24),
            thumbColor: const Color(0xFFFBBF24),
            inactiveTrackColor: Colors.white12,
            trackHeight: 4,
          ),
          child: Slider(
            value: _speed.clamp(0.1, 10.0),
            min: 0.1,
            max: 10.0,
            divisions: 99,
            onChanged: (val) {
              setState(() {
                _speed = val;
              });
            },
          ),
        ),

        // Presets Wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: standardPresets.map((p) {
            final isSelected = (_speed - p).abs() < 0.05;
            return ChoiceChip(
              label: Text('${p}x'),
              selected: isSelected,
              selectedColor: const Color(0xFFFBBF24),
              backgroundColor: const Color(0xFF1E2433),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _speed = p;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCurveTab() {
    return Column(
      children: [
        // Live Curve Preview Graph
        Container(
          height: 100,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2433),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _SpeedCurveGraphPainter(curveType: _curve),
            ),
          ),
        ),

        // Curve Chips List
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: SpeedCurveType.values.length,
            separatorBuilder: (_, unused) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = SpeedCurveType.values[index];
              final isSelected = _curve == item;

              return InkWell(
                onTap: () {
                  setState(() {
                    _curve = item;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : const Color(0xFF1E2433),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
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
    );
  }
}

class _SpeedCurveGraphPainter extends CustomPainter {
  final SpeedCurveType curveType;

  _SpeedCurveGraphPainter({required this.curveType});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    // Draw horizontal grid center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );

    final path = Path();
    final points = _getCurvePoints(curveType, size);

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    // Curve fill gradient
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFBBF24).withValues(alpha: 0.35),
          const Color(0xFFFBBF24).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Curve stroke
    final strokePaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    // Draw control anchor dots
    final dotPaint = Paint()..color = Colors.white;
    for (final pt in points) {
      canvas.drawCircle(pt, 3.5, dotPaint);
    }
  }

  List<Offset> _getCurvePoints(SpeedCurveType type, Size size) {
    final w = size.width;
    final h = size.height;

    switch (type) {
      case SpeedCurveType.none:
        return [Offset(0, h * 0.5), Offset(w, h * 0.5)];
      case SpeedCurveType.montage:
        return [
          Offset(0, h * 0.8),
          Offset(w * 0.25, h * 0.7),
          Offset(w * 0.5, h * 0.15),
          Offset(w * 0.75, h * 0.65),
          Offset(w, h * 0.8),
        ];
      case SpeedCurveType.hero:
        return [
          Offset(0, h * 0.4),
          Offset(w * 0.3, h * 0.4),
          Offset(w * 0.5, h * 0.85),
          Offset(w * 0.7, h * 0.4),
          Offset(w, h * 0.4),
        ];
      case SpeedCurveType.bulletTime:
        return [
          Offset(0, h * 0.15),
          Offset(w * 0.25, h * 0.25),
          Offset(w * 0.5, h * 0.9),
          Offset(w * 0.75, h * 0.25),
          Offset(w, h * 0.15),
        ];
      case SpeedCurveType.jumpCut:
        return [
          Offset(0, h * 0.2),
          Offset(w * 0.25, h * 0.8),
          Offset(w * 0.5, h * 0.2),
          Offset(w * 0.75, h * 0.8),
          Offset(w, h * 0.2),
        ];
      case SpeedCurveType.flashIn:
        return [
          Offset(0, h * 0.9),
          Offset(w * 0.25, h * 0.1),
          Offset(w * 0.6, h * 0.3),
          Offset(w, h * 0.45),
        ];
      case SpeedCurveType.flashOut:
        return [
          Offset(0, h * 0.1),
          Offset(w * 0.3, h * 0.15),
          Offset(w * 0.7, h * 0.85),
          Offset(w, h * 0.9),
        ];
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedCurveGraphPainter oldDelegate) {
    return oldDelegate.curveType != curveType;
  }
}
