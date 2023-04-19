//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';

class LinkedAccountDetailsPage extends StatefulWidget {
  final Connection connection;

  const LinkedAccountDetailsPage({Key? key, required this.connection})
      : super(key: key);

  @override
  State<LinkedAccountDetailsPage> createState() =>
      _LinkedAccountDetailsPageState();
}

class _LinkedAccountDetailsPageState extends State<LinkedAccountDetailsPage> {
  final Map<String, String> _balances = {};
  List<ContextedAddress> contextAddresses = [];
  String _source = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final address = widget.connection.accountNumber;

    switch (widget.connection.connectionType) {
      case 'feralFileWeb3':
      case 'feralFileToken':
        _source = "FeralFile";

        context
            .read<FeralfileBloc>()
            .add(GetFFAccountInfoEvent(widget.connection));

        final ffAccount = widget.connection.ffConnection?.ffAccount ??
            widget.connection.ffWeb3Connection?.ffAccount;
        final ethereumAddress = ffAccount?.ethereumAddress;
        final tezosAddress = ffAccount?.tezosAddress;

        if (ethereumAddress != null) {
          contextAddresses
              .add(ContextedAddress(CryptoType.ETH, ethereumAddress));
          fetchETHBalance(ethereumAddress);
        }

        if (tezosAddress != null) {
          contextAddresses.add(ContextedAddress(CryptoType.XTZ, tezosAddress));
          fetchXtzBalance(tezosAddress);
        }

        break;

      case "walletBeacon":
        _source = widget.connection.walletBeaconConnection?.peer.name ??
            "tezos_wallet".tr();
        contextAddresses.add(ContextedAddress(CryptoType.XTZ, address));
        fetchXtzBalance(address);
        break;

      case "walletConnect":
        _source = widget.connection.wcConnectedSession?.sessionStore
                .remotePeerMeta.name ??
            "ethereum_wallet".tr();
        contextAddresses.add(ContextedAddress(CryptoType.ETH, address));
        fetchETHBalance(address);
        break;

      case "walletBrowserConnect":
        _source = widget.connection.data;
        contextAddresses.add(ContextedAddress(CryptoType.ETH, address));
        fetchETHBalance(address);
        break;

      case 'ledger':
        final data = widget.connection.ledgerConnection;
        _source = data?.ledgerName ?? 'Unknown';
        final ethereumAddress = data?.etheremAddress.firstOrNull;
        final tezosAddress = data?.tezosAddress.firstOrNull;

        if (ethereumAddress != null) {
          contextAddresses
              .add(ContextedAddress(CryptoType.ETH, ethereumAddress));
          fetchETHBalance(ethereumAddress);
        }

        if (tezosAddress != null) {
          contextAddresses.add(ContextedAddress(CryptoType.XTZ, tezosAddress));
          fetchXtzBalance(tezosAddress);
        }
        break;
      case "manuallyAddress":
        contextAddresses.add(ContextedAddress(
            CryptoType.UNKNOWN, widget.connection.accountNumber));
        break;

      default:
        break;
    }
  }

  Future fetchXtzBalance(String address) async {
    int balance = await injector<TezosService>().getBalance(address);
    setState(() {
      _balances[address] = "${XtzAmountFormatter(balance).format()} XTZ";
    });
  }

  Future fetchETHBalance(String address) async {
    final balance = await injector<EthereumService>().getBalance(address);
    setState(() {
      _balances[address] =
          "${EthAmountFormatter(balance.getInWei).format()} ETH";
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.connection.connectionType) {
      case 'feralFileWeb3':
      case 'feralFileToken':
        _source = "FeralFile";

        final feralFileState = context.watch<FeralfileBloc>().state;
        final wyreWallet =
            (feralFileState.connection?.ffConnection?.ffAccount ??
                    feralFileState.connection?.ffWeb3Connection?.ffAccount)
                ?.wyreWallet;
        if (wyreWallet != null) {
          setState(() {
            _balances[widget.connection.accountNumber] =
                "${wyreWallet.availableBalances['USDC'] ?? 0} USDC";
          });
        }
        break;
    }

    final padding = ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, bottom: 0);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.connection.name.isNotEmpty
            ? widget.connection.name.maskIfNeeded()
            : widget.connection.accountNumber,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            addTitleSpace(),
            Padding(
              padding: padding,
              child: _addressesSection(),
            ),
            addOnlyDivider(),
            const SizedBox(height: 16),
            Padding(
              padding: padding,
              child: _backupSection(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _addressesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contextAddresses.length > 1
              ? "linked_addresses".tr()
              : "linked_address".tr(),
          style: theme.textTheme.ppMori400Black16,
        ),
        const SizedBox(height: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...contextAddresses.map(
              (e) => Column(
                children: [
                  _addressRow(e.cryptoType,
                      address: e.address,
                      balanceString: e.cryptoType != CryptoType.UNKNOWN
                          ? _balances[e.address] ?? '-- ${e.cryptoType.code}'
                          : ""),
                  e == contextAddresses.last
                      ? const SizedBox()
                      : addOnlyDivider(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _addressRow(CryptoType type,
      {required String address, required balanceString}) {
    final theme = Theme.of(context);
    final balanceStyle = theme.textTheme.ppMori400Grey14;
    final isHidden =
        injector<AccountService>().isLinkedAccountHiddenInGallery(address);
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dragDismissible: false,
        children: slidableActions(address),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(type.source, style: theme.textTheme.ppMori700Black14),
              const Expanded(child: SizedBox()),
              if (isHidden) ...[
                SvgPicture.asset(
                  'assets/images/hide.svg',
                  color: theme.colorScheme.surface,
                ),
                const SizedBox(width: 10),
              ],
              Text(balanceString, style: balanceStyle),
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
                    Clipboard.setData(ClipboardData(text: address));
                  },
                  child: Text(
                    address,
                    style: theme.textTheme.ppMori400Black14,
                  ),
                ),
              ),
            ],
          )
        ]),
      ),
    );
  }

  Widget _backupSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("backup".tr(), style: theme.textTheme.ppMori400Black16),
        const SizedBox(height: 24),
        if (_source == 'FeralFile') ...[
          Text("ba_the_keys_for_thisFf".tr(),
              //'The keys for this account are either automatically backed up by Feral File or managed by your web3 wallet (if you connected one).',
              style: theme.textTheme.ppMori400Black14),
        ] else ...[
          Text("ba_the_keys_for_this".tr(args: [_source]),
              //"The keys for this account are in $_source. You should manage your key backups there.",
              style: theme.textTheme.ppMori400Black14),
        ],
      ],
    );
  }

  List<CustomSlidableAction> slidableActions(String address) {
    final theme = Theme.of(context);
    final isHidden =
        injector<AccountService>().isLinkedAccountHiddenInGallery(address);
    return [
      CustomSlidableAction(
        backgroundColor: AppColor.secondarySpanishGrey,
        foregroundColor: theme.colorScheme.secondary,
        child: Semantics(
          label: "${address}_hide",
          child: SvgPicture.asset(
              isHidden ? 'assets/images/unhide.svg' : 'assets/images/hide.svg'),
        ),
        onPressed: (_) async {
          await injector<AccountService>()
              .setHideLinkedAccountInGallery(address, !isHidden);
          setState(() {});
        },
      ),
    ];
  }
}
