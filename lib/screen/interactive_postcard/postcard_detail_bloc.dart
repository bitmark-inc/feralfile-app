//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/postcard_bigmap.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/distance_formater.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:http/http.dart' as http;
import 'package:nft_collection/database/dao/dao.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';

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

class FetchLeaderboardEvent extends PostcardDetailEvent {}

class RefreshLeaderboardEvent extends PostcardDetailEvent {}

class PostcardDetailBloc
    extends AuBloc<PostcardDetailEvent, PostcardDetailState> {
  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  final ProvenanceDao _provenanceDao;
  final IndexerService _indexerService;
  final PostcardService _postcardService;

  PostcardDetailBloc(
    this._assetTokenDao,
    this._assetDao,
    this._provenanceDao,
    this._indexerService,
    this._postcardService,
  ) : super(PostcardDetailState(provenances: [], postcardValueLoaded: false)) {
    on<PostcardDetailGetInfoEvent>((event, emit) async {
      if (event.useIndexer) {
        final request = QueryListTokensRequest(
          owners: [event.identity.owner],
        );
        final assetToken = (await _indexerService.getNftTokens(request))
            .where((element) => element.id == event.identity.id)
            .toList();
        if (assetToken.isNotEmpty) {
          final paths = getUpdatingPath(assetToken.first);
          emit(state.copyWith(
            assetToken: assetToken.first,
            provenances: assetToken.first.provenance,
            imagePath: paths.first,
            metadataPath: paths.second,
          ));
          add(PostcardDetailGetValueEvent(
              contractAddress: assetToken.first.contractAddress ?? "",
              tokenId: assetToken.first.tokenId ?? ""));
        }
        return;
      } else {
        final tokenService = injector<TokensService>();
        await tokenService.reindexAddresses([event.identity.owner]);
        final assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
            event.identity.id, event.identity.owner);
        final paths = getUpdatingPath(assetToken);
        emit(state.copyWith(
            assetToken: assetToken,
            imagePath: paths.first,
            metadataPath: paths.second));

        final provenances =
            await _provenanceDao.findProvenanceByTokenID(event.identity.id);
        emit(state.copyWith(provenances: provenances));

        add(PostcardDetailGetValueEvent(
            contractAddress: assetToken?.contractAddress ?? "",
            tokenId: assetToken?.tokenId ?? ""));

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
              emit(state.copyWith(assetToken: assetToken));
            } catch (error) {
              log.info("ArtworkDetailGetInfoEvent: preview url error", error);
            }
          }
        }
      }
    });

    on<PostcardDetailGetValueEvent>((event, emit) async {
      final postcardValue = await _postcardService.getPostcardValue(
          contractAddress: event.contractAddress, tokenId: event.tokenId);
      emit(state.copyWith(
          postcardValue: postcardValue, postcardValueLoaded: true));
    });

    on<FetchLeaderboardEvent>((event, emit) async {
      try {
        const size = LEADERBOARD_PAGE_SIZE;
        final offset = state.leaderboard?.items.length ?? 0;
        emit(state.copyWith(isFetchingLeaderboard: true));
        final leaderboard = await _postcardService.fetchPostcardLeaderboard(
            unit: DistanceFormatter.getDistanceUnit.name,
            size: size,
            offset: offset);
        final newLeaderboard = state.leaderboard == null
            ? leaderboard
            : PostcardLeaderboard(
                items: state.leaderboard!.items
                  ..addAll(leaderboard.items
                      .where((element) =>
                          element.rank > state.leaderboard!.items.length)
                      .toList()),
                lastUpdated: DateTime.now());
        emit(state.copyWith(
            leaderboard: newLeaderboard, isFetchingLeaderboard: false));
      } catch (e) {
        log.info("FetchLeaderboardEvent: error ${e.toString()}");
      }
    });
    on<RefreshLeaderboardEvent>((event, emit) async {
      try {
        const offset = 0;
        final leaderboard = await _postcardService.fetchPostcardLeaderboard(
            unit: DistanceFormatter.getDistanceUnit.name,
            size: state.leaderboard?.items.length ?? 0,
            offset: offset);
        emit(state.copyWith(leaderboard: leaderboard));
      } catch (e) {
        log.info("RefreshLeaderboardEvent: error ${e.toString()}");
      }
    });
  }

  Future<PostcardValue?> getPostcardValue(
      String contractAddress, String tokenId) async {
    try {
      final postcardService = injector<PostcardService>();
      final postcardValue = await postcardService.getPostcardValue(
          contractAddress: contractAddress, tokenId: tokenId);
      return postcardValue;
    } catch (e) {
      return null;
    }
  }

  Pair<String?, String?> getUpdatingPath(AssetToken? asset) {
    String? imagePath;
    String? metadataPath;
    if (asset != null) {
      final postcardService = injector<PostcardService>();
      final stampingPostcard =
          postcardService.getStampingPostcardWithPath(asset.stampingPostcard!);
      if (stampingPostcard != null) {
        if (state.isLastOwner &&
            stampingPostcard.counter == asset.numberOwners) {
          final isStamped = asset.isStamped;
          if (!isStamped) {
            log.info("[PostcardDetail] Stamping... ");
            imagePath = stampingPostcard.imagePath;
            metadataPath = stampingPostcard.metadataPath;
          } else {
            postcardService
                .updateStampingPostcard([stampingPostcard], isRemove: true);
          }
        }
      }
    }
    return Pair(imagePath, metadataPath);
  }
}
