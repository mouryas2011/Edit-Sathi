import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/video_clip.dart';
import '../../../../providers/timeline_provider.dart';
import '../../../../providers/project_provider.dart';

class VideoPreviewCanvas extends StatelessWidget {
  const VideoPreviewCanvas({super.key});

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

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectProvider>().activeProject;
    final timeline = context.watch<TimelineProvider>();

    if (project == null) return const SizedBox.shrink();

    final currentPos = timeline.currentPosition;
    final totalDuration = project.totalDuration;

    // Find current active video clip
    VideoClipModel? activeClip;
    for (final clip in project.videoClips) {
      if (currentPos >= clip.startTime && currentPos <= clip.endTime) {
        activeClip = clip;
        break;
      }
    }

    // Active text overlays at this point in time
    final activeTexts = project.textOverlays.where((t) {
      return currentPos >= t.startTime && currentPos <= t.endTime;
    }).toList();

    final activeFilter = activeClip?.filter != VideoFilterPreset.none
        ? activeClip!.filter
        : project.globalFilter;
    final colorFilter = _getColorFilter(activeFilter);

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
                // Background visual layer (Simulated realistic video footage with filter)
                ColorFiltered(
                  colorFilter: colorFilter ??
                      const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
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
                        // Stylized cafe portrait graphic or scene representation
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                activeClip != null
                                    ? Icons.videocam_rounded
                                    : Icons.movie_outlined,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Live Active Text Overlays rendered on canvas!
                ...activeTexts.map((textModel) {
                  return Align(
                    alignment: Alignment(
                      textModel.positionX,
                      textModel.positionY,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: textModel.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        textModel.text,
                        style: TextStyle(
                          color: textModel.fontColor,
                          fontSize: textModel.fontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  );
                }),

                // Center Play/Pause button overlay
                if (!timeline.isPlaying)
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white60, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),

                // Canvas Controls (Fullscreen toggle bottom-left, Timecode bottom-right)
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Timecode Pill (Matching mockup: "00:08 / 00:28")
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
}
