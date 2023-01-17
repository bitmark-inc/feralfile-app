//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:autonomy_flutter/view/responsive.dart';

class LinkAppOptionsPage extends StatefulWidget {
  final WalletApp walletApp;
  const LinkAppOptionsPage({Key? key, required this.walletApp})
      : super(key: key);

  @override
  State<LinkAppOptionsPage> createState() => _LinkAppOptionsPageState();
}

class _LinkAppOptionsPageState extends State<LinkAppOptionsPage> {
  VoidCallback? _wcURIListener;
  bool _isPageInactive = false;

  @override
  void dispose() {
    _removeMetaMaskURIListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(children: [
          Expanded(
              child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "where_are_you_using"
                    .tr(args: [widget.walletApp.toString().split(".").last]),
                style: theme.textTheme.headline1,
              ),
              addTitleSpace(),
              _mobileAppOnThisDeviceOptionWidget(context),
              addOnlyDivider(),
              _browserExtensionOptionWidget(context),
              const SizedBox(
                height: 40,
              ),
              if (widget.walletApp == WalletApp.MetaMask) ...[
                Container(
                  color: AppColor.chatPrimaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'important'.tr(),
                          style: theme.textTheme.atlasGreyBold14,
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'autonomy_currently'.tr(),
                              children: [
                                TextSpan(
                                    text: '${'ethereum_mainnet'.tr()}. ',
                                    style: theme.textTheme.atlasBlackBold14),
                                TextSpan(text: 'all_other_evm_networks'.tr()),
                              ],
                              style: theme.textTheme.atlasBlackNormal14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ]),
          ))
        ]),
      ),
    );
  }

  Widget _mobileAppOnThisDeviceOptionWidget(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRow(
      leftWidget: Text('mobile_app_on_this_device'.tr(),
          style: theme.textTheme.headline4),
      onTap: () => _linkMetamask(),
    );
  }

  Widget _browserExtensionOptionWidget(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRow(
      leftWidget:
          Text('browser_extension'.tr(), style: theme.textTheme.headline4),
      onTap: () => Navigator.of(context).pushNamed(AppRouter.linkMetamaskPage),
    );
  }

  void _registerMetaMaskURIListener() {
    if (_wcURIListener != null) return;

    _wcURIListener = () async {
      log.info("_wcURIListener Get Notifier");
      if (_isPageInactive) return;
      final uri = injector<WalletConnectDappService>().wcURI.value;
      log.info("_wcURIListener Get wcURI $uri");

      if (uri == null) return;
      final metamaskLink =
          "https://metamask.app.link/wc?uri=${Uri.encodeComponent(uri)}";

      final urlAndroid = "metamask://wc?uri=$uri";

      log.info(metamaskLink);
      if (Platform.isAndroid) {
        try {
          await _launchURL(urlAndroid);
        } catch (e) {
          await _launchURL(metamaskLink);
        }
      } else {
        await _launchURL(metamaskLink);
      }
    };

    injector<WalletConnectDappService>().wcURI.addListener(_wcURIListener!);
  }

  void _removeMetaMaskURIListener() {
    if (_wcURIListener == null) return;

    injector<WalletConnectDappService>().wcURI.removeListener(_wcURIListener!);
    injector<WalletConnectDappService>().disconnect();
  }

  Future _linkMetamask() async {
    // Open Metamask
    _registerMetaMaskURIListener();

    injector<WalletConnectDappService>().start();
    injector<WalletConnectDappService>().connect();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        !await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication)) {
      _isPageInactive = true;
      Navigator.of(context)
          .pushNamed(AppRouter.linkWalletConnectPage, arguments: 'MetaMask');
    }
  }
}
