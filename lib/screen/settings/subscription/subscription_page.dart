//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with AfterLayoutMixin {
  @override
  void afterFirstLayout(BuildContext context) {
    unawaited(injector<ConfigurationService>().setAlreadyShowProTip(true));
    injector<ConfigurationService>().showProTip.value = false;
  }

  @override
  Widget build(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'autonomy_pro'.tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: BlocBuilder<UpgradesBloc, UpgradeState>(
            builder: (context, state) => Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            addTitleSpace(),
                            const SizedBox(
                              height: 98,
                            ),
                            Padding(
                              padding:
                                  ResponsiveLayout.pageHorizontalEdgeInsets,
                              child: _statusSection(context, state),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: ResponsiveLayout
                          .pageHorizontalEdgeInsetsWithSubmitButton,
                      child: _actionSection(context, state),
                    ),
                  ],
                )),
      ),
    );
  }

  static String get _subscriptionsManagementLocation {
    if (Platform.isIOS) {
      return 'set_apl_sub'.tr(); //"Settings > Apple ID > Subscriptions.";
    } else if (Platform.isAndroid) {
      return 'pla_pay_sub'
          .tr(); //"Play Store -> Payments & subscriptions -> Subscriptions.";
    } else {
      return '';
    }
  }

  Widget _statusSection(
    BuildContext context,
    UpgradeState state,
  ) {
    final theme = Theme.of(context);
    IAPProductStatus status = state.status;
    switch (status) {
      case IAPProductStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('subscribed'.tr(), style: theme.textTheme.ppMori400Black16),
            const SizedBox(height: 16),
            Text('thank_support'.tr(args: [_subscriptionsManagementLocation]),
                style: theme.textTheme.ppMori400Black14),
            const SizedBox(height: 10),
            _benefitImage(context),
            const SizedBox(height: 30),
          ],
        );
      case IAPProductStatus.trial:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('sub_30_days'.tr(), //"Subscribed (30-day free trial)",
                style: theme.textTheme.ppMori400Black16),
            const SizedBox(height: 16),
            Text(
                'to_cancel_your_subscription'.tr(
                    namedArgs: {'location': _subscriptionsManagementLocation}),
                //"You will be charged ${state.productDetails?.price ?? "US\$4.99"}/month starting $trialExpireDate. To cancel your subscription, go to $_subscriptionsManagementLocation",
                style: theme.textTheme.ppMori400Black14),
            const SizedBox(height: 10),
            _benefitImage(context),
            const SizedBox(height: 30),
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
            const SizedBox(height: 30),
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
            const SizedBox(height: 30),
          ],
        );
      case IAPProductStatus.error:
        return Text('error_loading_sub'.tr(),
            //"Error when loading your subscription.",
            style: theme.textTheme.ppMori400Black12);
    }
  }

  Widget _actionSection(
    BuildContext context,
    UpgradeState state,
  ) {
    final theme = Theme.of(context);
    IAPProductStatus status = state.status;
    switch (status) {
      case IAPProductStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                alignment: Alignment.bottomCenter,
                child: Column(
                  children: [
                    PrimaryButton(
                        text: 'subscribed'.tr(), color: theme.disableColor),
                    const SizedBox(height: 6),
                    Text(
                      'you_will_be_charged'.tr(
                        namedArgs: {
                          'price':
                              state.productDetails?.price ?? '4.99usd'.tr(),
                          'date': '',
                          'location': _subscriptionsManagementLocation
                        },
                      ),
                      style: theme.textTheme.ppMori400Black12,
                    ),
                  ],
                ))
          ],
        );
      case IAPProductStatus.trial:
        final df = DateFormat('yyyy-MMM-dd');
        final trialExpireDate =
            df.format(state.trialExpiredDate ?? DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        'price': state.productDetails?.price ?? '4.99usd'.tr(),
                        'date': trialExpireDate,
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
        return const SizedBox();
      case IAPProductStatus.expired:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  PrimaryButton(
                    onTap: () {
                      onPressSubscribe(context);
                    },
                    text: 'renew_for'.tr(
                      namedArgs: {
                        'price': state.productDetails?.price ?? '4.99usd'.tr(),
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
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  PrimaryButton(
                      onTap: () {
                        onPressSubscribe(context);
                      },
                      text: 'sub_then_price'.tr()),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'then_price'.tr(
                      args: [state.productDetails?.price ?? '4.99usd'.tr()],
                    ),
                    style: theme.textTheme.ppMori400Black12,
                  ),
                ],
              ),
            )
          ],
        );
      case IAPProductStatus.error:
        return Text('error_loading_sub'.tr(),
            //"Error when loading your subscription.",
            style: theme.textTheme.headlineMedium);
    }
  }

  Widget _benefitImage(BuildContext context) => Column(
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/images/premium_comparation_light.svg',
              height: 320,
            ),
          ),
        ],
      );

  void onPressSubscribe(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
  }
}
