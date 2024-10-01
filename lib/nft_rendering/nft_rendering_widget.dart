// ignore_for_file: discarded_futures

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:autonomy_flutter/nft_rendering/feralfile_webview.dart';
import 'package:autonomy_flutter/nft_rendering/nft_error_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/nft_rendering/svg_image.dart';
import 'package:autonomy_flutter/nft_rendering/webview_controller_ext.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Get nft rendering widget by type
/// You can add and define more types by creating classes extends
/// [INFTRenderingWidget]
///
const keysCode = {
  'backspace': 8,
  'tab': 9,
  'enter': 13,
  'shift': 16,
  'ctrl': 17,
  'alt': 18,
  'pausebreak': 19,
  'capslock': 20,
  'esc': 27,
  'space': 32,
  'pageup': 33,
  'pagedown': 34,
  'end': 35,
  'home': 36,
  'leftarrow': 37,
  'uparrow': 38,
  'rightarrow': 39,
  'downarrow': 40,
  'insert': 45,
  'delete': 46,
  '0': 48,
  '1': 49,
  '2': 50,
  '3': 51,
  '4': 52,
  '5': 53,
  '6': 54,
  '7': 55,
  '8': 56,
  '9': 57,
  'a': 65,
  'b': 66,
  'c': 67,
  'd': 68,
  'e': 69,
  'f': 70,
  'g': 71,
  'h': 72,
  'i': 73,
  'j': 74,
  'k': 75,
  'l': 76,
  'm': 77,
  'n': 78,
  'o': 79,
  'p': 80,
  'q': 81,
  'r': 82,
  's': 83,
  't': 84,
  'u': 85,
  'v': 86,
  'w': 87,
  'x': 88,
  'y': 89,
  'z': 90,
  'leftwindowkey': 91,
  'rightwindowkey': 92,
  'selectkey': 93,
  'numpad0': 96,
  'numpad1': 97,
  'numpad2': 98,
  'numpad3': 99,
  'numpad4': 100,
  'numpad5': 101,
  'numpad6': 102,
  'numpad7': 103,
  'numpad8': 104,
  'numpad9': 105,
  'multiply': 106,
  'add': 107,
  'subtract': 109,
  'decimalpoint': 110,
  'divide': 111,
  'f1': 112,
  'f2': 113,
  'f3': 114,
  'f4': 115,
  'f5': 116,
  'f6': 117,
  'f7': 118,
  'f8': 119,
  'f9': 120,
  'f10': 121,
  'f11': 122,
  'f12': 123,
  'numlock': 144,
  'scrolllock': 145,
  'semicolon': 186,
  'equalsign': 187,
  'comma': 188,
  'dash': 189,
  'period': 190,
  'forwardslash': 191,
  'graveaccent': 192,
  'openbracket': 219,
  'backslash': 220,
  'closebracket': 221,
  'singlequote': 222
};

class RenderingType {
  static const image = 'image';
  static const svg = 'svg';
  static const gif = 'gif';
  static const audio = 'audio';
  static const video = 'video';
  static const pdf = 'application/pdf';
  static const webview = 'webview';
  static const modelViewer = 'modelViewer';
}

INFTRenderingWidget typesOfNFTRenderingWidget(String type) {
  switch (type) {
    case RenderingType.image:
      return ImageNFTRenderingWidget();
    case RenderingType.svg:
      return SVGNFTRenderingWidget();
    case RenderingType.gif:
      return GifNFTRenderingWidget();
    case RenderingType.audio:
      return AudioNFTRenderingWidget();
    case RenderingType.video:
      return VideoNFTRenderingWidget();
    case RenderingType.pdf:
      return PDFNFTRenderingWidget();
    case RenderingType.modelViewer:
      return kIsWeb
          ? ModelViewerRenderingWidget()
          : ModelViewerRenderingWidget();
    case RenderingType.webview:
      return kIsWeb ? WebviewNFTRenderingWidget() : WebviewNFTRenderingWidget();
    default:
      return WebviewNFTRenderingWidget();
  }
}

/// Class holds property of rendering widget
class RenderingWidgetBuilder {
  late Widget? loadingWidget;
  late Widget? errorWidget;
  late Widget? noPreviewUrlWidget;
  final String? thumbnailURL;
  late String? previewURL;
  late dynamic controller;
  final int? latestPosition;
  final String? overriddenHtml;
  final bool isMute;
  final bool skipViewport;
  Function({int? time, WebViewController? webViewController})? onLoaded;
  Function({int? time})? onDispose;
  FocusNode? focusNode;

  RenderingWidgetBuilder({
    this.loadingWidget,
    this.errorWidget,
    this.noPreviewUrlWidget,
    this.thumbnailURL,
    this.previewURL,
    this.controller,
    this.onLoaded,
    this.onDispose,
    this.latestPosition,
    this.overriddenHtml,
    this.isMute = false,
    this.focusNode,
    this.skipViewport = false,
  });
}

/// interface of rendering widget
abstract class INFTRenderingWidget {
  INFTRenderingWidget({RenderingWidgetBuilder? renderingWidgetBuilder}) {
    if (renderingWidgetBuilder != null) {
      loadingWidget =
          renderingWidgetBuilder.loadingWidget ?? const NFTLoadingWidget();
      errorWidget =
          renderingWidgetBuilder.errorWidget ?? const NFTErrorWidget();
      previewURL = renderingWidgetBuilder.previewURL ?? '';
      controller = renderingWidgetBuilder.controller;
      onLoaded = renderingWidgetBuilder.onLoaded;
      onDispose = renderingWidgetBuilder.onDispose;
      latestPosition = renderingWidgetBuilder.latestPosition;
      overriddenHtml = renderingWidgetBuilder.overriddenHtml;
      isMute = renderingWidgetBuilder.isMute;
      skipViewport = renderingWidgetBuilder.skipViewport;
      focusNode = renderingWidgetBuilder.focusNode;
    }
  }

  void setRenderWidgetBuilder(RenderingWidgetBuilder renderingWidgetBuilder) {
    loadingWidget =
        renderingWidgetBuilder.loadingWidget ?? const NFTLoadingWidget();
    errorWidget = renderingWidgetBuilder.errorWidget ?? const NFTErrorWidget();
    noPreviewUrlWidget =
        renderingWidgetBuilder.noPreviewUrlWidget ?? const NoPreviewUrlWidget();
    previewURL = renderingWidgetBuilder.previewURL ?? '';
    controller = renderingWidgetBuilder.controller;
    onLoaded = renderingWidgetBuilder.onLoaded;
    onDispose = renderingWidgetBuilder.onDispose;
    latestPosition = renderingWidgetBuilder.latestPosition;
    overriddenHtml = renderingWidgetBuilder.overriddenHtml;
    isMute = renderingWidgetBuilder.isMute;
    skipViewport = renderingWidgetBuilder.skipViewport;
    focusNode = renderingWidgetBuilder.focusNode;
  }

  Function({int? time, WebViewController? webViewController})? onLoaded;
  Function({int? time})? onDispose;
  FocusNode? focusNode;
  Widget loadingWidget = const NFTLoadingWidget();
  Widget errorWidget = const NFTErrorWidget();
  Widget noPreviewUrlWidget = const NoPreviewUrlWidget();
  String previewURL = '';
  dynamic controller;
  int? latestPosition;
  String? overriddenHtml;
  bool isMute = false;
  bool skipViewport = false;

  Widget build(BuildContext context) => const SizedBox();

  static const fadeThreshold = 0.7;

  Widget _loadingBuilder(
      BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) {
      return child;
    }
    return Opacity(
      opacity: _getOpacityFromLoadingProgress(loadingProgress),
      child: loadingWidget,
    );
  }

  double _getOpacityFromLoadingProgress(ImageChunkEvent loadingProgress) {
    if (loadingProgress.expectedTotalBytes == null) {
      return 1;
    }
    final total = loadingProgress.expectedTotalBytes!.toDouble();
    final loaded = loadingProgress.cumulativeBytesLoaded.toDouble();
    final progress = loaded / total;
    if (progress < fadeThreshold) {
      return 1;
    } else {
      return 1.0 - ((progress - fadeThreshold) / (1 - fadeThreshold));
    }
  }

  void dispose();

  void didPopNext();

  Future<void> pauseOrResume() async {}

  Future<void> pause() async {}

  Future<void> resume() async {}

  Future<void> mute() async {}

  Future<void> unmute() async {}

  Future<bool> clearPrevious();
}

/// Image rendering widget type
class ImageNFTRenderingWidget extends INFTRenderingWidget {
  ImageNFTRenderingWidget({
    super.renderingWidgetBuilder,
  });

  @override
  Widget build(BuildContext context) {
    onLoaded?.call();
    return previewURL.isEmpty ? noPreviewUrlWidget : _widgetBuilder();
  }

  Widget _widgetBuilder() => Image.network(
        previewURL,
        loadingBuilder: _loadingBuilder,
        errorBuilder: (context, url, error) => Center(
          child: errorWidget,
        ),
        // fit: BoxFit.cover,
      );

  @override
  void didPopNext() {}

  @override
  void dispose() {}

  @override
  Future<bool> clearPrevious() => Future.value(true);
}

class SVGNFTRenderingWidget extends INFTRenderingWidget {
  SVGNFTRenderingWidget({
    super.renderingWidgetBuilder,
  });

  @override
  Widget build(BuildContext context) =>
      previewURL.isEmpty ? noPreviewUrlWidget : _widgetBuilder();

  @override
  Future<bool> clearPrevious() => Future.value(true);

  @override
  void didPopNext() {}

  @override
  void dispose() {}

  Widget _widgetBuilder() => SvgImage(
        url: previewURL,
        fallbackToWebView: true,
        loadingWidgetBuilder: (context) => loadingWidget,
        onLoaded: () => onLoaded?.call(),
        onError: () {},
      );
}

class GifNFTRenderingWidget extends INFTRenderingWidget {
  GifNFTRenderingWidget({
    super.renderingWidgetBuilder,
  });

  @override
  Widget build(BuildContext context) {
    onLoaded?.call();
    return previewURL.isEmpty ? noPreviewUrlWidget : _widgetBuilder();
  }

  @override
  Future<bool> clearPrevious() => Future.value(true);

  @override
  void didPopNext() {}

  @override
  void dispose() {}

  Widget _widgetBuilder() => Image.network(
        previewURL,
        loadingBuilder: _loadingBuilder,
        errorBuilder: (context, url, error) => Center(
          child: errorWidget,
        ),
        fit: BoxFit.cover,
      );
}

class AudioNFTRenderingWidget extends INFTRenderingWidget {
  String? _thumbnailURL;
  AudioPlayer? _player;

  final _progressStreamController = StreamController<double>();

  @override
  Future<bool> clearPrevious() async {
    await _pauseAudio();
    return true;
  }

  @override
  void didPopNext() {
    unawaited(_resumeAudio());
  }

  @override
  void dispose() {
    unawaited(_disposeAudioPlayer());
  }

  @override
  Future<void> pauseOrResume() async {
    if (_player?.playing == true) {
      await _pauseAudio();
    } else {
      await _resumeAudio();
    }
  }

  @override
  Future<void> pause() async {
    if (_player?.playing == true) {
      await _pauseAudio();
    }
  }

  @override
  Future<void> resume() async {
    if (_player?.playing == false) {
      await _resumeAudio();
    }
  }

  @override
  Future<void> mute() async {
    unawaited(_player?.setVolume(0));
  }

  @override
  Future<void> unmute() async {
    unawaited(_player?.setVolume(1));
  }

  Future _disposeAudioPlayer() async {
    await _player?.dispose();
    _player = null;
  }

  Future _playAudio(String audioURL) async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _player = AudioPlayer();
      _player?.positionStream.listen((event) {
        final progress =
            event.inMilliseconds / (_player?.duration?.inMilliseconds ?? 1);
        _progressStreamController.sink.add(progress);
      });
      await _player?.setLoopMode(LoopMode.all);
      await _player?.setAudioSource(AudioSource.uri(Uri.parse(audioURL)));
      if (isMute) {
        unawaited(mute());
      }
      onLoaded?.call(time: _player?.duration?.inSeconds);
      await _player?.play();
    } catch (e) {
      if (kDebugMode) {
        print("Can't set audio source: $audioURL. Error: $e");
      }
    }
  }

  Future<void> _pauseAudio() async {
    await _player?.pause();
  }

  Future<void> _resumeAudio() async {
    await _player?.play();
  }

  @override
  void setRenderWidgetBuilder(RenderingWidgetBuilder renderingWidgetBuilder) {
    super.setRenderWidgetBuilder(renderingWidgetBuilder);
    _thumbnailURL = renderingWidgetBuilder.thumbnailURL;
    unawaited(_disposeAudioPlayer().then((_) {
      final audioURL = renderingWidgetBuilder.previewURL;
      if (audioURL != null) {
        _playAudio(audioURL);
      }
    }));
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Image.network(
              _thumbnailURL ?? '',
              loadingBuilder: _loadingBuilder,
              errorBuilder: (context, url, error) => Center(
                child: errorWidget,
              ),
              fit: BoxFit.contain,
            ),
          ),
          StreamBuilder<double>(
              stream: _progressStreamController.stream,
              builder: (context, snapshot) => LinearProgressIndicator(
                    value: snapshot.data ?? 0,
                    color: const Color.fromRGBO(0, 255, 163, 1),
                    backgroundColor: Colors.transparent,
                  )),
        ],
      );
}

/// Video rendering widget type
class VideoNFTRenderingWidget extends INFTRenderingWidget {
  String? _thumbnailURL;
  bool _playAfterInitialized = true;

  VideoNFTRenderingWidget({
    super.renderingWidgetBuilder,
  }) {
    runZonedGuarded(() {
      _controller = VideoPlayerController.networkUrl(Uri.parse(previewURL));

      unawaited(_controller!.initialize().then((_) async {
        _stateOfRenderingWidget.previewLoaded();
        final durationVideo = _controller?.value.duration.inSeconds ?? 0;
        Duration position;
        if (latestPosition == null || latestPosition! >= durationVideo) {
          position = const Duration();
        } else {
          position = Duration(seconds: latestPosition!);
        }
        await _controller?.seekTo(position);
        if (isMute) {
          await _controller?.setVolume(0);
        }
        onLoaded?.call(time: durationVideo);
        await _controller?.setLooping(true);
        if (_playAfterInitialized) {
          await _controller?.play();
        }
      }));
    }, (error, stack) {
      _stateOfRenderingWidget.playingFailed();
    });
  }

  @override
  Future<void> pauseOrResume() async {
    if (_controller?.value.isPlaying ?? false) {
      await _controller?.pause();
    } else {
      await _controller?.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_controller?.value.isPlaying ?? false) {
      await _controller?.pause();
    }
  }

  @override
  Future<void> resume() async {
    if (!(_controller?.value.isPlaying ?? false)) {
      await _controller?.play();
    }
  }

  @override
  Future<void> mute() async {
    await _controller?.setVolume(0);
  }

  @override
  Future<void> unmute() async {
    await _controller?.setVolume(1);
  }

  VideoPlayerController? _controller;
  final _stateOfRenderingWidget = StateOfRenderingWidget();

  @override
  void setRenderWidgetBuilder(RenderingWidgetBuilder renderingWidgetBuilder) {
    super.setRenderWidgetBuilder(renderingWidgetBuilder);
    runZonedGuarded(() {
      _thumbnailURL = renderingWidgetBuilder.thumbnailURL;
      if (_controller != null) {
        unawaited(_controller?.dispose());
        _controller = null;
      }
      _controller = VideoPlayerController.networkUrl(Uri.parse(previewURL));

      unawaited(_controller!.initialize().then((_) async {
        final time = _controller?.value.duration.inSeconds;
        Duration position;
        if (latestPosition == null ||
            latestPosition! >= _controller!.value.duration.inSeconds) {
          position = const Duration();
        } else {
          position = Duration(seconds: latestPosition!);
        }
        await _controller?.seekTo(position);
        if (isMute) {
          await _controller?.setVolume(0);
        }
        onLoaded?.call(time: time);
        _stateOfRenderingWidget.previewLoaded();
        unawaited(_controller?.setLooping(true));
        if (_playAfterInitialized) {
          unawaited(_controller?.play());
        }
      }));
    }, (error, stack) {
      _stateOfRenderingWidget.playingFailed();
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _stateOfRenderingWidget,
        builder: (context, child) =>
            previewURL.isEmpty ? noPreviewUrlWidget : _widgetBuilder(),
      );

  Widget _widgetBuilder() {
    if (_controller != null) {
      if (_stateOfRenderingWidget.isPlayingFailed && _thumbnailURL != null) {
        return Image.network(
          _thumbnailURL!,
          loadingBuilder: _loadingBuilder,
          errorBuilder: (context, url, error) => Center(
            child: errorWidget,
          ),
          fit: BoxFit.cover,
        );
      } else if (_stateOfRenderingWidget.isPreviewLoaded) {
        return Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            Visibility(
              visible: isMute,
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
        return loadingWidget;
      }
    } else {
      return const SizedBox();
    }
  }

  @override
  void didPopNext() {
    _playAfterInitialized = true;
    unawaited(_controller?.play());
  }

  @override
  Future<void> dispose() async {
    final position = await _controller?.position;
    onDispose?.call(time: position?.inSeconds ?? 0);
    unawaited(_controller?.dispose());
    _controller = null;
  }

  @override
  Future<bool> clearPrevious() async {
    _playAfterInitialized = false;
    await _controller?.pause();
    return true;
  }
}

class StateOfRenderingWidget with ChangeNotifier {
  bool isPreviewLoaded = false;
  bool isPlayingFailed = false;

  void previewLoaded() {
    isPreviewLoaded = true;
    isPlayingFailed = false;
    notifyListeners();
  }

  void playingFailed() {
    isPreviewLoaded = false;
    isPlayingFailed = true;
    notifyListeners();
  }
}

/// Webview rendering widget type
class WebviewNFTRenderingWidget extends INFTRenderingWidget {
  WebviewNFTRenderingWidget({
    super.renderingWidgetBuilder,
  });

  ValueNotifier<bool> isPausing = ValueNotifier(false);

  WebViewController? _webViewController;
  TextEditingController? _textController;
  final backgroundColor = Colors.black;
  final _stateOfRenderingWidget = StateOfRenderingWidget();
  late Key key;

  @override
  void setRenderWidgetBuilder(RenderingWidgetBuilder renderingWidgetBuilder) {
    super.setRenderWidgetBuilder(renderingWidgetBuilder);
    _textController = TextEditingController();
  }

  Future<void> onPause() async {
    await _webViewController?.evaluateJavascript(
        source: "var video = document.getElementsByTagName('video')[0]; "
            'if(video != undefined) { video.pause(); } '
            "var audio = document.getElementsByTagName('audio')[0]; "
            'if(audio != undefined) { audio.pause(); }');
  }

  Future<void> onResume() async {
    await _webViewController?.evaluateJavascript(
        source: "var video = document.getElementsByTagName('video')[0]; "
            'if(video != undefined) { video.play(); } '
            "var audio = document.getElementsByTagName('audio')[0]; "
            'if(audio != undefined) { audio.play(); }');
  }

  @override
  Future<void> pauseOrResume() async {
    if (isPausing.value) {
      await onResume();
    } else {
      await onPause();
    }
    isPausing.value = !isPausing.value;
  }

  @override
  Future<void> pause() async {
    if (isPausing.value) {
      await onResume();
      isPausing.value = false;
    }
  }

  @override
  Future<void> resume() async {
    if (!isPausing.value) {
      await onPause();
      isPausing.value = true;
    }
  }

  @override
  Future<void> mute() async {
    await _webViewController?.evaluateJavascript(
        source: "var video = document.getElementsByTagName('video')[0]; "
            'if(video != undefined) { video.muted = true; } '
            "var audio = document.getElementsByTagName('audio')[0]; "
            'if(audio != undefined) { audio.muted = true; }');
  }

  @override
  Future<void> unmute() async {
    await _webViewController?.evaluateJavascript(
        source: "var video = document.getElementsByTagName('video')[0]; "
            'if(video != undefined) { video.muted = false; } '
            "var audio = document.getElementsByTagName('audio')[0]; "
            'if(audio != undefined) { audio.muted = false; }');
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _stateOfRenderingWidget,
        builder: (context, child) =>
            previewURL.isEmpty ? noPreviewUrlWidget : _widgetBuilder(),
      );

  Widget _widgetBuilder() => Stack(
        children: [
          Visibility(
            visible: focusNode != null,
            child: TextFormField(
              controller: _textController,
              focusNode: focusNode,
              onChanged: (value) async {
                await _webViewController?.evaluateJavascript(
                  source: '''
                        window.dispatchEvent(new KeyboardEvent('keydown', 
                            {'key': '${value.characters.last}',
                            'keyCode': ${keysCode[value.characters.last]},
                            'which': ${keysCode[value.characters.last]}}));
                        window.dispatchEvent(new KeyboardEvent('keypress', 
                            {'key': '${value.characters.last}',
                            'keyCode': ${keysCode[value.characters.last]},
                            'which': ${keysCode[value.characters.last]}}));
                            
                        window.dispatchEvent(new KeyboardEvent('keyup', 
                        {'key': '${value.characters.last}',
                        'keyCode': ${keysCode[value.characters.last]},
                        'which': ${keysCode[value.characters.last]}}));''',
                );
                _textController?.text = '';
              },
            ),
          ),
          FeralFileWebview(
            key: Key(previewURL),
            uri: Uri.parse(overriddenHtml != null ? 'about:blank' : previewURL),
            overriddenHtml: overriddenHtml,
            backgroundColor: backgroundColor,
            onStarted: (WebViewController controller) {
              _webViewController = controller;
              if (overriddenHtml != null) {
                final uri = Uri.dataFromString(overriddenHtml!,
                    mimeType: 'text/html',
                    encoding: Encoding.getByName('utf-8'));
                unawaited(
                  _webViewController?.loadRequest(uri),
                );
              }
            },
            onLoaded: (controller) async {
              _stateOfRenderingWidget.previewLoaded();
              onLoaded?.call(webViewController: _webViewController);
              String viewportContent =
                  Platform.isIOS ? 'width=device-width, initial-scale=1.0' : '';
              String javascriptString = '''
            var viewportmeta = document.querySelector('meta[name="viewport"]');
            if (!viewportmeta) {
              var head = document.getElementsByTagName('head')[0];
              var viewport = document.createElement('meta');
              viewport.setAttribute('name', 'viewport');
              viewport.setAttribute('content', '$viewportContent');
              head.appendChild(viewport);
            }
            ''';
              await _webViewController?.evaluateJavascript(
                  source: javascriptString);

              // check background color is set
              await _webViewController?.evaluateJavascript(
                source: '''
                      if (window.getComputedStyle(document.body).backgroundColor == 'rgba(0, 0, 0, 0)') {
                  document.body.style.backgroundColor = 
                  'rgba(
                      ${backgroundColor.red}, 
                      ${backgroundColor.green}, 
                      ${backgroundColor.blue}, 
                      1,
                  )';
                }
                ''',
              );

              if (!skipViewport) {
                await _webViewController?.evaluateJavascript(
                    source: '''document.body.style.overflow = 'hidden';''');
              }

              if (isMute) {
                await mute();
              }
            },
          ),
          if (!_stateOfRenderingWidget.isPreviewLoaded) ...[
            loadingWidget,
          ],
        ],
      );

  @override
  void didPopNext() {
    unawaited(
      _webViewController?.evaluateJavascript(
        source: '''
            var video = document.getElementsByTagName('video')[0]; 
            if(video != undefined) { video.play(); } 
            var audio = document.getElementsByTagName('audio')[0]; 
            if(audio != undefined) { audio.play(); }
            ''',
      ),
    );
  }

  @override
  void dispose() {
    _textController?.dispose();
    _webViewController = null;
  }

  @override
  Future<bool> clearPrevious() async {
    await _webViewController?.evaluateJavascript(
      source: '''
            var video = document.getElementsByTagName('video')[0]; 
            if(video != undefined) { video.pause(); } 
            var audio = document.getElementsByTagName('audio')[0]; 
            if(audio != undefined) { audio.pause(); }
            ''',
    );
    return true;
  }

  void updateWebviewSize() {
    if (_webViewController != null) {
      EasyDebounce.debounce(
        'screen_rotate', // <-- An ID for this particular debouncer
        const Duration(milliseconds: 100), // <-- The debounce duration
        () => unawaited(
          _webViewController?.evaluateJavascript(
              source: "window.dispatchEvent(new Event('resize'));"),
        ),
      );
    }
  }
}

/// PDF rendering widget type
class PDFNFTRenderingWidget extends INFTRenderingWidget {
  PDFNFTRenderingWidget({
    super.renderingWidgetBuilder,
  });

  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();

  @override
  Widget build(BuildContext context) =>
      previewURL.isEmpty ? noPreviewUrlWidget : _widgetBuilder();

  final _isReady = ValueNotifier(true);
  final _error = ValueNotifier<dynamic>(null);

  Widget _widgetBuilder() => Stack(children: [
        FutureBuilder(
            future: _createFileOfPdfUrl(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final file = snapshot.data!;
                return PDFView(
                  key: Key(previewURL),
                  filePath: file.path,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                    ),
                  },
                  pageFling: false,
                  // if set to true the link is handled in flutter
                  onRender: (_) {
                    _isReady.value = true;
                  },
                  onError: (error) {
                    _error.value = error;
                  },
                  onPageError: (page, error) {
                    _error.value = error;
                  },
                  onViewCreated: (PDFViewController pdfViewController) {
                    _controller.complete(pdfViewController);
                  },
                  onLinkHandler: (String? uri) {},
                  onPageChanged: (int? page, int? total) {},
                );
              } else {
                return const SizedBox();
              }
            }),
        ValueListenableBuilder<dynamic>(
          valueListenable: _error,
          builder: (context, error, child) => Visibility(
            visible: error != null,
            child: Container(
              color: Colors.black,
              child: errorWidget,
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isReady,
          builder: (context, isReady, child) => Visibility(
            visible: !isReady,
            child: Container(
              color: Colors.black,
              child: loadingWidget,
            ),
          ),
        ),
      ]);

  Future<File> _createFileOfPdfUrl() async {
    Completer<File> completer = Completer();
    try {
      final url = previewURL;
      final filename = url.substring(url.lastIndexOf('/') + 1);
      var request = await HttpClient().getUrl(Uri.parse(url));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      var dir = await getApplicationDocumentsDirectory();
      File file = File('${dir.path}/$filename');

      await file.writeAsBytes(bytes, flush: true);
      completer.complete(file);
    } catch (e) {
      _error.value = e.toString();
    }

    return completer.future;
  }

  @override
  Future<bool> clearPrevious() => Future.value(true);

  @override
  void didPopNext() {}

  @override
  void dispose() {}
}

/// Model viewer widget type
class ModelViewerRenderingWidget extends INFTRenderingWidget {
  ModelViewerRenderingWidget({
    super.renderingWidgetBuilder,
  });

  @override
  Widget build(BuildContext context) =>
      previewURL.isEmpty ? noPreviewUrlWidget : _widgetBuilder();

  Widget _widgetBuilder() => Stack(
        children: [
          ModelViewer(
            key: Key(previewURL),
            src: previewURL,
            ar: true,
            autoRotate: true,
          ),
        ],
      );

  @override
  Future<bool> clearPrevious() => Future.value(true);

  @override
  void didPopNext() {}

  @override
  void dispose() {}
}

class NoPreviewUrlWidget extends StatelessWidget {
  const NoPreviewUrlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Center(
          child: ClipPath(
            clipper: RectangleClipper(),
            child: Container(
              padding: const EdgeInsets.all(15),
              height: size.width,
              width: size.width,
              color: Colors.white,
            ),
          ),
        ),
        Center(
          child: ClipPath(
            clipper: RectangleClipper(),
            child: Container(
              padding: const EdgeInsets.all(15),
              height: size.width - 2,
              width: size.width - 2,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class RectangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 14;

    Path path = Path()
      ..lineTo(0, 0)
      ..lineTo(size.width - radius, 0)
      ..lineTo(size.width, radius)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
