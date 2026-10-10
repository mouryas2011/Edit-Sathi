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
  none,
  crossFade,
  slideLeft,
  zoomIn,
  fadeToBlack,
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
  final double speed; // 0.5x, 1.0x, 2.0x
  final double volume; // 0.0 - 1.0
  final bool isMuted;
  final VideoFilterPreset filter;
  final TransitionType transition;
  final String? customThumbnail;

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
    this.volume = 1.0,
    this.isMuted = false,
    this.filter = VideoFilterPreset.none,
    this.transition = TransitionType.none,
    this.customThumbnail,
  });

  Duration get endTime => startTime + duration;

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
    double? volume,
    bool? isMuted,
    VideoFilterPreset? filter,
    TransitionType? transition,
    String? customThumbnail,
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
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      filter: filter ?? this.filter,
      transition: transition ?? this.transition,
      customThumbnail: customThumbnail ?? this.customThumbnail,
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
      'volume': volume,
      'isMuted': isMuted,
      'filter': filter.name,
      'transition': transition.name,
      'customThumbnail': customThumbnail,
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
      customThumbnail: json['customThumbnail'] as String?,
    );
  }
}
