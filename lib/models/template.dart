import 'project.dart';
import 'video_clip.dart';

class VideoTemplateModel {
  final String id;
  final String title;
  final String tag;
  final String description;
  final AspectRatioPreset aspectRatio;
  final Duration estimatedDuration;
  final int placeholderClipsCount;
  final String suggestedMusicTitle;
  final String initialTitleText;
  final VideoFilterPreset filter;
  final String badgeText;

  const VideoTemplateModel({
    required this.id,
    required this.title,
    required this.tag,
    required this.description,
    required this.aspectRatio,
    required this.estimatedDuration,
    required this.placeholderClipsCount,
    required this.suggestedMusicTitle,
    required this.initialTitleText,
    this.filter = VideoFilterPreset.none,
    required this.badgeText,
  });
}
