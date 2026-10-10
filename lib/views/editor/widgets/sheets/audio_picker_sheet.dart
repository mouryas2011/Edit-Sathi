import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../models/audio_track.dart';
import '../../../../theme/app_colors.dart';

class AudioPickerSheet extends StatelessWidget {
  final Duration currentPosition;
  final Function(AudioTrackModel) onAudioSelected;

  const AudioPickerSheet({
    super.key,
    required this.currentPosition,
    required this.onAudioSelected,
  });

  static void show({
    required BuildContext context,
    required Duration currentPosition,
    required Function(AudioTrackModel) onAudioSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AudioPickerSheet(
        currentPosition: currentPosition,
        onAudioSelected: onAudioSelected,
      ),
    );
  }

  Future<void> _pickDeviceAudio(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.audio,
      );

      if (files.isNotEmpty && files.first.path != null) {
        final file = files.first;
        final track = AudioTrackModel(
          id: const Uuid().v4(),
          title: file.name,
          sourcePath: file.path!,
          type: AudioTrackType.music,
          startTime: currentPosition,
          duration: const Duration(seconds: 30),
          volume: 0.9,
          waveformData: List.generate(32, (i) => 0.2 + (i % 5 * 0.15)),
        );
        onAudioSelected(track);
        if (context.mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryTracks = [
      (
        'Cafe Moments.mp3',
        'Lofi & Ambient Cafe',
        '02:14',
        const Duration(seconds: 28),
      ),
      (
        'Summer Beats.mp3',
        'Upbeat Tropical House',
        '01:45',
        const Duration(seconds: 32),
      ),
      (
        'Wanderlust Ambient.mp3',
        'Cinematic Mountain Drone',
        '03:10',
        const Duration(seconds: 45),
      ),
      (
        'Acoustic Kitchen.mp3',
        'Gentle Folk Guitar',
        '02:30',
        const Duration(seconds: 25),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF161924),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Music & Audio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.file_upload_outlined, size: 18),
                label: const Text('From Device'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
                onPressed: () => _pickDeviceAudio(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Royalty-Free Music Library',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Column(
            children: libraryTracks.map((item) {
              return InkWell(
                onTap: () {
                  final track = AudioTrackModel(
                    id: const Uuid().v4(),
                    title: item.$1,
                    sourcePath: 'assets/${item.$1}',
                    type: AudioTrackType.music,
                    startTime: currentPosition,
                    duration: item.$4,
                    volume: 0.85,
                    waveformData: List.generate(
                      32,
                      (i) => 0.2 + (0.7 * (i % 4 == 0 ? 0.8 : 0.4)),
                    ),
                  );
                  onAudioSelected(track);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22283A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.audioTrack.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: AppColors.audioTrack,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.$3,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
