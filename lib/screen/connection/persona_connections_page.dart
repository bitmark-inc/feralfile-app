//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_page.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/au_outlined_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';

import '../../model/tzkt_operation.dart';
import '../../view/responsive.dart';

class PersonaConnectionsPage extends StatefulWidget {
  final PersonaConnectionsPayload payload;

  const PersonaConnectionsPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<PersonaConnectionsPage> createState() => _PersonaConnectionsPageState();
}

class _PersonaConnectionsPageState extends State<PersonaConnectionsPage>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    final personUUID = widget.payload.personaUUID;
    context.read<AccountsBloc>().add(
        FindAccount(personUUID, widget.payload.address, widget.payload.type));
    switch (widget.payload.type) {
      case CryptoType.ETH:
        context.read<EthereumBloc>().add(GetEthereumAddressEvent(personUUID));
        context
            .read<EthereumBloc>()
            .add(GetEthereumBalanceWithUUIDEvent(personUUID));
        break;
      case CryptoType.XTZ:
        context.read<TezosBloc>().add(GetTezosBalanceWithUUIDEvent(personUUID));
        context.read<TezosBloc>().add(GetTezosAddressEvent(personUUID));
        break;
      case CryptoType.USDC:
        context.read<USDCBloc>().add(GetAddressEvent(personUUID));
        context.read<USDCBloc>().add(GetUSDCBalanceWithUUIDEvent(personUUID));
        break;
      case CryptoType.UNKNOWN:
        // do nothing
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _callFetchConnections();
    memoryValues =
        memoryValues.copyWith(scopedPersona: widget.payload.personaUUID);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _callFetchConnections();
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
    memoryValues.scopedPersona = null;
  }

  void _callFetchConnections() {
    final personUUID = widget.payload.personaUUID;

    switch (widget.payload.type) {
      case CryptoType.ETH:
        context.read<ConnectionsBloc>().add(GetETHConnectionsEvent(personUUID));
        break;
      case CryptoType.XTZ:
        context.read<ConnectionsBloc>().add(GetXTZConnectionsEvent(personUUID));
        break;
      default:
        // do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.payload.personaName,
        onBack: () {
          if (widget.payload.isBackHome) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.homePage,
              (route) => false,
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _addressSection(),
                    if (widget.payload.type == CryptoType.ETH ||
                        widget.payload.type == CryptoType.XTZ) ...[
                      const SizedBox(height: 40),
                      _connectionsSection(),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.payload.type == CryptoType.ETH ||
                widget.payload.type == CryptoType.XTZ ||
                widget.payload.type == CryptoType.USDC) ...[
              Row(
                children: [
                  Expanded(
                    child: AuOutlinedButton(
                      text: "send".tr(),
                      onPress: () async {
                        final payload = await Navigator.of(context).pushNamed(
                            SendCryptoPage.tag,
                            arguments: SendData(
                                LibAukDart.getWallet(
                                    widget.payload.personaUUID),
                                widget.payload.type,
                                null)) as Map?;
                        if (payload == null || !payload["isTezos"]) {
                          return;
                        }

                        if (!mounted) return;
                        final tx = payload['tx'] as TZKTOperation;
                        tx.sender = TZKTActor(address: widget.payload.address);
                        UIHelper.showMessageAction(
                          context,
                          'success'.tr(),
                          'send_success_des'.tr(),
                          onAction: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed(
                              AppRouter.tezosTXDetailPage,
                              arguments: {
                                "current_address": tx.sender?.address,
                                "tx": tx,
                              },
                            );
                          },
                          actionButton: 'see_transaction_detail'.tr(),
                          closeButton: "close".tr(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 16.0,
                  ),
                  Expanded(
                    child: BlocConsumer<AccountsBloc, AccountsState>(
                      listener: (context, accountState) async {},
                      builder: (context, accountState) {
                        final account = accountState.accounts?.firstWhere(
                            (element) =>
                                element.blockchain ==
                                widget.payload.type.source);
                        return AuOutlinedButton(
                          text: "receive".tr(),
                          onPress: () {
                            if (account != null &&
                                account.accountNumber.isNotEmpty) {
                              Navigator.of(context).pushNamed(
                                  GlobalReceiveDetailPage.tag,
                                  arguments: account);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              )
            ],
            SizedBox(height: safeAreaBottom > 0 ? 40 : 16),
          ],
        ),
      ),
    );
  }

  Widget _addressSection() {
    var address = widget.payload.address;
    final theme = Theme.of(context);
    final addressStyle = theme.textTheme.subtitle1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.payload.type.source,
          style: theme.textTheme.headline1,
        ),
        const SizedBox(height: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("address".tr(), style: theme.textTheme.headline4),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      showInfoNotification(
                          const Key("address"), "copied_to_clipboard".tr());
                      Clipboard.setData(
                          ClipboardData(text: widget.payload.address));
                    },
                    child: Text(
                      address,
                      style: addressStyle,
                    ),
                  ),
                ),
              ],
            ),
            ..._cryptoSection()
          ],
        ),
      ],
    );
  }

  List<Widget> _cryptoSection() {
    final List<Widget> widgets = [addDivider()];
    switch (widget.payload.type) {
      case CryptoType.ETH:
        widgets.add(
            BlocBuilder<EthereumBloc, EthereumState>(builder: (context, state) {
          final ethAddress =
              state.personaAddresses?[widget.payload.personaUUID];
          final ethBalance = state.ethBalances[ethAddress];
          final balance = ethBalance == null
              ? "-- ETH"
              : "${EthAmountFormatter(ethBalance.getInWei).format()} ETH";
          return _historyRow(balance: balance);
        }));
        break;
      case CryptoType.XTZ:
        widgets
            .add(BlocBuilder<TezosBloc, TezosState>(builder: (context, state) {
          final tezosAddress =
              state.personaAddresses?[widget.payload.personaUUID];
          final xtzBalance = state.balances[tezosAddress];
          final balance = xtzBalance == null
              ? "-- XTZ"
              : "${XtzAmountFormatter(xtzBalance).format()} XTZ";
          return _historyRow(balance: balance);
        }));
        break;
      case CryptoType.USDC:
        widgets.add(BlocBuilder<USDCBloc, USDCState>(builder: (context, state) {
          final usdcAddress =
              state.personaAddresses?[widget.payload.personaUUID];
          final usdcBalance = state.usdcBalances[usdcAddress];
          final balance = usdcBalance == null
              ? "-- USDC"
              : "${USDCAmountFormatter(usdcBalance).format()} USDC";
          return _historyRow(balance: balance);
        }));
        break;
      default:
        return [];
    }

    return widgets;
  }

  Widget _historyRow({String balance = ""}) {
    final theme = Theme.of(context);
    final addressStyle = theme.textTheme.subtitle1;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                        widget.payload.type == CryptoType.USDC
                            ? "USDC"
                            : "history".tr(),
                        style: theme.textTheme.headline4),
                    const Expanded(child: SizedBox()),
                    Text(balance, style: addressStyle),
                  ],
                ),
              ),
              SvgPicture.asset('assets/images/iconForward.svg'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
      onTap: () {
        if (widget.payload.type == CryptoType.USDC) return;
        Navigator.of(context).pushNamed(
          AppRouter.walletDetailsPage,
          arguments: WalletDetailsPayload(
              type: widget.payload.type,
              wallet: LibAukDart.getWallet(widget.payload.personaUUID)),
        );
      },
    );
  }

  Widget _connectionsSection() {
    final theme = Theme.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "connections".tr(),
        style: theme.textTheme.headline1,
      ),
      const SizedBox(height: 24),
      BlocBuilder<ConnectionsBloc, ConnectionsState>(builder: (context, state) {
        final connectionItems = state.connectionItems;
        if (connectionItems == null) return const SizedBox();

        if (connectionItems.isEmpty) {
          return _emptyConnectionsWidget();
        } else {
          int index = 0;
          return Column(
            children: [
              ...connectionItems.map((connectionItem) {
                index++;
                return Column(
                  children: [
                    _connectionItemWidget(connectionItem),
                    index < connectionItems.length
                        ? addOnlyDivider()
                        : const SizedBox(),
                  ],
                );
              }).toList(),
            ],
          );
        }
      }),
    ]);
  }

  Widget _emptyConnectionsWidget() {
    final theme = Theme.of(context);
    return Column(children: [
      TappableForwardRowWithContent(
          leftWidget: Row(children: [
            SvgPicture.asset("assets/images/iconQr.svg"),
            const SizedBox(width: 17.5),
            Text('add_connection'.tr(), style: theme.textTheme.headline4),
          ]),
          bottomWidget: Text("connect_dapp".tr(),
              //"Connect this address to an external dapp or platform.",
              style: theme.textTheme.bodyText1),
          onTap: () {
            late ScannerItem scanItem;

            switch (widget.payload.type) {
              case CryptoType.ETH:
                scanItem = ScannerItem.WALLET_CONNECT;
                break;
              case CryptoType.XTZ:
                scanItem = ScannerItem.BEACON_CONNECT;
                break;
              default:
                break;
            }

            Navigator.of(context)
                .pushNamed(AppRouter.scanQRPage, arguments: scanItem);
          }),
    ]);
  }

  Widget _connectionItemWidget(ConnectionItem connectionItem) {
    final connection = connectionItem.representative;
    final theme = Theme.of(context);

    return TappableForwardRow(
      leftWidget: Row(children: [
        UIHelper.buildConnectionAppWidget(connection, 24),
        const SizedBox(width: 16),
        Expanded(
            child: Text(
          connection.appName,
          style: theme.textTheme.headline4,
          overflow: TextOverflow.ellipsis,
        )),
      ]),
      onTap: () {
        Navigator.of(context).pushNamed(AppRouter.connectionDetailsPage,
            arguments: connectionItem);
        _callFetchConnections();
      },
    );
  }
}

class PersonaConnectionsPayload {
  final String personaUUID;
  final String address;
  final CryptoType type;
  final String personaName;
  final bool isBackHome;

  PersonaConnectionsPayload(
      {required this.personaUUID,
      required this.address,
      required this.type,
      required this.personaName,
      this.isBackHome = false});
}
