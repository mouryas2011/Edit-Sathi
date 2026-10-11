import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../models/video_clip.dart';
import '../../../../providers/timeline_provider.dart';
import '../../../../providers/project_provider.dart';
import '../../../../services/media_picker_service.dart';
import '../../../../theme/app_colors.dart';
import 'sheets/text_edit_sheet.dart';

class VideoPreviewCanvas extends StatefulWidget {
  const VideoPreviewCanvas({super.key});

  @override
  State<VideoPreviewCanvas> createState() => _VideoPreviewCanvasState();
}

class _VideoPreviewCanvasState extends State<VideoPreviewCanvas> {
  VideoPlayerController? _controller;
  String? _loadedClipId;
  String? _loadedClipPath;
  bool _isControllerInitializing = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  ColorFilter? _getColorFilter(VideoFilterPreset filter) {
    switch (filter) {
      case VideoFilterPreset.none:
        return null;
      case VideoFilterPreset.warmSunset:
        return const ColorFilter.matrix(<double>[
          1.2, 0.0, 0.0, 0.0, 15,
          0.0, 1.0, 0.0, 0.0, 5,
          0.0, 0.0, 0.8, 0.0, -10,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case VideoFilterPreset.cinematic:
        return const ColorFilter.matrix(<double>[
          0.9, 0.0, 0.0, 0.0, -5,
          0.0, 1.05, 0.0, 0.0, 0,
          0.0, 0.0, 1.25, 0.0, 15,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case VideoFilterPreset.coolBlue:
        return const ColorFilter.matrix(<double>[
          0.85, 0.0, 0.0, 0.0, -10,
          0.0, 0.95, 0.0, 0.0, 0,
          0.0, 0.0, 1.3, 0.0, 20,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case VideoFilterPreset.retroVintage:
        return const ColorFilter.matrix(<double>[
          1.1, 0.1, 0.0, 0.0, 20,
          0.1, 1.0, 0.1, 0.0, 10,
          0.0, 0.1, 0.8, 0.0, -15,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case VideoFilterPreset.blackAndWhite:
        return const ColorFilter.matrix(<double>[
          0.33, 0.59, 0.11, 0.0, 0,
          0.33, 0.59, 0.11, 0.0, 0,
          0.33, 0.59, 0.11, 0.0, 0,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
      case VideoFilterPreset.vividPop:
        return const ColorFilter.matrix(<double>[
          1.3, 0.0, 0.0, 0.0, 10,
          0.0, 1.3, 0.0, 0.0, 10,
          0.0, 0.0, 1.3, 0.0, 10,
          0.0, 0.0, 0.0, 1.0, 0,
        ]);
    }
  }

  Future<VideoPlayerController?> _resolveAndCreateController(String path) async {
    try {
      if (kIsWeb) {
        return VideoPlayerController.networkUrl(Uri.parse(path));
      }
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return VideoPlayerController.networkUrl(Uri.parse(path));
      }
      if (path.startsWith('assets/')) {
        return VideoPlayerController.asset(path);
      }
      if (path.startsWith('file://')) {
        final f = File(Uri.parse(path).toFilePath());
        if (await f.exists()) return VideoPlayerController.file(f);
      }
      if (path.startsWith('content://')) {
        return VideoPlayerController.contentUri(Uri.parse(path));
      }

      // 1. Direct file path check
      final file = File(path);
      if (await file.exists()) {
        return VideoPlayerController.file(file);
      }

      // 2. Search imported_videos sandbox directory for matching filename
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/imported_videos');
      if (await videosDir.exists()) {
        final basename = path.split(RegExp(r'[/\\]')).last;
        final list = videosDir.listSync().whereType<File>();
        final match = list.where((f) => f.path.endsWith(basename) || f.path.contains(basename)).firstOrNull;
        if (match != null && await match.exists()) {
          return VideoPlayerController.file(match);
        }
      }

      // 3. Search cache directory
      final cacheDir = await getTemporaryDirectory();
      final cacheFile = File('${cacheDir.path}/${path.split(RegExp(r'[/\\]')).last}');
      if (await cacheFile.exists()) {
        return VideoPlayerController.file(cacheFile);
      }

      // 4. Try as content URI if it has any valid URI structure
      final uri = Uri.tryParse(path);
      if (uri != null && uri.hasScheme) {
        return VideoPlayerController.contentUri(uri);
      }
    } catch (e) {
      debugPrint('Error finding video for path $path: $e');
    }
    return null;
  }

  void _onPlayerTick() {
    if (!mounted || _controller == null || !_controller!.value.isInitialized) return;
    final ctrl = _controller!;
    if (ctrl.value.isPlaying) {
      final timeline = context.read<TimelineProvider>();
      final project = context.read<ProjectProvider>().activeProject;
      if (project == null) return;

      final clip = project.videoClips.where((c) => c.id == _loadedClipId).firstOrNull;
      if (clip != null) {
        final pos = ctrl.value.position;
        final playedFromTrim = pos - clip.trimStart;
        final ms = (playedFromTrim.inMilliseconds / (clip.speed > 0 ? clip.speed : 1.0)).round();
        final timelinePos = clip.startTime + Duration(milliseconds: ms);

        // Check if clip has finished
        if (pos >= clip.trimStart + clip.duration) {
          final nextClips = project.videoClips
              .where((c) => !project.hiddenVideoTracks.contains(c.trackIndex) && c.startTime >= clip.endTime)
              .toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
          if (nextClips.isNotEmpty) {
            timeline.seekTo(nextClips.first.startTime);
          } else {
            timeline.pause();
          }
        } else {
          timeline.updatePositionFromPlayback(timelinePos);
        }
      }
    }
    setState(() {});
  }

  Future<void> _setupClipController(VideoClipModel clip, Duration timelinePos, bool isPlaying) async {
    if (_isControllerInitializing) return;
    _isControllerInitializing = true;

    final old = _controller;
    _controller = null;
    await old?.dispose();

    try {
      final newController = await _resolveAndCreateController(clip.sourcePath);
      if (newController != null) {
        await newController.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Player initialize timeout (15s)'),
        );

        if (!mounted) {
          await newController.dispose();
          return;
        }

        newController.setLooping(false);
        final isTrackMuted = context.read<ProjectProvider>().activeProject?.mutedVideoTracks.contains(clip.trackIndex) ?? false;
        await newController.setVolume(clip.isMuted || isTrackMuted ? 0.0 : clip.volume);
        await newController.setPlaybackSpeed(clip.speed);

        // Seek to initial offset
        final localOffset = _calculateClipLocalPosition(clip, timelinePos);
        await newController.seekTo(localOffset);

        if (!mounted) {
          await newController.dispose();
          return;
        }

        if (isPlaying) {
          context.read<TimelineProvider>().setPlayerDriving(true);
          await newController.play();
        }

        newController.addListener(_onPlayerTick);

        _controller = newController;
        _loadedClipId = clip.id;
        _loadedClipPath = clip.sourcePath;
      } else {
        debugPrint('Could not create video controller for path: ${clip.sourcePath}');
        _loadedClipId = null;
        _loadedClipPath = null;
      }
    } catch (e) {
      debugPrint('Video controller setup fallback for ${clip.sourcePath}: $e');
      _controller = null;
      _loadedClipId = null;
      _loadedClipPath = null;
    } finally {
      _isControllerInitializing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _updatePlayerForClip(
    VideoClipModel? clip,
    Duration timelinePos,
    bool isPlaying,
  ) async {
    if (clip == null) {
      if (_controller != null) {
        final c = _controller;
        _controller = null;
        _loadedClipId = null;
        _loadedClipPath = null;
        await c?.dispose();
        if (mounted) {
          context.read<TimelineProvider>().setPlayerDriving(false);
          setState(() {});
        }
      }
      return;
    }

    // Clip changed or needs initialization
    if (_loadedClipId != clip.id || _loadedClipPath != clip.sourcePath || (_controller == null && !_isControllerInitializing)) {
      await _setupClipController(clip, timelinePos, isPlaying);
      return;
    }

    // If controller is already active, synchronize playback & seek
    if (_controller != null && _controller!.value.isInitialized) {
      final ctrl = _controller!;

      // Sync volume & speed
      final isTrackMuted = context.read<ProjectProvider>().activeProject?.mutedVideoTracks.contains(clip.trackIndex) ?? false;
      final targetVolume = clip.isMuted || isTrackMuted ? 0.0 : clip.volume;
      if (ctrl.value.volume != targetVolume) {
        ctrl.setVolume(targetVolume);
      }
      if (ctrl.value.playbackSpeed != clip.speed) {
        ctrl.setPlaybackSpeed(clip.speed);
      }

      // Sync play/pause
      if (isPlaying && !ctrl.value.isPlaying) {
        context.read<TimelineProvider>().setPlayerDriving(true);
        ctrl.play();
      } else if (!isPlaying && ctrl.value.isPlaying) {
        context.read<TimelineProvider>().setPlayerDriving(false);
        ctrl.pause();
      }

      // CRITICAL: NEVER call seekTo while playing! ExoPlayer plays at hardware rate.
      // Only seek when paused and offset is visibly different (> 50ms)
      if (!isPlaying) {
        final targetLocal = _calculateClipLocalPosition(clip, timelinePos);
        if ((ctrl.value.position - targetLocal).abs() > const Duration(milliseconds: 50)) {
          ctrl.seekTo(targetLocal);
        }
      }
    }
  }

  Duration _calculateClipLocalPosition(VideoClipModel clip, Duration timelinePos) {
    if (timelinePos < clip.startTime) {
      return clip.trimStart;
    }
    final relativeTime = timelinePos - clip.startTime;
    final speedAdjusted = Duration(
      milliseconds: (relativeTime.inMilliseconds * clip.speed).round(),
    );
    final target = clip.trimStart + speedAdjusted;
    if (target > clip.sourceDuration) {
      return clip.sourceDuration;
    }
    return target;
  }

  void _openFullscreen(BuildContext context, dynamic project, dynamic timeline, ColorFilter? colorFilter) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: project.aspectRatio.ratio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  ColorFiltered(
                    colorFilter: colorFilter ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                else
                  _buildFallbackVisual(project, null, colorFilter),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectProvider>().activeProject;
    final timeline = context.watch<TimelineProvider>();
    final projectProvider = context.read<ProjectProvider>();

    if (project == null) return const SizedBox.shrink();

    final currentPos = timeline.currentPosition;
    final totalDuration = project.totalDuration;

    // Find active clip at current playhead position across stacked tracks (highest visible track wins)
    final candidateClips = project.videoClips.where((c) {
      if (project.hiddenVideoTracks.contains(c.trackIndex)) return false;
      return currentPos >= c.startTime && currentPos <= c.endTime;
    }).toList();

    VideoClipModel? activeClip;
    if (candidateClips.isNotEmpty) {
      // Sort by trackIndex descending so higher track (e.g. V2 over V1) overlays lower track
      candidateClips.sort((a, b) => b.trackIndex.compareTo(a.trackIndex));
      activeClip = candidateClips.first;
    } else {
      // Fallback: nearest clip among visible tracks
      final visibleClips = project.videoClips
          .where((c) => !project.hiddenVideoTracks.contains(c.trackIndex))
          .toList();
      if (visibleClips.isNotEmpty) {
        if (currentPos <= visibleClips.first.startTime) {
          activeClip = visibleClips.first;
        } else if (currentPos >= visibleClips.last.endTime) {
          activeClip = visibleClips.last;
        }
      }
    }

    // Schedule player sync safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updatePlayerForClip(activeClip, currentPos, timeline.isPlaying);
      }
    });

    // Active text overlays at this point in time
    final activeTexts = project.textOverlays.where((t) {
      return currentPos >= t.startTime && currentPos <= t.endTime;
    }).toList();

    final activeFilter = (activeClip != null && activeClip.filter != VideoFilterPreset.none)
        ? activeClip.filter
        : project.globalFilter;
    final colorFilter = _getColorFilter(activeFilter);

    final bool hasValidRealPlayer = _controller != null && _controller!.value.isInitialized;

    return Container(
      color: Colors.black,
      width: double.infinity,
      child: Center(
        child: AspectRatio(
          aspectRatio: project.aspectRatio.ratio,
          child: GestureDetector(
            onTap: timeline.togglePlayPause,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Video Layer (Real Video Player with Live Color Filters)
                if (hasValidRealPlayer)
                  ColorFiltered(
                    colorFilter: colorFilter ??
                        const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: (_controller!.value.size.width > 0 &&
                                _controller!.value.size.height > 0)
                            ? _controller!.value.aspectRatio
                            : project.aspectRatio.ratio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                else if (_isControllerInitializing)
                  Container(
                    color: const Color(0xFF0F172A),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Loading ${activeClip?.title ?? 'Clip'}...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Rich simulated video footage fallback
                  _buildFallbackVisual(project, activeClip, colorFilter),

                // 2. Active Draggable & Editable Text Overlays on Canvas
                ...activeTexts.map((textModel) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment(
                          textModel.positionX,
                          textModel.positionY,
                        ),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            // Convert delta movement to alignment coordinates (-1.0 to 1.0)
                            final dx = details.delta.dx / (constraints.maxWidth / 2);
                            final dy = details.delta.dy / (constraints.maxHeight / 2);
                            final newX = (textModel.positionX + dx).clamp(-0.9, 0.9);
                            final newY = (textModel.positionY + dy).clamp(-0.9, 0.9);
                            projectProvider.updateTextOverlay(
                              textModel.copyWith(positionX: newX, positionY: newY),
                            );
                          },
                          onTap: () {
                            TextEditSheet.show(
                              context: context,
                              initialText: textModel,
                              currentPosition: textModel.startTime,
                              onSave: projectProvider.updateTextOverlay,
                              onDelete: () => projectProvider.removeTextOverlay(textModel.id),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: textModel.backgroundColor ?? Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  textModel.text,
                                  style: TextStyle(
                                    color: textModel.fontColor,
                                    fontSize: textModel.fontSize,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.open_with_rounded,
                                  size: 12,
                                  color: Colors.white54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // 3. Center Play/Pause Indicator
                if (!timeline.isPlaying)
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ),

                // 4. Canvas Controls: Fullscreen button bottom-left
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: GestureDetector(
                    onTap: () => _openFullscreen(context, project, timeline, colorFilter),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // 5. Timecode Pill (bottom-right: "00:08 / 00:28")
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_formatDuration(currentPos)} / ${_formatDuration(totalDuration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackVisual(
    dynamic project,
    VideoClipModel? activeClip,
    ColorFilter? colorFilter,
  ) {
    return ColorFiltered(
      colorFilter: colorFilter ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: project.title.toLowerCase().contains('cafe')
                ? [
                    const Color(0xFFFBBF24),
                    const Color(0xFFB45309),
                    const Color(0xFF451A03),
                  ]
                : [
                    const Color(0xFF38BDF8),
                    const Color(0xFF1E3A8A),
                    const Color(0xFF0F172A),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    activeClip != null ? Icons.videocam_rounded : Icons.movie_outlined,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeClip?.title ?? 'No clip at playhead',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                  if (activeClip != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_formatDuration(activeClip.duration)} • ${activeClip.filter.name}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.white38),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.video_library_rounded, size: 16),
                      label: const Text(
                        'Select / Re-link Video',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        final picked = await MediaPickerService.pickVideo();
                        if (picked != null && mounted) {
                          final updated = activeClip.copyWith(
                            sourcePath: picked.path,
                            duration: picked.duration,
                            sourceDuration: picked.duration,
                          );
                          context.read<ProjectProvider>().updateVideoClip(updated);
                          setState(() {
                            _loadedClipId = null;
                            _loadedClipPath = null;
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
