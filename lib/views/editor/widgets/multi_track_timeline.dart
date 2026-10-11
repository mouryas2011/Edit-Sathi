import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/video_clip.dart';
import '../../../../models/text_overlay.dart';
import '../../../../models/audio_track.dart';
import '../../../../models/shape_overlay.dart';
import '../../../../models/adjustment_layer.dart';
import '../../../../models/keyframe.dart';
import '../../../../providers/timeline_provider.dart';
import '../../../../providers/project_provider.dart';
import '../../../../services/media_picker_service.dart';
import '../../../../theme/app_colors.dart';
import 'timeline_ruler.dart';
import 'sheets/text_edit_sheet.dart';
import 'sheets/audio_picker_sheet.dart';
import 'sheets/audio_edit_sheet.dart';
import 'sheets/shape_picker_sheet.dart';
import 'sheets/adjustment_layer_sheet.dart';
import 'sheets/speed_sheet.dart';
import 'sheets/filter_picker_sheet.dart';
import 'sheets/transform_sheet.dart';
import 'sheets/transition_sheet.dart';

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
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1E2436),
              leading: const Icon(Icons.tune_rounded, color: Color(0xFFF59E0B)),
              title: const Text(
                'Adjustment Layer',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Add color grading or LUT effect across all video tracks', style: TextStyle(color: Colors.white54, fontSize: 11)),
              trailing: const Icon(Icons.add, color: Color(0xFFF59E0B)),
              onTap: () {
                Navigator.pop(ctx);
                AdjustmentLayerSheet.show(
                  context: context,
                  currentPosition: context.read<TimelineProvider>().currentPosition,
                  totalProjectDuration: active.totalDuration,
                  onSave: (layer) => projectProvider.addAdjustmentLayer(layer),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1E2436),
              leading: const Icon(Icons.interests_rounded, color: Color(0xFF06B6D4)),
              title: const Text(
                'Graphic Shape Overlay',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Add box, circle, arrow, star or badge on timeline', style: TextStyle(color: Colors.white54, fontSize: 11)),
              trailing: const Icon(Icons.add, color: Color(0xFF06B6D4)),
              onTap: () {
                Navigator.pop(ctx);
                ShapePickerSheet.show(
                  context: context,
                  currentPosition: context.read<TimelineProvider>().currentPosition,
                  onShapeSelected: (shape) => projectProvider.addShape(shape),
                );
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

    final hasSelection = timelineProvider.selectedTrack != SelectedTrackType.none &&
        timelineProvider.selectedItemId != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guarantee plenty of trailing space so the user can freely scroll past the end of the video
        final minScrollWidth = constraints.maxWidth + 400.0;
        final contentWidth = _durationToPixels(totalDuration, zoom) + 450.0;
        final totalTimelineWidth = math.max(minScrollWidth, contentWidth);

        return Container(
          color: const Color(0xFF0F111A),
          child: Column(
            children: [
              if (hasSelection)
                _buildContextualClipActionBar(
                  context,
                  project,
                  projectProvider,
                  timelineProvider,
                ),
              Expanded(
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

                      // Adjustment Layer Track Header (ADJ)
                      Container(
                        height: 36,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF181C2B),
                          border: Border(
                            left: BorderSide(color: Color(0xFFF59E0B), width: 3),
                            bottom: BorderSide(color: Color(0xFF262C40), width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADJ',
                                style: TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                AdjustmentLayerSheet.show(
                                  context: context,
                                  currentPosition: timelineProvider.currentPosition,
                                  totalProjectDuration: project.totalDuration,
                                  onSave: projectProvider.addAdjustmentLayer,
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

                      // Shape Overlay Track Header (SHP)
                      Container(
                        height: 36,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF181C2B),
                          border: Border(
                            left: BorderSide(color: Color(0xFF06B6D4), width: 3),
                            bottom: BorderSide(color: Color(0xFF262C40), width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SHP',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                ShapePickerSheet.show(
                                  context: context,
                                  currentPosition: timelineProvider.currentPosition,
                                  onShapeSelected: projectProvider.addShape,
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

                            // C. Adjustment Layer Lane (Premiere Pro style)
                            _buildAdjustmentTrackLane(
                              context,
                              project,
                              projectProvider,
                              timelineProvider,
                              zoom,
                              totalTimelineWidth,
                            ),

                            // D. Shapes Lane
                            _buildShapeTrackLane(
                              context,
                              project,
                              projectProvider,
                              timelineProvider,
                              zoom,
                              totalTimelineWidth,
                            ),

                            // E. Text Overlay Track Lane
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
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Trim Handle Widget (CapCut / VN style) ---
  Widget _buildTrimHandle({
    required bool isLeft,
    required Color color,
    required GestureDragUpdateCallback onDragUpdate,
    required GestureDragEndCallback onDragEnd,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
      child: Container(
        width: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(5) : Radius.zero,
            right: !isLeft ? const Radius.circular(5) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 2.5,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    );
  }

  // --- Contextual Clip Action Button ---
  Widget _buildClipActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color bgColor = const Color(0xFF1E2436),
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Contextual Clip Quick-Action Bar (CapCut / VN Style) ---
  Widget _buildContextualClipActionBar(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
  ) {
    final trackType = timelineProvider.selectedTrack;
    final itemId = timelineProvider.selectedItemId;

    String itemLabel = 'Selected';
    Color themeColor = const Color(0xFF38BDF8);
    List<Widget> actionButtons = [];

    if (trackType == SelectedTrackType.video) {
      final clip = (project.videoClips as List<VideoClipModel>)
          .cast<VideoClipModel?>()
          .firstWhere((c) => c?.id == itemId, orElse: () => null);

      if (clip != null) {
        itemLabel = 'V${clip.trackIndex + 1}: ${clip.title}';
        themeColor = const Color(0xFF38BDF8);

        final playhead = timelineProvider.currentPosition;
        final localOffset = playhead - clip.startTime;
        final isPlayheadInsideClip = localOffset >= Duration.zero && localOffset <= clip.duration;
        final hasKeyframeHere = isPlayheadInsideClip && clip.keyframes.any(
          (k) => (k.timeOffset - localOffset).inMilliseconds.abs() < 120,
        );

        actionButtons = [
          _buildClipActionButton(
            icon: Icons.call_split_rounded,
            label: 'Split',
            color: const Color(0xFF38BDF8),
            onTap: () {
              final splitOk = projectProvider.splitClipAtPosition(
                clip.id,
                timelineProvider.currentPosition,
              );
              if (!splitOk) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Position playhead over clip to split'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          _buildClipActionButton(
            icon: Icons.auto_awesome_rounded,
            label: clip.transition != TransitionType.none ? clip.transition.label : 'Transition',
            color: const Color(0xFFF43F5E),
            onTap: () {
              TransitionSheet.show(
                context: context,
                currentTransition: clip.transition,
                currentDuration: clip.transitionDuration,
                onApply: (trans, dur, applyToAll) {
                  if (applyToAll) {
                    projectProvider.applyTransitionToAllClips(trans, duration: dur);
                  } else {
                    projectProvider.updateClipTransition(clip.id, trans, duration: dur);
                  }
                },
              );
            },
          ),
          _buildClipActionButton(
            icon: hasKeyframeHere ? Icons.remove_circle_outline_rounded : Icons.diamond_rounded,
            label: hasKeyframeHere ? '-◆ Keyframe' : '+◆ Keyframe',
            color: const Color(0xFFFBBF24),
            onTap: () {
              if (!isPlayheadInsideClip) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Move playhead inside this clip to place keyframe')),
                );
                return;
              }
              if (hasKeyframeHere) {
                projectProvider.removeKeyframeAtOffset(clip.id, localOffset);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Keyframe removed at playhead')),
                );
              } else {
                final kf = KeyframeModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  timeOffset: localOffset,
                  scale: clip.scale,
                  rotation: clip.rotation,
                  positionX: clip.positionX,
                  positionY: clip.positionY,
                );
                projectProvider.addOrUpdateKeyframe(clip.id, kf);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('◆ Keyframe added at playhead!')),
                );
              }
            },
          ),
          _buildClipActionButton(
            icon: Icons.transform_rounded,
            label: 'Transform',
            color: const Color(0xFF67E8F9),
            onTap: () {
              TransformSheet.show(
                context: context,
                clip: clip,
                onSave: (updated) => projectProvider.updateVideoClip(updated),
              );
            },
          ),
          _buildClipActionButton(
            icon: Icons.speed_rounded,
            label: clip.speedCurve != SpeedCurveType.none ? clip.speedCurve.label : '${clip.speed}x Speed',
            color: const Color(0xFFFBBF24),
            onTap: () {
              SpeedSheet.show(
                context: context,
                currentSpeed: clip.speed,
                currentCurve: clip.speedCurve,
                onSpeedSelected: (spd, curve) => projectProvider.updateVideoClip(
                  clip.copyWith(speed: spd, speedCurve: curve),
                ),
              );
            },
          ),
          _buildClipActionButton(
            icon: Icons.auto_fix_high_rounded,
            label: clip.filter.name,
            color: const Color(0xFFA78BFA),
            onTap: () {
              FilterPickerSheet.show(
                context: context,
                currentFilter: clip.filter,
                onFilterSelected: (flt) => projectProvider.updateClipFilter(clip.id, flt),
              );
            },
          ),
          _buildClipActionButton(
            icon: Icons.content_copy_rounded,
            label: 'Duplicate',
            color: Colors.white70,
            onTap: () => projectProvider.duplicateVideoClip(clip.id),
          ),
          _buildClipActionButton(
            icon: Icons.delete_sweep_rounded,
            label: 'Ripple Del',
            color: const Color(0xFFF59E0B),
            onTap: () {
              projectProvider.rippleDeleteClip(clip.id);
              timelineProvider.clearSelection();
            },
          ),
          _buildClipActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: const Color(0xFFF87171),
            bgColor: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
            onTap: () {
              projectProvider.removeVideoClip(clip.id);
              timelineProvider.clearSelection();
            },
          ),
        ];
      }
    } else if (trackType == SelectedTrackType.audio) {
      final audio = (project.audioTracks as List<AudioTrackModel>)
          .cast<AudioTrackModel?>()
          .firstWhere((a) => a?.id == itemId, orElse: () => null);

      if (audio != null) {
        itemLabel = 'A${audio.trackIndex + 1}: ${audio.title}';
        themeColor = const Color(0xFF10B981);
        actionButtons = [
          _buildClipActionButton(
            icon: Icons.tune_rounded,
            label: 'Audio Studio',
            color: const Color(0xFF10B981),
            onTap: () {
              AudioEditSheet.show(
                context: context,
                track: audio,
                onSave: (updated) => projectProvider.updateAudioTrack(updated),
              );
            },
          ),
          _buildClipActionButton(
            icon: Icons.call_split_rounded,
            label: 'Split',
            color: const Color(0xFF34D399),
            onTap: () {
              final splitOk = projectProvider.splitAudioClipAtPosition(
                audio.id,
                timelineProvider.currentPosition,
              );
              if (!splitOk) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Position playhead over audio to split'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          _buildClipActionButton(
            icon: Icons.content_copy_rounded,
            label: 'Duplicate',
            color: Colors.white70,
            onTap: () => projectProvider.duplicateAudioClip(audio.id),
          ),
          _buildClipActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: const Color(0xFFF87171),
            bgColor: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
            onTap: () {
              projectProvider.removeAudioTrack(audio.id);
              timelineProvider.clearSelection();
            },
          ),
        ];
      }
    } else if (trackType == SelectedTrackType.text) {
      final text = (project.textOverlays as List<TextOverlayModel>)
          .cast<TextOverlayModel?>()
          .firstWhere((t) => t?.id == itemId, orElse: () => null);

      if (text != null) {
        itemLabel = 'Text: "${text.text}"';
        themeColor = const Color(0xFFA855F7);
        actionButtons = [
          _buildClipActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Edit Text',
            color: const Color(0xFFC084FC),
            onTap: () {
              TextEditSheet.show(
                context: context,
                initialText: text,
                currentPosition: text.startTime,
                onSave: projectProvider.updateTextOverlay,
                onDelete: () {
                  projectProvider.removeTextOverlay(text.id);
                  timelineProvider.clearSelection();
                },
              );
            },
          ),
          _buildClipActionButton(
            icon: Icons.content_copy_rounded,
            label: 'Duplicate',
            color: Colors.white70,
            onTap: () => projectProvider.duplicateTextOverlay(text.id),
          ),
          _buildClipActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: const Color(0xFFF87171),
            bgColor: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
            onTap: () {
              projectProvider.removeTextOverlay(text.id);
              timelineProvider.clearSelection();
            },
          ),
        ];
      }
    } else if (trackType == SelectedTrackType.shape) {
      final shape = (project.shapes as List<ShapeOverlayModel>)
          .cast<ShapeOverlayModel?>()
          .firstWhere((s) => s?.id == itemId, orElse: () => null);

      if (shape != null) {
        itemLabel = 'Shape: ${shape.type.name}';
        themeColor = const Color(0xFF06B6D4);
        actionButtons = [
          _buildClipActionButton(
            icon: Icons.interests_rounded,
            label: 'Edit Shape',
            color: const Color(0xFF67E8F9),
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
          ),
          _buildClipActionButton(
            icon: Icons.content_copy_rounded,
            label: 'Duplicate',
            color: Colors.white70,
            onTap: () => projectProvider.duplicateShape(shape.id),
          ),
          _buildClipActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: const Color(0xFFF87171),
            bgColor: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
            onTap: () {
              projectProvider.removeShape(shape.id);
              timelineProvider.clearSelection();
            },
          ),
        ];
      }
    } else if (trackType == SelectedTrackType.adjustment) {
      final layer = (project.adjustmentLayers as List<AdjustmentLayerModel>)
          .cast<AdjustmentLayerModel?>()
          .firstWhere((l) => l?.id == itemId, orElse: () => null);

      if (layer != null) {
        itemLabel = 'Adj: ${layer.title}';
        themeColor = const Color(0xFFF59E0B);
        actionButtons = [
          _buildClipActionButton(
            icon: Icons.tune_rounded,
            label: 'Edit Filter',
            color: const Color(0xFFFDE68A),
            onTap: () {
              AdjustmentLayerSheet.show(
                context: context,
                initialLayer: layer,
                currentPosition: layer.startTime,
                totalProjectDuration: project.totalDuration,
                onSave: projectProvider.updateAdjustmentLayer,
                onDelete: () {
                  projectProvider.removeAdjustmentLayer(layer.id);
                  timelineProvider.clearSelection();
                },
              );
            },
          ),
          _buildClipActionButton(
            icon: Icons.content_copy_rounded,
            label: 'Duplicate',
            color: Colors.white70,
            onTap: () => projectProvider.duplicateAdjustmentLayer(layer.id),
          ),
          _buildClipActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: const Color(0xFFF87171),
            bgColor: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
            onTap: () {
              projectProvider.removeAdjustmentLayer(layer.id);
              timelineProvider.clearSelection();
            },
          ),
        ];
      }
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131726),
        border: Border(
          bottom: BorderSide(
            color: themeColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selected item pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: themeColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 12, color: themeColor),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    itemLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Scrollable action buttons
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: actionButtons,
              ),
            ),
          ),

          // Close / Deselect button
          InkWell(
            onTap: () => timelineProvider.clearSelection(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
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
          // Empty slot tap target: tap clears selection and seeks; double tap adds clip
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                timelineProvider.clearSelection();
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
            final actualW = math.max(44.0, width);

            return Positioned(
              left: left,
              top: 3,
              bottom: 3,
              width: actualW,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Clip Body: Tap to select, drag horizontally to slide/reposition along track
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        timelineProvider.selectItem(SelectedTrackType.video, clip.id);
                      },
                      onHorizontalDragUpdate: (details) {
                        final delta = _pixelsToDuration(details.delta.dx, zoom);
                        var newStart = clip.startTime + delta;
                        if (newStart < Duration.zero) newStart = Duration.zero;

                        // Magnetic Snapping
                        if (_durationToPixels(newStart, zoom) < 14) newStart = Duration.zero;
                        final playheadDist = (_durationToPixels(newStart, zoom) - _durationToPixels(timelineProvider.currentPosition, zoom)).abs();
                        if (playheadDist < 14) newStart = timelineProvider.currentPosition;

                        projectProvider.moveVideoClip(clip.id, newStart);
                      },
                      onHorizontalDragEnd: (_) {
                        projectProvider.commitVideoClipMove(clip.id);
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
                                (actualW / 36).clamp(1, 12).toInt(),
                                (i) => Icon(
                                  Icons.crop_original_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            // Title & duration
                            Positioned(
                              left: isSelected ? 22 : 6,
                              top: 4,
                              right: isSelected ? 22 : 6,
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
                              left: isSelected ? 22 : 6,
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
                            // Keyframe diamond markers (Premiere / CapCut style)
                            ...clip.keyframes.map((kf) {
                              final kfLeft = _durationToPixels(kf.timeOffset, zoom);
                              return Positioned(
                                left: (kfLeft - 5).clamp(2.0, actualW - 12),
                                top: 14,
                                child: const Icon(
                                  Icons.diamond_rounded,
                                  size: 11,
                                  color: Color(0xFFFBBF24),
                                ),
                              );
                            }),
                            // Transition indicator badge
                            if (clip.transition != TransitionType.none)
                              Positioned(
                                right: 4,
                                bottom: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF43F5E),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    clip.transition.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Left Trim Handle (In-Point)
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: true,
                        color: const Color(0xFF38BDF8),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimVideoClipStart(clip.id, delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitVideoClipMove(clip.id);
                        },
                      ),
                    ),

                  // Right Trim Handle (Out-Point)
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: false,
                        color: const Color(0xFF38BDF8),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimVideoClipEnd(clip.id, clip.duration + delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitVideoClipMove(clip.id);
                        },
                      ),
                    ),

                  // Interactive Transition Badge Button between clips on Track 0 (CapCut / VN style)
                  if (clip.trackIndex == 0)
                    Positioned(
                      right: -10,
                      top: 10,
                      child: GestureDetector(
                        onTap: () {
                          TransitionSheet.show(
                            context: context,
                            currentTransition: clip.transition,
                            currentDuration: clip.transitionDuration,
                            onApply: (trans, dur, applyToAll) {
                              if (applyToAll) {
                                projectProvider.applyTransitionToAllClips(trans, duration: dur);
                              } else {
                                projectProvider.updateClipTransition(clip.id, trans, duration: dur);
                              }
                            },
                          );
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: clip.transition != TransitionType.none
                                ? const Color(0xFFF43F5E)
                                : const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: clip.transition != TransitionType.none
                                  ? Colors.white
                                  : Colors.white54,
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            clip.transition != TransitionType.none
                                ? clip.transition.icon
                                : Icons.hourglass_empty_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
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
        children: [
          // Empty slot tap target: tap clears selection and seeks
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                timelineProvider.clearSelection();
                final tappedDuration = _pixelsToDuration(details.localPosition.dx, zoom);
                timelineProvider.seekTo(tappedDuration);
              },
            ),
          ),

          ...texts.map((text) {
            final left = _durationToPixels(text.startTime, zoom);
            final width = _durationToPixels(text.duration, zoom);
            final isSelected = timelineProvider.selectedTrack == SelectedTrackType.text &&
                timelineProvider.selectedItemId == text.id;
            final actualW = math.max(44.0, width);

            return Positioned(
              left: left,
              top: 2,
              bottom: 2,
              width: actualW,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Text clip body: tap to select, drag to reposition along track
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        timelineProvider.selectItem(SelectedTrackType.text, text.id);
                      },
                      onHorizontalDragUpdate: (details) {
                        final delta = _pixelsToDuration(details.delta.dx, zoom);
                        var newStart = text.startTime + delta;
                        if (newStart < Duration.zero) newStart = Duration.zero;

                        if (_durationToPixels(newStart, zoom) < 14) newStart = Duration.zero;
                        final playheadDist = (_durationToPixels(newStart, zoom) - _durationToPixels(timelineProvider.currentPosition, zoom)).abs();
                        if (playheadDist < 14) newStart = timelineProvider.currentPosition;

                        projectProvider.moveTextOverlay(text.id, newStart);
                      },
                      onHorizontalDragEnd: (_) {
                        projectProvider.commitTextOverlayMove(text.id);
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                          left: isSelected ? 22 : 6,
                          right: isSelected ? 22 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textTrack,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFA855F7) : AppColors.textTrackBorder,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
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
                  ),

                  // Left Trim Handle (In-Point)
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: true,
                        color: const Color(0xFFA855F7),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimTextOverlayStart(text.id, delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitTextOverlayMove(text.id);
                        },
                      ),
                    ),

                  // Right Trim Handle (Out-Point)
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: false,
                        color: const Color(0xFFA855F7),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimTextOverlay(text.id, text.duration + delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitTextOverlayMove(text.id);
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
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
          // Empty slot tap target: tap clears selection and seeks
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                timelineProvider.clearSelection();
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
            final actualW = math.max(44.0, width);

            return Positioned(
              left: left,
              top: 2,
              bottom: 2,
              width: actualW,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Audio clip body: tap to select, drag to reposition along track
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        timelineProvider.selectItem(SelectedTrackType.audio, audio.id);
                      },
                      onHorizontalDragUpdate: (details) {
                        final delta = _pixelsToDuration(details.delta.dx, zoom);
                        var newStart = audio.startTime + delta;
                        if (newStart < Duration.zero) newStart = Duration.zero;

                        if (_durationToPixels(newStart, zoom) < 14) newStart = Duration.zero;
                        final playheadDist = (_durationToPixels(newStart, zoom) - _durationToPixels(timelineProvider.currentPosition, zoom)).abs();
                        if (playheadDist < 14) newStart = timelineProvider.currentPosition;

                        projectProvider.moveAudioClip(audio.id, newStart);
                      },
                      onHorizontalDragEnd: (_) {
                        projectProvider.commitAudioClipMove(audio.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.audioTrack,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF10B981) : AppColors.audioTrackBorder,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Simulated waveform
                            Positioned.fill(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  (actualW / 6).clamp(4, 50).toInt(),
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
                              left: isSelected ? 22 : 6,
                              top: 2,
                              right: isSelected ? 22 : 6,
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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Left Trim Handle (In-Point)
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: true,
                        color: const Color(0xFF10B981),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimAudioClipStart(audio.id, delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitAudioClipMove(audio.id);
                        },
                      ),
                    ),

                  // Right Trim Handle (Out-Point)
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: false,
                        color: const Color(0xFF10B981),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimAudioClip(audio.id, audio.duration + delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitAudioClipMove(audio.id);
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Adjustment Layer Track Lane Widget ---
  Widget _buildAdjustmentTrackLane(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
    double zoom,
    double totalWidth,
  ) {
    final adjLayers = project.adjustmentLayers as List<AdjustmentLayerModel>;

    return Container(
      height: 36,
      width: totalWidth,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131726).withValues(alpha: 0.35),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E2436), width: 0.5)),
      ),
      child: Stack(
        children: [
          // Empty slot tap target: tap clears selection and seeks
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                timelineProvider.clearSelection();
                final tappedDuration = _pixelsToDuration(details.localPosition.dx, zoom);
                timelineProvider.seekTo(tappedDuration);
              },
            ),
          ),

          ...adjLayers.map((layer) {
            final left = _durationToPixels(layer.startTime, zoom);
            final width = _durationToPixels(layer.duration, zoom);
            final isSelected = timelineProvider.selectedTrack == SelectedTrackType.adjustment &&
                timelineProvider.selectedItemId == layer.id;
            final actualW = math.max(44.0, width);

            return Positioned(
              left: left,
              top: 2,
              bottom: 2,
              width: actualW,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Adjustment Layer body: tap to select, drag horizontally to slide
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        timelineProvider.selectItem(SelectedTrackType.adjustment, layer.id);
                      },
                      onHorizontalDragUpdate: (details) {
                        final delta = _pixelsToDuration(details.delta.dx, zoom);
                        var newStart = layer.startTime + delta;
                        if (newStart < Duration.zero) newStart = Duration.zero;

                        if (_durationToPixels(newStart, zoom) < 14) newStart = Duration.zero;
                        final playheadDist = (_durationToPixels(newStart, zoom) - _durationToPixels(timelineProvider.currentPosition, zoom)).abs();
                        if (playheadDist < 14) newStart = timelineProvider.currentPosition;

                        projectProvider.moveAdjustmentLayer(layer.id, newStart);
                      },
                      onHorizontalDragEnd: (_) {
                        projectProvider.commitAdjustmentLayerMove(layer.id);
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                          left: isSelected ? 22 : 6,
                          right: isSelected ? 22 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB45309), Color(0xFF78350F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 12, color: Color(0xFFFDE68A)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${layer.title} (${layer.filter.name})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Left Trim Handle (In-Point)
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: true,
                        color: const Color(0xFFF59E0B),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimAdjustmentLayerStart(layer.id, delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitAdjustmentLayerMove(layer.id);
                        },
                      ),
                    ),

                  // Right Trim Handle (Out-Point)
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: false,
                        color: const Color(0xFFF59E0B),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimAdjustmentLayer(layer.id, layer.duration + delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitAdjustmentLayerMove(layer.id);
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Shape Overlay Track Lane Widget ---
  Widget _buildShapeTrackLane(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
    double zoom,
    double totalWidth,
  ) {
    final shapes = project.shapes as List<ShapeOverlayModel>;

    return Container(
      height: 36,
      width: totalWidth,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131726).withValues(alpha: 0.35),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E2436), width: 0.5)),
      ),
      child: Stack(
        children: [
          // Empty slot tap target: tap clears selection and seeks
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                timelineProvider.clearSelection();
                final tappedDuration = _pixelsToDuration(details.localPosition.dx, zoom);
                timelineProvider.seekTo(tappedDuration);
              },
            ),
          ),

          ...shapes.map((shape) {
            final left = _durationToPixels(shape.startTime, zoom);
            final width = _durationToPixels(shape.duration, zoom);
            final isSelected = timelineProvider.selectedTrack == SelectedTrackType.shape &&
                timelineProvider.selectedItemId == shape.id;
            final actualW = math.max(44.0, width);

            return Positioned(
              left: left,
              top: 2,
              bottom: 2,
              width: actualW,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Shape body: tap to select, drag horizontally to slide
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        timelineProvider.selectItem(SelectedTrackType.shape, shape.id);
                      },
                      onHorizontalDragUpdate: (details) {
                        final delta = _pixelsToDuration(details.delta.dx, zoom);
                        var newStart = shape.startTime + delta;
                        if (newStart < Duration.zero) newStart = Duration.zero;

                        if (_durationToPixels(newStart, zoom) < 14) newStart = Duration.zero;
                        final playheadDist = (_durationToPixels(newStart, zoom) - _durationToPixels(timelineProvider.currentPosition, zoom)).abs();
                        if (playheadDist < 14) newStart = timelineProvider.currentPosition;

                        projectProvider.moveShape(shape.id, newStart);
                      },
                      onHorizontalDragEnd: (_) {
                        projectProvider.commitShapeMove(shape.id);
                      },
                      child: Container(
                        padding: EdgeInsets.only(
                          left: isSelected ? 22 : 6,
                          right: isSelected ? 22 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0E7490), Color(0xFF155E75)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF0891B2),
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.interests_rounded, size: 12, color: Color(0xFF67E8F9)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Shape: ${shape.type.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Left Trim Handle (In-Point)
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: true,
                        color: const Color(0xFF06B6D4),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimShapeStart(shape.id, delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitShapeMove(shape.id);
                        },
                      ),
                    ),

                  // Right Trim Handle (Out-Point)
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildTrimHandle(
                        isLeft: false,
                        color: const Color(0xFF06B6D4),
                        onDragUpdate: (details) {
                          final delta = _pixelsToDuration(details.delta.dx, zoom);
                          projectProvider.trimShape(shape.id, shape.duration + delta);
                        },
                        onDragEnd: (_) {
                          projectProvider.commitShapeMove(shape.id);
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
