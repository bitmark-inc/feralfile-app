//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/otp.dart';
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/file_helper.dart';
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

  Future<ClaimResponse> setPendingToken(
      {required String receiver,
      required TokenClaimResponse response,
      required FFSeries series});

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

  Future<List<ExhibitionDetail>> getAllExhibitions({
    String sortBy = 'openAt',
    String sortOrder = 'DESC',
    int limit = 8,
    int offset = 0,
    bool withArtworks = false,
  });

  Future<Exhibition> getFeaturedExhibition();

  Future<List<Artwork>> getExhibitionArtworks(String exhibitionId);

  Future<List<Artwork>> getSeriesArtworks(String seriesId);

  Future<String> getFeralfileActionMessage(
      {required String address, required FeralfileAction action});

  Future<String> getFeralfileArtworkDownloadUrl({
    required String artworkId,
    required String owner,
    required String signature,
  });

  Future<Artwork> getArtwork(String artworkId);

  Future<File?> downloadFeralfileArtwork(AssetToken assetToken);
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
      throw Exception('Not airdrop exhibition');
    }
  }

  @override
  Future<FFSeries> getSeries(String id) async =>
      (await _feralFileApi.getSeries(id)).result;

  @override
  Future<ClaimResponse> setPendingToken(
      {required String receiver,
      required TokenClaimResponse response,
      required FFSeries series}) async {
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
  }

  @override
  Future<ClaimResponse?> claimToken(
      {required String seriesId,
      String? address,
      Otp? otp,
      Future<bool> Function(FFSeries)? onConfirm}) async {
    log.info('[FeralFileService] Claim token - series: $seriesId');
    final series = await getSeries(seriesId);

    if (series.airdropInfo == null ||
        series.airdropInfo?.endedAt?.isBefore(DateTime.now()) == true) {
      throw AirdropExpired();
    }

    if ((series.airdropInfo?.remainAmount ?? 0) > 0) {
      final accepted = await onConfirm?.call(series) ?? true;
      if (!accepted) {
        log.info('[FeralFileService] User refused claim token');
        return null;
      }
      final wallet = await _accountService.getDefaultAccount();
      final message =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final accountDID = await wallet.getAccountDID();
      final signature = await wallet.getAccountDIDSignature(message);
      final receiver = address ?? await wallet.getTezosAddress();
      Map<String, dynamic> body = {
        'claimer': accountDID,
        'timestamp': message,
        'signature': signature,
        'address': receiver,
        if (otp != null) ...{'airdropTOTPPasscode': otp.code}
      };
      final response = await _feralFileApi.claimSeries(series.id, body);
      final claimResponse = setPendingToken(
          receiver: receiver, response: response, series: series);
      return claimResponse;
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
      log.info('[FeralFileService] Fetch token failed ($indexerId) $e');
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

  @override
  Future<List<ExhibitionDetail>> getAllExhibitions({
    String sortBy = 'openAt',
    String sortOrder = 'DESC',
    int limit = 8,
    int offset = 0,
    bool withArtworks = false,
  }) async {
    final exhibitions = await _feralFileApi.getAllExhibitions(
        sortBy: sortBy, sortOrder: sortOrder, limit: limit, offset: offset);
    final listExhibition = exhibitions.result;
    log
      ..info('[FeralFileService] Get all exhibitions: ${listExhibition.length}')
      ..info('[FeralFileService] Get all exhibitions: '
          '${listExhibition.map((e) => e.id).toList()}');
    final listExhibitionDetail =
        listExhibition.map((e) => ExhibitionDetail(exhibition: e)).toList();
    if (withArtworks) {
      try {
        await Future.wait(listExhibitionDetail.map((e) async {
          final artworks = await getExhibitionArtworks(e.exhibition.id);
          e.artworks = artworks;
        }));
      } catch (e) {
        log.info('[FeralFileService] Get artworks failed $e');
      }
    }
    return listExhibitionDetail;
  }

  @override
  Future<Exhibition> getFeaturedExhibition() async {
    final featuredExhibition = await _feralFileApi.getFeaturedExhibition();
    return featuredExhibition.result;
  }

  @override
  Future<List<Artwork>> getExhibitionArtworks(String exhibitionId) async {
    final artworks =
        await _feralFileApi.getListArtworks(exhibitionId: exhibitionId);
    final listArtwork = artworks.result;
    log
      ..info(
        '[FeralFileService] Get exhibition artworks: ${listArtwork.length}',
      )
      ..info(
        '[FeralFileService] Get exhibition artworks: '
        '${listArtwork.map((e) => e.id).toList()}',
      );
    return listArtwork;
  }

  @override
  Future<List<Artwork>> getSeriesArtworks(String seriesId) async {
    final artworks = await _feralFileApi.getListArtworks(seriesId: seriesId);
    final listArtwork = artworks.result;
    log
      ..info(
        '[FeralFileService] Get series artworks: ${listArtwork.length}',
      )
      ..info(
        '[FeralFileService] Get series artworks: '
        '${listArtwork.map((e) => e.id).toList()}',
      );
    return listArtwork;
  }

  @override
  Future<String> getFeralfileActionMessage(
      {required String address, required FeralfileAction action}) async {
    final response = await _feralFileApi.getActionMessage({
      'address': address,
      'action': action.action,
    });
    return response.message;
  }

  @override
  Future<String> getFeralfileArtworkDownloadUrl(
      {required String artworkId,
      required String owner,
      required String signature}) async {
    final FeralFileResponse<String> response =
        await _feralFileApi.getDownloadUrl(artworkId, signature, owner);
    return response.result;
  }

  @override
  Future<Artwork> getArtwork(String artworkId) async {
    final response = await _feralFileApi.getArtworks(artworkId);
    return response.result;
  }

  @override
  Future<File?> downloadFeralfileArtwork(AssetToken assetToken) async {
    try {
      final artwork = await injector<FeralFileService>()
          .getArtwork(assetToken.tokenId ?? '');
      final message =
          await injector<FeralFileService>().getFeralfileActionMessage(
        address: assetToken.owner,
        action: FeralfileAction.downloadSeries,
      );
      final ownerAddress = assetToken.owner;
      final chain = assetToken.blockchain;
      final account = await injector<AccountService>()
          .getAccountByAddress(chain: chain, address: ownerAddress);
      final signature =
          await account.signMessage(chain: chain, message: message);
      final publicKey = await account.wallet.getTezosPublicKey();
      final signatureString = '$message|$signature|$publicKey';
      final signatureHex = base64.encode(utf8.encode(signatureString));

      final url =
          await injector<FeralFileService>().getFeralfileArtworkDownloadUrl(
        artworkId: artwork.id,
        signature: signatureHex,
        owner: ownerAddress,
      );
      final file = await FileHelper.downloadFileMultipart(url);
      return file;
    } catch (e) {
      log.info('Error downloading artwork: $e');
      rethrow;
    }
  }
}

enum FeralfileAction {
  downloadSeries;

  String get action {
    switch (this) {
      case FeralfileAction.downloadSeries:
        return 'download series';
    }
  }
}
