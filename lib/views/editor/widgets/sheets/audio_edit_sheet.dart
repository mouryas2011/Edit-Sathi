import 'package:flutter/material.dart';
import '../../../../models/audio_track.dart';

class AudioEditSheet extends StatefulWidget {
  final AudioTrackModel track;
  final Function(AudioTrackModel) onSave;

  const AudioEditSheet({
    super.key,
    required this.track,
    required this.onSave,
  });

  static void show({
    required BuildContext context,
    required AudioTrackModel track,
    required Function(AudioTrackModel) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AudioEditSheet(
        track: track,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AudioEditSheet> createState() => _AudioEditSheetState();
}

class _AudioEditSheetState extends State<AudioEditSheet> {
  late double _volume;
  late double _fadeInSeconds;
  late double _fadeOutSeconds;
  late VoiceEffectPreset _voiceEffect;

  @override
  void initState() {
    super.initState();
    _volume = widget.track.volume;
    _fadeInSeconds = (widget.track.fadeInDuration.inMilliseconds / 1000.0).clamp(0.0, 5.0);
    _fadeOutSeconds = (widget.track.fadeOutDuration.inMilliseconds / 1000.0).clamp(0.0, 5.0);
    _voiceEffect = widget.track.voiceEffect;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.equalizer_rounded, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Audio Studio: ${widget.track.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Volume Slider (0% - 200%)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Volume Boost',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(_volume * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF10B981),
                      thumbColor: const Color(0xFF10B981),
                      inactiveTrackColor: Colors.white12,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _volume.clamp(0.0, 2.0),
                      min: 0.0,
                      max: 2.0,
                      divisions: 40,
                      onChanged: (val) {
                        setState(() {
                          _volume = val;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Fade In & Fade Out
                  Row(
                    children: [
                      // Fade In
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Fade In',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  '${_fadeInSeconds.toStringAsFixed(1)}s',
                                  style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF34D399),
                                thumbColor: const Color(0xFF34D399),
                                inactiveTrackColor: Colors.white12,
                                trackHeight: 2,
                              ),
                              child: Slider(
                                value: _fadeInSeconds,
                                min: 0.0,
                                max: 5.0,
                                divisions: 50,
                                onChanged: (val) {
                                  setState(() {
                                    _fadeInSeconds = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Fade Out
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Fade Out',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  '${_fadeOutSeconds.toStringAsFixed(1)}s',
                                  style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF34D399),
                                thumbColor: const Color(0xFF34D399),
                                inactiveTrackColor: Colors.white12,
                                trackHeight: 2,
                              ),
                              child: Slider(
                                value: _fadeOutSeconds,
                                min: 0.0,
                                max: 5.0,
                                divisions: 50,
                                onChanged: (val) {
                                  setState(() {
                                    _fadeOutSeconds = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Voice Effects (CapCut / VN style)
                  const Text(
                    'Voice Effects & Audio FX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: VoiceEffectPreset.values.length,
                    itemBuilder: (context, index) {
                      final fx = VoiceEffectPreset.values[index];
                      final isSelected = _voiceEffect == fx;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _voiceEffect = fx;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF10B981).withValues(alpha: 0.22)
                                : const Color(0xFF1E2433),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF10B981) : Colors.white10,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                fx.icon,
                                size: 22,
                                color: isSelected ? const Color(0xFF10B981) : Colors.white70,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fx.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final updated = widget.track.copyWith(
                  volume: _volume,
                  fadeInDuration: Duration(milliseconds: (_fadeInSeconds * 1000).round()),
                  fadeOutDuration: Duration(milliseconds: (_fadeOutSeconds * 1000).round()),
                  voiceEffect: _voiceEffect,
                );
                widget.onSave(updated);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Save Audio Settings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
