//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';

abstract class FeralFileService {
  Future<FFSeries> getAirdropSeriesFromExhibitionId(String id);

  Future<FFSeries> getSeries(String id);

  Future<ClaimResponse?> claimToken({
    required String seriesId,
    String? address,
    Otp? otp,
    Future<bool> Function(FFSeries)? onConfirm,
  });

  Future<Exhibition?> getExhibitionFromTokenID(String artworkID);

  Future<FeralFileResaleInfo> getResaleInfo(String exhibitionID);

  Future<String?> getPartnerFullName(String exhibitionId);

  Future<Exhibition> getExhibition(String id);
}

class FeralFileServiceImpl extends FeralFileService {
  final FeralFileApi _feralFileApi;
  final AccountService _accountService;

  FeralFileServiceImpl(
    this._feralFileApi,
    this._accountService,
  );

  @override
  Future<FFSeries> getAirdropSeriesFromExhibitionId(String id) async {
    final resp = await _feralFileApi.getExhibition(id);
    final exhibition = resp.result;
    final airdropSeriesId = exhibition.series
        ?.firstWhereOrNull((e) => e.settings?.isAirdrop == true)
        ?.id;
    if (airdropSeriesId != null) {
      final airdropSeries = await _feralFileApi.getSeries(airdropSeriesId);
      return airdropSeries.result;
    } else {
      throw Exception("Not airdrop exhibition");
    }
  }

  @override
  Future<FFSeries> getSeries(String id) async {
    return (await _feralFileApi.getSeries(id)).result;
  }

  @override
  Future<ClaimResponse?> claimToken(
      {required String seriesId,
      String? address,
      Otp? otp,
      Future<bool> Function(FFSeries)? onConfirm}) async {
    log.info("[FeralFileService] Claim token - series: $seriesId");
    final series = await getSeries(seriesId);

    if (series.airdropInfo == null ||
        series.airdropInfo?.endedAt?.isBefore(DateTime.now()) == true) {
      throw AirdropExpired();
    }

    if ((series.airdropInfo?.remainAmount ?? 0) > 0) {
      final accepted = await onConfirm?.call(series) ?? true;
      if (!accepted) {
        log.info("[FeralFileService] User refused claim token");
        return null;
      }
      final wallet = await _accountService.getDefaultAccount();
      final message =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final accountDID = await wallet.getAccountDID();
      final signature = await wallet.getAccountDIDSignature(message);
      final receiver = address ?? await wallet.getTezosAddress();
      Map<String, dynamic> body = {
        "claimer": accountDID,
        "timestamp": message,
        "signature": signature,
        "address": receiver,
        if (otp != null) ...{"airdropTOTPPasscode": otp.code}
      };
      final response = await _feralFileApi.claimSeries(series.id, body);
      final indexer = injector<TokensService>();
      await indexer.reindexAddresses([receiver]);

      final indexerId =
          series.airdropInfo!.getTokenIndexerId(response.result.artworkID);
      List<AssetToken> assetTokens = await _fetchTokens(
        indexerId: indexerId,
        receiver: receiver,
      );
      if (assetTokens.isNotEmpty) {
        await indexer.setCustomTokens(assetTokens);
      } else {
        assetTokens = [
          createPendingAssetToken(
            series: series,
            owner: receiver,
            tokenId: response.result.artworkID,
          )
        ];
        await indexer.setCustomTokens(assetTokens);
      }
      return ClaimResponse(
          token: assetTokens.first, airdropInfo: series.airdropInfo!);
    } else {
      throw NoRemainingToken();
    }
  }

  @override
  Future<Exhibition> getExhibition(String id) async {
    final resp = await _feralFileApi.getExhibition(id);
    return resp.result;
  }

  Future<List<AssetToken>> _fetchTokens({
    required String indexerId,
    required String receiver,
  }) async {
    try {
      final indexerService = injector<IndexerService>();
      final List<AssetToken> assets = await indexerService
          .getNftTokens(QueryListTokensRequest(ids: [indexerId]));
      final tokens = assets
          .map((e) => e
            ..pending = true
            ..owner = receiver
            ..balance = 1
            ..owners.putIfAbsent(receiver, () => 1)
            ..lastActivityTime = DateTime.now())
          .toList();
      return tokens;
    } catch (e) {
      log.info("[FeralFileService] Fetch token failed ($indexerId) $e");
      return [];
    }
  }

  @override
  Future<FeralFileResaleInfo> getResaleInfo(String exhibitionID) async {
    final resaleInfo = await _feralFileApi.getResaleInfo(exhibitionID);
    return resaleInfo.result;
  }

  @override
  Future<String?> getPartnerFullName(String exhibitionId) async {
    final exhibition = await _feralFileApi.getExhibition(exhibitionId);
    return exhibition.result.partner?.fullName;
  }

  @override
  Future<Exhibition?> getExhibitionFromTokenID(String artworkID) async {
    final artwork = await _feralFileApi.getArtworks(artworkID);
    return artwork.result.series?.exhibition;
  }
}
