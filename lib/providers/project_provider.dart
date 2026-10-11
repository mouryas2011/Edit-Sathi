import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/video_clip.dart';
import '../models/text_overlay.dart';
import '../models/audio_track.dart';
import '../models/shape_overlay.dart';
import '../models/adjustment_layer.dart';
import '../models/keyframe.dart';
import '../models/template.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/template_service.dart';
import '../services/thumbnail_service.dart';

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
    ResolutionPreset resolution = ResolutionPreset.res1080p,
    List<VideoClipModel> initialClips = const [],
  }) {
    final now = DateTime.now();
    final newProject = ProjectModel(
      id: _uuid.v4(),
      title: title,
      aspectRatio: ratio,
      resolution: resolution,
      fps: 30,
      createdAt: now,
      updatedAt: now,
      videoClips: List.from(initialClips),
      textOverlays: [],
      audioTracks: [],
    );

    _projects.insert(0, newProject);
    openProject(newProject);
    StorageService.saveProject(newProject);

    if (initialClips.isNotEmpty && initialClips.first.sourcePath.isNotEmpty && !initialClips.first.sourcePath.startsWith('assets/')) {
      ThumbnailService.generateVideoThumbnail(initialClips.first.sourcePath).then((thumb) {
        if (thumb != null) {
          updateProjectThumbnail(newProject.id, thumb);
        }
      });
    }

    notifyListeners();
    return newProject;
  }

  void updateProjectThumbnail(String projectId, String thumbnailPath) {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx >= 0) {
      _projects[idx] = _projects[idx].copyWith(customThumbnail: thumbnailPath);
      if (_activeProject?.id == projectId) {
        _activeProject = _activeProject!.copyWith(customThumbnail: thumbnailPath);
      }
      StorageService.saveProject(_projects[idx]);
      notifyListeners();
    }
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

  void updateClipTransform(
    String clipId, {
    double? scale,
    double? rotation,
    double? positionX,
    double? positionY,
    bool? flipHorizontal,
    bool? flipVertical,
  }) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;

    final old = _activeProject!.videoClips[index];
    final updated = old.copyWith(
      scale: scale ?? old.scale,
      rotation: rotation ?? old.rotation,
      positionX: positionX ?? old.positionX,
      positionY: positionY ?? old.positionY,
      flipHorizontal: flipHorizontal ?? old.flipHorizontal,
      flipVertical: flipVertical ?? old.flipVertical,
    );

    final currentClips = List<VideoClipModel>.from(_activeProject!.videoClips);
    currentClips[index] = updated;

    _activeProject = _activeProject!.copyWith(
      videoClips: currentClips,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void resetClipTransform(String clipId) {
    updateClipTransform(
      clipId,
      scale: 1.0,
      rotation: 0.0,
      positionX: 0.0,
      positionY: 0.0,
      flipHorizontal: false,
      flipVertical: false,
    );
    _saveAndNotify();
  }

  void updateClipSpeed(String clipId, double speed) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;
    final clip = _activeProject!.videoClips[index];
    updateVideoClip(clip.copyWith(speed: speed));
  }

  void updateClipFilter(String clipId, VideoFilterPreset filter) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;
    final clip = _activeProject!.videoClips[index];
    updateVideoClip(clip.copyWith(filter: filter));
  }

  void updateClipTransition(String clipId, TransitionType transition, {Duration? duration}) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;
    final clip = _activeProject!.videoClips[index];
    updateVideoClip(clip.copyWith(
      transition: transition,
      transitionDuration: duration ?? clip.transitionDuration,
    ));
  }

  void applyTransitionToAllClips(TransitionType transition, {Duration? duration}) {
    if (_activeProject == null) return;
    _pushHistory();

    final dur = duration ?? const Duration(milliseconds: 500);
    final updatedClips = _activeProject!.videoClips.map((c) {
      return c.copyWith(
        transition: transition,
        transitionDuration: dur,
      );
    }).toList();

    _activeProject = _activeProject!.copyWith(
      videoClips: updatedClips,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateClipSpeedCurve(String clipId, SpeedCurveType curve) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;
    final clip = _activeProject!.videoClips[index];
    updateVideoClip(clip.copyWith(speedCurve: curve));
  }

  void addOrUpdateKeyframe(String clipId, KeyframeModel keyframe) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;
    _pushHistory();

    final clip = _activeProject!.videoClips[index];
    final keyframes = List<KeyframeModel>.from(clip.keyframes);
    
    // Check if keyframe exists near this timestamp (within 60ms)
    final existingIndex = keyframes.indexWhere((k) => 
      (k.timeOffset - keyframe.timeOffset).inMilliseconds.abs() < 60);

    if (existingIndex >= 0) {
      keyframes[existingIndex] = keyframe;
    } else {
      keyframes.add(keyframe);
    }
    keyframes.sort((a, b) => a.timeOffset.compareTo(b.timeOffset));

    updateVideoClip(clip.copyWith(keyframes: keyframes));
  }

  void removeKeyframe(String clipId, String keyframeId) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;
    _pushHistory();

    final clip = _activeProject!.videoClips[index];
    final keyframes = clip.keyframes.where((k) => k.id != keyframeId).toList();
    updateVideoClip(clip.copyWith(keyframes: keyframes));
  }

  void removeKeyframeAtOffset(String clipId, Duration offset) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;
    _pushHistory();

    final clip = _activeProject!.videoClips[index];
    final keyframes = clip.keyframes.where((k) => 
      (k.timeOffset - offset).inMilliseconds.abs() >= 100).toList();
    updateVideoClip(clip.copyWith(keyframes: keyframes));
  }

  /// Premiere Pro style Ripple Delete: deletes clip and slides subsequent clips back
  void rippleDeleteClip(String clipId) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;
    _pushHistory();

    final targetClip = _activeProject!.videoClips[index];
    final targetTrack = targetClip.trackIndex;
    final deletedDuration = targetClip.duration;
    final targetStart = targetClip.startTime;

    final updatedClips = <VideoClipModel>[];
    for (final c in _activeProject!.videoClips) {
      if (c.id == clipId) continue;
      if (c.trackIndex == targetTrack && c.startTime > targetStart) {
        // Shift earlier by deleted duration
        final newStart = c.startTime - deletedDuration;
        updatedClips.add(c.copyWith(startTime: newStart < Duration.zero ? Duration.zero : newStart));
      } else {
        updatedClips.add(c);
      }
    }

    _activeProject = _activeProject!.copyWith(
      videoClips: updatedClips,
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

  /// Move a video clip along the timeline (and optionally between video tracks)
  void moveVideoClip(String clipId, Duration newStartTime, {int? newTrackIndex}) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;

    final old = _activeProject!.videoClips[index];
    final safeStart = newStartTime < Duration.zero ? Duration.zero : newStartTime;
    final targetTrack = newTrackIndex ?? old.trackIndex;

    int trackCount = _activeProject!.videoTrackCount;
    if (targetTrack >= trackCount) {
      trackCount = targetTrack + 1;
    }

    final updated = old.copyWith(
      startTime: safeStart,
      trackIndex: targetTrack,
    );

    final clips = List<VideoClipModel>.from(_activeProject!.videoClips);
    clips[index] = updated;

    _activeProject = _activeProject!.copyWith(
      videoClips: clips,
      videoTrackCount: trackCount,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Commit the moved clip position to history and persistent storage
  void commitVideoClipMove(String clipId) {
    if (_activeProject == null) return;
    _pushHistory();
    _saveAndNotify();
  }

  /// Trim the in-point (start) of a video clip interactively
  void trimVideoClipStart(String clipId, Duration delta) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;

    final clip = _activeProject!.videoClips[index];
    final newTrimStart = clip.trimStart + delta;
    final newDuration = clip.duration - delta;

    if (newDuration < const Duration(milliseconds: 200) || newTrimStart < Duration.zero) {
      return;
    }

    final newStartTime = clip.startTime + delta;
    if (newStartTime < Duration.zero) return;

    final updated = clip.copyWith(
      startTime: newStartTime,
      duration: newDuration,
      trimStart: newTrimStart,
    );

    final clips = List<VideoClipModel>.from(_activeProject!.videoClips);
    clips[index] = updated;

    _activeProject = _activeProject!.copyWith(
      videoClips: clips,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Trim the out-point (end) of a video clip interactively
  void trimVideoClipEnd(String clipId, Duration newDuration) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;

    final clip = _activeProject!.videoClips[index];
    final clampedDuration = newDuration < const Duration(milliseconds: 200)
        ? const Duration(milliseconds: 200)
        : newDuration;

    final maxAvail = clip.sourceDuration - clip.trimStart;
    final safeDuration = (clip.sourceDuration > Duration.zero && clampedDuration > maxAvail)
        ? maxAvail
        : clampedDuration;

    final updated = clip.copyWith(
      duration: safeDuration,
      trimEnd: (clip.sourceDuration > safeDuration) ? (clip.sourceDuration - clip.trimStart - safeDuration) : Duration.zero,
    );

    final clips = List<VideoClipModel>.from(_activeProject!.videoClips);
    clips[index] = updated;

    _activeProject = _activeProject!.copyWith(
      videoClips: clips,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Duplicate a video clip and place it directly adjacent to it
  void duplicateVideoClip(String clipId) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;

    _pushHistory();
    final original = _activeProject!.videoClips[index];
    final duplicated = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      startTime: original.endTime,
    );

    final clips = List<VideoClipModel>.from(_activeProject!.videoClips);
    clips.insert(index + 1, duplicated);

    _activeProject = _activeProject!.copyWith(
      videoClips: clips,
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

  /// Split whatever clip is under the playhead (optionally specifying track index)
  bool splitClipAtPlayhead(Duration playhead, {int? targetTrackIndex}) {
    if (_activeProject == null) return false;
    final candidateClips = _activeProject!.videoClips.where((c) {
      if (targetTrackIndex != null && c.trackIndex != targetTrackIndex) return false;
      return playhead > c.startTime && playhead < c.endTime;
    }).toList();

    if (candidateClips.isEmpty) return false;
    // Prefer the clip on the highest track (or targetTrackIndex)
    candidateClips.sort((a, b) => b.trackIndex.compareTo(a.trackIndex));
    return splitClipAtPosition(candidateClips.first.id, playhead);
  }

  /// Add a video clip specifically to a target track at a specific timestamp or end of track
  void addVideoClipToTrack(VideoClipModel clip, {int trackIndex = 0, Duration? startTime}) {
    if (_activeProject == null) return;
    _pushHistory();

    final currentClips = List<VideoClipModel>.from(_activeProject!.videoClips);
    final trackClips = currentClips.where((c) => c.trackIndex == trackIndex).toList();

    Duration start = startTime ?? Duration.zero;
    if (startTime == null && trackClips.isNotEmpty) {
      start = trackClips.last.endTime;
    }

    // Auto-expand track count if needed
    int trackCount = _activeProject!.videoTrackCount;
    if (trackIndex >= trackCount) {
      trackCount = trackIndex + 1;
    }

    currentClips.add(clip.copyWith(
      trackIndex: trackIndex,
      startTime: start,
    ));

    _activeProject = _activeProject!.copyWith(
      videoClips: currentClips,
      videoTrackCount: trackCount,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  /// Add an audio track specifically to a target track at a specific timestamp or end of track
  void addAudioClipToTrack(AudioTrackModel audio, {int trackIndex = 0, Duration? startTime}) {
    if (_activeProject == null) return;
    _pushHistory();

    final currentAudios = List<AudioTrackModel>.from(_activeProject!.audioTracks);
    final trackAudios = currentAudios.where((a) => a.trackIndex == trackIndex).toList();

    Duration start = startTime ?? Duration.zero;
    if (startTime == null && trackAudios.isNotEmpty) {
      start = trackAudios.last.endTime;
    }

    int trackCount = _activeProject!.audioTrackCount;
    if (trackIndex >= trackCount) {
      trackCount = trackIndex + 1;
    }

    currentAudios.add(audio.copyWith(
      trackIndex: trackIndex,
      startTime: start,
    ));

    _activeProject = _activeProject!.copyWith(
      audioTracks: currentAudios,
      audioTrackCount: trackCount,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  /// Move clip to a new start time and optionally change track
  void moveClip(String clipId, Duration newStartTime, [int? newTrackIndex]) {
    if (_activeProject == null) return;
    final index = _activeProject!.videoClips.indexWhere((c) => c.id == clipId);
    if (index < 0) return;

    _pushHistory();
    final old = _activeProject!.videoClips[index];
    final updated = old.copyWith(
      startTime: newStartTime < Duration.zero ? Duration.zero : newStartTime,
      trackIndex: newTrackIndex ?? old.trackIndex,
    );

    final currentClips = List<VideoClipModel>.from(_activeProject!.videoClips);
    currentClips[index] = updated;

    _activeProject = _activeProject!.copyWith(
      videoClips: currentClips,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  /// Move audio track to a new start time and optionally change track
  void moveAudioTrackItem(String audioId, Duration newStartTime, [int? newTrackIndex]) {
    if (_activeProject == null) return;
    final index = _activeProject!.audioTracks.indexWhere((a) => a.id == audioId);
    if (index < 0) return;

    _pushHistory();
    final old = _activeProject!.audioTracks[index];
    final updated = old.copyWith(
      startTime: newStartTime < Duration.zero ? Duration.zero : newStartTime,
      trackIndex: newTrackIndex ?? old.trackIndex,
    );

    final currentAudios = List<AudioTrackModel>.from(_activeProject!.audioTracks);
    currentAudios[index] = updated;

    _activeProject = _activeProject!.copyWith(
      audioTracks: currentAudios,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void moveAudioClip(String audioId, Duration newStartTime, {int? newTrackIndex}) {
    moveAudioTrackItem(audioId, newStartTime, newTrackIndex);
  }

  void trimAudioClip(String audioId, Duration newDuration) {
    if (_activeProject == null) return;
    final index = _activeProject!.audioTracks.indexWhere((a) => a.id == audioId);
    if (index < 0) return;

    final old = _activeProject!.audioTracks[index];
    final safeDuration = newDuration < const Duration(milliseconds: 300)
        ? const Duration(milliseconds: 300)
        : newDuration;

    final updated = old.copyWith(duration: safeDuration);
    final audios = List<AudioTrackModel>.from(_activeProject!.audioTracks);
    audios[index] = updated;

    _activeProject = _activeProject!.copyWith(
      audioTracks: audios,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void commitAudioClipMove(String audioId) {
    if (_activeProject == null) return;
    _pushHistory();
    _saveAndNotify();
  }

  void trimAudioClipStart(String audioId, Duration delta) {
    if (_activeProject == null) return;
    final index = _activeProject!.audioTracks.indexWhere((a) => a.id == audioId);
    if (index < 0) return;

    final old = _activeProject!.audioTracks[index];
    final newDuration = old.duration - delta;
    if (newDuration < const Duration(milliseconds: 300)) return;

    final newStartTime = old.startTime + delta;
    if (newStartTime < Duration.zero) return;

    final updated = old.copyWith(
      startTime: newStartTime,
      duration: newDuration,
    );
    final audios = List<AudioTrackModel>.from(_activeProject!.audioTracks);
    audios[index] = updated;

    _activeProject = _activeProject!.copyWith(
      audioTracks: audios,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  bool splitAudioClipAtPosition(String audioId, Duration timelinePos) {
    if (_activeProject == null) return false;
    final index = _activeProject!.audioTracks.indexWhere((a) => a.id == audioId);
    if (index < 0) return false;

    final targetAudio = _activeProject!.audioTracks[index];
    if (timelinePos <= targetAudio.startTime || timelinePos >= targetAudio.endTime) {
      return false;
    }

    _pushHistory();
    final firstDuration = timelinePos - targetAudio.startTime;
    final secondDuration = targetAudio.duration - firstDuration;

    final audio1 = targetAudio.copyWith(
      duration: firstDuration,
    );
    final audio2 = targetAudio.copyWith(
      id: _uuid.v4(),
      title: '${targetAudio.title} (Part 2)',
      startTime: timelinePos,
      duration: secondDuration,
    );

    final audios = List<AudioTrackModel>.from(_activeProject!.audioTracks);
    audios[index] = audio1;
    audios.insert(index + 1, audio2);

    _activeProject = _activeProject!.copyWith(
      audioTracks: audios,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
    return true;
  }

  void duplicateAudioClip(String audioId) {
    if (_activeProject == null) return;
    final index = _activeProject!.audioTracks.indexWhere((a) => a.id == audioId);
    if (index < 0) return;

    _pushHistory();
    final original = _activeProject!.audioTracks[index];
    final duplicated = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      startTime: original.endTime,
    );

    final audios = List<AudioTrackModel>.from(_activeProject!.audioTracks);
    audios.insert(index + 1, duplicated);

    _activeProject = _activeProject!.copyWith(
      audioTracks: audios,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  // --- Multi-Track Add & Header State Management ---
  void addVideoTrack() {
    if (_activeProject == null) return;
    _pushHistory();
    final currentCount = _activeProject!.videoTrackCount;
    _activeProject = _activeProject!.copyWith(
      videoTrackCount: (currentCount + 1).clamp(1, 8),
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void addAudioTrackLane() {
    if (_activeProject == null) return;
    _pushHistory();
    final currentCount = _activeProject!.audioTrackCount;
    _activeProject = _activeProject!.copyWith(
      audioTrackCount: (currentCount + 1).clamp(1, 8),
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void toggleMuteVideoTrack(int trackIndex) {
    if (_activeProject == null) return;
    _pushHistory();
    final list = List<int>.from(_activeProject!.mutedVideoTracks);
    if (list.contains(trackIndex)) {
      list.remove(trackIndex);
    } else {
      list.add(trackIndex);
    }
    _activeProject = _activeProject!.copyWith(
      mutedVideoTracks: list,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void toggleHideVideoTrack(int trackIndex) {
    if (_activeProject == null) return;
    _pushHistory();
    final list = List<int>.from(_activeProject!.hiddenVideoTracks);
    if (list.contains(trackIndex)) {
      list.remove(trackIndex);
    } else {
      list.add(trackIndex);
    }
    _activeProject = _activeProject!.copyWith(
      hiddenVideoTracks: list,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void toggleLockVideoTrack(int trackIndex) {
    if (_activeProject == null) return;
    _pushHistory();
    final list = List<int>.from(_activeProject!.lockedVideoTracks);
    if (list.contains(trackIndex)) {
      list.remove(trackIndex);
    } else {
      list.add(trackIndex);
    }
    _activeProject = _activeProject!.copyWith(
      lockedVideoTracks: list,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void toggleMuteAudioTrack(int trackIndex) {
    if (_activeProject == null) return;
    _pushHistory();
    final list = List<int>.from(_activeProject!.mutedAudioTracks);
    if (list.contains(trackIndex)) {
      list.remove(trackIndex);
    } else {
      list.add(trackIndex);
    }
    _activeProject = _activeProject!.copyWith(
      mutedAudioTracks: list,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void toggleLockAudioTrack(int trackIndex) {
    if (_activeProject == null) return;
    _pushHistory();
    final list = List<int>.from(_activeProject!.lockedAudioTracks);
    if (list.contains(trackIndex)) {
      list.remove(trackIndex);
    } else {
      list.add(trackIndex);
    }
    _activeProject = _activeProject!.copyWith(
      lockedAudioTracks: list,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
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

  void moveTextOverlay(String textId, Duration newStartTime) {
    if (_activeProject == null) return;
    final index = _activeProject!.textOverlays.indexWhere((t) => t.id == textId);
    if (index < 0) return;

    final old = _activeProject!.textOverlays[index];
    final updated = old.copyWith(startTime: newStartTime < Duration.zero ? Duration.zero : newStartTime);
    final texts = List<TextOverlayModel>.from(_activeProject!.textOverlays);
    texts[index] = updated;

    _activeProject = _activeProject!.copyWith(textOverlays: texts, updatedAt: DateTime.now());
    notifyListeners();
  }

  void commitTextOverlayMove(String textId) {
    if (_activeProject == null) return;
    _pushHistory();
    _saveAndNotify();
  }

  void trimTextOverlayStart(String textId, Duration delta) {
    if (_activeProject == null) return;
    final index = _activeProject!.textOverlays.indexWhere((t) => t.id == textId);
    if (index < 0) return;

    final old = _activeProject!.textOverlays[index];
    final newDuration = old.duration - delta;
    if (newDuration < const Duration(milliseconds: 300)) return;

    final newStartTime = old.startTime + delta;
    if (newStartTime < Duration.zero) return;

    final updated = old.copyWith(
      startTime: newStartTime,
      duration: newDuration,
    );
    final texts = List<TextOverlayModel>.from(_activeProject!.textOverlays);
    texts[index] = updated;

    _activeProject = _activeProject!.copyWith(textOverlays: texts, updatedAt: DateTime.now());
    notifyListeners();
  }

  void trimTextOverlay(String textId, Duration newDuration) {
    if (_activeProject == null) return;
    final index = _activeProject!.textOverlays.indexWhere((t) => t.id == textId);
    if (index < 0) return;

    final old = _activeProject!.textOverlays[index];
    final safeDuration = newDuration < const Duration(milliseconds: 300) ? const Duration(milliseconds: 300) : newDuration;
    final updated = old.copyWith(duration: safeDuration);
    final texts = List<TextOverlayModel>.from(_activeProject!.textOverlays);
    texts[index] = updated;

    _activeProject = _activeProject!.copyWith(textOverlays: texts, updatedAt: DateTime.now());
    notifyListeners();
  }

  void duplicateTextOverlay(String textId) {
    if (_activeProject == null) return;
    final index = _activeProject!.textOverlays.indexWhere((t) => t.id == textId);
    if (index < 0) return;

    _pushHistory();
    final original = _activeProject!.textOverlays[index];
    final duplicated = original.copyWith(
      id: _uuid.v4(),
      startTime: original.endTime,
    );

    final texts = List<TextOverlayModel>.from(_activeProject!.textOverlays);
    texts.insert(index + 1, duplicated);

    _activeProject = _activeProject!.copyWith(textOverlays: texts, updatedAt: DateTime.now());
    _saveAndNotify();
  }

  // --- Shapes Management ---
  void addShape(ShapeOverlayModel shape) {
    if (_activeProject == null) return;
    _pushHistory();

    final shapes = List<ShapeOverlayModel>.from(_activeProject!.shapes)..add(shape);
    _activeProject = _activeProject!.copyWith(
      shapes: shapes,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateShape(ShapeOverlayModel updated) {
    if (_activeProject == null) return;
    _pushHistory();

    final shapes = _activeProject!.shapes.map((s) {
      return s.id == updated.id ? updated : s;
    }).toList();

    _activeProject = _activeProject!.copyWith(
      shapes: shapes,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void removeShape(String id) {
    if (_activeProject == null) return;
    _pushHistory();

    final shapes = _activeProject!.shapes.where((s) => s.id != id).toList();
    _activeProject = _activeProject!.copyWith(
      shapes: shapes,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void moveShape(String shapeId, Duration newStartTime) {
    if (_activeProject == null) return;
    final index = _activeProject!.shapes.indexWhere((s) => s.id == shapeId);
    if (index < 0) return;

    final old = _activeProject!.shapes[index];
    final updated = old.copyWith(startTime: newStartTime < Duration.zero ? Duration.zero : newStartTime);
    final shapes = List<ShapeOverlayModel>.from(_activeProject!.shapes);
    shapes[index] = updated;

    _activeProject = _activeProject!.copyWith(shapes: shapes, updatedAt: DateTime.now());
    notifyListeners();
  }

  void commitShapeMove(String shapeId) {
    if (_activeProject == null) return;
    _pushHistory();
    _saveAndNotify();
  }

  void trimShapeStart(String shapeId, Duration delta) {
    if (_activeProject == null) return;
    final index = _activeProject!.shapes.indexWhere((s) => s.id == shapeId);
    if (index < 0) return;

    final old = _activeProject!.shapes[index];
    final newDuration = old.duration - delta;
    if (newDuration < const Duration(milliseconds: 300)) return;

    final newStartTime = old.startTime + delta;
    if (newStartTime < Duration.zero) return;

    final updated = old.copyWith(
      startTime: newStartTime,
      duration: newDuration,
    );
    final shapes = List<ShapeOverlayModel>.from(_activeProject!.shapes);
    shapes[index] = updated;

    _activeProject = _activeProject!.copyWith(shapes: shapes, updatedAt: DateTime.now());
    notifyListeners();
  }

  void trimShape(String shapeId, Duration newDuration) {
    if (_activeProject == null) return;
    final index = _activeProject!.shapes.indexWhere((s) => s.id == shapeId);
    if (index < 0) return;

    final old = _activeProject!.shapes[index];
    final safeDuration = newDuration < const Duration(milliseconds: 300) ? const Duration(milliseconds: 300) : newDuration;
    final updated = old.copyWith(duration: safeDuration);
    final shapes = List<ShapeOverlayModel>.from(_activeProject!.shapes);
    shapes[index] = updated;

    _activeProject = _activeProject!.copyWith(shapes: shapes, updatedAt: DateTime.now());
    notifyListeners();
  }

  void duplicateShape(String shapeId) {
    if (_activeProject == null) return;
    final index = _activeProject!.shapes.indexWhere((s) => s.id == shapeId);
    if (index < 0) return;

    _pushHistory();
    final original = _activeProject!.shapes[index];
    final duplicated = original.copyWith(
      id: _uuid.v4(),
      startTime: original.endTime,
    );

    final shapes = List<ShapeOverlayModel>.from(_activeProject!.shapes);
    shapes.insert(index + 1, duplicated);

    _activeProject = _activeProject!.copyWith(shapes: shapes, updatedAt: DateTime.now());
    _saveAndNotify();
  }

  // --- Adjustment Layer Management ---
  void addAdjustmentLayer(AdjustmentLayerModel layer) {
    if (_activeProject == null) return;
    _pushHistory();

    final layers = List<AdjustmentLayerModel>.from(_activeProject!.adjustmentLayers)..add(layer);
    _activeProject = _activeProject!.copyWith(
      adjustmentLayers: layers,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateAdjustmentLayer(AdjustmentLayerModel updated) {
    if (_activeProject == null) return;
    _pushHistory();

    final layers = _activeProject!.adjustmentLayers.map((l) {
      return l.id == updated.id ? updated : l;
    }).toList();

    _activeProject = _activeProject!.copyWith(
      adjustmentLayers: layers,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void removeAdjustmentLayer(String id) {
    if (_activeProject == null) return;
    _pushHistory();

    final layers = _activeProject!.adjustmentLayers.where((l) => l.id != id).toList();
    _activeProject = _activeProject!.copyWith(
      adjustmentLayers: layers,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void moveAdjustmentLayer(String layerId, Duration newStartTime) {
    if (_activeProject == null) return;
    final index = _activeProject!.adjustmentLayers.indexWhere((l) => l.id == layerId);
    if (index < 0) return;

    final old = _activeProject!.adjustmentLayers[index];
    final updated = old.copyWith(startTime: newStartTime < Duration.zero ? Duration.zero : newStartTime);
    final layers = List<AdjustmentLayerModel>.from(_activeProject!.adjustmentLayers);
    layers[index] = updated;

    _activeProject = _activeProject!.copyWith(adjustmentLayers: layers, updatedAt: DateTime.now());
    notifyListeners();
  }

  void commitAdjustmentLayerMove(String layerId) {
    if (_activeProject == null) return;
    _pushHistory();
    _saveAndNotify();
  }

  void trimAdjustmentLayerStart(String layerId, Duration delta) {
    if (_activeProject == null) return;
    final index = _activeProject!.adjustmentLayers.indexWhere((l) => l.id == layerId);
    if (index < 0) return;

    final old = _activeProject!.adjustmentLayers[index];
    final newDuration = old.duration - delta;
    if (newDuration < const Duration(milliseconds: 300)) return;

    final newStartTime = old.startTime + delta;
    if (newStartTime < Duration.zero) return;

    final updated = old.copyWith(
      startTime: newStartTime,
      duration: newDuration,
    );
    final layers = List<AdjustmentLayerModel>.from(_activeProject!.adjustmentLayers);
    layers[index] = updated;

    _activeProject = _activeProject!.copyWith(adjustmentLayers: layers, updatedAt: DateTime.now());
    notifyListeners();
  }

  void trimAdjustmentLayer(String layerId, Duration newDuration) {
    if (_activeProject == null) return;
    final index = _activeProject!.adjustmentLayers.indexWhere((l) => l.id == layerId);
    if (index < 0) return;

    final old = _activeProject!.adjustmentLayers[index];
    final safeDuration = newDuration < const Duration(milliseconds: 300) ? const Duration(milliseconds: 300) : newDuration;
    final updated = old.copyWith(duration: safeDuration);
    final layers = List<AdjustmentLayerModel>.from(_activeProject!.adjustmentLayers);
    layers[index] = updated;

    _activeProject = _activeProject!.copyWith(adjustmentLayers: layers, updatedAt: DateTime.now());
    notifyListeners();
  }

  void duplicateAdjustmentLayer(String layerId) {
    if (_activeProject == null) return;
    final index = _activeProject!.adjustmentLayers.indexWhere((l) => l.id == layerId);
    if (index < 0) return;

    _pushHistory();
    final original = _activeProject!.adjustmentLayers[index];
    final duplicated = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      startTime: original.endTime,
    );

    final layers = List<AdjustmentLayerModel>.from(_activeProject!.adjustmentLayers);
    layers.insert(index + 1, duplicated);

    _activeProject = _activeProject!.copyWith(adjustmentLayers: layers, updatedAt: DateTime.now());
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

  void updateAudioStudio(
    String audioId, {
    double? volume,
    Duration? fadeIn,
    Duration? fadeOut,
    VoiceEffectPreset? effect,
  }) {
    if (_activeProject == null) return;
    final index = _activeProject!.audioTracks.indexWhere((a) => a.id == audioId);
    if (index < 0) return;
    _pushHistory();

    final audio = _activeProject!.audioTracks[index];
    final updated = audio.copyWith(
      volume: volume ?? audio.volume,
      fadeInDuration: fadeIn ?? audio.fadeInDuration,
      fadeOutDuration: fadeOut ?? audio.fadeOutDuration,
      voiceEffect: effect ?? audio.voiceEffect,
    );

    final audios = List<AudioTrackModel>.from(_activeProject!.audioTracks);
    audios[index] = updated;

    _activeProject = _activeProject!.copyWith(
      audioTracks: audios,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  void updateCanvasBackground({
    required CanvasBgType bgType,
    int? colorValue,
    int? gradientIndex,
    double? blurSigma,
  }) {
    if (_activeProject == null) return;
    _pushHistory();

    _activeProject = _activeProject!.copyWith(
      canvasBgType: bgType,
      canvasColorValue: colorValue ?? _activeProject!.canvasColorValue,
      canvasGradientIndex: gradientIndex ?? _activeProject!.canvasGradientIndex,
      canvasBlurSigma: blurSigma ?? _activeProject!.canvasBlurSigma,
      updatedAt: DateTime.now(),
    );
    _saveAndNotify();
  }

  // --- AI Actions ---
  void applyAutoCut() {
    if (_activeProject == null) return;
    _pushHistory();
    final silences = AiService.detectSilenceIntervals(_activeProject!);
    _activeProject = AiService.applySilenceJumpCuts(
      project: _activeProject!,
      selectedSilences: silences,
    );
    _saveAndNotify();
  }

  void applyCustomCaptions(List<AiCaptionSegment> captions, CaptionStylePreset style) {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = AiService.applyCaptionsToProject(
      project: _activeProject!,
      captions: captions,
      style: style,
    );
    _saveAndNotify();
  }

  void applySilenceCuts(List<SilenceSection> silences) {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = AiService.applySilenceJumpCuts(
      project: _activeProject!,
      selectedSilences: silences,
    );
    _saveAndNotify();
  }

  void applyAudioNormalization() {
    if (_activeProject == null) return;
    _pushHistory();
    _activeProject = AiService.normalizeAudio(_activeProject!);
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
