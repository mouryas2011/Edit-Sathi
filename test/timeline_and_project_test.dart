import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edit_sathi/models/project.dart';
import 'package:edit_sathi/models/video_clip.dart';
import 'package:edit_sathi/models/text_overlay.dart';
import 'package:edit_sathi/models/audio_track.dart';
import 'package:edit_sathi/models/shape_overlay.dart';
import 'package:edit_sathi/models/adjustment_layer.dart';
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

    test('Adobe Premiere Pro multi-track video and audio tracks expansion and placement', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Premiere Pro Multi-Track Test');

      expect(provider.activeProject!.videoTrackCount, 1);
      expect(provider.activeProject!.audioTrackCount, 1);

      // Add Video Track V2
      provider.addVideoTrack();
      expect(provider.activeProject!.videoTrackCount, 2);

      // Add Audio Track A2
      provider.addAudioTrackLane();
      expect(provider.activeProject!.audioTrackCount, 2);

      // Place clip on Track V2
      provider.addVideoClipToTrack(
        const VideoClipModel(
          id: 'v2-clip',
          sourcePath: 'overlay.mp4',
          title: 'B-Roll Overlay',
          startTime: Duration(seconds: 4),
          duration: Duration(seconds: 6),
          sourceDuration: Duration(seconds: 6),
          trackIndex: 1, // V2
        ),
        trackIndex: 1,
        startTime: const Duration(seconds: 4),
      );

      // Place audio on Track A2
      provider.addAudioClipToTrack(
        const AudioTrackModel(
          id: 'a2-audio',
          title: 'SFX Whoosh',
          sourcePath: 'whoosh.mp3',
          startTime: Duration(seconds: 3),
          duration: Duration(seconds: 2),
          trackIndex: 1, // A2
        ),
        trackIndex: 1,
        startTime: const Duration(seconds: 3),
      );

      final project = provider.activeProject!;
      expect(project.videoClips.any((c) => c.trackIndex == 1), isTrue);
      expect(project.audioTracks.any((a) => a.trackIndex == 1), isTrue);

      // Test Track toggles (Mute, Hide, Lock)
      provider.toggleHideVideoTrack(1);
      expect(provider.activeProject!.hiddenVideoTracks.contains(1), isTrue);
      provider.toggleHideVideoTrack(1);
      expect(provider.activeProject!.hiddenVideoTracks.contains(1), isFalse);

      provider.toggleMuteAudioTrack(0);
      expect(provider.activeProject!.mutedAudioTracks.contains(0), isTrue);
      provider.toggleLockVideoTrack(1);
      expect(provider.activeProject!.lockedVideoTracks.contains(1), isTrue);
    });

    test('splitClipAtPlayhead cleanly splits target clip under needle', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Split Test');

      provider.addVideoClip(
        const VideoClipModel(
          id: 'clip-to-split',
          sourcePath: 'long_video.mp4',
          title: 'Full Scene',
          startTime: Duration.zero,
          duration: Duration(seconds: 20),
          sourceDuration: Duration(seconds: 20),
        ),
      );

      // Split at 7.5 seconds
      final success = provider.splitClipAtPlayhead(const Duration(milliseconds: 7500));
      expect(success, isTrue);

      final clips = provider.activeProject!.videoClips;
      expect(clips.length, 2);
      expect(clips[0].duration, const Duration(milliseconds: 7500));
      expect(clips[1].startTime, const Duration(milliseconds: 7500));
      expect(clips[1].duration, const Duration(milliseconds: 12500));
    });

    test('TimelineProvider stepping and zoom adjustments work accurately', () {
      final timeline = TimelineProvider();
      timeline.setTotalDuration(const Duration(seconds: 30));

      expect(timeline.currentPosition, Duration.zero);
      timeline.stepForward(step: const Duration(seconds: 2));
      expect(timeline.currentPosition, const Duration(seconds: 2));

      timeline.stepBackward(step: const Duration(seconds: 1));
      expect(timeline.currentPosition, const Duration(seconds: 1));

      final initialZoom = timeline.zoomLevel;
      timeline.zoomIn();
      expect(timeline.zoomLevel, initialZoom + 0.25);
      timeline.zoomOut();
      expect(timeline.zoomLevel, initialZoom);
    });

    test('VideoClipModel transform properties and ProjectProvider transform methods work accurately', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Transform Test');

      const clip = VideoClipModel(
        id: 'clip-t1',
        sourcePath: 'sample.mp4',
        title: 'Transform Clip',
        startTime: Duration.zero,
        duration: Duration(seconds: 10),
        sourceDuration: Duration(seconds: 10),
      );
      provider.addVideoClip(clip);

      // Verify default transform
      expect(provider.activeProject!.videoClips.first.scale, 1.0);
      expect(provider.activeProject!.videoClips.first.rotation, 0.0);
      expect(provider.activeProject!.videoClips.first.positionX, 0.0);
      expect(provider.activeProject!.videoClips.first.positionY, 0.0);
      expect(provider.activeProject!.videoClips.first.flipHorizontal, isFalse);

      // Apply transform update
      provider.updateClipTransform(
        'clip-t1',
        scale: 1.75,
        rotation: 0.52,
        positionX: 0.25,
        positionY: -0.15,
      );

      final updated = provider.activeProject!.videoClips.first;
      expect(updated.scale, 1.75);
      expect(updated.rotation, 0.52);
      expect(updated.positionX, 0.25);
      expect(updated.positionY, -0.15);

      // Reset transform
      provider.resetClipTransform('clip-t1');
      final reset = provider.activeProject!.videoClips.first;
      expect(reset.scale, 1.0);
      expect(reset.rotation, 0.0);
      expect(reset.positionX, 0.0);
      expect(reset.positionY, 0.0);
      expect(reset.flipHorizontal, isFalse);
    });

    test('ShapeOverlayModel creation, serialization, and ProjectProvider CRUD operations', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Shape Test');

      final shape = ShapeOverlayModel(
        id: 'shape-1',
        type: ShapeType.star,
        color: 0xFFFFD700,
        strokeColor: 0xFFFFFFFF,
        strokeWidth: 3.0,
        positionX: 0.1,
        positionY: -0.2,
        width: 120,
        height: 120,
        rotation: 0.15,
        startTime: const Duration(seconds: 2),
        duration: const Duration(seconds: 5),
      );

      // Test JSON roundtrip
      final json = shape.toJson();
      final fromJson = ShapeOverlayModel.fromJson(json);
      expect(fromJson.id, 'shape-1');
      expect(fromJson.type, ShapeType.star);
      expect(fromJson.color, 0xFFFFD700);
      expect(fromJson.strokeWidth, 3.0);
      expect(fromJson.width, 120);
      expect(fromJson.startTime, const Duration(seconds: 2));
      expect(fromJson.duration, const Duration(seconds: 5));
      expect(fromJson.endTime, const Duration(seconds: 7));

      // Test CRUD in provider
      provider.addShape(shape);
      expect(provider.activeProject!.shapes.length, 1);

      // Update shape
      provider.updateShape(shape.copyWith(positionX: 0.5, strokeWidth: 4.5));
      expect(provider.activeProject!.shapes.first.positionX, 0.5);
      expect(provider.activeProject!.shapes.first.strokeWidth, 4.5);

      // Remove shape
      provider.removeShape('shape-1');
      expect(provider.activeProject!.shapes.isEmpty, isTrue);
    });

    test('AdjustmentLayerModel non-destructive color grading matrix generation and CRUD operations', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Adjustment Layer Test');

      final layer = AdjustmentLayerModel(
        id: 'adj-1',
        title: 'Cinematic Grade',
        filter: VideoFilterPreset.cinematic,
        brightness: 0.1,
        contrast: 1.25,
        saturation: 1.3,
        opacity: 0.9,
        startTime: const Duration(seconds: 1),
        duration: const Duration(seconds: 8),
      );

      // Test buildColorFilter()
      final filter = layer.buildColorFilter();
      expect(filter, isNotNull);

      // Test JSON roundtrip
      final json = layer.toJson();
      final fromJson = AdjustmentLayerModel.fromJson(json);
      expect(fromJson.id, 'adj-1');
      expect(fromJson.title, 'Cinematic Grade');
      expect(fromJson.filter, VideoFilterPreset.cinematic);
      expect(fromJson.contrast, 1.25);
      expect(fromJson.saturation, 1.3);
      expect(fromJson.opacity, 0.9);
      expect(fromJson.startTime, const Duration(seconds: 1));
      expect(fromJson.duration, const Duration(seconds: 8));
      expect(fromJson.endTime, const Duration(seconds: 9));

      // Test CRUD in provider
      provider.addAdjustmentLayer(layer);
      expect(provider.activeProject!.adjustmentLayers.length, 1);

      // Update adjustment layer
      provider.updateAdjustmentLayer(layer.copyWith(brightness: -0.2, title: 'Moody Noir'));
      expect(provider.activeProject!.adjustmentLayers.first.brightness, -0.2);
      expect(provider.activeProject!.adjustmentLayers.first.title, 'Moody Noir');

      // Remove adjustment layer
      provider.removeAdjustmentLayer('adj-1');
      expect(provider.activeProject!.adjustmentLayers.isEmpty, isTrue);
    });

    test('CapCut/VN timeline clip moving, in/out trimming, duplication, and splitting across all media types', () {
      final provider = ProjectProvider();
      provider.createNewProject(title: 'Interactive Timeline Gestures Test');

      // 1. Video Clip Move & Trim
      provider.addVideoClip(
        const VideoClipModel(
          id: 'v-touch-1',
          sourcePath: '/storage/vid.mp4',
          title: 'Scene A',
          startTime: Duration.zero,
          duration: Duration(seconds: 10),
          sourceDuration: Duration(seconds: 20),
        ),
      );

      // Move video clip along timeline
      provider.moveVideoClip('v-touch-1', const Duration(seconds: 4));
      provider.commitVideoClipMove('v-touch-1');
      expect(provider.activeProject!.videoClips.first.startTime, const Duration(seconds: 4));

      // Trim video clip in-point (start)
      provider.trimVideoClipStart('v-touch-1', const Duration(seconds: 2));
      final trimmedVid = provider.activeProject!.videoClips.first;
      expect(trimmedVid.startTime, const Duration(seconds: 6));
      expect(trimmedVid.duration, const Duration(seconds: 8));
      expect(trimmedVid.trimStart, const Duration(seconds: 2));

      // Trim video clip out-point (end)
      provider.trimVideoClipEnd('v-touch-1', const Duration(seconds: 5));
      expect(provider.activeProject!.videoClips.first.duration, const Duration(seconds: 5));

      // Duplicate video clip
      provider.duplicateVideoClip('v-touch-1');
      expect(provider.activeProject!.videoClips.length, 2);
      expect(provider.activeProject!.videoClips[1].startTime, provider.activeProject!.videoClips[0].endTime);

      // 2. Audio Clip Move, Trim & Split
      provider.addAudioTrack(
        const AudioTrackModel(
          id: 'a-touch-1',
          sourcePath: '/storage/audio.mp3',
          title: 'BGM',
          startTime: Duration.zero,
          duration: Duration(seconds: 12),
        ),
      );

      // Move audio clip
      provider.moveAudioClip('a-touch-1', const Duration(seconds: 3));
      provider.commitAudioClipMove('a-touch-1');
      expect(provider.activeProject!.audioTracks.first.startTime, const Duration(seconds: 3));

      // Trim audio start
      provider.trimAudioClipStart('a-touch-1', const Duration(seconds: 1));
      expect(provider.activeProject!.audioTracks.first.startTime, const Duration(seconds: 4));
      expect(provider.activeProject!.audioTracks.first.duration, const Duration(seconds: 11));

      // Trim audio end
      provider.trimAudioClip('a-touch-1', const Duration(seconds: 6));
      expect(provider.activeProject!.audioTracks.first.duration, const Duration(seconds: 6));

      // Split audio clip at position
      final audioSplit = provider.splitAudioClipAtPosition('a-touch-1', const Duration(seconds: 7));
      expect(audioSplit, isTrue);
      expect(provider.activeProject!.audioTracks.length, 2);
      expect(provider.activeProject!.audioTracks[0].duration, const Duration(seconds: 3));
      expect(provider.activeProject!.audioTracks[1].startTime, const Duration(seconds: 7));
      expect(provider.activeProject!.audioTracks[1].duration, const Duration(seconds: 3));

      // 3. Text Overlay Move, Trim & Duplicate
      provider.addTextOverlay(
        const TextOverlayModel(
          id: 't-touch-1',
          text: 'Title Intro',
          startTime: Duration.zero,
          duration: Duration(seconds: 5),
        ),
      );

      provider.moveTextOverlay('t-touch-1', const Duration(seconds: 2));
      provider.commitTextOverlayMove('t-touch-1');
      expect(provider.activeProject!.textOverlays.first.startTime, const Duration(seconds: 2));

      provider.trimTextOverlayStart('t-touch-1', const Duration(seconds: 1));
      expect(provider.activeProject!.textOverlays.first.startTime, const Duration(seconds: 3));
      expect(provider.activeProject!.textOverlays.first.duration, const Duration(seconds: 4));

      provider.duplicateTextOverlay('t-touch-1');
      expect(provider.activeProject!.textOverlays.length, 2);

      // 4. Shape Overlay Move, Trim & Duplicate
      provider.addShape(
        const ShapeOverlayModel(
          id: 's-touch-1',
          type: ShapeType.star,
          startTime: Duration.zero,
          duration: Duration(seconds: 4),
        ),
      );

      provider.moveShape('s-touch-1', const Duration(seconds: 3));
      provider.commitShapeMove('s-touch-1');
      expect(provider.activeProject!.shapes.first.startTime, const Duration(seconds: 3));

      provider.trimShapeStart('s-touch-1', const Duration(seconds: 1));
      expect(provider.activeProject!.shapes.first.startTime, const Duration(seconds: 4));
      expect(provider.activeProject!.shapes.first.duration, const Duration(seconds: 3));

      provider.duplicateShape('s-touch-1');
      expect(provider.activeProject!.shapes.length, 2);

      // 5. Adjustment Layer Move, Trim & Duplicate
      provider.addAdjustmentLayer(
        const AdjustmentLayerModel(
          id: 'adj-touch-1',
          title: 'Color Filter',
          startTime: Duration.zero,
          duration: Duration(seconds: 6),
        ),
      );

      provider.moveAdjustmentLayer('adj-touch-1', const Duration(seconds: 2));
      provider.commitAdjustmentLayerMove('adj-touch-1');
      expect(provider.activeProject!.adjustmentLayers.first.startTime, const Duration(seconds: 2));

      provider.trimAdjustmentLayerStart('adj-touch-1', const Duration(seconds: 1));
      expect(provider.activeProject!.adjustmentLayers.first.startTime, const Duration(seconds: 3));
      expect(provider.activeProject!.adjustmentLayers.first.duration, const Duration(seconds: 5));

      provider.duplicateAdjustmentLayer('adj-touch-1');
      expect(provider.activeProject!.adjustmentLayers.length, 2);
    });
  });
}
