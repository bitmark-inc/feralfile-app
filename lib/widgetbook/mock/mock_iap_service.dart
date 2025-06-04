import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase_platform_interface/src/types/product_details.dart';
import 'package:in_app_purchase_platform_interface/src/types/purchase_details.dart';

class MockIAPService extends IAPService {
  @override
  ValueNotifier<Map<String, ProductDetails>> products = ValueNotifier({});
  @override
  ValueNotifier<Map<String, IAPProductStatus>> purchases = ValueNotifier({});
  @override
  ValueNotifier<Map<String, DateTime>> trialExpireDates = ValueNotifier({});

  @override
  Map<String, DateTime> cancelAt = {};

  @override
  Future<List<dynamic>> getProducts() async {
    return [];
  }

  @override
  Future<bool> purchaseProduct(String productId) async {
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    return true;
  }

  @override
  Future<List<dynamic>> getPurchases() async {
    return [];
  }

  @override
  Future<bool> isProductPurchased(String productId) async {
    return true;
  }

  @override
  Future<void> clearReceipt() async {}

  @override
  Future<CustomSubscription> getCustomActiveSubscription() async {
    return CustomSubscription(
      rawPrice: 100,
      currency: 'USD',
      billingPeriod: 'monthly',
    );
  }

  // @override
  // PurchaseDetails? getPurchaseDetails(String productId) {
  //   return null;
  // }

  @override
  Future<String> getStripeUrl() async {
    return 'https://example.com/stripe';
  }

  @override
  Future<bool> isSubscribed({bool includeInhouse = true}) async {
    return false;
  }

  @override
  Future<bool> isSubscribedToProduct(String productId) async {
    return false;
  }

  @override
  Future<bool> isSubscribedToAnyProduct() async {
    return false;
  }

  @override
  Future<bool> isSubscribedToAnyProductInList(List<String> productIds) async {
    return false;
  }

  @override
  Future<void> purchase(ProductDetails product) {
    // TODO: implement purchase
    throw UnimplementedError();
  }

  @override
  Future<bool> renewJWT() {
    // TODO: implement renewJWT
    throw UnimplementedError();
  }

  @override
  Future<void> reset() {
    // TODO: implement reset
    throw UnimplementedError();
  }

  @override
  Future<void> restore() {
    // TODO: implement restore
    throw UnimplementedError();
  }

  @override
  Future<void> setup() {
    // TODO: implement setup
    throw UnimplementedError();
  }

  @override
  PurchaseDetails? getPurchaseDetails(String productId) {
    return null;
  }
}
