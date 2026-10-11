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

  /// Safely resolves a PlatformFile to an accessible local filesystem path.
  /// If the file only exists as a content URI or stream, copies its bytes to the app's cache directory.
  static Future<String?> resolvePlatformFilePath(PlatformFile file) async {
    if (file.path != null && file.path!.isNotEmpty) {
      if (kIsWeb) return file.path;
      final f = File(file.path!);
      if (await f.exists()) {
        return file.path;
      }
    }

    // Attempt to copy bytes to cache for Android content:// or SAF streams
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final sanitized = file.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
        final target = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$sanitized');
        await target.writeAsBytes(bytes, flush: true);
        return target.path;
      }
    } catch (e) {
      debugPrint('Error reading/caching PlatformFile: $e');
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

  /// Pick a video using ImagePicker with automatic FilePicker fallback
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
        pickedPath = xfile.path;
        pickedName = xfile.name;
        sizeBytes = await xfile.length();
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
      } else {
        controller = VideoPlayerController.file(File(path));
      }

      await controller.initialize().timeout(
        const Duration(seconds: 4),
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
