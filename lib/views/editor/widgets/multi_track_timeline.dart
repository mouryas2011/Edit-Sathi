import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/video_clip.dart';
import '../../../../models/text_overlay.dart';
import '../../../../models/audio_track.dart';
import '../../../../providers/timeline_provider.dart';
import '../../../../providers/project_provider.dart';
import '../../../../services/media_picker_service.dart';
import '../../../../theme/app_colors.dart';
import 'timeline_ruler.dart';
import 'sheets/text_edit_sheet.dart';
import 'sheets/audio_picker_sheet.dart';

class MultiTrackTimeline extends StatefulWidget {
  const MultiTrackTimeline({super.key});

  @override
  State<MultiTrackTimeline> createState() => _MultiTrackTimelineState();
}

class _MultiTrackTimelineState extends State<MultiTrackTimeline> {
  final ScrollController _scrollController = ScrollController();
  final double _basePixelsPerSecond = 34.0;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timeline = context.read<TimelineProvider>();
      timeline.addListener(_onTimelineUpdate);
    });
  }

  void _onTimelineUpdate() {
    if (!mounted) return;
    final timeline = context.read<TimelineProvider>();
    if (timeline.isPlaying && _scrollController.hasClients && !_isAutoScrolling) {
      final zoom = timeline.zoomLevel;
      final playheadX = _durationToPixels(timeline.currentPosition, zoom);
      final currentScroll = _scrollController.offset;
      final viewportWidth = _scrollController.position.viewportDimension;

      // If playhead approaches right edge of viewport, auto-scroll smoothly forward
      if (playheadX > currentScroll + viewportWidth - 60) {
        _isAutoScrolling = true;
        _scrollController.animateTo(
          playheadX - 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ).then((_) {
          _isAutoScrolling = false;
        });
      } else if (playheadX < currentScroll) {
        // If playhead looped back to start
        _isAutoScrolling = true;
        _scrollController.animateTo(
          math.max(0.0, playheadX - 40),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ).then((_) {
          _isAutoScrolling = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _getPixelsPerSecond(double zoom) => _basePixelsPerSecond * zoom;

  double _durationToPixels(Duration d, double zoom) {
    return (d.inMilliseconds / 1000.0) * _getPixelsPerSecond(zoom);
  }

  Duration _pixelsToDuration(double px, double zoom) {
    final sec = px / _getPixelsPerSecond(zoom);
    return Duration(milliseconds: (sec * 1000).round());
  }

  Future<void> _addClipFromPickedInfo(
    BuildContext context,
    PickedVideoInfo picked,
    ProjectProvider projectProvider, {
    int trackIndex = 0,
    Duration? position,
  }) async {
    final cleanTitle = picked.name.contains('.')
        ? picked.name.split('.').first
        : picked.name;

    final newClip = VideoClipModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourcePath: picked.path,
      title: cleanTitle.isNotEmpty ? cleanTitle : 'New Clip',
      startTime: position ?? Duration.zero,
      duration: picked.duration,
      sourceDuration: picked.duration,
      trackIndex: trackIndex,
    );

    projectProvider.addVideoClipToTrack(newClip, trackIndex: trackIndex, startTime: position);
    final active = projectProvider.activeProject;
    if (active != null && context.mounted) {
      context.read<TimelineProvider>().setTotalDuration(active.totalDuration);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added clip "$cleanTitle" to Track V${trackIndex + 1}'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF06B6D4),
        ),
      );
    }
  }

  Future<void> _pickVideoClip(
    BuildContext context,
    ProjectProvider projectProvider, {
    int trackIndex = 0,
    Duration? position,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF161926),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Track V${trackIndex + 1}',
                    style: const TextStyle(
                      color: Color(0xFF06B6D4),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Video Clip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFF1E2436),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF8B5CF6),
                child: Icon(Icons.photo_library_rounded, color: Colors.white),
              ),
              title: const Text('From Gallery / Photos', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Pick video from device photos', style: TextStyle(color: Colors.white60)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await MediaPickerService.pickVideo(source: ImageSource.gallery);
                if (picked != null && context.mounted) {
                  await _addClipFromPickedInfo(
                    context,
                    picked,
                    projectProvider,
                    trackIndex: trackIndex,
                    position: position,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFF1E2436),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF06B6D4),
                child: Icon(Icons.folder_open_rounded, color: Colors.white),
              ),
              title: const Text('From Files / Storage', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Browse device files or downloads', style: TextStyle(color: Colors.white60)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await MediaPickerService.pickVideoFromFileStorage();
                if (picked != null && context.mounted) {
                  await _addClipFromPickedInfo(
                    context,
                    picked,
                    projectProvider,
                    trackIndex: trackIndex,
                    position: position,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFF1E2436),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF43F5E),
                child: Icon(Icons.videocam_rounded, color: Colors.white),
              ),
              title: const Text('Record with Camera', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Capture live video', style: TextStyle(color: Colors.white60)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await MediaPickerService.pickVideo(source: ImageSource.camera);
                if (picked != null && context.mounted) {
                  await _addClipFromPickedInfo(
                    context,
                    picked,
                    projectProvider,
                    trackIndex: trackIndex,
                    position: position,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTrackSheet(BuildContext context, ProjectProvider projectProvider) {
    final active = projectProvider.activeProject;
    if (active == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF161926),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Add New Timeline Track',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1E2436),
              leading: const Icon(Icons.video_collection_rounded, color: Color(0xFF06B6D4)),
              title: Text(
                'Video Track (V${active.videoTrackCount + 1})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Layer videos, b-roll or overlays above main video', style: TextStyle(color: Colors.white54, fontSize: 11)),
              trailing: const Icon(Icons.add, color: Color(0xFF06B6D4)),
              onTap: () {
                Navigator.pop(ctx);
                projectProvider.addVideoTrack();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1E2436),
              leading: const Icon(Icons.audiotrack_rounded, color: Color(0xFF10B981)),
              title: Text(
                'Audio Track (A${active.audioTrackCount + 1})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Add background music, voiceover or sound effect layer', style: TextStyle(color: Colors.white54, fontSize: 11)),
              trailing: const Icon(Icons.add, color: Color(0xFF10B981)),
              onTap: () {
                Navigator.pop(ctx);
                projectProvider.addAudioTrackLane();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final timelineProvider = context.watch<TimelineProvider>();
    final project = projectProvider.activeProject;

    if (project == null) return const SizedBox.shrink();

    final zoom = timelineProvider.zoomLevel;
    final pps = _getPixelsPerSecond(zoom);
    final totalDuration = project.totalDuration;
    final playheadX = _durationToPixels(timelineProvider.currentPosition, zoom);

    // Stacking: V{count-1} down to V0 (e.g. V3, V2, V1) like Premiere Pro
    final videoTrackIndices = List.generate(project.videoTrackCount, (i) => project.videoTrackCount - 1 - i);
    final audioTrackIndices = List.generate(project.audioTrackCount, (i) => i);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guarantee plenty of trailing space so the user can freely scroll past the end of the video
        final minScrollWidth = constraints.maxWidth + 400.0;
        final contentWidth = _durationToPixels(totalDuration, zoom) + 450.0;
        final totalTimelineWidth = math.max(minScrollWidth, contentWidth);

        return Container(
          color: const Color(0xFF0F111A),
          child: Row(
            children: [
              // -------------------------------------------------------------
              // 1. LEFT DOCK: Adobe Premiere Pro Style Track Headers (Fixed)
              // -------------------------------------------------------------
              Container(
                width: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF141724),
                  border: Border(
                    right: BorderSide(color: Color(0xFF262C40), width: 1.5),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ruler corner header spacer
                      Container(
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10131F),
                          border: Border(bottom: BorderSide(color: Color(0xFF262C40))),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.layers_rounded, color: Colors.white38, size: 14),
                            SizedBox(width: 3),
                            Text('TRACKS', style: TextStyle(color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      // Video Track Headers (Descending: V3, V2, V1)
                      ...videoTrackIndices.map((trackIdx) {
                        final isMuted = project.mutedVideoTracks.contains(trackIdx);
                        final isHidden = project.hiddenVideoTracks.contains(trackIdx);
                        final isLocked = project.lockedVideoTracks.contains(trackIdx);

                        return Container(
                          height: 52,
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181C2B),
                            border: Border(
                              left: BorderSide(
                                color: trackIdx == 0 ? const Color(0xFF06B6D4) : const Color(0xFF38BDF8),
                                width: 3,
                              ),
                              bottom: const BorderSide(color: Color(0xFF262C40), width: 0.5),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Track badge (e.g. V1, V2, V3)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'V${trackIdx + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Quick Add button for this track
                                  GestureDetector(
                                    onTap: () => _pickVideoClip(context, projectProvider, trackIndex: trackIdx),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.add, color: Colors.white70, size: 13),
                                    ),
                                  ),
                                ],
                              ),
                              // Controls: Eye (Hide), Mute, Lock
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  GestureDetector(
                                    onTap: () => projectProvider.toggleHideVideoTrack(trackIdx),
                                    child: Icon(
                                      isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 13,
                                      color: isHidden ? const Color(0xFFEF4444) : Colors.white60,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => projectProvider.toggleMuteVideoTrack(trackIdx),
                                    child: Icon(
                                      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                      size: 13,
                                      color: isMuted ? const Color(0xFFF59E0B) : Colors.white60,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => projectProvider.toggleLockVideoTrack(trackIdx),
                                    child: Icon(
                                      isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                      size: 13,
                                      color: isLocked ? const Color(0xFFF59E0B) : Colors.white30,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      // Text Track Header (T1)
                      Container(
                        height: 36,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF181C2B),
                          border: Border(
                            left: BorderSide(color: Color(0xFFA855F7), width: 3),
                            bottom: BorderSide(color: Color(0xFF262C40), width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TXT',
                                style: TextStyle(
                                  color: Color(0xFFC084FC),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                TextEditSheet.show(
                                  context: context,
                                  currentPosition: timelineProvider.currentPosition,
                                  onSave: projectProvider.addTextOverlay,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.add, color: Colors.white70, size: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Audio Track Headers (A1, A2, etc.)
                      ...audioTrackIndices.map((trackIdx) {
                        final isMuted = project.mutedAudioTracks.contains(trackIdx);
                        final isLocked = project.lockedAudioTracks.contains(trackIdx);

                        return Container(
                          height: 42,
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181C2B),
                            border: Border(
                              left: BorderSide(
                                color: trackIdx == 0 ? const Color(0xFF10B981) : const Color(0xFF34D399),
                                width: 3,
                              ),
                              bottom: const BorderSide(color: Color(0xFF262C40), width: 0.5),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'A${trackIdx + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF34D399),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      AudioPickerSheet.show(
                                        context: context,
                                        currentPosition: timelineProvider.currentPosition,
                                        onAudioSelected: (audio) {
                                          projectProvider.addAudioClipToTrack(
                                            audio,
                                            trackIndex: trackIdx,
                                            startTime: timelineProvider.currentPosition,
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.add, color: Colors.white70, size: 13),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  GestureDetector(
                                    onTap: () => projectProvider.toggleMuteAudioTrack(trackIdx),
                                    child: Icon(
                                      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                      size: 13,
                                      color: isMuted ? const Color(0xFFF59E0B) : Colors.white60,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => projectProvider.toggleLockAudioTrack(trackIdx),
                                    child: Icon(
                                      isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                      size: 13,
                                      color: isLocked ? const Color(0xFFF59E0B) : Colors.white30,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      // Add Track Header Button at Bottom
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(color: Color(0xFF262C40)),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 24),
                          ),
                          onPressed: () => _showAddTrackSheet(context, projectProvider),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 12),
                              SizedBox(width: 2),
                              Text('Track', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // 2. RIGHT DOCK: Horizontally Scrollable Lanes (No Gesture Trap)
              // -------------------------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: totalTimelineWidth,
                    child: Stack(
                      children: [
                        // Column of track lanes
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // A. Interactive Time Ruler for scrubbing
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) {
                                final tapX = details.localPosition.dx;
                                final tappedDuration = _pixelsToDuration(tapX, zoom);
                                timelineProvider.seekTo(tappedDuration);
                              },
                              onHorizontalDragUpdate: (details) {
                                final dragX = details.localPosition.dx;
                                final draggedDuration = _pixelsToDuration(dragX, zoom);
                                timelineProvider.seekTo(draggedDuration);
                              },
                              child: Container(
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10131F),
                                  border: Border(bottom: BorderSide(color: Color(0xFF262C40))),
                                ),
                                child: TimelineRuler(
                                  totalDuration: totalDuration + const Duration(seconds: 15),
                                  pixelsPerSecond: pps,
                                ),
                              ),
                            ),

                            // B. Video Track Lanes (Descending: V3, V2, V1)
                            ...videoTrackIndices.map((trackIdx) {
                              return _buildVideoTrackLane(
                                context,
                                project,
                                projectProvider,
                                timelineProvider,
                                trackIdx,
                                zoom,
                                totalTimelineWidth,
                              );
                            }),

                            // C. Text Overlay Track Lane
                            _buildTextTrackLane(
                              context,
                              project,
                              projectProvider,
                              timelineProvider,
                              zoom,
                              totalTimelineWidth,
                            ),

                            // D. Audio Track Lanes (A1, A2, etc.)
                            ...audioTrackIndices.map((trackIdx) {
                              return _buildAudioTrackLane(
                                context,
                                project,
                                projectProvider,
                                timelineProvider,
                                trackIdx,
                                zoom,
                                totalTimelineWidth,
                              );
                            }),

                            // Blank bottom buffer
                            const SizedBox(height: 24),
                          ],
                        ),

                        // E. Synchronized Playhead Needle (Interactive top head)
                        Positioned(
                          left: playheadX - 1.0,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            ignoring: false,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: (details) {
                                final newX = playheadX + details.delta.dx;
                                timelineProvider.seekTo(_pixelsToDuration(newX, zoom));
                              },
                              child: Column(
                                children: [
                                  // Top Draggable Scrubber Knob
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF06B6D4).withValues(alpha: 0.8),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F172A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Needle Line through all tracks
                                  Expanded(
                                    child: Container(
                                      width: 2.0,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Video Track Lane Widget ---
  Widget _buildVideoTrackLane(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
    int trackIndex,
    double zoom,
    double totalWidth,
  ) {
    final clipsOnTrack = (project.videoClips as List<VideoClipModel>)
        .where((c) => c.trackIndex == trackIndex)
        .toList();

    return Container(
      height: 52,
      width: totalWidth,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131726).withValues(alpha: 0.5),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1E2436), width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // Empty slot tap target to place clip at tapped point
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final tappedDuration = _pixelsToDuration(details.localPosition.dx, zoom);
                timelineProvider.seekTo(tappedDuration);
              },
              onDoubleTap: () {
                _pickVideoClip(
                  context,
                  projectProvider,
                  trackIndex: trackIndex,
                  position: timelineProvider.currentPosition,
                );
              },
            ),
          ),

          // Render clips on this track
          ...clipsOnTrack.map((clip) {
            final left = _durationToPixels(clip.startTime, zoom);
            final width = _durationToPixels(clip.duration, zoom);
            final isSelected = timelineProvider.selectedTrack == SelectedTrackType.video &&
                timelineProvider.selectedItemId == clip.id;

            return Positioned(
              left: left,
              top: 3,
              bottom: 3,
              width: width.clamp(36.0, 10000.0),
              child: GestureDetector(
                onTap: () {
                  timelineProvider.selectItem(SelectedTrackType.video, clip.id);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF38BDF8) : Colors.white24,
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF334155), Color(0xFF1E293B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Filmstrip frame markers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          (width / 36).clamp(1, 12).toInt(),
                          (i) => Icon(
                            Icons.crop_original_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      // Title & duration
                      Positioned(
                        left: 6,
                        top: 4,
                        right: isSelected ? 48 : 6,
                        child: Text(
                          clip.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 6,
                        bottom: 3,
                        child: Text(
                          '${(clip.duration.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Quick delete button if selected
                      if (isSelected)
                        Positioned(
                          right: 2,
                          top: 2,
                          bottom: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  projectProvider.removeVideoClip(clip.id);
                                  timelineProvider.clearSelection();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Subtle prompt if empty
          if (clipsOnTrack.isEmpty)
            Positioned(
              left: 12,
              top: 14,
              child: Text(
                'Track V${trackIndex + 1} empty (double-tap to add video)',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  // --- Text Overlay Track Lane Widget ---
  Widget _buildTextTrackLane(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
    double zoom,
    double totalWidth,
  ) {
    final texts = project.textOverlays as List<TextOverlayModel>;

    return Container(
      height: 36,
      width: totalWidth,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131726).withValues(alpha: 0.35),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E2436), width: 0.5)),
      ),
      child: Stack(
        children: texts.map((text) {
          final left = _durationToPixels(text.startTime, zoom);
          final width = _durationToPixels(text.duration, zoom);
          final isSelected = timelineProvider.selectedTrack == SelectedTrackType.text &&
              timelineProvider.selectedItemId == text.id;

          return Positioned(
            left: left,
            top: 2,
            bottom: 2,
            width: width.clamp(40.0, 10000.0),
            child: GestureDetector(
              onTap: () {
                timelineProvider.selectItem(SelectedTrackType.text, text.id);
                TextEditSheet.show(
                  context: context,
                  initialText: text,
                  currentPosition: text.startTime,
                  onSave: projectProvider.updateTextOverlay,
                  onDelete: () => projectProvider.removeTextOverlay(text.id),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.textTrack,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected ? Colors.white : AppColors.textTrackBorder,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.title_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        text.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Audio Track Lane Widget ---
  Widget _buildAudioTrackLane(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
    int trackIndex,
    double zoom,
    double totalWidth,
  ) {
    final audiosOnTrack = (project.audioTracks as List<AudioTrackModel>)
        .where((a) => a.trackIndex == trackIndex)
        .toList();

    return Container(
      height: 42,
      width: totalWidth,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131726).withValues(alpha: 0.4),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E2436), width: 0.5)),
      ),
      child: Stack(
        children: [
          // Empty slot tap target
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final tappedDuration = _pixelsToDuration(details.localPosition.dx, zoom);
                timelineProvider.seekTo(tappedDuration);
              },
            ),
          ),

          ...audiosOnTrack.map((audio) {
            final left = _durationToPixels(audio.startTime, zoom);
            final width = _durationToPixels(audio.duration, zoom);
            final isSelected = timelineProvider.selectedTrack == SelectedTrackType.audio &&
                timelineProvider.selectedItemId == audio.id;

            return Positioned(
              left: left,
              top: 2,
              bottom: 2,
              width: width.clamp(36.0, 10000.0),
              child: GestureDetector(
                onTap: () {
                  timelineProvider.selectItem(SelectedTrackType.audio, audio.id);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.audioTrack,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? Colors.white : AppColors.audioTrackBorder,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Simulated waveform
                      Positioned.fill(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            (width / 6).clamp(4, 50).toInt(),
                            (i) => Container(
                              width: 2,
                              height: 6.0 + ((i * 7) % 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 6,
                        top: 2,
                        child: Text(
                          audio.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 2,
                          top: 2,
                          bottom: 2,
                          child: GestureDetector(
                            onTap: () {
                              projectProvider.removeAudioTrack(audio.id);
                              timelineProvider.clearSelection();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
