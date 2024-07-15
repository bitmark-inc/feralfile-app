//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:card_swiper/card_swiper.dart';
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
  final int initialIndex = 0;

  @override
  void afterFirstLayout(BuildContext context) {
    unawaited(injector<ConfigurationService>().setAlreadyShowProTip(true));
    injector<ConfigurationService>().showProTip.value = false;
  }

  List<SubscriptionDetails> activeSubscriptionDetails(
      List<SubscriptionDetails> subscriptionDetails) {
    final activeSubscriptionDetails = <SubscriptionDetails>[];
    for (final subscriptionDetail in subscriptionDetails) {
      final shouldIgnoreOnUI = inactiveCustomIds()
              .contains(subscriptionDetail.productDetails.customID) &&
          !(subscriptionDetail.status == IAPProductStatus.completed ||
              subscriptionDetail.status == IAPProductStatus.trial &&
                  subscriptionDetail.trialExpiredDate != null &&
                  subscriptionDetail.trialExpiredDate!
                      .isBefore(DateTime.now()));
      if (!shouldIgnoreOnUI) {
        activeSubscriptionDetails.add(subscriptionDetail);
      }
    }
    return activeSubscriptionDetails;
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
        child:
            BlocBuilder<UpgradesBloc, UpgradeState>(builder: (context, state) {
          final subscriptionDetails =
              activeSubscriptionDetails(state.subscriptionDetails);
          return Swiper(
            itemCount: subscriptionDetails.length,
            onIndexChanged: (index) {},
            index: initialIndex,
            loop: false,
            itemBuilder: (context, index) =>
                _subcribeView(context, subscriptionDetails[index]),
            pagination: const SwiperPagination(
              builder: DotSwiperPaginationBuilder(
                  color: AppColor.auLightGrey,
                  activeColor: MomaPallet.lightYellow),
            ),
            controller: SwiperController(),
          );
        }),
      ),
    );
  }

  Widget _subcribeView(
          BuildContext context, SubscriptionDetails subscriptionDetails) =>
      Column(
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
                    padding: ResponsiveLayout.pageHorizontalEdgeInsets,
                    child: _statusSection(context, subscriptionDetails),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
            child: _actionSection(context, subscriptionDetails),
          ),
        ],
      );

  Widget _statusSection(
    BuildContext context,
    SubscriptionDetails subscriptionDetails,
  ) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.ppMori400Black16;
    final contentStyle = theme.textTheme.ppMori400Black14;
    IAPProductStatus status = subscriptionDetails.status;
    switch (status) {
      case IAPProductStatus.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('subscribed'.tr(), style: titleStyle),
            Text(
              'thank_support'.tr(),
              style: contentStyle,
            ),
            const SizedBox(height: 10),
            _benefitImage(context, status),
            const SizedBox(height: 30),
          ],
        );
      case IAPProductStatus.trial:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'sub_30_days'.tr(),
              style: titleStyle,
            ),
            Text(
              'you_are_enjoying_a_free_trial'.tr(),
              style: contentStyle,
            ),
            _benefitImage(context, status),
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
              'free_user'.tr(),
              style: titleStyle,
            ),
            Text(
              'your_subscription_has_expired'.tr(),
              style: contentStyle,
            ),
            _benefitImage(context, status),
            const SizedBox(height: 30),
          ],
        );
      case IAPProductStatus.notPurchased:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'free_user'.tr(),
              style: titleStyle,
            ),
            Text(
              'upgrade_to_use'.tr(),
              style: contentStyle,
            ),
            _benefitImage(context, status),
            const SizedBox(height: 30),
          ],
        );
      case IAPProductStatus.error:
        return Text(
          'error_loading_sub'.tr(),
          //"Error when loading your subscription.",
          style: theme.textTheme.ppMori400Black12,
        );
    }
  }

  Widget _actionSection(
    BuildContext context,
    SubscriptionDetails subscriptionDetails,
  ) {
    final theme = Theme.of(context);
    IAPProductStatus status = subscriptionDetails.status;
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
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '${'you_are_subscribed_at'.tr(
                        namedArgs: {
                          'price': subscriptionDetails.productDetails?.price ??
                              '4.99usd'.tr(),
                        },
                      )}\n${'auto_renews_unless_cancelled'.tr()}',
                      style: theme.textTheme.ppMori400Black12,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ))
          ],
        );
      case IAPProductStatus.trial:
        final df = DateFormat('yyyy-MMM-dd');
        final trialExpireDate =
            df.format(subscriptionDetails.trialExpiredDate ?? DateTime.now());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  PrimaryButton(
                    text: 'subscribed_for_a_30_day'.tr(),
                    color: theme.disableColor,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    '${'after_trial'.tr(
                      namedArgs: {
                        'price': subscriptionDetails.productDetails?.price ??
                            '4.99usd'.tr(),
                        'date': trialExpireDate,
                      },
                    )}\n${'auto_renews_unless_cancelled'.tr()}',
                    style: theme.textTheme.ppMori400Black12,
                    textAlign: TextAlign.center,
                  ),
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
                      onPressSubscribe(context,
                          subscriptionDetails: subscriptionDetails);
                    },
                    text: 'renew_feralfile_pro'.tr(),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    '${'renew_for'.tr(
                      namedArgs: {
                        'price': subscriptionDetails.productDetails?.price ??
                            '4.99usd'.tr(),
                      },
                    )}\n${'auto_renews_unless_cancelled'.tr()}',
                    style: theme.textTheme.ppMori400Black12,
                    textAlign: TextAlign.center,
                  ),
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
                        onPressSubscribe(context,
                            subscriptionDetails: subscriptionDetails);
                      },
                      text: 'subscribe_for_a_30_day'.tr()),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    '${'then_price'.tr(
                      args: [
                        subscriptionDetails.productDetails?.price ??
                            '4.99usd'.tr()
                      ],
                    )}\n${'auto_renews_unless_cancelled'.tr()}',
                    style: theme.textTheme.ppMori400Black12,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          ],
        );
      case IAPProductStatus.error:
        return Text(
          'error_loading_sub'.tr(),
          //"Error when loading your subscription.",
          style: theme.textTheme.headlineMedium,
        );
    }
  }

  Widget _benefitImage(BuildContext context, IAPProductStatus status) => Column(
        children: [
          Center(
            child: SvgPicture.asset(
              [IAPProductStatus.trial, IAPProductStatus.completed]
                      .contains(status)
                  ? 'assets/images/premium_comparation_subscribed.svg'
                  : 'assets/images/premium_comparation_free_user.svg',
              height: 320,
            ),
          ),
        ],
      );

  void onPressSubscribe(BuildContext context,
      {required SubscriptionDetails subscriptionDetails}) {
    final ids = [subscriptionDetails.productDetails?.customID ?? ''];
    context.read<UpgradesBloc>().add(UpgradePurchaseEvent(ids));
  }
}
