import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/project_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../export/export_dialog.dart';

class EditorTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const EditorTopBar({
    super.key,
    required this.onBack,
  });

  void _showRenameDialog(BuildContext context, ProjectProvider provider) {
    final currentTitle = provider.activeProject?.title ?? 'Untitled';
    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161924),
        title: const Text('Rename Project', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Project Name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
            onPressed: () {
              provider.updateTitle(controller.text);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = context.watch<ProjectProvider>();
    final project = projectProvider.activeProject;
    if (project == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.editorBg,
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: onBack,
          ),

          // Title & Resolution pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showRenameDialog(context, projectProvider),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          project.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 14, color: Colors.white60),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${project.resolution.label} • ${project.fps}fps',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Undo button
          IconButton(
            icon: Icon(
              Icons.undo,
              color: projectProvider.canUndo ? Colors.white : Colors.white24,
              size: 20,
            ),
            onPressed: projectProvider.canUndo ? projectProvider.undo : null,
          ),

          // Redo button
          IconButton(
            icon: Icon(
              Icons.redo,
              color: projectProvider.canRedo ? Colors.white : Colors.white24,
              size: 20,
            ),
            onPressed: projectProvider.canRedo ? projectProvider.redo : null,
          ),

          const SizedBox(width: 4),

          // Purple Export Pill Button (Matching mockup)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.file_upload_outlined, size: 16),
            label: const Text(
              'Export',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              ExportDialog.show(context, project);
            },
          ),
        ],
      ),
    );
  }
}
