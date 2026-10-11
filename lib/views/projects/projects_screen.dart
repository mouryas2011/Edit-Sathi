import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project.dart';
import '../../models/video_clip.dart';
import '../../services/media_picker_service.dart';
import '../../theme/app_colors.dart';
import '../editor/editor_screen.dart';
import '../export/export_dialog.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _searchQuery = '';
  AspectRatioPreset? _filterRatio;

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final allProjects = projectProvider.projects;

    final filtered = allProjects.where((p) {
      final matchesSearch =
          p.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _filterRatio == null || p.aspectRatio == _filterRatio;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text(
          'My Projects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search projects...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterRatio == null,
                  onSelected: (val) => setState(() => _filterRatio = null),
                ),
                const SizedBox(width: 8),
                ...AspectRatioPreset.values.map((ratio) {
                  final isSelected = _filterRatio == ratio;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(ratio.label),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _filterRatio = val ? ratio : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Projects List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No matching projects found',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final project = filtered[index];
                      return Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.movie_filter_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            project.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${project.formattedDuration} • ${project.aspectRatio.label} • ${project.resolution.label}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'export') {
                                ExportDialog.show(context, project);
                              } else if (val == 'duplicate') {
                                projectProvider.duplicateProject(project.id);
                              } else if (val == 'delete') {
                                projectProvider.deleteProject(project.id);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'export',
                                child: Text('Export Video'),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicate'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                          onTap: () {
                            projectProvider.openProject(project);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EditorScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        onPressed: () {
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
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF8B5CF6),
                      child: Icon(Icons.photo_library_rounded, color: Colors.white),
                    ),
                    title: const Text('Import from Gallery', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Pick video from phone gallery', style: TextStyle(color: Colors.white60)),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final picked = await MediaPickerService.pickVideo();
                      if (picked != null && context.mounted) {
                        final clean = picked.name.contains('.') ? picked.name.split('.').first : picked.name;
                        projectProvider.createNewProject(
                          title: clean.isNotEmpty ? clean : 'New Project',
                          ratio: picked.aspectRatioPreset,
                          resolution: picked.resolutionPreset,
                          initialClips: [
                            VideoClipModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              sourcePath: picked.path,
                              title: clean,
                              startTime: Duration.zero,
                              duration: picked.duration,
                              sourceDuration: picked.duration,
                            ),
                          ],
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditorScreen()),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF06B6D4),
                      child: Icon(Icons.folder_open_rounded, color: Colors.white),
                    ),
                    title: const Text('Choose Video File', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Browse device downloads or files', style: TextStyle(color: Colors.white60)),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final picked = await MediaPickerService.pickVideoFromFileStorage();
                      if (picked != null && context.mounted) {
                        final clean = picked.name.contains('.') ? picked.name.split('.').first : picked.name;
                        projectProvider.createNewProject(
                          title: clean.isNotEmpty ? clean : 'New Project',
                          ratio: picked.aspectRatioPreset,
                          resolution: picked.resolutionPreset,
                          initialClips: [
                            VideoClipModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              sourcePath: picked.path,
                              title: clean,
                              startTime: Duration.zero,
                              duration: picked.duration,
                              sourceDuration: picked.duration,
                            ),
                          ],
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EditorScreen()),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF10B981),
                      child: Icon(Icons.aspect_ratio_rounded, color: Colors.white),
                    ),
                    title: const Text('Blank Canvas Project', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Start with an empty timeline', style: TextStyle(color: Colors.white60)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      projectProvider.createNewProject(title: 'New Edit');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditorScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
