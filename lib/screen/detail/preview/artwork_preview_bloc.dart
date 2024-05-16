//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/helpers.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:nft_collection/services/indexer_service.dart';

class ArtworkPreviewBloc
    extends AuBloc<ArtworkPreviewEvent, ArtworkPreviewState> {
  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  final IndexerService _indexerService;

  ArtworkPreviewBloc(this._assetTokenDao, this._assetDao, this._indexerService)
      : super(ArtworkPreviewLoadingState()) {
    on<ArtworkPreviewGetAssetTokenEvent>((event, emit) async {
      AssetToken? assetToken;
      if (event.useIndexer) {
        final request = QueryListTokensRequest(
          ids: [event.identity.id],
        );
        final tokens = await _indexerService.getNftTokens(request);
        if (tokens.isNotEmpty) {
          assetToken = tokens.first;
        }
      } else {
        assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
            event.identity.id, event.identity.owner);
      }

      if (state is ArtworkPreviewLoadedState) {
        final currentState = state as ArtworkPreviewLoadedState;
        emit(currentState.copyWith(assetToken: assetToken));
      } else {
        emit(ArtworkPreviewLoadedState(assetToken: assetToken));
      }
      // change ipfs if the cloud_flare ipfs has not worked
      try {
        if (assetToken?.previewURL != null) {
          final response =
              await callRequest(Uri.parse(assetToken!.previewURL!));
          if (response.statusCode == 520) {
            assetToken.asset?.previewURL = assetToken.previewURL!.replaceRange(
                0, Environment.autonomyIpfsPrefix.length, DEFAULT_IPFS_PREFIX);
            if (!event.useIndexer) {
              await _assetDao.insertAsset(assetToken.asset!);
              final artistId = assetToken.asset!.artistID;
              if (artistId != null) {
                NftCollectionBloc.eventController
                    .add(AddArtistsEvent(artists: [artistId]));
              }
            }
            emit(ArtworkPreviewLoadedState(assetToken: assetToken));
          }
        }
      } catch (_) {
        // ignore this error
      }
    });
  }
}
