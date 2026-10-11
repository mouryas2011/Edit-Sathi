import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../models/video_clip.dart';
import '../../../../providers/timeline_provider.dart';
import '../../../../providers/project_provider.dart';
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
        if (mounted) setState(() {});
      }
      return;
    }

    // Clip changed or needs initialization
    if (_loadedClipId != clip.id || _loadedClipPath != clip.sourcePath) {
      if (_isControllerInitializing) return;
      _isControllerInitializing = true;

      final old = _controller;
      _controller = null;
      await old?.dispose();

      VideoPlayerController? newController;
      try {
        if (kIsWeb) {
          newController = VideoPlayerController.networkUrl(Uri.parse(clip.sourcePath));
        } else {
          final file = File(clip.sourcePath);
          if (await file.exists()) {
            newController = VideoPlayerController.file(file);
          } else if (clip.sourcePath.startsWith('http://') ||
              clip.sourcePath.startsWith('https://')) {
            newController = VideoPlayerController.networkUrl(Uri.parse(clip.sourcePath));
          } else if (clip.sourcePath.startsWith('assets/')) {
            newController = VideoPlayerController.asset(clip.sourcePath);
          }
        }

        if (newController != null) {
          await newController.initialize().timeout(
            const Duration(seconds: 4),
            onTimeout: () => throw TimeoutException('Player initialize timeout'),
          );

          if (!mounted) {
            await newController.dispose();
            return;
          }

          newController.setLooping(false);
          await newController.setVolume(clip.isMuted ? 0.0 : clip.volume);
          await newController.setPlaybackSpeed(clip.speed);

          // Seek to initial offset
          final localOffset = _calculateClipLocalPosition(clip, timelinePos);
          await newController.seekTo(localOffset);

          if (isPlaying) {
            await newController.play();
          }

          _controller = newController;
          _loadedClipId = clip.id;
          _loadedClipPath = clip.sourcePath;
        }
      } catch (e) {
        debugPrint('Video controller setup fallback: $e');
        _controller = null;
      } finally {
        _isControllerInitializing = false;
        if (mounted) setState(() {});
      }
      return;
    }

    // If controller is already active, synchronize playback & seek
    if (_controller != null && _controller!.value.isInitialized) {
      final ctrl = _controller!;

      // Sync volume & speed
      final targetVolume = clip.isMuted ? 0.0 : clip.volume;
      if (ctrl.value.volume != targetVolume) {
        ctrl.setVolume(targetVolume);
      }
      if (ctrl.value.playbackSpeed != clip.speed) {
        ctrl.setPlaybackSpeed(clip.speed);
      }

      // Sync play/pause
      if (isPlaying && !ctrl.value.isPlaying) {
        ctrl.play();
      } else if (!isPlaying && ctrl.value.isPlaying) {
        ctrl.pause();
      }

      // Sync seek position when paused or if desynchronized > 250ms
      final targetLocal = _calculateClipLocalPosition(clip, timelinePos);
      if (!isPlaying || (ctrl.value.position - targetLocal).abs() > const Duration(milliseconds: 250)) {
        ctrl.seekTo(targetLocal);
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

    // Find active clip at current playhead position
    VideoClipModel? activeClip;
    for (final clip in project.videoClips) {
      if (currentPos >= clip.startTime && currentPos <= clip.endTime) {
        activeClip = clip;
        break;
      }
    }
    // Edge case: if playhead is exactly at 0 or at project end
    if (activeClip == null && project.videoClips.isNotEmpty) {
      if (currentPos <= project.videoClips.first.startTime) {
        activeClip = project.videoClips.first;
      } else if (currentPos >= project.videoClips.last.endTime) {
        activeClip = project.videoClips.last;
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
                        aspectRatio: _controller!.value.aspectRatio,
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
