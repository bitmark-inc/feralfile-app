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
                "More Autonomy",
                style: theme.textTheme.headline1,
              ),
              const SizedBox(height: 24.0),
              _subscribeView(context, state),
            ],
          ));
    });
  }

  static String get _subscriptionsManagementLocation {
    if (Platform.isIOS) {
      return "Settings > Apple ID > Subscriptions.";
    } else if (Platform.isAndroid) {
      return "Play Store -> Payments & subscriptions -> Subscriptions.";
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
            Text("Subscribed", style: theme.textTheme.headline4),
            const SizedBox(height: 16.0),
            Text(
                "Thank you for your support. Manage your subscription in $_subscriptionsManagementLocation",
                style: theme.textTheme.bodyText1),
          ],
        );
      case IAPProductStatus.trial:
        final df = DateFormat("yyyy-MMM-dd");
        final trialExpireDate = df.format(state.trialExpiredDate!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Subscribed (30-day free trial)",
                style: theme.textTheme.headline4),
            const SizedBox(height: 16.0),
            Text(
                "You will be charged ${state.productDetails?.price ?? "US\$4.99"}/month starting $trialExpireDate. To cancel your subscription, go to $_subscriptionsManagementLocation",
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
                Text("Subscribe", style: theme.textTheme.headline4),
                const Spacer(),
                SvgPicture.asset('assets/images/iconForward.svg'),
              ]),
              const SizedBox(height: 16.0),
              ...[
                "View your collection on TV and projectors.",
                "Priority support."
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
        return Text("Error when loading your subscription.",
            style: theme.textTheme.headline4);
    }
  }

  static showSubscriptionDialog(BuildContext context, String? price,
      PremiumFeature? feature, Function()? onPressSubscribe) {
    final theme = Theme.of(context);

    UIHelper.showDialog(
      context,
      "More Autonomy",
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (feature != null) ...[
            Text(feature.moreAutonomyDescription,
                style: theme.primaryTextTheme.bodyText1),
            const SizedBox(height: 16),
          ],
          Text('Upgrading gives you:', style: theme.primaryTextTheme.bodyText1),
          SvgPicture.asset(
            'assets/images/premium_comparation.svg',
            height: 320,
          ),
          const SizedBox(height: 16),
          Text("*Google TV app plus AirPlay & Chromecast streaming",
              style: theme.primaryTextTheme.headline5),
          const SizedBox(height: 40),
          AuFilledButton(
            text:
                "SUBSCRIBE FOR A 30-DAY FREE TRIAL\n(THEN ${price ?? "4.99"}/MONTH)",
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
              "NOT NOW",
              style: theme.primaryTextTheme.button,
            ),
          ),
        ],
      ),
    );
  }
}
