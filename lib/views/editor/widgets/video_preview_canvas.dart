import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../models/project.dart';
import '../../../../models/video_clip.dart';
import '../../../../models/shape_overlay.dart';
import '../../../../models/adjustment_layer.dart';
import '../../../../providers/timeline_provider.dart';
import '../../../../providers/project_provider.dart';
import '../../../../services/media_picker_service.dart';
import '../../../../theme/app_colors.dart';
import 'sheets/text_edit_sheet.dart';
import 'sheets/transform_sheet.dart';
import 'sheets/shape_picker_sheet.dart';
import 'sheets/adjustment_layer_sheet.dart';

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

  // Touch gesture transform tracking
  double _gestureBaseScale = 1.0;
  double _gestureBaseRotation = 0.0;
  double _gestureBasePosX = 0.0;
  double _gestureBasePosY = 0.0;
  bool _isTransforming = false;
  final bool _showTransformControls = true;

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

      // CRITICAL: NEVER call seekTo while playing!
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

  void _openFullscreen(BuildContext context, dynamic project, dynamic timeline, ColorFilter? colorFilter, VideoClipModel? activeClip, ColorFilter? adjFilter) {
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
                  _buildTransformedVideoWidget(
                    _controller!,
                    activeClip,
                    colorFilter,
                    adjFilter,
                    project.aspectRatio.ratio,
                    context.read<TimelineProvider>().currentPosition,
                  )
                else
                  _buildFallbackVisual(project, activeClip, colorFilter, adjFilter),
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

  Widget _buildCanvasBackground(ProjectModel project, VideoPlayerController? controller) {
    switch (project.canvasBgType) {
      case CanvasBgType.blur:
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF0B0F19)),
            if (controller != null && controller.value.isInitialized)
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: project.canvasBlurSigma,
                    sigmaY: project.canvasBlurSigma,
                  ),
                  child: Transform.scale(
                    scale: 1.35,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.2),
                    radius: 1.2,
                    colors: [Color(0xFF1E293B), Color(0xFF0B0F19)],
                  ),
                ),
              ),
            Container(color: Colors.black.withValues(alpha: 0.28)),
          ],
        );

      case CanvasBgType.color:
        return Container(color: Color(project.canvasColorValue));

      case CanvasBgType.gradient:
        const presets = [
          [Color(0xFF0F172A), Color(0xFF1E293B)],
          [Color(0xFF31103F), Color(0xFF701A75)],
          [Color(0xFF1E1B4B), Color(0xFF3B82F6)],
          [Color(0xFF064E3B), Color(0xFF10B981)],
          [Color(0xFF7F1D1D), Color(0xFFF97316)],
          [Color(0xFF111827), Color(0xFF6366F1)],
        ];
        final grad = presets[project.canvasGradientIndex.clamp(0, presets.length - 1)];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: grad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
    }
  }

  Widget _buildTransformedVideoWidget(
    VideoPlayerController controller,
    VideoClipModel? clip,
    ColorFilter? baseFilter,
    ColorFilter? adjFilter,
    double canvasAspectRatio,
    Duration currentPos,
  ) {
    final localOffset = clip != null && currentPos >= clip.startTime
        ? currentPos - clip.startTime
        : Duration.zero;

    final kfTransform = clip?.getTransformAt(localOffset);
    double scale = kfTransform?.scale ?? clip?.scale ?? 1.0;
    double rotation = kfTransform?.rotation ?? clip?.rotation ?? 0.0;
    double posX = kfTransform?.positionX ?? clip?.positionX ?? 0.0;
    double posY = kfTransform?.positionY ?? clip?.positionY ?? 0.0;
    double opacity = kfTransform?.opacity ?? 1.0;
    final flipH = clip?.flipHorizontal == true ? -1.0 : 1.0;
    final flipV = clip?.flipVertical == true ? -1.0 : 1.0;

    double slideDx = 0.0;
    double slideDy = 0.0;
    double overlayBlack = 0.0;
    double overlayWhite = 0.0;

    // Apply Transition Effects (Premiere Pro, VN, CapCut)
    if (clip != null &&
        clip.transition != TransitionType.none &&
        localOffset < clip.transitionDuration) {
      final t = (localOffset.inMilliseconds / clip.transitionDuration.inMilliseconds)
          .clamp(0.0, 1.0);

      switch (clip.transition) {
        case TransitionType.crossFade:
          opacity *= t;
          break;
        case TransitionType.dipToBlack:
        case TransitionType.fadeToBlack:
          overlayBlack = (1.0 - t).clamp(0.0, 1.0);
          break;
        case TransitionType.dipToWhite:
          overlayWhite = (1.0 - t).clamp(0.0, 1.0);
          break;
        case TransitionType.wipeLeft:
        case TransitionType.slideLeft:
          slideDx = (1.0 - t) * 1.0;
          break;
        case TransitionType.wipeRight:
        case TransitionType.slideRight:
          slideDx = -(1.0 - t) * 1.0;
          break;
        case TransitionType.zoomIn:
          scale *= (0.3 + 0.7 * t);
          opacity *= t;
          break;
        case TransitionType.zoomOut:
          scale *= (1.8 - 0.8 * t);
          opacity *= t;
          break;
        case TransitionType.glitch:
          if ((localOffset.inMilliseconds / 80).floor() % 2 == 0) {
            slideDx = 0.04;
            opacity *= 0.85;
          } else {
            slideDx = -0.04;
          }
          break;
        case TransitionType.none:
          break;
      }
    }

    Widget content = Center(
      child: AspectRatio(
        aspectRatio: (controller.value.size.width > 0 && controller.value.size.height > 0)
            ? controller.value.aspectRatio
            : canvasAspectRatio,
        child: VideoPlayer(controller),
      ),
    );

    if (baseFilter != null) {
      content = ColorFiltered(colorFilter: baseFilter, child: content);
    }
    if (adjFilter != null) {
      content = ColorFiltered(colorFilter: adjFilter, child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tx = (posX + slideDx) * (constraints.maxWidth / 2);
        final ty = (posY + slideDy) * (constraints.maxHeight / 2);

        Widget result = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            // ignore: deprecated_member_use
            ..translate(tx, ty)
            ..rotateZ(rotation)
            // ignore: deprecated_member_use
            ..scale(scale * flipH, scale * flipV),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: content,
          ),
        );

        if (overlayBlack > 0.0) {
          result = Stack(
            fit: StackFit.expand,
            children: [
              result,
              IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: overlayBlack),
                ),
              ),
            ],
          );
        } else if (overlayWhite > 0.0) {
          result = Stack(
            fit: StackFit.expand,
            children: [
              result,
              IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: overlayWhite),
                ),
              ),
            ],
          );
        }

        return result;
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

    // Find active clip at current playhead position across stacked tracks
    final candidateClips = project.videoClips.where((c) {
      if (project.hiddenVideoTracks.contains(c.trackIndex)) return false;
      return currentPos >= c.startTime && currentPos <= c.endTime;
    }).toList();

    VideoClipModel? activeClip;
    if (candidateClips.isNotEmpty) {
      candidateClips.sort((a, b) => b.trackIndex.compareTo(a.trackIndex));
      activeClip = candidateClips.first;
    } else {
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

    // Active shapes at this point in time
    final activeShapes = project.shapes.where((s) {
      return currentPos >= s.startTime && currentPos <= s.endTime;
    }).toList();

    // Active adjustment layers at this point in time
    final activeAdjLayers = project.adjustmentLayers.where((al) {
      return currentPos >= al.startTime && currentPos <= al.endTime;
    }).toList();
    final AdjustmentLayerModel? activeAdj = activeAdjLayers.firstOrNull;
    final adjFilter = activeAdj?.buildColorFilter();

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: timeline.togglePlayPause,
                onDoubleTap: () {
                  if (activeClip != null) {
                    projectProvider.resetClipTransform(activeClip.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('↺ Reset scale and rotation to default'),
                        duration: Duration(milliseconds: 1200),
                        backgroundColor: Color(0xFF1E293B),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (activeClip != null) {
                    TransformSheet.show(
                      context: context,
                      clip: activeClip,
                      onSave: projectProvider.updateVideoClip,
                    );
                  }
                },
                // Direct touch-to-zoom, rotate, and pan gestures on active clip
                onScaleStart: (details) {
                  if (activeClip != null) {
                    _gestureBaseScale = activeClip.scale;
                    _gestureBaseRotation = activeClip.rotation;
                    _gestureBasePosX = activeClip.positionX;
                    _gestureBasePosY = activeClip.positionY;
                    setState(() {
                      _isTransforming = true;
                    });
                  }
                },
                onScaleUpdate: (details) {
                  if (activeClip != null) {
                    double newScale = _gestureBaseScale;
                    double newRotation = _gestureBaseRotation;

                    // Pinch-to-zoom scale
                    if (details.scale != 1.0) {
                      newScale = (_gestureBaseScale * details.scale).clamp(0.2, 5.0);
                    }
                    // Two-finger twist rotation
                    if (details.rotation != 0.0) {
                      newRotation = _gestureBaseRotation + details.rotation;
                    }

                    // Drag to pan (offset from center)
                    final dx = details.focalPointDelta.dx / (constraints.maxWidth / 2);
                    final dy = details.focalPointDelta.dy / (constraints.maxHeight / 2);

                    _gestureBasePosX = (_gestureBasePosX + dx).clamp(-2.0, 2.0);
                    _gestureBasePosY = (_gestureBasePosY + dy).clamp(-2.0, 2.0);

                    projectProvider.updateClipTransform(
                      activeClip.id,
                      scale: newScale,
                      rotation: newRotation,
                      positionX: _gestureBasePosX,
                      positionY: _gestureBasePosY,
                    );
                  }
                },
                onScaleEnd: (details) {
                  setState(() {
                    _isTransforming = false;
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 0. Studio Canvas Background (Blur Fill / Solid Color / Gradient)
                    _buildCanvasBackground(project, _controller),

                    // 1. Video Layer (Interactive Transformed Video + Live Color Filter & Adjustment Layer)
                    if (hasValidRealPlayer)
                      _buildTransformedVideoWidget(
                        _controller!,
                        activeClip,
                        colorFilter,
                        adjFilter,
                        project.aspectRatio.ratio,
                        currentPos,
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
                      // Fallback visual with transformation & adjustment layer applied
                      _buildTransformedFallbackVisual(
                        project,
                        activeClip,
                        colorFilter,
                        adjFilter,
                        constraints,
                        currentPos,
                      ),

                    // 2. Interactive Cyan Bounding Box Gizmo for active clip
                    if (activeClip != null && (_isTransforming || (!timeline.isPlaying && _showTransformControls)))
                      _buildTransformBoundingBox(activeClip, constraints, projectProvider),

                    // 3. Active Shapes Layer (Interactive & Draggable)
                    ...activeShapes.map((shape) {
                      return Align(
                        alignment: Alignment(shape.positionX, shape.positionY),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final dx = details.delta.dx / (constraints.maxWidth / 2);
                            final dy = details.delta.dy / (constraints.maxHeight / 2);
                            final newX = (shape.positionX + dx).clamp(-0.95, 0.95);
                            final newY = (shape.positionY + dy).clamp(-0.95, 0.95);
                            projectProvider.updateShape(
                              shape.copyWith(positionX: newX, positionY: newY),
                            );
                          },
                          onTap: () {
                            ShapePickerSheet.show(
                              context: context,
                              currentPosition: shape.startTime,
                              onShapeSelected: (updated) {
                                projectProvider.updateShape(
                                  updated.copyWith(
                                    id: shape.id,
                                    positionX: shape.positionX,
                                    positionY: shape.positionY,
                                  ),
                                );
                              },
                            );
                          },
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Transform.rotate(
                                angle: shape.rotation,
                                child: CustomPaint(
                                  size: Size(shape.width, shape.height),
                                  painter: ShapeCustomPainter(shape: shape),
                                ),
                              ),
                              // Delete pin
                              if (!timeline.isPlaying)
                                GestureDetector(
                                  onTap: () => projectProvider.removeShape(shape.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // 4. Active Draggable & Editable Text Overlays on Canvas
                    ...activeTexts.map((textModel) {
                      return Align(
                        alignment: Alignment(
                          textModel.positionX,
                          textModel.positionY,
                        ),
                        child: GestureDetector(
                          onPanUpdate: (details) {
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
                    }),

                    // 5. Active Adjustment Layer Indicator Pill (Top Left)
                    if (activeAdj != null)
                      Positioned(
                        left: 12,
                        top: 10,
                        child: GestureDetector(
                          onTap: () {
                            AdjustmentLayerSheet.show(
                              context: context,
                              initialLayer: activeAdj,
                              currentPosition: activeAdj.startTime,
                              totalProjectDuration: project.totalDuration,
                              onSave: projectProvider.updateAdjustmentLayer,
                              onDelete: () => projectProvider.removeAdjustmentLayer(activeAdj.id),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, size: 13, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  'Layer: ${activeAdj.title} (${activeAdj.filter.name})',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // 6. Floating Transform Quick Controls Pill (Top Center)
                    if (activeClip != null && !timeline.isPlaying && _showTransformControls) ...[
                      Builder(
                        builder: (context) {
                          final currentClip = activeClip!;
                          return Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF06B6D4), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Scale ${(currentClip.scale * 100).toInt()}% • ${(currentClip.rotation * 180 / math.pi).toInt()}°',
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        projectProvider.updateVideoClip(
                                          currentClip.copyWith(flipHorizontal: !currentClip.flipHorizontal),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: currentClip.flipHorizontal ? const Color(0xFF06B6D4) : Colors.white10,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          Icons.flip_rounded,
                                          size: 13,
                                          color: currentClip.flipHorizontal ? Colors.black : Colors.white70,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => projectProvider.resetClipTransform(currentClip.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.restart_alt_rounded, size: 13, color: Colors.white70),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        TransformSheet.show(
                                          context: context,
                                          clip: currentClip,
                                          onSave: projectProvider.updateVideoClip,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Tune',
                                          style: TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // 7. Center Play/Pause Indicator
                    if (!timeline.isPlaying)
                      Center(
                        child: IgnorePointer(
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
                      ),

                    // 8. Canvas Controls: Fullscreen button bottom-left
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: GestureDetector(
                        onTap: () => _openFullscreen(
                          context,
                          project,
                          timeline,
                          colorFilter,
                          activeClip,
                          adjFilter,
                        ),
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

                    // 9. Timecode Pill (bottom-right: "00:08 / 00:28")
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTransformBoundingBox(
    VideoClipModel clip,
    BoxConstraints constraints,
    ProjectProvider projectProvider,
  ) {
    final scale = clip.scale;
    final rotation = clip.rotation;
    final tx = clip.positionX * (constraints.maxWidth / 2);
    final ty = clip.positionY * (constraints.maxHeight / 2);

    return IgnorePointer(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          // ignore: deprecated_member_use
          ..translate(tx, ty)
          ..rotateZ(rotation)
          // ignore: deprecated_member_use
          ..scale(scale),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF06B6D4),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Top-left dot
              Positioned(
                left: -4,
                top: -4,
                child: _buildHandleDot(),
              ),
              // Top-right dot
              Positioned(
                right: -4,
                top: -4,
                child: _buildHandleDot(),
              ),
              // Bottom-left dot
              Positioned(
                left: -4,
                bottom: -4,
                child: _buildHandleDot(),
              ),
              // Bottom-right dot
              Positioned(
                right: -4,
                bottom: -4,
                child: _buildHandleDot(),
              ),
              // Top rotation stalk
              Positioned(
                top: -20,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF06B6D4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 1.5,
                        height: 10,
                        color: const Color(0xFF06B6D4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandleDot() {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF06B6D4), width: 2),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4),
        ],
      ),
    );
  }

  Widget _buildTransformedFallbackVisual(
    dynamic project,
    VideoClipModel? activeClip,
    ColorFilter? colorFilter,
    ColorFilter? adjFilter,
    BoxConstraints constraints,
    Duration currentPos,
  ) {
    final localOffset = activeClip != null && currentPos >= activeClip.startTime
        ? currentPos - activeClip.startTime
        : Duration.zero;

    final kfTransform = activeClip?.getTransformAt(localOffset);
    double scale = kfTransform?.scale ?? activeClip?.scale ?? 1.0;
    double rotation = kfTransform?.rotation ?? activeClip?.rotation ?? 0.0;
    double posX = kfTransform?.positionX ?? activeClip?.positionX ?? 0.0;
    double posY = kfTransform?.positionY ?? activeClip?.positionY ?? 0.0;
    double opacity = kfTransform?.opacity ?? 1.0;
    final flipH = activeClip?.flipHorizontal == true ? -1.0 : 1.0;
    final flipV = activeClip?.flipVertical == true ? -1.0 : 1.0;

    double slideDx = 0.0;
    double slideDy = 0.0;
    double overlayBlack = 0.0;
    double overlayWhite = 0.0;

    if (activeClip != null &&
        activeClip.transition != TransitionType.none &&
        localOffset < activeClip.transitionDuration) {
      final t = (localOffset.inMilliseconds / activeClip.transitionDuration.inMilliseconds)
          .clamp(0.0, 1.0);

      switch (activeClip.transition) {
        case TransitionType.crossFade:
          opacity *= t;
          break;
        case TransitionType.dipToBlack:
        case TransitionType.fadeToBlack:
          overlayBlack = (1.0 - t).clamp(0.0, 1.0);
          break;
        case TransitionType.dipToWhite:
          overlayWhite = (1.0 - t).clamp(0.0, 1.0);
          break;
        case TransitionType.wipeLeft:
        case TransitionType.slideLeft:
          slideDx = (1.0 - t) * 1.0;
          break;
        case TransitionType.wipeRight:
        case TransitionType.slideRight:
          slideDx = -(1.0 - t) * 1.0;
          break;
        case TransitionType.zoomIn:
          scale *= (0.3 + 0.7 * t);
          opacity *= t;
          break;
        case TransitionType.zoomOut:
          scale *= (1.8 - 0.8 * t);
          opacity *= t;
          break;
        case TransitionType.glitch:
          if ((localOffset.inMilliseconds / 80).floor() % 2 == 0) {
            slideDx = 0.04;
            opacity *= 0.85;
          } else {
            slideDx = -0.04;
          }
          break;
        case TransitionType.none:
          break;
      }
    }

    final tx = (posX + slideDx) * (constraints.maxWidth / 2);
    final ty = (posY + slideDy) * (constraints.maxHeight / 2);

    Widget result = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(tx, ty)
        ..rotateZ(rotation)
        // ignore: deprecated_member_use
        ..scale(scale * flipH, scale * flipV),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: _buildFallbackVisual(project, activeClip, colorFilter, adjFilter),
      ),
    );

    if (overlayBlack > 0.0) {
      result = Stack(
        fit: StackFit.expand,
        children: [
          result,
          IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: overlayBlack),
            ),
          ),
        ],
      );
    } else if (overlayWhite > 0.0) {
      result = Stack(
        fit: StackFit.expand,
        children: [
          result,
          IgnorePointer(
            child: Container(
              color: Colors.white.withValues(alpha: overlayWhite),
            ),
          ),
        ],
      );
    }

    return result;
  }

  Widget _buildFallbackVisual(
    dynamic project,
    VideoClipModel? activeClip,
    ColorFilter? colorFilter,
    ColorFilter? adjFilter,
  ) {
    Widget content = Container(
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
    );

    if (colorFilter != null) {
      content = ColorFiltered(colorFilter: colorFilter, child: content);
    }
    if (adjFilter != null) {
      content = ColorFiltered(colorFilter: adjFilter, child: content);
    }

    return content;
  }
}

class ShapeCustomPainter extends CustomPainter {
  final ShapeOverlayModel shape;

  const ShapeCustomPainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = shape.displayColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = shape.displayStrokeColor
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    switch (shape.type) {
      case ShapeType.rectangle:
        canvas.drawRect(rect, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawRect(rect, strokePaint);
        break;

      case ShapeType.roundedRect:
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(shape.cornerRadius));
        canvas.drawRRect(rrect, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawRRect(rrect, strokePaint);
        break;

      case ShapeType.circle:
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.min(size.width, size.height) / 2;
        canvas.drawCircle(center, radius, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawCircle(center, radius, strokePaint);
        break;

      case ShapeType.arrow:
        final path = Path();
        final w = size.width;
        final h = size.height;
        path.moveTo(0, h * 0.35);
        path.lineTo(w * 0.55, h * 0.35);
        path.lineTo(w * 0.55, h * 0.1);
        path.lineTo(w, h * 0.5);
        path.lineTo(w * 0.55, h * 0.9);
        path.lineTo(w * 0.55, h * 0.65);
        path.lineTo(0, h * 0.65);
        path.close();
        canvas.drawPath(path, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.star:
        final path = Path();
        final cx = size.width / 2;
        final cy = size.height / 2;
        final outerR = math.min(cx, cy);
        final innerR = outerR * 0.45;
        for (int i = 0; i < 10; i++) {
          final r = i.isEven ? outerR : innerR;
          final angle = (i * 36 - 90) * math.pi / 180.0;
          final x = cx + r * math.cos(angle);
          final y = cy + r * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.heart:
        final path = Path();
        final w = size.width;
        final h = size.height;
        path.moveTo(w * 0.5, h * 0.85);
        path.cubicTo(w * 0.1, h * 0.55, 0, h * 0.25, w * 0.25, h * 0.1);
        path.cubicTo(w * 0.45, 0.0, w * 0.5, h * 0.25, w * 0.5, h * 0.25);
        path.cubicTo(w * 0.5, h * 0.25, w * 0.55, 0.0, w * 0.75, h * 0.1);
        path.cubicTo(w * 1.0, h * 0.25, w * 0.9, h * 0.55, w * 0.5, h * 0.85);
        path.close();
        canvas.drawPath(path, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.callout:
        final path = Path();
        final w = size.width;
        final h = size.height;
        final r = shape.cornerRadius;
        path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h * 0.75), Radius.circular(r)));
        path.moveTo(w * 0.2, h * 0.75);
        path.lineTo(w * 0.1, h);
        path.lineTo(w * 0.35, h * 0.75);
        path.close();
        canvas.drawPath(path, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.line:
        final p = Paint()
          ..color = shape.displayColor
          ..strokeWidth = math.max(shape.strokeWidth, 4.0)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant ShapeCustomPainter oldDelegate) {
    return oldDelegate.shape != shape;
  }
}
