//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class UpgradeEvent {}

class UpgradeQueryInfoEvent extends UpgradeEvent {}

class UpgradeIAPInfoEvent extends UpgradeEvent {}

class UpgradePurchaseEvent extends UpgradeEvent {
  final List<String> subscriptionIds;

  UpgradePurchaseEvent(this.subscriptionIds);
}

class SubscriptionDetails {
  final IAPProductStatus status;
  final ProductDetails productDetails;
  final DateTime? trialExpiredDate;
  final PurchaseDetails? purchaseDetails;

  SubscriptionDetails(this.status, this.productDetails,
      {this.trialExpiredDate, this.purchaseDetails});
}

class UpgradeState {
  List<SubscriptionDetails> subscriptionDetails;
  bool isProcessing;

  UpgradeState({this.subscriptionDetails = const [], this.isProcessing = false});

  List<SubscriptionDetails> get activeSubscriptionDetails {
    final activeSubscriptionDetails = <SubscriptionDetails>[];
    for (final subscriptionDetail in subscriptionDetails) {
      final shouldIgnoreOnUI =
          inactiveIds().contains(subscriptionDetail.productDetails.id) &&
              !(subscriptionDetail.status == IAPProductStatus.completed ||
                  subscriptionDetail.status == IAPProductStatus.trial &&
                      subscriptionDetail.trialExpiredDate != null &&
                      subscriptionDetail.trialExpiredDate!
                          .isBefore(DateTime.now()));
      if (!shouldIgnoreOnUI) {
        activeSubscriptionDetails.add(subscriptionDetail);
      }
    }
    return activeSubscriptionDetails;
  }
}
