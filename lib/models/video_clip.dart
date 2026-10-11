import 'package:flutter/material.dart';
import 'keyframe.dart';

enum VideoFilterPreset {
  none,
  cinematic,
  warmSunset,
  coolBlue,
  retroVintage,
  blackAndWhite,
  vividPop,
}

enum TransitionType {
  none('None', Icons.block),
  crossFade('Cross Dissolve', Icons.auto_awesome),
  dipToBlack('Dip to Black', Icons.dark_mode_rounded),
  fadeToBlack('Fade to Black', Icons.dark_mode_rounded),
  dipToWhite('Dip to White', Icons.light_mode_rounded),
  wipeLeft('Wipe Left', Icons.swipe_left_rounded),
  wipeRight('Wipe Right', Icons.swipe_right_rounded),
  slideLeft('Slide Left', Icons.arrow_back_rounded),
  slideRight('Slide Right', Icons.arrow_forward_rounded),
  zoomIn('Zoom In', Icons.zoom_in_rounded),
  zoomOut('Zoom Out', Icons.zoom_out_rounded),
  glitch('Glitch Flash', Icons.flash_on_rounded);

  final String label;
  final IconData icon;
  const TransitionType(this.label, this.icon);
}

enum SpeedCurveType {
  none('Linear', 'Constant playback speed'),
  montage('Montage', 'Slow intro, high-speed burst, slow finish'),
  hero('Hero Moment', 'Standard speed with dramatic slow-mo center'),
  bulletTime('Bullet Time', 'Fast entry, ultra slow center, fast exit'),
  jumpCut('Jump Cut', 'Alternating high speed burst rhythm'),
  flashIn('Flash In', 'Rapid acceleration from stop to high speed'),
  flashOut('Flash Out', 'High speed burst settling into smooth slow-mo');

  final String label;
  final String description;
  const SpeedCurveType(this.label, this.description);
}

class VideoClipModel {
  final String id;
  final String sourcePath;
  final bool isAsset;
  final String title;
  final Duration startTime; // Position on timeline
  final Duration duration; // Display duration (affected by trims and speed)
  final Duration sourceDuration; // Full un-trimmed duration of raw media
  final Duration trimStart; // Offset from beginning of raw file
  final Duration trimEnd; // Offset from end of raw file
  final double speed; // 0.1x - 10.0x
  final SpeedCurveType speedCurve;
  final double volume; // 0.0 - 2.0
  final bool isMuted;
  final VideoFilterPreset filter;
  final TransitionType transition;
  final Duration transitionDuration;
  final String? customThumbnail;
  final int trackIndex; // 0 for V1, 1 for V2, 2 for V3...
  final double scale; // 0.1 to 5.0 (1.0 = 100%)
  final double rotation; // In radians (0.0 = 0 deg)
  final double positionX; // Offset from center in canvas coordinates (-1.0 to 1.0)
  final double positionY; // Offset from center in canvas coordinates (-1.0 to 1.0)
  final bool flipHorizontal;
  final bool flipVertical;
  final List<KeyframeModel> keyframes;

  const VideoClipModel({
    required this.id,
    required this.sourcePath,
    this.isAsset = false,
    required this.title,
    required this.startTime,
    required this.duration,
    required this.sourceDuration,
    this.trimStart = Duration.zero,
    this.trimEnd = Duration.zero,
    this.speed = 1.0,
    this.speedCurve = SpeedCurveType.none,
    this.volume = 1.0,
    this.isMuted = false,
    this.filter = VideoFilterPreset.none,
    this.transition = TransitionType.none,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.customThumbnail,
    this.trackIndex = 0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.positionX = 0.0,
    this.positionY = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.keyframes = const [],
  });

  Duration get endTime => startTime + duration;

  /// Gets the transform (scale, rotation, position, opacity) interpolated across keyframes
  KeyframeTransform getTransformAt(Duration localOffset) {
    return KeyframeModel.interpolate(
      keyframes: keyframes,
      offset: localOffset,
      baseScale: scale,
      baseRotation: rotation,
      basePositionX: positionX,
      basePositionY: positionY,
    );
  }

  VideoClipModel copyWith({
    String? id,
    String? sourcePath,
    bool? isAsset,
    String? title,
    Duration? startTime,
    Duration? duration,
    Duration? sourceDuration,
    Duration? trimStart,
    Duration? trimEnd,
    double? speed,
    SpeedCurveType? speedCurve,
    double? volume,
    bool? isMuted,
    VideoFilterPreset? filter,
    TransitionType? transition,
    Duration? transitionDuration,
    String? customThumbnail,
    int? trackIndex,
    double? scale,
    double? rotation,
    double? positionX,
    double? positionY,
    bool? flipHorizontal,
    bool? flipVertical,
    List<KeyframeModel>? keyframes,
  }) {
    return VideoClipModel(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      isAsset: isAsset ?? this.isAsset,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      sourceDuration: sourceDuration ?? this.sourceDuration,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      speed: speed ?? this.speed,
      speedCurve: speedCurve ?? this.speedCurve,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      filter: filter ?? this.filter,
      transition: transition ?? this.transition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      customThumbnail: customThumbnail ?? this.customThumbnail,
      trackIndex: trackIndex ?? this.trackIndex,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      keyframes: keyframes ?? this.keyframes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourcePath': sourcePath,
      'isAsset': isAsset,
      'title': title,
      'startTimeMs': startTime.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'sourceDurationMs': sourceDuration.inMilliseconds,
      'trimStartMs': trimStart.inMilliseconds,
      'trimEndMs': trimEnd.inMilliseconds,
      'speed': speed,
      'speedCurve': speedCurve.name,
      'volume': volume,
      'isMuted': isMuted,
      'filter': filter.name,
      'transition': transition.name,
      'transitionDurationMs': transitionDuration.inMilliseconds,
      'customThumbnail': customThumbnail,
      'trackIndex': trackIndex,
      'scale': scale,
      'rotation': rotation,
      'positionX': positionX,
      'positionY': positionY,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'keyframes': keyframes.map((k) => k.toJson()).toList(),
    };
  }

  factory VideoClipModel.fromJson(Map<String, dynamic> json) {
    return VideoClipModel(
      id: json['id'] as String,
      sourcePath: json['sourcePath'] as String,
      isAsset: json['isAsset'] as bool? ?? false,
      title: json['title'] as String,
      startTime: Duration(milliseconds: json['startTimeMs'] as int),
      duration: Duration(milliseconds: json['durationMs'] as int),
      sourceDuration: Duration(milliseconds: json['sourceDurationMs'] as int),
      trimStart: Duration(milliseconds: json['trimStartMs'] as int? ?? 0),
      trimEnd: Duration(milliseconds: json['trimEndMs'] as int? ?? 0),
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      speedCurve: SpeedCurveType.values.firstWhere(
        (e) => e.name == json['speedCurve'],
        orElse: () => SpeedCurveType.none,
      ),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      filter: VideoFilterPreset.values.firstWhere(
        (e) => e.name == json['filter'],
        orElse: () => VideoFilterPreset.none,
      ),
      transition: TransitionType.values.firstWhere(
        (e) => e.name == json['transition'],
        orElse: () => TransitionType.none,
      ),
      transitionDuration: Duration(
        milliseconds: json['transitionDurationMs'] as int? ?? 500,
      ),
      customThumbnail: json['customThumbnail'] as String?,
      trackIndex: json['trackIndex'] as int? ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      positionX: (json['positionX'] as num?)?.toDouble() ?? 0.0,
      positionY: (json['positionY'] as num?)?.toDouble() ?? 0.0,
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
      keyframes: (json['keyframes'] as List<dynamic>?)
              ?.map((k) => KeyframeModel.fromJson(k as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
