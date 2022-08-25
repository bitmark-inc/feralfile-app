//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

class Wc2Request {
  Wc2Request({
    required this.id,
    required this.method,
    required this.topic,
    required this.params,
    required this.chainId,
  });

  int id;
  String method;
  String topic;
  Map<String, dynamic> params;
  String chainId;

  factory Wc2Request.fromJson(Map<String, dynamic> json) => Wc2Request(
        id: json["id"],
        method: json["method"],
        topic: json["topic"],
        params: json["params"],
        chainId: json["chainId"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "method": method,
        "topic": topic,
        "params": params,
        "chainId": chainId,
      };
}

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
        message: json["message"],
        permissions: List<Wc2Permission>.from(
            json["permissions"].map((x) => Wc2Permission.fromJson(x))),
        account: json["account"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "permissions": List<dynamic>.from(permissions.map((x) => x.toJson())),
        "account": account,
      };
}

class Wc2Permission {
  Wc2Permission({
    required this.type,
    required this.request,
  });

  String type;
  Wc2ChainsPermissionRequest request;

  factory Wc2Permission.fromJson(Map<String, dynamic> json) => Wc2Permission(
        type: json["type"],
        request: Wc2ChainsPermissionRequest.fromJson(json["request"]),
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "request": request.toJson(),
      };
}

class Wc2ChainsPermissionRequest {
  Wc2ChainsPermissionRequest({
    required this.chains,
  });

  List<String> chains;

  factory Wc2ChainsPermissionRequest.fromJson(Map<String, dynamic> json) =>
      Wc2ChainsPermissionRequest(
        chains: List<String>.from(json["chains"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "chains": List<dynamic>.from(chains.map((x) => x)),
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

  factory Wc2SignRequestParams.fromJson(Map<String, dynamic> json) => Wc2SignRequestParams(
    chain: json["chain"],
    address: json["address"],
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "chain": chain,
    "address": address,
    "message": message,
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

  factory Wc2SendRequestParams.fromJson(Map<String, dynamic> json) => Wc2SendRequestParams(
    chain: json["chain"],
    address: json["address"],
    transactions: json["transactions"],
  );

  Map<String, dynamic> toJson() => {
    "chain": chain,
    "address": address,
    "transactions": transactions,
  };
}
