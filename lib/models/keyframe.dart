class KeyframeModel {
  final String id;
  final Duration timeOffset; // Relative to clip's startTime
  final double? scale;
  final double? rotation; // in degrees
  final double? positionX; // normalized offset -1.0 to 1.0
  final double? positionY; // normalized offset -1.0 to 1.0
  final double? opacity; // 0.0 to 1.0

  const KeyframeModel({
    required this.id,
    required this.timeOffset,
    this.scale,
    this.rotation,
    this.positionX,
    this.positionY,
    this.opacity,
  });

  KeyframeModel copyWith({
    String? id,
    Duration? timeOffset,
    double? scale,
    double? rotation,
    double? positionX,
    double? positionY,
    double? opacity,
  }) {
    return KeyframeModel(
      id: id ?? this.id,
      timeOffset: timeOffset ?? this.timeOffset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeOffsetMs': timeOffset.inMilliseconds,
      'scale': scale,
      'rotation': rotation,
      'positionX': positionX,
      'positionY': positionY,
      'opacity': opacity,
    };
  }

  factory KeyframeModel.fromJson(Map<String, dynamic> json) {
    return KeyframeModel(
      id: json['id'] as String,
      timeOffset: Duration(milliseconds: json['timeOffsetMs'] as int? ?? 0),
      scale: (json['scale'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble(),
      positionX: (json['positionX'] as num?)?.toDouble(),
      positionY: (json['positionY'] as num?)?.toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble(),
    );
  }

  /// Calculates interpolated transform values at a given time offset relative to the clip
  static KeyframeTransform interpolate({
    required List<KeyframeModel> keyframes,
    required Duration offset,
    required double baseScale,
    required double baseRotation,
    required double basePositionX,
    required double basePositionY,
    double baseOpacity = 1.0,
  }) {
    if (keyframes.isEmpty) {
      return KeyframeTransform(
        scale: baseScale,
        rotation: baseRotation,
        positionX: basePositionX,
        positionY: basePositionY,
        opacity: baseOpacity,
      );
    }

    final sorted = List<KeyframeModel>.from(keyframes)
      ..sort((a, b) => a.timeOffset.compareTo(b.timeOffset));

    if (offset <= sorted.first.timeOffset) {
      final k = sorted.first;
      return KeyframeTransform(
        scale: k.scale ?? baseScale,
        rotation: k.rotation ?? baseRotation,
        positionX: k.positionX ?? basePositionX,
        positionY: k.positionY ?? basePositionY,
        opacity: k.opacity ?? baseOpacity,
      );
    }

    if (offset >= sorted.last.timeOffset) {
      final k = sorted.last;
      return KeyframeTransform(
        scale: k.scale ?? baseScale,
        rotation: k.rotation ?? baseRotation,
        positionX: k.positionX ?? basePositionX,
        positionY: k.positionY ?? basePositionY,
        opacity: k.opacity ?? baseOpacity,
      );
    }

    // Find the adjacent keyframe bracket
    for (int i = 0; i < sorted.length - 1; i++) {
      final prev = sorted[i];
      final next = sorted[i + 1];
      if (offset >= prev.timeOffset && offset <= next.timeOffset) {
        final totalSpan = (next.timeOffset - prev.timeOffset).inMicroseconds;
        if (totalSpan <= 0) {
          return KeyframeTransform(
            scale: next.scale ?? baseScale,
            rotation: next.rotation ?? baseRotation,
            positionX: next.positionX ?? basePositionX,
            positionY: next.positionY ?? basePositionY,
            opacity: next.opacity ?? baseOpacity,
          );
        }
        final progress = (offset - prev.timeOffset).inMicroseconds / totalSpan;
        final t = progress.clamp(0.0, 1.0);

        final pScale = prev.scale ?? baseScale;
        final nScale = next.scale ?? baseScale;

        final pRot = prev.rotation ?? baseRotation;
        final nRot = next.rotation ?? baseRotation;

        final pX = prev.positionX ?? basePositionX;
        final nX = next.positionX ?? basePositionX;

        final pY = prev.positionY ?? basePositionY;
        final nY = next.positionY ?? basePositionY;

        final pOp = prev.opacity ?? baseOpacity;
        final nOp = next.opacity ?? baseOpacity;

        return KeyframeTransform(
          scale: pScale + (nScale - pScale) * t,
          rotation: pRot + (nRot - pRot) * t,
          positionX: pX + (nX - pX) * t,
          positionY: pY + (nY - pY) * t,
          opacity: pOp + (nOp - pOp) * t,
        );
      }
    }

    return KeyframeTransform(
      scale: baseScale,
      rotation: baseRotation,
      positionX: basePositionX,
      positionY: basePositionY,
      opacity: baseOpacity,
    );
  }
}

class KeyframeTransform {
  final double scale;
  final double rotation;
  final double positionX;
  final double positionY;
  final double opacity;

  const KeyframeTransform({
    required this.scale,
    required this.rotation,
    required this.positionX,
    required this.positionY,
    required this.opacity,
  });
}
