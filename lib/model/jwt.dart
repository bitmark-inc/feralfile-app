//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/jwt.dart';
import 'package:collection/collection.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:system_date_time_format/system_date_time_format.dart';

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

  String get mixpanelName {
    switch (this) {
      case MembershipType.free:
        return 'Free';
      case MembershipType.premium:
        return 'Premium';
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
      : expireIn = double.tryParse(json['expire_in'].toString())?.toInt(),
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
    final exp = (claim['membershipExpiry'] ?? 0) as int;
    final source =
        MembershipSource.fromString((claim['source'] ?? '') as String);
    final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return SubscriptionStatus(
        membership: membershipType,
        isTrial: isTrial,
        expireDate: expDate,
        source: source);
  }

  @override
  String toString() => jwtToken;
}

enum MembershipSource {
  purchase,
  webPurchase,
  giftCode,
  preset;

  String get name {
    switch (this) {
      case MembershipSource.purchase:
        return 'in_app_purchase';
      case MembershipSource.giftCode:
        return 'gift_code';
      case MembershipSource.preset:
        return 'preset';
      case MembershipSource.webPurchase:
        return 'web_purchase';
    }
  }

  static MembershipSource? fromString(String name) {
    switch (name) {
      case 'purchase':
      case 'in_app_purchase':
        return MembershipSource.purchase;
      case 'gift_code':
        return MembershipSource.giftCode;
      case 'preset':
        return MembershipSource.preset;
      case 'web_purchase':
        return MembershipSource.webPurchase;
      default:
        return null;
    }
  }
}

class SubscriptionStatus {
  final MembershipType membership;
  final bool isTrial;
  final MembershipSource? source;
  final DateTime? expireDate;

  SubscriptionStatus(
      {required this.membership,
      required this.isTrial,
      required this.source,
      this.expireDate});

  bool isExpired() => expireDate?.isBefore(DateTime.now()) ?? true;

  bool get isPremium => membership == MembershipType.premium && !isExpired();

  @override
  String toString() => 'SubscriptionStatus{plan: $membership, '
      'isTrial: $isTrial, expireDate: $expireDate, source: $source}';

  ProductDetails? get premiumProductDetails {
    final allProducts = injector<IAPService>().products.value.values.toList();
    return allProducts.firstWhereOrNull((element) => element.id == premiumId());
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
    final status = injector<IAPService>().purchases.value[productDetails.id];
    return status == IAPProductStatus.completed;
  }

  String? get expireDateFormatted {
    if (expireDate == null) {
      return null;
    }
    final context = injector<NavigationService>().context;
    final pattern = SystemDateTimeFormat.of(context);
    return DateFormat(pattern.mediumDatePattern).format(expireDate!);
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
