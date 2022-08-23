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
import 'package:autonomy_flutter/util/au_cached_manager.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
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

    final tokenIDs = tokens.map((e) => e.id).toList();
    const int cellPerRow = 3;
    const double cellSpacing = 3.0;
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        ? SvgPicture.network(asset.getGalleryThumbnailUrl()!)
                        : CachedNetworkImage(
                            imageUrl: asset.getGalleryThumbnailUrl()!,
                            fit: BoxFit.cover,
                            memCacheHeight: _cachedImageSize,
                            memCacheWidth: _cachedImageSize,
                            cacheManager: injector<AUCacheManager>(),
                            placeholder: (context, index) => Container(
                                color: const Color.fromRGBO(227, 227, 227, 1)),
                            placeholderFadeInDuration:
                                const Duration(milliseconds: 300),
                            errorWidget: (context, url, error) => Container(
                                color: const Color.fromRGBO(227, 227, 227, 1),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/images/image_error.svg',
                                    width: 75,
                                    height: 75,
                                  ),
                                )),
                          ),
                  ),
                  onTap: () {
                    final index = tokenIDs.indexOf(asset.id);
                    final payload = ArtworkDetailPayload(tokenIDs, index);
                    Navigator.of(context).pushNamed(
                        AppRouter.artworkPreviewPage,
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
