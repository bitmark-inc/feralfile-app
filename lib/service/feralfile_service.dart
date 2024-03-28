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
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/download_helper.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';

enum ArtworkModel {
  multi,
  single,
  multiUnique,
  ;

  String get value {
    switch (this) {
      case ArtworkModel.multi:
        return 'multi';
      case ArtworkModel.single:
        return 'single';
      case ArtworkModel.multiUnique:
        return 'multi_unique';
    }
  }

  String get title {
    switch (this) {
      case ArtworkModel.multiUnique:
        return 'series';
      case ArtworkModel.single:
        return 'single';
      case ArtworkModel.multi:
        return 'edition';
    }
  }

  String get pluralTitle {
    switch (this) {
      case ArtworkModel.multiUnique:
        return 'series';
      case ArtworkModel.single:
        return 'singles';
      case ArtworkModel.multi:
        return 'editions';
    }
  }

  static ArtworkModel? fromString(String value) {
    switch (value) {
      case 'multi':
        return ArtworkModel.multi;
      case 'single':
        return ArtworkModel.single;
      case 'multi_unique':
        return ArtworkModel.multiUnique;
      default:
        return null;
    }
  }
}

enum ExtendedArtworkModel {
  interactiveInstruction,
  ;

  String get title {
    switch (this) {
      case ExtendedArtworkModel.interactiveInstruction:
        return 'interactive instruction';
    }
  }

  String get pluralTitle {
    switch (this) {
      case ExtendedArtworkModel.interactiveInstruction:
        return 'interactive instructions';
    }
  }

  static ExtendedArtworkModel? fromTitle(String title) {
    switch (title) {
      case 'interactive instruction':
        return ExtendedArtworkModel.interactiveInstruction;
      default:
        return null;
    }
  }
}

enum GenerativeMediumTypes {
  software,
  model,
  ;

  String get value {
    switch (this) {
      case GenerativeMediumTypes.software:
        return 'software';
      case GenerativeMediumTypes.model:
        return '3d';
    }
  }
}

abstract class FeralFileService {
  Future<FFSeries> getAirdropSeriesFromExhibitionId(String id);

  Future<FFSeries> getSeries(String id);

  Future<List<FFSeries>> getListSeries(String exhibitionId);

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

  String? getCuratorFullName(String exhibitionId);

  Future<Exhibition> getExhibition(String id);

  Future<List<ExhibitionDetail>> getAllExhibitions({
    String sortBy = 'openAt',
    String sortOrder = 'DESC',
    int limit = 8,
    int offset = 0,
    bool withArtworks = false,
    bool withSeries = false,
  });

  Future<Exhibition> getFeaturedExhibition();

  Future<List<Artwork>> getExhibitionArtworks(String exhibitionId,
      {bool withSeries = false});

  Future<List<Artwork>> getSeriesArtworks(String seriesId,
      {bool withSeries = false});

  Future<String> getFeralfileActionMessage(
      {required String address, required FeralfileAction action});

  Future<String> getFeralfileArtworkDownloadUrl({
    required String artworkId,
    required String owner,
    required String signature,
  });

  Future<Artwork> getArtwork(String artworkId);

  Future<File?> downloadFeralfileArtwork(AssetToken assetToken,
      {Function(int received, int total)? onReceiveProgress});
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
      final airdropSeries = await _feralFileApi.getSeries(
        seriesId: airdropSeriesId,
      );
      return airdropSeries.result;
    } else {
      throw Exception('Not airdrop exhibition');
    }
  }

  @override
  Future<FFSeries> getSeries(String id) async =>
      (await _feralFileApi.getSeries(seriesId: id)).result;

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
  String? getCuratorFullName(String exhibitionId) {
    if (exhibitionId == SOUND_MACHINES_EXHIBITION_ID) {
      return 'MoMA';
    }
    return null;
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
    bool withSeries = false,
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
          final artworks =
              await getExhibitionArtworks(e.exhibition.id, withSeries: true);
          e.artworks = artworks;
        }));
      } catch (e) {
        log.info('[FeralFileService] Get artworks failed $e');
      }
    }
    if (withSeries) {
      try {
        await Future.wait(listExhibitionDetail.mapIndexed((index, e) async {
          final series = await getListSeries(e.exhibition.id);
          listExhibitionDetail[index] =
              e.copyWith(exhibition: e.exhibition.copyWith(series: series));
        }));
      } catch (e) {
        log.info('[FeralFileService] Get series failed $e');
      }
    }
    return listExhibitionDetail;
  }

  @override
  Future<Exhibition> getFeaturedExhibition() async {
    final featuredExhibition = await _feralFileApi.getFeaturedExhibition();
    return featuredExhibition.result;
  }

  Future<List<Artwork>> _getExhibitionArtworkByDirectApi(String exhibitionId,
      {bool withSeries = false}) async {
    final artworks =
        await _feralFileApi.getListArtworks(exhibitionId: exhibitionId);
    List<Artwork> listArtwork = artworks.result;
    log
      ..info(
        '[FeralFileService] [_getExhibitionByDirectApi] '
        'Get exhibition artworks: ${listArtwork.length}',
      )
      ..info(
        '[FeralFileService] [_getExhibitionByDirectApi] '
        'Get exhibition artworks: '
        '${listArtwork.map((e) => e.id).toList()}',
      );
    if (withSeries) {
      final listSeries = await getListSeries(exhibitionId);
      final seriesMap =
          Map.fromEntries(listSeries.map((e) => MapEntry(e.id, e)));
      listArtwork = listArtwork
          .map((e) => e.copyWith(series: seriesMap[e.seriesID]))
          .toList();
    }
    return listArtwork;
  }

  Future<List<Artwork>> _getExhibitionFakeArtworks(String exhibitionId) async {
    List<Artwork> listArtworks = [];
    final exhibition = await getExhibition(exhibitionId);
    final series = await getListSeries(exhibitionId);
    await Future.wait(series.map((e) => _fakeSeriesArtworks(e, exhibition)))
        .then((value) {
      listArtworks.addAll(value.expand((element) => element));
    });
    return listArtworks;
  }

  String getFeralfileTokenId(
      {required String seriesOnchainID,
      required String exhibitionID,
      required int artworkIndex}) {
    final BigInt si = BigInt.parse(seriesOnchainID);
    final BigInt msi = si * BigInt.from(1000000) + BigInt.from(artworkIndex);
    final String part1 = exhibitionID.replaceAll('-', '');
    final String part2 = msi.toRadixString(16);
    final String p = part1 + part2;
    final BigInt tokenIDBigInt = BigInt.parse('0x$p');
    final String tokenID = tokenIDBigInt.toString();
    return tokenID;
  }

  Future<String> previewArtCustomTokenID(
      {required String seriesOnchainID,
      required String exhibitionID,
      required int artworkIndex}) async {
    final String tokenID = getFeralfileTokenId(
        seriesOnchainID: seriesOnchainID,
        exhibitionID: exhibitionID,
        artworkIndex: artworkIndex);
    final Uint8List tokenIDBytes = utf8.encode(tokenID);
    final String tokenIDHash = sha256.convert(tokenIDBytes).toString();
    return '&token_id=$tokenID&token_id_hash=0x$tokenIDHash';
  }

  Future<String?> _getPreviewURI(
      FFSeries series, int artworkIndex, Exhibition exhibition) async {
    String? previewURI;
    if (series.settings?.artworkModel == ArtworkModel.multiUnique &&
        series.previewFile == null) {
      previewURI = '${series.uniquePreviewPath}/$artworkIndex';
    }
    if (previewURI == null) {
      if (!GenerativeMediumTypes.values
              .any((element) => element.value == series.medium) &&
          series.uniquePreviewPath != null) {
        previewURI = '${series.uniquePreviewPath}/$artworkIndex';
      }
    }

    if (previewURI != null) {
      return previewURI;
    } else {
      previewURI ??= getFFUrl(series.previewFile?.uri ?? '');
      final artworkNumber = artworkIndex + 1;
      previewURI = '$previewURI?edition_number=$artworkIndex'
          '&artwork_number=$artworkNumber'
          '&blockchain=${exhibition.mintBlockchain}';
      //TODO: check if (contract) {...}

      if (GenerativeMediumTypes.values
          .any((element) => element.value == series.medium)) {
        try {
          final tokenParameters = await previewArtCustomTokenID(
            seriesOnchainID: series.onchainID ?? '',
            exhibitionID: series.exhibitionID,
            artworkIndex: artworkIndex,
          );
          previewURI += tokenParameters;
        } catch (error, stackTrace) {
          log.info(
              '[FeralFileService] Get preview URI failed: $error, $stackTrace');
        }
      }
    }
    return previewURI;
  }

  String _getThumbnailURI(FFSeries series, int artworkIndex) =>
      series.uniqueThumbnailPath != null
          ? '${series.uniqueThumbnailPath}/$artworkIndex-large.jpg'
          : series.thumbnailURI ?? '';

  Future<List<Artwork>> _fakeSeriesArtworks(
      FFSeries series, Exhibition exhibition) async {
    final List<Artwork> artworks = [];
    final maxArtworks = series.maxEdition;
    for (var i = 0; i < maxArtworks; i++) {
      final previewURI = await _getPreviewURI(series, i, exhibition);
      final artworkId = getFeralfileTokenId(
        seriesOnchainID: series.onchainID ?? '',
        exhibitionID: series.exhibitionID,
        artworkIndex: i,
      );
      final thumbnailURI = _getThumbnailURI(series, i);
      final fakeArtwork = Artwork(
        artworkId,
        series.id,
        i,
        '#${i + 1}',
        'Artwork category $i',
        'ownerAccountID',
        null,
        null,
        'blockchainStatus',
        false,
        thumbnailURI,
        previewURI ?? '',
        {},
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        null,
        series,
        null,
      );
      artworks.add(fakeArtwork);
    }
    return artworks;
  }

  @override
  Future<List<Artwork>> getExhibitionArtworks(String exhibitionId,
      {bool withSeries = false}) async {
    List<Artwork> listArtworks = [];
    listArtworks = await _getExhibitionArtworkByDirectApi(exhibitionId,
        withSeries: withSeries);
    if (listArtworks.isNotEmpty) {
      return listArtworks;
    } else {
      listArtworks = await _getExhibitionFakeArtworks(exhibitionId);
    }
    return listArtworks;
  }

  @override
  Future<List<Artwork>> getSeriesArtworks(String seriesId,
      {bool withSeries = false}) async {
    final artworks = await _feralFileApi.getListArtworks(seriesId: seriesId);
    List<Artwork> listArtwork = artworks.result;
    if (listArtwork.isEmpty) {
      final series = await getSeries(seriesId);
      listArtwork = await _fakeSeriesArtworks(series, series.exhibition!);
    } else if (withSeries) {
      final series = await getSeries(seriesId);
      listArtwork = listArtwork.map((e) => e.copyWith(series: series)).toList();
    }
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
  Future<File?> downloadFeralfileArtwork(AssetToken assetToken,
      {Function(int received, int total)? onReceiveProgress}) async {
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
      final file = DownloadHelper.fileChunkedDownload(url,
          onReceiveProgress: onReceiveProgress);
      return file;
    } catch (e) {
      log.info('Error downloading artwork: $e');
      rethrow;
    }
  }

  @override
  Future<List<FFSeries>> getListSeries(String exhibitionId) async {
    final response = await _feralFileApi.getListSeries(
        exhibitionID: exhibitionId, sortBy: 'displayIndex', sortOrder: 'ASC');
    return response.result;
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
