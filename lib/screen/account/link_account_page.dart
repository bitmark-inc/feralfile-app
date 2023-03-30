//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wc_connected_session.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/services/tokens_service.dart';

class LinkAccountPage extends StatefulWidget {
  const LinkAccountPage({Key? key}) : super(key: key);

  @override
  State<LinkAccountPage> createState() => _LinkAccountPageState();
}

class _LinkAccountPageState extends State<LinkAccountPage>
    with RouteAware, WidgetsBindingObserver {
  VoidCallback? _remotePeerWCAccountListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void initState() {
    super.initState();

    _registerLinkedWalletConnectListener();
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    _removeLinkedWalletConnectListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: "link_wallet".tr(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            addTitleSpace(),
            _tezosLinkView(context),
          ],
        ),
      ),
    );
  }

  Widget _tezosLinkView(BuildContext context) {
    final tezosBeaconService = injector<TezosBeaconService>();
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.tappableForwardRowEdgeInsets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TappableForwardRow(
            padding: padding,
            leftWidget: Row(
              children: [
                Image.asset("assets/images/kukai_wallet.png"),
                const SizedBox(width: 16),
                Text("kukai".tr(), style: theme.textTheme.ppMori400Black14),
              ],
            ),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRouter.linkTezosKukaiPage)),
        addOnlyDivider(),
        _linkLedger(),
        addOnlyDivider(),
        TappableForwardRow(
          padding: padding,
          leftWidget: Row(
            children: [
              Image.asset("assets/images/metamask-alternative.png"),
              const SizedBox(width: 16),
              Text("metamask".tr(), style: theme.textTheme.ppMori400Black14),
            ],
          ),
          onTap: () => Navigator.of(context).pushNamed(
              AppRouter.linkAppOptionPage,
              arguments: WalletApp.MetaMask),
        ),
        addOnlyDivider(),
        TappableForwardRow(
            padding: padding,
            leftWidget: Row(
              children: [
                Image.asset("assets/images/temple_wallet.png"),
                const SizedBox(width: 16),
                Text("temple".tr(), style: theme.textTheme.ppMori400Black14),
              ],
            ),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRouter.linkTezosTemplePage)),
        addOnlyDivider(),
        TappableForwardRow(
            padding: padding,
            leftWidget: Row(
              children: [
                Image.asset("assets/images/walletconnect-alternative.png"),
                const SizedBox(width: 16),
                Text("other_ethereum_wallets".tr(),
                    style: theme.textTheme.ppMori400Black14),
              ],
            ),
            onTap: () => Navigator.of(context)
                .pushNamed(AppRouter.linkWalletConnectPage)),
        addOnlyDivider(),
        TappableForwardRow(
            padding: padding,
            leftWidget: Row(
              children: [
                Image.asset("assets/images/tezos_wallet.png"),
                const SizedBox(width: 16),
                Text("other_tezos_wallets".tr(),
                    style: theme.textTheme.ppMori400Black14),
              ],
            ),
            onTap: () async {
              final uri = await tezosBeaconService.getConnectionURI();

              if (!mounted) return;
              Navigator.of(context)
                  .pushNamed(AppRouter.linkBeaconConnectPage, arguments: uri);
            }),
        addOnlyDivider(),
      ],
    );
  }

  Widget _linkLedger() {
    final theme = Theme.of(context);
    return Column(
      children: [
        TappableForwardRow(
            padding: ResponsiveLayout.tappableForwardRowEdgeInsets,
            leftWidget: Row(
              children: [
                SvgPicture.asset("assets/images/iconLedger.svg"),
                const SizedBox(width: 16),
                Text("ledger".tr(), style: theme.textTheme.ppMori400Black14),
              ],
            ),
            onTap: () => Navigator.of(context).pushNamed(
                  AppRouter.selectLedgerWalletPage,
                )),
      ],
    );
  }

  // MARK: - Handlers
  void _registerLinkedWalletConnectListener() {
    if (_remotePeerWCAccountListener != null) return;
    // Link Successfully
    _remotePeerWCAccountListener = () async {
      log.info("WalletConnectDappService GetNotifier: remotePeerAccount");
      final connectedSession =
          injector<WalletConnectDappService>().remotePeerAccount.value;
      if (connectedSession == null) return;

      if (connectedSession.sessionStore.remotePeerMeta.name == "Feral File") {
        _handleLinkFeralFile(connectedSession);
      } else {
        _handleLinkETHWallet(connectedSession);
      }
    };

    injector<WalletConnectDappService>()
        .remotePeerAccount
        .addListener(_remotePeerWCAccountListener!);
  }

  void _removeLinkedWalletConnectListener() {
    if (_remotePeerWCAccountListener == null) return;

    injector<WalletConnectDappService>()
        .remotePeerAccount
        .removeListener(_remotePeerWCAccountListener!);
  }

  bool _isLinking = false;

  Future _handleLinkFeralFile(WCConnectedSession session) async {
    if (_isLinking) return;
    final apiToken =
        session.accounts.firstOrNull?.replaceFirst("feralfile-api:", "");
    if (apiToken == null) return;
    _isLinking = true;

    try {
      final connection =
          await injector<FeralFileService>().linkFF(apiToken, delayLink: false);

      if (!mounted) return;
      UIHelper.hideInfoDialog(context);
      UIHelper.showFFAccountLinked(context, connection.name);

      await Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
        if (injector<ConfigurationService>().isDoneOnboarding()) {
          Navigator.of(context).popUntil(
              (route) => route.settings.name == AppRouter.homePageNoTransition);
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.accountsPreviewPage, (route) => false);
        }
      });
      _isLinking = false;
    } on AlreadyLinkedException catch (exception) {
      UIHelper.showAlreadyLinked(context, exception.connection);
      _isLinking = false;
    } catch (_) {
      _isLinking = false;
      UIHelper.hideInfoDialog(context);
      rethrow;
    }
  }

  Future _handleLinkETHWallet(WCConnectedSession session) async {
    if (_isLinking) return;
    _isLinking = true;

    try {
      final linkedAccount =
          await injector<AccountService>().linkETHWallet(session);

      // SideEffect: pre-fetch tokens
      injector<TokensService>()
          .fetchTokensForAddresses(linkedAccount.accountNumbers);

      final walletName =
          linkedAccount.wcConnectedSession?.sessionStore.remotePeerMeta.name ??
              'your_wallet'.tr();

      if (!mounted) return;
      UIHelper.showAccountLinked(context, linkedAccount, walletName);
      _isLinking = false;
    } on AlreadyLinkedException catch (exception) {
      UIHelper.showAlreadyLinked(context, exception.connection);
      _isLinking = false;
    } catch (_) {
      _isLinking = false;
      UIHelper.hideInfoDialog(context);
      rethrow;
    }
  }
}
