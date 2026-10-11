import 'package:flutter/material.dart';
import '../../../../models/project.dart';
import '../../../../services/ai_service.dart';
import '../../../../theme/app_colors.dart';

class AiCaptionsSheet extends StatefulWidget {
  final ProjectModel project;
  final Function(List<AiCaptionSegment> captions, CaptionStylePreset style) onApply;

  const AiCaptionsSheet({
    super.key,
    required this.project,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required ProjectModel project,
    required Function(List<AiCaptionSegment> captions, CaptionStylePreset style) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiCaptionsSheet(
        project: project,
        onApply: onApply,
      ),
    );
  }

  @override
  State<AiCaptionsSheet> createState() => _AiCaptionsSheetState();
}

class _AiCaptionsSheetState extends State<AiCaptionsSheet> {
  String _selectedLanguage = 'hi_en';
  CaptionStylePreset _selectedStyle = CaptionStylePreset.modernPill;
  List<AiCaptionSegment> _captions = [];
  bool _isGenerating = false;

  final Map<String, String> _languages = {
    'hi_en': 'Hinglish (Hindi + English)',
    'hi': 'Hindi (हिन्दी)',
    'en': 'English (Global)',
    'es': 'Spanish (Español)',
  };

  @override
  void initState() {
    super.initState();
    _loadCaptions();
  }

  Future<void> _loadCaptions() async {
    setState(() => _isGenerating = true);
    final results = await AiService.generateOfflineCaptions(
      project: widget.project,
      languageCode: _selectedLanguage,
    );
    if (mounted) {
      setState(() {
        _captions = results;
        _isGenerating = false;
      });
    }
  }

  void _exportSrt() {
    final srt = AiService.exportToSrt(_captions);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Export Subtitles (.SRT)', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: SelectableText(
            srt,
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.closed_caption_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'On-Device Auto Captions',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '100% Offline • Zero Cloud Upload',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined, color: Colors.white70),
                tooltip: 'Export SRT',
                onPressed: _exportSrt,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Language Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: _languages.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLanguage = val);
                    _loadCaptions();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Caption Style Selector
          const Text('Caption Style Preset:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StyleChip(
                  label: 'Slate Pill',
                  selected: _selectedStyle == CaptionStylePreset.modernPill,
                  onTap: () => setState(() => _selectedStyle = CaptionStylePreset.modernPill),
                ),
                _StyleChip(
                  label: 'Karaoke Highlight',
                  selected: _selectedStyle == CaptionStylePreset.karaokeHighlight,
                  onTap: () => setState(() => _selectedStyle = CaptionStylePreset.karaokeHighlight),
                ),
                _StyleChip(
                  label: 'Cinematic Outline',
                  selected: _selectedStyle == CaptionStylePreset.cinematicOutline,
                  onTap: () => setState(() => _selectedStyle = CaptionStylePreset.cinematicOutline),
                ),
                _StyleChip(
                  label: 'Minimal Clean',
                  selected: _selectedStyle == CaptionStylePreset.minimalSub,
                  onTap: () => setState(() => _selectedStyle = CaptionStylePreset.minimalSub),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Captions List
          Expanded(
            child: _isGenerating
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Analyzing speech track on-device...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _captions.length,
                    itemBuilder: (context, index) {
                      final item = _captions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.startTime.inSeconds}s',
                                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: item.text,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onChanged: (newVal) => item.text = newVal,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text('Apply Captions to Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onApply(_captions, _selectedStyle);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
