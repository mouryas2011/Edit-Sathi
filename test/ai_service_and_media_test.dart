import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edit_sathi/models/project.dart';
import 'package:edit_sathi/models/video_clip.dart';
import 'package:edit_sathi/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('On-Device AI Suite & Media Tests', () {
    late ProjectModel sampleProject;

    setUp(() {
      final now = DateTime.now();
      sampleProject = ProjectModel(
        id: 'ai-proj-1',
        title: 'Podcast Highlights',
        createdAt: now,
        updatedAt: now,
        videoClips: const [
          VideoClipModel(
            id: 'c1',
            sourcePath: '/sandbox/test_video.mp4',
            title: 'Speaker Clip',
            startTime: Duration.zero,
            duration: Duration(seconds: 15),
            sourceDuration: Duration(seconds: 15),
          ),
        ],
      );
    });

    test('Generates offline captions with accurate timestamp intervals', () async {
      final captions = await AiService.generateOfflineCaptions(
        project: sampleProject,
        languageCode: 'hi_en',
      );

      expect(captions.isNotEmpty, isTrue);
      expect(captions.first.startTime, Duration.zero);
      expect(captions.first.text.isNotEmpty, isTrue);

      // Verify SRT export formatting
      final srt = AiService.exportToSrt(captions);
      expect(srt.contains('-->'), isTrue);
      expect(srt.contains('1'), isTrue);
    });

    test('Detects speech silence intervals for clean jump cuts', () {
      final silences = AiService.detectSilenceIntervals(sampleProject);
      expect(silences.isNotEmpty, isTrue);
      expect(silences.first.duration > Duration.zero, isTrue);

      final cutProject = AiService.applySilenceJumpCuts(
        project: sampleProject,
        selectedSilences: silences,
      );
      expect(cutProject.videoClips.isNotEmpty, isTrue);
    });

    test('Evaluates best thumbnail candidates deterministically without cloud', () {
      final thumbnails = AiService.evaluateThumbnailCandidates(sampleProject);
      expect(thumbnails.isNotEmpty, isTrue);
      expect(thumbnails.first.overallScore, inInclusiveRange(0.0, 100.0));
      expect(thumbnails.first.timestamp <= sampleProject.totalDuration, isTrue);
    });

    test('Diagnoses audio loudness and LUFS metrics locally', () {
      final report = AiService.diagnoseAudio(sampleProject);
      expect(report.estimatedLufs, isNotNull);
      expect(report.healthStatus.isNotEmpty, isTrue);
      expect(report.recommendation.isNotEmpty, isTrue);

      final normalized = AiService.normalizeAudio(sampleProject);
      expect(normalized.videoClips.first.volume, closeTo(1.0, 0.5));
    });
  });
}
