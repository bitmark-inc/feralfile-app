//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'request_response.g.dart';

@JsonSerializable()
class SharePostcardResponse {
  String? deeplink;

  SharePostcardResponse({this.deeplink});

  factory SharePostcardResponse.fromJson(Map<String, dynamic> json) =>
      _$SharePostcardResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SharePostcardResponseToJson(this);
}

@JsonSerializable()
class SharePostcardRequest {
  String? tokenId;
  String? signature;

  SharePostcardRequest({this.tokenId, this.signature});

  factory SharePostcardRequest.fromJson(Map<String, dynamic> json) =>
      _$SharePostcardRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SharePostcardRequestToJson(this);
}

@JsonSerializable()
class SharedPostcardInfor {
  String shareCode;
  String tokenID;
  String id;
  String status;

  SharedPostcardInfor(
      {required this.shareCode,
      required this.tokenID,
      required this.id,
      required this.status});

  factory SharedPostcardInfor.fromJson(Map<String, dynamic> json) {
    return SharedPostcardInfor(
      shareCode: json['shareCode'] as String,
      tokenID: json['tokenID'] as String,
      id: json['id'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareCode': shareCode,
      'tokenID': tokenID,
      'id': id,
      'status': status,
    };
  }
}
