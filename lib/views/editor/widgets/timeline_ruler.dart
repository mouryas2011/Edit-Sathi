import 'package:flutter/material.dart';

class TimelineRuler extends StatelessWidget {
  final Duration totalDuration;
  final double pixelsPerSecond;

  const TimelineRuler({
    super.key,
    required this.totalDuration,
    required this.pixelsPerSecond,
  });

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = (totalDuration.inMilliseconds / 1000).ceil() + 2;
    final totalWidth = totalSeconds * pixelsPerSecond;

    return SizedBox(
      height: 26,
      width: totalWidth,
      child: CustomPaint(
        painter: _TimelineRulerPainter(
          totalSeconds: totalSeconds,
          pixelsPerSecond: pixelsPerSecond,
          formatTime: _formatTime,
        ),
      ),
    );
  }
}

class _TimelineRulerPainter extends CustomPainter {
  final int totalSeconds;
  final double pixelsPerSecond;
  final String Function(int) formatTime;

  _TimelineRulerPainter({
    required this.totalSeconds,
    required this.pixelsPerSecond,
    required this.formatTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.0;

    final subLinePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;

    const textStyle = TextStyle(
      color: Colors.white54,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int sec = 0; sec <= totalSeconds; sec++) {
      final x = sec * pixelsPerSecond;

      // Draw tick
      if (sec % 5 == 0) {
        canvas.drawLine(
          Offset(x, size.height - 8),
          Offset(x, size.height),
          linePaint,
        );

        // Text label (00:00, 00:05, 00:10...)
        textPainter.text = TextSpan(
          text: formatTime(sec),
          style: textStyle,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - (textPainter.width / 2), size.height - 22),
        );
      } else {
        canvas.drawLine(
          Offset(x, size.height - 4),
          Offset(x, size.height),
          subLinePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineRulerPainter oldDelegate) {
    return oldDelegate.totalSeconds != totalSeconds ||
        oldDelegate.pixelsPerSecond != pixelsPerSecond;
  }
}
