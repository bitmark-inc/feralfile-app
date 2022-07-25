//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/common/network_config_injector.dart';
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

class LinkedAccountDetailsPage extends StatefulWidget {
  final Connection connection;

  const LinkedAccountDetailsPage({Key? key, required this.connection})
      : super(key: key);

  @override
  State<LinkedAccountDetailsPage> createState() =>
      _LinkedAccountDetailsPageState();
}

class _LinkedAccountDetailsPageState extends State<LinkedAccountDetailsPage> {
  Map<String, String> _balances = {};
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
            "Tezos Wallet";
        contextedAddresses.add(ContextedAddress(CryptoType.XTZ, address));
        fetchXtzBalance(address);
        break;

      case "walletConnect":
        _source = widget.connection.wcConnectedSession?.sessionStore
                .remotePeerMeta.name ??
            "Ethereum Wallet";
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
    int balance = await injector<NetworkConfigInjector>()
        .I<TezosService>()
        .getBalance(address);
    setState(() {
      _balances[address] = "${XtzAmountFormatter(balance).format()} XTZ";
    });
  }

  Future fetchETHBalance(String address) async {
    final balance = await injector<NetworkConfigInjector>()
        .I<EthereumService>()
        .getBalance(address);
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
        margin: pageEdgeInsets,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _addressesSection(),
              SizedBox(height: 40),
              _cryptoSection(),
              SizedBox(height: 40),
              _preferencesSection(),
              SizedBox(height: 40),
              _backupSection(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contextedAddresses.length > 1
              ? "Linked addresses"
              : "Linked adddress",
          style: appTextTheme.headline1,
        ),
        SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...contextedAddresses.map(
              (e) => Column(
                children: [
                  _addressRow(e.cryptoType, address: e.address),
                  SizedBox(height: 15),
                  addOnlyDivider(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cryptoSection() {
    if (contextedAddresses.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Crypto",
          style: appTextTheme.headline1,
        ),
        SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...contextedAddresses.map(
              (e) {
                return Column(
                  children: [
                    _balanceRow(e.cryptoType,
                        balanceString:
                            _balances[e.address] ?? '-- ${e.cryptoType.code}'),
                    if (e != contextedAddresses.last) ...[
                      addDivider(),
                    ]
                  ],
                );
              },
            )
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _addressRow(CryptoType type, {required String address}) {
    final addressStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type.source, style: appTextTheme.headline4),
          TextButton(
            onPressed: () => Share.share("${type.source} address: $address"),
            child: Text(
              "Share",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: "AtlasGrotesk",
                  fontWeight: FontWeight.bold),
            ),
            style: ButtonStyle(alignment: Alignment.centerRight),
          )
        ],
      ),
      Row(
        children: [
          Expanded(
            child: Text(address, style: addressStyle),
          ),
        ],
      )
    ]);
  }

  Widget _balanceRow(CryptoType type, {required String balanceString}) {
    final balanceStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(type.fullCode, style: appTextTheme.headline4),
        Text(balanceString, style: balanceStyle),
      ],
    );
  }

  Widget _preferencesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "Preferences",
        style: appTextTheme.headline1,
      ),
      SizedBox(
        height: 14,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hide from collection', style: appTextTheme.headline4),
              CupertinoSwitch(
                value: isHideGalleryEnabled,
                onChanged: (value) async {
                  await injector<AccountService>()
                      .setHideLinkedAccountInGallery(
                          widget.connection.hiddenGalleryKey, value);
                  setState(() {
                    isHideGalleryEnabled = value;
                  });
                },
                activeColor: Colors.black,
              )
            ],
          ),
          SizedBox(height: 14),
          Text(
            "Do not show this account's NFTs in the collection view.",
            style: appTextTheme.bodyText1,
          ),
        ],
      ),
      SizedBox(height: 12),
    ]);
  }

  Widget _backupSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Backup", style: appTextTheme.headline1),
        SizedBox(height: 24),
        if (_source == 'FeralFile') ...[
          Text(
              'The keys for this account are either automically backed up by Feral File or managed by your web3 wallet (if you connected one).',
              style: appTextTheme.bodyText1),
        ] else ...[
          Text(
              "The keys for this account are in $_source. You should manage your key backups there.",
              style: appTextTheme.bodyText1),
        ],
      ],
    );
  }
}
