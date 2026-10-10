import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/video_clip.dart';
import '../models/text_overlay.dart';
import '../models/audio_track.dart';
import '../models/template.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/template_service.dart';

class ProjectProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  List<ProjectModel> _projects = [];
  ProjectModel? _activeProject;
  bool _isLoading = false;

  // Undo / Redo history stacks
  final List<ProjectModel> _undoStack = [];
  final List<ProjectModel> _redoStack = [];

  List<ProjectModel> get projects => _projects;
  ProjectModel? get activeProject => _activeProject;
  bool get isLoading => _isLoading;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _projects = await StorageService.loadProjects();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  void openProject(ProjectModel project) {
    _activeProject = project;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void _pushHistory() {
    if (_activeProject != null) {
      _undoStack.add(_activeProject!);
      if (_undoStack.length > 25) {
        _undoStack.removeAt(0);
      }
      _redoStack.clear();
    }
  }

  void undo() {
    if (!canUndo || _activeProject == null) return;
    _redoStack.add(_activeProject!);
    _activeProject = _undoStack.removeLast();
    _saveAndNotify();
  }

  void redo() {
    if (!canRedo || _activeProject == null) return;
    _undoStack.add(_activeProject!);
    _activeProject = _redoStack.removeLast();
    _saveAndNotify();
  }

  void _saveAndNotify() {
    if (_activeProject != null) {
      _updateInList(_activeProject!);
      StorageService.saveProject(_activeProject!);
    }
    notifyListeners();
  }

  void _updateInList(ProjectModel project) {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      _projects[idx] = project;
    } else {
      _projects.insert(0, project);
    }
  }

  ProjectModel createNewProject({
    String title = 'Untitled Project',
    AspectRatioPreset ratio = AspectRatioPreset.vertical9x16,
  }) {
    final now = DateTime.now();
    final newProject = ProjectModel(
      id: _uuid.v4(),
      title: title,
      aspectRatio: ratio,
      resolution: ResolutionPreset.res1080p,
      fps: 30,
      createdAt: now,
      updatedAt: now,
      videoClips: [],
      textOverlays: [],
      audioTracks: [],
    );

    _projects.insert(0, newProject);
    openProject(newProject);
    StorageService.saveProject(newProject);
    notifyListeners();
    return newProject;
  }

  ProjectModel createFromTemplate(VideoTemplateModel template) {
    final project = TemplateService.createProjectFromTemplate(template);
    _projects.insert(0, project);
    openProject(project);
    StorageService.saveProject(project);
    notifyListeners();
    return project;
  }

  void updateTitle(String newTitle) {
    if (_activeProject == null || newTitle.trim().isEmpty) return;
    _pushHistory();
    _activeProject = _activeProject!.copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateAspectRatio(AspectRatioPreset ratio) {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = _activeProject!.copyWith(
      aspectRatio: ratio,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateResolution(ResolutionPreset res, int fps) {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = _activeProject!.copyWith(
      resolution: res,
      fps: fps,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateGlobalFilter(VideoFilterPreset filter) {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = _activeProject!.copyWith(
      globalFilter: filter,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  // --- Video Clips Management ---
  void addVideoClip(VideoClipModel clip) {
    if (_activeProject == null) return;
    _pushHistory();

    final currentClips = List<VideoClipModel>.from(_activeProject!.videoClips);
    // Position new clip after the last clip
    Duration start = Duration.zero;
    if (currentClips.isNotEmpty) {
      start = currentClips.last.endTime;
    }

    currentClips.add(clip.copyWith(startTime: start));
    _activeProject = _activeProject!.copyWith(
      videoClips: currentClips,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateVideoClip(VideoClipModel updated) {
    if (_activeProject == null) return;
    _pushHistory();

    final clips = _activeProject!.videoClips.map((c) {
      return c.id == updated.id ? updated : c;
    }).toList();

    _activeProject = _activeProject!.copyWith(
      videoClips: clips,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void removeVideoClip(String clipId) {
    if (_activeProject == null) return;
    _pushHistory();

    final currentClips = _activeProject!.videoClips.where((c) => c.id != clipId).toList();
    // Re-pack remaining clips sequentially
    final reorderedClips = <VideoClipModel>[];
    Duration pos = Duration.zero;
    for (final c in currentClips) {
      reorderedClips.add(c.copyWith(startTime: pos));
      pos += c.duration;
    }

    _activeProject = _activeProject!.copyWith(
      videoClips: reorderedClips,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  /// Split a clip at a specific timeline timestamp
  bool splitClipAtPosition(String clipId, Duration timelinePos) {
    if (_activeProject == null) return false;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return false;

    final targetClip = _activeProject!.videoClips[index];
    if (timelinePos <= targetClip.startTime || timelinePos >= targetClip.endTime) {
      return false; // Point is not within the clip
    }

    _pushHistory();

    final firstDuration = timelinePos - targetClip.startTime;
    final secondDuration = targetClip.duration - firstDuration;

    final clip1 = targetClip.copyWith(
      duration: firstDuration,
      trimEnd: targetClip.trimEnd + secondDuration,
    );

    final clip2 = targetClip.copyWith(
      id: _uuid.v4(),
      title: '${targetClip.title} (Part 2)',
      startTime: timelinePos,
      duration: secondDuration,
      trimStart: targetClip.trimStart + firstDuration,
    );

    final updatedClips = List<VideoClipModel>.from(_activeProject!.videoClips);
    updatedClips[index] = clip1;
    updatedClips.insert(index + 1, clip2);

    _activeProject = _activeProject!.copyWith(
      videoClips: updatedClips,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
    return true;
  }

  // --- Text Overlay Management ---
  void addTextOverlay(TextOverlayModel text) {
    if (_activeProject == null) return;
    _pushHistory();

    final texts = List<TextOverlayModel>.from(_activeProject!.textOverlays)..add(text);
    _activeProject = _activeProject!.copyWith(
      textOverlays: texts,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateTextOverlay(TextOverlayModel updated) {
    if (_activeProject == null) return;
    _pushHistory();

    final texts = _activeProject!.textOverlays.map((t) {
      return t.id == updated.id ? updated : t;
    }).toList();

    _activeProject = _activeProject!.copyWith(
      textOverlays: texts,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void removeTextOverlay(String id) {
    if (_activeProject == null) return;
    _pushHistory();

    final texts = _activeProject!.textOverlays.where((t) => t.id != id).toList();
    _activeProject = _activeProject!.copyWith(
      textOverlays: texts,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  // --- Audio Track Management ---
  void addAudioTrack(AudioTrackModel audio) {
    if (_activeProject == null) return;
    _pushHistory();

    final audios = List<AudioTrackModel>.from(_activeProject!.audioTracks)..add(audio);
    _activeProject = _activeProject!.copyWith(
      audioTracks: audios,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateAudioTrack(AudioTrackModel updated) {
    if (_activeProject == null) return;
    _pushHistory();

    final audios = _activeProject!.audioTracks.map((a) {
      return a.id == updated.id ? updated : a;
    }).toList();

    _activeProject = _activeProject!.copyWith(
      audioTracks: audios,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void removeAudioTrack(String id) {
    if (_activeProject == null) return;
    _pushHistory();

    final audios = _activeProject!.audioTracks.where((a) => a.id != id).toList();
    _activeProject = _activeProject!.copyWith(
      audioTracks: audios,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  // --- AI Actions ---
  void applyAutoCut() {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = AiService.applyAutoCut(_activeProject!);
    _saveAndNotify();
  }

  void applyAutoCaptions() {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = AiService.generateAutoCaptions(_activeProject!);
    _saveAndNotify();
  }

  void applyBeatSync() {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = AiService.applyBeatSync(_activeProject!);
    _saveAndNotify();
  }

  // --- Project Management ---
  Future<void> duplicateProject(String id) async {
    final original = _projects.firstWhere((p) => p.id == id);
    final copy = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _projects.insert(0, copy);
    await StorageService.saveProjects(_projects);
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    if (_activeProject?.id == id) {
      _activeProject = null;
    }
    await StorageService.deleteProject(id);
    notifyListeners();
  }
}
