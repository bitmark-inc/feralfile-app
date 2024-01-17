//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:http/http.dart' as http;
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/services/indexer_service.dart';

class ArtworkDetailBloc extends AuBloc<ArtworkDetailEvent, ArtworkDetailState> {
  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  final ProvenanceDao _provenanceDao;
  final IndexerService _indexerService;
  final TokenDao _tokenDao;
  final AirdropService _airdropService;
  final IndexerApi _indexerApi;

  ArtworkDetailBloc(
    this._assetTokenDao,
    this._assetDao,
    this._provenanceDao,
    this._indexerService,
    this._tokenDao,
    this._airdropService,
    this._indexerApi,
  ) : super(ArtworkDetailState(provenances: [])) {
    on<ArtworkDetailGetInfoEvent>((event, emit) async {
      final tokens = await _tokenDao.findTokensByID(event.identity.id);
      Map<String, int> owners = {};
      for (var token in tokens) {
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
          emit(ArtworkDetailState(
              assetToken: assetToken.first,
              provenances: assetToken.first.provenance,
              owners: owners));
        }
        return;
      }
      final assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
          event.identity.id, event.identity.owner);
      final provenances =
          await _provenanceDao.findProvenanceByTokenID(event.identity.id);
      emit(ArtworkDetailState(
        assetToken: assetToken,
        provenances: provenances,
        owners: owners,
      ));
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
            emit(ArtworkDetailState(
              assetToken: assetToken,
              provenances: provenances,
              owners: owners,
            ));
          } catch (error) {
            log.info('ArtworkDetailGetInfoEvent: preview url error', error);
          }
        }
      }
      if (assetToken != null && assetToken.isAirdropToken) {
        add(ArtworkDetailGetAirdropDeeplink(assetToken: state.assetToken!));
      }
      await _indexHistory(event.identity.id);
    });
    on<ArtworkDetailGetAirdropDeeplink>((event, emit) async {
      String deeplink = '';
      try {
        deeplink = await _airdropService.shareAirdrop(event.assetToken) ?? '';
      } catch (error) {
        log.info('ArtworkDetailGetAirdropDeeplink: share airdrop error',
            error.toString());
      }
      emit(state.copyWith(airdropDeeplink: deeplink));
    });
  }

  Future<void> _indexHistory(String tokenId) async {
    await _indexerApi.indexTokenHistory({'indexID': tokenId});
  }
}
