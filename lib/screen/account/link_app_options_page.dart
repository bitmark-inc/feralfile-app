//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      appBar: getBackAppBar(context,
          onBack: () => Navigator.of(context).pop(),
          title: widget.walletApp.toString().split(".").last),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          addTitleSpace(),
          Padding(
            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
            child: Text(
              "where_are_you_using"
                  .tr(args: [widget.walletApp.toString().split(".").last]),
              style: theme.textTheme.ppMori700Black24,
            ),
          ),
          addTitleSpace(),
          _mobileAppOnThisDeviceOptionWidget(context),
          addOnlyDivider(),
          _browserExtensionOptionWidget(context),
          addOnlyDivider(),
          const SizedBox(height: 30),
          if (widget.walletApp == WalletApp.MetaMask) ...[
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.auSuperTeal,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'important'.tr(),
                        style: theme.textTheme.ppMori700Black14,
                      ),
                      const SizedBox(height: 15),
                      RichText(
                        text: TextSpan(
                            text: 'autonomy_currently'.tr(),
                            children: [
                              TextSpan(
                                  text: '${'ethereum_mainnet'.tr()}. ',
                                  style: theme.textTheme.ppMori400Black14),
                              TextSpan(text: 'all_other_evm_networks'.tr()),
                            ],
                            style: theme.textTheme.ppMori400Black14),
                      ),
                      const SizedBox(height: 15.0),
                      AuSecondaryButton(
                        text: "request_other_supported_networks".tr(),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.supportThreadPage,
                            arguments: NewIssuePayload(
                                reportIssueType: ReportIssueType.Feature),
                          );
                        },
                        borderColor: AppColor.primaryBlack,
                        textColor: AppColor.primaryBlack,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _mobileAppOnThisDeviceOptionWidget(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRow(
      padding: ResponsiveLayout.tappableForwardRowEdgeInsets,
      leftWidget: Text('mobile_app_on_this_device'.tr(),
          style: theme.textTheme.ppMori400Black14),
      onTap: () => _linkMetamask(),
    );
  }

  Widget _browserExtensionOptionWidget(BuildContext context) {
    final theme = Theme.of(context);
    return TappableForwardRow(
      padding: ResponsiveLayout.tappableForwardRowEdgeInsets,
      leftWidget: Text('browser_extension'.tr(),
          style: theme.textTheme.ppMori400Black14),
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
      if (!mounted) return;
      Navigator.of(context)
          .pushNamed(AppRouter.linkWalletConnectPage, arguments: 'MetaMask')
          .then((value) => _isPageInactive = false);
    }
  }
}
