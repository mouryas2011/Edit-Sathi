import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';

class ThumbnailService {
  static const MethodChannel _channel = MethodChannel('com.editsathi.edit_sathi/thumbnail');
  static final Map<String, String> _cache = {};

  /// Extract video frame thumbnail from local video file
  static Future<String?> generateVideoThumbnail(
    String videoPath, {
    int timeMs = 500,
    int quality = 85,
  }) async {
    if (videoPath.isEmpty) return null;

    if (_cache.containsKey(videoPath)) {
      final cachedPath = _cache[videoPath]!;
      if (File(cachedPath).existsSync()) {
        return cachedPath;
      }
    }

    try {
      final String? thumbPath = await _channel.invokeMethod<String>(
        'getVideoThumbnail',
        {
          'videoPath': videoPath,
          'timeMs': timeMs,
          'quality': quality,
        },
      );

      if (thumbPath != null && thumbPath.isNotEmpty) {
        _cache[videoPath] = thumbPath;
        return thumbPath;
      }
    } catch (e) {
      debugPrint('ThumbnailService: Error extracting frame from $videoPath: $e');
    }
    return null;
  }

  /// Builds a live thumbnail image widget for a project
  static Widget buildThumbnailWidget(
    ProjectModel project, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final clip = project.videoClips.isNotEmpty ? project.videoClips.first : null;
    final directThumb = project.customThumbnail ?? clip?.customThumbnail;

    // 1. Direct thumbnail already stored
    if (directThumb != null && directThumb.isNotEmpty) {
      final file = File(directThumb);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(project, width, height),
          ),
        );
      }
    }

    // 2. Extract on-the-fly from first video clip
    if (clip != null && clip.sourcePath.isNotEmpty && !clip.sourcePath.startsWith('assets/')) {
      final file = File(clip.sourcePath);
      if (file.existsSync()) {
        return FutureBuilder<String?>(
          future: generateVideoThumbnail(clip.sourcePath),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final thumbFile = File(snapshot.data!);
              if (thumbFile.existsSync()) {
                return ClipRRect(
                  borderRadius: borderRadius ?? BorderRadius.circular(16),
                  child: Image.file(
                    thumbFile,
                    width: width,
                    height: height,
                    fit: fit,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(project, width, height),
                  ),
                );
              }
            }
            return _buildFallbackThumbnail(project, width, height);
          },
        );
      }
    }

    return _buildFallbackThumbnail(project, width, height);
  }

  static Widget _buildFallbackThumbnail(ProjectModel project, double? width, double? height) {
    LinearGradient gradient;
    IconData iconData;

    final title = project.title.toLowerCase();
    if (title.contains('cafe') || title.contains('coffee')) {
      gradient = const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFF78350F), Color(0xFF451A03)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      iconData = Icons.coffee_rounded;
    } else if (title.contains('travel') || title.contains('trip') || title.contains('vlog')) {
      gradient = const LinearGradient(
        colors: [Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF0F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      iconData = Icons.landscape_rounded;
    } else if (title.contains('reel') || title.contains('tiktok') || title.contains('short')) {
      gradient = const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF312E81)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      iconData = Icons.music_video_rounded;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF06B6D4), Color(0xFF0F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      iconData = Icons.movie_filter_rounded;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Filmstrip perforations simulation
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (i) => Container(
                  width: 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (i) => Container(
                  width: 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: Colors.white.withValues(alpha: 0.8),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
