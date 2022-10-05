import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shake/shake.dart';

class PreviewTokenClaim extends StatefulWidget {
  final String? title;
  final String? artistName;
  final String? artworkThumbnail;

  const PreviewTokenClaim(
      {Key? key, this.title, this.artistName, this.artworkThumbnail})
      : super(key: key);

  @override
  State<PreviewTokenClaim> createState() => _PreviewTokenClaimState();
}

class _PreviewTokenClaimState extends State<PreviewTokenClaim>
    with AfterLayoutMixin, WidgetsBindingObserver {
  bool isFullScreen = false;
  ShakeDetector? _detector;
  @override
  void dispose() {
    // TODO: implement dispose
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
  void afterFirstLayout(BuildContext context) {
    // Calling the same function "after layout" to resolve the issue.
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

  @override
  Widget build(BuildContext context) {
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
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
                child: Container(
                  color: theme.colorScheme.primary,
                  height: safeAreaTop + 52,
                  padding: EdgeInsets.fromLTRB(15, safeAreaTop, 15, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 30),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.title ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: ResponsiveLayout.isMobile
                                        ? theme.textTheme.atlasWhiteBold12
                                        : theme.textTheme.atlasWhiteBold14,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(height: 4.0),
                                      Text(
                                        "by".tr(args: [
                                          widget.artistName ?? ''
                                        ]).trim(),
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.primaryTextTheme.headline5,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isFullScreen = true;
                          });
                        },
                        icon: Icon(
                          Icons.fullscreen,
                          color: theme.colorScheme.secondary,
                          size: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: closeIcon(color: theme.colorScheme.secondary),
                        tooltip: "CloseArtwork",
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: widget.artworkThumbnail != null
                    ? Image.network(widget.artworkThumbnail!)
                    : Container(),
              )
            ],
          ),
        ));
  }
}
