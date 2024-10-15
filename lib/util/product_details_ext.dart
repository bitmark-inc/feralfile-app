import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

extension ProductDetailsExt on ProductDetails {
  static const _indiaCurrencyCode = 'INR';

  SKSubscriptionPeriodUnit get period => SKSubscriptionPeriodUnit.year;

  String get renewPolicyText {
    if (Platform.isAndroid && currencyCode == _indiaCurrencyCode) {
      return 'renew_policy_india'.tr();
    }
    return 'auto_renews_unless_cancelled'.tr();
  }
}
