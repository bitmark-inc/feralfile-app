//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:autonomy_flutter/util/constants.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class SharedPostcard {
  final String tokenID;
  final String owner;
  final DateTime? sharedAt;

  SharedPostcard(this.tokenID, this.owner, this.sharedAt);

  // fromJson method
  factory SharedPostcard.fromJson(Map<String, dynamic> json) {
    return SharedPostcard(
      json["tokenID"] as String,
      json["owner"] as String,
      json["sharedAt"] == null
          ? null
          : DateTime.parse(json["sharedAt"] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tokenID": tokenID,
      "owner": owner,
      "sharedAt": sharedAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    if (sharedAt == null) {
      return false;
    }
    return DateTime.now()
        .subtract(POSTCARD_SHARE_LINK_VALID_DURATION)
        .isAfter(sharedAt!);
  }
}
