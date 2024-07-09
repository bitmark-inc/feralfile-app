//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
ort 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';

class MoMAPostcardPage extends StatefulWidget {
  const MoMAPostcardPage({super.key});

  @override
  State<MoMAPostcardPage> createState() => _MoMAPostcardPageState();
}

class _MoMAPostcardPageState extends State<MoMAPostcardPage> {
  int _cachedImageSize = 0;
  final nftBloc = injector.get<NftCollectionBloc>(param1: false);

  @override
  void initState() {
    super.initState();
  }

  List<CompactedAssetToken> _updateTokens(List<CompactedAssetToken> tokens) {
    List<CompactedAssetToken> filteredTokens = tokens.filterAssetToken();
    final nextKey = nftBloc.state.nextKey;
    if (nextKey != null &&
        !nextKey.isLoaded &&
        filteredTokens.length < COLLECTION_INITIAL_MIN_SIZE) {
      nftBloc.add(
        GetTokensByOwnerEvent(
          pageKey: nextKey,
        ),
      );
    }
    return filteredTokens;
  }

  @override
  Widget build(BuildContext context) {
    final contentWidget =
        BlocBuilder<NftCollectionBloc, NftCollectionBlocState>(
      bloc: nftBloc,
      builder: (context, state) => NftCollectionGrid(
        state: state.state,
        tokens: _updateTokens(state.tokens.items),
        loadingIndicatorBuilder: _loadingView,
        emptyGalleryViewBuilder: _emptyPostcard,
        customGalleryViewBuilder: (context, tokens) =>
            _assetsWidget(context, tokens),
      ),
    );
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        backgroundColor: AppColor.primaryBlack,
        appBar: getFFAppBar(
          context,
          onBack: () => Navigator.pop(context),
          title: Text('moma_postcard'.tr()),
        ),
        body: Column(
          children: [
            Expanded(
              child: contentWidget,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingView(BuildContext context) => Center(
          child: Column(
        children: [
          loadingIndicator(),
        ],
      ));

  Widget _emptyPostcard(BuildContext context) => Padding(
        padding: ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            addTitleSpace(),
            Text(
              'no_moma_postcard'.tr(),
              style: Theme.of(context).textTheme.ppMori400Black14,
            ),
          ],
        ),
      );

  Widget _assetsWidget(BuildContext context, List<CompactedAssetToken> tokens) {
    final accountIdentities = tokens
        .where((e) => e.pending != true || e.hasMetadata)
        .map((element) => element.identity)
        .toList();

    const int cellPerRowPhone = 3;
    const int cellPerRowTablet = 6;
    const double cellSpacing = 3;
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;
    if (_cachedImageSize == 0) {
      final estimatedCellWidth =
          MediaQuery.of(context).size.width / cellPerRow -
              cellSpacing * (cellPerRow - 1);
      _cachedImageSize = (estimatedCellWidth * 3).ceil();
    }
    List<Widget> sources;
    sources = [
      SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cellPerRow,
          crossAxisSpacing: cellSpacing,
          mainAxisSpacing: cellSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final asset = tokens[index];

            if (asset.pending == true && asset.isPostcard) {
              return MintTokenWidget(
                thumbnail: asset.galleryThumbnailURL,
                tokenId: asset.tokenId,
              );
            }

            return GestureDetector(
              child: asset.pending == true && !asset.hasMetadata
                  ? PendingTokenWidget(
                      thumbnail: asset.galleryThumbnailURL,
                      tokenId: asset.tokenId,
                      shouldRefreshCache: asset.shouldRefreshThumbnailCache,
                    )
                  : tokenGalleryThumbnailWidget(
                      context,
                      asset,
                      _cachedImageSize,
                      usingThumbnailID: index > 50,
                    ),
              onTap: () {
                if (asset.pending == true && !asset.hasMetadata) {
                  return;
                }

                final index = tokens
                    .where((e) => e.pending != true || e.hasMetadata)
                    .toList()
                    .indexOf(asset);
                final payload = asset.isPostcard
                    ? PostcardDetailPagePayload(accountIdentities, index)
                    : ArtworkDetailPayload(accountIdentities, index);

                final pageName = asset.isPostcard
                    ? AppRouter.claimedPostcardDetailsPage
                    : AppRouter.artworkDetailsPage;
                unawaited(Navigator.of(context)
                    .pushNamed(pageName, ////need change to pageName
                        arguments: payload));
              },
            );
          },
          childCount: tokens.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: sources,
      controller: ScrollController(),
    );
  }
}
