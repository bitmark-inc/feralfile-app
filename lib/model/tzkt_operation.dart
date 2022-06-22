//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'tzkt_operation.g.dart';

@JsonSerializable()
class TZKTOperation {
  String type;
  int id;
  int level;
  DateTime timestamp;
  String block;
  String hash;
  int counter;
  TZKTActor? sender;
  TZKTActor? initiator;
  int gasLimit;
  int gasUsed;
  int storageLimit;
  int storageUsed;
  int bakerFee;
  int storageFee;
  int allocationFee;
  TZKTActor? target;
  int amount;
  String? status;
  bool hasInternals;
  TZKTQuote quote;
  TZKTParameter? parameter;

  TZKTOperation({
    required this.type,
    required this.id,
    required this.level,
    required this.timestamp,
    required this.block,
    required this.hash,
    required this.counter,
    this.initiator,
    this.sender,
    this.target,
    required this.gasLimit,
    required this.gasUsed,
    required this.storageLimit,
    required this.storageUsed,
    required this.bakerFee,
    required this.storageFee,
    required this.allocationFee,
    required this.amount,
    this.status,
    required this.hasInternals,
    required this.quote,
    this.parameter,
  });

  factory TZKTOperation.fromJson(Map<String, dynamic> json) =>
      _$TZKTOperationFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTOperationToJson(this);
}

@JsonSerializable()
class TZKTActor {
  String address;

  TZKTActor({required this.address});

  factory TZKTActor.fromJson(Map<String, dynamic> json) =>
      _$TZKTActorFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTActorToJson(this);
}

@JsonSerializable()
class TZKTQuote {
  double usd;

  TZKTQuote({required this.usd});

  factory TZKTQuote.fromJson(Map<String, dynamic> json) =>
      _$TZKTQuoteFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTQuoteToJson(this);
}

@JsonSerializable()
class TZKTParameter {
  String entrypoint;
  Object? value;

  TZKTParameter({required this.entrypoint, required this.value});

  factory TZKTParameter.fromJson(Map<String, dynamic> json) =>
      _$TZKTParameterFromJson(json);

  Map<String, dynamic> toJson() => _$TZKTParameterToJson(this);
}
