import 'package:better_player_plus/better_player_plus.dart';

class VideoManager {
  static final VideoManager _instance = VideoManager._internal();
  factory VideoManager() => _instance;

  BetterPlayerController? _currentController;

  VideoManager._internal();

  void setController(BetterPlayerController controller) {
    if (_currentController != null && _currentController != controller) {
      _currentController!.pause();
    }
    _currentController = controller;
  }

  void pauseCurrent() {
    _currentController?.pause();
  }

  void disposeCurrent() {
    _currentController?.dispose();
    _currentController = null;
  }
}
