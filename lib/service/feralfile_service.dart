//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/feralfile_api.dart';
import 'package:autonomy_flutter/gateway/source_exhibition_api.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_list_response.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/download_helper.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/series_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nft_collection/models/asset_token.dart';

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
  static const int offset = 0;
  static const int limit = 300;

  Future<FFSeries> getSeries(String id,
      {String? exhibitionID, bool includeFirstArtwork = false});

  Future<List<FFSeries>> getListSeries(String exhibitionId,
      {bool includeFirstArtwork = false});

  Future<Exhibition?> getExhibitionFromTokenID(String artworkID);

  Future<FeralFileResaleInfo> getResaleInfo(String exhibitionID);

  Future<String?> getPartnerFullName(String exhibitionId);

  Future<Exhibition> getExhibition(String id,
      {bool includeFirstArtwork = false});

  Future<List<Exhibition>> getAllExhibitions({
    String sortBy = 'openAt',
    String sortOrder = 'DESC',
    int limit = 8,
    int offset = 0,
  });

  Future<Exhibition> getSourceExhibition();

  Future<Exhibition?> getUpcomingExhibition();

  Future<Exhibition> getFeaturedExhibition();

  Future<FeralFileListResponse<Artwork>> getSeriesArtworks(
      String seriesId, String exhibitionID,
      {bool withSeries = false, int offset = offset, int limit = limit});

  Future<Artwork?> getFirstViewableArtwork(String seriesId);

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
  final SourceExhibitionAPI _sourceExhibitionAPI;
  Exhibition? sourceExhibition;
  List<BeforeMintingArtworkInfo> beforeMintingArtworkInfos = [];

  FeralFileServiceImpl(
    this._feralFileApi,
    this._sourceExhibitionAPI,
  );

  @override
  Future<FFSeries> getSeries(String id,
      {String? exhibitionID, bool includeFirstArtwork = false}) async {
    if (exhibitionID == SOURCE_EXHIBITION_ID) {
      return await _getSourceSeries(
        id,
        includeFirstArtwork: includeFirstArtwork,
      );
    }
    final series = (await _feralFileApi.getSeries(
            seriesId: id, includeFirstArtwork: includeFirstArtwork))
        .result;

    if (includeFirstArtwork && series.artwork == null) {
      final exhibition = await getExhibition(series.exhibitionID);
      final artworks = await _getFakeSeriesArtworks(exhibition, series, 0, 1);
      return series.copyWith(artwork: artworks.first);
    }

    return series;
  }

  @override
  Future<Exhibition> getExhibition(String id,
      {bool includeFirstArtwork = false}) async {
    if (id == SOURCE_EXHIBITION_ID) {
      return getSourceExhibition();
    }

    final resp = await _feralFileApi.getExhibition(id,
        includeFirstArtwork: includeFirstArtwork);
    final exhibition = resp.result!;

    if (includeFirstArtwork &&
        exhibition.series != null &&
        exhibition.series!.any((series) => series.artwork == null)) {
      final List<FFSeries> newSeries = [];
      for (final series in exhibition.series ?? []) {
        if (series.artwork == null) {
          final fakeArtwork =
              await _getFakeSeriesArtworks(exhibition, series, 0, 1);
          newSeries.add(series.copyWith(artwork: fakeArtwork.first));
        } else {
          newSeries.add(series);
        }
      }

      return exhibition.copyWith(series: newSeries);
    }

    return exhibition;
  }

  @override
  Future<FeralFileResaleInfo> getResaleInfo(String exhibitionID) async {
    final resaleInfo = await _feralFileApi.getResaleInfo(exhibitionID);
    return resaleInfo.result;
  }

  @override
  Future<String?> getPartnerFullName(String exhibitionId) async {
    final exhibition = await _feralFileApi.getExhibition(exhibitionId);
    return exhibition.result!.partner?.fullName;
  }

  @override
  Future<Exhibition?> getExhibitionFromTokenID(String artworkID) async {
    final artwork = await _feralFileApi.getArtworks(artworkID);
    return artwork.result.series?.exhibition;
  }

  @override
  Future<List<Exhibition>> getAllExhibitions({
    String sortBy = 'openAt',
    String sortOrder = 'DESC',
    int limit = 8,
    int offset = 0,
  }) async {
    final exhibitions = await _feralFileApi.getAllExhibitions(
        sortBy: sortBy, sortOrder: sortOrder, limit: limit, offset: offset);
    final listExhibition = exhibitions.result;
    log
      ..info('[FeralFileService] Get all exhibitions: ${listExhibition.length}')
      ..info('[FeralFileService] Get all exhibitions: '
          '${listExhibition.map((e) => e.id).toList()}');
    return listExhibition;
  }

  @override
  Future<Exhibition?> getUpcomingExhibition() async {
    final exhibitionResponse = await _feralFileApi.getUpcomingExhibition();
    return exhibitionResponse.result;
  }

  @override
  Future<Exhibition> getFeaturedExhibition() async {
    final exhibitionResponse = await _feralFileApi.getFeaturedExhibition();
    return exhibitionResponse.result!;
  }

  Future<List<Artwork>> _getFakeSeriesArtworks(
      Exhibition exhibition, FFSeries series, int offset, int limit) async {
    if (exhibition.isJohnGerrardShow) {
      return await _getJohnGerrardFakeArtworks(
        series: series,
        offset: offset,
        limit: limit,
        onlySignedArtwork: true,
      );
    }
    final fakeArtworks =
        _createFakeSeriesArtworks(series, exhibition, offset, limit);
    return fakeArtworks;
  }

  Future<List<Artwork>> _createFakeSeriesArtworks(
      FFSeries series, Exhibition exhibition, int offset, int limit) async {
    final List<Artwork> artworks = [];
    final maxArtworks = limit;
    for (var i = offset; i < maxArtworks; i++) {
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
        null,
      );
      artworks.add(fakeArtwork);
    }
    return artworks;
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

  Future<FeralFileListResponse<Artwork>> _fakeSeriesArtworks(
      String seriesId, String exhibitionId,
      {required int offset, required int limit}) async {
    final exhibition = await getExhibition(exhibitionId);
    final series = await getSeries(seriesId);
    final List<Artwork> seriesArtworks =
        await _getFakeSeriesArtworks(exhibition, series, offset, limit);
    final total = series.latestRevealedArtworkIndex == null
        ? series.maxEdition
        : series.latestRevealedArtworkIndex! + 1;
    return FeralFileListResponse(
        result: seriesArtworks,
        paging: Paging(offset: offset, limit: limit, total: total));
  }

  @override
  Future<FeralFileListResponse<Artwork>> getSeriesArtworks(
      String seriesId, String exhibitionID,
      {bool withSeries = false,
      int offset = FeralFileService.offset,
      int limit = FeralFileService.limit}) async {
    if (exhibitionID == SOURCE_EXHIBITION_ID) {
      final artworks = await _getSourceSeriesArtworks(seriesId);
      return FeralFileListResponse(
          result:
              artworks.sublist(offset, min(artworks.length, offset + limit)),
          paging: Paging(offset: 0, limit: limit, total: artworks.length));
    }

    FeralFileListResponse<Artwork> artworksResponse = await _feralFileApi
        .getListArtworks(seriesId: seriesId, offset: offset, limit: limit);
    if (artworksResponse.result.isEmpty) {
      return await _fakeSeriesArtworks(seriesId, exhibitionID,
          offset: offset, limit: limit);
    }

    if (withSeries) {
      final series = await getSeries(seriesId);
      artworksResponse.copyWith(
          result: artworksResponse.result
              .map((e) => e.copyWith(series: series))
              .toList());
    }
    log
      ..info(
        '[FeralFileService] Get series artworks:'
        ' ${artworksResponse.result.length}, offset $offset, limit $limit',
      )
      ..info(
        '[FeralFileService] Get series artworks: '
        '${artworksResponse.result.map((e) => e.id).toList()}',
      );
    return artworksResponse;
  }

  @override
  Future<Artwork?> getFirstViewableArtwork(String seriesId) async {
    final response = await _feralFileApi.getListArtworks(
      seriesId: seriesId,
      includeActiveSwap: false,
      sortOrder: 'DESC',
      isViewable: true,
    );
    return response.result.firstOrNull;
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
  Future<List<FFSeries>> getListSeries(String exhibitionId,
      {bool includeFirstArtwork = false}) async {
    if (exhibitionId == SOURCE_EXHIBITION_ID) {
      final exhibition = await getSourceExhibition();
      return exhibition.series ?? [];
    }
    final response = await _feralFileApi.getListSeries(
        exhibitionID: exhibitionId, sortBy: 'displayIndex', sortOrder: 'ASC');
    return response.result;
  }

  // Source Exhibition
  @override
  Future<Exhibition> getSourceExhibition() async {
    if (sourceExhibition != null) {
      return sourceExhibition!;
    }

    final exhibition = await _sourceExhibitionAPI.getSourceExhibitionInfo();
    final series = await _sourceExhibitionAPI.getSourceExhibitionSeries();
    sourceExhibition = exhibition.copyWith(series: series);
    return sourceExhibition!;
  }

  Future<FFSeries> _getSourceSeries(String seriesID,
      {bool includeFirstArtwork = false}) async {
    late List<FFSeries> listSeries;
    if (sourceExhibition != null && sourceExhibition!.series != null) {
      listSeries = sourceExhibition!.series!;
    } else {
      listSeries = await _sourceExhibitionAPI.getSourceExhibitionSeries();
    }

    final series = listSeries.firstWhere((series) => series.id == seriesID);
    if (includeFirstArtwork) {
      final firstArtwork = series.artworks!.first;
      return series.copyWith(artwork: firstArtwork);
    }

    return series;
  }

  Future<List<Artwork>> _getSourceSeriesArtworks(String seriesID) async {
    final series = await _getSourceSeries(seriesID);
    return series.artworks!;
  }

  // John Gerrard exhibition
  Future<List<BeforeMintingArtworkInfo>> _getBeforeMintingArtworkInfos(
      FFSeries series) async {
    if (beforeMintingArtworkInfos.isNotEmpty) {
      return beforeMintingArtworkInfos;
    }

    try {
      final artworkInfoLink =
          '${Environment.feralFileAssetURL}/previews/${series.id}/${series.previewFile?.version ?? ''}/info.json';
      final response = await http.get(Uri.parse(artworkInfoLink));
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        beforeMintingArtworkInfos = body.entries.map((entry) {
          final map = entry.value as Map<String, dynamic>;
          return BeforeMintingArtworkInfo.fromJson(map);
        }).toList();
        return beforeMintingArtworkInfos;
      } else {
        throw Exception('Failed to load SOURCE series');
      }
    } catch (e) {
      throw Exception('Failed to load SOURCE series');
    }
  }

  Future<List<Artwork>> _getJohnGerrardFakeArtworks({
    required FFSeries series,
    required int offset,
    bool onlySignedArtwork = false,
    int limit = 50,
  }) async {
    int maxArtwork;
    if (onlySignedArtwork) {
      maxArtwork = series.latestRevealedArtworkIndex == null
          ? 0
          : (series.latestRevealedArtworkIndex! + 1);
    } else {
      maxArtwork = series.settings?.maxArtwork ?? 0;
    }

    if (maxArtwork == 0) {
      return [];
    }

    final endIndex = min(offset + limit, maxArtwork);
    if (offset >= endIndex) {
      return [];
    }

    List<Artwork> fakeArtworks = [];
    for (var index = offset; index < endIndex; index++) {
      final fakeArtwork = await _getJohnGerrardArtworkByIndex(index, series);
      fakeArtworks.add(fakeArtwork);
    }

    return fakeArtworks;
  }

  Future<Artwork> _getJohnGerrardArtworkByIndex(
      int index, FFSeries series) async {
    final beforeMintingArtworkInfos =
        await _getBeforeMintingArtworkInfos(series);
    final artworkId = getFeralfileTokenId(
      seriesOnchainID: series.onchainID ?? '',
      exhibitionID: series.exhibitionID,
      artworkIndex: index,
    );
    return Artwork(
        artworkId,
        series.id,
        index,
        beforeMintingArtworkInfos[index].artworkTitle,
        '',
        null,
        null,
        null,
        '',
        false,
        'previews/${series.id}/${series.previewFile?.version}/generated_images/crystal_${index + MAGIC_NUMBER}_img.jpg',
        'previews/${series.id}/${series.previewFile?.version}/nft.html?hourIdx=${index + MAGIC_NUMBER}',
        {
          'viewableAt': beforeMintingArtworkInfos[index].viewableAt,
        },
        DateTime.now(),
        DateTime.now(),
        DateTime.now(),
        null,
        series,
        null,
        null);
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
