import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/asset.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArtworkPreviewPage extends StatefulWidget {
  static const tag = "artwork_preview";

  final Asset asset;

  const ArtworkPreviewPage({Key? key, required this.asset}) : super(key: key);

  @override
  State<ArtworkPreviewPage> createState() => _ArtworkPreviewPageState();
}

class _ArtworkPreviewPageState extends State<ArtworkPreviewPage> {
  VideoPlayerController? _controller;
  bool isFullscreen = false;

  @override
  void initState() {
    super.initState();

    final artwork = widget.asset.projectMetadata.latest;
    if (artwork.medium == "video") {
      _controller = VideoPlayerController.network(artwork.previewUrl)
        ..initialize().then((_) {
          _controller?.play();
          _controller?.setLooping(true);
          setState(() {});
        });
    }

    ShakeDetector detector = ShakeDetector.autoStart(onPhoneShake: () {
      setState(() {
        isFullscreen = false;
      });
    });

    detector.startListening();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
          padding: MediaQuery.of(context).padding,
          child: Column(
            children: [
              !isFullscreen ? Container(
                color: Colors.black,
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
                            widget.asset.projectMetadata.latest.title,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                fontFamily: "AtlasGrotesk"),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            "by ${widget.asset.projectMetadata.latest.artistName}",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                                fontSize: 12,
                                fontFamily: "AtlasGrotesk"),
                          )
                        ],
                      ),
                    ),
                    // IconButton(
                    //   onPressed: () {
                    //   },
                    //   icon: Icon(
                    //     CupertinoIcons.back,
                    //     color: Colors.white,
                    //   ),
                    // ),
                    // IconButton(
                    //   onPressed: () {
                    //   },
                    //   icon: Icon(
                    //     CupertinoIcons.forward,
                    //     color: Colors.white,
                    //   ),
                    // ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isFullscreen = true;
                        });

                        if (injector<ConfigurationService>().isFullscreenIntroEnabled()) {
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
              ) : SizedBox(),
              Expanded(
                child: Container(
                  child: _getArtworkView(),
                ),
              ),
            ],
          )),
    );
  }

  Widget _getArtworkView() {
    switch (widget.asset.projectMetadata.latest.medium) {
      case "image":
        return Image.network(widget.asset.projectMetadata.latest.previewUrl);
      case "video":
        return _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : SizedBox();
      default:
        return WebView(
            initialUrl: widget.asset.projectMetadata.latest.previewUrl,
            javascriptMode: JavascriptMode.unrestricted);
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
                  injector<ConfigurationService>().setFullscreenIntroEnable(false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
