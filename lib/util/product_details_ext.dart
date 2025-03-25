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
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Important (Regional Policy Notice)',
              style: theme.textTheme.ppMori700Black14.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: theme.textTheme.ppMori400Black12,
                        children: [
                          TextSpan(
                            text: 'India:',
                            style: theme.textTheme.ppMori400Black12
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' Automatic renewal is ',
                          ),
                          TextSpan(
                            text: 'not available',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                ' for subscriptions above ₹15,000. Subscribers in India must manually renew their subscription each year through their Google Play account.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                        maxLines: 3,
                        text: TextSpan(
                          style: theme.textTheme.ppMori400Black12,
                          children: [
                            TextSpan(
                              text: 'All other regions:',
                              style: theme.textTheme.ppMori400Black12
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  ' Your subscription automatically renews each year unless canceled.',
                            ),
                          ],
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
            text: TextSpan(
          style: theme.textTheme.ppMori400Black12,
          children: [
            TextSpan(
                text: 'Note:', style: TextStyle(fontWeight: FontWeight.bold)),
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
        ...[],
      ],
    );
  }
}
