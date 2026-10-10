enum AudioTrackType {
  music,
  voiceover,
  soundEffect,
}

class AudioTrackModel {
  final String id;
  final String title;
  final String sourcePath;
  final bool isAsset;
  final AudioTrackType type;
  final Duration startTime;
  final Duration duration;
  final Duration trimStart;
  final double volume; // 0.0 - 1.0
  final bool isMuted;
  final List<double> waveformData;

  const AudioTrackModel({
    required this.id,
    required this.title,
    required this.sourcePath,
    this.isAsset = false,
    this.type = AudioTrackType.music,
    required this.startTime,
    required this.duration,
    this.trimStart = Duration.zero,
    this.volume = 1.0,
    this.isMuted = false,
    this.waveformData = const [],
  });

  Duration get endTime => startTime + duration;

  AudioTrackModel copyWith({
    String? id,
    String? title,
    String? sourcePath,
    bool? isAsset,
    AudioTrackType? type,
    Duration? startTime,
    Duration? duration,
    Duration? trimStart,
    double? volume,
    bool? isMuted,
    List<double>? waveformData,
  }) {
    return AudioTrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      sourcePath: sourcePath ?? this.sourcePath,
      isAsset: isAsset ?? this.isAsset,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      trimStart: trimStart ?? this.trimStart,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      waveformData: waveformData ?? this.waveformData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sourcePath': sourcePath,
      'isAsset': isAsset,
      'type': type.name,
      'startTimeMs': startTime.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'trimStartMs': trimStart.inMilliseconds,
      'volume': volume,
      'isMuted': isMuted,
      'waveformData': waveformData,
    };
  }

  factory AudioTrackModel.fromJson(Map<String, dynamic> json) {
    return AudioTrackModel(
      id: json['id'] as String,
      title: json['title'] as String,
      sourcePath: json['sourcePath'] as String,
      isAsset: json['isAsset'] as bool? ?? false,
      type: AudioTrackType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AudioTrackType.music,
      ),
      startTime: Duration(milliseconds: json['startTimeMs'] as int),
      duration: Duration(milliseconds: json['durationMs'] as int),
      trimStart: Duration(milliseconds: json['trimStartMs'] as int? ?? 0),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      waveformData: (json['waveformData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }
}
