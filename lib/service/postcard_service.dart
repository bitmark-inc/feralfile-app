//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/model/postcard_claim.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:geolocator/geolocator.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/models/asset_token.dart';

abstract class PostcardService {
  Future<ReceivePostcardRespone?> receivePostcard(
      {required String shareId,
      required Position location,
      required String address});

  Future<ClaimPostCardResponse> claimEmptyPostcard(
      ClaimPostCardRequest request);

  Future<SharePostcardRespone> sharePostcard(
      AssetToken asset, String signature);

  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode);

  Future<AssetToken> getPostcard(String tokenId);

  Future<bool> isReceived(String tokenId);

  Future<bool> stampPostcard(String tokenId, WalletStorage wallet, int index,
      File image, Position? location);
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
  Future<ReceivePostcardRespone?> receivePostcard({
    required String shareId,
    required Position location,
    required String address,
  }) async {
    final body = {
      "shareId": shareId,
      "location": [location.latitude, location.longitude],
      "address": address,
    };

    ///TODO: update api
    final postcard = await _postcardApi.claim(ClaimPostCardRequest());

    return ReceivePostcardRespone(tokenId: postcard.tokenID);
  }

  @override
  Future<SharePostcardRespone> sharePostcard(
      AssetToken asset, String signature) async {
    final tokenId = asset.tokenId ?? '';
    final counter = asset.counter;
    final body = {
      "tokenId": tokenId,
      "signature": signature,
      "counter": counter,
    };
    return SharePostcardRespone(url: "https://bitmark.com");
    final response = await _postcardApi.share(tokenId, body);
    if (response.statusCode == 200) {
      final url = json.decode(response.body);
      return SharePostcardRespone(url: url);
    } else {
      throw Exception('Failed to load postcards');
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
    return SharedPostcardInfor(
        shareId: "sharedId",
        tokenId: "tokenId",
        imageCID: "imageCID",
        counter: 0);
    final response = await _postcardApi.claimShareCode(shareCode);
    if (response.statusCode == 200) {
      final sharedPostcardInfor = json.decode(response.body);
      return sharedPostcardInfor;
    } else {
      throw Exception('Failed to load postcards');
    }
  }

  @override
  Future<bool> isReceived(String tokenId) async {
    return false;
  }

  @override
  Future<bool> stampPostcard(String tokenId, WalletStorage wallet, int index,
      File image, Position? location) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signature = await _tezosService.signMessage(
        wallet, index, Uint8List.fromList(utf8.encode(timestamp.toString())));
    final address = await wallet.getTezosAddress(index: index);
    final publicKey = await wallet.getTezosPublicKey(index: index);
    final lat = location?.latitude;
    final lon = location?.longitude;
    final result = await _postcardApi.updatePostcard(
        tokenId: tokenId,
        data: image,
        signature: signature,
        timestamp: timestamp,
        address: address,
        publicKey: publicKey,
        lat: lat,
        lon: lon) as Map<String, dynamic>;
    final ok = result["metadataCID"] as String;
    return ok.isNotEmpty;
  }
}

class SharePostcardRespone {
  String? url;

  SharePostcardRespone({this.url});
}

class ReceivePostcardRespone {
  String? tokenId;

  ReceivePostcardRespone({this.tokenId});
}

class SharedPostcardInfor {
  String shareId;
  String tokenId;
  String imageCID;
  int counter;

  SharedPostcardInfor(
      {required this.shareId,
      required this.tokenId,
      required this.imageCID,
      required this.counter});
}
