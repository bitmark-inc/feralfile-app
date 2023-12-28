//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

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
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:collection/collection.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';

import '../model/ff_exhibition_artworks_response.dart';

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

  Future<List<ExhibitionDetail>> getAllExhibitions({
    String sortBy = 'openAt',
    String sortOrder = 'DESC',
    int limit = 8,
    int offset = 0,
    bool withArtworks = false,
  });

  Future<Exhibition> getFeaturedExhibition();

  Future<List<Artwork>> getExhibitionArtworks(String exhibitionId);
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
    //final artworks = await _feralFileApi.getExhibitionArtworks(exhibitionId);
    final a = {
      "result": [
        {
          "id": "1895471415479101141617488280575446737837854080",
          "seriesID": "688c1976-748d-4b54-8aac-61b5561924e6",
          "index": 0,
          "name": "#1",
          "category": "CE",
          "ownerAccountID": "0x457ee5f723C7606c12a7264b52e285906F91eEA6",
          "virgin": false,
          "blockchainStatus": "settled",
          "isExternal": true,
          "thumbnailURI":
              "previews/688c1976-748d-4b54-8aac-61b5561924e6/1697235166/_unique-thumbnails/0-large.jpg",
          "previewURI":
              "previews/688c1976-748d-4b54-8aac-61b5561924e6/1697235166/index.html?edition_number=0&artwork_number=1&blockchain=ethereum&contract=0xacd3392e9Ec2C4D876D09DC38cb52F842Ea58096&token_id=1895471415479101141617488280575446737837854080&token_id_hash=0x8aa618bba26a20bd9dc653b8091970ff780b6eca462f4df844d30536124b7dbd",
          "metadata": {
            "ipfs_cid":
                "QmNVdQSp1AvZonLwHzTbbZDPLgbpty15RMQrbPEWd4ooTU/1895471415479101141617488280575446737837854080"
          },
          "mintedAt": "2023-11-16T07:10:59Z",
          "createdAt": "2023-11-16T07:11:18.636127Z",
          "updatedAt": "2023-12-26T08:56:36Z",
          "isArchived": false,
          "artworkAttributes": [
            {
              "id": "3e9d3b43-670a-4160-869e-74ec477df9fc",
              "artworkID": "1895471415479101141617488280575446737837854080",
              "index": 0,
              "seriesID": "688c1976-748d-4b54-8aac-61b5561924e6",
              "traitType": "Artist",
              "value": "Aleksandra Jovanić",
              "percentage": 16.666666666666668
            },
            {
              "id": "1ad257b3-a1e7-430b-abf7-07604e355dc8",
              "artworkID": "1895471415479101141617488280575446737837854080",
              "index": 0,
              "seriesID": "688c1976-748d-4b54-8aac-61b5561924e6",
              "traitType": "Artwork of",
              "value": "30",
              "percentage": 100
            },
            {
              "id": "dcf5d30b-05a9-4e72-b823-1fbc9e89ea28",
              "artworkID": "1895471415479101141617488280575446737837854080",
              "index": 0,
              "seriesID": "688c1976-748d-4b54-8aac-61b5561924e6",
              "traitType": "Exhibition",
              "value": "Feral File - +GRAPH",
              "percentage": 100
            },
            {
              "id": "a4f45e47-8094-4d26-8f5f-2104ef27a608",
              "artworkID": "1895471415479101141617488280575446737837854080",
              "index": 0,
              "seriesID": "688c1976-748d-4b54-8aac-61b5561924e6",
              "traitType": "Series",
              "value": "The Space in Between",
              "percentage": 16.666666666666668
            }
          ]
        },
        {
          "id": "1895471415479101141617488280575446737833854080",
          "seriesID": "fe2f3149-d59c-44dc-ba15-f9bc21798388",
          "index": 0,
          "name": "#1",
          "category": "CE",
          "ownerAccountID": "0x457ee5f723C7606c12a7264b52e285906F91eEA6",
          "virgin": false,
          "blockchainStatus": "settled",
          "isExternal": true,
          "thumbnailURI":
              "previews/fe2f3149-d59c-44dc-ba15-f9bc21798388/1699526305/_unique-thumbnails/0-large.jpg",
          "previewURI":
              "previews/fe2f3149-d59c-44dc-ba15-f9bc21798388/1699526305/index.html?edition_number=0&artwork_number=1&blockchain=ethereum&contract=0xacd3392e9Ec2C4D876D09DC38cb52F842Ea58096&token_id=1895471415479101141617488280575446737833854080&token_id_hash=0xf82eb1d0dec2c15401723de9b0ab21bd4e24b27a6202004f2789a6e90b0eb2ab",
          "metadata": {
            "ipfs_cid":
                "QmNVdQSp1AvZonLwHzTbbZDPLgbpty15RMQrbPEWd4ooTU/1895471415479101141617488280575446737833854080"
          },
          "mintedAt": "2023-11-16T07:10:59Z",
          "createdAt": "2023-11-16T07:11:18.636127Z",
          "updatedAt": "2023-12-26T08:56:31Z",
          "isArchived": false,
          "artworkAttributes": [
            {
              "id": "aaaa667f-76c0-4f83-9ec5-f766ad7b65ea",
              "artworkID": "1895471415479101141617488280575446737833854080",
              "index": 0,
              "seriesID": "fe2f3149-d59c-44dc-ba15-f9bc21798388",
              "traitType": "Artist",
              "value": "Iskra Velitchkova",
              "percentage": 16.666666666666668
            },
            {
              "id": "547d4478-38f3-4b6d-83a7-caab2f11b56d",
              "artworkID": "1895471415479101141617488280575446737833854080",
              "index": 0,
              "seriesID": "fe2f3149-d59c-44dc-ba15-f9bc21798388",
              "traitType": "Artwork of",
              "value": "30",
              "percentage": 100
            },
            {
              "id": "0678c1b2-dc23-477d-8816-ee6e496a221e",
              "artworkID": "1895471415479101141617488280575446737833854080",
              "index": 0,
              "seriesID": "fe2f3149-d59c-44dc-ba15-f9bc21798388",
              "traitType": "Exhibition",
              "value": "Feral File - +GRAPH",
              "percentage": 100
            },
            {
              "id": "282c28c6-97b3-4b1a-bda0-f6273377cb00",
              "artworkID": "1895471415479101141617488280575446737833854080",
              "index": 0,
              "seriesID": "fe2f3149-d59c-44dc-ba15-f9bc21798388",
              "traitType": "Series",
              "value": "ANATOMY of a rabbit but bird",
              "percentage": 16.666666666666668
            }
          ]
        },
      ],
      "paging": {"offset": 0, "limit": 300, "total": 40}
    } as Map<String, dynamic>;
    final result = ExhibitionArtworksResponse.fromJson(a);
    return result.result;
  }
}
