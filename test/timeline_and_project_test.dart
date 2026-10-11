import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edit_sathi/models/project.dart';
import 'package:edit_sathi/models/video_clip.dart';
import 'package:edit_sathi/models/text_overlay.dart';
import 'package:edit_sathi/models/audio_track.dart';
import 'package:edit_sathi/providers/timeline_provider.dart';
import 'package:edit_sathi/providers/project_provider.dart';
import 'package:edit_sathi/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('ProjectModel & Timeline Tests', () {
    test('Calculates total timeline duration correctly from multiple tracks', () {
      final now = DateTime.now();
      final project = ProjectModel(
        id: 'test-1',
        title: 'Duration Test',
        createdAt: now,
        updatedAt: now,
        videoClips: const [
          VideoClipModel(
            id: 'c1',
            sourcePath: 'path1.mp4',
            title: 'Clip 1',
            startTime: Duration.zero,
            duration: Duration(seconds: 10),
            sourceDuration: Duration(seconds: 12),
          ),
          VideoClipModel(
            id: 'c2',
            sourcePath: 'path2.mp4',
            title: 'Clip 2',
            startTime: Duration(seconds: 10),
            duration: Duration(seconds: 15),
            sourceDuration: Duration(seconds: 20),
          ),
        ],
        textOverlays: const [
          TextOverlayModel(
            id: 't1',
            text: 'Ending Outro',
            startTime: Duration(seconds: 20),
            duration: Duration(seconds: 8), // ends at 28s
          ),
        ],
      );

      expect(project.totalDuration, const Duration(seconds: 28));
      expect(project.formattedDuration, '00:28');
    });

    test('ProjectModel JSON serialization and deserialization integrity', () {
      final now = DateTime.now();
      final original = ProjectModel(
        id: 'json-proj-1',
        title: 'Cafe Vlog',
        aspectRatio: AspectRatioPreset.vertical9x16,
        resolution: ResolutionPreset.res1080p,
        fps: 60,
        createdAt: now,
        updatedAt: now,
        globalFilter: VideoFilterPreset.warmSunset,
        videoClips: const [
          VideoClipModel(
            id: 'vc1',
            sourcePath: 'assets/sample.mp4',
            title: 'Intro',
            startTime: Duration.zero,
            duration: Duration(seconds: 5),
            sourceDuration: Duration(seconds: 10),
          ),
        ],
        audioTracks: [
          AudioTrackModel(
            id: 'at1',
            title: 'Cafe Moments.mp3',
            sourcePath: 'assets/audio.mp3',
            startTime: Duration.zero,
            duration: const Duration(seconds: 20),
            waveformData: const [0.2, 0.5, 0.8],
          ),
        ],
      );

      final json = original.toJson();
      final reconstructed = ProjectModel.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.aspectRatio, original.aspectRatio);
      expect(reconstructed.resolution, original.resolution);
      expect(reconstructed.fps, 60);
      expect(reconstructed.globalFilter, VideoFilterPreset.warmSunset);
      expect(reconstructed.videoClips.length, 1);
      expect(reconstructed.videoClips.first.title, 'Intro');
      expect(reconstructed.audioTracks.length, 1);
      expect(reconstructed.audioTracks.first.title, 'Cafe Moments.mp3');
    });

    test('Clip splitting at playhead produces two consecutive clips', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Split Test');

      const clip = VideoClipModel(
        id: 'clip-to-split',
        sourcePath: 'video.mp4',
        title: 'Full Scene',
        startTime: Duration.zero,
        duration: Duration(seconds: 10),
        sourceDuration: Duration(seconds: 10),
      );

      provider.addVideoClip(clip);
      expect(provider.activeProject!.videoClips.length, 1);

      // Split at 4.0 seconds
      final splitResult = provider.splitClipAtPosition(
        'clip-to-split',
        const Duration(seconds: 4),
      );

      expect(splitResult, isTrue);
      final clips = provider.activeProject!.videoClips;
      expect(clips.length, 2);
      expect(clips[0].duration, const Duration(seconds: 4));
      expect(clips[0].endTime, const Duration(seconds: 4));
      expect(clips[1].startTime, const Duration(seconds: 4));
      expect(clips[1].duration, const Duration(seconds: 6));
      expect(clips[1].endTime, const Duration(seconds: 10));
    });

    test('Undo and Redo stack works predictably on title and clip edits', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Initial Title');

      expect(provider.canUndo, isFalse);
      expect(provider.canRedo, isFalse);

      provider.updateTitle('Modified Title');
      expect(provider.activeProject!.title, 'Modified Title');
      expect(provider.canUndo, isTrue);

      provider.undo();
      expect(provider.activeProject!.title, 'Initial Title');
      expect(provider.canRedo, isTrue);

      provider.redo();
      expect(provider.activeProject!.title, 'Modified Title');
    });

    test('TimelineProvider scrubbing and boundary limits', () {
      final timeline = TimelineProvider();
      timeline.setTotalDuration(const Duration(seconds: 30));

      timeline.seekTo(const Duration(seconds: 15));
      expect(timeline.currentPosition, const Duration(seconds: 15));

      // Cannot seek negative
      timeline.seekTo(const Duration(seconds: -5));
      expect(timeline.currentPosition, Duration.zero);

      // Clamped to totalDuration
      timeline.seekTo(const Duration(seconds: 45));
      expect(timeline.currentPosition, const Duration(seconds: 30));
    });

    test('ExportSettings estimates output byte size accurately', () {
      const settings = ExportSettings(
        resolution: ResolutionPreset.res1080p,
        fps: 30,
        bitrateMbps: 12.0,
      );

      // For 10 seconds:
      // (12 * 1,000,000 / 8) * 10 = 15,000,000 bytes video
      // (192,000 / 8) * 10 = 240,000 bytes audio
      final estimatedBytes = settings.estimateFileSizeBytes(const Duration(seconds: 10));
      expect(estimatedBytes, 15240000);
      expect(settings.formatEstimatedSize(const Duration(seconds: 10)), '14.5 MB');
    });

    test('ProjectProvider creates project with initialClips correctly', () {
      final provider = ProjectProvider();
      const clip = VideoClipModel(
        id: 'clip-init-1',
        sourcePath: '/storage/sample.mp4',
        title: 'Initial Video',
        startTime: Duration.zero,
        duration: Duration(seconds: 24),
        sourceDuration: Duration(seconds: 24),
      );

      final project = provider.createNewProject(
        title: 'Imported Video',
        ratio: AspectRatioPreset.vertical9x16,
        resolution: ResolutionPreset.res1080p,
        initialClips: [clip],
      );

      expect(project.videoClips.length, 1);
      expect(project.videoClips.first.duration, const Duration(seconds: 24));
      expect(project.totalDuration, const Duration(seconds: 24));
      expect(provider.activeProject?.id, project.id);
    });

    test('Sequentially appending clips stacks them on the timeline', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Multi Clip Test');

      provider.addVideoClip(
        const VideoClipModel(
          id: 'c1',
          sourcePath: 'v1.mp4',
          title: 'Scene 1',
          startTime: Duration.zero,
          duration: Duration(seconds: 8),
          sourceDuration: Duration(seconds: 8),
        ),
      );

      provider.addVideoClip(
        const VideoClipModel(
          id: 'c2',
          sourcePath: 'v2.mp4',
          title: 'Scene 2',
          startTime: Duration.zero,
          duration: Duration(seconds: 12),
          sourceDuration: Duration(seconds: 12),
        ),
      );

      final clips = provider.activeProject!.videoClips;
      expect(clips.length, 2);
      expect(clips[0].startTime, Duration.zero);
      expect(clips[0].endTime, const Duration(seconds: 8));
      expect(clips[1].startTime, const Duration(seconds: 8));
      expect(clips[1].endTime, const Duration(seconds: 20));
      expect(provider.activeProject!.totalDuration, const Duration(seconds: 20));
    });
  });
}
