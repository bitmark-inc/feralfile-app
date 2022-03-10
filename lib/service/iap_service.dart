import 'dart:async';

import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/cupertino.dart';

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
}

class IAPServiceImpl implements IAPService {
  ConfigurationService _configurationService;
  IAPApi _iapApi;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  ValueNotifier<Map<String, ProductDetails>> products = ValueNotifier({});
  ValueNotifier<Map<String, IAPProductStatus>> purchases = ValueNotifier({});

  IAPServiceImpl(this._configurationService, this._iapApi);
  String? _receiptData;

  Future<void> setup() async {
    final jwt = _configurationService.getIAPJWT();
    if (jwt != null && jwt.isValid()) {}
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      log.info("finish fetching iap tiers");
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

    ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(productIds.toSet());
    if (productDetailResponse.error != null) {
      return;
    }

    products.value = Map.fromIterable(productDetailResponse.productDetails,
        key: (e) => e.id, value: (e) => e);

    // restore();
  }

  Future<bool> renewJWT() async {
    final receiptData = _configurationService.getIAPReceipt();
    if (receiptData == null) return false;

    final jwt = await _verifyPurchase(receiptData);
    if (jwt == null) return false;
    _configurationService.setIAPJWT(jwt);
    return true;
  }

  Future<void> purchase(ProductDetails product) async {
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: null,
    );

    if (Platform.isIOS) {
      var transactions = await SKPaymentQueueWrapper().transactions();
      await Future.forEach(transactions,
          (SKPaymentTransactionWrapper skPaymentTransactionWrapper) async {
        await SKPaymentQueueWrapper()
            .finishTransaction(skPaymentTransactionWrapper);
      });
    }

    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() async {
    await _inAppPurchase.restorePurchases();
  }

  Future<JWT?> _verifyPurchase(String receiptData) async {
    final platform;
    if (Platform.isIOS) {
      platform = 'apple';
    } else {
      platform = 'google';
    }
    try {
      final jwt = await _iapApi
          .verifyIAP({'platform': platform, 'receipt_data': receiptData});
      return jwt;
    } catch (error) {
      log.info("error when verifying receipt", error);
      return null;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        purchases.value[purchaseDetails.productID] = IAPProductStatus.pending;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          purchases.value[purchaseDetails.productID] = IAPProductStatus.error;
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
          if (jwt != null && jwt.isValid()) {
            purchases.value[purchaseDetails.productID] =
                IAPProductStatus.completed;
            _configurationService.setIAPJWT(jwt);
            _configurationService.setIAPReceipt(receiptData);
          } else {
            purchases.value[purchaseDetails.productID] =
                IAPProductStatus.expired;
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
