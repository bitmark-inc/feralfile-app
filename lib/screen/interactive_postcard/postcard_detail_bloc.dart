//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
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

class FetchLeaderboardEvent extends PostcardDetailEvent {}

class RefreshLeaderboardEvent extends PostcardDetailEvent {}

class PostcardDetailBloc
    extends AuBloc<PostcardDetailEvent, PostcardDetailState> {
  final AssetTokenDao _assetTokenDao;
  final AssetDao _assetDao;
  final ProvenanceDao _provenanceDao;
  final IndexerService _indexerService;
  final PostcardService _postcardService;
  final ConfigurationService _configurationService;

  PostcardDetailBloc(
    this._assetTokenDao,
    this._assetDao,
    this._provenanceDao,
    this._indexerService,
    this._postcardService,
    this._configurationService,
  ) : super(PostcardDetailState(provenances: [])) {
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
        }
        return;
      } else {
        final tokenService = injector<TokensService>();
        unawaited(tokenService.reindexAddresses([event.identity.owner]));
        final assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
            event.identity.id, event.identity.owner);
        if (assetToken == null) {
          log.info("ArtworkDetailGetInfoEvent: $event assetToken is null");
        }
        final paths = getUpdatingPath(assetToken);
        emit(state.copyWith(
            assetToken: assetToken,
            imagePath: paths.first,
            metadataPath: paths.second));

        final provenances =
            await _provenanceDao.findProvenanceByTokenID(event.identity.id);
        emit(state.copyWith(provenances: provenances));

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

  Pair<String?, String?> getUpdatingPath(AssetToken? asset) {
    String? imagePath;
    String? metadataPath;
    if (asset != null) {
      final postcardService = injector<PostcardService>();
      final stampingPostcard =
          postcardService.getStampingPostcardWithPath(asset.stampingPostcard!);
      final processingStampPostcard = asset.processingStampPostcard;
      final isStamped = asset.isStamped;
      if (!isStamped) {
        if (stampingPostcard != null) {
          log.info("[PostcardDetail] Stamping... ");
          imagePath = stampingPostcard.imagePath;
          metadataPath = stampingPostcard.metadataPath;
        } else {
          if (processingStampPostcard != null) {
            log.info("[PostcardDetail] Processing stamp... ");
            imagePath = processingStampPostcard.imagePath;
            metadataPath = processingStampPostcard.metadataPath;
          }
        }
      } else {
        if (stampingPostcard != null) {
          postcardService
              .updateStampingPostcard([stampingPostcard], isRemove: true);
        }
        if (processingStampPostcard != null) {
          _configurationService.setProcessingStampPostcard(
              [processingStampPostcard],
              isRemove: true);
        }
      }
    }
    return Pair(imagePath, metadataPath);
  }
}
