import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/project_provider.dart';
import '../../models/video_clip.dart';
import '../../services/template_service.dart';
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

  Future<void> _handleNewProject(BuildContext context) async {
    final projectProvider = context.read<ProjectProvider>();
    final picker = ImagePicker();

    try {
      final video = await picker.pickVideo(source: ImageSource.gallery);
      final newProj = projectProvider.createNewProject(
        title: video != null && video.name.isNotEmpty
            ? video.name.split('.').first
            : 'New Project',
      );
      if (video != null) {
        newProj.videoClips.add(
          VideoClipModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sourcePath: video.path,
            title: video.name,
            startTime: Duration.zero,
            duration: const Duration(seconds: 10),
            sourceDuration: const Duration(seconds: 15),
          ),
        );
        projectProvider.openProject(newProj);
      }
    } catch (_) {
      projectProvider.createNewProject(title: 'New Edit');
    }

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      );
    }
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
