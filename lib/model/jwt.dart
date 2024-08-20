//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/jwt.dart';

class JWT {
  int? expireIn;
  String jwtToken;

  JWT({required this.jwtToken, this.expireIn});

  JWT.fromJson(Map<String, dynamic> json)
      : expireIn = json['expire_in'],
        jwtToken = json['jwt_token'];

  Map<String, dynamic> toJson() => {
        'expire_in': expireIn,
        'jwt_token': jwtToken,
      };

  bool isValid({bool withSubscription = false}) {
    final claim = parseJwt(jwtToken);
    final exp = (claim['exp'] ?? 0) as int;
    final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final value = expDate.compareTo(DateTime.now());
    if (withSubscription) {
      final plan = claim['membership'] as String;
      return value > 0 && plan == 'premium';
    }

    return value > 0;
  }

  SubscriptionStatus getSubscriptionStatus() {
    final claim = parseJwt(jwtToken);
    final plan = claim['membership'] as String;
    final isTrial = (claim['trial'] as bool?) == true;
    final exp = (claim['exp'] ?? 0) as int;
    final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return SubscriptionStatus(
        plan: plan, isTrial: isTrial, expireDate: expDate);
  }

  @override
  String toString() => jwtToken;
}

class SubscriptionStatus {
  final String plan;
  final bool isTrial;
  final DateTime expireDate;

  SubscriptionStatus(
      {required this.plan, required this.isTrial, required this.expireDate});

  bool get isPremium => plan == 'premium' && expireDate.isAfter(DateTime.now());

  @override
  String toString() => 'SubscriptionStatus{plan: $plan, '
      'isTrial: $isTrial, expireDate: $expireDate}';
}

class OnesignalIdentityHash {
  String hash;

  OnesignalIdentityHash({required this.hash});

  OnesignalIdentityHash.fromJson(Map<String, dynamic> json)
      : hash = json['hash'];

  Map<String, dynamic> toJson() => {
        'hash': hash,
      };
}
