//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:share/share.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/screen/bloc/feralfile/feralfile_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/eth_amount_formatter.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/xtz_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

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
  bool isHideGalleryEnabled = false;
  List<ContextedAddress> contextedAddresses = [];
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
        contextedAddresses.add(ContextedAddress(CryptoType.BITMARK, address));

        final ffAccount = widget.connection.ffConnection?.ffAccount ??
            widget.connection.ffWeb3Connection?.ffAccount;
        final ethereumAddress = ffAccount?.ethereumAddress;
        final tezosAddress = ffAccount?.tezosAddress;

        if (ethereumAddress != null) {
          contextedAddresses
              .add(ContextedAddress(CryptoType.ETH, ethereumAddress));
          fetchETHBalance(ethereumAddress);
        }

        if (tezosAddress != null) {
          contextedAddresses
              .add(ContextedAddress(CryptoType.XTZ, tezosAddress));
          fetchXtzBalance(tezosAddress);
        }

        break;

      case "walletBeacon":
        _source = widget.connection.walletBeaconConnection?.peer.name ??
            "tezos_wallet".tr();
        contextedAddresses.add(ContextedAddress(CryptoType.XTZ, address));
        fetchXtzBalance(address);
        break;

      case "walletConnect":
        _source = widget.connection.wcConnectedSession?.sessionStore
                .remotePeerMeta.name ??
            "ethereum_wallet".tr();
        contextedAddresses.add(ContextedAddress(CryptoType.ETH, address));
        fetchETHBalance(address);
        break;

      case "walletBrowserConnect":
        _source = widget.connection.data;
        contextedAddresses.add(ContextedAddress(CryptoType.ETH, address));
        fetchETHBalance(address);
        break;

      case 'ledger':
        final data = widget.connection.ledgerConnection;
        _source = data?.ledgerName ?? 'Unknown';
        final ethereumAddress = data?.etheremAddress.firstOrNull;
        final tezosAddress = data?.tezosAddress.firstOrNull;

        if (ethereumAddress != null) {
          contextedAddresses
              .add(ContextedAddress(CryptoType.ETH, ethereumAddress));
          fetchETHBalance(ethereumAddress);
        }

        if (tezosAddress != null) {
          contextedAddresses
              .add(ContextedAddress(CryptoType.XTZ, tezosAddress));
          fetchXtzBalance(tezosAddress);
        }
        break;

      default:
        break;
    }

    isHideGalleryEnabled = injector<AccountService>()
        .isLinkedAccountHiddenInGallery(widget.connection.hiddenGalleryKey);
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

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.connection.name.maskIfNeeded(),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _addressesSection(),
              const SizedBox(height: 40),
              _preferencesSection(),
              const SizedBox(height: 40),
              _backupSection(),
              const SizedBox(height: 40),
            ],
          ),
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
          contextedAddresses.length > 1
              ? "linked_addresses".tr()
              : "linked_address".tr(),
          style: theme.textTheme.headline1,
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...contextedAddresses.map(
              (e) => Column(
                children: [
                  _addressRow(e.cryptoType,
                      address: e.address,
                      balanceString:
                          _balances[e.address] ?? '-- ${e.cryptoType.code}'),
                  const SizedBox(height: 15),
                  addOnlyDivider(),
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
    final balanceStyle = theme.textTheme.subtitle1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(type.source, style: theme.textTheme.headline4),
          Text(balanceString, style: balanceStyle),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                showInfoNotification(const Key("address"), "copied_to_clipboard".tr());
                Clipboard.setData(ClipboardData(text: address));
              },
              child: Text(
                address,
                style: theme.textTheme.subtitle1,
              ),
            ),
          ),
        ],
      )
    ]);
  }

  Widget _preferencesSection() {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "preferences".tr(),
        style: theme.textTheme.headline1,
      ),
      const SizedBox(
        height: 14,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("hide_from_collection".tr(),
                  style: theme.textTheme.headline4),
              CupertinoSwitch(
                value: isHideGalleryEnabled,
                onChanged: (value) async {
                  await injector<AccountService>()
                      .setHideLinkedAccountInGallery(
                          widget.connection.hiddenGalleryKey, value);
                  final hiddenAddress =
                      await injector<AccountService>().getHiddenAddresses();
                  setState(() {
                    context
                        .read<NftCollectionBloc>()
                        .add(UpdateHiddenTokens(ownerAddresses: hiddenAddress));
                    isHideGalleryEnabled = value;
                  });
                },
                activeColor: theme.colorScheme.primary,
              )
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "do_not_show_nft".tr(),
            //"Do not show this account's NFTs in the collection view."
            style: theme.textTheme.bodyText1,
          ),
        ],
      ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _backupSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("backup".tr(), style: theme.textTheme.headline1),
        const SizedBox(height: 24),
        if (_source == 'FeralFile') ...[
          Text("ba_the_keys_for_thisFf".tr(),
              //'The keys for this account are either automatically backed up by Feral File or managed by your web3 wallet (if you connected one).',
              style: theme.textTheme.bodyText1),
        ] else ...[
          Text("ba_the_keys_for_thisFf".tr(args: [_source]),
              //"The keys for this account are in $_source. You should manage your key backups there.",
              style: theme.textTheme.bodyText1),
        ],
      ],
    );
  }
}
