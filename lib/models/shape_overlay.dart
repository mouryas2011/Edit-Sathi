import 'package:flutter/material.dart';

enum ShapeType {
  rectangle,
  roundedRect,
  circle,
  arrow,
  star,
  heart,
  callout,
  line,
}

class ShapeOverlayModel {
  final String id;
  final ShapeType type;
  final int color; // ARGB hex value
  final int strokeColor;
  final double strokeWidth;
  final double opacity;
  final double positionX; // Normalized offset from center (-1.0 to 1.0)
  final double positionY; // Normalized offset from center (-1.0 to 1.0)
  final double width;
  final double height;
  final double rotation; // Radians
  final double cornerRadius;
  final Duration startTime;
  final Duration duration;
  final int trackIndex;

  const ShapeOverlayModel({
    required this.id,
    required this.type,
    this.color = 0xFF06B6D4, // Cyan by default
    this.strokeColor = 0xFFFFFFFF,
    this.strokeWidth = 2.0,
    this.opacity = 1.0,
    this.positionX = 0.0,
    this.positionY = 0.0,
    this.width = 100.0,
    this.height = 100.0,
    this.rotation = 0.0,
    this.cornerRadius = 12.0,
    required this.startTime,
    required this.duration,
    this.trackIndex = 0,
  });

  Duration get endTime => startTime + duration;

  Color get displayColor => Color(color).withValues(alpha: opacity);
  Color get displayStrokeColor => Color(strokeColor).withValues(alpha: opacity);

  ShapeOverlayModel copyWith({
    String? id,
    ShapeType? type,
    int? color,
    int? strokeColor,
    double? strokeWidth,
    double? opacity,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    double? rotation,
    double? cornerRadius,
    Duration? startTime,
    Duration? duration,
    int? trackIndex,
  }) {
    return ShapeOverlayModel(
      id: id ?? this.id,
      type: type ?? this.type,
      color: color ?? this.color,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      trackIndex: trackIndex ?? this.trackIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'color': color,
      'strokeColor': strokeColor,
      'strokeWidth': strokeWidth,
      'opacity': opacity,
      'positionX': positionX,
      'positionY': positionY,
      'width': width,
      'height': height,
      'rotation': rotation,
      'cornerRadius': cornerRadius,
      'startTimeMs': startTime.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'trackIndex': trackIndex,
    };
  }

  factory ShapeOverlayModel.fromJson(Map<String, dynamic> json) {
    return ShapeOverlayModel(
      id: json['id'] as String,
      type: ShapeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ShapeType.rectangle,
      ),
      color: json['color'] as int? ?? 0xFF06B6D4,
      strokeColor: json['strokeColor'] as int? ?? 0xFFFFFFFF,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 100.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 12.0,
      startTime: Duration(milliseconds: json['startTimeMs'] as int? ?? 0),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 3000),
      trackIndex: json['trackIndex'] as int? ?? 0,
    );
  }
}
