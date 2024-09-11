//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/subscription_detail_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:autonomy_flutter/view/membership_card.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubscriptionPage extends StatefulWidget {
  final SubscriptionPagePayload? payload;

  const SubscriptionPage({super.key, this.payload});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with AfterLayoutMixin {
  final int initialIndex = 0;
  final _upgradesBloc = injector.get<UpgradesBloc>();
  late bool _isUpgrading;

  @override
  void initState() {
    super.initState();
    _isUpgrading = false;
  }

  @override
  Widget build(BuildContext context) {
    _upgradesBloc.add(UpgradeQueryInfoEvent());

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'go_premium'.tr(),
          onBack: () {
            if (widget.payload?.onBack != null) {
              widget.payload?.onBack?.call();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        body: SafeArea(
          child: BlocBuilder<UpgradesBloc, UpgradeState>(
              bloc: _upgradesBloc,
              builder: (context, state) {
                final subscriptionDetails = state.activeSubscriptionDetails;
                final subscriptionStatus = injector<ConfigurationService>()
                    .getIAPJWT()
                    ?.getSubscriptionStatus();
                return Swiper(
                  itemCount: subscriptionDetails.length,
                  onIndexChanged: (index) {},
                  index: initialIndex,
                  loop: false,
                  itemBuilder: (context, index) => _subcribeView(
                      context, subscriptionDetails[index], subscriptionStatus),
                  pagination: subscriptionDetails.length > 1
                      ? const SwiperPagination(
                          builder: DotSwiperPaginationBuilder(
                              color: AppColor.auLightGrey,
                              activeColor: MomaPallet.lightYellow),
                        )
                      : null,
                  controller: SwiperController(),
                );
              }),
        ),
      ),
    );
  }

  Widget _subcribeView(
          BuildContext context,
          SubscriptionDetails subscriptionDetails,
          SubscriptionStatus? subscriptionStatus) =>
      Container(
        color: AppColor.auGreyBackground,
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _statusSection(
                  context, subscriptionDetails, subscriptionStatus),
            ),
            const SizedBox(
              height: 64,
            ),
            Padding(
              padding:
                  ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
              child: _actionSection(
                  context, subscriptionDetails, subscriptionStatus),
            ),
          ],
        ),
      );

  Widget _statusSection(
    BuildContext context,
    SubscriptionDetails subscriptionDetails,
    SubscriptionStatus? subscriptionStatus,
  ) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.ppMori700White24;
    final contentStyle = theme.textTheme.ppMori400White14;
    IAPProductStatus status = subscriptionDetails.status;

    switch (status) {
      case IAPProductStatus.completed:
        // case user has membership
        final source = subscriptionStatus?.source ?? MembershipSource.purchase;
        switch (source) {
          case MembershipSource.purchase:
          case MembershipSource.preset:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('thank_you_for_being_premium'.tr(), style: titleStyle),
                const SizedBox(height: 24),
                Text(
                  'your_support_help_us'.tr(),
                  style: contentStyle,
                ),
              ],
            );
          case MembershipSource.giftCode:
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('you_receiveed_one_year_membership'.tr(),
                    style: titleStyle),
                const SizedBox(height: 24),
                Text(
                  'enjoy_exclusive_benefits'.tr(),
                  style: contentStyle,
                ),
              ],
            );
        }
      case IAPProductStatus.trial:
      // we dont support trial now
      case IAPProductStatus.loading:
      case IAPProductStatus.pending:
        return Container(
          height: 80,
          alignment: Alignment.topCenter,
          child: const LoadingWidget(),
        );
      case IAPProductStatus.expired:
      // expired membership: user has membership but it's expired
      // in this case, the UI is the same as free user
      case IAPProductStatus.notPurchased:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'free_user'.tr(),
              style: titleStyle,
            ),
            const SizedBox(height: 24),
            Text(
              'upgrade_your_membership'.tr(),
              style: contentStyle,
            ),
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
    SubscriptionStatus? subscriptionStatus,
  ) {
    final theme = Theme.of(context);
    final dateFormater = DateFormat('dd/MM/yyyy');
    IAPProductStatus status = subscriptionDetails.status;
    switch (status) {
      case IAPProductStatus.completed:
        final source = subscriptionStatus?.source ?? MembershipSource.purchase;
        switch (source) {
          case MembershipSource.purchase:
            return MembershipCard(
              type: MembershipCardType.premium,
              price: subscriptionDetails.price,
              isProcessing: false,
              isEnable: true,
              canAutoRenew: true,
              buttonBuilder: (context) => Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: AppColor.auLightGrey,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        color: AppColor.feralFileHighlight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'active'.tr(),
                      style: theme.textTheme.ppMori400Black14,
                    ),
                    const Spacer(),
                    if (subscriptionStatus?.expireDate != null)
                      Text(
                        'renews_'.tr(namedArgs: {
                          'date': dateFormater
                              .format(subscriptionStatus!.expireDate!)
                        }),
                        style: theme.textTheme.ppMori400Black14,
                      ),
                  ],
                ),
              ),
            );
          case MembershipSource.preset:
          case MembershipSource.giftCode:
            return MembershipCard(
              type: MembershipCardType.premium,
              price: subscriptionDetails.price,
              isProcessing: false,
              isEnable: true,
              buttonBuilder: (context) => Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: AppColor.auLightGrey,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        color: AppColor.feralFileHighlight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'active'.tr(),
                      style: theme.textTheme.ppMori400Black14,
                    ),
                    const Spacer(),
                    if (subscriptionStatus?.expireDate != null)
                      if (subscriptionStatus!.expireDate!
                          .isMembershipLifetime())
                        Text(
                          'lifetime'.tr(),
                          style: theme.textTheme.ppMori700Black14,
                        )
                      else
                        Text(
                          'expires_'.tr(namedArgs: {
                            'date': dateFormater
                                .format(subscriptionStatus.expireDate!)
                          }),
                          style: theme.textTheme.ppMori400Black14,
                        ),
                  ],
                ),
              ),
            );
        }

      case IAPProductStatus.trial:
      case IAPProductStatus.loading:
      case IAPProductStatus.pending:
        return const SizedBox();
      case IAPProductStatus.expired:
      case IAPProductStatus.notPurchased:
        // when user is essentially a free user
        return MembershipCard(
          type: MembershipCardType.premium,
          price: subscriptionDetails.price,
          isProcessing: _isUpgrading,
          isEnable: true,
          onTap: (_) {
            setState(() {
              _isUpgrading = true;
            });
            _onPressSubscribe(context,
                subscriptionDetails: subscriptionDetails);
          },
          buttonText: 'upgrade'.tr(),
          canAutoRenew: true,
        );
      case IAPProductStatus.error:
        return Text(
          'error_loading_sub'.tr(),
          //"Error when loading your subscription.",
          style: theme.textTheme.headlineMedium,
        );
    }
  }

  void _onPressSubscribe(BuildContext context,
      {required SubscriptionDetails subscriptionDetails}) {
    final ids = [subscriptionDetails.productDetails.id];
    context.read<UpgradesBloc>().add(UpgradePurchaseEvent(ids));
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {}
}

class SubscriptionPagePayload {
  final Function()? onBack;

  SubscriptionPagePayload({this.onBack});
}
