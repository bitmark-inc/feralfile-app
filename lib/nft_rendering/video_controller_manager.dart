import 'dart:async';

import 'package:video_player/video_player.dart';

final videoControllerManager = VideoControllerManager(maxVideoControllers: 1);

class VideoControllerManager {
  // Map to store video positions when users switch between videos
  final Map<String, Duration> _videoSeekPositionMap = {};

  // Map from video URL path to their controllers
  final Map<String, VideoPlayerController> _videoControllers = {};

  // List of video URL paths to manage the pool (first is oldest)
  final List<String> _controllerPool = [];

  // Maximum number of video controllers (configurable)
  final int maxVideoControllers;

  // Function to call before a controller is disposed
  final Map<String, Function(VideoPlayerController)>
      _beforeVideoControllerDisposedHandlers = {};

  // Constructor to set the maximum number of controllers
  VideoControllerManager({this.maxVideoControllers = 2});

  /// Disposes of a specific controller by [videoUri], or all if [videoUri] is null
  Future<void> recycle({Uri? videoUri, bool resetSeekPosition = false}) async {
    if (videoUri != null) {
      final videoPath = videoUri.path;
      // Dispose the controller associated with the videoUri
      final controller = _videoControllers[videoPath];
      if (controller != null) {
        if (resetSeekPosition) {
          _videoSeekPositionMap.remove(videoPath);
        } else {
          final position = controller.value.position;
          _videoSeekPositionMap[videoPath] = position;
        }
        _beforeVideoControllerDisposedHandlers[videoPath]?.call(controller);
        await controller.dispose();
        _videoControllers.remove(videoPath);
        _controllerPool.remove(videoPath);
      }
    } else {
      // Dispose all controllers
      for (var controller in _videoControllers.values) {
        final position = controller.value.position;
        final videoPath = _controllerPool.firstWhere(
          (path) => _videoControllers[path] == controller,
          orElse: () => '',
        );
        _videoSeekPositionMap[videoPath] = position;
        _beforeVideoControllerDisposedHandlers[videoPath]?.call(controller);
        await controller.dispose();
      }
      _videoControllers.clear();
      _controllerPool.clear();
    }
  }

  /// Requests a video controller for the given [videoUri]
  Future<VideoPlayerController> requestVideoController(
    Uri videoUri, {
    Function(VideoPlayerController)? onVideoControllerCreated,
    Function(VideoPlayerController)? beforeVideoControllerDisposed,
  }) async {
    final videoPath = videoUri.path;

    // Check if the controller for this videoUri is already in the pool
    if (_videoControllers.containsKey(videoPath)) {
      // Bring the videoUri to the end of the pool (most recently used)
      _controllerPool
        ..remove(videoPath)
        ..add(videoPath);
      final controller = _videoControllers[videoPath]!;
      if (!controller.value.isInitialized) {
        onVideoControllerCreated?.call(controller);
        await controller.initialize();
      }
      return controller;
    } else {
      VideoPlayerController controller;

      if (_controllerPool.length < maxVideoControllers) {
        // Create a new controller
        controller = VideoPlayerController.networkUrl(videoUri);
        await controller.initialize();
      } else {
        // Replace the first (oldest) controller in the pool
        final oldestVideoPath = _controllerPool[0];

        await recycle(videoUri: Uri.parse(oldestVideoPath));

        // Create a new controller
        controller = VideoPlayerController.networkUrl(videoUri);
        await controller.initialize();
      }

      // Add the new controller to the pool and mappings
      _videoControllers[videoPath] = controller;
      _controllerPool.add(videoPath);
      _beforeVideoControllerDisposedHandlers[videoPath] =
          beforeVideoControllerDisposed ?? (_) {};

      // Seek to saved position if it exists
      final savedPosition = _videoSeekPositionMap[videoPath];
      if (savedPosition != null) {
        await controller.seekTo(savedPosition);
      }

      onVideoControllerCreated?.call(controller);
      return controller;
    }
  }
}
