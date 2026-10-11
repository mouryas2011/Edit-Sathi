import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/project_provider.dart';
import '../../../../providers/timeline_provider.dart';
import '../../../../theme/app_colors.dart';

class TimelineTransportControls extends StatelessWidget {
  final VoidCallback? onAddVideoTrack;
  final VoidCallback? onAddAudioTrack;

  const TimelineTransportControls({
    super.key,
    this.onAddVideoTrack,
    this.onAddAudioTrack,
  });

  String _formatPreciseDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  void _showAddTrackMenu(BuildContext context, ProjectProvider projectProvider) {
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
            Row(
              children: [
                const Icon(Icons.layers_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Add Timeline Track',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tracks: ${active.videoTrackCount}V / ${active.audioTrackCount}A',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1E2436),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.video_collection_rounded, color: Color(0xFF06B6D4), size: 22),
              ),
              title: Text(
                'Add Video Track (V${active.videoTrackCount + 1})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Add an overlay video/b-roll track layer',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF06B6D4)),
              onTap: () {
                Navigator.pop(ctx);
                projectProvider.addVideoTrack();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added Video Track V${active.videoTrackCount + 1}'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF06B6D4),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1E2436),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.audiotrack_rounded, color: Color(0xFF10B981), size: 22),
              ),
              title: Text(
                'Add Audio Track (A${active.audioTrackCount + 1})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Add background music or SFX track layer',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
              onTap: () {
                Navigator.pop(ctx);
                projectProvider.addAudioTrackLane();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added Audio Track A${active.audioTrackCount + 1}'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF10B981),
                  ),
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
    final timeline = context.watch<TimelineProvider>();
    final projectProvider = context.watch<ProjectProvider>();
    final project = projectProvider.activeProject;

    final currentPos = timeline.currentPosition;
    final totalDuration = project?.totalDuration ?? timeline.totalDuration;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121520),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          // 1. Timecode Indicator (Monospace, high readability)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPreciseDuration(currentPos),
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  ' / ${_formatPreciseDuration(totalDuration)}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // 2. Undo / Redo
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 19),
            color: projectProvider.canUndo ? Colors.white70 : Colors.white24,
            tooltip: 'Undo',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: projectProvider.canUndo ? projectProvider.undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 19),
            color: projectProvider.canRedo ? Colors.white70 : Colors.white24,
            tooltip: 'Redo',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: projectProvider.canRedo ? projectProvider.redo : null,
          ),

          const Spacer(),

          // 3. Central Transport Group (Step Backward, Big Play/Pause, Step Forward)
          // Step -1s
          IconButton(
            icon: const Icon(Icons.replay_rounded, size: 21),
            color: Colors.white70,
            tooltip: 'Step -1s',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => timeline.stepBackward(),
          ),

          const SizedBox(width: 4),

          // BIG VIBRANT PLAY / PAUSE BUTTON
          GestureDetector(
            onTap: () => timeline.togglePlayPause(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                timeline.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Step +1s
          IconButton(
            icon: const Icon(Icons.forward_rounded, size: 21),
            color: Colors.white70,
            tooltip: 'Step +1s',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => timeline.stepForward(),
          ),

          const Spacer(),

          // 4. Split Action Button
          IconButton(
            icon: const Icon(Icons.content_cut_rounded, size: 19),
            color: const Color(0xFFF59E0B),
            tooltip: 'Split Clip at Playhead',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              final didSplit = projectProvider.splitClipAtPlayhead(currentPos);
              if (didSplit) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Split clip at current playhead position'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Place playhead over a clip to split it'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),

          // 5. Zoom In/Out
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 17),
            color: Colors.white54,
            tooltip: 'Zoom Out',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: () => timeline.zoomOut(),
          ),
          Text(
            '${timeline.zoomLevel.toStringAsFixed(1)}x',
            style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 17),
            color: Colors.white54,
            tooltip: 'Zoom In',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: () => timeline.zoomIn(),
          ),

          // 6. Premiere-Pro "+ Track" Button
          Container(
            height: 28,
            margin: const EdgeInsets.only(left: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF252D42),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_rounded, size: 15, color: Color(0xFF38BDF8)),
              label: const Text('+ Track', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              onPressed: () => _showAddTrackMenu(context, projectProvider),
            ),
          ),
        ],
      ),
    );
  }
}
