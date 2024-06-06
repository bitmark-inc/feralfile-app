//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

const List<String> _kAppleProductIds = <String>[
  'Au_IntroSub',
];

const List<String> _kGoogleProductIds = <String>[
  'com.bitmark.autonomy_client.subscribe',
];

enum IAPProductStatus {
  loading,
  notPurchased,
  pending,
  expired,
  error,
  trial,
  completed,
}

abstract class IAPService {
  late ValueNotifier<Map<String, ProductDetails>> products;
  late ValueNotifier<Map<String, IAPProductStatus>> purchases;
  late ValueNotifier<Map<String, DateTime>> trialExpireDates;

  Future<void> setup();

  Future<void> purchase(ProductDetails product);

  Future<void> restore();

  Future<bool> renewJWT();

  Future<bool> isSubscribed();
}

class IAPServiceImpl implements IAPService {
  final ConfigurationService _configurationService;
  final AuthService _authService;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  ValueNotifier<Map<String, ProductDetails>> products = ValueNotifier({});
  @override
  ValueNotifier<Map<String, IAPProductStatus>> purchases = ValueNotifier({});
  @override
  ValueNotifier<Map<String, DateTime>> trialExpireDates = ValueNotifier({});

  IAPServiceImpl(this._configurationService, this._authService) {
    unawaited(setup());
  }

  String? _receiptData;
  bool _isSetup = false;

  @override
  Future<void> setup() async {
    if (_isSetup) {
      return;
    }

    _isSetup = true;

    // Waiting for IAP available
    await _inAppPurchase.isAvailable();

    final jwt = _configurationService.getIAPJWT();
    if (jwt != null && jwt.isValid(withSubscription: true)) {}
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      log.info('[IAPService] finish fetching iap tiers');
      _subscription.cancel();
    }, onError: (error) {
      log.severe(error);
    });

    final List<String> productIds;

    if (Platform.isIOS) {
      productIds = _kAppleProductIds;

      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
    } else {
      productIds = _kGoogleProductIds;
    }

    await _cleanupPendingTransactions();

    ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(productIds.toSet());
    if (productDetailResponse.error != null) {
      return;
    }

    products.value = {
      for (var e in productDetailResponse.productDetails) e.id: e
    };
  }

  @override
  Future<bool> renewJWT() async {
    final receiptData = _configurationService.getIAPReceipt();
    if (receiptData == null) {
      unawaited(_configurationService.setIAPJWT(null));
      return false;
    }

    final jwt = await _verifyPurchase(receiptData);
    if (jwt == null || !jwt.isValid(withSubscription: true)) {
      unawaited(_configurationService.setIAPJWT(null));
      return false;
    }
    unawaited(_configurationService.setIAPJWT(jwt));
    return true;
  }

  @override
  Future<void> purchase(ProductDetails product) async {
    if (!(await _inAppPurchase.isAvailable())) {
      return;
    }
    final purchaseParam = PurchaseParam(
      productDetails: product,
    );

    log.info('[IAPService] purchase: ${product.id}');

    await _cleanupPendingTransactions();

    log.info('[IAPService] buy non comsumable: ${product.id}');
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restore() async {
    log.info('[IAPService] restore purchases');
    if (!(await _inAppPurchase.isAvailable()) || await isAppCenterBuild()) {
      return;
    }
    await _inAppPurchase.restorePurchases();
  }

  Future<JWT?> _verifyPurchase(String receiptData) async {
    try {
      final jwt = await _authService.getAuthToken(
          receiptData: receiptData, forceRefresh: true);
      return jwt;
    } catch (error) {
      log.info('[IAPService] error when verifying receipt', error);
      unawaited(_configurationService.setIAPReceipt(null));
      return null;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    if (purchaseDetailsList.isEmpty) {
      // Remove purchase status
      unawaited(_configurationService.setIAPReceipt(null));
      unawaited(_configurationService.setPremium(false));
      return;
    }

    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      log.info('[IAPService] purchase: ${purchaseDetails.productID},'
          ' status: ${purchaseDetails.status.name}');

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }

      if (purchaseDetails.status == PurchaseStatus.pending) {
        purchases.value[purchaseDetails.productID] = IAPProductStatus.pending;
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        purchases.value[purchaseDetails.productID] =
            IAPProductStatus.notPurchased;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          purchases.value[purchaseDetails.productID] = IAPProductStatus.error;
          log.warning(
              "[IAPService] error: ${purchaseDetails.error?.message ?? ""}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final receiptData =
              purchaseDetails.verificationData.serverVerificationData;
          if (_receiptData == receiptData) {
            // Prevent duplicated events.
            return;
          }
          _receiptData = receiptData;
          final jwt = await _verifyPurchase(receiptData);
          final subscriptionStatus = jwt?.getSubscriptionStatus();
          log
            ..info('[IAPService] subscription: $subscriptionStatus')
            ..info('[IAPService] verifying the receipt');
          if (subscriptionStatus?.isPremium == true) {
            unawaited(_configurationService.setIAPJWT(jwt));
            if (!_configurationService.isPremium()) {
              unawaited(_configurationService.setPremium(true));
            }
            final status = subscriptionStatus!;
            if (status.isTrial) {
              purchases.value[purchaseDetails.productID] =
                  IAPProductStatus.trial;
              trialExpireDates.value[purchaseDetails.productID] =
                  status.expireDate;
            } else {
              purchases.value[purchaseDetails.productID] =
                  IAPProductStatus.completed;
              if (purchaseDetails.status == PurchaseStatus.purchased) {
                unawaited(injector<ConfigurationService>()
                    .setSubscriptionTime(DateTime.now()));
              }
            }
            purchases.notifyListeners();
          } else {
            log.info('[IAPService] the receipt is invalid');
            unawaited(_configurationService.setPremium(false));
            purchases.value[purchaseDetails.productID] =
                IAPProductStatus.expired;
            unawaited(_configurationService.setIAPReceipt(null));
            unawaited(_cleanupPendingTransactions());
            purchases.notifyListeners();
            return;
          }
        }
      }
      purchases.notifyListeners();
    });
  }

  @override
  Future<bool> isSubscribed() async {
    final jwt = _configurationService.getIAPJWT();
    return jwt != null && jwt.isValid(withSubscription: true);
  }

  Future _cleanupPendingTransactions() async {
    if (Platform.isIOS) {
      var transactions = await SKPaymentQueueWrapper().transactions();
      log.info('[IAPService] cleaning up pending transactions: '
          '${transactions.length}');

      if (transactions.isNotEmpty) {
        for (var transaction in transactions) {
          log.info('[IAPService] cleaning up transaction: $transaction');
          unawaited(SKPaymentQueueWrapper().finishTransaction(transaction));
        }

        await Future.delayed(const Duration(seconds: 3));
        log.info('[IAPService] finish cleaning up');
      }
    }
  }
}

class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction,
          SKStorefrontWrapper storefront) =>
      true;

  @override
  bool shouldShowPriceConsent() => false;
}
