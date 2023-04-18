//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_bigmap.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:http/http.dart' as http;
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/services/indexer_service.dart';

abstract class PostcardDetailEvent {}

class PostcardDetailGetInfoEvent extends PostcardDetailEvent {
  final ArtworkIdentity identity;
  final bool useIndexer;

  PostcardDetailGetInfoEvent(this.identity, {this.useIndexer = false});
}

class PostcardDetailGetValueEvent extends PostcardDetailEvent {
  final String contractAddress;
  final String tokenId;

  PostcardDetailGetValueEvent({
    required this.contractAddress,
    required this.tokenId,
  });
}

class PostcardDetailBloc
    extends AuBloc<PostcardDetailEvent, PostcardDetailState> {
  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  final ProvenanceDao _provenanceDao;
  final IndexerService _indexerService;

  PostcardDetailBloc(
    this._assetTokenDao,
    this._assetDao,
    this._provenanceDao,
    this._indexerService,
  ) : super(PostcardDetailState(provenances: [])) {
    on<PostcardDetailGetInfoEvent>((event, emit) async {
      if (event.useIndexer) {
        final request = QueryListTokensRequest(
          ids: [event.identity.id],
        );
        final assetToken = await _indexerService.getNftTokens(request);
        if (assetToken.isNotEmpty) {
          final postcardValue = await getPostcardValue(
              assetToken.first.contractType, assetToken.first.tokenId ?? "");
          emit(state.copyWith(
              assetToken: assetToken.first,
              provenances: assetToken.first.provenance,
              postcardValue: postcardValue));
        }
        return;
      } else {
        final assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
            event.identity.id, event.identity.owner);
        if (assetToken != null &&
            assetToken.asset != null &&
            (assetToken.mimeType?.isEmpty ?? true)) {
          final uri = Uri.tryParse(assetToken.previewURL ?? '');
          if (uri != null) {
            try {
              final res = await http.head(uri);
              assetToken.asset!.mimeType = res.headers["content-type"];
              _assetDao.updateAsset(assetToken.asset!);
            } catch (error) {
              log.info("ArtworkDetailGetInfoEvent: preview url error", error);
            }
          }
        }
        final provenances =
            await _provenanceDao.findProvenanceByTokenID(event.identity.id);
        final postcardValue = await getPostcardValue(
            assetToken?.contractAddress ?? "", assetToken?.tokenId ?? "");
        emit(state.copyWith(
          assetToken: assetToken,
          provenances: provenances,
          postcardValue: postcardValue,
        ));
      }
    });

    on<PostcardDetailGetValueEvent>((event, emit) async {
      final postcardService = injector<PostcardService>();
      final postcardValue = await postcardService.getPostcardValue(
          contractAddress: event.contractAddress, tokenId: event.tokenId);
      emit(state.copyWith(postcardValue: postcardValue));
    });
  }

  Future<PostcardValue?> getPostcardValue(
      String contractAddress, String tokenId) async {
    final postcardService = injector<PostcardService>();
    final postcardValue = await postcardService.getPostcardValue(
        contractAddress: contractAddress, tokenId: tokenId);
    return postcardValue;
  }
}
