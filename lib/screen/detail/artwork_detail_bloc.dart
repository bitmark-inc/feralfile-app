//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_state.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:nft_collection/database/dao/dao.dart';
import 'package:http/http.dart' as http;
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/services/indexer_service.dart';

class ArtworkDetailBloc extends AuBloc<ArtworkDetailEvent, ArtworkDetailState> {
  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  final ProvenanceDao _provenanceDao;
  final IndexerService _indexerService;

  ArtworkDetailBloc(
    this._assetTokenDao,
    this._assetDao,
    this._provenanceDao,
    this._indexerService,
  ) : super(ArtworkDetailState(provenances: [])) {
    on<ArtworkDetailGetInfoEvent>((event, emit) async {
      if (event.useIndexer) {
        final request = QueryListTokensRequest(
          ids: [event.identity.id],
        );
        final assetToken = await _indexerService.getNftTokens(request);

        if (assetToken.isNotEmpty) {
          emit(ArtworkDetailState(
              assetToken: assetToken.first,
              provenances: assetToken.first.provenance));
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
            assetToken.asset!.mimeType = res.headers["content-type"];
            _assetDao.updateAsset(assetToken.asset!);
            emit(ArtworkDetailState(
              assetToken: assetToken,
              provenances: provenances,
            ));
          } catch (error) {
            log.info("ArtworkDetailGetInfoEvent: preview url error", error);
          }
        }
      }
    });
  }
}
