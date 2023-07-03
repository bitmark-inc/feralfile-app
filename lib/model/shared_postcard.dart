//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';

@JsonSerializable()
class SharedPostcard {
  final String tokenID;
  final String owner;
  final DateTime? sharedAt;

  SharedPostcard(this.tokenID, this.owner, this.sharedAt);

  // override operator ==
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedPostcard &&
          runtimeType == other.runtimeType &&
          tokenID == other.tokenID &&
          owner == other.owner;

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
    return sharedAt!
        .add(POSTCARD_SHARE_LINK_VALID_DURATION)
        .isBefore(DateTime.now());
  }

  @override
  int get hashCode {
    return tokenID.hashCode ^ owner.hashCode;
  }
}

extension ListSharedPostcard on List<SharedPostcard> {
  Future<List<SharedPostcard>> get expiredPostcards async {
    final expiredPostcards = <SharedPostcard>[];
    await Future.forEach(this, (SharedPostcard postcard) async {
      if (postcard.isExpired) {
        final token = await injector<AssetTokenDao>()
            .findAssetTokenByIdAndOwner(postcard.tokenID, postcard.owner);
        if (token != null &&
            token.getArtists.lastOrNull?.id == postcard.owner) {
          expiredPostcards.add(postcard);
        }
      }
    });
    return expiredPostcards;
  }
}

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <Id>{};
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}
