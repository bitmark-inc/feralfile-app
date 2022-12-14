//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_rendering/nft_rendering.dart';

// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import 'hidden_artworks_bloc.dart';

class HiddenArtworksPage extends StatefulWidget {
  const HiddenArtworksPage({Key? key}) : super(key: key);

  @override
  State<HiddenArtworksPage> createState() => _HiddenArtworksPageState();
}

class _HiddenArtworksPageState extends State<HiddenArtworksPage> {
  int _cachedImageSize = 0;

  @override
  void initState() {
    super.initState();

    context.read<HiddenArtworksBloc>().add(HiddenArtworksEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<HiddenArtworksBloc, List<AssetToken>>(
          builder: (context, state) {
        return Container(
          child: _assetsWidget(state),
        );
      }),
    );
  }

  Widget _assetsWidget(List<AssetToken> tokens) {
    final theme = Theme.of(context);

    final artworkIdentities =
        tokens.map((e) => ArtworkIdentity(e.id, e.ownerAddress)).toList();
    const int cellPerRowPhone = 3;
    const int cellPerRowTablet = 6;
    const double cellSpacing = 3.0;
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    if (_cachedImageSize == 0) {
      final estimatedCellWidth =
          MediaQuery.of(context).size.width / cellPerRow -
              cellSpacing * (cellPerRow - 1);
      _cachedImageSize = (estimatedCellWidth * 3).ceil();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 24, 24, 14),
            child: Text(
              "Hidden",
              style: theme.textTheme.headline1,
            ),
          ),
        ),
        SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cellPerRow,
              crossAxisSpacing: cellSpacing,
              mainAxisSpacing: cellSpacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final asset = tokens[index];
                final ext = p.extension(asset.getGalleryThumbnailUrl()!);
                return GestureDetector(
                  child: Hero(
                    tag: asset.id,
                    child: ext == ".svg"
                        ? SvgImage(
                            url: asset.getGalleryThumbnailUrl()!,
                            loadingWidgetBuilder: (_) =>
                                const GalleryThumbnailPlaceholder(),
                            errorWidgetBuilder: (_) =>
                                const GalleryThumbnailErrorWidget(),
                            unsupportWidgetBuilder: (context) =>
                                const GalleryUnSupportThumbnailWidget(),
                          )
                        : CachedNetworkImage(
                            imageUrl: asset.getGalleryThumbnailUrl()!,
                            fit: BoxFit.cover,
                            memCacheHeight: _cachedImageSize,
                            memCacheWidth: _cachedImageSize,
                            cacheManager: injector<CacheManager>(),
                            placeholder: (context, index) =>
                                const GalleryThumbnailPlaceholder(),
                            errorWidget: (context, url, error) =>
                                const GalleryThumbnailErrorWidget(),
                            placeholderFadeInDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                  ),
                  onTap: () {
                    final index = artworkIdentities.indexWhere((element) =>
                        element.id == asset.id &&
                        element.owner == asset.ownerAddress);
                    final payload =
                        ArtworkDetailPayload(artworkIdentities, index);

                    Navigator.of(context).pushNamed(
                        AppRouter.artworkDetailsPage,
                        arguments: payload);
                  },
                );
              },
              childCount: tokens.length,
            )),
        SliverToBoxAdapter(
            child: Container(
          height: 56.0,
        ))
      ],
      controller: ScrollController(),
    );
  }
}
