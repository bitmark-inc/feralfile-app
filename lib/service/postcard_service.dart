//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/models/asset_token.dart';

abstract class PostcardService {
  Future<ReceivePostcardRespone?> receivePostcard(
      {required String shareId,
      required Position location,
      required String address});

  Future claimEmptyPostcard();

  Future<SharePostcardRespone> sharePostcard(
      AssetToken asset, String signature);

  Future<SharedPostcardInfor> getSharedPostcardInfor(String shareCode);

  Future<AssetToken> getPostcard(String tokenId);

  Future<bool> isReceived(String tokenId);
}

class PostcardServiceImpl extends PostcardService {
  final PostcardApi _postcardApi;
  final IndexerApi _indexerApi;
  PostcardServiceImpl(this._postcardApi, this._indexerApi);

  @override
  Future claimEmptyPostcard() async {
    final body = {"id": "postcard", "claimer": "tz1"};
    final xApiSignature = Environment.xApiSignature;
    final response = await _postcardApi.claim(xApiSignature, body);
    if (response.statusCode == 200) {
      final postcard = json.decode(response.body);
      return postcard;
    } else {
      throw Exception('Failed to load postcards');
    }
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
    final xApiSignature = Environment.xApiSignature;
    final response = await _postcardApi.claim(xApiSignature, body);
    if (response.statusCode == 200) {
      final postcard = json.decode(response.body);
      return ReceivePostcardRespone(tokenId: postcard["tokenId"]);
    } else {
      throw Exception('Failed to load postcards');
    }
  }

  @override
  Future<SharePostcardRespone> sharePostcard(
      AssetToken asset, String signature) async {
    final tokenId = asset.tokenId ?? '';
    final counter = asset.counter;
    // final respone = await _postcardAPI.sharePostcard({
    //   "tokenId": tokenId,
    //   "signature": signature,
    // });
    final body = {
      "tokenId": tokenId,
      "signature": signature,
      "counter": counter,
    };
    final xApiSignature = Environment.xApiSignature;
    final response = await _postcardApi.share(xApiSignature, tokenId, body);
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
    final xApiSignature = Environment.xApiSignature;
    final response =
        await _postcardApi.claimShareCode(xApiSignature, shareCode);
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
