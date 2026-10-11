import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class PickedVideoInfo {
  final String path;
  final String name;
  final Duration duration;
  final AspectRatioPreset aspectRatioPreset;
  final ResolutionPreset resolutionPreset;
  final int sizeBytes;

  const PickedVideoInfo({
    required this.path,
    required this.name,
    required this.duration,
    required this.aspectRatioPreset,
    required this.resolutionPreset,
    this.sizeBytes = 0,
  });
}

class MediaPickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Request media permission safely on mobile platforms
  static Future<bool> requestMediaPermissions() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+)
        final videoStatus = await Permission.videos.status;
        if (videoStatus.isGranted || videoStatus.isLimited) return true;

        final videoReq = await Permission.videos.request();
        if (videoReq.isGranted || videoReq.isLimited) return true;

        // Fallback for Android 12 and below
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return true;

        final storageReq = await Permission.storage.request();
        return storageReq.isGranted;
      } else if (Platform.isIOS) {
        final photos = await Permission.photos.request();
        return photos.isGranted || photos.isLimited;
      }
    } catch (_) {
      // Permission handler may fail on desktop/unsupported platforms
    }
    return true;
  }

  /// Safely resolves a PlatformFile to an accessible local filesystem path in the app sandbox.
  static Future<String?> resolvePlatformFilePath(PlatformFile file) async {
    if (kIsWeb) return file.path;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/imported_videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final safeName = file.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final targetFile = File('${videosDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName');

      // 1. If local file path exists and is accessible
      if (file.path != null && file.path!.isNotEmpty) {
        final src = File(file.path!);
        if (await src.exists()) {
          await src.copy(targetFile.path);
          if (await targetFile.exists() && await targetFile.length() > 0) {
            return targetFile.path;
          }
        }
      }

      // 2. Read bytes on demand
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        await targetFile.writeAsBytes(bytes, flush: true);
        return targetFile.path;
      }
    } catch (e) {
      debugPrint('Error resolving PlatformFile: $e');
    }

    return file.path;
  }

  /// Pick video from file explorer / device storage
  static Future<PickedVideoInfo?> pickVideoFromFileStorage() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.video,
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final resolvedPath = await resolvePlatformFilePath(file);
        if (resolvedPath != null && resolvedPath.isNotEmpty) {
          int sizeBytes = file.lengthSync() ?? 0;
          if (sizeBytes == 0 && !kIsWeb) {
            try {
              sizeBytes = await File(resolvedPath).length();
            } catch (_) {}
          }
          final probed = await probeVideoMetadata(resolvedPath);
          return PickedVideoInfo(
            path: resolvedPath,
            name: file.name,
            duration: probed.duration,
            aspectRatioPreset: probed.aspectRatio,
            resolutionPreset: probed.resolution,
            sizeBytes: sizeBytes,
          );
        }
      }
    } catch (e) {
      debugPrint('FilePicker error: $e');
    }
    return null;
  }

  /// Pick a video using ImagePicker with automatic FilePicker fallback and sandbox persistence
  static Future<PickedVideoInfo?> pickVideo({
    ImageSource source = ImageSource.gallery,
  }) async {
    String? pickedPath;
    String? pickedName;
    int sizeBytes = 0;

    // 1. Try ImagePicker
    try {
      final XFile? xfile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 60),
      );
      if (xfile != null) {
        pickedName = xfile.name;
        try {
          sizeBytes = await xfile.length();
        } catch (_) {}

        String? sandboxedPath;
        if (!kIsWeb) {
          try {
            final appDir = await getApplicationDocumentsDirectory();
            final videosDir = Directory('${appDir.path}/imported_videos');
            if (!await videosDir.exists()) {
              await videosDir.create(recursive: true);
            }
            final safeName = (pickedName.isNotEmpty ? pickedName : 'imported_video.mp4')
                .replaceAll(RegExp(r'[^\w\.-]'), '_');
            final targetFile = File('${videosDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName');

            // Fast copy if source exists on disk
            if (xfile.path.isNotEmpty) {
              final src = File(xfile.path);
              if (await src.exists()) {
                await src.copy(targetFile.path);
                if (await targetFile.exists() && await targetFile.length() > 0) {
                  sandboxedPath = targetFile.path;
                  debugPrint('Copied video to app sandbox: ${targetFile.path}');
                }
              }
            }

            // Stream fallback
            if (sandboxedPath == null) {
              final bytes = await xfile.readAsBytes();
              if (bytes.isNotEmpty) {
                await targetFile.writeAsBytes(bytes, flush: true);
                if (await targetFile.exists() && await targetFile.length() > 0) {
                  sandboxedPath = targetFile.path;
                  debugPrint('Wrote video bytes to app sandbox: ${targetFile.path}');
                }
              }
            }
          } catch (e) {
            debugPrint('Error persisting video into sandbox: $e');
          }
        }

        // Never return a bare filename; always use sandboxedPath or xfile.path
        pickedPath = sandboxedPath ?? (xfile.path.isNotEmpty ? xfile.path : null);
      }
    } catch (e) {
      debugPrint('ImagePicker failed or cancelled: $e');
    }

    // 2. If ImagePicker returned nothing or threw, try FilePicker (gallery source only)
    if (pickedPath == null && source == ImageSource.gallery) {
      final fromStorage = await pickVideoFromFileStorage();
      if (fromStorage != null) {
        return fromStorage;
      }
    }

    if (pickedPath == null || pickedPath.isEmpty) {
      return null;
    }

    if (pickedName == null || pickedName.isEmpty) {
      pickedName = pickedPath.split(RegExp(r'[/\\]')).last;
    }

    // 3. Extract real video duration and dimensions
    final probed = await probeVideoMetadata(pickedPath);

    return PickedVideoInfo(
      path: pickedPath,
      name: pickedName,
      duration: probed.duration,
      aspectRatioPreset: probed.aspectRatio,
      resolutionPreset: probed.resolution,
      sizeBytes: sizeBytes,
    );
  }

  /// Probe real video duration, aspect ratio, and resolution using VideoPlayerController
  static Future<({Duration duration, AspectRatioPreset aspectRatio, ResolutionPreset resolution})>
      probeVideoMetadata(String path) async {
    Duration duration = const Duration(seconds: 10);
    AspectRatioPreset aspectPreset = AspectRatioPreset.vertical9x16;
    ResolutionPreset resolutionPreset = ResolutionPreset.res1080p;

    VideoPlayerController? controller;
    try {
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (path.startsWith('content://')) {
        controller = VideoPlayerController.contentUri(Uri.parse(path));
      } else if (path.startsWith('file://')) {
        controller = VideoPlayerController.file(File(Uri.parse(path).toFilePath()));
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (path.startsWith('assets/')) {
        controller = VideoPlayerController.asset(path);
      } else {
        final f = File(path);
        if (await f.exists()) {
          controller = VideoPlayerController.file(f);
        } else {
          final uri = Uri.tryParse(path);
          if (uri != null && uri.hasScheme) {
            controller = VideoPlayerController.contentUri(uri);
          } else {
            // Search sandbox
            final appDir = await getApplicationDocumentsDirectory();
            final videosDir = Directory('${appDir.path}/imported_videos');
            final base = path.split(RegExp(r'[/\\]')).last;
            if (await videosDir.exists()) {
              final match = videosDir
                  .listSync()
                  .whereType<File>()
                  .where((x) => x.path.endsWith(base) || x.path.contains(base))
                  .firstOrNull;
              if (match != null) {
                controller = VideoPlayerController.file(match);
              }
            }
          }
        }
      }

      if (controller != null) {
        await controller.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Video probe timeout'),
        );

        final d = controller.value.duration;
        if (d > Duration.zero) {
          duration = d;
        }

        final size = controller.value.size;
        if (size.width > 0 && size.height > 0) {
          final ratio = size.width / size.height;
          if (ratio < 0.7) {
            aspectPreset = AspectRatioPreset.vertical9x16; // 9:16 (0.5625)
          } else if (ratio < 0.9) {
            aspectPreset = AspectRatioPreset.portrait4x5; // 4:5 (0.8)
          } else if (ratio < 1.25) {
            aspectPreset = AspectRatioPreset.square1x1; // 1:1 (1.0)
          } else if (ratio < 2.0) {
            aspectPreset = AspectRatioPreset.horizontal16x9; // 16:9 (1.777)
          } else {
            aspectPreset = AspectRatioPreset.cinematic21x9; // 21:9 (2.333)
          }

          // Determine resolution
          final maxDimension = size.width > size.height ? size.width : size.height;
          if (maxDimension >= 2500) {
            resolutionPreset = ResolutionPreset.res4K;
          } else if (maxDimension >= 1000) {
            resolutionPreset = ResolutionPreset.res1080p;
          } else {
            resolutionPreset = ResolutionPreset.res720p;
          }
        }
      }
    } catch (e) {
      debugPrint('Could not probe video metadata directly: $e');
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
    }

    return (
      duration: duration,
      aspectRatio: aspectPreset,
      resolution: resolutionPreset,
    );
  }
}
