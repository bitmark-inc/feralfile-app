//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:math';

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/connections/connections_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/ethereum/ethereum_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/tezos/tezos_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/usdc/usdc_bloc.dart';
import 'package:autonomy_flutter/screen/connection/persona_connections_page.dart';
import 'package:autonomy_flutter/screen/global_receive/receive_detail_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/send/send_crypto_page.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_list_view.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_bloc.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/wallet_detail_state.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/usdc_amount_formatter.dart';
import 'package:autonomy_flutter/view/au_buttons.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

class WalletDetailPage extends StatefulWidget {
  final WalletDetailsPayload payload;

  const WalletDetailPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends State<WalletDetailPage> with RouteAware {
  late ScrollController controller;
  bool hideConnection = false;
  bool hideSend = false;
  bool hideAddress = false;
  bool hideBalance = false;

  @override
  void initState() {
    super.initState();
    final personUUID = widget.payload.personaUUID;
    context.read<AccountsBloc>().add(
        FindAccount(personUUID, widget.payload.address, widget.payload.type));
    switch (widget.payload.type) {
      case CryptoType.ETH:
        context
            .read<EthereumBloc>()
            .add(GetEthereumBalanceWithAddressEvent([widget.payload.address]));
        context
            .read<USDCBloc>()
            .add(GetUSDCBalanceWithAddressEvent(widget.payload.address));
        break;
      case CryptoType.XTZ:
        context
            .read<TezosBloc>()
            .add(GetTezosBalanceWithAddressEvent([widget.payload.address]));
        break;
      case CryptoType.USDC:
        context
            .read<USDCBloc>()
            .add(GetUSDCBalanceWithAddressEvent(widget.payload.address));
        break;
      case CryptoType.UNKNOWN:
        // do nothing
        break;
    }
    controller = ScrollController();
    controller.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _callFetchConnections();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    final cryptoType = widget.payload.type;
    final address = widget.payload.address;
    context
        .read<WalletDetailBloc>()
        .add(WalletDetailBalanceEvent(cryptoType, address));
    if (cryptoType == CryptoType.ETH) {
      context.read<USDCBloc>().add(GetUSDCBalanceWithAddressEvent(address));
    }
    _callFetchConnections();
  }

  void _listener() {
    if (controller.offset > 0) {
      setState(() {
        hideConnection = true;
      });
    } else {
      setState(() {
        hideConnection = false;
      });
    }
  }

  void _callFetchConnections() {
    final personUUID = widget.payload.personaUUID;

    switch (widget.payload.type) {
      case CryptoType.ETH:
        context
            .read<ConnectionsBloc>()
            .add(GetETHConnectionsEvent(personUUID, widget.payload.index));
        break;
      case CryptoType.XTZ:
        context
            .read<ConnectionsBloc>()
            .add(GetXTZConnectionsEvent(personUUID, widget.payload.index));
        break;
      default:
        // do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cryptoType = widget.payload.type;
    final address = widget.payload.address;
    context
        .read<WalletDetailBloc>()
        .add(WalletDetailBalanceEvent(cryptoType, address));
    final theme = Theme.of(context);
    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);
    final showConnection = (widget.payload.type == CryptoType.ETH ||
        widget.payload.type == CryptoType.XTZ);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.payload.type.name,
        icon: const Icon(
          AuIcon.scan,
        ),
        action: showConnection ? _connectionIconTap : null,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: BlocConsumer<WalletDetailBloc, WalletDetailState>(
          listener: (context, state) async {},
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hideConnection ? const SizedBox(height: 16) : addTitleSpace(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 3000),
                  height: hideConnection ? 60 : null,
                  child: _balanceSection(state.balance, state.balanceInUSD),
                ),
                Visibility(
                    visible: hideConnection,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 12,
                        ),
                        addOnlyDivider(),
                      ],
                    )),
                Expanded(
                  child: CustomScrollView(
                    controller: controller,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 3000),
                              child: Column(
                                children: [
                                  cryptoType == CryptoType.USDC
                                      ? Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 26, 0, 12),
                                    child: _erc20Tag(),
                                  )
                                      : SizedBox(height: hideConnection ? 84 : 52),
                                  Padding(
                                    padding: padding,
                                    child: _addressSection(),
                                  ),
                                  const SizedBox(height: 24),
                                  Padding(
                                    padding: padding,
                                    child: _sendReceiveSection(),
                                  ),
                                  const SizedBox(height: 24),
                                  if (widget.payload.type == CryptoType.ETH) ...[
                                    BlocBuilder<USDCBloc, USDCState>(
                                        builder: (context, state) {
                                          final address = widget.payload.address;
                                          final usdcBalance = state.usdcBalances[address];
                                          final balance = usdcBalance == null
                                              ? "-- USDC"
                                              : "${USDCAmountFormatter(usdcBalance).format()} USDC";
                                          return Padding(
                                            padding: padding,
                                            child: _usdcBalance(balance),
                                          );
                                        })
                                  ],
                                  addDivider(),
                                  if (showConnection) ...[
                                    Padding(
                                      padding: padding,
                                      child: _connectionsSection(),
                                    ),
                                    addDivider(),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      widget.payload.type == CryptoType.XTZ
                          ? TezosTXListView(
                              address: widget.payload.address,
                            )
                          : const SliverToBoxAdapter(
                              child: SizedBox(),
                            )
                    ],
                  ),
                ),
                widget.payload.type == CryptoType.XTZ
                    ? GestureDetector(
                        onTap: () =>
                            launchUrlString(_txURL(widget.payload.address)),
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.fromLTRB(0, 17, 0, 20),
                          color: AppColor.secondaryDimGreyBackground,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("powered_by_tzkt".tr(),
                                  style: theme.textTheme.ppMori400Black14),
                              const SizedBox(
                                width: 8,
                              ),
                              SvgPicture.asset(
                                  "assets/images/external_link.svg"),
                            ],
                          ),
                        ),
                      )
                    : Container(),
              ],
            );
          }),
    );
  }

  void _connectionIconTap() {
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

    Navigator.of(context).pushNamed(AppRouter.scanQRPage, arguments: scanItem);
  }

  Widget _usdcBalance(String balance) {
    final theme = Theme.of(context);
    final balanceStyle = theme.textTheme.ppMori400White14
        .copyWith(color: AppColor.auQuickSilver);
    return TappableForwardRow(
        padding: EdgeInsets.zero,
        leftWidget: Container(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/usdc.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 35),
              Text(
                "USDC",
                style: theme.textTheme.ppMori700Black14,
              ),
              const SizedBox(width: 10),
              _erc20Tag()
            ],
          ),
        ),
        rightWidget: Text(
          balance,
          style: balanceStyle,
        ),
        onTap: () {
          final payload = WalletDetailsPayload(
              type: CryptoType.USDC,
              wallet: widget.payload.wallet,
              personaUUID: widget.payload.personaUUID,
              address: widget.payload.address,
              personaName: widget.payload.personaName,
              index: widget.payload.index);
          Navigator.of(context)
              .pushNamed(AppRouter.walletDetailsPage, arguments: payload);
        });
  }

  Widget _erc20Tag() {
    final theme = Theme.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          side: const BorderSide(
            color: AppColor.auQuickSilver,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15)),
      onPressed: () {},
      child: Text('ERC-20', style: theme.textTheme.ppMori400Grey14),
    );
  }

  Widget _balanceSection(String balance, String balanceInUSD) {
    final theme = Theme.of(context);
    if (widget.payload.type == CryptoType.ETH ||
        widget.payload.type == CryptoType.XTZ) {
      return SizedBox(
        child: Column(
          children: [
            Text(
              balance.isNotEmpty ? balance : "-- ${widget.payload.type.name}",
              style: hideConnection
                  ? theme.textTheme.ppMori400Black14.copyWith(fontSize: 24)
                  : theme.textTheme.ppMori400Black36,
            ),
            Text(
              balanceInUSD.isNotEmpty ? balanceInUSD : "-- USD",
              style: hideConnection
                  ? theme.textTheme.ppMori400Grey14
                  : theme.textTheme.ppMori400Grey16,
            )
          ],
        ),
      );
    }

    if (widget.payload.type == CryptoType.USDC) {
      return BlocBuilder<USDCBloc, USDCState>(
        builder: (context, state) {
          final usdcBalance = state.usdcBalances[widget.payload.address];
          final balance = usdcBalance == null
              ? "-- USDC"
              : "${USDCAmountFormatter(usdcBalance).format()} USDC";
          return SizedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(balance, style: theme.textTheme.ppMori400Black36),
              ],
            ),
          );
        },
      );
    }
    return Container();
  }

  Widget _addressSection() {
    var address = widget.payload.address;
    final theme = Theme.of(context);
    bool isCopied = false;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColor.auLightGrey,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      child: Row(
        children: [
          Text(
            "your_address".tr(),
            style: theme.textTheme.ppMori400Grey14,
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            address.mask(4),
            style: theme.textTheme.ppMori400Black14,
          ),
          Expanded(
            child: StatefulBuilder(builder: (context, setState) {
              return Container(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    //width: double.infinity,
                    height: 28.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCopied
                            ? AppColor.auSuperTeal
                            : AppColor.auLightGrey,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                        side: BorderSide(
                          color: isCopied
                              ? Colors.transparent
                              : AppColor.greyMedium,
                        ),
                        alignment: Alignment.center,
                      ),
                      onPressed: () {
                        if (isCopied) return;
                        showInfoNotification(const Key("address"),
                            "address_copied_to_clipboard".tr());
                        Clipboard.setData(ClipboardData(text: address));
                        setState(() {
                          isCopied = true;
                        });
                      },
                      child: isCopied
                          ? Text(
                              'Copied',
                              style: theme.textTheme.ppMori400Black14,
                            )
                          : Text('Copy',
                              style: theme.textTheme.ppMori400Grey14),
                    ),
                  ));
            }),
          ),
        ],
      ),
    );
  }

  Widget _connectionsSection() {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      BlocBuilder<ConnectionsBloc, ConnectionsState>(builder: (context, state) {
        final connectionItems = state.connectionItems;
        //if (connectionItems == null) return const SizedBox();
        return TappableForwardRow(
          padding: EdgeInsets.zero,
          leftWidget: Text(
            "connection_with_dApps".tr(),
            style: theme.textTheme.ppMori400Black14,
          ),
          rightWidget: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColor.auGrey),
            ),
            width: 24,
            height: 24,
            child: Text(
              '${connectionItems?.length ?? 0}',
              style: theme.textTheme.ppMori400Black14
                  .copyWith(color: AppColor.auGrey),
            ),
          ),
          onTap: () {
            final payload = PersonaConnectionsPayload(
              personaUUID: widget.payload.personaUUID,
              index: widget.payload.index,
              address: widget.payload.address,
              type: widget.payload.type,
            );
            Navigator.of(context).pushNamed(AppRouter.personaConnectionsPage,
                arguments: payload);
          },
        );
      }),
    ]);
  }

  String _txURL(String address) {
    return "https://tzkt.io/$address/operations";
  }

  Widget _sendReceiveSection() {
    final theme = Theme.of(context);
    if (widget.payload.type == CryptoType.ETH ||
        widget.payload.type == CryptoType.XTZ ||
        widget.payload.type == CryptoType.USDC) {
      return Row(
        children: [
          Expanded(
            child: AuCustomButton(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/Send.svg',
                    width: 18,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    '${"send".tr()} ${widget.payload.type.name}',
                    style: theme.textTheme.ppMori400Black14,
                  ),
                ],
              ),
              onPressed: () async {
                final payload = await Navigator.of(context).pushNamed(
                    SendCryptoPage.tag,
                    arguments: SendData(
                        LibAukDart.getWallet(widget.payload.personaUUID),
                        widget.payload.type,
                        null,
                        widget.payload.index)) as Map?;
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
                final account = accountState.accounts?.firstWhere((element) =>
                    element.blockchain == widget.payload.type.source);
                final blockChain =
                    (widget.payload.type.source == CryptoType.USDC.source)
                        ? CryptoType.ETH.source
                        : widget.payload.type.source;
                return AuCustomButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: pi,
                        child: SvgPicture.asset(
                          'assets/images/Recieve.svg',
                          width: 18,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        '${"receive".tr()} ${widget.payload.type.name}',
                        style: theme.textTheme.ppMori400Black14,
                      ),
                    ],
                  ),
                  onPressed: () {
                    if (account != null && account.accountNumber.isNotEmpty) {
                      Navigator.of(context).pushNamed(
                          GlobalReceiveDetailPage.tag,
                          arguments: GlobalReceivePayload(
                              address: widget.payload.address,
                              blockchain: blockChain,
                              account: account));
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
    }
    return const SizedBox(
      height: 10,
    );
  }
}

class WalletDetailsPayload {
  final CryptoType type;
  final WalletStorage wallet;
  final String personaUUID;
  final String address;
  final String personaName;
  final int index;

  WalletDetailsPayload({
    required this.type,
    required this.wallet,
    required this.personaUUID,
    required this.address,
    required this.personaName,
    required this.index,
  });
}
