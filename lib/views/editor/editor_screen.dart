import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/timeline_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/editor_top_bar.dart';
import 'widgets/video_preview_canvas.dart';
import 'widgets/multi_track_timeline.dart';
import 'widgets/editor_bottom_toolbar.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final project = context.read<ProjectProvider>().activeProject;
      if (project != null) {
        context.read<TimelineProvider>().setTotalDuration(project.totalDuration);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectProvider>().activeProject;
    final timeline = context.watch<TimelineProvider>();

    if (project != null && timeline.totalDuration != project.totalDuration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<TimelineProvider>().setTotalDuration(project.totalDuration);
        }
      });
    }

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.editorBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No active project found',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.editorBg,
      ),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          context.read<TimelineProvider>().pause();
        },
        child: Scaffold(
          backgroundColor: AppColors.editorBg,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Top Bar
                EditorTopBar(
                  onBack: () {
                    context.read<TimelineProvider>().pause();
                    Navigator.of(context).pop();
                  },
                ),

                // 2. Video Preview Canvas (Real-time playback & overlay rendering)
                const Expanded(
                  flex: 5,
                  child: VideoPreviewCanvas(),
                ),

                // 3. Multi-Track Timeline (Video strip, text pill, audio waveform)
                const Expanded(
                  flex: 4,
                  child: MultiTrackTimeline(),
                ),

                // 4. Bottom Action Toolbar (Trim, Text, Audio, Effects, Captions, More)
                const EditorBottomToolbar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
