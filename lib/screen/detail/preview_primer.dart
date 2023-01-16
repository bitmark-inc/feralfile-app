import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';

import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_page.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';

import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nft_collection/models/asset_token.dart';
import 'package:shake/shake.dart';
import 'package:wakelock/wakelock.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PreviewPrimerPage extends StatefulWidget {
  final AssetToken token;

  const PreviewPrimerPage({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<PreviewPrimerPage> createState() => _PreviewPrimerPageState();
}

class _PreviewPrimerPageState extends State<PreviewPrimerPage>
    with AfterLayoutMixin, WidgetsBindingObserver {
  bool isFullScreen = false;
  ShakeDetector? _detector;
  WebViewController? _controller;
  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _detector?.stopListening();
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    }
  }

  @override
  void initState() {
    Wakelock.enable();
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        setState(() {
          isFullScreen = false;
        });
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      },
    );

    _detector?.startListening();

    WidgetsBinding.instance.addObserver(this);
  }

  Future _moveToInfo(AssetToken? asset) async {
    if (asset == null) return;
    Wakelock.disable();
    Navigator.of(context).pop();
  }

  void onClickFullScreen() {
    setState(() {
      isFullScreen = true;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (injector<ConfigurationService>().isFullscreenIntroEnabled()) {
      showModalBottomSheet<void>(
        context: context,
        constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.isMobile
                ? double.infinity
                : Constants.maxWidthModalTablet),
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return const FullscreenIntroPopup();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = widget.token;
    return Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: SafeArea(
          top: false,
          bottom: false,
          left: !isFullScreen,
          right: !isFullScreen,
          child: Column(
            children: [
              Visibility(
                visible: !isFullScreen,
                child: ControlView(
                  assetToken: token,
                  onClickInfo: () => _moveToInfo(token),
                  onClickFullScreen: onClickFullScreen,
                ),
              ),
              Expanded(
                child: WebView(
                  initialUrl: WEB3_PRIMER_URL,
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  javascriptMode: JavascriptMode.unrestricted,
                  onPageFinished: (url) {
                    EasyDebounce.debounce(
                      'screen_rotate',
                      const Duration(milliseconds: 100),
                      () => _controller?.runJavascript(
                          "window.dispatchEvent(new Event('resize'));"),
                    );
                  },
                ),
              )
            ],
          ),
        ));
  }
}
