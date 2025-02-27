import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

extension ProductDetailsExt on ProductDetails {
  static const _indiaCurrencyCode = 'INR';

  SKSubscriptionPeriodUnit get period => SKSubscriptionPeriodUnit.year;

  Widget renewPolicyWidget(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.textTheme.ppMori400Black12,
        children: [
          TextSpan(
            text:
                'This subscription will automatically renew every year unless you cancel. Your account will be charged',
          ),
          TextSpan(
            text: ' $price/${period.name}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' at the start of each renewal period.'),
          if (Platform.isAndroid && currencyCode == _indiaCurrencyCode) ...[
            TextSpan(text: '\n\n'),
            TextSpan(
              text: 'renew_policy_india'.tr(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  String get renewPolicyText {
    final price = this.price;
    String text = 'auto_renews_unless_cancelled'
        .tr(namedArgs: {'price': '${price}/${period.name}'});
    if (Platform.isAndroid && currencyCode == _indiaCurrencyCode) {
      text += '\n\n' + 'renew_policy_india'.tr();
    }
    return text;
  }
}
