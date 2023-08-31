import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:shake/shake.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  InAppWebViewController? _controller;
  final _configurationService = injector<ConfigurationService>();

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
    super.initState();
    WakelockPlus.enable();
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

  Future _moveToInfo(AssetToken? assetToken) async {
    if (assetToken == null) return;
    WakelockPlus.disable();
    Navigator.of(context).pop();
  }

  void onClickFullScreen() {
    setState(() {
      isFullScreen = true;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final theme = Theme.of(context);

    if (injector<ConfigurationService>().isFullscreenIntroEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: theme.auSuperTeal.withOpacity(0.9),
              borderRadius: BorderRadius.circular(64),
            ),
            child: Text(
              'shake_exit'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.ppMori600Black12,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = widget.token;
    final identityBloc = context.read<IdentityBloc>();
    final version = _configurationService.getVersionInfo();
    final isShowArtistName = !token.isPostcard;
    return Scaffold(
        appBar: isFullScreen
            ? null
            : AppBar(
                systemOverlayStyle: systemUiOverlayDarkStyle,
                backgroundColor: theme.colorScheme.primary,
                leadingWidth: 0,
                centerTitle: false,
                title: GestureDetector(
                  onTap: () => _moveToInfo(token),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        token.title ?? '',
                        style: theme.textTheme.ppMori400White16,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isShowArtistName)
                        BlocBuilder<IdentityBloc, IdentityState>(
                          bloc: identityBloc
                            ..add(GetIdentityEvent([
                              token.artistName ?? '',
                            ])),
                          builder: (context, state) {
                            final artistName = token.artistName
                                ?.toIdentityOrMask(state.identityMap);
                            if (artistName != null) {
                              return Row(
                                children: [
                                  const SizedBox(height: 4.0),
                                  Expanded(
                                    child: Text(
                                      "by".tr(args: [artistName]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.ppMori400White14,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(
                      maxWidth: 44,
                      maxHeight: 44,
                    ),
                    icon: Icon(
                      AuIcon.close,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    tooltip: 'close_icon',
                  )
                ],
              ),
        backgroundColor: theme.colorScheme.primary,
        body: SafeArea(
          top: false,
          bottom: false,
          left: !isFullScreen,
          right: !isFullScreen,
          child: Column(
            children: [
              Expanded(
                child: InAppWebView(
                  initialUrlRequest:
                      URLRequest(url: Uri.tryParse(WEB3_PRIMER_URL)),
                  initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                          userAgent: "user_agent"
                              .tr(namedArgs: {"version": version}))),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadStop: (controller, uri) {
                    EasyDebounce.debounce(
                      'screen_rotate',
                      const Duration(milliseconds: 100),
                      () => _controller?.evaluateJavascript(
                          source: "window.dispatchEvent(new Event('resize'));"),
                    );
                  },
                ),
              ),
              Visibility(
                visible: !isFullScreen,
                child: Container(
                  color: theme.colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 15,
                      bottom: 30,
                      right: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => onClickFullScreen(),
                          child: Semantics(
                            label: "fullscreen_icon",
                            child: SvgPicture.asset(
                              'assets/images/fullscreen_icon.svg',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
