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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.ppMori400Black12,
            children: [
              TextSpan(
                text: 'auto_renews_unless_cancelled'
                    .tr(namedArgs: {'price': '$price'}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.ppMori400Black12,
              children: [
                TextSpan(
                    text: 'Note:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text: ' A subscription is ',
                ),
                TextSpan(
                    text: 'not required',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text:
                      ' to use the basic features of this app. Premium features require a subscription.',
                ),
              ],
            )),
        if (Platform.isAndroid && currencyCode == _indiaCurrencyCode) ...[
          const SizedBox(height: 8),
          Text(
            textAlign: TextAlign.center,
            'renew_policy_india'.tr(),
            style: theme.textTheme.ppMori400Black12
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ],
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
