import 'dart:async';
import 'package:flutter/foundation.dart';

enum SelectedTrackType {
  none,
  video,
  text,
  audio,
}

class TimelineProvider extends ChangeNotifier {
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(seconds: 28);
  bool _isPlaying = false;
  double _zoomLevel = 1.0; // 1.0 = standard, 2.0 = zoomed in
  Timer? _playbackTimer;

  SelectedTrackType _selectedTrack = SelectedTrackType.none;
  String? _selectedItemId;

  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;
  double get zoomLevel => _zoomLevel;
  SelectedTrackType get selectedTrack => _selectedTrack;
  String? get selectedItemId => _selectedItemId;

  void setTotalDuration(Duration duration) {
    if (_totalDuration != duration) {
      _totalDuration = duration;
      if (_currentPosition > _totalDuration) {
        _currentPosition = _totalDuration;
      }
      notifyListeners();
    }
  }

  void seekTo(Duration position) {
    if (position < Duration.zero) {
      _currentPosition = Duration.zero;
    } else if (position > _totalDuration) {
      _currentPosition = _totalDuration;
    } else {
      _currentPosition = position;
    }
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (_isPlaying) return;
    if (_currentPosition >= _totalDuration) {
      _currentPosition = Duration.zero;
    }
    _isPlaying = true;
    notifyListeners();

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      final nextMs = _currentPosition.inMilliseconds + 33;
      if (nextMs >= _totalDuration.inMilliseconds) {
        _currentPosition = _totalDuration;
        pause();
      } else {
        _currentPosition = Duration(milliseconds: nextMs);
        notifyListeners();
      }
    });
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    notifyListeners();
  }

  void setZoomLevel(double zoom) {
    _zoomLevel = zoom.clamp(0.5, 3.0);
    notifyListeners();
  }

  void selectItem(SelectedTrackType trackType, String? itemId) {
    _selectedTrack = trackType;
    _selectedItemId = itemId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedTrack = SelectedTrackType.none;
    _selectedItemId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
