import 'dart:io';

import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

extension GooglePlayProductDetailsExt on GooglePlayProductDetails {
  String get customID => '${id}_$subscriptionIndex';
}

extension ProductDetailsExt on ProductDetails {
  String get customID {
    if (this is GooglePlayProductDetails) {
      return (this as GooglePlayProductDetails).customID;
    }
    return id;
  }

  SKSubscriptionPeriodUnit get period {
    if (Platform.isAndroid) {
      if (this.customID == premiumCustomId()) {
        return SKSubscriptionPeriodUnit.year;
      } else {
        return SKSubscriptionPeriodUnit.month;
      }
    } else if (Platform.isIOS) {
      return (this as AppStoreProductDetails)
              .skProduct
              .subscriptionPeriod
              ?.unit ??
          SKSubscriptionPeriodUnit.month;
    } else {
      throw Exception('Unsupported platform');
    }
  }

  String get price {
    if (Platform.isAndroid) {
      return (this as GooglePlayProductDetails).price;
    } else if (Platform.isIOS) {
      return (this as AppStoreProductDetails).skProduct.price;
    } else {
      throw Exception('Unsupported platform');
    }
  }

  String get currencyCode {
    if (Platform.isAndroid) {
      return (this as GooglePlayProductDetails).currencyCode;
    } else if (Platform.isIOS) {
      return (this as AppStoreProductDetails)
          .skProduct
          .priceLocale
          .currencyCode;
    } else {
      throw Exception('Unsupported platform');
    }
  }

  String get currencySymbol {
    if (Platform.isAndroid) {
      return (this as GooglePlayProductDetails).currencySymbol;
    } else if (Platform.isIOS) {
      return (this as AppStoreProductDetails)
          .skProduct
          .priceLocale
          .currencySymbol;
    } else {
      throw Exception('Unsupported platform');
    }
  }
} // TODO Implement this library.
