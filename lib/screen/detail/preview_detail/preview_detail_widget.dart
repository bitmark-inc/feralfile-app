//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_rendering/nft_rendering.dart';

class ArtworkPreviewWidget extends StatefulWidget {
  final ArtworkIdentity identity;
  final Function({int? time})? onLoaded;
  final Function({int? time})? onDispose;
  final bool isMute;
  final FocusNode? focusNode;
  final bool useIndexer;

  const ArtworkPreviewWidget({
    Key? key,
    required this.identity,
    this.onLoaded,
    this.onDispose,
    this.isMute = false,
    this.focusNode,
    this.useIndexer = false,
  }) : super(key: key);

  @override
  State<ArtworkPreviewWidget> createState() => _ArtworkPreviewWidgetState();
}

class _ArtworkPreviewWidgetState extends State<ArtworkPreviewWidget>
    with WidgetsBindingObserver, RouteAware {
  final bloc = ArtworkPreviewDetailBloc(injector(), injector(), injector());

  INFTRenderingWidget? _renderingWidget;

  @override
  void initState() {
    bloc.add(ArtworkPreviewDetailGetAssetTokenEvent(widget.identity,
        useIndexer: widget.useIndexer));
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _renderingWidget?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    _renderingWidget?.didPopNext();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    _renderingWidget?.clearPrevious();
    super.didPushNext();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateWebviewSize();
  }

  _updateWebviewSize() {
    if (_renderingWidget != null &&
        _renderingWidget is WebviewNFTRenderingWidget) {
      (_renderingWidget as WebviewNFTRenderingWidget).updateWebviewSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArtworkPreviewDetailBloc, ArtworkPreviewDetailState>(
      bloc: bloc,
      builder: (context, state) {
        switch (state.runtimeType) {
          case ArtworkPreviewDetailLoadingState:
            return const CircularProgressIndicator();
          case ArtworkPreviewDetailLoadedState:
            final assetToken =
                (state as ArtworkPreviewDetailLoadedState).assetToken;
            if (assetToken != null) {
              return BlocProvider(
                create: (_) => RetryCubit(),
                child: BlocBuilder<RetryCubit, int>(
                  builder: (context, attempt) {
                    if (assetToken.isPostcard) {
                      return Container(
                          alignment: Alignment.center,
                          child: PostcardRatio(assetToken: assetToken));
                    }
                    if (attempt > 0) {
                      _renderingWidget?.dispose();
                      _renderingWidget = null;
                    }
                    if (_renderingWidget == null ||
                        _renderingWidget!.previewURL !=
                            assetToken.getPreviewUrl()) {
                      _renderingWidget = buildRenderingWidget(
                        context,
                        assetToken,
                        attempt: attempt > 0 ? attempt : null,
                        onLoaded: widget.onLoaded,
                        onDispose: widget.onLoaded,
                        overriddenHtml: state.overriddenHtml,
                        isMute: widget.isMute,
                        focusNode: widget.focusNode,
                      );
                    }

                    switch (assetToken.getMimeType) {
                      case RenderingType.image:
                      case RenderingType.video:
                      case RenderingType.gif:
                      case RenderingType.pdf:
                      case RenderingType.svg:
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: _artworkWithWalterMark(assetToken),
                          ),
                        );
                      default:
                        return Center(
                          child: _artworkWithWalterMark(assetToken),
                        );
                    }
                  },
                ),
              );
            }
            return const SizedBox();
          default:
            return Container();
        }
      },
    );
  }

  Widget _artworkWithWalterMark(AssetToken assetToken) {
    return Stack(
      children: [
        _renderingWidget?.build(context) ?? const SizedBox(),
        Positioned(
          bottom: 10,
          left: 10,
          right: 0,
          child: _waterMark(assetToken),
        ),
      ],
    );
  }

  Widget _waterMark(AssetToken assetToken) {
    final theme = Theme.of(context);
    final edition =
        (assetToken.editionName != null && assetToken.editionName!.isNotEmpty)
            ? "${assetToken.editionName} - "
            : "";

    return FutureBuilder<bool>(
      future: assetToken.isViewOnly(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!) {
          return Padding(
              padding: ResponsiveLayout.pageEdgeInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColor.auSuperTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 10),
                      child: Text("view_only".tr().toLowerCase(),
                          style: theme.textTheme.ppMori400Black12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColor.primaryBlack,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: AppColor.auSuperTeal, width: 2)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 10),
                      child: RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                                text: "$edition${assetToken.asset?.title}"
                                    .toUpperCase(),
                                style: theme.textTheme.ppMori600Black12
                                    .copyWith(
                                        color: AppColor.white,
                                        fontStyle: FontStyle.italic)),
                            TextSpan(
                              text: " owned by ${assetToken.owner.maskOnly(5)}",
                              style: theme.textTheme.ppMori400White12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ));
        }
        return const SizedBox();
      },
    );
  }
}

class PostcardPreviewWidget extends StatefulWidget {
  final ArtworkIdentity identity;
  final bool useIndexer;

  const PostcardPreviewWidget({
    Key? key,
    required this.identity,
    this.useIndexer = false,
  }) : super(key: key);

  @override
  State<PostcardPreviewWidget> createState() => _PostcardPreviewWidgetState();
}

class _PostcardPreviewWidgetState extends State<PostcardPreviewWidget>
    with WidgetsBindingObserver, RouteAware {
  final bloc =
      PostcardDetailBloc(injector(), injector(), injector(), injector());

  @override
  void initState() {
    bloc.add(PostcardDetailGetInfoEvent(widget.identity,
        useIndexer: widget.useIndexer));
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostcardDetailBloc, PostcardDetailState>(
        bloc: bloc,
        builder: (context, state) {
          final assetToken = state.assetToken;
          if (assetToken != null) {
            return BlocProvider(
              create: (_) => RetryCubit(),
              child: BlocBuilder<RetryCubit, int>(
                builder: (context, attempt) {
                  return Container(
                      alignment: Alignment.center,
                      child: PostcardRatio(assetToken: assetToken));
                },
              ),
            );
          }
          return const SizedBox();
        });
  }
}
