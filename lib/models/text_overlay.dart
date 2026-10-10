import 'package:flutter/material.dart';

enum TextAnimationType {
  none,
  fade,
  popIn,
  slideUp,
  typewriter,
}

class TextOverlayModel {
  final String id;
  final String text;
  final Duration startTime;
  final Duration duration;
  final double fontSize;
  final int fontColorValue;
  final int? backgroundColorValue;
  final double positionX; // -1.0 (left) to 1.0 (right)
  final double positionY; // -1.0 (top) to 1.0 (bottom)
  final TextAnimationType animation;

  const TextOverlayModel({
    required this.id,
    required this.text,
    required this.startTime,
    required this.duration,
    this.fontSize = 24.0,
    this.fontColorValue = 0xFFFFFFFF, // White
    this.backgroundColorValue = 0x887C3AED, // Semi-transparent Purple
    this.positionX = 0.0,
    this.positionY = 0.5, // Lower middle third
    this.animation = TextAnimationType.popIn,
  });

  Duration get endTime => startTime + duration;
  Color get fontColor => Color(fontColorValue);
  Color? get backgroundColor =>
      backgroundColorValue != null ? Color(backgroundColorValue!) : null;

  TextOverlayModel copyWith({
    String? id,
    String? text,
    Duration? startTime,
    Duration? duration,
    double? fontSize,
    int? fontColorValue,
    int? backgroundColorValue,
    double? positionX,
    double? positionY,
    TextAnimationType? animation,
  }) {
    return TextOverlayModel(
      id: id ?? this.id,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      fontSize: fontSize ?? this.fontSize,
      fontColorValue: fontColorValue ?? this.fontColorValue,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      animation: animation ?? this.animation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'startTimeMs': startTime.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'fontSize': fontSize,
      'fontColorValue': fontColorValue,
      'backgroundColorValue': backgroundColorValue,
      'positionX': positionX,
      'positionY': positionY,
      'animation': animation.name,
    };
  }

  factory TextOverlayModel.fromJson(Map<String, dynamic> json) {
    return TextOverlayModel(
      id: json['id'] as String,
      text: json['text'] as String,
      startTime: Duration(milliseconds: json['startTimeMs'] as int),
      duration: Duration(milliseconds: json['durationMs'] as int),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      fontColorValue: json['fontColorValue'] as int? ?? 0xFFFFFFFF,
      backgroundColorValue: json['backgroundColorValue'] as int?,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.5,
      animation: TextAnimationType.values.firstWhere(
        (e) => e.name == json['animation'],
        orElse: () => TextAnimationType.none,
      ),
    );
  }
}
