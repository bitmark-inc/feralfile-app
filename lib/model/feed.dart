//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'feed.g.dart';

@JsonSerializable()
class FeedData {
  @JsonKey(defaultValue: [])
  List<FeedEvent> events;
  FeedNext next;

  FeedData({
    required this.events,
    required this.next,
  });

  factory FeedData.fromJson(Map<String, dynamic> json) =>
      _$FeedDataFromJson(json);

  Map<String, dynamic> toJson() => _$FeedDataToJson(this);
}

@JsonSerializable()
class FollowingData {
  @JsonKey(name: "following", defaultValue: [])
  List<Following> followings;
  FeedNext next;

  FollowingData({
    required this.followings,
    required this.next,
  });

  factory FollowingData.fromJson(Map<String, dynamic> json) =>
      _$FollowingDataFromJson(json);

  Map<String, dynamic> toJson() => _$FollowingDataToJson(this);
}

@JsonSerializable()
class Following {
  String address;
  DateTime timestamp;

  Following({
    required this.address,
    required this.timestamp,
  });

  factory Following.fromJson(Map<String, dynamic> json) =>
      _$FollowingFromJson(json);

  Map<String, dynamic> toJson() => _$FollowingToJson(this);
}

@JsonSerializable()
class FeedNext {
  String timestamp;
  String serial;

  FeedNext({
    required this.timestamp,
    required this.serial,
  });

  factory FeedNext.fromJson(Map<String, dynamic> json) =>
      _$FeedNextFromJson(json);

  Map<String, dynamic> toJson() => _$FeedNextToJson(this);
}

@JsonSerializable()
class FeedEvent {
  String id;
  String chain;
  String contract;
  @JsonKey(name: "token")
  String tokenID;
  String recipient;
  String action;
  DateTime timestamp;

  FeedEvent({
    required this.id,
    required this.chain,
    required this.contract,
    required this.tokenID,
    required this.recipient,
    required this.action,
    required this.timestamp,
  });

  factory FeedEvent.fromJson(Map<String, dynamic> json) =>
      _$FeedEventFromJson(json);

  Map<String, dynamic> toJson() => _$FeedEventToJson(this);

  String get uniqueKey {
    return "${chain}_${contract}_${tokenID}_$recipient";
  }
}

extension FeedEventHelpers on FeedEvent {
  String get indexerID {
    try {
      switch (chain) {
        case 'ethereum':
          return "eth-$contract-${BigInt.parse(tokenID).toRadixString(16)}";
        case 'tezos':
          return "tez-$contract-$tokenID";
        case 'bitmark':
          return 'bmrk--$tokenID';
        default:
          return '';
      }
    } catch (exception) {
      return '';
    }
  }

  String get actionRepresentation {
    switch (action) {
      case "mint":
        return "minted";
      default:
        return "collected";
    }
  }
}
