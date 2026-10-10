import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../services/export_service.dart';
import '../../theme/app_colors.dart';

class ExportDialog extends StatefulWidget {
  final ProjectModel project;

  const ExportDialog({
    super.key,
    required this.project,
  });

  static Future<void> show(BuildContext context, ProjectModel project) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExportDialog(project: project),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final ExportService _exportService = ExportService();
  StreamSubscription<ExportProgress>? _sub;

  ResolutionPreset _resolution = ResolutionPreset.res1080p;
  int _fps = 30;
  final double _bitrateMbps = 12.0;

  bool _isExporting = false;
  bool _isDone = false;
  double _progress = 0.0;
  String _statusText = 'Ready to export';
  String? _exportedFilePath;
  int _finalSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _resolution = widget.project.resolution;
    _fps = widget.project.fps;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _exportService.cancel();
    super.dispose();
  }

  void _startExport() {
    setState(() {
      _isExporting = true;
      _isDone = false;
      _progress = 0.0;
      _statusText = 'Starting export...';
    });

    final settings = ExportSettings(
      resolution: _resolution,
      fps: _fps,
      bitrateMbps: _bitrateMbps,
    );

    _sub = _exportService.exportProject(widget.project, settings).listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _progress = progress.progress;
          _statusText = progress.stage;
          if (progress.isCompleted) {
            _isExporting = false;
            _isDone = true;
            _exportedFilePath = progress.outputPath;
            _finalSizeBytes = progress.outputSizeBytes;
          } else if (progress.isCancelled) {
            _isExporting = false;
            _statusText = 'Export was cancelled.';
          }
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isExporting = false;
          _statusText = 'Export failed: $err';
        });
      },
    );
  }

  void _cancelExport() {
    _exportService.cancel();
    _sub?.cancel();
    setState(() {
      _isExporting = false;
      _statusText = 'Export cancelled';
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ExportSettings(
      resolution: _resolution,
      fps: _fps,
      bitrateMbps: _bitrateMbps,
    );
    final estimatedSizeStr = settings.formatEstimatedSize(widget.project.totalDuration);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161924),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isDone
                    ? 'Export Complete! 🎉'
                    : (_isExporting ? 'Exporting Video...' : 'Export Settings'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isDone) ...[
            // Completed state
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 54,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.project.title}.mp4',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_resolution.label} • $_fps fps • ${(_finalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text(
                      'Share Video',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      if (_exportedFilePath != null) {
                        ExportService.shareVideo(
                          _exportedFilePath!,
                          widget.project.title,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ] else if (_isExporting) ...[
            // In progress state
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _cancelExport,
                child: const Text(
                  'Cancel Export',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ] else ...[
            // Settings selection state
            const Text(
              'Resolution',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ResolutionPreset.values.map((res) {
                final isSelected = _resolution == res;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(res.label),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFF22283A),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _resolution = res);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text(
              'Frame Rate (FPS)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [24, 30, 60].map((fps) {
                final isSelected = _fps == fps;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$fps fps'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFF22283A),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _fps = fps);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Summary info card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF22283A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Size',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        estimatedSizeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Timeline Length',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        widget.project.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                onPressed: _startExport,
                child: const Text(
                  'Export Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
