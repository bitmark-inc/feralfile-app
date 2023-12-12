//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/gateway/merchandise_api.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/leaderboard/postcard_leaderboard.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
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
  final TokensService _tokenService;
  final MerchandiseApi _merchandiseApi;
  final RemoteConfigService _remoteConfig;

  PostcardDetailBloc(
    this._assetTokenDao,
    this._assetDao,
    this._provenanceDao,
    this._indexerService,
    this._postcardService,
    this._configurationService,
    this._tokenService,
    this._merchandiseApi,
    this._remoteConfig,
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
          final tempsPrompt = assetToken.first.stampingPostcardConfig?.prompt ??
              assetToken.first.processingStampPostcard?.prompt;
          if (tempsPrompt != null &&
              assetToken.first.postcardMetadata.prompt == null) {
            assetToken.first.setAssetPrompt(tempsPrompt);
          }
          final paths = getUpdatingPath(assetToken.first);

          emit(state.copyWith(
            assetToken: assetToken.first,
            provenances: assetToken.first.provenance,
            imagePath: paths.first,
            metadataPath: paths.second,
            showMerch: false,
            enableMerch: false,
          ));
        }
        return;
      } else {
        unawaited(_tokenService.reindexAddresses([event.identity.owner]));
        final assetToken = await _assetTokenDao.findAssetTokenByIdAndOwner(
            event.identity.id, event.identity.owner);
        if (assetToken == null) {
          log.info('ArtworkDetailGetInfoEvent: $event assetToken is null');
        }

        final tempsPrompt = assetToken?.stampingPostcardConfig?.prompt ??
            assetToken?.processingStampPostcard?.prompt;
        if (tempsPrompt != null &&
            assetToken?.postcardMetadata.prompt == null) {
          assetToken?.setAssetPrompt(tempsPrompt);
        }
        final paths = getUpdatingPath(assetToken);
        final isViewOnly = await assetToken?.isViewOnly();
        emit(
          state.copyWith(
              assetToken: assetToken,
              imagePath: paths.first,
              metadataPath: paths.second,
              isViewOnly: isViewOnly),
        );

        final showProvenances =
            _remoteConfig.getBool(ConfigGroup.viewDetail, ConfigKey.provenance);
        if (showProvenances) {
          final provenances =
              await _provenanceDao.findProvenanceByTokenID(event.identity.id);
          emit(state.copyWith(provenances: provenances));
        }

        final showMerch = !_enableMerch(assetToken) ||
            await _showMerchProduct(assetToken, isViewOnly ?? true);
        if (showMerch != state.showMerch) {
          emit(state.copyWith(
              showMerch: showMerch, enableMerch: _enableMerch(assetToken)));
        }

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
              emit(state.copyWith(assetToken: assetToken));
            } catch (error) {
              log.info('ArtworkDetailGetInfoEvent: preview url error', error);
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
        log.info('FetchLeaderboardEvent: error $e');
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
        log.info('RefreshLeaderboardEvent: error $e');
      }
    });
  }

  Pair<String?, String?> getUpdatingPath(AssetToken? asset) {
    String? imagePath;
    String? metadataPath;
    if (asset != null) {
      final stampingPostcard =
          _postcardService.getStampingPostcardWithPath(asset.stampingPostcard!);
      final processingStampPostcard = asset.processingStampPostcard;
      final isStamped = asset.isStamped;
      if (!isStamped) {
        if (stampingPostcard != null) {
          log.info('[PostcardDetail] Stamping... ');
          imagePath = stampingPostcard.imagePath;
          metadataPath = stampingPostcard.metadataPath;
        } else {
          if (processingStampPostcard != null) {
            log.info('[PostcardDetail] Processing stamp... ');
            imagePath = processingStampPostcard.imagePath;
            metadataPath = processingStampPostcard.metadataPath;
          }
        }
      } else {
        if (stampingPostcard != null) {
          unawaited(_postcardService
              .updateStampingPostcard([stampingPostcard], isRemove: true));
        }
        if (processingStampPostcard != null) {
          unawaited(_configurationService.setProcessingStampPostcard(
              [processingStampPostcard],
              isRemove: true));
        }
      }
    }
    return Pair(imagePath, metadataPath);
  }

  Future<bool> _showMerchProduct(AssetToken? asset, bool isViewOnly) async {
    if (asset == null) {
      return false;
    }
    final isShowConfig =
        _remoteConfig.getBool(ConfigGroup.merchandise, ConfigKey.enable) &&
            (_remoteConfig.getBool(
                    ConfigGroup.merchandise, ConfigKey.allowViewOnly) ||
                !isViewOnly);
    if (!isShowConfig) {
      return false;
    }
    try {
      final products = await _merchandiseApi.getProducts(asset.id);
      return products.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  bool _enableMerch(AssetToken? asset) {
    if (asset == null) {
      return false;
    }
    final isEnable = asset.isCompleted ||
        !_remoteConfig.getBool(
            ConfigGroup.merchandise, ConfigKey.mustCompleted);
    return isEnable;
  }
}
