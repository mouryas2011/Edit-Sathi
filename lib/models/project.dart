import 'video_clip.dart';
import 'text_overlay.dart';
import 'audio_track.dart';
import 'shape_overlay.dart';
import 'adjustment_layer.dart';

enum AspectRatioPreset {
  vertical9x16(9 / 16, '9:16', 'TikTok / Reels'),
  horizontal16x9(16 / 9, '16:9', 'YouTube / Standard'),
  square1x1(1 / 1, '1:1', 'Instagram Post'),
  portrait4x5(4 / 5, '4:5', 'Portrait Feed'),
  cinematic21x9(21 / 9, '21:9', 'Cinematic Wide');

  final double ratio;
  final String label;
  final String description;
  const AspectRatioPreset(this.ratio, this.label, this.description);
}

enum ResolutionPreset {
  res720p('720p', 1280, 720),
  res1080p('1080p', 1920, 1080),
  res4K('4K UHD', 3840, 2160);

  final String label;
  final int width;
  final int height;
  const ResolutionPreset(this.label, this.width, this.height);
}

enum CanvasBgType {
  blur('Blur Fill', 'Soft blurred background from current video clip'),
  color('Solid Color', 'Studio solid color backdrop'),
  gradient('Gradient', 'Modern aesthetic gradient backdrop');

  final String label;
  final String description;
  const CanvasBgType(this.label, this.description);
}

class ProjectModel {
  final String id;
  final String title;
  final AspectRatioPreset aspectRatio;
  final ResolutionPreset resolution;
  final int fps; // 24, 30, 60
  final List<VideoClipModel> videoClips;
  final List<TextOverlayModel> textOverlays;
  final List<AudioTrackModel> audioTracks;
  final List<ShapeOverlayModel> shapes;
  final List<AdjustmentLayerModel> adjustmentLayers;
  final VideoFilterPreset globalFilter;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? customThumbnail;
  final int videoTrackCount; // e.g. 1 (V1), 2 (V2), 3 (V3)
  final int audioTrackCount; // e.g. 1 (A1), 2 (A2), 3 (A3)
  final List<int> mutedVideoTracks;
  final List<int> hiddenVideoTracks;
  final List<int> lockedVideoTracks;
  final List<int> mutedAudioTracks;
  final List<int> lockedAudioTracks;
  final CanvasBgType canvasBgType;
  final int canvasColorValue;
  final int canvasGradientIndex;
  final double canvasBlurSigma;

  const ProjectModel({
    required this.id,
    required this.title,
    this.aspectRatio = AspectRatioPreset.vertical9x16,
    this.resolution = ResolutionPreset.res1080p,
    this.fps = 30,
    this.videoClips = const [],
    this.textOverlays = const [],
    this.audioTracks = const [],
    this.shapes = const [],
    this.adjustmentLayers = const [],
    this.globalFilter = VideoFilterPreset.none,
    required this.createdAt,
    required this.updatedAt,
    this.customThumbnail,
    this.videoTrackCount = 1,
    this.audioTrackCount = 1,
    this.mutedVideoTracks = const [],
    this.hiddenVideoTracks = const [],
    this.lockedVideoTracks = const [],
    this.mutedAudioTracks = const [],
    this.lockedAudioTracks = const [],
    this.canvasBgType = CanvasBgType.blur,
    this.canvasColorValue = 0xFF0B0F19,
    this.canvasGradientIndex = 0,
    this.canvasBlurSigma = 12.0,
  });

  /// Computes the total timeline length based on all tracks.
  Duration get totalDuration {
    Duration maxDuration = Duration.zero;

    for (final clip in videoClips) {
      if (clip.endTime > maxDuration) {
        maxDuration = clip.endTime;
      }
    }
    for (final text in textOverlays) {
      if (text.endTime > maxDuration) {
        maxDuration = text.endTime;
      }
    }
    for (final audio in audioTracks) {
      if (audio.endTime > maxDuration) {
        maxDuration = audio.endTime;
      }
    }
    for (final shape in shapes) {
      if (shape.endTime > maxDuration) {
        maxDuration = shape.endTime;
      }
    }
    for (final adj in adjustmentLayers) {
      if (adj.endTime > maxDuration) {
        maxDuration = adj.endTime;
      }
    }

    return maxDuration == Duration.zero ? const Duration(seconds: 5) : maxDuration;
  }

  String get formattedDuration {
    final d = totalDuration;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    AspectRatioPreset? aspectRatio,
    ResolutionPreset? resolution,
    int? fps,
    List<VideoClipModel>? videoClips,
    List<TextOverlayModel>? textOverlays,
    List<AudioTrackModel>? audioTracks,
    List<ShapeOverlayModel>? shapes,
    List<AdjustmentLayerModel>? adjustmentLayers,
    VideoFilterPreset? globalFilter,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customThumbnail,
    int? videoTrackCount,
    int? audioTrackCount,
    List<int>? mutedVideoTracks,
    List<int>? hiddenVideoTracks,
    List<int>? lockedVideoTracks,
    List<int>? mutedAudioTracks,
    List<int>? lockedAudioTracks,
    CanvasBgType? canvasBgType,
    int? canvasColorValue,
    int? canvasGradientIndex,
    double? canvasBlurSigma,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      videoClips: videoClips ?? this.videoClips,
      textOverlays: textOverlays ?? this.textOverlays,
      audioTracks: audioTracks ?? this.audioTracks,
      shapes: shapes ?? this.shapes,
      adjustmentLayers: adjustmentLayers ?? this.adjustmentLayers,
      globalFilter: globalFilter ?? this.globalFilter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customThumbnail: customThumbnail ?? this.customThumbnail,
      videoTrackCount: videoTrackCount ?? this.videoTrackCount,
      audioTrackCount: audioTrackCount ?? this.audioTrackCount,
      mutedVideoTracks: mutedVideoTracks ?? this.mutedVideoTracks,
      hiddenVideoTracks: hiddenVideoTracks ?? this.hiddenVideoTracks,
      lockedVideoTracks: lockedVideoTracks ?? this.lockedVideoTracks,
      mutedAudioTracks: mutedAudioTracks ?? this.mutedAudioTracks,
      lockedAudioTracks: lockedAudioTracks ?? this.lockedAudioTracks,
      canvasBgType: canvasBgType ?? this.canvasBgType,
      canvasColorValue: canvasColorValue ?? this.canvasColorValue,
      canvasGradientIndex: canvasGradientIndex ?? this.canvasGradientIndex,
      canvasBlurSigma: canvasBlurSigma ?? this.canvasBlurSigma,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'aspectRatio': aspectRatio.name,
      'resolution': resolution.name,
      'fps': fps,
      'videoClips': videoClips.map((e) => e.toJson()).toList(),
      'textOverlays': textOverlays.map((e) => e.toJson()).toList(),
      'audioTracks': audioTracks.map((e) => e.toJson()).toList(),
      'shapes': shapes.map((e) => e.toJson()).toList(),
      'adjustmentLayers': adjustmentLayers.map((e) => e.toJson()).toList(),
      'globalFilter': globalFilter.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'customThumbnail': customThumbnail,
      'videoTrackCount': videoTrackCount,
      'audioTrackCount': audioTrackCount,
      'mutedVideoTracks': mutedVideoTracks,
      'hiddenVideoTracks': hiddenVideoTracks,
      'lockedVideoTracks': lockedVideoTracks,
      'mutedAudioTracks': mutedAudioTracks,
      'lockedAudioTracks': lockedAudioTracks,
      'canvasBgType': canvasBgType.name,
      'canvasColorValue': canvasColorValue,
      'canvasGradientIndex': canvasGradientIndex,
      'canvasBlurSigma': canvasBlurSigma,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      aspectRatio: AspectRatioPreset.values.firstWhere(
        (e) => e.name == json['aspectRatio'],
        orElse: () => AspectRatioPreset.vertical9x16,
      ),
      resolution: ResolutionPreset.values.firstWhere(
        (e) => e.name == json['resolution'],
        orElse: () => ResolutionPreset.res1080p,
      ),
      fps: json['fps'] as int? ?? 30,
      videoClips: (json['videoClips'] as List<dynamic>?)
              ?.map((e) => VideoClipModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      textOverlays: (json['textOverlays'] as List<dynamic>?)
              ?.map((e) => TextOverlayModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      audioTracks: (json['audioTracks'] as List<dynamic>?)
              ?.map((e) => AudioTrackModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      shapes: (json['shapes'] as List<dynamic>?)
              ?.map((e) => ShapeOverlayModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      adjustmentLayers: (json['adjustmentLayers'] as List<dynamic>?)
              ?.map((e) => AdjustmentLayerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      globalFilter: VideoFilterPreset.values.firstWhere(
        (e) => e.name == json['globalFilter'],
        orElse: () => VideoFilterPreset.none,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      customThumbnail: json['customThumbnail'] as String?,
      videoTrackCount: json['videoTrackCount'] as int? ?? 1,
      audioTrackCount: json['audioTrackCount'] as int? ?? 1,
      mutedVideoTracks: (json['mutedVideoTracks'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      hiddenVideoTracks: (json['hiddenVideoTracks'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      lockedVideoTracks: (json['lockedVideoTracks'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      mutedAudioTracks: (json['mutedAudioTracks'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      lockedAudioTracks: (json['lockedAudioTracks'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      canvasBgType: CanvasBgType.values.firstWhere(
        (e) => e.name == json['canvasBgType'],
        orElse: () => CanvasBgType.blur,
      ),
      canvasColorValue: json['canvasColorValue'] as int? ?? 0xFF0B0F19,
      canvasGradientIndex: json['canvasGradientIndex'] as int? ?? 0,
      canvasBlurSigma: (json['canvasBlurSigma'] as num?)?.toDouble() ?? 12.0,
    );
  }
}
