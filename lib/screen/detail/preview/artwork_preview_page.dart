//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shake/shake.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ArtworkPreviewPage extends StatefulWidget {
  final ArtworkDetailPayload payload;

  const ArtworkPreviewPage({required this.payload, super.key});

  @override
  State<ArtworkPreviewPage> createState() => _ArtworkPreviewPageState();
}

class _ArtworkPreviewPageState extends State<ArtworkPreviewPage>
    with
        AfterLayoutMixin<ArtworkPreviewPage>,
        RouteAware,
        WidgetsBindingObserver {
  late PageController controller;
  late ArtworkPreviewBloc _bloc;

  ShakeDetector? _detector;
  final _focusNode = FocusNode();

  INFTRenderingWidget? _renderingWidget;

  List<ArtworkIdentity> _tokens = [];
  late int initialPage;

  final metricClient = injector.get<MetricClientService>();

  @override
  void initState() {
    super.initState();
    _tokens = List.from(widget.payload.identities);
    final initialTokenID = _tokens[widget.payload.currentIndex];
    initialPage = _tokens.indexOf(initialTokenID);

    controller = PageController(initialPage: initialPage);
    _bloc = context.read<ArtworkPreviewBloc>();
    final currentIdentity = _tokens[initialPage];
    _bloc.add(ArtworkPreviewGetAssetTokenEvent(currentIdentity,
        useIndexer: widget.payload.useIndexer));
    unawaited(_setFullScreen());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    unawaited(disableLandscapeMode());
    unawaited(WakelockPlus.disable());
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _detector?.stopListening();
    if (Platform.isAndroid) {
      unawaited(SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      ));
    }
    unawaited(Sentry.getSpan()?.finish(status: const SpanStatus.ok()));
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    unawaited(enableLandscapeMode());
    unawaited(WakelockPlus.enable());
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    unawaited(enableLandscapeMode());
    unawaited(WakelockPlus.enable());
    _renderingWidget?.didPopNext();
    super.didPopNext();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    unawaited(_openSnackBar(context));
    // Calling the same function "after layout" to resolve the issue.
    _detector = ShakeDetector.autoStart(
      onPhoneShake: () async {
        Navigator.of(context).pop();
      },
    );

    _detector?.startListening();

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _setFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _openSnackBar(BuildContext context) async {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColor.feralFileHighlight.withOpacity(0.9),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ArtworkPreviewBloc, ArtworkPreviewState>(
        builder: (context, states) => PopScope(
              onPopInvoked: (_) async {
                await SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.manual,
                  overlays: SystemUiOverlay.values,
                );
              },
              child: Scaffold(
                backgroundColor: theme.colorScheme.primary,
                body: SafeArea(
                  top: false,
                  bottom: false,
                  left: false,
                  right: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (value) {
                            final currentId = _tokens[value];
                            _bloc.add(ArtworkPreviewGetAssetTokenEvent(
                                currentId,
                                useIndexer: widget.payload.useIndexer));
                          },
                          controller: controller,
                          itemCount: _tokens.length,
                          itemBuilder: (context, index) {
                            if (_tokens[index].id.isPostcardId) {
                              return PostcardPreviewWidget(
                                identity: _tokens[index],
                                useIndexer: widget.payload.useIndexer,
                              );
                            }
                            return ArtworkPreviewWidget(
                              identity: _tokens[index],
                              onLoaded: (
                                  {InAppWebViewController? webViewController,
                                  int? time}) {},
                              focusNode: _focusNode,
                              useIndexer: widget.payload.useIndexer,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        listener: (context, state) {},
        listenWhen: (previous, current) {
          if (current is ArtworkPreviewLoadedState &&
              previous is ArtworkPreviewLoadingState) {
            if (current.assetToken != null) {
              unawaited(current.assetToken?.sendViewArtworkEvent());
            }
          }
          return true;
        });
  }
}
