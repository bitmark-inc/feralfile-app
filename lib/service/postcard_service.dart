//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:nft_collection/data/api/indexer_api.dart';
import 'package:nft_collection/models/asset_token.dart';

abstract class PostcardService {
  Future<ReceivePostcardRespone?> receivePostcard(
      {required String shareId,
      required String tokenId,
      required String address,
      required int counter});

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

  Future claimEmptyPostcard() async {
    final body = {"id": "postcard", "claimer": "tz1"};
    final response = await _postcardApi.claim(body);
    if (response.statusCode == 200) {
      final postcard = json.decode(response.body);
      return postcard;
    } else {
      throw Exception('Failed to load postcards');
    }
  }

  @override
  Future<ReceivePostcardRespone?> receivePostcard(
      {required String shareId,
      required String tokenId,
      required String address,
      required int counter}) async {
    return ReceivePostcardRespone(tokenId: "tokenId");
  }

  @override
  Future<SharePostcardRespone> sharePostcard(
      AssetToken asset, String signature) async {
    // final tokenId = asset.tokenId;
    // final respone = await _postcardAPI.sharePostcard({
    //   "tokenId": tokenId,
    //   "signature": signature,
    // });
    return SharePostcardRespone(
        url:
            "https://autonomy.bitmark.com/postcard?shareId=shareId&tokenId=tokenId&imageCID=imageCID&counter=0");
  }

  Future<AssetToken> getPostcard(String tokenId) async {
    final assets = await _indexerApi.getNftTokens({
      "ids": [tokenId]
    });
    return assets.first;
  }

  @override
  Future<SharedPostcardInfor> getSharedPostcardInfor(String share_codde) {
    return Future.value(SharedPostcardInfor(
        shareId: "shareId",
        tokenId:
            "tez-KT1U49F46ZRK2WChpVpkUvwwQme7Z595V3nt-37214540304218121786566893708923600581837527203284427749671447415338838818020",
        imageCID: "imageCID",
        counter: 0));
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
