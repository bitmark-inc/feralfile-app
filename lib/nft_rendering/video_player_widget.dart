import 'dart:async';

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/nft_rendering/nft_error_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:autonomy_flutter/nft_rendering/video_controller_manager.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:video_player/video_player.dart';

class VideoNFTRenderingWidget extends NFTRenderingWidget {
  final String previewURL; // The URL of the video to play
  final String? thumbnailURL; // The URL of the thumbnail to display
  final bool isMute; // Mute state of the video
  final Widget loadingWidget; // Custom loading widget
  final Widget errorWidget; // Custom error widget
  final Widget
      noPreviewUrlWidget; // Widget to show when no preview URL is provided
  final Function? onLoaded; // Callback for when the video is loaded
  final Function? onDispose; // Callback for when the widget is disposed

  const VideoNFTRenderingWidget({
    required this.previewURL,
    this.loadingWidget = const LoadingWidget(),
    this.errorWidget = const NFTErrorWidget(),
    this.noPreviewUrlWidget = const NoPreviewUrlWidget(),
    super.key,
    this.thumbnailURL,
    this.isMute = false,
    this.onLoaded,
    this.onDispose,
  });

  @override
  State<VideoNFTRenderingWidget> createState() =>
      _VideoNFTRenderingWidgetState();
}

class _VideoNFTRenderingWidgetState
    extends NFTRenderingWidgetState<VideoNFTRenderingWidget>
    with RouteAware, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isPreviewLoaded = false;
  bool _isPlayingFailed = false;
  bool _playAfterInitialized = true;
  bool _shouldUseThumbnail = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initVideoController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didUpdateWidget(covariant VideoNFTRenderingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewURL != widget.previewURL) {
      unawaited(_dispose().then((_) => _initVideoController()));
    }
  }

  Future<void> _initVideoController(
      {bool shouldIncreaseRefCountIfALreadyExist = true}) async {
    try {
      final videoUri = Uri.parse(widget.previewURL);
      _controller = await videoControllerManager.requestVideoController(
        videoUri,
        shouldIncrementRefCountIfAlreadyExists:
            shouldIncreaseRefCountIfALreadyExist,
        beforeVideoControllerDisposed: (controller) {
          if (context.mounted) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) {
                setState(
                  () {
                    _isPreviewLoaded = false;
                    _isPlayingFailed = false;
                    _shouldUseThumbnail = true;
                    _controller = null;
                  },
                );
              },
            );
          }
        },
      );
      if (widget.isMute) {
        await _controller?.setVolume(0);
      } else {
        await _controller?.setVolume(1);
      }
      await _controller?.setLooping(true);
      if (_playAfterInitialized) {
        await _controller?.play();
      }

      // Callback when the video is loaded
      if (widget.onLoaded != null) {
        final time = _controller?.value.duration.inSeconds;
        widget.onLoaded?.call(time);
      }
      setState(() {
        _isPreviewLoaded = true;
        _shouldUseThumbnail = false;
        _isPlayingFailed = false;
      });
    } catch (error) {
      log.info('Error initializing video controller: $error');
      unawaited(Sentry.captureException(
          'Error initializing video controller: $error'));
      if (error is! FlutterError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isPlayingFailed = true;
              _shouldUseThumbnail = false;
              _isPreviewLoaded = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    unawaited(_dispose());
    super.dispose();
  }

  Future<void> _dispose() async {
    if (widget.onDispose != null) {
      final position = await _controller?.position;
      widget.onDispose?.call(position?.inSeconds ?? 0);
    }
    if (_controller != null) {
      await videoControllerManager.recycle(
        videoUri: Uri.parse(widget.previewURL),
        resetSeekPosition: true,
      );
      _controller = null;
    }
  }

  Future<void> pauseOrResume() async {
    if (_controller?.value.isPlaying ?? false) {
      await _controller?.pause();
    } else {
      await _controller?.play();
    }
  }

  @override
  Future<void> didPushNext() async {
    _playAfterInitialized = false;
    await _controller?.pause();
  }

  @override
  Future<void> didPopNext() async {
    _playAfterInitialized = true;
    // request video controller again
    // when _controller is already exist in controller pool,
    // we should not increase the ref count
    await _initVideoController(shouldIncreaseRefCountIfALreadyExist: false);
  }

  @override
  Widget build(BuildContext context) {
    final previewURL = widget.previewURL;
    final thumbnailURL = widget.thumbnailURL;
    if (previewURL.isEmpty) {
      return widget.noPreviewUrlWidget; // Show no preview URL widget
    }

    if ((_shouldUseThumbnail || _isPlayingFailed) && thumbnailURL != null) {
      return _videoThumbnail(thumbnailURL);
    }

    if (_controller != null) {
      if (_isPreviewLoaded) {
        return Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(
                  _controller!,
                ),
              ),
            ),
            Visibility(
              visible: widget.isMute,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: SvgPicture.asset('assets/images/Mute_Circle.svg'),
                ),
              ),
            ),
          ],
        );
      } else {
        return widget.loadingWidget;
      }
    } else {
      return widget.loadingWidget;
    }
  }

  Widget _videoThumbnail(String thumbnailURL) => Image.network(
        thumbnailURL,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return widget.loadingWidget;
        },
        errorBuilder: (context, url, error) => Center(
          child: widget.errorWidget,
        ),
        fit: BoxFit.cover,
      );

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> resume() async {
    await _controller?.play();
  }

  @override
  Future<void> mute() async {
    await _controller?.setVolume(0);
  }

  @override
  Future<void> unmute() async {
    await _controller?.setVolume(1);
  }
}
