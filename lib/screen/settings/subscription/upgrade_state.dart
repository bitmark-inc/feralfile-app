//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/subscription_details_ext.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class UpgradeEvent {}

class UpgradeQueryInfoEvent extends UpgradeEvent {}

class UpgradeIAPInfoEvent extends UpgradeEvent {}

class UpgradePurchaseEvent extends UpgradeEvent {
  final List<String> subscriptionIds;

  UpgradePurchaseEvent(this.subscriptionIds);
}

class SubscriptionDetails {
  IAPProductStatus status;
  final ProductDetails productDetails;
  final DateTime? trialExpiredDate;
  final PurchaseDetails? purchaseDetails;

  SubscriptionDetails(this.status, this.productDetails,
      {this.trialExpiredDate, this.purchaseDetails});
}

class UpgradeState {
  List<SubscriptionDetails> subscriptionDetails;
  bool isProcessing;
  final MembershipSource? membershipSource;
  final String? stripePortalUrl;

  UpgradeState({
    this.subscriptionDetails = const [],
    this.isProcessing = false,
    this.membershipSource,
    this.stripePortalUrl,
  });

  List<SubscriptionDetails> get activeSubscriptionDetails =>
      subscriptionDetails.activeSubscriptionDetails;

  UpgradeState copyWith({
    List<SubscriptionDetails>? subscriptionDetails,
    bool? isProcessing,
    MembershipSource? membershipSource,
    String? stripePortalUrl,
  }) =>
      UpgradeState(
        subscriptionDetails: subscriptionDetails ?? this.subscriptionDetails,
        isProcessing: isProcessing ?? false,
        membershipSource: membershipSource ?? this.membershipSource,
        stripePortalUrl: stripePortalUrl ?? this.stripePortalUrl,
      );
}
