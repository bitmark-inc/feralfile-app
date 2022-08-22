//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/purchase_validator.dart';
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
    setup();
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
      log.info("[IAPService] finish fetching iap tiers");
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

    // Restore previous purchase
    await restore();

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

  @override
  Future<void> purchase(ProductDetails product) async {
    if (await _inAppPurchase.isAvailable() == false) return;
    final purchaseParam = PurchaseParam(
      productDetails: product,
    );

    log.info("[IAPService] purchase: ${product.id}");

    await _cleanupPendingTransactions();

    log.info("[IAPService] buy non comsumable: ${product.id}");
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restore() async {
    log.info("[IAPService] restore purchases");
    if (await _inAppPurchase.isAvailable() == false ||
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
          "[IAPService] purchase: ${purchaseDetails.productID},"
              " status: ${purchaseDetails.status.name}");

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }

      if (purchaseDetails.status == PurchaseStatus.pending) {
        purchases.value[purchaseDetails.productID] = IAPProductStatus.pending;
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        purchases.value[purchaseDetails.productID] = IAPProductStatus.notPurchased;
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
            final product = products.value[purchaseDetails.productID];
            if (product != null) {
              final validator = PurchaseValidatorFactory.createPurchaseValidator(
                  product: product, purchase: purchaseDetails);
              final trialExpireDate = await validator.getTrialExpireDate();
              if (trialExpireDate != null) {
                log.info("[IAPService] the receipt is trial");
                purchases.value[purchaseDetails.productID] =
                    IAPProductStatus.trial;
                trialExpireDates.value[purchaseDetails.productID] =
                    trialExpireDate;
              } else if (await validator.isValid()) {
                log.info("[IAPService] the receipt is valid");
                purchases.value[purchaseDetails.productID] =
                    IAPProductStatus.completed;
              }
              purchases.notifyListeners();
              return;
            }
            log.info("[IAPService] the receipt is invalid");
            purchases.value[purchaseDetails.productID] =
                IAPProductStatus.expired;
            _configurationService.setIAPJWT(null);
            _cleanupPendingTransactions();
            return;
          }
        }
      }
      purchases.notifyListeners();
    });
  }

  @override
  Future<bool> isSubscribed() async {
    if (await isAppCenterBuild()) {
      return true;
    }
    final jwt = _configurationService.getIAPJWT();
    final jwtValid = jwt != null && jwt.isValid(withSubscription: true);
    if (jwtValid) {
      return true;
    }
    return purchases.value.values.any((status) {
      return status == IAPProductStatus.completed ||
          status == IAPProductStatus.trial;
    });
  }

  Future _cleanupPendingTransactions() async {
    if (Platform.isIOS) {
      var transactions = await SKPaymentQueueWrapper().transactions();
      log.info(
          "[IAPService] cleaning up pending transactions: ${transactions.length}");

      if (transactions.isNotEmpty) {
        for (var transaction in transactions) {
          log.info(
              "[IAPService] cleaning up transaction: ${transaction.toString()}");
          SKPaymentQueueWrapper().finishTransaction(transaction);
        }

        await Future.delayed(const Duration(seconds: 3));
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
