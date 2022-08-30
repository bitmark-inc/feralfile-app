//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AccessMethodPage extends StatelessWidget {
  final String walletApp;
  const AccessMethodPage({Key? key, required this.walletApp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(children: [
          Expanded(
              child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "access_method".tr(),
                style: theme.textTheme.headline1,
              ),
              addTitleSpace(),
              _linkAccount(context),
              addDivider(),
              _importAccount(context),
            ]),
          ))
        ]),
      ),
    );
  }

  Widget _linkAccount(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRowWithContent(
        leftWidget: Text('link'.tr(), style: theme.textTheme.headline4),
        bottomWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              //'View your NFTs without Autonomy accessing your private keys in ${walletApp.split('.').last}.',
              "li_view_your_nfts".tr(args: [walletApp.split('.').last]),
              style: theme.textTheme.bodyText1,
            ),
            if (walletApp == 'WalletApp.MetaMask') ...[
              const SizedBox(height: 8),
              Text(
                'supported_networks'.tr(),
                style: ResponsiveLayout.isMobile
                    ? theme.textTheme.atlasBlackNormal14
                    : theme.textTheme.atlasBlackNormal16,
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: ' •  ',
                  style: ResponsiveLayout.isMobile
                      ? theme.textTheme.atlasBlackNormal14
                      : theme.textTheme.atlasBlackNormal16,
                  children: [
                    TextSpan(text: 'ethereum_mainnet'.tr()),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'unsupported_networks'.tr(),
                style: ResponsiveLayout.isMobile
                    ? theme.textTheme.atlasBlackNormal14
                    : theme.textTheme.atlasBlackNormal16,
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: ' •  ',
                  style: ResponsiveLayout.isMobile
                      ? theme.textTheme.atlasBlackNormal14
                      : theme.textTheme.atlasBlackNormal16,
                  children: [
                    TextSpan(text: 'polygon'.tr()),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  text: ' •  ',
                  style: ResponsiveLayout.isMobile
                      ? theme.textTheme.atlasBlackNormal14
                      : theme.textTheme.atlasBlackNormal16,
                  children: [
                    TextSpan(text: 'binance_smart_chain'.tr()),
                  ],
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          switch (walletApp) {
            case 'WalletApp.MetaMask':
              Navigator.of(context).pushNamed(AppRouter.linkAppOptionPage);
              break;

            case 'WalletApp.Kukai':
              Navigator.of(context).pushNamed(AppRouter.linkTezosKukaiPage);
              break;

            case 'WalletApp.Temple':
              Navigator.of(context).pushNamed(AppRouter.linkTezosTemplePage);
              break;

            default:
              return;
          }
        });
  }

  Widget _importAccount(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRowWithContent(
      leftWidget: Text('import'.tr(), style: theme.textTheme.headline4),
      bottomWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("im_view_and_control".tr(),
              //'View and control your NFTs, sign authorizations, and connect to other platforms with Autonomy.',
              style: theme.textTheme.bodyText1),
          const SizedBox(height: 16),
          learnMoreAboutAutonomySecurityWidget(context),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.importAccountPage),
    );
  }
}
