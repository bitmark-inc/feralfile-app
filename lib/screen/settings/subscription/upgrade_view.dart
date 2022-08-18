//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/constants.dart';

import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class UpgradesView extends StatelessWidget {
  static const String tag = 'select_network';

  const UpgradesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());
    final theme = Theme.of(context);

    return BlocBuilder<UpgradesBloc, UpgradeState>(builder: (context, state) {
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "more_autonomy".tr(),
                style: theme.textTheme.headline1,
              ),
              const SizedBox(height: 16.0),
              _subscribeView(context, state),
            ],
          ));
    });
  }

  static String get _subscriptionsManagementLocation {
    if (Platform.isIOS) {
      return "set_apl_sub".tr();//"Settings > Apple ID > Subscriptions.";
    } else if (Platform.isAndroid) {
      return "pla_pay_sub".tr();//"Play Store -> Payments & subscriptions -> Subscriptions.";
    } else {
      return "";
    }
  }

  static Widget _subscribeView(BuildContext context, UpgradeState state) {
    final theme = Theme.of(context);

    switch (state.status) {
      case IAPProductStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("subscribed".tr(), style: theme.textTheme.headline4),
            const SizedBox(height: 16.0),
            Text(
                "thank_support".tr(args: [_subscriptionsManagementLocation]),
                //"Thank you for your support. Manage your subscription in $_subscriptionsManagementLocation",
                style: theme.textTheme.bodyText1),
          ],
        );
      case IAPProductStatus.trial:
        final df = DateFormat("yyyy-MMM-dd");
        final trialExpireDate = df.format(state.trialExpiredDate!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "sub_30_days".tr(),//"Subscribed (30-day free trial)",
                style: theme.textTheme.headline4),
            const SizedBox(height: 16.0),
            Text(
                "you_will_be_charged".tr(namedArgs: {"price":state.productDetails?.price ?? "4.99usd".tr(),"date":trialExpireDate,"location":_subscriptionsManagementLocation}),
                //"You will be charged ${state.productDetails?.price ?? "US\$4.99"}/month starting $trialExpireDate. To cancel your subscription, go to $_subscriptionsManagementLocation",
                style: theme.textTheme.bodyText1),
          ],
        );
      case IAPProductStatus.loading:
      case IAPProductStatus.pending:
        return Container(
          height: 80,
          alignment: Alignment.center,
          child: const CupertinoActivityIndicator(),
        );
      case IAPProductStatus.notPurchased:
      case IAPProductStatus.expired:
        return GestureDetector(
          onTap: (() => showSubscriptionDialog(
                  context, state.productDetails?.price, null, (() {
                context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
              }))),
          child: Column(
            children: [
              Row(children: [
                Text("h_subscribe".tr(), style: theme.textTheme.headline4),
                const Spacer(),
                SvgPicture.asset('assets/images/iconForward.svg'),
              ]),
              const SizedBox(height: 16.0),
              ...[
                "view_collection_tv".tr(),
                //"View your collection on TV and projectors.",
                "priority_support".tr()
              ]
                  .map((item) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ' •  ',
                              style: theme.textTheme.bodyText1,
                              textAlign: TextAlign.start,
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyText1,
                              ),
                            ),
                          ]))
                  .toList(),
            ],
          ),
        );
      case IAPProductStatus.error:
        return Text(
            "error_loading_sub".tr(),
            //"Error when loading your subscription.",
            style: theme.textTheme.headline4);
    }
  }

  static showSubscriptionDialog(BuildContext context, String? price,
      PremiumFeature? feature, Function()? onPressSubscribe) {
    final theme = Theme.of(context);

    UIHelper.showDialog(
      context,
      "more_autonomy".tr(),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (feature != null) ...[
            Text(feature.moreAutonomyDescription,
                style: theme.primaryTextTheme.bodyText1),
            const SizedBox(height: 16),
          ],
          Text('upgrading_gives_you'.tr(), style: theme.primaryTextTheme.bodyText1),
          SvgPicture.asset(
            'assets/images/premium_comparation.svg',
            height: 320,
          ),
          const SizedBox(height: 16),
          Text(
            "gg_tv_app".tr(),
              //"*Google TV app plus AirPlay & Chromecast streaming",
              style: theme.primaryTextTheme.headline5),
          const SizedBox(height: 40),
          AuFilledButton(
            text:
                "sub_then_price".tr(args: [price ?? "4.99usd".tr()]),
                //"SUBSCRIBE FOR A 30-DAY FREE TRIAL\n(THEN ${price ?? "4.99"}/MONTH)",
            textAlign: TextAlign.center,
            onPress: () {
              if (onPressSubscribe != null) onPressSubscribe();
              Navigator.of(context).pop();
            },
            color: theme.colorScheme.secondary,
            textStyle: theme.textTheme.button,
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "not_now".tr(),
              style: theme.primaryTextTheme.button,
            ),
          ),
        ],
      ),
    );
  }
}
