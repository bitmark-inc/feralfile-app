//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/jwt.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';
import 'package:collection/collection.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum MembershipType {
  free,
  premium;

  String get name {
    switch (this) {
      case MembershipType.free:
        return 'none';
      case MembershipType.premium:
        return 'premium';
    }
  }

  static MembershipType fromString(String name) {
    switch (name) {
      case 'premium':
      case 'foundation':
        return MembershipType.premium;
      case 'none':
      default:
        return MembershipType.free;
    }
  }
}

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

  bool _isValid() {
    final claim = parseJwt(jwtToken);
    final exp = (claim['exp'] ?? 0) as int;
    final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return expDate.isAfter(DateTime.now());
  }

  MembershipType _getMembershipType() {
    final claim = parseJwt(jwtToken);
    final membership = claim['membership'] as String;
    return MembershipType.values
        .firstWhere((e) => e == MembershipType.fromString(membership));
  }

  bool isPremiumValid() {
    final membership = _getMembershipType();
    return _isValid() && membership == MembershipType.premium;
  }

  bool isValid({bool withSubscription = false}) {
    final isJWTvalid = _isValid();

    if (withSubscription && isJWTvalid) {
      final membership = _getMembershipType();
      return membership != MembershipType.free;
    }

    return isJWTvalid;
  }

  SubscriptionStatus getSubscriptionStatus() {
    final claim = parseJwt(jwtToken);
    final membershipType =
        MembershipType.fromString(claim['membership'] as String);
    final isTrial = (claim['trial'] as bool?) == true;
    final exp = (claim['exp'] ?? 0) as int;
    final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return SubscriptionStatus(
        membership: membershipType, isTrial: isTrial, expireDate: expDate);
  }

  @override
  String toString() => jwtToken;
}

class SubscriptionStatus {
  final MembershipType membership;
  final bool isTrial;
  final DateTime expireDate;

  SubscriptionStatus(
      {required this.membership,
      required this.isTrial,
      required this.expireDate});

  bool _isExpired() => expireDate.isBefore(DateTime.now());

  bool get isPremium => membership == MembershipType.premium && !_isExpired();

  @override
  String toString() => 'SubscriptionStatus{plan: $membership, '
      'isTrial: $isTrial, expireDate: $expireDate}';

  ProductDetails? get premiumProductDetails {
    final allProducts = injector<IAPService>().products.value.values.toList();
    return allProducts
        .firstWhereOrNull((element) => element.customID == premiumCustomId());
  }

  ProductDetails? get productDetails {
    switch (membership) {
      case MembershipType.free:
        return null;
      case MembershipType.premium:
        return premiumProductDetails;
    }
  }

  bool status(ProductDetails productDetails) {
    final status =
        injector<IAPService>().purchases.value[productDetails.customID];
    return status == IAPProductStatus.completed;
  }
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
