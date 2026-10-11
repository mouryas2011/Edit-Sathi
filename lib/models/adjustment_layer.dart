import 'package:flutter/material.dart';
import 'video_clip.dart';

class AdjustmentLayerModel {
  final String id;
  final String title;
  final Duration startTime;
  final Duration duration;
  final int trackIndex; // Track level (affects all tracks below this index)
  final VideoFilterPreset filter;
  final double brightness; // -0.5 to 0.5 (0 = normal)
  final double contrast; // 0.5 to 2.0 (1.0 = normal)
  final double saturation; // 0.0 to 2.0 (1.0 = normal)
  final double opacity; // 0.0 to 1.0 (1.0 = 100% effect)
  final int? tintColor; // Optional color tint overlay (ARGB)

  const AdjustmentLayerModel({
    required this.id,
    this.title = 'Adjustment Layer',
    required this.startTime,
    required this.duration,
    this.trackIndex = 1,
    this.filter = VideoFilterPreset.cinematic,
    this.brightness = 0.0,
    this.contrast = 1.1,
    this.saturation = 1.15,
    this.opacity = 1.0,
    this.tintColor,
  });

  Duration get endTime => startTime + duration;

  ColorFilter? buildColorFilter() {
    // Generate combined 5x4 color matrix for brightness, contrast, and preset
    final b = brightness * 255.0;
    final c = contrast;
    final s = saturation;

    // Luminance coefficients for saturation
    const rw = 0.2126;
    const gw = 0.7152;
    const bw = 0.0722;

    final sr = (1 - s) * rw;
    final sg = (1 - s) * gw;
    final sb = (1 - s) * bw;

    // Matrix with combined contrast, saturation, and brightness offset
    return ColorFilter.matrix(<double>[
      (sr + s) * c, sg * c, sb * c, 0, b,
      sr * c, (sg + s) * c, sb * c, 0, b,
      sr * c, sg * c, (sb + s) * c, 0, b,
      0, 0, 0, opacity, 0,
    ]);
  }

  AdjustmentLayerModel copyWith({
    String? id,
    String? title,
    Duration? startTime,
    Duration? duration,
    int? trackIndex,
    VideoFilterPreset? filter,
    double? brightness,
    double? contrast,
    double? saturation,
    double? opacity,
    int? tintColor,
  }) {
    return AdjustmentLayerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      trackIndex: trackIndex ?? this.trackIndex,
      filter: filter ?? this.filter,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      opacity: opacity ?? this.opacity,
      tintColor: tintColor ?? this.tintColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTimeMs': startTime.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'trackIndex': trackIndex,
      'filter': filter.name,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'opacity': opacity,
      'tintColor': tintColor,
    };
  }

  factory AdjustmentLayerModel.fromJson(Map<String, dynamic> json) {
    return AdjustmentLayerModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Adjustment Layer',
      startTime: Duration(milliseconds: json['startTimeMs'] as int? ?? 0),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 5000),
      trackIndex: json['trackIndex'] as int? ?? 1,
      filter: VideoFilterPreset.values.firstWhere(
        (e) => e.name == json['filter'],
        orElse: () => VideoFilterPreset.cinematic,
      ),
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.1,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.15,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      tintColor: json['tintColor'] as int?,
    );
  }
}
