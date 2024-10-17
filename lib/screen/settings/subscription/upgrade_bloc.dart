//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/jwt.dart';
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

        log.info('UpgradeBloc: jwt is ${jwt == null ? 'null' : 'not null'}');

        if (jwt != null) {
          // update purchase status in IAP service
          final subscriptionStatus = jwt.getSubscriptionStatus();
          log.info('UpgradeBloc: subscriptionStatus: $subscriptionStatus');
          final id = premiumId();
          if (subscriptionStatus.isPremium) {
            // if subscription is premium, update purchase in IAP service
            _iapService.purchases.value[id] = subscriptionStatus.isTrial
                ? IAPProductStatus.trial
                : IAPProductStatus.completed;
          } else {
            // if subscription is not premium, update purchase in IAP service
            _iapService.purchases.value[id] = subscriptionStatus.isExpired()
                ? IAPProductStatus.expired
                : IAPProductStatus.notPurchased;
          }

          final membershipSource = subscriptionStatus.source;
          if (membershipSource == MembershipSource.webPurchase) {
            final customSubscription =
                await _iapService.getCustomActiveSubscription();
            final webPurchaseProduct = ProductDetails(
              id: 'web_purchase',
              title: 'Web Purchase',
              description: 'Web Purchase',
              price: customSubscription.price,
              currencyCode: customSubscription.currency.toLowerCase(),
              rawPrice: customSubscription.rawPrice.toDouble(),
            );
            _iapService.products.value[webPurchaseProduct.id] =
                webPurchaseProduct;
            _iapService.purchases.value[webPurchaseProduct.id] =
                IAPProductStatus.completed;
          }
          final stripePortalUrl =
              membershipSource == MembershipSource.webPurchase
                  ? await injector<IAPService>().getStripeUrl()
                  : null;

          // after updating purchase status, emit new state
          emit(state.copyWith(
            subscriptionDetails: listSubscriptionDetails,
            membershipSource: membershipSource,
            stripePortalUrl: stripePortalUrl,
          ));
        } else {
          // if no JWT, query IAP info
          _onNewIAPEventFunc();
        }
      } catch (error) {
        log.info('UpgradeQueryInfoEvent error');
        emit(state.copyWith(subscriptionDetails: []));
      }
    });

// Return IAP info after getting from Apple / Google
    on<UpgradeIAPInfoEvent>((event, emit) async {
      // get list of subscription details from IAP service
      final subscriptionDetails = listSubscriptionDetails;
      emit(state.copyWith(
        subscriptionDetails: subscriptionDetails,
      ));
    });

// Purchase event
    on<UpgradePurchaseEvent>((event, emit) async {
      emit(state.copyWith(isProcessing: true));
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
      emit(state.copyWith(
        subscriptionDetails: listSubscriptionDetails,
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

  @override
  Future<void> close() {
    _iapService.purchases.removeListener(_onNewIAPEventFunc);
    _iapService.products.removeListener(_onNewIAPEventFunc);
    return super.close();
  }
}
