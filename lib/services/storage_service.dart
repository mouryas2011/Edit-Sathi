import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/video_clip.dart';
import '../models/text_overlay.dart';
import '../models/audio_track.dart';

class StorageService {
  static const String _projectsKey = 'edit_sathi_projects_v1';
  static const String _initializedKey = 'edit_sathi_has_seeded_v1';

  static Future<List<ProjectModel>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeeded = prefs.getBool(_initializedKey) ?? false;

    if (!hasSeeded) {
      final seedProjects = _getInitialSeedProjects();
      await saveProjects(seedProjects);
      await prefs.setBool(_initializedKey, true);
      return seedProjects;
    }

    final rawJson = prefs.getString(_projectsKey);
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return _getInitialSeedProjects();
    }
  }

  static Future<void> saveProjects(List<ProjectModel> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(projects.map((p) => p.toJson()).toList());
    await prefs.setString(_projectsKey, encoded);
  }

  static Future<void> saveProject(ProjectModel project) async {
    final projects = await loadProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      projects[index] = project.copyWith(updatedAt: DateTime.now());
    } else {
      projects.insert(0, project);
    }
    await saveProjects(projects);
  }

  static Future<void> deleteProject(String id) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == id);
    await saveProjects(projects);
  }

  /// Initial realistic sample projects matching the user's reference mockup
  static List<ProjectModel> _getInitialSeedProjects() {
    final now = DateTime.now();

    return [
      // 1. Cafe Vlog (featured in mockup)
      ProjectModel(
        id: 'project-cafe-vlog',
        title: 'Cafe Vlog',
        aspectRatio: AspectRatioPreset.vertical9x16,
        resolution: ResolutionPreset.res1080p,
        fps: 30,
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        globalFilter: VideoFilterPreset.warmSunset,
        videoClips: [
          const VideoClipModel(
            id: 'clip-1',
            sourcePath: 'assets/sample_cafe_intro.mp4',
            title: 'Cafe Entrance',
            startTime: Duration.zero,
            duration: Duration(seconds: 10),
            sourceDuration: Duration(seconds: 14),
            trimStart: Duration(seconds: 1),
            trimEnd: Duration(seconds: 3),
            filter: VideoFilterPreset.warmSunset,
          ),
          const VideoClipModel(
            id: 'clip-2',
            sourcePath: 'assets/sample_coffee_pour.mp4',
            title: 'Coffee Pouring',
            startTime: Duration(seconds: 10),
            duration: Duration(seconds: 9),
            sourceDuration: Duration(seconds: 12),
            trimStart: Duration.zero,
            trimEnd: Duration(seconds: 3),
            filter: VideoFilterPreset.warmSunset,
          ),
          const VideoClipModel(
            id: 'clip-3',
            sourcePath: 'assets/sample_cafe_smile.mp4',
            title: 'Smiling Portrait',
            startTime: Duration(seconds: 19),
            duration: Duration(seconds: 9),
            sourceDuration: Duration(seconds: 10),
            trimStart: Duration.zero,
            trimEnd: Duration(seconds: 1),
            filter: VideoFilterPreset.warmSunset,
          ),
        ],
        textOverlays: [
          const TextOverlayModel(
            id: 'text-1',
            text: 'A Beautiful Day ✨',
            startTime: Duration(seconds: 5),
            duration: Duration(seconds: 16),
            fontSize: 22,
            fontColorValue: 0xFFFFFFFF,
            backgroundColorValue: 0xCC7C3AED,
            positionX: 0.0,
            positionY: 0.45,
            animation: TextAnimationType.popIn,
          ),
        ],
        audioTracks: [
          AudioTrackModel(
            id: 'audio-1',
            title: 'Cafe Moments.mp3',
            sourcePath: 'assets/cafe_moments.mp3',
            type: AudioTrackType.music,
            startTime: Duration.zero,
            duration: const Duration(seconds: 28),
            volume: 0.85,
            waveformData: List.generate(
              32,
              (i) => 0.2 + (0.7 * (i % 5 == 0 ? 0.9 : (i % 3 == 0 ? 0.6 : 0.35))),
            ),
          ),
        ],
      ),

      // 2. Travel Edit
      ProjectModel(
        id: 'project-travel-edit',
        title: 'Travel Edit',
        aspectRatio: AspectRatioPreset.vertical9x16,
        resolution: ResolutionPreset.res1080p,
        fps: 30,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        globalFilter: VideoFilterPreset.cinematic,
        videoClips: [
          const VideoClipModel(
            id: 'clip-t1',
            sourcePath: 'assets/travel_mountain.mp4',
            title: 'Mountain Lake',
            startTime: Duration.zero,
            duration: Duration(seconds: 25),
            sourceDuration: Duration(seconds: 30),
            filter: VideoFilterPreset.cinematic,
          ),
          const VideoClipModel(
            id: 'clip-t2',
            sourcePath: 'assets/travel_sunset.mp4',
            title: 'Golden Peak',
            startTime: Duration(seconds: 25),
            duration: Duration(seconds: 20),
            sourceDuration: Duration(seconds: 22),
            filter: VideoFilterPreset.cinematic,
          ),
        ],
        textOverlays: [
          const TextOverlayModel(
            id: 'text-t1',
            text: 'A Brighter You 🏔️',
            startTime: Duration(seconds: 3),
            duration: Duration(seconds: 12),
            fontSize: 24,
            fontColorValue: 0xFFFFFFFF,
            backgroundColorValue: 0x990F172A,
            positionX: 0.0,
            positionY: -0.5,
          ),
        ],
        audioTracks: [
          AudioTrackModel(
            id: 'audio-t1',
            title: 'Wanderlust Ambient.mp3',
            sourcePath: 'assets/wanderlust.mp3',
            type: AudioTrackType.music,
            startTime: Duration.zero,
            duration: const Duration(seconds: 45),
            volume: 0.8,
            waveformData: List.generate(36, (i) => 0.3 + (i % 4 * 0.18)),
          ),
        ],
      ),

      // 3. Reels 2024
      ProjectModel(
        id: 'project-reels-2024',
        title: 'Reels 2024',
        aspectRatio: AspectRatioPreset.vertical9x16,
        resolution: ResolutionPreset.res1080p,
        fps: 60,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 3)),
        globalFilter: VideoFilterPreset.vividPop,
        videoClips: [
          const VideoClipModel(
            id: 'clip-r1',
            sourcePath: 'assets/reels_palm.mp4',
            title: 'Palm Beach Sunset',
            startTime: Duration.zero,
            duration: Duration(seconds: 32),
            sourceDuration: Duration(seconds: 40),
            filter: VideoFilterPreset.vividPop,
          ),
        ],
        textOverlays: [
          const TextOverlayModel(
            id: 'text-r1',
            text: 'Good Vibes Only 🌴',
            startTime: Duration(seconds: 2),
            duration: Duration(seconds: 15),
            fontSize: 26,
            fontColorValue: 0xFFFFDF00,
            positionX: 0.0,
            positionY: 0.3,
          ),
        ],
        audioTracks: [
          AudioTrackModel(
            id: 'audio-r1',
            title: 'Summer Beats.mp3',
            sourcePath: 'assets/summer_beats.mp3',
            type: AudioTrackType.music,
            startTime: Duration.zero,
            duration: const Duration(seconds: 32),
            volume: 0.9,
            waveformData: List.generate(32, (i) => 0.4 + (i % 6 * 0.1)),
          ),
        ],
      ),
    ];
  }
}
