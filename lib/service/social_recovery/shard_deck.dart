//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'shard_deck.g.dart';

@JsonSerializable()
class ShardDeck {
  ShardInfo defaultAccount;
  List<ShardInfo> otherAccounts;

  ShardDeck({
    required this.defaultAccount,
    required this.otherAccounts,
  });

  factory ShardDeck.fromJson(Map<String, dynamic> json) =>
      _$ShardDeckFromJson(json);

  Map<String, dynamic> toJson() => _$ShardDeckToJson(this);
}

@JsonSerializable()
class ShardInfo {
  String uuid;
  String shard;

  ShardInfo({
    required this.uuid,
    required this.shard,
  });

  factory ShardInfo.fromJson(Map<String, dynamic> json) =>
      _$ShardInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ShardInfoToJson(this);
}

@JsonSerializable()
class ContactDeck {
  String uuid;
  String name;
  ShardDeck deck;
  DateTime createdAt;

  ContactDeck({
    required this.uuid,
    required this.name,
    required this.deck,
    required this.createdAt,
  });

  factory ContactDeck.fromJson(Map<String, dynamic> json) =>
      _$ContactDeckFromJson(json);

  Map<String, dynamic> toJson() => _$ContactDeckToJson(this);
}
