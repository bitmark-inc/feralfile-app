//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:json_annotation/json_annotation.dart';

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
  factory SharedPostcard.fromJson(Map<String, dynamic> json) => SharedPostcard(
        json['tokenID'] as String,
        json['owner'] as String,
        json['sharedAt'] == null
            ? null
            : DateTime.parse(json['sharedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'tokenID': tokenID,
        'owner': owner,
        'sharedAt': sharedAt?.toIso8601String(),
      };

  @override
  int get hashCode => tokenID.hashCode ^ owner.hashCode;
}

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <Id>{};
    var list = inplace ? this : List<E>.from(this)
      ..retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}
