import 'package:uuid/uuid.dart';
import '../models/template.dart';
import '../models/project.dart';
import '../models/video_clip.dart';
import '../models/text_overlay.dart';
import '../models/audio_track.dart';

class TemplateService {
  static List<VideoTemplateModel> getTemplates() {
    return const [
      VideoTemplateModel(
        id: 'tmpl-vlog',
        title: 'Daily Aesthetic Vlog',
        tag: 'VLOG',
        description: 'Warm cafe & lifestyle aesthetic with gentle cuts and ambient vibes.',
        aspectRatio: AspectRatioPreset.vertical9x16,
        estimatedDuration: Duration(seconds: 28),
        placeholderClipsCount: 3,
        suggestedMusicTitle: 'Cafe Moments.mp3',
        initialTitleText: 'A Beautiful Day ✨',
        filter: VideoFilterPreset.warmSunset,
        badgeText: 'POPULAR',
      ),
      VideoTemplateModel(
        id: 'tmpl-travel',
        title: 'Cinematic Mountain Travel',
        tag: 'TRAVEL',
        description: 'Breathtaking landscape transitions with letterbox grading.',
        aspectRatio: AspectRatioPreset.vertical9x16,
        estimatedDuration: Duration(seconds: 45),
        placeholderClipsCount: 4,
        suggestedMusicTitle: 'Wanderlust Ambient.mp3',
        initialTitleText: 'A Brighter You 🏔️',
        filter: VideoFilterPreset.cinematic,
        badgeText: 'TRENDING',
      ),
      VideoTemplateModel(
        id: 'tmpl-birthday',
        title: 'Birthday Celebration Memories',
        tag: 'BIRTHDAY',
        description: 'Vibrant party colors, upbeat bounce text, and joyful beat drops.',
        aspectRatio: AspectRatioPreset.vertical9x16,
        estimatedDuration: Duration(seconds: 30),
        placeholderClipsCount: 3,
        suggestedMusicTitle: 'Birthday Beats.mp3',
        initialTitleText: 'Happy Birthday! 🎉',
        filter: VideoFilterPreset.vividPop,
        badgeText: 'FEATURED',
      ),
      VideoTemplateModel(
        id: 'tmpl-food',
        title: 'Gourmet Food Reel',
        tag: 'FOOD',
        description: 'Close-up culinary shots, sizzling sizzles, and crisp color pop.',
        aspectRatio: AspectRatioPreset.square1x1,
        estimatedDuration: Duration(seconds: 25),
        placeholderClipsCount: 3,
        suggestedMusicTitle: 'Acoustic Kitchen.mp3',
        initialTitleText: 'Chef’s Special 🍜',
        filter: VideoFilterPreset.warmSunset,
        badgeText: 'NEW',
      ),
    ];
  }

  static ProjectModel createProjectFromTemplate(VideoTemplateModel template) {
    const uuid = Uuid();
    final now = DateTime.now();

    final clips = List.generate(
      template.placeholderClipsCount,
      (i) {
        final clipDuration = Duration(
          milliseconds: (template.estimatedDuration.inMilliseconds /
                  template.placeholderClipsCount)
              .round(),
        );
        return VideoClipModel(
          id: uuid.v4(),
          sourcePath: 'assets/sample_${template.tag.toLowerCase()}_$i.mp4',
          title: '${template.tag} Scene ${i + 1}',
          startTime: clipDuration * i,
          duration: clipDuration,
          sourceDuration: clipDuration + const Duration(seconds: 3),
          filter: template.filter,
        );
      },
    );

    return ProjectModel(
      id: uuid.v4(),
      title: '${template.tag} Edit',
      aspectRatio: template.aspectRatio,
      resolution: ResolutionPreset.res1080p,
      fps: 30,
      createdAt: now,
      updatedAt: now,
      globalFilter: template.filter,
      videoClips: clips,
      textOverlays: [
        TextOverlayModel(
          id: uuid.v4(),
          text: template.initialTitleText,
          startTime: const Duration(seconds: 1),
          duration: Duration(
            seconds: (template.estimatedDuration.inSeconds * 0.6).round(),
          ),
          fontSize: 24,
          fontColorValue: 0xFFFFFFFF,
          backgroundColorValue: 0xCC7C3AED,
          positionX: 0.0,
          positionY: 0.45,
          animation: TextAnimationType.popIn,
        ),
      ],
      audioTracks: [
        AudioTrackModel(
          id: uuid.v4(),
          title: template.suggestedMusicTitle,
          sourcePath: 'assets/${template.suggestedMusicTitle}',
          type: AudioTrackType.music,
          startTime: Duration.zero,
          duration: template.estimatedDuration,
          volume: 0.85,
          waveformData: List.generate(30, (i) => 0.25 + (i % 5 * 0.15)),
        ),
      ],
    );
  }
}
