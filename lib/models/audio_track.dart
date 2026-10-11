import 'package:flutter/material.dart';

enum AudioTrackType {
  music,
  voiceover,
  soundEffect,
}

enum VoiceEffectPreset {
  none('Original', Icons.mic_none_rounded),
  bassBoost('Bass Boost', Icons.speaker_group_rounded),
  crispVocal('Crisp Vocal', Icons.graphic_eq_rounded),
  echoReverb('Echo Reverb', Icons.surround_sound_rounded),
  telephone('Telephone', Icons.phone_in_talk_rounded),
  robot('Robot', Icons.smart_toy_rounded),
  deepVoice('Deep Voice', Icons.record_voice_over_rounded),
  chipmunk('Chipmunk', Icons.sentiment_very_satisfied_rounded);

  final String label;
  final IconData icon;
  const VoiceEffectPreset(this.label, this.icon);
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
  final double volume; // 0.0 - 2.0 (boost up to 200%)
  final bool isMuted;
  final List<double> waveformData;
  final int trackIndex; // 0 for A1, 1 for A2, 2 for A3...
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final VoiceEffectPreset voiceEffect;

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
    this.trackIndex = 0,
    this.fadeInDuration = Duration.zero,
    this.fadeOutDuration = Duration.zero,
    this.voiceEffect = VoiceEffectPreset.none,
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
    int? trackIndex,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
    VoiceEffectPreset? voiceEffect,
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
      trackIndex: trackIndex ?? this.trackIndex,
      fadeInDuration: fadeInDuration ?? this.fadeInDuration,
      fadeOutDuration: fadeOutDuration ?? this.fadeOutDuration,
      voiceEffect: voiceEffect ?? this.voiceEffect,
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
      'trackIndex': trackIndex,
      'fadeInDurationMs': fadeInDuration.inMilliseconds,
      'fadeOutDurationMs': fadeOutDuration.inMilliseconds,
      'voiceEffect': voiceEffect.name,
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
      trackIndex: json['trackIndex'] as int? ?? 0,
      fadeInDuration: Duration(
        milliseconds: json['fadeInDurationMs'] as int? ?? 0,
      ),
      fadeOutDuration: Duration(
        milliseconds: json['fadeOutDurationMs'] as int? ?? 0,
      ),
      voiceEffect: VoiceEffectPreset.values.firstWhere(
        (e) => e.name == json['voiceEffect'],
        orElse: () => VoiceEffectPreset.none,
      ),
    );
  }
}
