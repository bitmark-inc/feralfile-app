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
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/mix_panel_client_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "autonomy_pro".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child:
            BlocBuilder<UpgradesBloc, UpgradeState>(builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addTitleSpace(),
              Center(
                child: SvgPicture.asset(
                  'assets/images/subscription.svg',
                  height: 80,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Expanded(
                  child: Padding(
                padding: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
                child: _statusSection(context, state),
              )),
            ],
          );
        }),
      ),
    );
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

  Widget _statusSection(
    BuildContext context,
    UpgradeState state,
  ) {
    final mixpanel = injector<MixPanelClientService>().mixpanel;
    final theme = Theme.of(context);
    IAPProductStatus status = state.status;
    switch (status) {
      case IAPProductStatus.completed:
        mixpanel.getPeople().set("Subscription", "Subscried");
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("subscribed".tr(), style: theme.textTheme.ppMori400Black16),
            const SizedBox(height: 16.0),
            Text("thank_support".tr(args: [_subscriptionsManagementLocation]),
                //"Thank you for your support. Manage your subscription in $_subscriptionsManagementLocation",
                style: theme.textTheme.ppMori400Black14),
            const SizedBox(height: 10.0),
            _benefitImage(context),
            const Spacer(),
            Container(
                alignment: Alignment.bottomCenter,
                child: Column(
                  children: [
                    PrimaryButton(
                        text: 'subscribed'.tr(), color: theme.disableColor),
                    const SizedBox(height: 6),
                    Text(
                      "you_will_be_charged".tr(
                        namedArgs: {
                          "price":
                              state.productDetails?.price ?? "4.99usd".tr(),
                          "date": "",
                          "location": _subscriptionsManagementLocation
                        },
                      ),
                      style: theme.textTheme.ppMori400Black12,
                    ),
                  ],
                ))
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
                style: theme.textTheme.ppMori400Black16),
            const SizedBox(height: 16.0),
            Text(
                "to_cancel_your_subscription".tr(
                    namedArgs: {"location": _subscriptionsManagementLocation}),
                //"You will be charged ${state.productDetails?.price ?? "US\$4.99"}/month starting $trialExpireDate. To cancel your subscription, go to $_subscriptionsManagementLocation",
                style: theme.textTheme.ppMori400Black14),
            const SizedBox(height: 10.0),
            _benefitImage(context),
            const SizedBox(
              height: 10,
            ),
            const Spacer(),
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  PrimaryButton(
                      onTap: () {
                        onPressSubscribe(context);
                      },
                      text: 'sub_then_price'.tr()),
                  const SizedBox(height: 6),
                  Text(
                    'you_will_be_charged_starting'.tr(
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
          alignment: Alignment.topCenter,
          child: const CupertinoActivityIndicator(),
        );
      case IAPProductStatus.expired:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'your_subscription_has_expired'.tr(),
              style: theme.textTheme.ppMori400Black14,
            ),
            _benefitImage(context),
            const Spacer(),
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  AuPrimaryButton(
                    onPressed: () {
                      onPressSubscribe(context);
                    },
                    text: 'renew_for'.tr(
                      namedArgs: {
                        'price': state.productDetails?.price ?? "4.99usd".tr(),
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            )
          ],
        );
      case IAPProductStatus.notPurchased:
        return Column(
          children: [
            Text(
              'upgrade_to_use'.tr(),
              style: theme.textTheme.ppMori400Black14,
            ),
            _benefitImage(context),
            const Spacer(),
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  AuPrimaryButton(
                      onPressed: () {
                        onPressSubscribe(context);
                      },
                      text: 'sub_then_price'.tr()),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'then_price'.tr(
                      args: [state.productDetails?.price ?? "4.99usd".tr()],
                    ),
                    style: theme.textTheme.ppMori400Black12,
                  ),
                ],
              ),
            )
          ],
        );
      case IAPProductStatus.error:
        return Text("error_loading_sub".tr(),
            //"Error when loading your subscription.",
            style: theme.textTheme.headline4);
    }
  }

  Widget _benefitImage(BuildContext context) {
    return Column(
      children: [
        Center(
          child: SvgPicture.asset(
            'assets/images/premium_comparation_light.svg',
            height: 320,
          ),
        ),
      ],
    );
  }

  void onPressSubscribe(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
  }
}
