//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/gateway/airdrop_api.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/graphql/model/get_list_tokens.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';

class AirdropService {
  final AirdropApi _airdropApi;
  final AssetTokenDao _assetTokenDao;
  final AccountService _accountService;
  final TezosService _tezosService;
  final TokensService _tokensService;
  final FeralFileService _feralFileService;
  final IndexerService _indexerService;
  final NavigationService _navigationService;

  const AirdropService(
      this._airdropApi,
      this._assetTokenDao,
      this._accountService,
      this._tezosService,
      this._tokensService,
      this._feralFileService,
      this._indexerService,
      this._navigationService);

  Future<AirdropShareResponse> share(AirdropShareRequest request) async =>
      _airdropApi.share(request.tokenId, request);

  Future<AirdropClaimShareResponse> claimShare(
          AirdropClaimShareRequest request) async =>
      _airdropApi.claimShare(request.shareCode);

  Future<AirdropRequestClaimResponse> requestClaim(
          AirdropRequestClaimRequest request) async =>
      _airdropApi.requestClaim(request);

  Future<TokenClaimResponse> claim(AirdropClaimRequest request) async =>
      _airdropApi.claim(request);

  Future<AssetToken?> getTokenByContract(List<String> contractAddress) async {
    final allTokens = await _assetTokenDao.findAllAssetTokens();
    final assetToken = allTokens.firstWhereOrNull(
        (element) => contractAddress.contains(element.contractAddress));
    return assetToken;
  }

  Future<AirdropRequestClaimResponse> claimRequestGift(
      AssetToken assetToken) async {
    try {
      final request = AirdropRequestClaimRequest(
          ownerAddress: assetToken.owner,
          id: MOMA_MEMENTO_6_CLAIM_ID,
          indexID: assetToken.id);
      final requestClaimResponse = await requestClaim(request);
      return requestClaimResponse;
    } catch (e) {
      log.info('[Airdrop service] claimGift: $e');
      _navigationService.showAirdropJustOnce();
      rethrow;
    }
  }

  Future<ClaimResponse> claimGift(
      {required String claimID,
      required String shareCode,
      required String seriesId,
      required String receivingAddress}) async {
    final defaultAccount = await _accountService.getDefaultAccount();
    final didKey = await defaultAccount.getAccountDID();
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final didKeySignature =
        await defaultAccount.getAccountDIDSignature(timestamp);
    final series = await _feralFileService.getSeries(seriesId);
    try {
      final claimRequest = AirdropClaimRequest(
          claimId: claimID,
          shareCode: shareCode,
          receivingAddress: receivingAddress,
          did: didKey,
          didSignature: didKeySignature,
          timestamp: timestamp);
      final claimResponse = await claim(claimRequest);
      await _tokensService.reindexAddresses([receivingAddress]);

      final indexerId =
          series.airdropInfo!.getTokenIndexerId(claimResponse.result.artworkID);
      List<AssetToken> assetTokens = await _fetchTokens(
        indexerId: indexerId,
        receiver: receivingAddress,
      );
      if (assetTokens.isNotEmpty) {
        await _tokensService.setCustomTokens(assetTokens);
      } else {
        assetTokens = [
          createPendingAssetToken(
            series: series,
            owner: receivingAddress,
            tokenId: claimResponse.result.artworkID,
          )
        ];
        await _tokensService.setCustomTokens(assetTokens);
      }
      return ClaimResponse(
          token: assetTokens.first, airdropInfo: series.airdropInfo!);
    } catch (e) {
      log.info('[Airdrop service] claimGift: $e');
      if (e is DioException) {
        switch (e.response?.data['message']) {
          case 'cannot self claim':
            _navigationService.showAirdropJustOnce();
            break;
          case 'invalid claim':
            _navigationService.showAirdropAlreadyClaimed();
            break;
          case 'the token is not available for share':
            _navigationService.showAirdropAlreadyClaimed();
            break;
          default:
            UIHelper.showClaimTokenError(
              _navigationService.navigatorKey.currentContext!,
              e,
              series: series,
            );
        }
      }
      rethrow;
    }
  }

  Future<List<AssetToken>> _fetchTokens({
    required String indexerId,
    required String receiver,
  }) async {
    try {
      final List<AssetToken> assets = await _indexerService
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
      return [];
    }
  }

  Future<String?> shareAirdrop(AssetToken assetToken) async {
    try {
      final ownerAddress = assetToken.owner;
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final isViewOnly = await assetToken.isViewOnly();
      String signature = '';
      String ownerPublicKey = '';
      if (!isViewOnly) {
        final ownerWallet = await _accountService.getAccountByAddress(
            chain: assetToken.blockchain, address: ownerAddress);
        ownerPublicKey = await ownerWallet.wallet
            .getTezosPublicKey(index: ownerWallet.index);
        signature = await _tezosService.signMessage(
            ownerWallet.wallet,
            ownerWallet.index,
            Uint8List.fromList(utf8.encode('${assetToken.id}|$timestamp')));
      }
      final shareRequest = AirdropShareRequest(
          tokenId: assetToken.id,
          ownerAddress: assetToken.owner,
          ownerPublicKey: ownerPublicKey,
          signature: signature,
          timestamp: timestamp);
      final shareResponse = await share(shareRequest);
      return shareResponse.deepLink;
    } catch (e) {
      log.info('[Airdrop service] shareGift: error $e');
      return null;
    }
  }
}

class AirdropRequestClaimRequest {
  String ownerAddress;
  String id;
  String indexID;

  AirdropRequestClaimRequest(
      {required this.ownerAddress, required this.id, required this.indexID});

  //toJson
  Map<String, dynamic> toJson() => {
        'ownerAddress': ownerAddress,
        'id': id,
        'indexID': indexID,
      };

  // fromJson
  factory AirdropRequestClaimRequest.fromJson(Map<String, dynamic> json) =>
      AirdropRequestClaimRequest(
        ownerAddress: json['ownerAddress'],
        id: json['id'],
        indexID: json['indexID'],
      );
}

class AirdropRequestClaimResponse {
  String claimID;
  String seriesID;

  AirdropRequestClaimResponse({required this.claimID, required this.seriesID});

  //toJson
  Map<String, dynamic> toJson() => {
        'claimID': claimID,
        'seriesID': seriesID,
      };

  // fromJson
  factory AirdropRequestClaimResponse.fromJson(Map<String, dynamic> json) =>
      AirdropRequestClaimResponse(
        claimID: json['claimID'],
        seriesID: json['seriesID'],
      );
}

class AirdropClaimRequest {
  String claimId;
  String shareCode;
  String receivingAddress;
  String did;
  String didSignature;
  String timestamp;

  AirdropClaimRequest(
      {required this.claimId,
      required this.shareCode,
      required this.receivingAddress,
      required this.did,
      required this.didSignature,
      required this.timestamp});

  //toJson
  Map<String, dynamic> toJson() => {
        'claimID': claimId,
        'shareCode': shareCode,
        'receivingAddress': receivingAddress,
        'did': did,
        'didSignature': didSignature,
        'timestamp': timestamp,
      };

  // fromJson
  factory AirdropClaimRequest.fromJson(Map<String, dynamic> json) =>
      AirdropClaimRequest(
        claimId: json['claimID'],
        shareCode: json['shareCode'],
        receivingAddress: json['receivingAddress'],
        did: json['did'],
        didSignature: json['didSignature'],
        timestamp: json['timesStamp'],
      );
}

class AirdropClaimShareRequest {
  String shareCode;

  AirdropClaimShareRequest({required this.shareCode});

  //toJson
  Map<String, dynamic> toJson() => {
        'shareCode': shareCode,
      };

  // fromJson
  factory AirdropClaimShareRequest.fromJson(Map<String, dynamic> json) =>
      AirdropClaimShareRequest(
        shareCode: json['shareCode'],
      );
}

class AirdropClaimShareResponse {
  String shareCode;
  String seriesID;

  AirdropClaimShareResponse({required this.shareCode, required this.seriesID});

  //toJson
  Map<String, dynamic> toJson() => {
        'shareCode': shareCode,
        'seriesID': seriesID,
      };

  // fromJson
  factory AirdropClaimShareResponse.fromJson(Map<String, dynamic> json) =>
      AirdropClaimShareResponse(
        shareCode: json['shareCode'],
        seriesID: json['seriesID'],
      );
}

class AirdropShareRequest {
  String tokenId;
  String ownerAddress;
  String? ownerPublicKey;
  String timestamp;
  String? signature;

  AirdropShareRequest(
      {required this.tokenId,
      required this.ownerAddress,
      required this.ownerPublicKey,
      required this.signature,
      required this.timestamp});

  //toJson
  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'ownerAddress': ownerAddress,
        'ownerPublicKey': ownerPublicKey,
        'timestamp': timestamp,
        'signature': signature,
      };

  // fromJson
  factory AirdropShareRequest.fromJson(Map<String, dynamic> json) =>
      AirdropShareRequest(
        tokenId: json['tokenId'],
        ownerAddress: json['ownerAddress'],
        ownerPublicKey: json['ownerPublicKey'],
        timestamp: json['timestamp'],
        signature: json['signature'],
      );
}

class AirdropShareResponse {
  String deepLink;

  AirdropShareResponse({required this.deepLink});

  //toJson
  Map<String, dynamic> toJson() => {
        'deeplink': deepLink,
      };

  // fromJson
  factory AirdropShareResponse.fromJson(Map<String, dynamic> json) =>
      AirdropShareResponse(
        deepLink: json['deeplink'],
      );
}

class AirdropTokenIdentity {
  String id;
  String owner;

  AirdropTokenIdentity({required this.id, required this.owner});

  //toJson
  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
      };

  // fromJson
  factory AirdropTokenIdentity.fromJson(Map<String, dynamic> json) =>
      AirdropTokenIdentity(
        id: json['id'],
        owner: json['owner'],
      );
}

enum AirdropType {
  memento6,
  unknown;

  String get seriesId {
    switch (this) {
      case AirdropType.memento6:
        return memento6SeriesId;
      default:
        return 'unknown';
    }
  }
}
