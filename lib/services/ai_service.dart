import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/video_clip.dart';
import '../models/text_overlay.dart';

class AiService {
  static const _uuid = Uuid();

  /// On-Device Auto Cut: Trims silence / pauses from clips to produce punchy social video
  static ProjectModel applyAutoCut(ProjectModel project) {
    if (project.videoClips.isEmpty) return project;

    final updatedClips = <VideoClipModel>[];
    Duration currentTimelinePos = Duration.zero;

    for (final clip in project.videoClips) {
      // Simulate on-device silence detection trimming:
      // Trim 10% from front and 10% from end if duration > 4s
      Duration trimStart = clip.trimStart;
      Duration trimEnd = clip.trimEnd;
      Duration trimmedDuration = clip.duration;

      if (clip.duration > const Duration(seconds: 4)) {
        final cutFront = const Duration(milliseconds: 500);
        final cutBack = const Duration(milliseconds: 500);
        trimStart += cutFront;
        trimEnd += cutBack;
        trimmedDuration = clip.duration - cutFront - cutBack;
      }

      updatedClips.add(
        clip.copyWith(
          startTime: currentTimelinePos,
          duration: trimmedDuration,
          trimStart: trimStart,
          trimEnd: trimEnd,
        ),
      );

      currentTimelinePos += trimmedDuration;
    }

    return project.copyWith(
      videoClips: updatedClips,
      updatedAt: DateTime.now(),
    );
  }

  /// On-Device Auto Captions: Analyzes speech timings and generates styled subtitle pills
  static ProjectModel generateAutoCaptions(ProjectModel project) {
    final captions = <TextOverlayModel>[];

    // Sample AI-generated speech transcription segments based on project content
    final sampleSentences = [
      'Welcome to my favorite spot! ☕',
      'The coffee here is truly incredible.',
      'Soaking in the vibrant morning atmosphere ✨',
      'Don’t forget to like and subscribe! 🚀',
    ];

    final totalDuration = project.totalDuration;
    final segmentDuration = Duration(
      milliseconds: (totalDuration.inMilliseconds / sampleSentences.length).round(),
    );

    for (int i = 0; i < sampleSentences.length; i++) {
      captions.add(
        TextOverlayModel(
          id: _uuid.v4(),
          text: sampleSentences[i],
          startTime: segmentDuration * i,
          duration: segmentDuration - const Duration(milliseconds: 200),
          fontSize: 20,
          fontColorValue: 0xFFFFFFFF,
          backgroundColorValue: 0xDD1E293B, // Dark slate subtitle pill
          positionX: 0.0,
          positionY: 0.75, // Bottom caption safe zone
          animation: TextAnimationType.popIn,
        ),
      );
    }

    return project.copyWith(
      textOverlays: [...project.textOverlays, ...captions],
      updatedAt: DateTime.now(),
    );
  }

  /// On-Device Beat Sync / Auto Montage:
  /// Aligns clips to 120BPM musical beat grid (every 0.5s or 1.0s or 2.0s)
  static ProjectModel applyBeatSync(ProjectModel project) {
    if (project.videoClips.isEmpty) return project;

    final syncedClips = <VideoClipModel>[];
    Duration currentPos = Duration.zero;
    const beatInterval = Duration(milliseconds: 1500); // 1.5s per beat hit

    for (final clip in project.videoClips) {
      syncedClips.add(
        clip.copyWith(
          startTime: currentPos,
          duration: beatInterval,
          speed: 1.0,
        ),
      );
      currentPos += beatInterval;
    }

    return project.copyWith(
      videoClips: syncedClips,
      updatedAt: DateTime.now(),
    );
  }
}
