import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wc_connected_session.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/error_handler.dart';

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
      ),
      body: Container(
        margin: pageEdgeInsets,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Link account",
                style: appTextTheme.headline1,
              ),
              addTitleSpace(),
              Text(
                  'If you have multiple accounts in your wallet, make sure that the account you want to link is active.',
                  style: appTextTheme.bodyText1),
              SizedBox(height: 24),
              _bitmarkLinkView(context),
              addOnlyDivider(),
              SizedBox(height: 40),
              _ethereumLinkView(context),
              SizedBox(height: 40),
              _tezosLinkView(context),
              SizedBox(height: 40),
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
        BlocConsumer<FeralfileBloc, FeralFileState>(
            listener: (context, state) async {
          final event = state.event;
          if (event == null) return;

          if (event is LinkAccountSuccess) {
            // SideEffect: pre-fetch tokens
            injector<TokensService>()
                .fetchTokensForAddresses([event.connection.accountNumber]);
            UIHelper.hideInfoDialog(context);
            await Future.delayed(Duration(milliseconds: 200));
            UIHelper.showInfoDialog(context, 'Account linked',
                'Autonomy has received autorization to link to your Feral File account ${event.connection.name}');

            await Future.delayed(SHORT_SHOW_DIALOG_DURATION, () {
              if (injector<ConfigurationService>().isDoneOnboarding()) {
                Navigator.of(context).popUntil(
                    (route) => route.settings.name == AppRouter.settingsPage);
              } else {
                doneOnboarding(context);
              }
            });

            return;
          } else if (event is AlreadyLinkedError) {
            UIHelper.hideInfoDialog(context);
            await Future.delayed(Duration(milliseconds: 200));
            showErrorDiablog(
                context,
                ErrorEvent(
                    null,
                    "Already linked",
                    "You’ve already linked this account to Autonomy.",
                    ErrorItemState.seeAccount), defaultAction: () {
              Navigator.of(context).pushReplacementNamed(
                  AppRouter.linkedAccountDetailsPage,
                  arguments: event.connection);
            });
            return;
          }
        }, builder: (context, state) {
          return TappableForwardRow(
              leftWidget: Row(
                children: [
                  SvgPicture.asset("assets/images/feralfileAppIcon.svg"),
                  SizedBox(width: 16),
                  Text("Feral File", style: appTextTheme.headline4),
                ],
              ),
              onTap: () async {
                // Navigator.of(context).pushNamed(AppRouter.linkFeralFilePage);
                final walletConnectService =
                    injector<WalletConnectDappService>();
                await walletConnectService.start();
                walletConnectService.connect();
                var wcURI = walletConnectService.wcURI.value;
                if (wcURI == null) {
                  return;
                }
                wcURI = Uri.encodeQueryComponent(wcURI);

                final network = injector<ConfigurationService>().getNetwork();
                final url = Environment.networkedFeralFileWebsiteURL(network) +
                    '/exhibitions?callbackUrl=autonomy%3A%2F%2F&wc=$wcURI';

                UIHelper.showInfoDialog(
                  context,
                  'Link requested',
                  'Autonomy has sent a request to Feral File in your mobile browser to link to your account. Please make sure you are signed in and authorize the request. ',
                  isDismissible: true,
                );

                await launchUrlString(url,
                    mode: LaunchMode.externalApplication);
              });
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
          height: 4,
        ),
        TappableForwardRow(
          leftWidget: Row(
            children: [
              Image.asset("assets/images/metamask-alternative.png"),
              SizedBox(width: 16),
              Text("MetaMask", style: appTextTheme.headline4),
            ],
          ),
          onTap: () => Navigator.of(context).pushNamed(
              AppRouter.accessMethodPage,
              arguments: WalletApp.MetaMask.toString()),
        ),
        _linkLedger("Ethereum"),
        addOnlyDivider(),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/walletconnect-alternative.png"),
                SizedBox(width: 16),
                Text("Other Ethereum wallets", style: appTextTheme.headline4),
              ],
            ),
            onTap: () => Navigator.of(context)
                .pushNamed(AppRouter.linkWalletConnectPage)),
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
            onTap: () => Navigator.of(context).pushNamed(
                AppRouter.accessMethodPage,
                arguments: WalletApp.Kukai.toString())),
        addOnlyDivider(),
        TappableForwardRow(
            leftWidget: Row(
              children: [
                Image.asset("assets/images/temple_wallet.png"),
                SizedBox(width: 16),
                Text("Temple", style: appTextTheme.headline4),
              ],
            ),
            onTap: () => Navigator.of(context).pushNamed(
                AppRouter.accessMethodPage,
                arguments: WalletApp.Temple.toString())),
        _linkLedger("Tezos"),
        addOnlyDivider(),
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

  Widget _linkLedger(String blockchain) {
    return Column(
      children: [
        addOnlyDivider(),
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
    _isLinking = true;

    final apiToken = session.accounts.first.replaceFirst("feralfile-api:", "");

    context.read<FeralfileBloc>().add(LinkFFAccountInfoEvent(apiToken));
  }

  Future _handleLinkETHWallet(WCConnectedSession session) async {
    if (_isLinking) return;
    _isLinking = true;

    try {
      final linkedAccount =
          await injector<AccountService>().linkETHWallet(session);

      // SideEffect: pre-fetch tokens
      injector<TokensService>()
          .fetchTokensForAddresses([linkedAccount.accountNumber]);

      final walletName =
          linkedAccount.wcConnectedSession?.sessionStore.remotePeerMeta.name ??
              'your wallet';
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
