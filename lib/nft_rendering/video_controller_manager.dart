import 'dart:async';

import 'package:autonomy_flutter/util/log.dart';
import 'package:sentry/sentry.dart';
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

  final Map<String, Completer<VideoPlayerController>>
      _requestVideoControllerCompleters = {};

  // Constructor to set the maximum number of controllers
  VideoControllerManager({this.maxVideoControllers = 2});

  final Map<String, bool> _cyclingUriMap = {};

  final Map<String, int> _controllerRefCount =
      {}; // Track references per controller

  Future<void> _recycleUri(Uri videoUri,
      {bool resetSeekPosition = false}) async {
    final videoPath = videoUri.toString();
    if (_cyclingUriMap[videoPath] == true) {
      log.info('[VideoControllerManager] Recycling video controller '
          'for $videoUri is already in progress');
      return;
    }
    _cyclingUriMap[videoPath] = true;
    log.info(
        '[VideoControllerManager] Recycling video controller for $videoUri');
    // Dispose the controller associated with the videoUri
    try {
      final controller = _videoControllers[videoPath];
      if (controller != null) {
        _controllerRefCount[videoPath] =
            (_controllerRefCount[videoPath] ?? 1) - 1;
        if (_controllerRefCount[videoPath]! <= 0) {
          if (resetSeekPosition) {
            _videoSeekPositionMap.remove(videoPath);
          } else {
            final position = controller.value.position;
            _videoSeekPositionMap[videoPath] = position;
          }
          try {
            _beforeVideoControllerDisposedHandlers[videoPath]?.call(controller);
          } catch (error) {
            log.info('[VideoControllerManager] Error calling '
                'beforeVideoControllerDisposed handler '
                'for $videoUri: $error');
          }
          await controller.dispose();
          _videoControllers.remove(videoPath);
          _controllerPool.remove(videoPath);
          _controllerRefCount.remove(videoPath);
        } else {
          await controller.setVolume(0);
        }
      }
      _cyclingUriMap.remove(videoPath);
    } catch (error, s) {
      log.info('[VideoControllerManager] Error recycling video '
          'controller for $videoUri: $error');
      unawaited(Sentry.captureException(
          'Error recycling video controller for $videoUri, error: $error',
          stackTrace: s));
      _cyclingUriMap.remove(videoPath);
    }
  }

  /// Disposes of a specific controller by [videoUri],
  /// or all if [videoUri] is null
  Future<void> recycle({Uri? videoUri, bool resetSeekPosition = false}) async {
    if (videoUri != null) {
      await _recycleUri(videoUri, resetSeekPosition: resetSeekPosition);
    } else {
      // Dispose all controllers
      for (var controller in _videoControllers.values) {
        final videoPath = _controllerPool.firstWhere(
          (path) => _videoControllers[path] == controller,
          orElse: () => '',
        );
        await _recycleUri(Uri.parse(videoPath),
            resetSeekPosition: resetSeekPosition);
      }
      _videoControllers.clear();
      _controllerPool.clear();
    }
    log.info(
        '[VideoControllerManager] Recycled video controller for $videoUri');
  }

  /// Requests a video controller for the given [videoUri]
  Future<VideoPlayerController> requestVideoController(
    Uri videoUri, {
    Function(VideoPlayerController)? onVideoControllerCreated,
    Function(VideoPlayerController)? beforeVideoControllerDisposed,
    bool shouldIncrementRefCountIfAlreadyExists = true,
  }) async {
    log.info(
        '[VideoControllerManager] Requesting video controller for $videoUri');
    final videoPath = videoUri.toString();
    Completer<VideoPlayerController>? completer =
        _requestVideoControllerCompleters[videoPath];
    if (completer != null) {
      return completer.future;
    }
    completer = Completer<VideoPlayerController>();
    _requestVideoControllerCompleters[videoPath] = completer;

    try {
      // Check if the controller for this videoUri is already in the pool
      if (_videoControllers.containsKey(videoPath)) {
        log.info('[VideoControllerManager] Video controller '
            'for $videoUri already exists');
        // Bring the videoUri to the end of the pool (most recently used)
        _controllerPool
          ..remove(videoPath)
          ..add(videoPath);
        final controller = _videoControllers[videoPath]!;
        if (!controller.value.isInitialized) {
          onVideoControllerCreated?.call(controller);
          await controller.initialize();
        }
        completer.complete(controller);
        _requestVideoControllerCompleters.remove(videoPath);
        if (shouldIncrementRefCountIfAlreadyExists) {
          _controllerRefCount[videoPath] =
              (_controllerRefCount[videoPath] ?? 0) + 1;
        }
        return controller;
      } else {
        VideoPlayerController controller;

        if (_controllerPool.length < maxVideoControllers) {
          log.info('[VideoControllerManager] Creating new '
              'video controller for $videoUri');
          // Create a new controller
          controller = VideoPlayerController.networkUrl(videoUri);
          await controller.initialize();
        } else {
          log.info('[VideoControllerManager] Replacing video '
              'controller for $videoUri');
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
        log.info('[VideoControllerManager] '
            'Requested video controller for $videoUri');
        completer.complete(controller);
        _requestVideoControllerCompleters.remove(videoPath);
        _controllerRefCount[videoPath] =
            (_controllerRefCount[videoPath] ?? 0) + 1;
        return controller;
      }
    } catch (error, s) {
      log.info('[VideoControllerManager] '
          'Error requesting video controller for $videoUri: $error');
      unawaited(
        Sentry.captureException(
          'Error requesting video controller for $videoUri, error: $error',
          stackTrace: s,
        ),
      );
      completer.completeError(error);
      _requestVideoControllerCompleters.remove(videoPath);
      return completer.future;
    }
  }
}
