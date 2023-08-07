import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:shake/shake.dart';

class PreviewActivationTokenPage extends StatefulWidget {
  final AssetToken assetToken;

  const PreviewActivationTokenPage({
    Key? key,
    required this.assetToken,
  }) : super(key: key);

  @override
  State<PreviewActivationTokenPage> createState() =>
      _PreviewActivationTokenPageState();
}

class _PreviewActivationTokenPageState extends State<PreviewActivationTokenPage>
    with AfterLayoutMixin, WidgetsBindingObserver {
  bool isFullScreen = false;
  ShakeDetector? _detector;

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
    final assetToken = widget.assetToken;
    final artist = assetToken.artistName;
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
                        child: GestureDetector(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/images/iconInfo.svg",
                                colorFilter: ColorFilter.mode(
                                    theme.colorScheme.secondary,
                                    BlendMode.srcIn),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      assetToken.title ?? "",
                                      overflow: TextOverflow.ellipsis,
                                      style: ResponsiveLayout.isMobile
                                          ? theme.textTheme.atlasWhiteBold12
                                          : theme.textTheme.atlasWhiteBold14,
                                    ),
                                    Row(
                                      children: [
                                        const SizedBox(height: 4.0),
                                        Text(
                                          "by".tr(args: [artist ?? ""]).trim(),
                                          overflow: TextOverflow.ellipsis,
                                          style: theme
                                              .primaryTextTheme.headlineSmall,
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.activationTokenDetailPage,
                              arguments: assetToken,
                            );
                          },
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
                child: CachedNetworkImage(
                  imageUrl: assetToken.thumbnailURL!,
                  fit: BoxFit.contain,
                ),
              )
            ],
          ),
        ));
  }
}
