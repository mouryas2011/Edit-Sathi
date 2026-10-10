import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/project_provider.dart';
import '../../../../providers/timeline_provider.dart';
import '../../../../theme/app_colors.dart';
import 'sheets/text_edit_sheet.dart';
import 'sheets/audio_picker_sheet.dart';
import 'sheets/filter_picker_sheet.dart';
import 'sheets/aspect_ratio_sheet.dart';
import 'sheets/speed_sheet.dart';

class EditorBottomToolbar extends StatelessWidget {
  const EditorBottomToolbar({super.key});

  void _handleTrimAction(
    BuildContext context,
    ProjectProvider projectProvider,
    TimelineProvider timelineProvider,
  ) {
    final project = projectProvider.activeProject;
    if (project == null || project.videoClips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video clips to trim or split')),
      );
      return;
    }

    final playhead = timelineProvider.currentPosition;
    final activeClip = project.videoClips.cast<dynamic>().firstWhere(
      (c) => playhead >= c.startTime && playhead <= c.endTime,
      orElse: () => project.videoClips.first,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF161924),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trim & Edit: ${activeClip.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ToolActionButton(
                  icon: Icons.content_cut_rounded,
                  label: 'Split Here',
                  onTap: () {
                    final success = projectProvider.splitClipAtPosition(
                      activeClip.id,
                      playhead,
                    );
                    Navigator.of(ctx).pop();
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Move playhead inside the clip to split',
                          ),
                        ),
                      );
                    }
                  },
                ),
                _ToolActionButton(
                  icon: Icons.speed_rounded,
                  label: 'Speed',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    SpeedSheet.show(
                      context: context,
                      currentSpeed: activeClip.speed,
                      onSpeedSelected: (speed) {
                        projectProvider.updateVideoClip(
                          activeClip.copyWith(speed: speed),
                        );
                      },
                    );
                  },
                ),
                _ToolActionButton(
                  icon: activeClip.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  label: activeClip.isMuted ? 'Unmute' : 'Mute Clip',
                  onTap: () {
                    projectProvider.updateVideoClip(
                      activeClip.copyWith(isMuted: !activeClip.isMuted),
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
                _ToolActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Clip',
                  color: Colors.redAccent,
                  onTap: () {
                    projectProvider.removeVideoClip(activeClip.id);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
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

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.editorBg,
        border: Border(
          top: BorderSide(color: AppColors.editorBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Trim
          _ToolbarItem(
            icon: Icons.content_cut_rounded,
            label: 'Trim',
            onTap: () => _handleTrimAction(
              context,
              projectProvider,
              timelineProvider,
            ),
          ),

          // 2. Text
          _ToolbarItem(
            icon: Icons.title_rounded,
            label: 'Text',
            onTap: () {
              TextEditSheet.show(
                context: context,
                currentPosition: timelineProvider.currentPosition,
                onSave: projectProvider.addTextOverlay,
              );
            },
          ),

          // 3. Audio
          _ToolbarItem(
            icon: Icons.music_note_rounded,
            label: 'Audio',
            onTap: () {
              AudioPickerSheet.show(
                context: context,
                currentPosition: timelineProvider.currentPosition,
                onAudioSelected: projectProvider.addAudioTrack,
              );
            },
          ),

          // 4. Effects
          _ToolbarItem(
            icon: Icons.star_border_rounded,
            label: 'Effects',
            onTap: () {
              if (project != null) {
                FilterPickerSheet.show(
                  context: context,
                  currentFilter: project.globalFilter,
                  onFilterSelected: projectProvider.updateGlobalFilter,
                );
              }
            },
          ),

          // 5. Captions
          _ToolbarItem(
            icon: Icons.closed_caption_outlined,
            label: 'Captions',
            onTap: () {
              projectProvider.applyAutoCaptions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ AI Captions generated from speech track!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          // 6. More
          _ToolbarItem(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            onTap: () {
              if (project != null) {
                AspectRatioSheet.show(
                  context: context,
                  currentRatio: project.aspectRatio,
                  onRatioSelected: projectProvider.updateAspectRatio,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ToolbarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ToolActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
