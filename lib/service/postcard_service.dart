//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/receive_postcard_page.dart';
import 'package:autonomy_flutter/screen/send_receive_postcard/request_response.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:geolocator/geolocator.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/models/asset_token.dart';

abstract class PostcardService {
  Future<ReceivePostcardResponse> receivePostcard(
      {required String shareCode,
      required Position location,
      required String address});

  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request);

  Future<SharePostcardResponse> sharePostcard(
      AssetToken asset, String signature);

  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode);

  Future<AssetToken> getPostcard(String tokenId);

  Future<bool> isReceived(String tokenId);

  Future<bool> stampPostcard(String tokenId, WalletStorage wallet, int index,
      File image, File metadata, Position? location, int counter);
}

class PostcardServiceImpl extends PostcardService {
  final PostcardApi _postcardApi;
  final IndexerApi _indexerApi;
  final TezosService _tezosService;

  PostcardServiceImpl(this._postcardApi, this._indexerApi, this._tezosService);

  @override
  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request) async {
    return _postcardApi.claim(request);
  }

  @override
  Future<ReceivePostcardResponse> receivePostcard({
    required String shareCode,
    required Position location,
    required String address,
  }) async {
    final body = {
      "shareCode": shareCode,
      "location": [location.latitude, location.longitude],
      "address": address,
    };
    return _postcardApi.receive(body);
  }

  @override
  Future<SharePostcardResponse> sharePostcard(
      AssetToken asset, String signature) async {
    final tokenId = asset.tokenId ?? '';
    final body = {
      "address": asset.owner,
      "contractAddress": asset.contractAddress
    };
    try {
      final response = await _postcardApi.share(tokenId, body);

      final deeplink = response["deeplink"];
      return SharePostcardResponse(deeplink: deeplink);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AssetToken> getPostcard(String tokenId) async {
    final assets = await _indexerApi.getNftTokens({
      "ids": [tokenId]
    });
    return assets.first;
  }

  @override
  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode) async {
    final response = await _postcardApi.claimShareCode(shareCode);
    response["shareCode"] = shareCode;
    final sharedPostcardInfor = SharedPostcardInfor.fromJson(response);
    return sharedPostcardInfor;
  }

  @override
  Future<bool> isReceived(String tokenId) async {
    return false;
  }

  @override
  Future<bool> stampPostcard(String tokenId, WalletStorage wallet, int index,
      File image, File metadata, Position? location, int counter) async {
    final message2sign =
        [Environment.postcardContractAddress, tokenId, counter].join("|");
    final signature = await _tezosService.signMessage(
        wallet, index, Uint8List.fromList(utf8.encode(message2sign)));
    final address = await wallet.getTezosAddress(index: index);
    final publicKey = await wallet.getTezosPublicKey(index: index);
    final lat = location?.latitude;
    final lon = location?.longitude;
    final result = await _postcardApi.updatePostcard(
        tokenId: tokenId,
        data: image,
        metadata: metadata,
        signature: signature,
        address: address,
        publicKey: publicKey,
        lat: lat,
        lon: lon) as Map<String, dynamic>;
    final ok = result["metadataCID"] as String;
    return ok.isNotEmpty;
  }
}
