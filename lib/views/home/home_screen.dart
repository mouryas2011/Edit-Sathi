import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/project_provider.dart';
import '../../models/project.dart';
import '../../models/video_clip.dart';
import '../../models/text_overlay.dart';
import '../../models/audio_track.dart';
import '../../services/template_service.dart';
import '../../services/media_picker_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/project_card.dart';
import '../widgets/template_card.dart';
import '../widgets/quick_action_button.dart';
import '../editor/editor_screen.dart';
import '../export/export_dialog.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToTemplates;
  final VoidCallback onNavigateToProjects;

  const HomeScreen({
    super.key,
    required this.onNavigateToTemplates,
    required this.onNavigateToProjects,
  });

  Future<void> _showLoadingDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 16),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importVideoFromPicker(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
    bool forceFilePicker = false,
  }) async {
    final projectProvider = context.read<ProjectProvider>();

    // 1. Request permission
    await MediaPickerService.requestMediaPermissions();

    if (!context.mounted) return;

    // Show loading
    _showLoadingDialog(context, 'Importing video & analyzing...');

    PickedVideoInfo? pickedInfo;
    try {
      if (forceFilePicker) {
        pickedInfo = await MediaPickerService.pickVideoFromFileStorage();
      } else {
        pickedInfo = await MediaPickerService.pickVideo(source: source);
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }

    if (!context.mounted) return;
    // Dismiss loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    if (pickedInfo == null) {
      // User cancelled or no video selected
      return;
    }

    // Create valid project with real video clip
    final cleanTitle = pickedInfo.name.contains('.')
        ? pickedInfo.name.split('.').first
        : pickedInfo.name;

    final initialClip = VideoClipModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourcePath: pickedInfo.path,
      title: cleanTitle,
      startTime: Duration.zero,
      duration: pickedInfo.duration,
      sourceDuration: pickedInfo.duration,
    );

    projectProvider.createNewProject(
      title: cleanTitle.isNotEmpty ? cleanTitle : 'My Video Edit',
      ratio: pickedInfo.aspectRatioPreset,
      resolution: pickedInfo.resolutionPreset,
      initialClips: [initialClip],
    );

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      );
    }
  }

  void _createSampleProject(BuildContext context) {
    final projectProvider = context.read<ProjectProvider>();
    projectProvider.createNewProject(
      title: 'Cinematic Reel',
      ratio: AspectRatioPreset.vertical9x16,
      resolution: ResolutionPreset.res1080p,
      initialClips: [
        const VideoClipModel(
          id: 'sample-clip-1',
          sourcePath: 'assets/sample_cafe_intro.mp4',
          title: 'Morning Lights',
          startTime: Duration.zero,
          duration: Duration(seconds: 10),
          sourceDuration: Duration(seconds: 14),
          filter: VideoFilterPreset.warmSunset,
        ),
        const VideoClipModel(
          id: 'sample-clip-2',
          sourcePath: 'assets/sample_coffee_pour.mp4',
          title: 'Aesthetic Pour',
          startTime: Duration.zero,
          duration: Duration(seconds: 9),
          sourceDuration: Duration(seconds: 12),
          filter: VideoFilterPreset.cinematic,
        ),
      ],
    );

    projectProvider.addTextOverlay(
      const TextOverlayModel(
        id: 'sample-text-1',
        text: 'Morning Vibes ☕',
        startTime: Duration(seconds: 1),
        duration: Duration(seconds: 5),
        positionX: 0.0,
        positionY: 0.55,
      ),
    );

    projectProvider.addAudioTrack(
      const AudioTrackModel(
        id: 'sample-audio-1',
        sourcePath: 'assets/audio/lofi_chill.mp3',
        title: 'Lofi Chill Beat',
        type: AudioTrackType.music,
        startTime: Duration.zero,
        duration: Duration(seconds: 19),
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  void _createBlankProject(BuildContext context) {
    final projectProvider = context.read<ProjectProvider>();
    projectProvider.createNewProject(
      title: 'New Blank Edit',
      ratio: AspectRatioPreset.vertical9x16,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  void _showNewProjectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF161924),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Create New Project',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select media from device or start with a sample',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Option 1: Gallery / Videos
            _ImportOptionTile(
              icon: Icons.photo_library_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Import from Gallery',
              subtitle: 'Select videos from your phone gallery or photos',
              onTap: () {
                Navigator.of(ctx).pop();
                _importVideoFromPicker(context, source: ImageSource.gallery);
              },
            ),

            // Option 2: Files / Storage
            _ImportOptionTile(
              icon: Icons.folder_open_rounded,
              iconColor: const Color(0xFF06B6D4),
              title: 'Choose Video File',
              subtitle: 'Browse downloads, SD card, or local device files',
              onTap: () {
                Navigator.of(ctx).pop();
                _importVideoFromPicker(context, forceFilePicker: true);
              },
            ),

            // Option 3: Camera
            _ImportOptionTile(
              icon: Icons.videocam_rounded,
              iconColor: const Color(0xFFF43F5E),
              title: 'Record with Camera',
              subtitle: 'Capture a fresh video clip right now',
              onTap: () {
                Navigator.of(ctx).pop();
                _importVideoFromPicker(context, source: ImageSource.camera);
              },
            ),

            // Option 4: Sample Demo Video
            _ImportOptionTile(
              icon: Icons.movie_filter_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Try Sample Demo Project',
              subtitle: 'Test all editor features instantly with ready media',
              onTap: () {
                Navigator.of(ctx).pop();
                _createSampleProject(context);
              },
            ),

            // Option 5: Blank Project
            _ImportOptionTile(
              icon: Icons.aspect_ratio_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Blank Canvas Project',
              subtitle: 'Start with an empty timeline and add media anytime',
              onTap: () {
                Navigator.of(ctx).pop();
                _createBlankProject(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNewProject(BuildContext context) async {
    _showNewProjectSheet(context);
  }

  void _showAiToolsSheet(BuildContext context) {
    final projectProvider = context.read<ProjectProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: const Color(0xFF161924),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'On-Device AI Magic Tools ✨',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '100% private, on-device processing. No video uploaded.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.aiToolsBg,
                child: Icon(Icons.auto_awesome, color: AppColors.aiToolsIcon),
              ),
              title: const Text(
                'Auto Smart Cut',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Detects silent pauses & trims dead air automatically',
                style: TextStyle(color: Colors.white60),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                if (projectProvider.projects.isNotEmpty) {
                  projectProvider.openProject(projectProvider.projects.first);
                  projectProvider.applyAutoCut();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditorScreen()),
                  );
                } else {
                  _createSampleProject(context);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.autoEditBg,
                child: Icon(Icons.closed_caption, color: AppColors.autoEditIcon),
              ),
              title: const Text(
                'Auto Captions Generator',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Transcribes speech track into animated subtitle pills',
                style: TextStyle(color: Colors.white60),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                if (projectProvider.projects.isNotEmpty) {
                  projectProvider.openProject(projectProvider.projects.first);
                  projectProvider.applyAutoCaptions();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditorScreen()),
                  );
                } else {
                  _createSampleProject(context);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.templatesBg,
                child: Icon(Icons.graphic_eq, color: AppColors.templatesIcon),
              ),
              title: const Text(
                'Beat Sync Reel Maker',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Syncs video cuts with musical rhythm and beat drops',
                style: TextStyle(color: Colors.white60),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                if (projectProvider.projects.isNotEmpty) {
                  projectProvider.openProject(projectProvider.projects.first);
                  projectProvider.applyBeatSync();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditorScreen()),
                  );
                } else {
                  _createSampleProject(context);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final projects = projectProvider.projects;
    final templates = TemplateService.getTemplates();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header (Title + Subtitle + Notification + Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.primaryGradient.createShader(bounds),
                            child: const Text(
                              'Edit Sathi',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Create something amazing',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Bell Icon with red unread dot
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 26,
                              color: Color(0xFF1E293B),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No new notifications right now.'),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 10,
                            right: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // Profile Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryLight,
                            width: 2,
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF472B6), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero Banner: "+ New Project >"
              GestureDetector(
                onTap: () => _handleNewProject(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroCardGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'New Project',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Action 4 Cards: Auto Edit, AI Tools, Templates, More
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionButton(
                    label: 'Auto Edit',
                    icon: Icons.content_cut_rounded,
                    backgroundColor: AppColors.autoEditBg,
                    iconColor: AppColors.autoEditIcon,
                    onTap: () {
                      if (projects.isNotEmpty) {
                        projectProvider.openProject(projects.first);
                        projectProvider.applyAutoCut();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditorScreen(),
                          ),
                        );
                      } else {
                        _showNewProjectSheet(context);
                      }
                    },
                  ),
                  QuickActionButton(
                    label: 'AI Tools',
                    icon: Icons.auto_awesome_rounded,
                    backgroundColor: AppColors.aiToolsBg,
                    iconColor: AppColors.aiToolsIcon,
                    onTap: () => _showAiToolsSheet(context),
                  ),
                  QuickActionButton(
                    label: 'Templates',
                    icon: Icons.photo_library_outlined,
                    backgroundColor: AppColors.templatesBg,
                    iconColor: AppColors.templatesIcon,
                    onTap: onNavigateToTemplates,
                  ),
                  QuickActionButton(
                    label: 'More',
                    icon: Icons.grid_view_rounded,
                    backgroundColor: AppColors.moreBg,
                    iconColor: AppColors.moreIcon,
                    onTap: onNavigateToProjects,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Recent Projects Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Projects',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: onNavigateToProjects,
                    child: const Row(
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Recent Projects Horizontal Scroll List
              if (projects.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No projects yet. Tap "+ New Project" to begin!'),
                  ),
                )
              else
                SizedBox(
                  height: 185,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ProjectCard(
                        project: project,
                        onTap: () {
                          projectProvider.openProject(project);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditorScreen(),
                            ),
                          );
                        },
                        onRename: () {
                          final ctrl = TextEditingController(text: project.title);
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Rename Project'),
                              content: TextField(controller: ctrl),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    projectProvider.openProject(project);
                                    projectProvider.updateTitle(ctrl.text);
                                    Navigator.of(ctx).pop();
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDuplicate: () {
                          projectProvider.duplicateProject(project.id);
                        },
                        onExport: () {
                          ExportDialog.show(context, project);
                        },
                        onDelete: () {
                          projectProvider.deleteProject(project.id);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // Templates for You Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Templates for You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: onNavigateToTemplates,
                    child: const Row(
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Templates Horizontal Scroll List
              SizedBox(
                height: 154,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return TemplateCard(
                      template: template,
                      onTap: () {
                        projectProvider.createFromTemplate(template);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditorScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

