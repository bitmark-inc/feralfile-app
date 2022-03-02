import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shake/shake.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArtworkPreviewPage extends StatefulWidget {
  static const tag = "artwork_preview";

  final ArtworkDetailPayload payload;

  const ArtworkPreviewPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<ArtworkPreviewPage> createState() => _ArtworkPreviewPageState();
}

class _ArtworkPreviewPageState extends State<ArtworkPreviewPage> {
  VideoPlayerController? _controller;
  bool isFullscreen = false;
  late int currentIndex;
  WebViewController? _webViewController;

  ShakeDetector? _detector;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.payload.currentIndex;
    final id = widget.payload.ids[currentIndex];

    context
        .read<ArtworkPreviewBloc>()
        .add(ArtworkPreviewGetAssetTokenEvent(id));

    _detector = ShakeDetector.autoStart(onPhoneShake: () {
      if (isFullscreen) {
        setState(() {
          isFullscreen = false;
        });
      }
    });

    _detector?.startListening();
  }

  @override
  void dispose() async {
    _controller?.dispose();
    _controller = null;
    _webViewController = null;
    _detector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ArtworkPreviewBloc, ArtworkPreviewState>(
          builder: (context, state) {
        if (state.asset != null) {
          final asset = state.asset!;

          if (asset.medium == "video" && loadedPath != asset.previewURL) {
            _startPlay(asset.previewURL!);
          }

          return Container(
              padding: MediaQuery.of(context)
                  .padding
                  .copyWith(bottom: 0, top: isFullscreen ? 0 : null),
              child: Column(
                children: [
                  !isFullscreen
                      ? Container(
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      asset.title,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          fontFamily: "AtlasGrotesk"),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      "by ${asset.artistName}",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w300,
                                          fontSize: 12,
                                          fontFamily: "AtlasGrotesk"),
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  currentIndex = currentIndex <= 0
                                      ? widget.payload.ids.length - 1
                                      : currentIndex - 1;
                                  final id = widget.payload.ids[currentIndex];
                                  context.read<ArtworkPreviewBloc>().add(
                                      ArtworkPreviewGetAssetTokenEvent(id));
                                },
                                icon: Icon(
                                  CupertinoIcons.back,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  currentIndex = currentIndex >=
                                          widget.payload.ids.length - 1
                                      ? 0
                                      : currentIndex + 1;
                                  final id = widget.payload.ids[currentIndex];
                                  context.read<ArtworkPreviewBloc>().add(
                                      ArtworkPreviewGetAssetTokenEvent(id));
                                },
                                icon: Icon(
                                  CupertinoIcons.forward,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    isFullscreen = true;
                                  });

                                  if (injector<ConfigurationService>()
                                      .isFullscreenIntroEnabled()) {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return _fullscreenIntroPopup();
                                      },
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(),
                  Expanded(
                    child: Center(
                      child: _getArtworkView(asset),
                    ),
                  ),
                ],
              ));
        } else {
          return SizedBox();
        }
      }),
    );
  }

  Widget _getArtworkView(AssetToken asset) {
    switch (asset.medium) {
      case "image":
        return Image.network(asset.previewURL!);
      case "video":
        if (_controller != null) {
          return AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          );
        } else {
          return SizedBox();
        }
      default:
        return WebView(
            key: UniqueKey(),
            initialUrl: asset.previewURL,
            onWebViewCreated: (WebViewController webViewController) {
              _webViewController = webViewController;
            },
            onPageFinished: (some) async {
              final javascriptString = '''
                var meta = document.createElement('meta');
                            meta.setAttribute('name', 'viewport');
                            meta.setAttribute('content', 'width=device-width');
                            document.getElementsByTagName('head')[0].appendChild(meta);
                ''';
              await _webViewController?.runJavascript(javascriptString);
            },
            javascriptMode: JavascriptMode.unrestricted,
            backgroundColor: Colors.black);
    }
  }

  Widget _fullscreenIntroPopup() {
    return Container(
      height: 300,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Full screen",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  fontFamily: "AtlasGrotesk"),
            ),
            SizedBox(height: 40.0),
            Text(
              "Shake your phone to exit fullscreen mode.",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  fontFamily: "AtlasGrotesk"),
            ),
            SizedBox(height: 40.0),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "OK",
                    color: Colors.white,
                    textStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: "IBMPlexMono"),
                    onPress: () {
                      Navigator.of(context).pop();
                    },
                  ),
                )
              ],
            ),
            SizedBox(height: 14.0),
            Center(
              child: GestureDetector(
                child: Text(
                  "DON’T SHOW AGAIN",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      fontFamily: "IBMPlexMono"),
                ),
                onTap: () {
                  injector<ConfigurationService>()
                      .setFullscreenIntroEnable(false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? loadedPath;
  AssetToken? _loadedAsset;

  Future<bool> _clearPrevious() async {
    await _controller?.pause();
    return true;
  }

  Future<void> _initializePlay(String videoPath) async {
    _controller = VideoPlayerController.network(videoPath);
    _controller!.initialize().then((_) {
      _controller?.play();
      _controller?.setLooping(true);
      setState(() {});
    });
  }

  Future<void> _startPlay(String videoPath) async {
    loadedPath = videoPath;

    Future.delayed(const Duration(milliseconds: 200), () {
      _clearPrevious().then((_) {
        _initializePlay(videoPath);
      });
    });
  }
}
