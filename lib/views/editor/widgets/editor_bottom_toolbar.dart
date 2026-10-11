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
import 'sheets/ai_captions_sheet.dart';
import 'sheets/ai_tools_sheet.dart';
import 'sheets/transform_sheet.dart';
import 'sheets/shape_picker_sheet.dart';
import 'sheets/adjustment_layer_sheet.dart';
import 'sheets/transition_sheet.dart';
import 'sheets/canvas_background_sheet.dart';
import '../../../../services/ai_service.dart';

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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                  const SizedBox(width: 12),
                  _ToolActionButton(
                    icon: Icons.transform_rounded,
                    label: 'Transform',
                    color: const Color(0xFF06B6D4),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      TransformSheet.show(
                        context: context,
                        clip: activeClip,
                        onSave: projectProvider.updateVideoClip,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _ToolActionButton(
                    icon: Icons.speed_rounded,
                    label: 'Speed',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      SpeedSheet.show(
                        context: context,
                        currentSpeed: activeClip.speed,
                        currentCurve: activeClip.speedCurve,
                        onSpeedSelected: (speed, curve) {
                          projectProvider.updateVideoClip(
                            activeClip.copyWith(speed: speed, speedCurve: curve),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _ToolActionButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Transition',
                    color: const Color(0xFFF43F5E),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      TransitionSheet.show(
                        context: context,
                        currentTransition: activeClip.transition,
                        currentDuration: activeClip.transitionDuration,
                        onApply: (trans, dur, applyToAll) {
                          if (applyToAll) {
                            projectProvider.applyTransitionToAllClips(trans, duration: dur);
                          } else {
                            projectProvider.updateClipTransition(activeClip.id, trans, duration: dur);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
                  _ToolActionButton(
                    icon: Icons.delete_sweep_rounded,
                    label: 'Ripple Del',
                    color: Colors.amberAccent,
                    onTap: () {
                      projectProvider.rippleDeleteClip(activeClip.id);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  const SizedBox(width: 12),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // 1. Transform (Zoom, Scale, Rotate, Position)
            _ToolbarItem(
              icon: Icons.transform_rounded,
              label: 'Transform',
              onTap: () {
                if (project == null || project.videoClips.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No video clips to transform')),
                  );
                  return;
                }
                final playhead = timelineProvider.currentPosition;
                final activeClip = project.videoClips.cast<dynamic>().firstWhere(
                  (c) => playhead >= c.startTime && playhead <= c.endTime,
                  orElse: () => project.videoClips.first,
                );
                TransformSheet.show(
                  context: context,
                  clip: activeClip,
                  onSave: projectProvider.updateVideoClip,
                );
              },
            ),

            // 2. Trim & Split
            _ToolbarItem(
              icon: Icons.content_cut_rounded,
              label: 'Trim',
              onTap: () => _handleTrimAction(
                context,
                projectProvider,
                timelineProvider,
              ),
            ),

            // 3. Shapes
            _ToolbarItem(
              icon: Icons.interests_rounded,
              label: 'Shapes',
              onTap: () {
                ShapePickerSheet.show(
                  context: context,
                  currentPosition: timelineProvider.currentPosition,
                  onShapeSelected: (shape) {
                    projectProvider.addShape(shape);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔷 Shape added to timeline! Drag on screen to reposition.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),

            // 4. Adjustment Layer (Premiere Pro style)
            _ToolbarItem(
              icon: Icons.tune_rounded,
              label: 'Adj Layer',
              onTap: () {
                if (project != null) {
                  AdjustmentLayerSheet.show(
                    context: context,
                    currentPosition: timelineProvider.currentPosition,
                    totalProjectDuration: project.totalDuration,
                    onSave: (layer) {
                      projectProvider.addAdjustmentLayer(layer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎚️ Adjustment Layer added! Applies effects across clips.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                }
              },
            ),

            // 5. Text Overlay
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

            // 6. Audio
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

            // 7. Filter Effects
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

            // 8. Auto Captions
            _ToolbarItem(
              icon: Icons.closed_caption_rounded,
              label: 'Captions',
              onTap: () {
                if (project != null) {
                  AiCaptionsSheet.show(
                    context: context,
                    project: project,
                    onApply: (captions, style) {
                      projectProvider.applyCustomCaptions(captions, style);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✨ Subtitles applied to timeline!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                }
              },
            ),

            // 9. AI Tools Suite
            _ToolbarItem(
              icon: Icons.auto_awesome_rounded,
              label: 'AI Tools',
              onTap: () {
                if (project != null) {
                  AiToolsSheet.show(
                    context: context,
                    project: project,
                    onSilenceCutApplied: () {
                      final silences = AiService.detectSilenceIntervals(project);
                      projectProvider.applySilenceCuts(silences);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✂️ Dead air removed from clips!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    onAudioNormalized: () {
                      projectProvider.applyAudioNormalization();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔊 Master audio normalized (-16 LUFS)!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    onHighlightSelected: (start, dur) {
                      timelineProvider.seekTo(start);
                    },
                  );
                }
              },
            ),

            // 10. Aspect Ratio / Canvas
            _ToolbarItem(
              icon: Icons.aspect_ratio_rounded,
              label: 'Ratio',
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

            // 11. Transitions (Premiere Pro / CapCut)
            _ToolbarItem(
              icon: Icons.auto_awesome_rounded,
              label: 'Transition',
              onTap: () {
                if (project == null || project.videoClips.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add video clips first to apply transitions')),
                  );
                  return;
                }
                final playhead = timelineProvider.currentPosition;
                final activeClip = project.videoClips.cast<dynamic>().firstWhere(
                  (c) => playhead >= c.startTime && playhead <= c.endTime,
                  orElse: () => project.videoClips.first,
                );
                TransitionSheet.show(
                  context: context,
                  currentTransition: activeClip.transition,
                  currentDuration: activeClip.transitionDuration,
                  onApply: (trans, dur, applyToAll) {
                    if (applyToAll) {
                      projectProvider.applyTransitionToAllClips(trans, duration: dur);
                    } else {
                      projectProvider.updateClipTransition(activeClip.id, trans, duration: dur);
                    }
                  },
                );
              },
            ),

            // 12. Canvas Background (CapCut / VN style blur, color, gradient)
            _ToolbarItem(
              icon: Icons.palette_rounded,
              label: 'Canvas BG',
              onTap: () {
                if (project != null) {
                  CanvasBackgroundSheet.show(
                    context: context,
                    project: project,
                    onSave: projectProvider.updateCanvasBackground,
                  );
                }
              },
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
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
