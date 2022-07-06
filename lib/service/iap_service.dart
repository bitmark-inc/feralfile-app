//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';
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
  completed,
}

abstract class IAPService {
  late ValueNotifier<Map<String, ProductDetails>> products;
  late ValueNotifier<Map<String, IAPProductStatus>> purchases;

  Future<void> setup();
  Future<void> purchase(ProductDetails product);
  Future<void> restore();
  Future<bool> renewJWT();
  Future<bool> isSubscribed();
}

class IAPServiceImpl implements IAPService {
  ConfigurationService _configurationService;
  AuthService _authService;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  ValueNotifier<Map<String, ProductDetails>> products = ValueNotifier({});
  ValueNotifier<Map<String, IAPProductStatus>> purchases = ValueNotifier({});

  IAPServiceImpl(this._configurationService, this._authService) {
    setup();
  }
  String? _receiptData;
  bool _isSetup = false;

  Future<void> setup() async {
    if (_isSetup) {
      return;
    }

    _isSetup = true;

    final jwt = _configurationService.getIAPJWT();
    if (jwt != null && jwt.isValid(withSubscription: true)) {}
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      log.info("[IAPService] finish fetching iap tiers");
      _subscription.cancel();
    }, onError: (error) {
      log.severe(error);
    });

    final productIds;

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

    products.value = Map.fromIterable(productDetailResponse.productDetails,
        key: (e) => e.id, value: (e) => e);
  }

  Future<bool> renewJWT() async {
    final receiptData = _configurationService.getIAPReceipt();
    if (receiptData == null) {
      _configurationService.setIAPJWT(null);
      return false;
    }

    final jwt = await _verifyPurchase(receiptData);
    if (jwt == null || !jwt.isValid(withSubscription: true)) {
      _configurationService.setIAPJWT(null);
      return false;
    }
    _configurationService.setIAPJWT(jwt);
    return true;
  }

  Future<void> purchase(ProductDetails product) async {
    if (await _inAppPurchase.isAvailable() == false) return;
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: null,
    );

    log.info("[IAPService] purchase: ${product.id}");

    await _cleanupPendingTransactions();

    log.info("[IAPService] buy non comsumable: ${product.id}");
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() async {
    log.info("[IAPService] restore purchases");
    if (await _inAppPurchase.isAvailable() == false ||
        kDebugMode ||
        await isAppCenterBuild()) return;
    await _inAppPurchase.restorePurchases();
  }

  Future<JWT?> _verifyPurchase(String receiptData) async {
    try {
      final jwt = await _authService.getAuthToken(
          receiptData: receiptData, forceRefresh: true);
      return jwt;
    } catch (error) {
      log.info("[IAPService] error when verifying receipt", error);
      _configurationService.setIAPReceipt(null);
      return null;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    if (purchaseDetailsList.isEmpty) {
      // Remove purchase status
      _configurationService.setIAPJWT(null);
      _configurationService.setIAPReceipt(null);
      return;
    }

    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      log.info(
          "[IAPService] purchase: ${purchaseDetails.productID}, status: ${purchaseDetails.status.name}");
      if (purchaseDetails.status == PurchaseStatus.pending) {
        purchases.value[purchaseDetails.productID] = IAPProductStatus.pending;
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
          log.info("[IAPService] verifying the receipt");
          if (jwt != null && jwt.isValid(withSubscription: true)) {
            purchases.value[purchaseDetails.productID] =
                IAPProductStatus.completed;
            _configurationService.setIAPJWT(jwt);
            log.info("[IAPService] the receipt is valid");
          } else {
            log.info("[IAPService] the receipt is invalid");
            purchases.value[purchaseDetails.productID] =
                IAPProductStatus.expired;
            _configurationService.setIAPJWT(null);
            _cleanupPendingTransactions();
            return;
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
      purchases.notifyListeners();
    });
  }

  Future<bool> isSubscribed() async {
    final jwt = _configurationService.getIAPJWT();
    return (jwt != null && jwt.isValid(withSubscription: true)) ||
        await isAppCenterBuild();
  }

  Future _cleanupPendingTransactions() async {
    if (Platform.isIOS) {
      var transactions = await SKPaymentQueueWrapper().transactions();
      log.info(
          "[IAPService] cleaning up pending transactions: ${transactions.length}");

      if (transactions.length > 0) {
        transactions.forEach((transaction) {
          log.info(
              "[IAPService] cleaning up transaction: ${transaction.toString()}");
          SKPaymentQueueWrapper().finishTransaction(transaction);
        });

        await Future.delayed(Duration(seconds: 3));
        log.info("[IAPService] finish cleaning up");
      }
    }
  }
}

class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
