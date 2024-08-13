//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class UpgradesBloc extends AuBloc<UpgradeEvent, UpgradeState> {
  final IAPService _iapService;
  final ConfigurationService _configurationService;

  UpgradesBloc(this._iapService, this._configurationService)
      : super(UpgradeState(IAPProductStatus.loading, null)) {
    // Query IAP info initially
    on<UpgradeQueryInfoEvent>((event, emit) async {
      final jwt = _configurationService.getIAPJWT();
      if (jwt != null) {
        final subscriptionStatus = jwt.getSubscriptionStatus();
        if (subscriptionStatus.isPremium) {
          if (subscriptionStatus.isTrial) {
            emit(
              UpgradeState(
                IAPProductStatus.trial,
                null,
                trialExpiredDate: subscriptionStatus.expireDate,
              ),
            );
          } else {
            emit(UpgradeState(IAPProductStatus.completed, null));
          }
        } else {
          final result = await _iapService.renewJWT();
          emit(UpgradeState(
              result
                  ? IAPProductStatus.completed
                  : IAPProductStatus.notPurchased,
              null));
        }
      } else {
        if (_iapService.products.value.isEmpty) {
          emit(UpgradeState(IAPProductStatus.loading, null));
        } else {
          _onNewIAPEventFunc();
        }
      }
    });

// Return IAP info after getting from Apple / Google
    on<UpgradeIAPInfoEvent>((event, emit) async {
      ProductDetails? productDetail;
      IAPProductStatus state = IAPProductStatus.loading;
      DateTime? trialExpireDate;

      if (_iapService.products.value.isNotEmpty) {
        final productId = _iapService.products.value.keys.first;
        productDetail = _iapService.products.value[productId];

        final subscriptionState = _iapService.purchases.value[productId];
        state = subscriptionState ?? IAPProductStatus.notPurchased;
        if (state == IAPProductStatus.trial) {
          trialExpireDate = _iapService.trialExpireDates.value[productId];
        }
      }

      emit(UpgradeState(state, productDetail,
          trialExpiredDate: trialExpireDate));
    });

// Update new state if needed
    on<UpgradeUpdateEvent>((event, emit) async {
      emit(event.newState);
    });

// Purchase event
    on<UpgradePurchaseEvent>((event, emit) async {
      try {
        final productId = _iapService.products.value.keys.first;
        final subscriptionProductDetails =
            _iapService.products.value[productId];
        if (subscriptionProductDetails != null) {
          await _iapService.purchase(subscriptionProductDetails);
          emit(UpgradeState(
              IAPProductStatus.pending, subscriptionProductDetails));
        } else {
          log.warning('No item to purchase');
        }
      } catch (error) {
        log.warning(error);
        emit(UpgradeState(IAPProductStatus.error, null));
      }
    });

    _iapService.purchases.addListener(_onNewIAPEventFunc);
    _iapService.products.addListener(_onNewIAPEventFunc);
  }

  void _onNewIAPEventFunc() {
    add(UpgradeIAPInfoEvent());
  }

  @override
  Future<void> close() {
    _iapService.purchases.removeListener(_onNewIAPEventFunc);
    _iapService.products.removeListener(_onNewIAPEventFunc);
    return super.close();
  }
}
