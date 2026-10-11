import 'package:flutter/material.dart';
import '../../../../models/project.dart';
import '../../../../services/ai_service.dart';
import '../../../../theme/app_colors.dart';

class AiToolsSheet extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onSilenceCutApplied;
  final VoidCallback onAudioNormalized;
  final Function(Duration startTime, Duration duration)? onHighlightSelected;

  const AiToolsSheet({
    super.key,
    required this.project,
    required this.onSilenceCutApplied,
    required this.onAudioNormalized,
    this.onHighlightSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required ProjectModel project,
    required VoidCallback onSilenceCutApplied,
    required VoidCallback onAudioNormalized,
    Function(Duration startTime, Duration duration)? onHighlightSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiToolsSheet(
        project: project,
        onSilenceCutApplied: onSilenceCutApplied,
        onAudioNormalized: onAudioNormalized,
        onHighlightSelected: onHighlightSelected,
      ),
    );
  }

  @override
  State<AiToolsSheet> createState() => _AiToolsSheetState();
}

class _AiToolsSheetState extends State<AiToolsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<SilenceSection> _silences;
  late List<HighlightCandidate> _highlights;
  late List<ThumbnailCandidate> _thumbnails;
  late AudioDiagnosticReport _audioReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _silences = AiService.detectSilenceIntervals(widget.project);
    _highlights = AiService.detectHighlightCandidates(widget.project);
    _thumbnails = AiService.evaluateThumbnailCandidates(widget.project);
    _audioReport = AiService.diagnoseAudio(widget.project);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title & Privacy Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'On-Device AI Suite',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Zero Cloud Inference • Private & Offline',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 4),
                    Text('100% On-Device', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Silence Cut'),
              Tab(text: 'Highlights'),
              Tab(text: 'Thumbnails'),
              Tab(text: 'Audio Doctor'),
            ],
          ),
          const SizedBox(height: 14),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSilenceCutTab(),
                _buildHighlightsTab(),
                _buildThumbnailsTab(),
                _buildAudioDoctorTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: SILENCE CUT ---
  Widget _buildSilenceCutTab() {
    final selectedCount = _silences.where((s) => s.isSelectedForCut).length;
    final totalCutMs = _silences
        .where((s) => s.isSelectedForCut)
        .fold<int>(0, (acc, s) => acc + s.duration.inMilliseconds);
    final savedSeconds = (totalCutMs / 1000).toStringAsFixed(1);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_silences.length} Pauses Detected',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Save ~${savedSeconds}s of dead air',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: selectedCount == 0
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onSilenceCutApplied();
                      },
                child: const Text('Apply Jump-Cuts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _silences.isEmpty
              ? const Center(
                  child: Text('No long silences detected in this clip.', style: TextStyle(color: Colors.white54)),
                )
              : ListView.builder(
                  itemCount: _silences.length,
                  itemBuilder: (context, index) {
                    final item = _silences[index];
                    return CheckboxListTile(
                      dense: true,
                      activeColor: AppColors.primary,
                      title: Text(
                        'Silence at ${(item.startTime.inMilliseconds / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Duration: ${(item.duration.inMilliseconds / 1000).toStringAsFixed(1)}s pause',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      value: item.isSelectedForCut,
                      onChanged: (val) {
                        setState(() => item.isSelectedForCut = val ?? true);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 2: HIGHLIGHTS ---
  Widget _buildHighlightsTab() {
    return ListView.builder(
      itemCount: _highlights.length,
      itemBuilder: (context, index) {
        final item = _highlights[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Score ${(item.score * 100).toInt()}%',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time: ${(item.startTime.inSeconds)}s - ${(item.startTime.inSeconds + item.duration.inSeconds)}s (${item.duration.inSeconds}s)',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onHighlightSelected?.call(item.startTime, item.duration);
                    },
                    child: const Text('Jump Here', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: THUMBNAILS ---
  Widget _buildThumbnailsTab() {
    return ListView.builder(
      itemCount: _thumbnails.length,
      itemBuilder: (context, index) {
        final item = _thumbnails[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_outlined, color: Colors.white54, size: 24),
                      const SizedBox(height: 4),
                      Text('${item.timestamp.inSeconds}s', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.suggestedHeadline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Sharpness: ${item.sharpnessScore}% • Contrast: ${item.contrastScore}%',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final path = await AiService.exportThumbnailImage(
                          project: widget.project,
                          candidate: item,
                        );
                        if (context.mounted && path != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thumbnail exported successfully!')),
                          );
                        }
                      },
                      child: const Text('Export Frame', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 4: AUDIO DOCTOR ---
  Widget _buildAudioDoctorTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Audio Health Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_audioReport.hasClipping ? Colors.redAccent : const Color(0xFF10B981)).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _audioReport.healthStatus,
                      style: TextStyle(
                        color: _audioReport.hasClipping ? Colors.redAccent : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricPill(label: 'Peak Level', value: '${_audioReport.peakDbfs} dBFS'),
                  _MetricPill(label: 'Loudness', value: '${_audioReport.estimatedLufs} LUFS'),
                  _MetricPill(label: 'Silence', value: '${_audioReport.silencePercentage}%'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _audioReport.recommendation,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
            label: const Text('Auto-Normalize Master Audio (1-Tap)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAudioNormalized();
            },
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Non-destructive local DSP • Does not affect original recording',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
