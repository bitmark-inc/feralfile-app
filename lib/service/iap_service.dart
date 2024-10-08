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
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:sentry/sentry.dart';

const List<String> _kAppleProductIds = <String>[
  ..._kAppleInactiveProductIds,
  ..._kAppleActiveProductIds,
];

const List<String> _kGoogleProductIds = <String>[
  ..._kGoogleInactiveProductIds,
  ..._kGoogleActiveProductIds,
];

const List<String> _kGoogleActiveProductIds = <String>[
  _kGooglePremiumProductId,
];

const List<String> _kAppleActiveProductIds = <String>[
  _kApplePremiumProductId,
];

const List<String> _kGoogleInactiveProductIds = <String>[
  'com.bitmark.autonomy_client.subscribe',
];

const List<String> _kAppleInactiveProductIds = <String>[
  'Au_IntroSub',
];

const _kGooglePremiumProductId = 'com.bitmark.feralfile.membership';

const _kApplePremiumProductId = 'com.bitmark.feralfile.premium';

String premiumId() =>
    Platform.isIOS ? _kApplePremiumProductId : _kGooglePremiumProductId;

List<String> inactiveIds() {
  final ids =
      Platform.isIOS ? _kAppleInactiveProductIds : _kGoogleInactiveProductIds;
  return ids;
}

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

  Future<bool> isSubscribed({bool includeInhouse = true});

  PurchaseDetails? getPurchaseDetails(String productId);

  void clearReceipt();
}

class IAPServiceImpl implements IAPService {
  final ConfigurationService _configurationService;
  final AuthService _authService;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final List<PurchaseDetails> _purchases = <PurchaseDetails>[];

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

    await _cleanupPendingTransactions();

    final productDetails = await fetchAllProducts();

    products.value = {for (var e in productDetails) e.id: e};
  }

  Future<void> setPaymentQueueDelegate() async {
    if (Platform.isIOS) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
    }
  }

  List<String> _getProductIds() {
    if (Platform.isIOS) {
      return _kAppleProductIds;
    } else {
      return _kGoogleProductIds;
    }
  }

  Future<List<ProductDetails>> _fetchProducts(List<String> productIds) async {
    ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(productIds.toSet());
    if (productDetailResponse.error != null) {
      unawaited(Sentry.captureException(productDetailResponse.error));
      return [];
    }

    return productDetailResponse.productDetails;
  }

  Future<List<ProductDetails>> fetchAllProducts() async {
    await setPaymentQueueDelegate();
    final productIds = _getProductIds();
    return _fetchProducts(productIds);
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
    await _purchase(product);
  }

  Future<void> _purchase(ProductDetails product) async {
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
      log.info('[IAPService] restore purchases not available');
      return;
    }
    await _inAppPurchase.restorePurchases();
    log.info('[IAPService] restore purchases completed');
  }

  Future<JWT?> _verifyPurchase(String receiptData) async {
    try {
      log.info('[IAPService] get authToken with receipt');
      final jwt = await _authService.getAuthToken(
          receiptData: receiptData, forceRefresh: true);
      return jwt;
    } catch (error) {
      log.info('[IAPService] error when verifying receipt', error);
      unawaited(_configurationService.setIAPReceipt(null));
      return null;
    }
  }

  Future<void> _onPurchaseUpdated(PurchaseDetails purchaseDetails) async {
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

          final status = subscriptionStatus!;
          if (status.productDetails?.id == purchaseDetails.productID) {
            if (status.isTrial) {
              purchases.value[purchaseDetails.productID] =
                  IAPProductStatus.trial;
              if (status.expireDate != null) {
                trialExpireDates.value[purchaseDetails.productID] =
                    status.expireDate!;
              }
            } else {
              purchases.value[purchaseDetails.productID] =
                  IAPProductStatus.completed;
              if (purchaseDetails.status == PurchaseStatus.purchased) {
                unawaited(injector<ConfigurationService>()
                    .setSubscriptionTime(DateTime.now()));
              }
              _purchases.add(purchaseDetails);
            }
            purchases.notifyListeners();
          }
        } else {
          log.info('[IAPService] the receipt is invalid');
          purchases.value[purchaseDetails.productID] = IAPProductStatus.expired;
          _purchases.remove(purchaseDetails);
          unawaited(_configurationService.setIAPReceipt(null));
          unawaited(_cleanupPendingTransactions());
          purchases.notifyListeners();
          return;
        }
      }
    }
    purchases.notifyListeners();
    injector<SubscriptionBloc>().add(GetSubscriptionEvent());
    injector<UpgradesBloc>().add(UpgradeQueryInfoEvent());
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    if (purchaseDetailsList.isEmpty) {
      // Remove purchase status
      unawaited(_configurationService.setIAPReceipt(null));
      return;
    }

    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      await _onPurchaseUpdated(purchaseDetails);
    });
  }

  @override
  Future<bool> isSubscribed({bool includeInhouse = true}) async {
    final jwt = _configurationService.getIAPJWT();
    return (jwt != null && jwt.isValid(withSubscription: true)) ||
        (includeInhouse && await isAppCenterBuild());
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

  @override
  PurchaseDetails? getPurchaseDetails(String productId) =>
      _purchases.firstWhereOrNull((element) => element.productID == productId);

  @override
  void clearReceipt() {
    _receiptData = null;
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
