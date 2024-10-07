import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

extension ProductDetailsExt on ProductDetails {
  static const _indiaCurrencyCode = 'INR';

  SKSubscriptionPeriodUnit get period {
    if (Platform.isAndroid) {
      return SKSubscriptionPeriodUnit.year;
    } else if (Platform.isIOS) {
      return (this as AppStoreProductDetails)
              .skProduct
              .subscriptionPeriod
              ?.unit ??
          SKSubscriptionPeriodUnit.year;
    } else {
      throw Exception('Unsupported platform');
    }
  }

  String get renewPolicyText {
    if (Platform.isAndroid && currencyCode == _indiaCurrencyCode) {
      return 'renew_policy_india'.tr();
    }
    return 'auto_renews_unless_cancelled'.tr();
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
}
