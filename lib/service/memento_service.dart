//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/gateway/memento_api.dart';

class MementoService {
  final MementoApi _mementoApi;

  const MementoService(this._mementoApi);

  Future<MementoShareRespone> share(MementoShareRequest request) async {
    return _mementoApi.share(request.tokenId, request);
    // return MementoShareRespone(deepLink: "autonomy.deepLink");
  }

  Future<MementoGetInfoResponse> getInfo(MementoGetInfoRequest request) async {
    return _mementoApi.getInfo(request.shareCode);
    // return MementoGetInfoResponse(
    //     shareCode: "shareCode", tokenId: "tokenId", imageCID: "imageCID");
  }

  Future<MementoRequestClaimResponse> requestClaim(
      MementoRequestClaimRequest request) async {
    return _mementoApi.requestClaim(request);
    // return MementoRequestClaimResponse(claimId: "claimId");
  }

  Future<MementoClaimResponse> claim(MementoClaimRequest request) async {
    return _mementoApi.claim(request);
    // return MementoClaimResponse();
  }
}

class MementoRequestClaimRequest {
  String ownerAddress;
  String id;
  String tokenId;

  MementoRequestClaimRequest(
      {required this.ownerAddress, required this.id, required this.tokenId});

  //toJson
  Map<String, dynamic> toJson() => {
        'ownerAddress': ownerAddress,
        'id': id,
        'tokenId': tokenId,
      };

  // fromJson
  factory MementoRequestClaimRequest.fromJson(Map<String, dynamic> json) {
    return MementoRequestClaimRequest(
      ownerAddress: json['ownerAddress'],
      id: json['id'],
      tokenId: json['tokenId'],
    );
  }
}

class MementoRequestClaimResponse {
  String claimId;

  MementoRequestClaimResponse({required this.claimId});

  //toJson
  Map<String, dynamic> toJson() => {
        'claimId': claimId,
      };

  // fromJson
  factory MementoRequestClaimResponse.fromJson(Map<String, dynamic> json) {
    return MementoRequestClaimResponse(
      claimId: json['claimId'],
    );
  }
}

class MementoClaimRequest {
  String claimId;
  String shareCode;
  String receivingAddress;
  String receivingPublicKey;
  String did;
  String signature;
  String didSignature;
  String timesStamp;

  MementoClaimRequest(
      {required this.claimId,
      required this.shareCode,
      required this.receivingAddress,
      required this.receivingPublicKey,
      required this.did,
      required this.signature,
      required this.didSignature,
      required this.timesStamp});

  //toJson
  Map<String, dynamic> toJson() => {
        'claimId': claimId,
        'shareCode': shareCode,
        'receivingAddress': receivingAddress,
        'receivingPublicKey': receivingPublicKey,
        'did': did,
        'signature': signature,
        'didSignature': didSignature,
        'timesStamp': timesStamp,
      };

  // fromJson
  factory MementoClaimRequest.fromJson(Map<String, dynamic> json) {
    return MementoClaimRequest(
      claimId: json['claimId'],
      shareCode: json['shareCode'],
      receivingAddress: json['receivingAddress'],
      receivingPublicKey: json['receivingPublicKey'],
      did: json['did'],
      signature: json['signature'],
      didSignature: json['didSignature'],
      timesStamp: json['timesStamp'],
    );
  }
}

class MementoClaimResponse {}

class MementoGetInfoRequest {
  String shareCode;

  MementoGetInfoRequest({required this.shareCode});

  //toJson
  Map<String, dynamic> toJson() => {
        'shareCode': shareCode,
      };

  // fromJson
  factory MementoGetInfoRequest.fromJson(Map<String, dynamic> json) {
    return MementoGetInfoRequest(
      shareCode: json['shareCode'],
    );
  }
}

class MementoGetInfoResponse {
  String shareCode;
  String tokenId;
  String imageCID;

  MementoGetInfoResponse(
      {required this.shareCode, required this.tokenId, required this.imageCID});

  //toJson
  Map<String, dynamic> toJson() => {
        'shareCode': shareCode,
        'tokenId': tokenId,
        'imageCID': imageCID,
      };

  // fromJson
  factory MementoGetInfoResponse.fromJson(Map<String, dynamic> json) {
    return MementoGetInfoResponse(
      shareCode: json['shareCode'],
      tokenId: json['tokenId'],
      imageCID: json['imageCID'],
    );
  }
}

class MementoShareRequest {
  String tokenId;
  String address;
  String publicKey;
  String timesStamp;
  String signature;

  MementoShareRequest(
      {required this.tokenId,
      required this.address,
      required this.publicKey,
      required this.signature,
      required this.timesStamp});

  //toJson
  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'address': address,
        'publicKey': publicKey,
        'timesStamp': timesStamp,
        'signature': signature,
      };

  // fromJson
  factory MementoShareRequest.fromJson(Map<String, dynamic> json) {
    return MementoShareRequest(
      tokenId: json['tokenId'],
      address: json['address'],
      publicKey: json['publicKey'],
      timesStamp: json['timesStamp'],
      signature: json['signature'],
    );
  }
}

class MementoShareRespone {
  String deepLink;

  MementoShareRespone({required this.deepLink});

  //toJson
  Map<String, dynamic> toJson() => {
        'deepLink': deepLink,
      };

  // fromJson
  factory MementoShareRespone.fromJson(Map<String, dynamic> json) {
    return MementoShareRespone(
      deepLink: json['deepLink'],
    );
  }
}
