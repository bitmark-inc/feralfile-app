//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UpgradesView extends StatelessWidget {
  static const String tag = 'select_network';

  const UpgradesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());

    return BlocBuilder<UpgradesBloc, UpgradeState>(builder: (context, state) {
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  AuIcon.subscription,
                  size: 63,
                ),
              ),
              _statusSection(context, state),
            ],
          ));
    });
  }

  static String get _subscriptionsManagementLocation {
    if (Platform.isIOS) {
      return "set_apl_sub".tr(); //"Settings > Apple ID > Subscriptions.";
    } else if (Platform.isAndroid) {
      return "pla_pay_sub"
          .tr(); //"Play Store -> Payments & subscriptions -> Subscriptions.";
    } else {
      return "";
    }
  }

  static showSubscriptionDialog(BuildContext context, String? price,
      PremiumFeature? feature, Function()? onPressSubscribe,
      {Function? onCancel}) {
    final theme = Theme.of(context);

    UIHelper.showDialog(
      context,
      "more_autonomy".tr(),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (feature != null) ...[
            Text(
              feature.moreAutonomyDescription,
              style: theme.textTheme.ppMori400White14,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'upgrading_gives_you'.tr(),
            style: theme.textTheme.ppMori400White14,
          ),
          const SizedBox(height: 16),
          SvgPicture.asset(
            'assets/images/premium_comparation.svg',
            height: 320,
          ),
          const SizedBox(height: 16),
          Text("gg_tv_app".tr(),
              //"*Google TV app plus AirPlay & Chromecast streaming",
              style: theme.primaryTextTheme.headlineSmall),
          const SizedBox(height: 40),
          AuFilledButton(
            text: "sub_then_price".tr(args: [price ?? "4.99usd".tr()]),
            //"SUBSCRIBE FOR A 30-DAY FREE TRIAL\n(THEN ${price ?? "4.99"}/MONTH)",
            textAlign: TextAlign.center,
            onPress: () {
              if (onPressSubscribe != null) onPressSubscribe();
              Navigator.of(context).pop();
            },
            color: theme.colorScheme.secondary,
            textStyle: theme.textTheme.labelLarge,
          ),
          TextButton(
            onPressed: () {
              onCancel?.call();
              Navigator.of(context).pop();
            },
            child: Text(
              "not_now".tr(),
              style: theme.primaryTextTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
    injector<ConfigurationService>().setShouldShowSubscriptionHint(false);
  }

  Widget _statusSection(
    BuildContext context,
    UpgradeState state,
  ) {
    final mixpanel = injector<MixPanelClientService>().mixpanel;
    final theme = Theme.of(context);
    IAPProductStatus status = IAPProductStatus.loading; //state.status;
    switch (status) {
      case IAPProductStatus.completed:
        mixpanel.getPeople().set("Subscription", "Subscried");
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("subscribed".tr(), style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16.0),
            Text("thank_support".tr(args: [_subscriptionsManagementLocation]),
                //"Thank you for your support. Manage your subscription in $_subscriptionsManagementLocation",
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 10.0),
            _benefitImage(context),
            AuPrimaryButton(onPressed: () {}, text: 'subscribed'.tr()),
            Text(
              "you_will_be_charged".tr(namedArgs: {
                "price": state.productDetails?.price ?? "4.99usd".tr(),
                "date": "",
                "location": _subscriptionsManagementLocation
              }),
            ),
          ],
        );
      case IAPProductStatus.trial:
        mixpanel.getPeople().set("Subscription", "Trial");
        final df = DateFormat("yyyy-MMM-dd");
        final trialExpireDate =
            df.format(state.trialExpiredDate ?? DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("sub_30_days".tr(), //"Subscribed (30-day free trial)",
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16.0),
            Text(
                "to_cancel_your_subscription".tr(
                    namedArgs: {"location": _subscriptionsManagementLocation}),
                //"You will be charged ${state.productDetails?.price ?? "US\$4.99"}/month starting $trialExpireDate. To cancel your subscription, go to $_subscriptionsManagementLocation",
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 10.0),
            _benefitImage(context),
            const SizedBox(
              height: 10,
            ),
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  AuPrimaryButton(
                      onPressed: () {}, text: 'sub_then_price'.tr()),
                  Text(
                    'you_will_be_charged'.tr(
                      namedArgs: {
                        "price": state.productDetails?.price ?? "4.99usd".tr(),
                        "date": trialExpireDate,
                      },
                    ),
                    style: theme.textTheme.ppMori400Black12,
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ],
        );
      case IAPProductStatus.loading:
      case IAPProductStatus.pending:
        return Container(
          height: 80,
          alignment: Alignment.center,
          child: const CupertinoActivityIndicator(),
        );
      case IAPProductStatus.expired:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your_subscription_has_expired'.tr(),
            )
          ],
        );
      case IAPProductStatus.notPurchased:
        return Column(
          children: [
            Text('upgrade_to_use'.tr()),
            _benefitImage(context),
            AuPrimaryButton(
                onPressed: () {
                  onPressSubscribe(context);
                  Navigator.of(context).pop();
                },
                text: 'sub_then_price'.tr()),
            Text('then_price'.tr(args: ["4.99usd".tr()])),
          ],
        );
      case IAPProductStatus.error:
      default:
        return Text("error_loading_sub".tr(),
            //"Error when loading your subscription.",
            style: theme.textTheme.headlineMedium);
    }
  }

  static Widget _benefitImage(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Center(
          child: SvgPicture.asset(
            'assets/images/premium_comparation.svg',
            height: 320,
          ),
        ),
        Text(
          'gg_tv_app'.tr(),
          style: theme.textTheme.ppMori400Black14,
        ),
      ],
    );
  }

  static void onPressSubscribe(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
  }
}
