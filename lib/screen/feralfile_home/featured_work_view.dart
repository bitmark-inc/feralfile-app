import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/gallery/gallery_page.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/loading_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/tokens_service.dart';

class FeaauredWorkView extends StatefulWidget {
  final List<String> tokenIDs;

  const FeaauredWorkView({required this.tokenIDs, super.key});

  @override
  State<FeaauredWorkView> createState() => _FeaauredWorkViewState();
}

class _FeaauredWorkViewState extends State<FeaauredWorkView> {
  List<AssetToken>? _featureTokens = null;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchFeaturedTokens(context));
  }

  @override
  void didUpdateWidget(covariant FeaauredWorkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tokenIDs != widget.tokenIDs) {
      unawaited(_fetchFeaturedTokens(context));
    }
  }

  Widget _loadingView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 80),
      constraints: BoxConstraints.expand(),
      child: loadingView(context, size: 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_featureTokens == null) {
      return _loadingView(context);
    } else {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, index) {
                final token = _featureTokens![index];
                return BlocBuilder<IdentityBloc, IdentityState>(
                  builder: (context, state) {
                    final artistName = state.identityMap[token.artistName] ??
                        token.artistName ??
                        token.artistID ??
                        '';
                    return GestureDetector(
                      onTap: () {
                        _gotoArtworkDetails(context, token);
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            // Image.network(token.thumbnailURL ?? ''),
                            CachedNetworkImage(
                              imageUrl: token.thumbnailURL ?? '',
                              cacheManager: injector<CacheManager>(),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                            _infoHeader(context, token, artistName, false,
                                context.read<CanvasDeviceBloc>().state),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: _featureTokens?.length ?? 0,
            )),
          ),
          // safe height for bottom
          SliverToBoxAdapter(
            child: Container(
              height: 80,
            ),
          ),
        ],
      );
    }
  }

  Future<void> _fetchFeaturedTokens(BuildContext context) async {
    final bloc = context.read<IdentityBloc>();
    final tokens =
        await injector<TokensService>().fetchManualTokens(widget.tokenIDs);
    final addresses = <String>[];
    for (final token in tokens) {
      addresses
        ..add(token.owner)
        ..add(token.artistName ?? '');
    }
    bloc.add(GetIdentityEvent(addresses));
    setState(() {
      _featureTokens ??= [];
      _featureTokens!.clear();
      _featureTokens!.addAll(tokens);
      log.info('feature tokens: ${_featureTokens!.length}');
    });
  }

  void _gotoArtworkDetails(BuildContext context, AssetToken token) {
    unawaited(Navigator.of(context).pushNamed(
      AppRouter.artworkDetailsPage,
      arguments: ArtworkDetailPayload(
        [
          ArtworkIdentity(
            token.id,
            token.owner,
          ),
        ],
        0,
      ),
    ));
  }

  Widget _infoHeader(BuildContext context, AssetToken asset, String? artistName,
      bool isViewOnly, CanvasDeviceState canvasState) {
    var subTitle = '';
    if (artistName != null && artistName.isNotEmpty) {
      subTitle = artistName;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 5, 20),
      child: Row(
        children: [
          Expanded(
            child: ArtworkDetailsHeader(
              title: asset.displayTitle ?? '',
              onTitleTap: () => _gotoArtworkDetails(context, asset),
              subTitle: subTitle,
              onSubTitleTap: asset.artistID != null
                  ? () => unawaited(
                      Navigator.of(context).pushNamed(AppRouter.galleryPage,
                          arguments: GalleryPagePayload(
                            address: asset.artistID!,
                            artistName: artistName!,
                            artistURL: asset.artistURL,
                          )))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
