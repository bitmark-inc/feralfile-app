//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share/share.dart';

class LinkedAccountDetailsPage extends StatefulWidget {
  final Connection connection;

  const LinkedAccountDetailsPage({Key? key, required this.connection})
      : super(key: key);

  @override
  State<LinkedAccountDetailsPage> createState() =>
      _LinkedAccountDetailsPageState();
}

class _LinkedAccountDetailsPageState extends State<LinkedAccountDetailsPage> {
  String? _balance;
  bool isHideGalleryEnabled = false;

  @override
  void initState() {
    super.initState();

    switch (widget.connection.connectionType) {
      case 'feralFileWeb3':
      case 'feralFileToken':
        context
            .read<FeralfileBloc>()
            .add(GetFFAccountInfoEvent(widget.connection));
        break;

      case "walletBeacon":
        fetchXtzBalance();
        break;

      case "walletConnect":
      case "walletBrowserConnect":
        fetchETHBalance();
        break;

      default:
        break;
    }

    isHideGalleryEnabled = injector<AccountService>()
        .isLinkedAccountHiddenInGallery(widget.connection.accountNumber);
  }

  Future fetchXtzBalance() async {
    int balance = await injector<NetworkConfigInjector>()
        .I<TezosService>()
        .getBalance(widget.connection.accountNumber);
    setState(() {
      _balance = "${XtzAmountFormatter(balance).format()} XTZ";
    });
  }

  Future fetchETHBalance() async {
    final balance = await injector<NetworkConfigInjector>()
        .I<EthereumService>()
        .getBalance(widget.connection.accountNumber);
    setState(() {
      _balance = "${EthAmountFormatter(balance.getInWei).format()} ETH";
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);
    final balanceStyle = appTextTheme.bodyText2?.copyWith(color: Colors.black);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: widget.connection.name.maskIfNeeded(),
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
              BlocBuilder<FeralfileBloc, FeralFileState>(
                builder: (context, state) {
                  final wyreWallet =
                      state.connection?.ffConnection?.ffAccount.wyreWallet;

                  final String source;
                  final String coinType;
                  final String balanceString;
                  final String addressType;
                  switch (widget.connection.connectionType) {
                    case "feralFileToken":
                    case "feralFileWeb3":
                      source = "FeralFile";
                      coinType = "USD Coin (USDC)";
                      balanceString = wyreWallet == null
                          ? "-- USDC"
                          : "${wyreWallet.availableBalances['USDC'] ?? 0} USDC";
                      addressType = 'Bitmark';
                      break;
                    case "walletBeacon":
                      source =
                          widget.connection.walletBeaconConnection?.peer.name ??
                              "Tezos Wallet";
                      coinType = "Tezos (XTZ)";
                      balanceString = _balance ?? "-- XTZ";
                      addressType = 'Tezos';
                      break;

                    case "walletConnect":
                      source = widget.connection.wcConnectedSession
                              ?.sessionStore.remotePeerMeta.name ??
                          "Ethereum Wallet";
                      coinType = "Ethereum (ETH)";
                      balanceString = _balance ?? "-- ETH";
                      addressType = 'Ethereum';
                      break;

                    case "walletBrowserConnect":
                      source = widget.connection.data;
                      coinType = "Ethereum (ETH)";
                      balanceString = _balance ?? "-- ETH";
                      addressType = 'Ethereum';
                      break;

                    default:
                      source = "";
                      coinType = "";
                      balanceString = "";
                      addressType = "";
                      break;
                  }

                  final address = widget.connection.accountNumber;

                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Linked address",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(addressType, style: appTextTheme.headline4),
                            TextButton(
                              onPressed: () =>
                                  Share.share("$addressType address: $address"),
                              child: Text(
                                "Share",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: "AtlasGrotesk",
                                    fontWeight: FontWeight.bold),
                              ),
                              style:
                                  ButtonStyle(alignment: Alignment.centerRight),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                address,
                                style: addressStyle,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        Text(
                          "Crypto",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              coinType,
                              style: appTextTheme.headline4,
                            ),
                            Text(
                              balanceString,
                              style: balanceStyle,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(height: 40),
                        _preferencesSection(),
                        SizedBox(height: 40),
                        Text(
                          "Backup",
                          style: appTextTheme.headline1,
                        ),
                        SizedBox(height: 24),
                        if (source == 'FeralFile') ...[
                          Text(
                              'The keys for this account are either automically backed up by Feral File or managed by your web3 wallet (if you connected one).',
                              style: appTextTheme.bodyText1),
                        ] else ...[
                          Text(
                              "The keys for this account are in $source. You should manage your key backups there.",
                              style: appTextTheme.bodyText1),
                        ],
                        SizedBox(height: 40),
                      ]);
                },
              )
            ],
          ),
        ),
      ),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hide from gallery', style: appTextTheme.headline4),
              CupertinoSwitch(
                value: isHideGalleryEnabled,
                onChanged: (value) async {
                  await injector<AccountService>()
                      .setHideLinkedAccountInGallery(
                          widget.connection.accountNumber, value);
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
            "Do not show this account's NFTs in the gallery view.",
            style: appTextTheme.bodyText1,
          ),
        ],
      ),
      SizedBox(height: 12),
    ]);
  }
}
