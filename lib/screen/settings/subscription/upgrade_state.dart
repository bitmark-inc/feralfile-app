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

class UpgradePurchaseEvent extends UpgradeEvent {}

class UpgradeUpdateEvent extends UpgradeEvent {
  final UpgradeState newState;

  UpgradeUpdateEvent(this.newState);
}

class UpgradeState {
  final IAPProductStatus status;
  final ProductDetails? productDetails;
  final DateTime? trialExpiredDate;

  UpgradeState(this.status, this.productDetails, {this.trialExpiredDate});
}
