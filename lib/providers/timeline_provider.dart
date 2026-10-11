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

  bool _isPlayerDriving = false;

  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;
  double get zoomLevel => _zoomLevel;
  SelectedTrackType get selectedTrack => _selectedTrack;
  String? get selectedItemId => _selectedItemId;
  bool get isPlayerDriving => _isPlayerDriving;

  void setTotalDuration(Duration duration) {
    if (_totalDuration != duration) {
      _totalDuration = duration;
      if (_currentPosition > _totalDuration) {
        _currentPosition = _totalDuration;
      }
      notifyListeners();
    }
  }

  void setPlayerDriving(bool driving) {
    _isPlayerDriving = driving;
    if (driving && _isPlaying) {
      // Let the video player clock drive smoothly
      _playbackTimer?.cancel();
      _playbackTimer = null;
    } else if (!driving && _isPlaying && _playbackTimer == null) {
      _startFallbackTimer();
    }
  }

  /// Called smoothly by active video controller while playing
  void updatePositionFromPlayback(Duration position) {
    if (position < Duration.zero) {
      _currentPosition = Duration.zero;
    } else if (position >= _totalDuration) {
      _currentPosition = _totalDuration;
      pause();
      return;
    } else {
      _currentPosition = position;
    }
    notifyListeners();
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

  void stepForward({Duration step = const Duration(seconds: 1)}) {
    seekTo(_currentPosition + step);
  }

  void stepBackward({Duration step = const Duration(seconds: 1)}) {
    seekTo(_currentPosition - step);
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

    if (!_isPlayerDriving) {
      _startFallbackTimer();
    }
  }

  void _startFallbackTimer() {
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

  void zoomIn() => setZoomLevel((_zoomLevel + 0.25).clamp(0.5, 3.0));
  void zoomOut() => setZoomLevel((_zoomLevel - 0.25).clamp(0.5, 3.0));

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
