//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sentry/sentry.dart';

class UpgradesBloc extends AuBloc<UpgradeEvent, UpgradeState> {
  final IAPService _iapService;
  final ConfigurationService _configurationService;

  UpgradesBloc(this._iapService, this._configurationService)
      : super(UpgradeState(subscriptionDetails: [])) {
    // Query IAP info initially
    on<UpgradeQueryInfoEvent>((event, emit) async {
      // get JWT from configuration service
      try {
        final jwt = _configurationService.getIAPJWT();

        if (jwt != null) {
          // update purchase status in IAP service
          final subscriptionStatus = jwt.getSubscriptionStatus();
          if (subscriptionStatus.isPremium) {
            // if subscription is premium, update purchase in IAP service
            final id = premiumId();
            _iapService.purchases.value[id] = subscriptionStatus.isTrial
                ? IAPProductStatus.trial
                : IAPProductStatus.completed;
          } else {
            // if subscription is free, update purchase in IAP service
          }

          // after updating purchase status, emit new state
          emit(UpgradeState(
            subscriptionDetails: listSubscriptionDetails,
            membershipSource: subscriptionStatus.source,
          ));
        } else {
          // if no JWT, query IAP info
          _onNewIAPEventFunc();
        }
      } catch (error) {
        log.info('UpgradeQueryInfoEvent error');
        emit(UpgradeState(subscriptionDetails: []));
      }
    });

// Return IAP info after getting from Apple / Google
    on<UpgradeIAPInfoEvent>((event, emit) async {
      // get list of subscription details from IAP service
      final subscriptionDetals = listSubscriptionDetails;
      emit(UpgradeState(
        subscriptionDetails: subscriptionDetals,
        membershipSource: state.membershipSource,
      ));
    });

// Purchase event
    on<UpgradePurchaseEvent>((event, emit) async {
      emit(UpgradeState(
          subscriptionDetails: state.subscriptionDetails, isProcessing: true));
      final listSubscriptionDetails = state.subscriptionDetails;
      final subscriptionIds = event.subscriptionIds;
      for (final subscriptionId in subscriptionIds) {
        final subscriptionProductDetails =
            _iapService.products.value[subscriptionId];
        if (subscriptionProductDetails != null) {
          try {
            await _iapService.purchase(subscriptionProductDetails);
            final index = listSubscriptionDetails.indexWhere((element) =>
                element.productDetails == subscriptionProductDetails);
            listSubscriptionDetails[index] = SubscriptionDetails(
                IAPProductStatus.pending, subscriptionProductDetails);
          } catch (error) {
            log.warning('Trigger purchase error: $error');
          }
        } else {
          unawaited(Sentry.captureException('No item to purchase'));
          log.warning('No item to purchase');
        }
      }
      emit(UpgradeState(
        subscriptionDetails: listSubscriptionDetails,
        membershipSource: state.membershipSource,
      ));
    });

    _iapService.purchases.addListener(_onNewIAPEventFunc);
    _iapService.products.addListener(_onNewIAPEventFunc);
  }

  void _onNewIAPEventFunc() {
    log.info('UpgradeBloc: _onNewIAPEventFunc');
    add(UpgradeIAPInfoEvent());
  }

  List<SubscriptionDetails> get listSubscriptionDetails {
    final subscriptionDetals = <SubscriptionDetails>[];
    final listProductDetails = _iapService.products.value.values.toList();
    for (final productDetails in listProductDetails) {
      IAPProductStatus subscriptionState = IAPProductStatus.loading;
      DateTime? trialExpireDate;
      subscriptionState = _iapService.purchases.value[productDetails.id] ??
          IAPProductStatus.notPurchased;
      if (subscriptionState == IAPProductStatus.trial) {
        trialExpireDate = _iapService.trialExpireDates.value[productDetails.id];
      }
      subscriptionDetals.add(SubscriptionDetails(
        subscriptionState,
        productDetails,
        trialExpiredDate: trialExpireDate,
        purchaseDetails: _iapService.getPurchaseDetails(productDetails.id),
      ));
    }
    return subscriptionDetals;
  }

  Future<IAPProductStatus> getSubscriptionStatus(
      ProductDetails productDetails) async {
    try {
      final productId = productDetails.id;
      final subscriptionProductDetails = _iapService.products.value[productId];
      if (subscriptionProductDetails != null) {
        await _iapService.purchase(subscriptionProductDetails);
        return IAPProductStatus.pending;
      } else {
        throw Exception('Product not found');
      }
    } catch (error) {
      log.warning(error);
      return IAPProductStatus.error;
    }
  }

  @override
  Future<void> close() {
    _iapService.purchases.removeListener(_onNewIAPEventFunc);
    _iapService.products.removeListener(_onNewIAPEventFunc);
    return super.close();
  }
}
