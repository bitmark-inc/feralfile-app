//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:http/http.dart' as http;
import 'package:autonomy_flutter/nft_collection/data/api/indexer_api.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/dao.dart';
import 'package:autonomy_flutter/nft_collection/graphql/model/get_list_tokens.dart';
import 'package:autonomy_flutter/nft_collection/services/indexer_service.dart';
import 'package:sentry/sentry.dart';

class ArtworkDetailBloc extends AuBloc<ArtworkDetailEvent, ArtworkDetailState> {
  ArtworkDetailBloc(
    this._assetTokenDao,
    this._assetDao,
    this._provenanceDao,
    this._indexerService,
    this._tokenDao,
    this._indexerApi,
  ) : super(ArtworkDetailState(provenances: [])) {
    on<ArtworkDetailGetInfoEvent>((event, emit) async {
      final tokens = await _tokenDao.findTokensByID(event.identity.id);
      final owners = <String, int>{};
      for (final token in tokens) {
        if (token.balance != null && token.balance! > 0) {
          owners[token.owner] = token.balance!;
        }
      }
      if (event.useIndexer) {
        final request = QueryListTokensRequest(
          ids: [event.identity.id],
        );
        final assetToken = await _indexerService.getNftTokens(request);

        if (assetToken.isNotEmpty) {
          final token = assetToken.first;
          emit(
            ArtworkDetailState(
              assetToken: token,
              provenances: token.provenance,
              owners: owners,
            ),
          );
          if (event.withArtwork && token.isFeralfile) {
            final artwork =
                await injector<FeralFileService>().getArtwork(token.tokenId!);
            final exhibition = await injector<FeralFileService>()
                .getExhibitionFromTokenID(token.tokenId!);
            emit(
              ArtworkDetailState(
                assetToken: token,
                provenances: token.provenance,
                owners: owners,
                artwork: artwork,
                exhibition: exhibition,
              ),
            );
          }
        }
        return;
      } else {
        final assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
          event.identity.id,
          event.identity.owner,
        );
        final provenances =
            await _provenanceDao.findProvenanceByTokenID(event.identity.id);
        emit(
          ArtworkDetailState(
            assetToken: assetToken,
            provenances: provenances,
            owners: owners,
          ),
        );
        if (assetToken != null &&
            assetToken.asset != null &&
            (assetToken.mimeType?.isEmpty ?? true)) {
          final uri = Uri.tryParse(assetToken.previewURL ?? '');
          if (uri != null) {
            try {
              final res = await http
                  .head(uri)
                  .timeout(const Duration(milliseconds: 10000));
              assetToken.asset!.mimeType = res.headers['content-type'];
              unawaited(_assetDao.updateAsset(assetToken.asset!));
              emit(
                ArtworkDetailState(
                  assetToken: assetToken,
                  provenances: provenances,
                  owners: owners,
                ),
              );
            } catch (error) {
              log.info('ArtworkDetailGetInfoEvent: preview url error', error);
            }
          }
        }
        await _indexHistory(event.identity.id);
        if (event.withArtwork && assetToken != null && assetToken.isFeralfile) {
          final artwork = await injector<FeralFileService>()
              .getArtwork(assetToken.tokenId!);
          final exhibition = await injector<FeralFileService>()
              .getExhibitionFromTokenID(assetToken.tokenId!);
          emit(
            ArtworkDetailState(
              assetToken: assetToken,
              provenances: provenances,
              owners: owners,
              artwork: artwork,
              exhibition: exhibition,
            ),
          );
        }
      }
    });
  }

  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  final ProvenanceDao _provenanceDao;
  final IndexerService _indexerService;
  final TokenDao _tokenDao;
  final IndexerApi _indexerApi;

  Future<void> _indexHistory(String tokenId) async {
    try {
      await _indexerApi.indexTokenHistory({'indexID': tokenId});
    } catch (e) {
      log.info('index history error: $e');
      unawaited(
        Sentry.captureException(
          '[ArtworkDetailBloc] index history error: $e',
        ),
      );
    }
  }
}
