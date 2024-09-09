//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'wc2_request.g.dart';

class Wc2PermissionsRequestParams {
  Wc2PermissionsRequestParams({
    required this.message,
    required this.permissions,
    required this.account,
  });

  String message;
  List<Wc2Permission> permissions;
  String account;

  factory Wc2PermissionsRequestParams.fromJson(Map<String, dynamic> json) =>
      Wc2PermissionsRequestParams(
        message: json['message'],
        permissions: List<Wc2Permission>.from(
            json['permissions'].map((x) => Wc2Permission.fromJson(x))),
        account: json['account'],
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'permissions': List<dynamic>.from(permissions.map((x) => x.toJson())),
        'account': account,
      };
}

class Wc2Permission {
  Wc2Permission({
    required this.type,
    required this.request,
    this.includeLinkedAccount,
  });

  String type;
  bool? includeLinkedAccount;
  Wc2ChainsPermissionRequest request;

  factory Wc2Permission.fromJson(Map<String, dynamic> json) => Wc2Permission(
        type: json['type'],
        includeLinkedAccount: json['includeLinkedAccount'],
        request: Wc2ChainsPermissionRequest.fromJson(json['request']),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'includeLinkedAccount': includeLinkedAccount,
        'request': request.toJson(),
      };
}

class Wc2ChainsPermissionRequest {
  Wc2ChainsPermissionRequest({
    required this.chains,
  });

  List<String> chains;

  factory Wc2ChainsPermissionRequest.fromJson(Map<String, dynamic> json) =>
      Wc2ChainsPermissionRequest(
        chains: List<String>.from(json['chains'].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        'chains': List<dynamic>.from(chains.map((x) => x)),
      };
}

class Wc2SignRequestParams {
  Wc2SignRequestParams({
    required this.chain,
    required this.address,
    required this.message,
  });

  String chain;
  String address;
  String message;

  factory Wc2SignRequestParams.fromJson(Map<String, dynamic> json) =>
      Wc2SignRequestParams(
        chain: json['chain'],
        address: json['address'],
        message: json['message'],
      );

  Map<String, dynamic> toJson() => {
        'chain': chain,
        'address': address,
        'message': message,
      };
}

class Wc2SendRequestParams {
  Wc2SendRequestParams({
    required this.chain,
    required this.address,
    required this.transactions,
  });

  String chain;
  String address;
  Map<String, dynamic> transactions;

  factory Wc2SendRequestParams.fromJson(Map<String, dynamic> json) =>
      Wc2SendRequestParams(
        chain: json['chain'],
        address: json['address'],
        transactions: json['transactions'],
      );

  Map<String, dynamic> toJson() => {
        'chain': chain,
        'address': address,
        'transactions': transactions,
      };
}

@JsonSerializable()
class Wc2PermissionResponse {
  final String signature;
  final List<Wc2PermissionResult> permissionResults;

  Wc2PermissionResponse({
    required this.signature,
    required this.permissionResults,
  });

  factory Wc2PermissionResponse.fromJson(Map<String, dynamic> json) =>
      _$Wc2PermissionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$Wc2PermissionResponseToJson(this);
}

@JsonSerializable()
class Wc2PermissionResult {
  final String type;
  final Wc2ChainResult result;

  Wc2PermissionResult({
    required this.type,
    required this.result,
  });

  factory Wc2PermissionResult.fromJson(Map<String, dynamic> json) =>
      _$Wc2PermissionResultFromJson(json);

  Map<String, dynamic> toJson() => _$Wc2PermissionResultToJson(this);
}

@JsonSerializable()
class Wc2ChainResult {
  final List<Wc2Chain> chains;

  Wc2ChainResult({
    required this.chains,
  });

  factory Wc2ChainResult.fromJson(Map<String, dynamic> json) =>
      _$Wc2ChainResultFromJson(json);

  Map<String, dynamic> toJson() => _$Wc2ChainResultToJson(this);
}

@JsonSerializable()
class Wc2Chain {
  static const ethereum = 'eip155';
  static const tezos = 'tezos';

  final String chain;
  final String address;
  final String? publicKey;
  final String? signature;

  Wc2Chain({
    required this.chain,
    required this.address,
    this.publicKey,
    this.signature,
  });

  factory Wc2Chain.fromJson(Map<String, dynamic> json) =>
      _$Wc2ChainFromJson(json);

  Map<String, dynamic> toJson() => _$Wc2ChainToJson(this);
}
