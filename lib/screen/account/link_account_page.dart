import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkAccountPage extends StatefulWidget {
  const LinkAccountPage({Key? key}) : super(key: key);

  @override
  State<LinkAccountPage> createState() => _LinkAccountPageState();
}

class _LinkAccountPageState extends State<LinkAccountPage>
    with RouteAware, WidgetsBindingObserver {
  VoidCallback? _wcURIListener;
  VoidCallback? _remotePeerWCAccountListener;
  bool _moveToOtherEtherumWalletPage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();

    _moveToOtherEtherumWalletPage = false;
  }

  @override
  void initState() {
    super.initState();

    // Open Metamask
    if (_wcURIListener == null) {
      _wcURIListener = () {
        log.info("_wcURIListener Get Notifier");
        if (_moveToOtherEtherumWalletPage) return;
        final _uri = injector<WalletConnectDappService>().wcURI.value;
        log.info("_wcURIListener Get wcURI $_uri");

        if (_uri == null) return;
        final metamaskLink =
            "https://metamask.app.link/wc?uri=" + Uri.encodeComponent(_uri);
        log.info(metamaskLink);
        _launchURL(metamaskLink);
      };

      injector<WalletConnectDappService>().wcURI.addListener(_wcURIListener!);
    }

    // Link Successfully
    if (_remotePeerWCAccountListener == null) {
      _remotePeerWCAccountListener = () {
        log.info("WalletConnectDappService GetNotifier: remotePeerAccount");
        final connectedSession =
            injector<WalletConnectDappService>().remotePeerAccount.value;
        if (connectedSession == null) return;

        context
            .read<AccountsBloc>()
            .add(LinkEthereumWalletEvent(connectedSession));
      };

      injector<WalletConnectDappService>()
          .remotePeerAccount
          .addListener(_remotePeerWCAccountListener!);
    }
  }

  void _launchURL(String _url) async {
    if (!await launch(_url, forceSafariVC: false, universalLinksOnly: true)) {
      _moveToOtherEtherumWalletPage = true;
      Navigator.of(context)
          .pushNamed(AppRouter.linkWalletConnectPage, arguments: "MetaMask");
    }
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);

    if (_wcURIListener != null) {
      injector<WalletConnectDappService>()
          .wcURI
          .removeListener(_wcURIListener!);
    }

    if (_remotePeerWCAccountListener != null) {
      injector<WalletConnectDappService>()
          .remotePeerAccount
          .removeListener(_remotePeerWCAccountListener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocListener<AccountsBloc, AccountsState>(
        listener: (context, state) {
          final event = state.event;
          if (event == null) return;

          if (event is LinkAccountSuccess) {
            final linkedAccount = event.connection;
            // SideEffect: pre-fetch tokens
            injector<TokensService>()
                .fetchTokensForAddresses([linkedAccount.accountNumber]);

            final walletName = linkedAccount
                    .wcConnectedSession?.sessionStore.remotePeerMeta.name ??
                'your wallet';
            UIHelper.showInfoDialog(context, "Account linked",
                "Autonomy has received autorization to link to your NFTs in $walletName.");

            final delay = _moveToOtherEtherumWalletPage ? 3 : 5;

            Future.delayed(Duration(seconds: delay), () {
              UIHelper.hideInfoDialog(context);

              if (injector<ConfigurationService>().isDoneOnboarding()) {
                Navigator.of(context).pushNamed(AppRouter.nameLinkedAccountPage,
                    arguments: linkedAccount);
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.nameLinkedAccountPage, (route) => false,
                    arguments: linkedAccount);
              }
            });
          }

          if (event is AlreadyLinkedError) {
            showErrorDiablog(
                context,
                ErrorEvent(
                    null,
                    "Already linked",
                    "You’ve already linked this account to Autonomy.",
                    ErrorItemState.seeAccount), defaultAction: () {
              Navigator.of(context).pushNamed(
                  AppRouter.linkedAccountDetailsPage,
                  arguments: event.connection);
            });
          }

          context.read<AccountsBloc>().add(ResetEventEvent());
        },
        child: Container(
          margin:
              EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Link account",
                        style: appTextTheme.headline1,
                      ),
                      addTitleSpace(),
                      RichText(
                        text: TextSpan(
                          style: appTextTheme.bodyText1,
                          children: <TextSpan>[
                            TextSpan(
                                text:
                                    'Linking your account to Autonomy does not import or access your private keys.',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            TextSpan(
                              text:
                                  ' If you have multiple accounts in your wallet, make sure that the account you want to link is active. ',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      _bitmarkLinkView(context),
                      addDivider(),
                      SizedBox(height: 24),
                      _ethereumLinkView(context),
                      SizedBox(height: 40),
                      _tezosLinkView(context),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bitmarkLinkView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BITMARK",
          style: appTextTheme.headline4,
        ),
        SizedBox(
          height: 16,
        ),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                SvgPicture.asset("assets/images/feralfileAppIcon.svg"),
                SizedBox(width: 16),
                Text("Feral File", style: appTextTheme.headline4),
              ],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.linkFeralFilePage);
            }),
      ],
    );
  }

  Widget _ethereumLinkView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ETHEREUM",
          style: appTextTheme.headline4,
        ),
        SizedBox(
          height: 20,
        ),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/metamask-alternative.png"),
                SizedBox(width: 16),
                Text("MetaMask", style: appTextTheme.headline4),
              ],
            ),
            onTap: () {
              _linkMetamask(context);
            }),
        if (Platform.isIOS) _linkLedger("Ethereum"),
        addDivider(),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/walletconnect-alternative.png"),
                SizedBox(width: 16),
                Text("Other Ethereum wallets", style: appTextTheme.headline4),
              ],
            ),
            onTap: () {
              _moveToOtherEtherumWalletPage = true;
              Navigator.of(context).pushNamed(AppRouter.linkWalletConnectPage);
            }),
      ],
    );
  }

  Widget _tezosLinkView(BuildContext context) {
    final tezosBeaconService = injector<TezosBeaconService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TEZOS",
          style: appTextTheme.headline4,
        ),
        SizedBox(
          height: 20,
        ),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/kukai_wallet.png"),
                SizedBox(width: 16),
                Text("Kukai", style: appTextTheme.headline4),
              ],
            ),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRouter.linkTezosKukaiPage)),
        addDivider(),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/temple_wallet.png"),
                SizedBox(width: 16),
                Text("Temple", style: appTextTheme.headline4),
              ],
            ),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRouter.linkTezosTemplePage)),
        if (Platform.isIOS) _linkLedger("Tezos"),
        addDivider(),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/tezos_wallet.png"),
                SizedBox(width: 16),
                Text("Other Tezos wallets", style: appTextTheme.headline4),
              ],
            ),
            onTap: () async {
              final uri = await tezosBeaconService.getConnectionURI();
              Navigator.of(context)
                  .pushNamed(AppRouter.linkBeaconConnectPage, arguments: uri);
            }),
      ],
    );
  }

  Future _linkMetamask(BuildContext context) async {
    injector<WalletConnectDappService>().start();
    injector<WalletConnectDappService>().connect();
  }

  Widget _linkLedger(String blockchain) {
    return Column(
      children: [
        addDivider(),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/iconLedger.png"),
                SizedBox(width: 16),
                Text("Ledger", style: appTextTheme.headline4),
              ],
            ),
            onTap: () => Navigator.of(context).pushNamed(
                AppRouter.linkLedgerWalletPage,
                arguments: blockchain)),
      ],
    );
  }
}
