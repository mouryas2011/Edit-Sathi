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
import 'sheets/aspect_ratio_sheet.dart';

class MultiTrackTimeline extends StatefulWidget {
  const MultiTrackTimeline({super.key});

  @override
  State<MultiTrackTimeline> createState() => _MultiTrackTimelineState();
}

class _MultiTrackTimelineState extends State<MultiTrackTimeline> {
  final ScrollController _scrollController = ScrollController();

  // Pixels per second at 1.0 zoom (e.g. 35 pixels = 1 second)
  final double _basePixelsPerSecond = 32.0;

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
    ProjectProvider projectProvider,
  ) async {
    final cleanTitle = picked.name.contains('.')
        ? picked.name.split('.').first
        : picked.name;

    final newClip = VideoClipModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourcePath: picked.path,
      title: cleanTitle.isNotEmpty ? cleanTitle : 'New Clip',
      startTime: Duration.zero, // projectProvider places it sequentially
      duration: picked.duration,
      sourceDuration: picked.duration,
    );

    projectProvider.addVideoClip(newClip);
    final active = projectProvider.activeProject;
    if (active != null && context.mounted) {
      context.read<TimelineProvider>().setTotalDuration(active.totalDuration);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added clip: $cleanTitle'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickNewVideoClip(
    BuildContext context,
    ProjectProvider projectProvider,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF161924),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            const Text(
              'Add Video Clip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF8B5CF6),
                child: Icon(Icons.photo_library_rounded, color: Colors.white),
              ),
              title: const Text('From Gallery / Photos', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Pick video from gallery', style: TextStyle(color: Colors.white60)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await MediaPickerService.pickVideo(source: ImageSource.gallery);
                if (picked != null && context.mounted) {
                  await _addClipFromPickedInfo(context, picked, projectProvider);
                }
              },
            ),
            ListTile(
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
                  await _addClipFromPickedInfo(context, picked, projectProvider);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF43F5E),
                child: Icon(Icons.videocam_rounded, color: Colors.white),
              ),
              title: const Text('Record Video with Camera', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Capture video directly', style: TextStyle(color: Colors.white60)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await MediaPickerService.pickVideo(source: ImageSource.camera);
                if (picked != null && context.mounted) {
                  await _addClipFromPickedInfo(context, picked, projectProvider);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF59E0B),
                child: Icon(Icons.movie_creation_outlined, color: Colors.white),
              ),
              title: const Text('Add Sample Scene Clip', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Insert a sample scene for testing', style: TextStyle(color: Colors.white60)),
              onTap: () {
                Navigator.of(ctx).pop();
                final clipNumber = (projectProvider.activeProject?.videoClips.length ?? 0) + 1;
                final newClip = VideoClipModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  sourcePath: 'assets/sample_clip_$clipNumber.mp4',
                  title: 'Scene Clip $clipNumber',
                  startTime: Duration.zero,
                  duration: const Duration(seconds: 8),
                  sourceDuration: const Duration(seconds: 12),
                  filter: VideoFilterPreset.cinematic,
                );
                projectProvider.addVideoClip(newClip);
                final active = projectProvider.activeProject;
                if (active != null && context.mounted) {
                  context.read<TimelineProvider>().setTotalDuration(active.totalDuration);
                }
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
    final totalTimelineWidth = _durationToPixels(totalDuration, zoom) + 160.0;
    final playheadX = _durationToPixels(timelineProvider.currentPosition, zoom);

    return Container(
      color: AppColors.editorSurface,
      child: Row(
        children: [
          // Left Dock with Quick Track Icons (Aspect, Text, Audio, Stickers)
          Container(
            width: 44,
            decoration: const BoxDecoration(
              color: AppColors.editorBg,
              border: Border(
                right: BorderSide(color: AppColors.editorBorder, width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _DockIconButton(
                  icon: Icons.crop_rotate_rounded,
                  tooltip: 'Aspect Ratio',
                  onTap: () {
                    AspectRatioSheet.show(
                      context: context,
                      currentRatio: project.aspectRatio,
                      onRatioSelected: projectProvider.updateAspectRatio,
                    );
                  },
                ),
                const SizedBox(height: 18),
                _DockIconButton(
                  icon: Icons.title_rounded,
                  tooltip: 'Add Text',
                  onTap: () {
                    TextEditSheet.show(
                      context: context,
                      currentPosition: timelineProvider.currentPosition,
                      onSave: projectProvider.addTextOverlay,
                    );
                  },
                ),
                const SizedBox(height: 18),
                _DockIconButton(
                  icon: Icons.music_note_rounded,
                  tooltip: 'Add Audio',
                  onTap: () {
                    AudioPickerSheet.show(
                      context: context,
                      currentPosition: timelineProvider.currentPosition,
                      onAudioSelected: projectProvider.addAudioTrack,
                    );
                  },
                ),
                const SizedBox(height: 18),
                _DockIconButton(
                  icon: Icons.auto_awesome_rounded,
                  tooltip: 'Auto Magic',
                  onTap: projectProvider.applyBeatSync,
                ),
              ],
            ),
          ),

          // Main Scrollable Timeline Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: GestureDetector(
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
                    child: SizedBox(
                      width: totalTimelineWidth.clamp(
                        constraints.maxWidth,
                        double.infinity,
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Time Ruler
                              TimelineRuler(
                                totalDuration: totalDuration,
                                pixelsPerSecond: pps,
                              ),
                              const SizedBox(height: 6),

                              // 2. Video Clips Track
                              _buildVideoTrack(
                                context,
                                project,
                                projectProvider,
                                timelineProvider,
                                zoom,
                              ),
                              const SizedBox(height: 8),

                              // 3. Text Overlay Track (Purple pill)
                              _buildTextTrack(
                                context,
                                project,
                                projectProvider,
                                timelineProvider,
                                zoom,
                              ),
                              const SizedBox(height: 8),

                              // 4. Audio Track (Teal pill with waveform)
                              _buildAudioTrack(
                                context,
                                project,
                                projectProvider,
                                timelineProvider,
                                zoom,
                              ),
                              const SizedBox(height: 8),

                              // 5. Secondary / Transition Track
                              _buildSecondaryTrack(
                                project,
                                zoom,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),

                          // Synchronized Playhead Line
                          Positioned(
                            left: playheadX - 1.0,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  // White vertical line
                                  Container(
                                    width: 2.0,
                                    color: Colors.white,
                                  ),
                                  // Top cursor handle
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Video Track Builder ---
  Widget _buildVideoTrack(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
    double zoom,
  ) {
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...project.videoClips.map((VideoClipModel clip) {
            final clipWidth = _durationToPixels(clip.duration, zoom);
            final isSelected =
                timelineProvider.selectedTrack == SelectedTrackType.video &&
                timelineProvider.selectedItemId == clip.id;

            return GestureDetector(
              onTap: () {
                timelineProvider.selectItem(SelectedTrackType.video, clip.id);
              },
              child: Container(
                width: clipWidth.clamp(36.0, 1000.0),
                height: 50,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.videoTrackBorder : Colors.white24,
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF334155), Color(0xFF1E293B)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Simulated video filmstrip frame icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        (clipWidth / 40).clamp(1, 10).toInt(),
                        (i) => Icon(
                          Icons.image_outlined,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    // Label
                    Positioned(
                      left: 6,
                      bottom: 4,
                      child: Text(
                        clip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // "+" Add Media Clip Button at end of video track
          GestureDetector(
            onTap: () => _pickNewVideoClip(context, projectProvider),
            child: Container(
              width: 44,
              height: 48,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white30, width: 1),
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Text Overlay Track Builder ---
  Widget _buildTextTrack(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
    double zoom,
  ) {
    if (project.textOverlays.isEmpty) return const SizedBox(height: 28);

    return SizedBox(
      height: 32,
      child: Stack(
        children: project.textOverlays.map<Widget>((TextOverlayModel text) {
          final left = _durationToPixels(text.startTime, zoom);
          final width = _durationToPixels(text.duration, zoom);
          final isSelected =
              timelineProvider.selectedTrack == SelectedTrackType.text &&
              timelineProvider.selectedItemId == text.id;

          return Positioned(
            left: left,
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
                width: width.clamp(50.0, 1000.0),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.textTrack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : AppColors.textTrackBorder,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textTrack.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.title, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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

  // --- Audio Track Builder (Teal Pill with Waveform) ---
  Widget _buildAudioTrack(
    BuildContext context,
    dynamic project,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
    double zoom,
  ) {
    if (project.audioTracks.isEmpty) return const SizedBox(height: 32);

    return SizedBox(
      height: 34,
      child: Stack(
        children: project.audioTracks.map<Widget>((AudioTrackModel audio) {
          final left = _durationToPixels(audio.startTime, zoom);
          final width = _durationToPixels(audio.duration, zoom);
          final isSelected =
              timelineProvider.selectedTrack == SelectedTrackType.audio &&
              timelineProvider.selectedItemId == audio.id;

          return Positioned(
            left: left,
            child: GestureDetector(
              onTap: () {
                timelineProvider.selectItem(SelectedTrackType.audio, audio.id);
              },
              child: Container(
                width: width.clamp(60.0, 1000.0),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.audioTrack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: isSelected ? 2.0 : 0.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      audio.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Waveform visualizer bars
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          (width / 7).clamp(4, 40).toInt(),
                          (i) {
                            final h = (i % 3 == 0)
                                ? 16.0
                                : ((i % 2 == 0) ? 10.0 : 6.0);
                            return Container(
                              width: 2.0,
                              height: h,
                              color: Colors.white.withValues(alpha: 0.8),
                            );
                          },
                        ),
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

  // --- Secondary Track (B-Roll / Ambient Layer) ---
  Widget _buildSecondaryTrack(dynamic project, double zoom) {
    final width = _durationToPixels(project.totalDuration, zoom);

    return SizedBox(
      height: 28,
      child: Stack(
        children: [
          Container(
            width: width,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                (width / 60).clamp(1, 15).toInt(),
                (i) => Icon(
                  Icons.auto_fix_high_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _DockIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
        ),
      ),
    );
  }
}
