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
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';
import 'package:autonomy_flutter/util/subscription_detail_ext.dart';
import 'package:autonomy_flutter/util/subscription_details_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:autonomy_flutter/view/membership_card.dart';
import 'package:autonomy_flutter/view/responsive.dart';
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
    with AfterLayoutMixin, RouteAware {
  final int initialIndex = 0;
  final _upgradesBloc = injector.get<UpgradesBloc>();

  // didPopNext
  @override
  void didPopNext() {
    super.didPopNext();
    _upgradesBloc.add(UpgradeQueryInfoEvent());
  }

  @override
  Widget build(BuildContext context) {
    _upgradesBloc.add(UpgradeQueryInfoEvent());

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: getBackAppBar(
          context,
          title: 'membership'.tr(),
          onBack: () {
            if (widget.payload?.onBack != null) {
              widget.payload?.onBack?.call();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        body: BlocBuilder<UpgradesBloc, UpgradeState>(
            bloc: _upgradesBloc,
            builder: (context, state) {
              final subscriptionDetails = state.activeSubscriptionDetails;
              final subscriptionStatus = injector<ConfigurationService>()
                  .getIAPJWT()
                  ?.getSubscriptionStatus();
              if (subscriptionDetails.isEmpty) {
                return const LoadingWidget();
              }
              return _subscribeView(
                context,
                subscriptionDetails.subscribedSubscriptionDetail ??
                    subscriptionDetails.first,
                subscriptionStatus,
                state.isProcessing,
              );
            }),
      ),
    );
  }

  Widget _subscribeView(
    BuildContext context,
    SubscriptionDetails subscriptionDetails,
    SubscriptionStatus? subscriptionStatus,
    bool? isProcessing,
  ) =>
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
                context,
                subscriptionDetails,
                subscriptionStatus,
                isProcessing,
              ),
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
          case MembershipSource.webPurchase:
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
        return Container(
          height: 500,
          alignment: Alignment.topCenter,
          child: const LoadingWidget(
            backgroundColor: Colors.transparent,
          ),
        );
      case IAPProductStatus.expired:
      // expired membership: user has membership but it's expired
      // in this case, the UI is the same as free user
      case IAPProductStatus.pending:
      // pending membership: user is purchasing membership
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
    bool? isProcessing,
  ) {
    final theme = Theme.of(context);
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
              renewPolicyText:
                  subscriptionDetails.productDetails.renewPolicyText,
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
                          'date': subscriptionStatus!.expireDateFormatted!
                        }),
                        style: theme.textTheme.ppMori400Black14,
                      ),
                  ],
                ),
              ),
            );
          case MembershipSource.webPurchase:
            return MembershipCard(
              type: MembershipCardType.premium,
              price: subscriptionDetails.price,
              isProcessing: false,
              isEnable: true,
              buttonBuilder: (context) {
                final cancelAt = subscriptionDetails.cancelAtFormatted;
                return Container(
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
                      if (cancelAt != null && cancelAt.isNotEmpty)
                        Text(
                          'cancel_at_'.tr(namedArgs: {
                            'date': cancelAt,
                          }),
                          style: theme.textTheme.ppMori400Black14,
                        )
                      else if (subscriptionStatus?.expireDate != null)
                        Text(
                          'renews_'.tr(namedArgs: {
                            'date': subscriptionStatus!.expireDateFormatted!
                          }),
                          style: theme.textTheme.ppMori400Black14,
                        ),
                    ],
                  ),
                );
              },
              renewPolicyBuilder: (context) {
                final theme = Theme.of(context);
                final cancelAt = subscriptionDetails.cancelAtFormatted;
                return GestureDetector(
                  onTap: () async {
                    final url = _upgradesBloc.state.stripePortalUrl;
                    final uri = Uri.tryParse(url ?? '');
                    if (uri != null) {
                      unawaited(
                        injector<NavigationService>().openUrl(uri).then(
                              (value) => _upgradesBloc.add(
                                UpgradeQueryInfoEvent(),
                              ),
                            ),
                      );
                    }
                  },
                  child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.ppMori400Black12,
                        children: [
                          if (cancelAt != null) ...[
                            TextSpan(
                              text: '${'canceled_policy_stripe'.tr()} ',
                            )
                          ] else ...[
                            TextSpan(
                              text: '${'renew_policy_stripe'.tr()} ',
                            ),
                          ],
                          const TextSpan(
                            text: 'Stripe',
                            style:
                                TextStyle(decoration: TextDecoration.underline),
                          ),
                        ],
                      )),
                );
              },
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
                            'date': subscriptionStatus.expireDateFormatted!
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
        return const SizedBox();
      case IAPProductStatus.expired:
      case IAPProductStatus.pending:
      case IAPProductStatus.notPurchased:
        // when user is essentially a free user
        return MembershipCard(
          type: MembershipCardType.essential,
          price: subscriptionDetails.price,
          isProcessing: isProcessing == true ||
              subscriptionDetails.status == IAPProductStatus.pending,
          isEnable: true,
          onTap: (_) {
            _onPressSubscribe(context,
                subscriptionDetails: subscriptionDetails);
          },
          buttonText: 'upgrade'.tr(),
          renewPolicyText: subscriptionDetails.productDetails.renewPolicyText,
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
